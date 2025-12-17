# Drop All Rows Script using Docker
# This script truncates all tables but keeps the schema structure
# Usage: .\drop-row.ps1
#
# This will DELETE ALL DATA but keep tables, indexes, constraints intact

# Import config
. "$PSScriptRoot\config.ps1"

Write-Host "=== DROP ALL ROWS (TRUNCATE) ===" -ForegroundColor Yellow
Show-Config
Write-Host ""
Write-Host "WARNING: This will DELETE ALL DATA in all tables!" -ForegroundColor Red
Write-Host "Schema structure (tables, indexes, constraints) will be preserved." -ForegroundColor Yellow
Write-Host ""

# Support auto-confirm from flow scripts
if ($env:AUTO_CONFIRM -eq "TRUNCATE") {
    $confirm = "TRUNCATE"
    Write-Host "Auto-confirmed: TRUNCATE" -ForegroundColor Gray
} else {
    $confirm = Read-Host "Are you sure you want to continue? Type 'TRUNCATE' to confirm"
}

if ($confirm -ne "TRUNCATE") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

# Check if Docker is running
if (-not (Test-DockerRunning)) {
    exit 1
}

# Get current directory for volume mount
$currentDir = (Get-Location).Path

# SQL to truncate all tables dynamically
$truncateSQL = @"
-- Truncate all tables in public schema (keeps structure)
DO `$`$ 
DECLARE 
    r RECORD;
    truncated_count INT := 0;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' CASCADE';
        RAISE NOTICE 'Truncated: %', r.tablename;
        truncated_count := truncated_count + 1;
    END LOOP;
    RAISE NOTICE 'Total tables truncated: %', truncated_count;
END `$`$;

-- Confirmation
SELECT 'All rows deleted successfully' AS status;
"@

# Write SQL to temp file
$tempSqlFile = "temp_drop_row.sql"
[System.IO.File]::WriteAllText($tempSqlFile, $truncateSQL, [System.Text.UTF8Encoding]::new($false))

Write-Host "`nTruncating all tables..." -ForegroundColor Yellow

# Execute SQL
$output = docker run --rm `
    -e PGPASSWORD=$DB_PASSWORD `
    -v "${currentDir}:/backup" `
    postgres:$POSTGRES_VERSION `
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f /backup/$tempSqlFile 2>&1

# Display output
$output | ForEach-Object { Write-Host $_ }

# Clean up temp file
Remove-Item $tempSqlFile -ErrorAction SilentlyContinue

# Check for errors
$outputString = $output -join "`n"
if ($outputString -match "ERROR:") {
    Write-Host "`nTruncate FAILED!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n=== ALL ROWS DELETED SUCCESSFULLY ===" -ForegroundColor Green
    Write-Host "Schema structure is preserved." -ForegroundColor Cyan
}
