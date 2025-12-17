# Drop All Schema Script using Docker
# This script drops all tables and recreates the public schema
# Usage: .\drop-all.ps1
#
# WARNING: This will DELETE ALL DATA and SCHEMA in the database!

$DB_HOST = "ep-patient-heart-ahu35yr5-pooler.c-3.us-east-1.aws.neon.tech"
$DB_USER = "neondb_owner"
$DB_NAME = "neondb"
$DB_PASSWORD = "npg_hlu8Cbiag6IY"

Write-Host "=== DROP ALL SCHEMA ===" -ForegroundColor Red
Write-Host "Host: $DB_HOST" -ForegroundColor Cyan
Write-Host "Database: $DB_NAME" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will DELETE ALL DATA and SCHEMA in the database!" -ForegroundColor Red
Write-Host "This action CANNOT be undone!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Are you sure you want to continue? Type 'DROP' to confirm"

if ($confirm -ne "DROP") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
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

# Get current directory for volume mount
$currentDir = (Get-Location).Path

# SQL to drop and recreate schema
$dropAllSQL = @"
-- Drop all objects in public schema
DROP SCHEMA public CASCADE;

-- Recreate public schema
CREATE SCHEMA public;

-- Grant permissions (for Neon, user is the owner)
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL ON SCHEMA public TO public;

-- Confirmation
SELECT 'Schema dropped and recreated successfully' AS status;
"@

# Write SQL to temp file
$tempSqlFile = "temp_drop_all.sql"
[System.IO.File]::WriteAllText($tempSqlFile, $dropAllSQL, [System.Text.UTF8Encoding]::new($false))

Write-Host "`nDropping all schema..." -ForegroundColor Yellow

# Execute SQL
$output = docker run --rm `
    -e PGPASSWORD=$DB_PASSWORD `
    -v "${currentDir}:/backup" `
    postgres:17 `
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f /backup/$tempSqlFile 2>&1

# Display output
$output | ForEach-Object { Write-Host $_ }

# Clean up temp file
Remove-Item $tempSqlFile -ErrorAction SilentlyContinue

# Check for errors
$outputString = $output -join "`n"
if ($outputString -match "ERROR:") {
    Write-Host "`nDrop schema FAILED!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n=== SCHEMA DROPPED SUCCESSFULLY ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run your Java app to let Flyway create schema and base data" -ForegroundColor Cyan
    Write-Host "  2. Run: .\restore-db-v2.ps1 <backup-file>.sql 4" -ForegroundColor Cyan
}
