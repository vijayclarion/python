# CI/CD Pipeline Implementation Guide

## Overview

This directory contains comprehensive documentation and examples for implementing industry-standard CI/CD pipelines with Entity Framework Core migrations for .NET 9 applications.

## Contents

### Documentation

- **[EF-CORE-MIGRATIONS-BEST-PRACTICES.md](./EF-CORE-MIGRATIONS-BEST-PRACTICES.md)** - Comprehensive guide on EF Core migrations in CI/CD with authoritative references
- **[IMPLEMENTATION-GUIDE.md](./IMPLEMENTATION-GUIDE.md)** - Step-by-step implementation instructions
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions
- **[SECURITY-CHECKLIST.md](./SECURITY-CHECKLIST.md)** - Security best practices checklist

### Examples

- **[Dockerfile.example](./Dockerfile.example)** - Production-ready Dockerfile
- **[../.github/workflows/dotnet-cicd-with-migrations.yml](../../.github/workflows/dotnet-cicd-with-migrations.yml)** - Complete CI/CD workflow
- **[../scripts/](../../scripts/)** - Helper scripts for migrations

## Quick Start

### 1. Review the Best Practices Document

Start by reading [EF-CORE-MIGRATIONS-BEST-PRACTICES.md](./EF-CORE-MIGRATIONS-BEST-PRACTICES.md) to understand:
- Why separate migration jobs are recommended
- Security considerations
- Rollback strategies
- Authoritative references from Microsoft and industry experts

### 2. Set Up GitHub Secrets

Configure the following secrets in your GitHub repository:

#### PreProd Environment
- `PREPROD_CONNECTION_STRING` - Database connection string
- `PREPROD_SQL_SERVER` - SQL Server hostname (if using backup scripts)
- `PREPROD_SQL_USER` - SQL Server username (if using backup scripts)
- `PREPROD_SQL_PASSWORD` - SQL Server password (if using backup scripts)

#### Production Environment
- `PROD_CONNECTION_STRING` - Database connection string
- `PROD_SQL_SERVER` - SQL Server hostname
- `PROD_SQL_USER` - SQL Server username
- `PROD_SQL_PASSWORD` - SQL Server password

### 3. Configure Environment Protection

In your GitHub repository settings:

1. Go to **Settings** → **Environments**
2. Create environments: `preprod` and `production`
3. For production, enable:
   - **Required reviewers** (at least 1-2 reviewers)
   - **Wait timer** (optional: 5-10 minutes)
   - **Deployment branches** (limit to `main` branch only)

### 4. Customize the Workflow

Edit `.github/workflows/dotnet-cicd-with-migrations.yml`:

1. Update `IMAGE_NAME` and `REGISTRY` if using a different container registry
2. Update project paths (replace `./src/YourProject.csproj` with actual path)
3. Customize deployment commands for your infrastructure
4. Add your backup commands for production
5. Configure notifications (Slack, Teams, email, etc.)

### 5. Test in Development

Before deploying to production:

```bash
# Test migration script generation
cd scripts
chmod +x apply-migrations.sh
./apply-migrations.sh development "$DEV_CONNECTION_STRING" ../src/YourProject.csproj

# Test in dry-run mode
DRY_RUN=true ./apply-migrations.sh development "$DEV_CONNECTION_STRING"
```

### 6. Deploy to PreProd

1. Merge your changes to the `develop` branch
2. The workflow will automatically:
   - Build and test
   - Generate migration scripts
   - Build Docker image
   - Apply migrations to PreProd
   - Deploy the application
3. Verify the deployment

### 7. Deploy to Production

1. Merge `develop` to `main` branch
2. The workflow will:
   - Build and test
   - Wait for manual approval (if configured)
   - Backup production database
   - Apply migrations
   - Deploy the application
3. Monitor the deployment closely

## Key Principles

### ✅ DO

