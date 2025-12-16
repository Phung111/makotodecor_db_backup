# Solutions for Database Backup/Restore Foreign Key Issues

## Problem
When restoring a data-only backup, foreign key constraint violations occur because:
1. **Circular dependencies**: 
   - `categories` → `imgs` (img_id)
   - `imgs` → `products` (product_id, nullable)
   - `products` → `categories` (category_id)
   - `colors` → `imgs` (img_id, nullable) and `products` (product_id)
2. **Bidirectional relationships**:
   - `users` ↔ `carts` (cart_id)
   - `users` ↔ `orders` (order_id)
3. **pg_dump** doesn't guarantee optimal insert order for data-only backups

## Solutions

### Solution 1: Defer Constraints (RECOMMENDED ⭐)
**Best for**: Regular users without superuser permissions

**How it works**: Use `SET CONSTRAINTS ALL DEFERRED` to defer FK checks until commit.

**Pros**:
- Works with regular user permissions
- No need to modify backup file
- Safe and reliable
- Constraints still validated at commit

**Cons**:
- Requires transaction (all or nothing)

**Usage**:
```powershell
.\restore-db-v2.ps1 backup_data_only_20251216_140519.sql 2
```

**Implementation**: See `restore-db-v2.ps1` Method 2

---

### Solution 2: Disable Triggers
**Best for**: Users with ALTER TABLE permissions

**How it works**: Temporarily disable all triggers (including FK constraint triggers).

**Pros**:
- Allows out-of-order inserts
- Re-enables automatically

**Cons**:
- Requires `ALTER TABLE` permission
- May not work on Neon (limited permissions)

**Usage**:
```powershell
.\restore-db-v2.ps1 backup_data_only_20251216_140519.sql 1
```

**Implementation**: See `restore-db-v2.ps1` Method 1

---

### Solution 3: Ordered Backup
**Best for**: Preventing issues at backup time

**How it works**: Create backup with tables in dependency order.

**Pros**:
- Prevents issues before they occur
- Easier restore process
- Works with any restore method

**Cons**:
- Need to remember to use ordered backup script
- Slightly more complex backup process

**Usage**:
```powershell
.\backup-data-only-ordered.ps1
.\restore-db.ps1 backup_data_only_ordered_*.sql
```

**Implementation**: See `backup-data-only-ordered.ps1`

---

### Solution 4: Modify Constraints to DEFERRABLE (Database Schema Change)
**Best for**: Long-term solution, requires schema migration

**How it works**: Alter FK constraints to be `DEFERRABLE INITIALLY DEFERRED`.

**Pros**:
- Permanent solution
- No script modifications needed
- Works automatically

**Cons**:
- Requires schema migration
- Need to modify existing constraints

**SQL Example**:
```sql
-- Make all FK constraints deferrable
ALTER TABLE categories 
  DROP CONSTRAINT fk_categories_img,
  ADD CONSTRAINT fk_categories_img 
    FOREIGN KEY (img_id) REFERENCES imgs(id) 
    DEFERRABLE INITIALLY DEFERRED;

-- Repeat for all FK constraints
```

---

### Solution 5: Use Full Backup Instead of Data-Only
**Best for**: Complete database backup/restore

**How it works**: Use `pg_dump` without `--data-only` flag.

**Pros**:
- Includes schema and data
- pg_dump handles dependencies automatically
- No FK issues

**Cons**:
- Larger backup files
- Includes schema changes (may not want this)
- Need to drop/recreate schema

**Usage**:
```powershell
.\backup-db.ps1  # Full backup
.\restore-db.ps1 backup_*.sql
```

---

## Recommended Approach

1. **For regular backups**: Use **Solution 1 (Defer Constraints)** - update `restore-db.ps1` to use Method 2
2. **For new backups**: Use **Solution 3 (Ordered Backup)** - use `backup-data-only-ordered.ps1`
3. **For long-term**: Consider **Solution 4 (DEFERRABLE constraints)** - modify schema migration

## Quick Fix for Current Script

Update `restore-db.ps1` to use deferred constraints:

```powershell
# Replace the disableTriggersSQL section with:
$deferConstraintsSQL = @"
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
"@

$commitSQL = @"
COMMIT;
"@

$restoreScript = $deferConstraintsSQL + "`n" + $backupContent + "`n" + $commitSQL
```
