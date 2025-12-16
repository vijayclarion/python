# EF Core Migrations in CI/CD: Industry Best Practices

## Executive Summary

This document provides authoritative recommendations for handling Entity Framework Core database migrations in CI/CD pipelines, specifically for .NET 9 applications deploying to PreProd and Production environments via Docker containers.

## Table of Contents

1. [Recommended Approach](#recommended-approach)
2. [Why This Approach?](#why-this-approach)
3. [Implementation Details](#implementation-details)
4. [Seed Data Strategy](#seed-data-strategy)
5. [Rollback Strategy](#rollback-strategy)
6. [Security Considerations](#security-considerations)
7. [Authoritative References](#authoritative-references)
8. [Common Anti-Patterns to Avoid](#common-anti-patterns-to-avoid)

---

## Recommended Approach

### Core Principle: Separate Migration from Deployment

**The industry-standard best practice is to execute database migrations as a separate, dedicated step in your CI/CD pipeline BEFORE deploying the application.**

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1. Build & Test                                            │
│     - Compile code                                          │
│     - Run unit tests                                        │
│     - Generate migration SQL scripts                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Build Docker Image                                      │
│     - Build application container                           │
│     - Push to container registry                            │
│     - DO NOT include migration execution                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Database Migration (Separate Job)                       │
│     - Backup database                                       │
│     - Run EF Core migrations                                │
│     - Verify migration success                              │
│     - Apply seed data (if needed)                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Deploy Application                                      │
│     - Deploy Docker container                               │
│     - Health checks                                         │
│     - Smoke tests                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Why This Approach?

### 1. **Separation of Concerns**

**Problem with running migrations on app startup:**
- Application startup becomes a critical database operation
- Multiple instances starting simultaneously can cause race conditions
- Difficult to track and audit database changes
- Rollback becomes complicated

**Benefit of separate migration job:**
- Single point of execution (no race conditions)
- Clear audit trail in CI/CD logs
- Migrations complete before application deployment
- Easy to monitor and alert on migration failures

### 2. **Zero-Downtime Deployments**

Running migrations separately enables:
- Database schema changes before application deployment
- Backward-compatible migrations (old and new code work during transition)
- Blue-green deployments
- Rolling updates with multiple application instances

### 3. **Better Error Handling**

- Migration failures prevent application deployment
- Application never starts with incompatible schema
- Clear failure points in pipeline
- Easier to diagnose and fix issues

### 4. **Improved Security**

- Application doesn't need elevated database permissions
- Migration credentials stored securely in CI/CD secrets
- Reduced attack surface in production containers
- Clear separation between runtime and deployment permissions

### 5. **Enhanced Observability**

- Dedicated logs for database changes
- Clear metrics on migration duration
- Easy integration with monitoring tools
- Historical record of all schema changes

---

## Implementation Details

### Script Generation: Developer vs CI/CD

Before choosing an execution method, you need to decide **who generates the migration SQL scripts**:

- **CI/CD-Generated Scripts** (Current Implementation) - Pipeline automatically generates scripts during build
- **Developer-Generated Scripts** - Developers manually create and commit SQL scripts to repository
- **Hybrid Approach** - Combine both for flexibility

**📖 See [MIGRATION-APPROACHES.md](./MIGRATION-APPROACHES.md) for detailed comparison and guidance on choosing the right approach for your team.**

The current workflow implements **CI/CD-Generated Scripts**, which is recommended for most agile teams. If your organization requires committed SQL scripts for DBA review or compliance, see the Developer-Generated approach in the guide above.

### Option 1: Using EF Core CLI (Recommended for Most Scenarios)

```bash
# Install EF Core tools
dotnet tool install --global dotnet-ef

# Run migrations
dotnet ef database update --project ./src/YourProject.csproj \
  --connection "$CONNECTION_STRING"
```

**Pros:**
- Simple and direct
- Automatically handles migration history
- Built-in safety checks
- Works with all EF Core features

**Cons:**
- Requires .NET runtime in CI environment
- Less control over exact SQL execution

### Option 2: Generate and Execute SQL Scripts

```bash
# Generate idempotent SQL script
dotnet ef migrations script --idempotent --output migrations.sql \
  --project ./src/YourProject.csproj

# Execute using native database tools
sqlcmd -S $SQL_SERVER -d $DATABASE -U $USER -P $PASSWORD -i migrations.sql
```

**Pros:**
- SQL can be reviewed before execution
- Works with existing database deployment tools
- Can be integrated with enterprise change management
- No .NET runtime needed for execution

**Cons:**
- Two-step process
- Requires SQL script generation in build
- Need to manage script artifacts

### Option 3: Hybrid Approach (Recommended for Enterprise)

Use the hybrid approach for the best of both worlds:

1. **Generate SQL scripts** during build for review and audit
2. **Execute via EF Core CLI** for reliability and safety
3. **Store SQL scripts** as artifacts for compliance and rollback

This is implemented in the provided YAML workflow.

---

## Seed Data Strategy

### Types of Seed Data

#### 1. **Static Reference Data**
Data that rarely changes (countries, states, product categories)

**Recommendation:** Include in EF Core migrations using `HasData()`

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Country>().HasData(
        new Country { Id = 1, Name = "United States", Code = "US" },
        new Country { Id = 2, Name = "Canada", Code = "CA" }
    );
}
```

**Pros:**
- Version controlled with schema
- Automatically applied with migrations
- Consistent across environments

#### 2. **Environment-Specific Data**
Data that varies by environment (test accounts, feature flags)

**Recommendation:** Use separate seeding scripts executed after migrations

```bash
# In CI/CD pipeline after migrations
dotnet run --project ./src/YourProject.csproj -- seed \
  --environment Production \
  --connection "$CONNECTION_STRING"
```

**Pros:**
- Flexible per environment
- Can be run on-demand
- Separate from schema changes

#### 3. **Large Dataset Imports**
Bulk data imports or data migrations

**Recommendation:** Use dedicated data import jobs separate from schema migrations

```bash
# Separate job for data imports
dotnet run --project ./src/DataImport.csproj \
  --source /data/import.csv \
  --connection "$CONNECTION_STRING"
```

**Pros:**
- Doesn't slow down deployments
- Can be retried independently
- Better error handling for data issues

### Seed Data Anti-Pattern: Manual Application

**Avoid:** Manually applying seed data through SQL scripts or database tools

**Problem:**
- No version control
- No audit trail
- Environment drift
- Human error prone

---

## Rollback Strategy

### Database Rollback Challenges

**Important:** Database rollbacks are more complex than application rollbacks because:
- Data loss risk (can't always undo data changes)
- Schema changes may be irreversible
- Cascading effects on dependent systems

### Recommended Rollback Approach

#### 1. **Always Backup Before Migrations**

```bash
# SQL Server example
BACKUP DATABASE [YourDatabase] 
TO DISK = '/backups/YourDatabase_20250101_120000.bak' 
WITH COPY_ONLY
```

**Critical for production environments**

#### 2. **Use Forward-Only Migrations**

**Recommendation:** Create new migrations to fix issues rather than rolling back

```bash
# Instead of reverting, create a new migration to fix
dotnet ef migrations add FixColumnNameTypo
```

**Pros:**
- Preserves data
- Clear audit trail
- Safer in production
- Supports multiple instances

#### 3. **Test Rollback Procedures**

Create reverse migrations for testing:

```bash
# Generate reverse script
dotnet ef migrations script CurrentMigration PreviousMigration \
  --output rollback.sql
```

Test rollback in non-production environments.

#### 4. **Blue-Green Deployments for Major Changes**

For significant schema changes:
1. Deploy to parallel environment (green)
2. Run migrations on green database
3. Test thoroughly
4. Switch traffic to green
5. Keep blue as instant rollback option

---

## Security Considerations

### 1. **Connection String Management**

**Never** store connection strings in code or configuration files in the repository.

**Use:**
- GitHub Secrets for GitHub Actions
- Azure Key Vault for Azure Pipelines
- AWS Secrets Manager for AWS
- HashiCorp Vault for on-premises

```yaml
# GitHub Actions example
- name: Run migrations
  env:
    CONNECTION_STRING: ${{ secrets.PROD_CONNECTION_STRING }}
  run: dotnet ef database update
```

### 2. **Principle of Least Privilege**

**Migration Credentials:**
- CREATE/ALTER/DROP permissions for schema objects
- Only active during migration job
- Different from application credentials

**Application Credentials:**
- SELECT/INSERT/UPDATE/DELETE on tables
- NO schema modification permissions
- Used at runtime

### 3. **Network Security**

- Use VPN or private networking for database access from CI/CD
- Whitelist CI/CD runner IP addresses
- Use Azure Private Link, AWS PrivateLink, or similar
- Enable SSL/TLS for database connections

### 4. **Audit Logging**

Enable and monitor:
- Database audit logs for all DDL operations
- CI/CD pipeline logs for migration execution
- Failed migration attempts
- Unauthorized access attempts

---

## Authoritative References

### Official Microsoft Documentation

1. **[Applying Migrations in Production Environments](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)**
   - Microsoft's official guidance on EF Core migrations in production
   - Recommends generating SQL scripts for production
   - Details on migration safety and best practices

2. **[Entity Framework Core Tools Reference](https://learn.microsoft.com/en-us/ef/core/cli/dotnet)**
   - Complete reference for `dotnet ef` commands
   - Connection string handling
   - Script generation options

3. **[.NET Application Security](https://learn.microsoft.com/en-us/dotnet/core/security/)**
   - Secure credential management
   - Best practices for secrets in CI/CD

4. **[Azure DevOps CI/CD for .NET](https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/dotnet-core)**
   - Microsoft's recommended CI/CD patterns
   - Environment management
   - Deployment strategies

### Industry Best Practices

5. **[GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)**
   - Secret management in workflows
   - Environment protection rules
   - Secure runner configuration

6. **[The Twelve-Factor App: Backing Services](https://12factor.net/backing-services)**
   - Treating databases as attached resources
   - Configuration management
   - Environment parity

7. **[Database Reliability Engineering (O'Reilly)](https://www.oreilly.com/library/view/database-reliability-engineering/9781491925935/)**
   - Chapter on Database Migrations
   - Production deployment patterns
   - Rollback strategies

### Community Resources

8. **[EF Core Community Standups](https://www.youtube.com/playlist?list=PLdo4fOcmZ0oX0ObHwBrJ0vJpZ7PiYMqeA)**
   - Regular updates from EF Core team
   - Migration patterns and practices
   - Real-world scenarios

9. **[ASP.NET Community Standup - DevOps](https://www.youtube.com/playlist?list=PLdo4fOcmZ0oVlqu_V8EkcDMPWhXWCXhRN)**
   - .NET DevOps best practices
   - CI/CD pipeline patterns
   - Production deployment strategies

10. **[Entity Framework Core GitHub Repository](https://github.com/dotnet/efcore)**
    - Issue discussions on migration strategies
    - Community patterns and solutions
    - Feature requests and roadmap

---

## Common Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Running Migrations on Application Startup

```csharp
// DON'T DO THIS in production
public class Program
{
    public static void Main(string[] args)
    {
        var host = CreateHostBuilder(args).Build();
        
        using (var scope = host.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            db.Database.Migrate(); // ❌ AVOID IN PRODUCTION
        }
        
        host.Run();
    }
}
```

**Problems:**
- Race conditions with multiple instances
- Application has elevated database permissions
- No audit trail
- Difficult to rollback
- Startup delays
- Complex error handling

**When it's acceptable:**
- Development environments
- Single-instance dev/test deployments
- Proof-of-concept projects

### ❌ Anti-Pattern 2: Manual SQL Scripts

```sql
-- DON'T manage migrations manually
-- manual_migration_2024_01_01.sql
ALTER TABLE Users ADD COLUMN LastLoginDate DATETIME;
```

**Problems:**
- No migration history tracking
- Error-prone
- Environment drift
- Difficult to coordinate with code changes
- No automatic rollback generation

### ❌ Anti-Pattern 3: Bundling Migrations in Docker Image

```dockerfile
# DON'T bundle migrations in application image
FROM mcr.microsoft.com/dotnet/aspnet:9.0
COPY --from=build /app/publish .
# ❌ AVOID: This runs migrations when container starts
ENTRYPOINT ["sh", "-c", "dotnet ef database update && dotnet MyApp.dll"]
```

**Problems:**
- Same issues as running on application startup
- Container needs database credentials
- Orchestration complexity
- Health check complications

### ❌ Anti-Pattern 4: No Backup Before Migrations

```yaml
# DON'T skip backups
- name: Run migrations
  run: dotnet ef database update  # ❌ No backup!
```

**Problems:**
- No safety net for production
- Data loss risk
- Cannot rollback easily
- Violates disaster recovery best practices

### ❌ Anti-Pattern 5: Using Production Database for Development

```json
// DON'T use production connection strings in development
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=prod-sql.database.windows.net;..." // ❌ DANGEROUS
  }
}
```

**Problems:**
- Accidental data modification
- Security risk
- Performance impact on production
- Compliance violations

---

## Conclusion

The recommended approach for handling EF Core migrations in CI/CD is:

1. ✅ **Separate migration execution** from application deployment
2. ✅ **Use dedicated CI/CD jobs** for database migrations
3. ✅ **Always backup** before production migrations
4. ✅ **Run migrations before** deploying application
5. ✅ **Use proper credential management** with secrets
6. ✅ **Generate SQL scripts** for audit and review
7. ✅ **Test migrations** in non-production environments first
8. ✅ **Monitor and log** all migration activities

This approach ensures reliability, security, and maintainability of your database schema management in production environments.

---

## Quick Reference: Decision Matrix

| Scenario | Recommended Approach |
|----------|---------------------|
| Small team, simple app | EF Core CLI in dedicated CI/CD job |
| Enterprise, compliance required | Generate SQL scripts + approval gates |
| Multiple microservices | Separate migration pipeline per service |
| Blue-green deployments | Backward-compatible migrations + separate job |
| High-availability requirement | Zero-downtime migrations + careful planning |
| Legacy database | SQL scripts with manual review |
| Development/testing | Application startup migrations (acceptable) |

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Applicable to:** .NET 9, Entity Framework Core 9.0+
