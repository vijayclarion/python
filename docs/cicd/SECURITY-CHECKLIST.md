# Security Checklist: EF Core Migrations in CI/CD

## Pre-Deployment Security Review

Use this checklist before deploying migrations to production.

---

## 🔐 Credential Management

### Connection Strings

- [ ] Connection strings are stored in CI/CD secrets (not in code)
- [ ] Connection strings are NOT in appsettings.json or other config files
- [ ] Connection strings use environment-specific secrets (separate for PreProd/Prod)
- [ ] Connection strings are NOT logged or printed in CI/CD output
- [ ] Connection string syntax is validated before use

### Database Credentials

- [ ] Separate credentials for migrations vs. application runtime
- [ ] Migration credentials have limited scope (only DDL operations)
- [ ] Application credentials have minimal permissions (no DDL)
- [ ] Credentials are rotated regularly (quarterly at minimum)
- [ ] Credentials use strong passwords (or managed identities where possible)
- [ ] No default or well-known passwords are used

### Secrets Management

- [ ] Using proper secrets management (GitHub Secrets, Azure Key Vault, AWS Secrets Manager, etc.)
- [ ] Secrets are not shared across environments unnecessarily
- [ ] Secrets have appropriate access controls (limited to required roles)
- [ ] Secret access is logged and audited
- [ ] Secrets are never committed to git (even in .env files)

---

## 🌐 Network Security

### Database Access

- [ ] Database is NOT publicly accessible
- [ ] Database firewall rules restrict access to CI/CD runners only
- [ ] Using VPN or private networking for database connections
- [ ] SSL/TLS enabled for all database connections
- [ ] Certificate validation enabled (not using TrustServerCertificate=true)
- [ ] IP whitelisting configured for CI/CD runners

### Application Access

- [ ] Health endpoints don't expose sensitive information
- [ ] Admin endpoints are properly secured
- [ ] API keys and tokens are not exposed in responses
- [ ] CORS policies are properly configured

---

## 🔑 Least Privilege Principle

### Migration User Permissions

SQL Server example:
```sql
-- Migration user should have:
GRANT CREATE TABLE TO migration_user;
GRANT ALTER ON SCHEMA::dbo TO migration_user;
GRANT CREATE INDEX TO migration_user;

-- Should NOT have:
-- GRANT CONTROL ON DATABASE TO migration_user; ❌
-- GRANT db_owner TO migration_user; ❌
```

- [ ] Migration user has DDL permissions only (CREATE, ALTER, DROP)
- [ ] Migration user does NOT have:
  - [ ] CONTROL permissions
  - [ ] db_owner role
  - [ ] Backup/restore permissions (unless specifically needed)
  - [ ] User management permissions

### Application User Permissions

- [ ] Application user has DML permissions only (SELECT, INSERT, UPDATE, DELETE)
- [ ] Application user does NOT have:
  - [ ] CREATE/ALTER/DROP permissions
  - [ ] Administrative permissions
  - [ ] Access to system tables
- [ ] Permissions are granted at table/schema level, not database level
- [ ] Row-level security considered for multi-tenant applications

---

## 🛡️ Docker Security

### Dockerfile Security

- [ ] Using official Microsoft base images
- [ ] Base images are up-to-date (latest patch version)
- [ ] Multi-stage build to minimize final image size
- [ ] Application runs as non-root user
- [ ] No secrets or credentials in Docker image
- [ ] .dockerignore configured to exclude sensitive files
- [ ] Health checks implemented

### Container Runtime

- [ ] Container registry uses authentication
- [ ] Images are scanned for vulnerabilities
- [ ] Containers run with minimal privileges
- [ ] Resource limits configured (CPU, memory)
- [ ] Read-only file system where possible
- [ ] No privileged mode unless absolutely necessary

---

## 🔍 Code Security

### Migration Code Review

- [ ] All migrations peer-reviewed before production
- [ ] No sensitive data hardcoded in migrations
- [ ] No SQL injection vulnerabilities in custom migrations
- [ ] Idempotent migrations (safe to run multiple times)
- [ ] Rollback plan documented for each migration
- [ ] Data loss risks identified and documented

### Application Code

- [ ] Using parameterized queries (no string concatenation)
- [ ] Input validation on all user inputs
- [ ] Output encoding to prevent XSS
- [ ] CSRF protection enabled
- [ ] Authentication and authorization properly implemented
- [ ] Dependency vulnerability scanning enabled

---

## 📋 Audit & Monitoring

### Logging

- [ ] Migration execution logged
- [ ] Failed migration attempts logged and alerted
- [ ] Database audit logging enabled
- [ ] CI/CD pipeline logs retained for compliance period
- [ ] Logs don't contain sensitive data (passwords, tokens, PII)

### Monitoring

- [ ] Alerts configured for migration failures
- [ ] Database performance monitoring enabled
- [ ] Unusual query patterns monitored
- [ ] Failed login attempts monitored
- [ ] Resource utilization monitored

### Compliance

- [ ] Migration changes comply with change management policy
- [ ] Proper approval workflow for production changes
- [ ] Backup verification before production migrations
- [ ] Documentation maintained for audit purposes
- [ ] Compliance requirements met (SOC 2, HIPAA, PCI-DSS, etc.)

