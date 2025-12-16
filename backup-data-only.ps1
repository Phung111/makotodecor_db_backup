# Database Backup Script (Data Only) using Docker
# Usage: .\backup-data-only.ps1

$DB_HOST = "ep-patient-heart-ahu35yr5-pooler.c-3.us-east-1.aws.neon.tech"
$DB_USER = "neondb_owner"
$DB_NAME = "neondb"
$DB_PASSWORD = "npg_hlu8Cbiag6IY"
$BACKUP_FILE = "backup_data_only_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

Write-Host "Starting database backup (data only)..." -ForegroundColor Green
Write-Host "Host: $DB_HOST" -ForegroundColor Cyan
Write-Host "Database: $DB_NAME" -ForegroundColor Cyan
Write-Host "Output file: $BACKUP_FILE" -ForegroundColor Cyan

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

# Set UTF-8 encoding for PowerShell
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Get current directory for volume mount
$currentDir = (Get-Location).Path

# Run pg_dump using Docker (use postgres:17 to match Neon's PostgreSQL 17.7)
# Use volume mount to avoid encoding issues with pipe
# Write directly to file inside container, then copy out
docker run --rm `
    -e PGPASSWORD=$DB_PASSWORD `
    -v "${currentDir}:/backup" `
    postgres:17 `
    sh -c "pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME --data-only --encoding=UTF8 > /backup/$BACKUP_FILE"

if ($LASTEXITCODE -eq 0) {
    $fileSize = (Get-Item $BACKUP_FILE).Length / 1MB
    Write-Host "`nBackup completed successfully!" -ForegroundColor Green
    Write-Host "File: $BACKUP_FILE" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "`nBackup failed!" -ForegroundColor Red
    exit 1
}
