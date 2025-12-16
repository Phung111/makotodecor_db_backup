# Database Restore Script using Docker
# Usage: .\restore-db.ps1 <backup-file.sql>

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
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

# Run psql using Docker (use postgres:17 to match Neon's PostgreSQL 17.7)
# PowerShell doesn't support < redirect, use -f flag with volume mount instead
# Use DEFERRED constraints to handle circular foreign key constraints
# This works with regular user permissions (no need for superuser)
Write-Host "`nRestoring database..." -ForegroundColor Green
Write-Host "Using DEFERRED constraints to handle circular foreign keys..." -ForegroundColor Yellow

# Read backup file
$backupContent = Get-Content $BackupFile -Raw -Encoding UTF8

# Build restore script with deferred constraints
# This defers FK constraint checks until commit, allowing out-of-order inserts
$deferConstraintsSQL = @"
-- Start transaction and defer all foreign key constraints
-- This allows inserting data in any order, constraints are checked at commit
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
"@

$commitSQL = @"
-- Commit transaction (all foreign key constraints will be validated at commit)
COMMIT;
"@

# Combine: begin transaction + defer constraints + backup content + commit
$restoreScript = $deferConstraintsSQL + "`n" + $backupContent + "`n" + $commitSQL

# Write to temp file
$tempRestoreFile = Join-Path $backupDir "temp_restore_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
[System.IO.File]::WriteAllText($tempRestoreFile, $restoreScript, [System.Text.UTF8Encoding]::new($false))
$tempRestoreName = Split-Path $tempRestoreFile -Leaf

# Run restore
docker run --rm `
    -e PGPASSWORD=$DB_PASSWORD `
    -v "${backupDir}:/backup" `
    postgres:17 `
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f /backup/$tempRestoreName

# Clean up temp file
Remove-Item $tempRestoreFile -ErrorAction SilentlyContinue

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nRestore completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nRestore failed!" -ForegroundColor Red
    exit 1
}
