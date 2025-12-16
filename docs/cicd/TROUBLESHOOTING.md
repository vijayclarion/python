# Troubleshooting Guide: EF Core Migrations in CI/CD

## Common Issues and Solutions

### Issue 1: "No migrations were applied" but pending migrations exist

**Symptoms:**
```
No pending migrations found.
```

But you know there are new migrations.

**Causes:**
1. Migration history table out of sync
2. Wrong connection string
3. Migration already applied manually

**Solutions:**

```bash
# Check migration history
dotnet ef migrations list --project ./src/YourProject.csproj --connection "$CONNECTION_STRING"

# Verify database connection
dotnet ef database drop --project ./src/YourProject.csproj --connection "$CONNECTION_STRING" --dry-run

# Check __EFMigrationsHistory table
SELECT * FROM __EFMigrationsHistory ORDER BY MigrationId DESC;
```

**Resolution:**
- Ensure connection string points to correct database
- Verify migration history table integrity
- Use idempotent scripts to safely re-apply

---

### Issue 2: Race condition - Multiple instances applying migrations

**Symptoms:**
```
A lock could not be obtained within the time allowed.
```

**Causes:**
- Multiple CI/CD jobs running migrations simultaneously
- Application startup migration + CI/CD migration conflict
- Multiple container instances starting at once

**Solutions:**

1. **Ensure single migration job:**
```yaml
# In GitHub Actions workflow
migrate-database:
  concurrency:
    group: migrate-${{ github.ref }}-${{ matrix.environment }}
    cancel-in-progress: false  # Don't cancel, queue instead
```

2. **Remove application startup migrations:**
```csharp
// Remove this from Program.cs
// db.Database.Migrate(); ❌
```

3. **Use migration locking:**
```csharp
// For Azure SQL Database
using (var connection = new SqlConnection(connectionString))
{
    connection.Open();
    using (var command = connection.CreateCommand())
    {
        command.CommandText = "sp_getapplock @Resource='Migration', @LockMode='Exclusive', @LockTimeout=60000";
        command.ExecuteNonQuery();
        
        // Run migration
        context.Database.Migrate();
        
        command.CommandText = "sp_releaseapplock @Resource='Migration'";
        command.ExecuteNonQuery();
    }
}
```

---

### Issue 3: Migration fails with timeout

**Symptoms:**
```
Execution Timeout Expired. The timeout period elapsed prior to completion of the operation.
```

**Causes:**
- Large data migrations
- Long-running schema changes
- Database under heavy load

**Solutions:**

1. **Increase timeout in connection string:**
```
Server=myserver;Database=mydb;User Id=user;Password=pass;Connect Timeout=300;Command Timeout=600;
```

2. **Split large migrations:**
```bash
# Break into smaller migrations
dotnet ef migrations add Migration1_AddColumn
dotnet ef migrations add Migration2_PopulateColumn
dotnet ef migrations add Migration3_AddIndex
```

3. **Run during maintenance window:**
```yaml
# Schedule for low-traffic period
on:
  schedule:
    - cron: '0 2 * * 0'  # Sunday at 2 AM
```

---

### Issue 4: "Cannot drop database because it is currently in use"

**Symptoms:**
```
Cannot drop database "MyDatabase" because it is currently in use.
```

**Causes:**
- Active connections to database
- Application still running
- Connection pooling

**Solutions:**

1. **Stop application first:**
```yaml
deploy-preprod:
  steps:
    - name: Stop application
      run: |
        # Stop existing containers/services
        kubectl scale deployment myapp --replicas=0
        
    - name: Run migrations
      run: dotnet ef database update
      
    - name: Start application
      run: kubectl scale deployment myapp --replicas=3
```

2. **Close connections before migration:**
```sql
-- SQL Server
ALTER DATABASE [MyDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
-- Run migration
ALTER DATABASE [MyDatabase] SET MULTI_USER;
```

---

### Issue 5: Connection string not recognized in CI/CD

**Symptoms:**
```
A connection string was not found in the application's configuration files.
```

**Causes:**
- Secret not configured
- Wrong environment variable name
- Syntax error in connection string

**Solutions:**

1. **Verify secret is set:**
```bash
# In GitHub Actions
echo "Connection string length: ${#CONNECTION_STRING}"
# Should show length, not actual string
```

2. **Pass explicitly:**
```yaml
- name: Run migrations
  run: |
    dotnet ef database update \
      --project ./src/YourProject.csproj \
      --connection "${{ secrets.PREPROD_CONNECTION_STRING }}"
```

3. **Check for special characters:**
```bash
# If password contains special chars, ensure proper escaping
# Use URL encoding or escape properly
```

---

### Issue 6: "Build failed" when running migrations

**Symptoms:**
```
Build failed. Use dotnet build to see the errors.
```

**Causes:**
- Compilation errors in migration code
- Missing dependencies
- Wrong .NET SDK version

**Solutions:**

1. **Build explicitly first:**
```yaml
- name: Build
  run: dotnet build --configuration Release
  
- name: Run migrations
  run: dotnet ef database update --no-build
```

2. **Check SDK version:**
```yaml
- name: Setup .NET
  uses: actions/setup-dotnet@v4
  with:
    dotnet-version: '9.0.x'  # Match your project
```

3. **Restore packages:**
```bash
dotnet restore
dotnet build
dotnet ef database update
```

---

### Issue 7: Seed data duplicates on re-runs

