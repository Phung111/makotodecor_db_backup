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
    "access_counts",        # No FK
    "flyway_schema_history",# No FK
    "img_types",            # No FK
    "users",                # cart_id, order_id nullable
    "imgs",                 # img_type_id nullable, product_id nullable
    "categories",           # img_id -> imgs
    "products",             # category_id -> categories
    "sizes",                # product_id -> products
    "colors",               # product_id -> products, img_id -> imgs
    "carts",                # user_id -> users
    "cart_items",           # cart_id, product_id, size_id, color_id
    "orders",               # user_id -> users
    "order_groups",         # order_id -> orders, product_id -> products
    "order_items"           # order_id, order_group_id, product_id
)

# Build pg_dump commands - dump each table separately to maintain order
# pg_dump doesn't respect the order of multiple -t arguments, so we dump individually
Write-Host "`nBacking up tables in dependency order..." -ForegroundColor Yellow
Write-Host "Order: $($tableOrder -join ', ')" -ForegroundColor Cyan

# Create header for backup file
# Note: Tables are ordered by dependency to avoid FK constraint violations
$headerSQL = @"
--
-- PostgreSQL database dump (Data Only - Ordered by Dependencies)
-- Dumped from database version 17.7
-- Dumped by pg_dump version 17.7
-- Tables are ordered to respect foreign key constraints

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

# Storage for circular reference handling
# imgs.product_id -> products.id (circular with categories)
$imgsProductIdMapping = @{}

# Dump each table in order and append to file
$tablesBackedUp = 0
$tablesSkipped = 0
foreach ($table in $tableOrder) {
    Write-Host "  Dumping table: $table" -ForegroundColor Gray
    $tempDumpFile = "temp_${table}_dump.sql"
    $tempErrFile = "temp_${table}_err.txt"
    
    # Dump single table (capture stderr to check if table exists)
    docker run --rm `
        -e PGPASSWORD=$DB_PASSWORD `
        -v "${currentDir}:/backup" `
        postgres:17 `
        sh -c "pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME --data-only --encoding=UTF8 -t public.$table > /backup/$tempDumpFile 2> /backup/$tempErrFile"
    
    # Check if table doesn't exist (skip instead of fail)
    $tableNotFound = $false
    if (Test-Path $tempErrFile) {
        $errContent = Get-Content $tempErrFile -Raw -ErrorAction SilentlyContinue
        if ($errContent -match "no matching tables were found") {
            $tableNotFound = $true
            Write-Host "    Skipped: Table '$table' does not exist in database" -ForegroundColor DarkYellow
            $tablesSkipped++
        }
        Remove-Item $tempErrFile -ErrorAction SilentlyContinue
    }
    
    if (-not $tableNotFound -and (Test-Path $tempDumpFile)) {
        # Read the temp dump file
        $tableLines = Get-Content $tempDumpFile -Encoding UTF8
        
        # Extract COPY block and sequence set for this table
        $inCopyBlock = $false
        $copyBlock = @()
        $sequenceBlock = @()
        $productIdColumnIndex = -1
        
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
                
                # For imgs table: find product_id column index to handle circular reference
                if ($table -eq "imgs" -and $line -match "COPY public\.imgs \(([^)]+)\)") {
                    $columns = $matches[1] -split ",\s*"
                    for ($i = 0; $i -lt $columns.Count; $i++) {
                        if ($columns[$i].Trim() -eq "product_id") {
                            $productIdColumnIndex = $i
                            Write-Host "    Handling circular reference: imgs.product_id (column index $i)" -ForegroundColor Cyan
                            break
                        }
                    }
                }
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
                # Special handling for imgs table: set product_id to NULL and save for later UPDATE
                if ($table -eq "imgs" -and $productIdColumnIndex -ge 0) {
                    $fields = $line -split "`t"
                    if ($fields.Count -gt $productIdColumnIndex) {
                        $imgId = $fields[0]
                        $productId = $fields[$productIdColumnIndex]
                        
                        # If product_id is not NULL, save it for UPDATE later
                        if ($productId -ne "\N" -and $productId -ne "") {
                            $imgsProductIdMapping[$imgId] = $productId
                            # Set product_id to NULL in COPY data
                            $fields[$productIdColumnIndex] = "\N"
                            $line = $fields -join "`t"
                        }
                    }
                }
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
            $tablesBackedUp++
            
            # Show circular reference handling info
            if ($table -eq "imgs" -and $imgsProductIdMapping.Count -gt 0) {
                Write-Host "    Saved $($imgsProductIdMapping.Count) imgs.product_id values for UPDATE after products" -ForegroundColor Cyan
            }
        }
        
        # After products table: add UPDATE statements to restore imgs.product_id
        if ($table -eq "products" -and $imgsProductIdMapping.Count -gt 0) {
            Write-Host "  Adding UPDATE statements for imgs.product_id (circular reference fix)..." -ForegroundColor Cyan
            
            $updateStatements = @()
            $updateStatements += ""
            $updateStatements += "-- Fix circular reference: Update imgs.product_id after products are inserted"
            
            # Group by product_id to create fewer UPDATE statements
            $productIdToImgIds = @{}
            foreach ($entry in $imgsProductIdMapping.GetEnumerator()) {
                $imgId = $entry.Key
                $productId = $entry.Value
                if (-not $productIdToImgIds.ContainsKey($productId)) {
                    $productIdToImgIds[$productId] = @()
                }
                $productIdToImgIds[$productId] += $imgId
            }
            
            foreach ($entry in $productIdToImgIds.GetEnumerator()) {
                $productId = $entry.Key
                $imgIds = $entry.Value -join ", "
                $updateStatements += "UPDATE public.imgs SET product_id = $productId WHERE id IN ($imgIds);"
            }
            
            $updateStatements += ""
            
            Add-Content -Path $BACKUP_FILE -Value ($updateStatements -join "`n") -Encoding UTF8
            Write-Host "    Added $($productIdToImgIds.Count) UPDATE statements" -ForegroundColor Green
        }
        
        # Append sequence set if exists
        if ($sequenceBlock.Count -gt 0) {
            Add-Content -Path $BACKUP_FILE -Value "`n-- Name: ${table}_id_seq; Type: SEQUENCE SET; Schema: public; Owner: $DB_USER`n" -Encoding UTF8
            $sequenceBlock | Add-Content -Path $BACKUP_FILE -Encoding UTF8
        }
        
        # Clean up temp file
        Remove-Item $tempDumpFile -ErrorAction SilentlyContinue
    } elseif (-not $tableNotFound) {
        # Clean up temp file if exists
        Remove-Item $tempDumpFile -ErrorAction SilentlyContinue
    }
}

Write-Host "`nBackup summary:" -ForegroundColor Yellow
Write-Host "  Tables backed up: $tablesBackedUp" -ForegroundColor Green
Write-Host "  Tables skipped (not found): $tablesSkipped" -ForegroundColor DarkYellow

# Add footer
$footerSQL = @"

--
-- PostgreSQL database dump complete (ordered by dependencies)
--
"@
Add-Content -Path $BACKUP_FILE -Value $footerSQL -Encoding UTF8

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
Write-Host "`nNote: Tables are ordered by dependency. Circular references (imgs.product_id) are handled automatically." -ForegroundColor Cyan
Write-Host "Use: .\restore-db.ps1 $BACKUP_FILE 4" -ForegroundColor Cyan
