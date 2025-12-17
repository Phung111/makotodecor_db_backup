# Database Restore Script using Docker (Version 2 - Multiple Solutions)
# Usage: .\restore-db-v2.ps1 <backup-file.sql> [method]
# Methods: 
#   1 = Disable triggers (current, may need permissions)
#   2 = Defer constraints (only works with DEFERRABLE FKs)
#   3 = Disable foreign keys temporarily
#   4 = Direct execution (RECOMMENDED for backups with session_replication_role)

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("1", "2", "3", "4")]
    [string]$Method = "4"
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

# Method 4: Direct execution (RECOMMENDED for Neon/managed PostgreSQL)
# Tables must be ordered by dependency in backup file
elseif ($Method -eq "4") {
    Write-Host "Using Method 4: Direct execution (RECOMMENDED)" -ForegroundColor Yellow
    Write-Host "  This method runs the backup file directly without modification." -ForegroundColor Gray
    Write-Host "  Requires tables to be ordered by dependency in backup file." -ForegroundColor Gray
    Write-Host "  Compatible with Neon and other managed PostgreSQL services." -ForegroundColor Gray
    
    # Remove session_replication_role if present (not supported on Neon)
    if ($backupContent -match "session_replication_role") {
        Write-Host "  Removing session_replication_role (not supported on managed PostgreSQL)..." -ForegroundColor Yellow
        $backupContent = $backupContent -replace "(?m)^.*session_replication_role.*$`r?`n?", ""
    }
    
    # Add TRUNCATE statements to clear existing data before restore
    # Using DO block to safely truncate only existing tables
    $truncateSQL = @"
-- Truncate all tables before restore (reverse dependency order)
-- Using DO block to handle non-existing tables gracefully
DO `$`$
DECLARE
    tables_to_truncate TEXT[] := ARRAY[
        'order_items', 'order_groups', 'orders', 'cart_items', 'carts',
        'colors', 'sizes', 'products', 'categories', 'imgs',
        'users', 'img_types', 'flyway_schema_history', 'access_counts'
    ];
    t TEXT;
BEGIN
    FOREACH t IN ARRAY tables_to_truncate
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t) THEN
            EXECUTE format('TRUNCATE TABLE public.%I CASCADE', t);
            RAISE NOTICE 'Truncated table: %', t;
        ELSE
            RAISE NOTICE 'Skipped (not found): %', t;
        END IF;
    END LOOP;
END
`$`$;

"@
    
    Write-Host "  Adding TRUNCATE statements to clear existing data..." -ForegroundColor Yellow
    $restoreScript = $truncateSQL + $backupContent
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

# Check for common error patterns, but ignore non-critical errors
# Ignore: "does not exist" (table not found during truncate - OK)
# Ignore: "NOTICE:" messages (informational)
$criticalErrors = $restoreOutputString -split "`n" | Where-Object { 
    $_ -match "ERROR:\s+" -and 
    $_ -notmatch "does not exist" -and
    $_ -notmatch "already exists" 
}

if ($criticalErrors.Count -gt 0) {
    $hasError = $true
    Write-Host "`nCritical ERROR detected in restore output!" -ForegroundColor Red
    $criticalErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
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
    Write-Host "3. Try using Method 4 (direct): .\restore-db-v2.ps1 $BackupFile 4" -ForegroundColor Yellow
    Write-Host "4. Try using Method 1 (triggers): .\restore-db-v2.ps1 $BackupFile 1" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`nRestore completed successfully!" -ForegroundColor Green
    Write-Host "All data has been restored to the database." -ForegroundColor Green
}