**Symptoms:**
Seed data is inserted multiple times, causing duplicates or unique constraint violations.

**Causes:**
- Seed logic not idempotent
- No duplicate checking

**Solutions:**

1. **Use idempotent seeding:**
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // EF Core HasData is idempotent by default
    modelBuilder.Entity<Country>().HasData(
        new Country { Id = 1, Name = "USA", Code = "US" }
    );
}
```

2. **Check before inserting:**
```csharp
public static async Task SeedDataAsync(ApplicationDbContext context)
{
    // Only seed if not already present
    if (!await context.Countries.AnyAsync())
    {
        context.Countries.AddRange(
            new Country { Name = "USA", Code = "US" },
            new Country { Name = "Canada", Code = "CA" }
        );
        await context.SaveChangesAsync();
    }
}
```

3. **Use upsert logic:**
```csharp
// For data that might need updates
var country = await context.Countries.FindAsync(1);
if (country == null)
{
    context.Countries.Add(new Country { Id = 1, Name = "USA" });
}
else
{
    country.Name = "United States";
}
await context.SaveChangesAsync();
```

---

### Issue 8: Rollback fails - data loss

**Symptoms:**
```
Cannot rollback migration: column was dropped and data is lost.
```

**Causes:**
- Destructive migration (DROP COLUMN, DROP TABLE)
- Data not backed up
- Irreversible operations

**Solutions:**

1. **Always backup before migration:**
```yaml
- name: Backup database
  run: |
    sqlcmd -S ${{ secrets.SQL_SERVER }} \
      -Q "BACKUP DATABASE [MyDb] TO DISK='/backup/db_$(date +%Y%m%d_%H%M%S).bak'"
```

2. **Use forward-only approach:**
```bash
# Instead of rolling back, create new migration to fix
dotnet ef migrations add FixPreviousMigration
```

3. **Test rollback in non-prod:**
```bash
# In dev environment
dotnet ef database update PreviousMigration
# Verify data integrity
# Test application functionality
```

4. **Restore from backup if needed:**
```sql
-- SQL Server
RESTORE DATABASE [MyDatabase] 
FROM DISK = '/backups/MyDatabase_backup.bak'
WITH REPLACE;
```

---

### Issue 9: Permission denied during migration

**Symptoms:**
```
The user does not have permission to perform this action.
CREATE TABLE permission denied.
```

**Causes:**
- Insufficient database permissions
- Using application credentials instead of migration credentials
- Restricted access in production

**Solutions:**

1. **Use dedicated migration credentials:**
```yaml
# Different secrets for migrations vs application
migrate-database:
  steps:
    - name: Run migrations
      env:
        # Migration user has DDL permissions
        CONNECTION_STRING: ${{ secrets.MIGRATION_CONNECTION_STRING }}
      run: dotnet ef database update
```

2. **Grant necessary permissions:**
```sql
-- SQL Server: Grant DDL permissions to migration user
GRANT CREATE TABLE TO migration_user;
GRANT ALTER ON SCHEMA::dbo TO migration_user;
GRANT CREATE INDEX TO migration_user;
```

3. **Verify permissions:**
```sql
-- Check current user permissions
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
```

---

### Issue 10: Docker image size too large

**Symptoms:**
Docker images are several GB in size, slow to build and deploy.

**Causes:**
- Including SDK in runtime image
- Not using multi-stage builds
- Including unnecessary files

**Solutions:**

1. **Use multi-stage builds:**
```dockerfile
# Build stage - includes SDK
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
# ... build steps ...

# Runtime stage - only includes runtime
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
COPY --from=build /app/publish .
```

2. **Use .dockerignore:**
```
**/bin/
**/obj/
**/.git/
**/TestResults/
```

3. **Verify image size:**
```bash
docker images | grep myapp
# Should be ~200-300MB for ASP.NET Core app
```

---

## Debugging Tips

### Enable verbose logging

```yaml
- name: Run migrations with verbose output
  run: |
    dotnet ef database update \
      --project ./src/YourProject.csproj \
      --connection "$CONNECTION_STRING" \
      --verbose
```

### Check migration history manually

```sql
-- See what migrations have been applied
SELECT * FROM __EFMigrationsHistory ORDER BY MigrationId;
```

### Test locally first

```bash
# Always test migrations locally before CI/CD
export CONNECTION_STRING="Server=localhost;Database=TestDb;..."
dotnet ef database update
```

### Review generated SQL

```bash
# Generate SQL script to review before applying
dotnet ef migrations script --idempotent --output review.sql
cat review.sql
```

### Monitor database during migration

```sql
-- In separate session, monitor active queries
SELECT 
    session_id,
    command,
    percent_complete,
    estimated_completion_time
FROM sys.dm_exec_requests
WHERE session_id = <your_session_id>;
```

---

## Getting Help

1. **Check logs:**
   - CI/CD pipeline logs
   - Application logs
   - Database logs

2. **Enable detailed errors:**
   ```json
   {
     "DetailedErrors": true,
     "Logging": {
       "LogLevel": {
         "Microsoft.EntityFrameworkCore": "Debug"
       }
     }
   }
   ```

3. **Test in isolation:**
   - Create separate test database
   - Run migration manually
   - Verify each step

4. **Consult documentation:**
   - [EF Core Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/)
   - [GitHub Actions](https://docs.github.com/en/actions)
   - [Docker](https://docs.docker.com/)

---

**Last Updated:** December 2024