1. **Separate migrations from deployment** - Run migrations as a dedicated CI/CD job
2. **Backup before migrations** - Always backup production databases
3. **Use environment protection** - Require approvals for production
4. **Generate SQL scripts** - Create audit trail and enable review
5. **Test in lower environments first** - PreProd should mirror Production
6. **Use proper secrets management** - Never commit connection strings
7. **Monitor migration execution** - Set up alerts for failures
8. **Version control everything** - All migrations in source control

### ❌ DON'T

1. **Don't run migrations on app startup** - Causes race conditions and security issues
2. **Don't bundle migrations in Docker images** - Violates separation of concerns
3. **Don't use manual SQL scripts** - Loses migration history and causes drift
4. **Don't skip backups** - Essential for disaster recovery
5. **Don't use same credentials for app and migrations** - Violate principle of least privilege
6. **Don't deploy without testing migrations** - Always test in lower environments first
7. **Don't skip code review for migrations** - Schema changes need review
8. **Don't rush production migrations** - Take time to verify and backup

## Architecture Decision Record (ADR)

### Decision: Separate Migration Job in CI/CD

**Status:** Recommended

**Context:**
We need a reliable way to manage database schema changes in our CI/CD pipeline for a .NET 9 application with Entity Framework Core, deploying to PreProd and Production via Docker containers.

**Decision:**
Implement database migrations as a separate, dedicated job in the CI/CD pipeline that runs BEFORE application deployment.

**Consequences:**

**Positive:**
- Eliminates race conditions between multiple container instances
- Clear audit trail of all schema changes
- Application doesn't need elevated database permissions
- Better error handling and rollback capabilities
- Supports zero-downtime deployments
- Enables database backups before changes
- Compatible with compliance and change management requirements

**Negative:**
- Slightly more complex CI/CD configuration
- Requires CI/CD runners to have database connectivity
- Need to manage database credentials in CI/CD secrets

**Alternatives Considered:**

1. **Running migrations on application startup** - Rejected due to race conditions and security concerns
2. **Manual migrations** - Rejected due to error-prone nature and lack of automation
3. **Bundling in Docker image** - Rejected due to security and separation of concerns

**References:**
- [Microsoft: Applying Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                       │
└─────────────────────────────────────────────────────────────┘

┌───────────────┐
│  Push/PR to   │
│  develop/main │
└───────┬───────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  Build & Test Job                                           │
│  • Restore dependencies                                     │
│  • Compile code                                             │
│  • Run unit tests                                           │
│  • Generate idempotent migration SQL scripts                │
│  • Upload migration scripts as artifact                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Build Docker Image Job                                     │
│  • Build application container                              │
│  • Tag with branch name and SHA                             │
│  • Push to container registry (GitHub Container Registry)  │
│  • Cache layers for faster builds                           │
└────────────────┬────────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
┌─────────────┐   ┌─────────────┐
│   PreProd   │   │  Production │
│  (develop)  │   │    (main)   │
└──────┬──────┘   └──────┬──────┘
       │                 │
       ▼                 ▼
┌─────────────────────────────────────┐
│  Migrate Database Job               │
│  • Download migration scripts       │
│  • Backup database (prod only)      │
│  • Run: dotnet ef database update   │
│  • Apply seed data (if needed)      │
│  • Verify migration success         │
│  • Alert on failure                 │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Deploy Application Job             │
│  • Deploy Docker container          │
│  • Wait for startup (30s)           │
│  • Health check                     │
│  • Smoke tests                      │
│  • Alert on failure                 │
└─────────────────────────────────────┘
```

## Support

For questions or issues:

1. Review the [Troubleshooting Guide](./TROUBLESHOOTING.md)
2. Check the [Security Checklist](./SECURITY-CHECKLIST.md)
3. Consult the [Microsoft Documentation](https://learn.microsoft.com/en-us/ef/core/)
4. Open an issue in the repository

## Contributing

When contributing improvements:

1. Test in development environment first
2. Update documentation if changing workflow
3. Follow security best practices
4. Get peer review for production changes

## License

This documentation and examples are provided as-is for reference purposes.

---

**Last Updated:** December 2024  
**Maintained by:** DevOps Team  
**Applicable to:** .NET 9, Entity Framework Core 9.0+
