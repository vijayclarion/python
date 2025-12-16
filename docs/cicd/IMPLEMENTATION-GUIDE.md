# Implementation Guide: EF Core Migrations in CI/CD

## Step-by-Step Implementation

This guide provides detailed steps to implement the recommended EF Core migration strategy in your CI/CD pipeline.

---

## Phase 1: Preparation (2-4 hours)

### Step 1.1: Review Current Implementation

**Action Items:**
1. Identify where migrations are currently executed
2. Document current deployment process
3. Identify all environments (dev, test, preprod, production)
4. Review current database access patterns

**Checklist:**
- [ ] Document current migration execution location (startup, manual, etc.)
- [ ] List all database connection strings by environment
- [ ] Identify who has database access
- [ ] Document current backup procedures
- [ ] Review current rollback procedures

**Expected Output:** Current state documentation

---

### Step 1.2: Remove Application Startup Migrations

**Action:** Remove automatic migration execution from application code

**Before:**
```csharp
// Program.cs or Startup.cs
public class Program
{
    public static void Main(string[] args)
    {
        var host = CreateHostBuilder(args).Build();
        
        // ❌ Remove this
        using (var scope = host.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            db.Database.Migrate();
        }
        
        host.Run();
    }
}
```

**After:**
```csharp
// Program.cs or Startup.cs
public class Program
{
    public static void Main(string[] args)
    {
        var host = CreateHostBuilder(args).Build();
        
        // ✅ Migrations handled by CI/CD pipeline
        // Application only connects to already-migrated database
        
        host.Run();
    }
}
```

**Testing:**
1. Remove migration code
2. Build and test locally against already-migrated database
3. Verify application starts without running migrations
4. Confirm no errors in logs

**Checklist:**
- [ ] Removed automatic migration code
- [ ] Application builds successfully
- [ ] Application starts without errors
- [ ] Unit tests pass
- [ ] Integration tests pass (with pre-migrated database)

---

### Step 1.3: Prepare Database Credentials

**Action:** Create separate credentials for migrations and application

**SQL Server Example:**
```sql
-- Create migration user (has DDL permissions)
CREATE LOGIN migration_user WITH PASSWORD = 'Strong!Password123';
CREATE USER migration_user FOR LOGIN migration_user;
GRANT CREATE TABLE TO migration_user;
GRANT ALTER ON SCHEMA::dbo TO migration_user;
GRANT CREATE INDEX TO migration_user;

-- Create application user (only DML permissions)
CREATE LOGIN app_user WITH PASSWORD = 'Different!Password456';
CREATE USER app_user FOR LOGIN app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO app_user;
```

**PostgreSQL Example:**
```sql
-- Create migration user
CREATE USER migration_user WITH PASSWORD 'Strong!Password123';
GRANT CREATE ON DATABASE mydb TO migration_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO migration_user;

-- Create application user
CREATE USER app_user WITH PASSWORD 'Different!Password456';
GRANT CONNECT ON DATABASE mydb TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
```

**Checklist:**
- [ ] Migration user created with DDL permissions
- [ ] Application user created with only DML permissions
- [ ] Connection strings prepared for each user
- [ ] Passwords meet security requirements
- [ ] Credentials documented securely

---

## Phase 2: CI/CD Pipeline Setup (4-6 hours)

### Step 2.1: Configure GitHub Secrets

**Action:** Add secrets to GitHub repository

**Navigate to:** Repository → Settings → Secrets and variables → Actions

**Add these secrets:**

**PreProd Environment:**
```
PREPROD_CONNECTION_STRING = Server=preprod-sql.database.windows.net;Database=MyAppDb;User Id=migration_user;Password=Strong!Password123;Encrypt=True;
PREPROD_APP_CONNECTION_STRING = Server=preprod-sql.database.windows.net;Database=MyAppDb;User Id=app_user;Password=Different!Password456;Encrypt=True;
```

**Production Environment:**
```
PROD_CONNECTION_STRING = Server=prod-sql.database.windows.net;Database=MyAppDb;User Id=migration_user;Password=Strong!Password123;Encrypt=True;
PROD_APP_CONNECTION_STRING = Server=prod-sql.database.windows.net;Database=MyAppDb;User Id=app_user;Password=Different!Password456;Encrypt=True;
```

