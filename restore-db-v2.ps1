# Database Restore Script using Docker (Version 2 - Multiple Solutions)
# Usage: .\restore-db-v2.ps1 <backup-file.sql> [method]
# Methods: 
#   1 = Disable triggers (current, may need permissions)
#   2 = Defer constraints (recommended)
#   3 = Disable foreign keys temporarily

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("1", "2", "3")]
    [string]$Method = "2"
)

$DB_HOST = "ep-patient-heart-ahu35yr5-pooler.c-3.us-east-1.aws.neon.tech"
$DB_USER = "neondb_owner"
$DB_NAME = "neondb"
$DB_PASSWORD = "npg_hlu8Cbiag6IY"

# Check if backup file exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "Error: Backup file not found: $BackupFile" -ForegroundColor Red
    exit 1
}

Write-Host "Starting database restore..." -ForegroundColor Yellow
Write-Host "Host: $DB_HOST" -ForegroundColor Cyan
Write-Host "Database: $DB_NAME" -ForegroundColor Cyan
Write-Host "Backup file: $BackupFile" -ForegroundColor Cyan
Write-Host "Method: $Method" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will overwrite existing data in the database!" -ForegroundColor Red
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Restore cancelled." -ForegroundColor Yellow
    exit 0
}

# Check if Docker is running
try {
    docker ps | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
} catch {
    Write-Host "Error: Docker is not running or not installed!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

# Get absolute path for volume mount
$backupPath = (Resolve-Path $BackupFile).Path
$backupDir = Split-Path $backupPath -Parent
$backupName = Split-Path $backupPath -Leaf

# Read backup file
$backupContent = Get-Content $BackupFile -Raw -Encoding UTF8

Write-Host "`nRestoring database..." -ForegroundColor Green

# Method 1: Disable triggers (may need ALTER TABLE permission)
if ($Method -eq "1") {
    Write-Host "Using Method 1: Disable triggers" -ForegroundColor Yellow
    
    $disableTriggersSQL = @"
-- Disable all triggers to allow out-of-order inserts
DO `$\$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    ) 
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' DISABLE TRIGGER ALL';
    END LOOP;
END `$\$;
"@

    $enableTriggersSQL = @"
-- Re-enable all triggers
DO `$\$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    ) 
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' ENABLE TRIGGER ALL';
    END LOOP;
END `$\$;
"@

    $restoreScript = $disableTriggersSQL + "`n" + $backupContent + "`n" + $enableTriggersSQL
}

# Method 2: Defer constraints (RECOMMENDED - works with regular user permissions)
elseif ($Method -eq "2") {
    Write-Host "Using Method 2: Defer constraints (RECOMMENDED)" -ForegroundColor Yellow
    
    $deferConstraintsSQL = @"
-- Start transaction and defer all foreign key constraints
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
"@

    $commitSQL = @"
-- Commit transaction (constraints will be checked at commit)
COMMIT;
"@

    $restoreScript = $deferConstraintsSQL + "`n" + $backupContent + "`n" + $commitSQL
}

# Method 3: Temporarily disable foreign key constraints
elseif ($Method -eq "3") {
    Write-Host "Using Method 3: Disable foreign key constraints" -ForegroundColor Yellow
    
    # Get list of foreign key constraints
    $disableFKsSQL = @"
-- Disable foreign key constraints temporarily
DO `$\$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT 
            conname,
            conrelid::regclass AS table_name
        FROM pg_constraint
        WHERE contype = 'f'
        AND connamespace = 'public'::regnamespace
    ) 
    LOOP
        -- Note: PostgreSQL doesn't support disabling FK constraints directly
        -- This method requires dropping and recreating constraints
        -- Not recommended for production
        RAISE NOTICE 'FK constraint: % on table %', r.conname, r.table_name;
    END LOOP;
END `$\$;
"@

    Write-Host "WARNING: Method 3 requires dropping constraints - not implemented for safety" -ForegroundColor Red
    Write-Host "Falling back to Method 2..." -ForegroundColor Yellow
    $Method = "2"
    
    $deferConstraintsSQL = @"
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
"@

    $commitSQL = @"
COMMIT;
"@

    $restoreScript = $deferConstraintsSQL + "`n" + $backupContent + "`n" + $commitSQL
}

# Write to temp file
$tempRestoreFile = Join-Path $backupDir "temp_restore_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
[System.IO.File]::WriteAllText($tempRestoreFile, $restoreScript, [System.Text.UTF8Encoding]::new($false))
$tempRestoreName = Split-Path $tempRestoreFile -Leaf

# Run restore and capture output
Write-Host "Executing restore..." -ForegroundColor Yellow
$restoreOutput = docker run --rm `
    -e PGPASSWORD=$DB_PASSWORD `
    -v "${backupDir}:/backup" `
    postgres:17 `
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f /backup/$tempRestoreName 2>&1

# Display output
$restoreOutput | ForEach-Object { Write-Host $_ }

# Check for errors in output (more reliable than exit code)
$hasError = $false
$restoreOutputString = $restoreOutput -join "`n"

# Check for common error patterns
if ($restoreOutputString -match "ERROR:\s+") {
    $hasError = $true
    Write-Host "`nERROR detected in restore output!" -ForegroundColor Red
}

# Check for ROLLBACK (indicates transaction failure)
if ($restoreOutputString -match "ROLLBACK") {
    $hasError = $true
    Write-Host "`nTransaction was rolled back - restore failed!" -ForegroundColor Red
}

# Check exit code as well
if ($LASTEXITCODE -ne 0) {
    $hasError = $true
    Write-Host "`npsql exited with error code: $LASTEXITCODE" -ForegroundColor Red
}

# Clean up temp file
Remove-Item $tempRestoreFile -ErrorAction SilentlyContinue

if ($hasError) {
    Write-Host "`nRestore FAILED! Database was rolled back to previous state." -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check for circular foreign key constraints" -ForegroundColor Yellow
    Write-Host "2. Verify table order in backup matches dependencies" -ForegroundColor Yellow
    Write-Host "3. Try using Method 1: .\restore-db-v2.ps1 $BackupFile 1" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`nRestore completed successfully!" -ForegroundColor Green
    Write-Host "All data has been restored to the database." -ForegroundColor Green
}
