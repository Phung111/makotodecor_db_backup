# Database Configuration File
# All scripts will import this file for common settings

# Database connection settings
$script:DB_HOST = "ep-patient-heart-ahu35yr5-pooler.c-3.us-east-1.aws.neon.tech"
$script:DB_USER = "neondb_owner"
$script:DB_NAME = "neondb"
$script:DB_PASSWORD = "npg_hlu8Cbiag6IY"

# Docker settings
$script:POSTGRES_VERSION = "17"

# Table order based on dependencies (no FK -> FK tables)
$script:TABLE_ORDER = @(
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

# Table order for Flyway flow (excludes flyway_schema_history)
$script:TABLE_ORDER_FLYWAY = @(
    "access_counts",        # No FK
    # flyway_schema_history EXCLUDED - Flyway manages it
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

# Function to check if Docker is running
function Test-DockerRunning {
    try {
        docker ps | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker is not running"
        }
        return $true
    } catch {
        Write-Host "Error: Docker is not running or not installed!" -ForegroundColor Red
        Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
        return $false
    }
}

# Function to display config info
function Show-Config {
    Write-Host "=== Database Configuration ===" -ForegroundColor Cyan
    Write-Host "Host: $DB_HOST" -ForegroundColor Gray
    Write-Host "Database: $DB_NAME" -ForegroundColor Gray
    Write-Host "User: $DB_USER" -ForegroundColor Gray
    Write-Host "===============================" -ForegroundColor Cyan
}

Write-Host "Config loaded successfully." -ForegroundColor Green