**Checklist:**
- [ ] All secrets added to GitHub
- [ ] Secret names match workflow YAML
- [ ] Connection strings tested and verified
- [ ] No typos in connection strings
- [ ] Secrets are environment-specific

---

### Step 2.2: Configure Environment Protection

**Action:** Set up environment protection rules

**Navigate to:** Repository → Settings → Environments

**For PreProd environment:**
- Deployment branches: `develop` only
- Environment secrets: Use PreProd secrets
- No reviewers required (auto-deploy)

**For Production environment:**
- Deployment branches: `main` only
- Required reviewers: 2 reviewers (specify team members)
- Wait timer: 5 minutes (optional)
- Environment secrets: Use Production secrets

**Checklist:**
- [ ] PreProd environment configured
- [ ] Production environment configured
- [ ] Required reviewers assigned
- [ ] Deployment branch restrictions set
- [ ] Environment URLs configured

---

### Step 2.3: Customize the Workflow File

**Action:** Copy and customize the provided workflow

**File location:** `.github/workflows/dotnet-cicd-with-migrations.yml`

**Customizations needed:**

1. **Update project paths:**
```yaml
# Replace './src/YourProject.csproj' with actual path
- name: Generate migration SQL scripts
  run: |
    dotnet ef migrations script --idempotent \
      --output migrations.sql \
      --project ./src/MyActualProject/MyActualProject.csproj
```

2. **Update image registry:**
```yaml
env:
  REGISTRY: ghcr.io  # or your registry
  IMAGE_NAME: ${{ github.repository }}
```

3. **Add deployment commands:**
```yaml
- name: Deploy Docker image
  run: |
    # Replace with your deployment method
    # Example for Azure Container Apps:
    az containerapp update \
      --name myapp \
      --resource-group myresourcegroup \
      --image ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

4. **Add backup commands (Production only):**
```yaml
- name: Create database backup
  run: |
    # SQL Server example
    sqlcmd -S ${{ secrets.PROD_SQL_SERVER }} \
      -U ${{ secrets.PROD_SQL_USER }} \
      -P ${{ secrets.PROD_SQL_PASSWORD }} \
      -Q "BACKUP DATABASE [MyAppDb] TO DISK = '/backups/MyAppDb_$(date +%Y%m%d_%H%M%S).bak'"
```

5. **Add health check URL:**
```yaml
- name: Health check
  run: |
    sleep 30
    curl -f https://myapp.com/health || exit 1
```

**Checklist:**
- [ ] Project paths updated
- [ ] Registry configuration correct
- [ ] Deployment commands added
- [ ] Backup commands configured (production)
- [ ] Health check URL configured
- [ ] Notification logic added (optional)

---

### Step 2.4: Update Dockerfile

**Action:** Ensure Dockerfile follows best practices

**Use the provided example:** `docs/cicd/Dockerfile.example`

**Key points:**
- Multi-stage build
- Non-root user
- No migration execution
- Health check configured

**Checklist:**
- [ ] Using multi-stage build
- [ ] Running as non-root user
- [ ] No migrations in Dockerfile
- [ ] Health check configured
- [ ] .dockerignore configured
- [ ] Build tested locally

---

## Phase 3: Testing (4-8 hours)

### Step 3.1: Test in Development

**Action:** Test the complete workflow in development environment

**Steps:**
```bash
# 1. Create a test migration
dotnet ef migrations add TestMigration --project ./src/YourProject.csproj

# 2. Generate SQL script
dotnet ef migrations script --idempotent --output test-migration.sql --project ./src/YourProject.csproj

# 3. Review the script
cat test-migration.sql

# 4. Apply migration using CLI
dotnet ef database update --project ./src/YourProject.csproj --connection "$DEV_CONNECTION_STRING"

# 5. Verify migration
dotnet ef migrations list --project ./src/YourProject.csproj --connection "$DEV_CONNECTION_STRING"

# 6. Test application
dotnet run --project ./src/YourProject.csproj

# 7. Remove test migration
dotnet ef migrations remove --project ./src/YourProject.csproj
```

**Checklist:**
- [ ] Test migration created successfully
- [ ] SQL script generated and reviewed
- [ ] Migration applied successfully
- [ ] Application starts without errors
- [ ] Application functions correctly
- [ ] Test migration removed

---

### Step 3.2: Test CI/CD Pipeline in PreProd

**Action:** Deploy to PreProd using CI/CD

**Steps:**
1. Create a feature branch
2. Add a real migration
3. Commit and push to feature branch
4. Create pull request to `develop`
5. Review the PR
6. Merge to `develop`
7. Monitor the workflow execution
8. Verify PreProd deployment

**Monitoring:**
```bash
# Check workflow status
# Go to: Repository → Actions → Your Workflow

