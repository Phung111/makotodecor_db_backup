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

# Build pg_dump commands - dump each table separately to maintain order
# pg_dump doesn't respect the order of multiple -t arguments, so we dump individually
Write-Host "`nBacking up tables in dependency order..." -ForegroundColor Yellow
Write-Host "Order: $($tableOrder -join ', ')" -ForegroundColor Cyan

# Create header for backup file
$headerSQL = @"
--
-- PostgreSQL database dump (Data Only - Ordered)
-- Dumped from database version 17.7
-- Dumped by pg_dump version 17.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

"@

# Write header to file
[System.IO.File]::WriteAllText($BACKUP_FILE, $headerSQL, [System.Text.UTF8Encoding]::new($false))

# Dump each table in order and append to file
$backupFailed = $false
foreach ($table in $tableOrder) {
    Write-Host "  Dumping table: $table" -ForegroundColor Gray
    $tempDumpFile = "temp_${table}_dump.sql"
    
    # Dump single table
    docker run --rm `
        -e PGPASSWORD=$DB_PASSWORD `
        -v "${currentDir}:/backup" `
        postgres:17 `
        sh -c "pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME --data-only --encoding=UTF8 -t public.$table > /backup/$tempDumpFile"
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $tempDumpFile)) {
        # Read the temp dump file
        $tableLines = Get-Content $tempDumpFile -Encoding UTF8
        
        # Extract COPY block and sequence set for this table
        $inCopyBlock = $false
        $copyBlock = @()
        $sequenceBlock = @()
        
        foreach ($line in $tableLines) {
            # Skip header lines (SET statements, etc.)
            if ($line -match "^SET |^SELECT pg_catalog\.set_config|^--|^$") {
                if (-not $inCopyBlock) {
                    continue
                }
            }
            
            # Start of COPY block for this table
            if ($line -match "COPY public\.$table") {
                $inCopyBlock = $true
                $copyBlock = @($line)
                continue
            }
            
            # End of COPY block
            if ($inCopyBlock -and $line -match "^\\\.$") {
                $copyBlock += $line
                $inCopyBlock = $false
                continue
            }
            
            # Collect COPY data lines
            if ($inCopyBlock) {
                $copyBlock += $line
                continue
            }
            
            # Collect sequence set for this table
            if ($line -match "SELECT pg_catalog\.setval.*$table") {
                $sequenceBlock += $line
            }
        }
        
        # Append to backup file if we have data
        if ($copyBlock.Count -gt 0) {
            Add-Content -Path $BACKUP_FILE -Value "`n-- Data for Name: $table; Type: TABLE DATA; Schema: public; Owner: $DB_USER`n" -Encoding UTF8
            $copyBlock | Add-Content -Path $BACKUP_FILE -Encoding UTF8
        }
        
        # Append sequence set if exists
        if ($sequenceBlock.Count -gt 0) {
            Add-Content -Path $BACKUP_FILE -Value "`n-- Name: ${table}_id_seq; Type: SEQUENCE SET; Schema: public; Owner: $DB_USER`n" -Encoding UTF8
            $sequenceBlock | Add-Content -Path $BACKUP_FILE -Encoding UTF8
        }
        
        # Clean up temp file
        Remove-Item $tempDumpFile -ErrorAction SilentlyContinue
    } else {
        Write-Host "  Warning: Failed to dump table $table" -ForegroundColor Yellow
        $backupFailed = $true
    }
}

if ($backupFailed) {
    Write-Host "`nSome tables failed to backup!" -ForegroundColor Red
    exit 1
}

# Add footer
$footerSQL = @"

--
-- PostgreSQL database dump complete
--
"@
Add-Content -Path $BACKUP_FILE -Value $footerSQL -Encoding UTF8

if (-not $backupFailed) {
    # Remove \restrict and \unrestrict commands that cause issues in restore
    Write-Host "`nCleaning up backup file..." -ForegroundColor Yellow
    $content = Get-Content $BACKUP_FILE -Raw -Encoding UTF8
    # Remove \restrict and \unrestrict lines
    $content = $content -replace '(?m)^\\restrict.*$', '' -replace '(?m)^\\unrestrict.*$', ''
    # Remove empty lines (more than 2 consecutive)
    $content = $content -replace '(?m)^\s*$\r?\n', ''
    [System.IO.File]::WriteAllText($BACKUP_FILE, $content, [System.Text.UTF8Encoding]::new($false))
    
    $fileSize = (Get-Item $BACKUP_FILE).Length / 1MB
    Write-Host "`nBackup completed successfully!" -ForegroundColor Green
    Write-Host "File: $BACKUP_FILE" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
    Write-Host "`nNote: This backup is ordered by dependencies for easier restore." -ForegroundColor Cyan
} else {
    Write-Host "`nBackup failed!" -ForegroundColor Red
    exit 1
}
