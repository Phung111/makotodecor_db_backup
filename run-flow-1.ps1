# Flow 1: Full Backup and Restore (with flyway_schema_history)
# This script runs the complete flow:
#   1. backup-data.ps1 (backup all data including flyway_schema_history)
#   2. drop-row.ps1 (truncate all tables, keep schema)
#   3. restore-db.ps1 (restore data from backup)
#
# Usage: .\run-flow-1.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  FLOW 1: Full Backup and Restore" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This flow will:" -ForegroundColor Yellow
Write-Host "  1. Backup all data (including flyway_schema_history)" -ForegroundColor Gray
Write-Host "  2. Truncate all tables (keep schema structure)" -ForegroundColor Gray
Write-Host "  3. Restore data from backup" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Start Flow 1? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Flow cancelled." -ForegroundColor Yellow
    exit 0
}

# Get script directory
$scriptDir = $PSScriptRoot

# Step 1: Backup
Write-Host ""
Write-Host "========== STEP 1/3: BACKUP ==========" -ForegroundColor Green
Write-Host ""

& "$scriptDir\backup-data.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backup failed! Aborting flow." -ForegroundColor Red
    exit 1
}

# Get the backup file name (most recent backup_data_only_ordered_*.sql)
$backupFile = Get-ChildItem -Path $scriptDir -Filter "backup_data_only_ordered_*.sql" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if (-not $backupFile) {
    Write-Host "No backup file found! Aborting flow." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Backup file: $($backupFile.Name)" -ForegroundColor Cyan
Write-Host ""

# Step 2: Drop rows
Write-Host "========== STEP 2/3: DROP ROWS ==========" -ForegroundColor Yellow
Write-Host ""

# Auto-confirm for drop-row
$env:AUTO_CONFIRM = "TRUNCATE"
& "$scriptDir\drop-row.ps1"
$env:AUTO_CONFIRM = $null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Drop rows failed! Aborting flow." -ForegroundColor Red
    Write-Host "You may need to restore manually: .\restore-db.ps1 $($backupFile.Name) 4" -ForegroundColor Yellow
    exit 1
}

# Step 3: Restore
Write-Host ""
Write-Host "========== STEP 3/3: RESTORE ==========" -ForegroundColor Green
Write-Host ""

# Auto-confirm for restore
$env:AUTO_CONFIRM = "yes"
& "$scriptDir\restore-db.ps1" $backupFile.FullName 4
$env:AUTO_CONFIRM = $null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Restore failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  FLOW 1 COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Backup file: $($backupFile.Name)" -ForegroundColor Gray
Write-Host "  - All tables truncated and restored" -ForegroundColor Gray