# Verify deployment
curl -f https://preprod.yourapp.com/health

# Check database
sqlcmd -S preprod-sql.database.windows.net -U migration_user -P '***' \
  -Q "SELECT * FROM __EFMigrationsHistory ORDER BY MigrationId DESC"
```

**Checklist:**
- [ ] Workflow triggered on merge to develop
- [ ] Build and test job passed
- [ ] Docker image built and pushed
- [ ] Migration job executed successfully
- [ ] Application deployed successfully
- [ ] Health check passed
- [ ] Application functions correctly
- [ ] Migration visible in database

---

### Step 3.3: Test Rollback Procedures

**Action:** Practice rollback in development/staging

**Steps:**
```bash
# 1. Apply a migration
dotnet ef database update --project ./src/YourProject.csproj

# 2. Note the current migration
CURRENT_MIGRATION=$(dotnet ef migrations list --project ./src/YourProject.csproj --no-connect | tail -1)

# 3. Create a backup (in real environment)
# sqlcmd backup command here

# 4. Rollback to previous migration
dotnet ef database update PreviousMigrationName --project ./src/YourProject.csproj

# 5. Verify rollback
dotnet ef migrations list --project ./src/YourProject.csproj

# 6. Test application with rolled-back schema
dotnet run --project ./src/YourProject.csproj

# 7. Re-apply if needed
dotnet ef database update --project ./src/YourProject.csproj
```

**Checklist:**
- [ ] Rollback script created
- [ ] Rollback tested in development
- [ ] Application functions after rollback
- [ ] Re-applying migration works
- [ ] Team trained on rollback procedures
- [ ] Rollback runbook documented

---

## Phase 4: Production Deployment (2-4 hours)

### Step 4.1: Pre-Production Checklist

**Before deploying to production:**

- [ ] All tests passed in lower environments
- [ ] Security checklist completed
- [ ] Database backup verified and tested
- [ ] Rollback plan documented and rehearsed
- [ ] Stakeholders notified of deployment window
- [ ] Monitoring dashboard prepared
- [ ] On-call engineer assigned and available
- [ ] Maintenance window scheduled (if needed)
- [ ] Communication plan ready
- [ ] Post-deployment verification plan ready

---

### Step 4.2: Production Deployment

**Action:** Deploy to production using CI/CD

**Steps:**
1. Create pull request from `develop` to `main`
2. Conduct thorough code review
3. Review and approve PR
4. Merge to `main` branch
5. Workflow triggers automatically
6. Required reviewers approve deployment
7. Monitor migration execution closely
8. Monitor application deployment
9. Verify production health

**During deployment:**
```bash
# Monitor workflow
# Go to: Repository → Actions → Production Deployment

# Watch for migration job completion
# Watch for deployment job completion

# Immediate verification
curl -f https://yourapp.com/health

# Database verification
sqlcmd -S prod-sql.database.windows.net -U migration_user -P '***' \
  -Q "SELECT TOP 5 * FROM __EFMigrationsHistory ORDER BY MigrationId DESC"