---

## 🔄 CI/CD Pipeline Security

### GitHub Actions Security

- [ ] Workflow files use specific action versions (not @main or @latest)
- [ ] Third-party actions reviewed for security
- [ ] GITHUB_TOKEN has minimal necessary permissions
- [ ] Environment protection rules configured for production
- [ ] Required reviewers configured for production deployments
- [ ] Branch protection rules enforced

### Environment Configuration

- [ ] Production environment requires manual approval
- [ ] Only specific branches can deploy to production
- [ ] Deployment logs are retained and reviewable
- [ ] Failed deployments trigger notifications
- [ ] Rollback procedures documented and tested

---

## 💾 Backup & Recovery

### Backup Strategy

- [ ] Automated backups configured
- [ ] Backups tested regularly (restore test)
- [ ] Backup retention policy defined and enforced
- [ ] Backups encrypted at rest
- [ ] Backups stored in secure location
- [ ] Backup before EVERY production migration

### Recovery Planning

- [ ] Disaster recovery plan documented
- [ ] Recovery Time Objective (RTO) defined
- [ ] Recovery Point Objective (RPO) defined
- [ ] Rollback procedures documented and tested
- [ ] Point-in-time recovery capability verified
- [ ] Off-site backup copy maintained

---

## 🧪 Testing Security

### Pre-Production Testing

- [ ] Migrations tested in development environment
- [ ] Migrations tested in staging/preprod environment
- [ ] Security scans run on migrations
- [ ] Load testing performed with new schema
- [ ] Rollback tested in non-production environment

### Production Safety

- [ ] Maintenance window scheduled for risky changes
- [ ] Communication plan for downtime
- [ ] Monitoring dashboard ready
- [ ] On-call engineer available during deployment
- [ ] Quick rollback plan prepared

---

## 📊 Data Protection

### Sensitive Data

- [ ] PII properly encrypted at rest
- [ ] PII properly encrypted in transit
- [ ] Data retention policies enforced
- [ ] GDPR/privacy compliance maintained
- [ ] Data masking used in non-production environments
- [ ] No production data in development/test environments

### Data Integrity

- [ ] Foreign key constraints maintained
- [ ] Data validation rules enforced
- [ ] Orphaned records handled properly
- [ ] Data consistency verified after migration
- [ ] No unintended data loss

---

## 🚨 Incident Response

### Preparation

- [ ] Incident response plan documented
- [ ] Contact list for security incidents maintained
- [ ] Escalation procedures defined
- [ ] Post-mortem template prepared
- [ ] Communication templates ready

### Detection & Response

- [ ] Security monitoring tools configured
- [ ] Anomaly detection enabled
- [ ] Automated alerts for suspicious activity
- [ ] Incident response team trained
- [ ] Regular security drills conducted

---

## 📝 Documentation

### Required Documentation

- [ ] Architecture diagram showing data flow
- [ ] Security architecture documented
- [ ] Threat model reviewed and updated
- [ ] Change management procedures documented
- [ ] Emergency procedures documented
- [ ] Runbook for common issues

### Compliance Documentation

- [ ] Security controls documented
- [ ] Audit logs retention policy documented
- [ ] Incident response procedures documented
- [ ] Business continuity plan documented
- [ ] Compliance certifications current

---

## ✅ Sign-Off

Before deploying to production, ensure:

- [ ] All critical items in this checklist are completed
- [ ] Security review conducted and approved
- [ ] Architecture review conducted and approved
- [ ] Required approvals obtained
- [ ] Deployment plan reviewed
- [ ] Rollback plan tested
- [ ] Monitoring and alerts verified
- [ ] Team notified of deployment schedule

---

## 🔗 Security Resources

### Microsoft Resources

- [Azure Security Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [.NET Security Guidance](https://learn.microsoft.com/en-us/dotnet/standard/security/)
- [SQL Server Security](https://learn.microsoft.com/en-us/sql/relational-databases/security/security-center-for-sql-server-database-engine-and-azure-sql-database)

### OWASP Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)

### Industry Standards

- [CIS Controls](https://www.cisecurity.org/controls)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [SOC 2 Compliance](https://www.aicpa.org/soc)

---

**Severity Levels:**

- 🔴 **Critical:** Must be addressed before production deployment
- 🟡 **High:** Should be addressed, may proceed with documented risk acceptance
- 🟢 **Medium:** Address in near term, doesn't block deployment
- ⚪ **Low:** Nice to have, address when convenient

Mark each item with severity and track remediation:

```
[ ] 🔴 Critical: Connection strings stored in CI/CD secrets
[ ] 🟡 High: Database firewall rules configured
[ ] 🟢 Medium: Regular credential rotation schedule
[ ] ⚪ Low: Enhanced logging for all operations
```

---

**Review Schedule:**
- Initial review: Before first production deployment
- Regular review: Quarterly
- Ad-hoc review: After security incidents or major changes

**Last Reviewed:** _______________  
**Reviewed By:** _______________  
**Next Review Date:** _______________

---

**Document Version:** 1.0  
**Last Updated:** December 2024
