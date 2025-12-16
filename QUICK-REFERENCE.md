# Quick Reference: EF Core Migrations in CI/CD

## 📌 TL;DR

**Run database migrations as a SEPARATE CI/CD job BEFORE deploying your application.**

```
✅ DO: Build → Migrate Database → Deploy App
❌ DON'T: Build → Deploy App (with migrations on startup)
```

---

## 🎯 Key Principle

### Separate Migration from Deployment

**Why?**
- ✅ No race conditions
- ✅ Better security (separate credentials)
- ✅ Clear audit trail
- ✅ Easy rollback
- ✅ Zero-downtime deployments

**Recommended by:** Microsoft, The Twelve-Factor App, Database Reliability Engineering

---

## 📁 What's in This Solution

| File | Purpose |
|------|---------|
| `.github/workflows/dotnet-cicd-with-migrations.yml` | Complete CI/CD workflow |
| `docs/cicd/EF-CORE-MIGRATIONS-BEST-PRACTICES.md` | Best practices + 10+ authoritative references |
| `docs/cicd/IMPLEMENTATION-GUIDE.md` | Step-by-step implementation (5 phases) |
| `docs/cicd/TROUBLESHOOTING.md` | 10+ common issues and solutions |
| `docs/cicd/SECURITY-CHECKLIST.md` | Complete security review checklist |
| `docs/cicd/README.md` | Quick start guide |
| `scripts/apply-migrations.sh` | Helper script for migrations |
| `scripts/rollback-migration.sh` | Helper script for rollbacks |
| `SOLUTION-SUMMARY.md` | Complete solution overview |

---

## 🚀 Quick Start (5 Minutes)

### 1. Set Up Secrets
```
Repository → Settings → Secrets → Actions
Add: PREPROD_CONNECTION_STRING
Add: PROD_CONNECTION_STRING
```

### 2. Configure Environments
```
Repository → Settings → Environments
Create: preprod (auto-deploy from 'develop')
Create: production (require approval, only 'main')
```

### 3. Customize Workflow
```yaml
# Edit: .github/workflows/dotnet-cicd-with-migrations.yml
# Update: ./src/YourProject.csproj (line 44, 65, 125, etc.)
# Add: Your deployment commands (line 112, 145)
# Add: Your backup commands (line 161)
```

### 4. Deploy
```bash
# Test in preprod
git push origin develop

# Deploy to production
git push origin main
```

---

## 📋 Workflow Overview

```
┌─────────────┐
│  Push Code  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ Build & Test    │
│ • Compile       │
│ • Run tests     │
│ • Gen SQL       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Build Docker    │
│ • Build image   │
│ • Push registry │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│PreProd │ │  Prod  │
└───┬────┘ └───┬────┘
    │          │
    ▼          ▼
┌──────────────────┐
│ Migrate DB       │
│ • Backup         │
│ • Run migrations │
│ • Verify         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Deploy App       │
│ • Deploy         │
│ • Health check   │
│ • Smoke tests    │
└──────────────────┘
```

---

## 💡 Core Commands

### Generate Migration
```bash
dotnet ef migrations add YourMigrationName
```

### Generate SQL Script
```bash
dotnet ef migrations script --idempotent --output migrations.sql
```

### Apply Migration
```bash
dotnet ef database update --connection "$CONNECTION_STRING"
```

### List Migrations
```bash
dotnet ef migrations list
```

### Rollback Migration
```bash
dotnet ef database update PreviousMigrationName
```

---

## 🔐 Security Essentials

### ✅ DO
- Store connection strings in CI/CD secrets
- Use separate credentials for migrations vs app
- Backup before production migrations
- Encrypt connections (SSL/TLS)
- Use firewall rules
- Audit all migrations

### ❌ DON'T
- Commit connection strings to git
- Use same credentials for app and migrations
- Give app DDL permissions
- Skip backups
- Use default passwords
- Ignore failed migrations

---