```

**Checklist:**
- [ ] PR reviewed and approved
- [ ] Workflow triggered
- [ ] Required reviewers approved deployment
- [ ] Backup created successfully
- [ ] Migration executed successfully
- [ ] Application deployed successfully
- [ ] Health check passed
- [ ] No errors in logs
- [ ] Smoke tests passed
- [ ] Monitoring shows healthy metrics

---

### Step 4.3: Post-Deployment Verification

**Action:** Verify production deployment

**Verification Steps:**
1. **Health check:** Verify `/health` endpoint
2. **Smoke tests:** Test critical user flows
3. **Database verification:** Check migration history
4. **Log review:** Check for errors or warnings
5. **Performance check:** Verify acceptable response times
6. **User verification:** Test with real user account
7. **Integration tests:** Verify external integrations

**Metrics to monitor:**
- Response times
- Error rates
- Database query performance
- Resource utilization (CPU, memory)
- Active connections

**Checklist:**
- [ ] Health endpoints responding
- [ ] Critical user flows working
- [ ] No errors in application logs
- [ ] No errors in database logs
- [ ] Performance within acceptable range
- [ ] External integrations working
- [ ] User feedback positive (if available)

---

### Step 4.4: Post-Deployment Tasks

**Action:** Complete post-deployment activities

**Tasks:**
1. Update documentation with deployment notes
2. Conduct post-deployment retrospective
3. Document any issues encountered
4. Update runbooks if needed
5. Share success with team
6. Archive backup confirmation
7. Close deployment ticket

**Checklist:**
- [ ] Deployment documented
- [ ] Team notified of completion
- [ ] Backup location documented
- [ ] Any issues documented
- [ ] Lessons learned captured
- [ ] Documentation updated
- [ ] Deployment ticket closed

---

## Phase 5: Ongoing Maintenance

### Regular Activities

**Weekly:**
- [ ] Review failed migration alerts
- [ ] Monitor database performance
- [ ] Review security logs

**Monthly:**
- [ ] Review and rotate credentials
- [ ] Test backup restoration
- [ ] Review migration execution times
- [ ] Update dependencies

**Quarterly:**
- [ ] Security checklist review
- [ ] Disaster recovery drill
- [ ] Documentation update
- [ ] Team training on procedures

---

## Common Migration Patterns

### Pattern 1: Adding a Simple Column

```csharp
// Migration
public partial class AddLastLoginDate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<DateTime>(
            name: "LastLoginDate",
            table: "Users",
            type: "datetime2",
            nullable: true);  // Nullable for existing rows
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "LastLoginDate",
            table: "Users");
    }
}
```

**Safe for zero-downtime:** Yes (nullable column)

---

### Pattern 2: Renaming a Column (Safe)

```csharp
// Step 1: Add new column
public partial class AddNewEmailColumn : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "EmailAddress",
            table: "Users",
            nullable: true);
            
        // Copy data from old column
        migrationBuilder.Sql(
            "UPDATE Users SET EmailAddress = Email WHERE Email IS NOT NULL");
    }
}

// Deploy application that uses both columns

// Step 2: Remove old column (in next deployment)
public partial class RemoveOldEmailColumn : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "Email",
            table: "Users");
    }
}
```

**Safe for zero-downtime:** Yes (two-step process)

---

### Pattern 3: Adding Required Column

```csharp
// Step 1: Add nullable column with default
public partial class AddIsActiveColumn : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<bool>(
            name: "IsActive",
            table: "Users",
            nullable: true);
            
        // Set default value for existing rows
        migrationBuilder.Sql(
            "UPDATE Users SET IsActive = 1 WHERE IsActive IS NULL");
    }
}

// Step 2: Make it required (in next deployment)
public partial class MakeIsActiveRequired : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AlterColumn<bool>(
            name: "IsActive",
            table: "Users",
            nullable: false);
    }
}
```

**Safe for zero-downtime:** Yes (two-step process)

---

## Troubleshooting Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| Migration not running | Check connection string, verify secrets |
| Race condition | Ensure only one migration job runs |
| Permission denied | Verify migration user has DDL permissions |
| Timeout | Increase connection timeout, split migrations |
| Duplicate seed data | Use idempotent seeding logic |
| Can't connect to database | Check firewall rules, VPN connection |

**For detailed troubleshooting, see:** [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## Success Criteria

Your implementation is successful when:

✅ Migrations execute automatically on merge to develop/main  
✅ No race conditions occur  
✅ Application never runs migrations  
✅ Database always backed up before production migrations  
✅ Rollback procedures work and are documented  
✅ Security checklist completed  
✅ Team trained on new procedures  
✅ Zero production incidents related to migrations  

---

## Next Steps

After successful implementation:

1. **Document your specific deployment process**
2. **Train team members on the new workflow**
3. **Set up monitoring and alerting**
4. **Schedule regular security reviews**
5. **Plan for continuous improvement**

---

## Additional Resources

- [EF Core Migrations Best Practices](./EF-CORE-MIGRATIONS-BEST-PRACTICES.md)
- [Security Checklist](./SECURITY-CHECKLIST.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [Microsoft EF Core Documentation](https://learn.microsoft.com/en-us/ef/core/)

---

**Estimated Total Implementation Time:** 12-22 hours  
**Recommended Team Size:** 2-3 people  
**Prerequisites:** .NET 9, EF Core 9, GitHub Actions access

---

**Document Version:** 1.0  
**Last Updated:** December 2024
