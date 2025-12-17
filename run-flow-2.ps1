# Flow 2: Flyway Flow (Backup → Drop All → Run Java/Flyway → Restore)
# This script runs the Flyway-compatible flow:
#   1. backup-data-flyway.ps1 (backup data WITHOUT flyway_schema_history)
#   2. drop-all.ps1 (drop entire schema)
#   3. [MANUAL] Run Java app to let Flyway create schema
#   4. restore-db.ps1 (restore data from backup)
#
# Usage: .\run-flow-2.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  FLOW 2: Flyway Flow" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This flow will:" -ForegroundColor Yellow
Write-Host "  1. Backup data (WITHOUT flyway_schema_history)" -ForegroundColor Gray
Write-Host "  2. Drop entire schema (CASCADE)" -ForegroundColor Gray
Write-Host "  3. [PAUSE] You run Java app (Flyway creates schema + base data)" -ForegroundColor Yellow
Write-Host "  4. Restore data from backup" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Start Flow 2? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Flow cancelled." -ForegroundColor Yellow
    exit 0
}

# Get script directory
$scriptDir = $PSScriptRoot

# Step 1: Backup
Write-Host ""
Write-Host "========== STEP 1/4: BACKUP FOR FLYWAY ==========" -ForegroundColor Green
Write-Host ""

& "$scriptDir\backup-data-flyway.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backup failed! Aborting flow." -ForegroundColor Red
    exit 1
}

# Get the backup file name (most recent backup_for_flyway_*.sql)
$backupFile = Get-ChildItem -Path $scriptDir -Filter "backup_for_flyway_*.sql" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if (-not $backupFile) {
    Write-Host "No backup file found! Aborting flow." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Backup file: $($backupFile.Name)" -ForegroundColor Cyan
Write-Host ""

# Step 2: Drop all schema
Write-Host "========== STEP 2/4: DROP ALL SCHEMA ==========" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: This will drop the ENTIRE schema!" -ForegroundColor Red
Write-Host ""

$dropConfirm = Read-Host "Type 'DROP' to confirm dropping the schema"
if ($dropConfirm -ne "DROP") {
    Write-Host "Drop cancelled. Aborting flow." -ForegroundColor Yellow
    Write-Host "Backup file is saved: $($backupFile.Name)" -ForegroundColor Cyan
    exit 0
}

# Run drop-all with confirmation already done
$dropSQL = @"
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO neondb_owner;
GRANT ALL ON SCHEMA public TO public;
SELECT 'Schema dropped and recreated successfully' AS status;
"@

$tempDropFile = "temp_drop_all_flow2.sql"
[System.IO.File]::WriteAllText($tempDropFile, $dropSQL, [System.Text.UTF8Encoding]::new($false))

$currentDir = (Get-Location).Path
$output = docker run --rm `
    -e PGPASSWORD="npg_hlu8Cbiag6IY" `
    -v "${currentDir}:/backup" `
    postgres:17 `
    psql -h "ep-patient-heart-ahu35yr5-pooler.c-3.us-east-1.aws.neon.tech" -U "neondb_owner" -d "neondb" -f /backup/$tempDropFile 2>&1

$output | ForEach-Object { Write-Host $_ }
Remove-Item $tempDropFile -ErrorAction SilentlyContinue

$outputString = $output -join "`n"
if ($outputString -match "ERROR:") {
    Write-Host "`nDrop schema failed! Aborting flow." -ForegroundColor Red
    exit 1
}

Write-Host "`nSchema dropped successfully!" -ForegroundColor Green

# Step 3: Pause for Java/Flyway
Write-Host ""
Write-Host "========== STEP 3/4: RUN JAVA APP (FLYWAY) ==========" -ForegroundColor Yellow
Write-Host ""
Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│                                                         │" -ForegroundColor Cyan
Write-Host "│   NOW RUN YOUR JAVA APPLICATION!                       │" -ForegroundColor Yellow
Write-Host "│                                                         │" -ForegroundColor Cyan
Write-Host "│   Flyway will:                                          │" -ForegroundColor Cyan
Write-Host "│   - Create all tables                                   │" -ForegroundColor Gray
Write-Host "│   - Create indexes and constraints                      │" -ForegroundColor Gray
Write-Host "│   - Insert base data                                    │" -ForegroundColor Gray
Write-Host "│   - Create flyway_schema_history                        │" -ForegroundColor Gray
Write-Host "│                                                         │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

$flywayDone = Read-Host "After running Java app, type 'DONE' to continue with restore"
if ($flywayDone -ne "DONE") {
    Write-Host "Flow paused." -ForegroundColor Yellow
    Write-Host "To continue later, run: .\restore-db.ps1 $($backupFile.Name) 4" -ForegroundColor Cyan
    exit 0
}

# Step 4: Restore
Write-Host ""
Write-Host "========== STEP 4/4: RESTORE DATA ==========" -ForegroundColor Green
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
Write-Host "  FLOW 2 COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Backup file: $($backupFile.Name)" -ForegroundColor Gray
Write-Host "  - Schema recreated by Flyway" -ForegroundColor Gray
Write-Host "  - Data restored from backup" -ForegroundColor Gray
Write-Host "  - flyway_schema_history managed by Flyway" -ForegroundColor Gray
