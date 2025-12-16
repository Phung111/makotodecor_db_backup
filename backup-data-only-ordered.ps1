# Database Backup Script (Data Only - Ordered) using Docker
# This script creates a backup with data ordered by dependency to avoid FK issues
# Usage: .\backup-data-only-ordered.ps1

$DB_HOST = "ep-patient-heart-ahu35yr5-pooler.c-3.us-east-1.aws.neon.tech"
$DB_USER = "neondb_owner"
$DB_NAME = "neondb"
$DB_PASSWORD = "npg_hlu8Cbiag6IY"
$BACKUP_FILE = "backup_data_only_ordered_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

Write-Host "Starting database backup (data only - ordered)..." -ForegroundColor Green
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

# Define table order based on dependencies (no FK -> FK tables)
# Order: tables without FKs first, then tables with FKs
$tableOrder = @(
    "access_counts",      # No FK
    "img_types",          # No FK
    "users",              # No FK (cart_id and order_id are nullable initially)
    "imgs",               # FK: img_type_id (nullable), product_id (nullable)
    "categories",         # FK: img_id (nullable)
    "products",           # FK: category_id
    "colors",             # FK: product_id, img_id (nullable)
    "sizes",              # FK: product_id
    "carts",              # FK: user_id
    "cart_items",         # FK: cart_id, product_id, size_id, color_id
    "orders",             # FK: user_id
    "order_groups",       # FK: order_id, product_id
    "order_items",        # FK: order_id, product_id, order_group_id
    "flyway_schema_history" # No FK
)

# Build pg_dump command with table order
$tableList = $tableOrder -join " -t public."
$pgDumpCmd = "pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME --data-only --encoding=UTF8 -t public.$($tableList -replace ' ', ' -t public.') > /backup/$BACKUP_FILE"

Write-Host "`nBacking up tables in dependency order..." -ForegroundColor Yellow
Write-Host "Order: $($tableOrder -join ', ')" -ForegroundColor Cyan

# Run pg_dump using Docker
docker run --rm `
    -e PGPASSWORD=$DB_PASSWORD `
    -v "${currentDir}:/backup" `
    postgres:17 `
    sh -c $pgDumpCmd

if ($LASTEXITCODE -eq 0) {
    $fileSize = (Get-Item $BACKUP_FILE).Length / 1MB
    Write-Host "`nBackup completed successfully!" -ForegroundColor Green
    Write-Host "File: $BACKUP_FILE" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
    Write-Host "`nNote: This backup is ordered by dependencies for easier restore." -ForegroundColor Cyan
} else {
    Write-Host "`nBackup failed!" -ForegroundColor Red
    exit 1
}