## 🆘 Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Race condition | Ensure only one migration job runs |
| Permission denied | Use migration user with DDL permissions |
| Timeout | Increase connection timeout, split migrations |
| Connection failed | Check firewall rules, secrets |
| Duplicate seed data | Use idempotent seeding logic |

**Full guide:** `docs/cicd/TROUBLESHOOTING.md`

---

## 📚 Documentation Hierarchy

**Start here →** `SOLUTION-SUMMARY.md` (Overview)  
**Then →** `docs/cicd/README.md` (Quick start)  
**Deep dive →** `docs/cicd/EF-CORE-MIGRATIONS-BEST-PRACTICES.md` (Best practices)  
**Implementation →** `docs/cicd/IMPLEMENTATION-GUIDE.md` (Step-by-step)  
**Security →** `docs/cicd/SECURITY-CHECKLIST.md` (Security review)  
**Help →** `docs/cicd/TROUBLESHOOTING.md` (Common issues)

---

## 🎓 Key Concepts

### 1. Idempotent Migrations
Scripts that can run multiple times safely
```bash
dotnet ef migrations script --idempotent
```

### 2. Separation of Concerns
- **Migration credentials:** DDL permissions
- **App credentials:** DML permissions only

### 3. Environment Protection
- **PreProd:** Auto-deploy from `develop`
- **Production:** Require approval, only from `main`

### 4. Backup Strategy
Always backup before production migrations
```sql
BACKUP DATABASE [MyDb] TO DISK = '/backups/backup.bak'
```

### 5. Rollback Plan
Forward-only approach preferred
```bash
# Create new migration to fix
dotnet ef migrations add FixPreviousIssue
```

---

## 📊 Success Checklist

- [ ] Migrations run as separate CI/CD job
- [ ] Application doesn't run migrations on startup
- [ ] Separate credentials for migrations and app
- [ ] Secrets stored in CI/CD (not in code)
- [ ] Environment protection configured
- [ ] Backup before production migrations
- [ ] Rollback procedures documented
- [ ] Security checklist completed
- [ ] Team trained on new workflow
- [ ] Monitoring and alerts configured

---

## 🔗 Authoritative References

1. **[Microsoft: Applying Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)**
2. **[Microsoft: EF Core Tools](https://learn.microsoft.com/en-us/ef/core/cli/dotnet)**
3. **[GitHub Actions Security](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)**
4. **[The Twelve-Factor App](https://12factor.net/)**
5. **[Database Reliability Engineering](https://www.oreilly.com/library/view/database-reliability-engineering/9781491925935/)**

**Full list (10+):** `docs/cicd/EF-CORE-MIGRATIONS-BEST-PRACTICES.md`

---

## 💬 Common Questions

**Q: Why not run migrations on app startup?**  
A: Race conditions, security issues, poor audit trail, difficult rollback

**Q: What if my migration fails?**  
A: Application deployment is blocked, database unchanged, easy to fix and retry

**Q: How do I rollback?**  
A: Create new forward migration to fix, or use rollback script (with backup)

**Q: What about seed data?**  
A: Static data in `HasData()`, dynamic data in separate seeding job

**Q: Is this approach required for all projects?**  
A: Highly recommended for production. Startup migrations OK for dev/POC.

---

## ⚡ Next Steps

1. **Review:** Read `docs/cicd/EF-CORE-MIGRATIONS-BEST-PRACTICES.md`
2. **Set up:** Follow `docs/cicd/IMPLEMENTATION-GUIDE.md`
3. **Secure:** Complete `docs/cicd/SECURITY-CHECKLIST.md`
4. **Deploy:** Test in preprod, then production
5. **Monitor:** Track metrics and optimize

---

## 📞 Need Help?

1. Check `docs/cicd/TROUBLESHOOTING.md`
2. Review `docs/cicd/SECURITY-CHECKLIST.md`
3. Consult Microsoft documentation
4. Open an issue in the repository

---

**Version:** 1.0 | **Updated:** December 2024 | **For:** .NET 9 + EF Core 9.0+
