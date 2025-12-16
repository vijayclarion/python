# Migration Script Generation: Developer vs CI/CD Approach

## Overview

There are two main approaches for generating EF Core migration scripts in your workflow:

1. **Developer-Generated Scripts** - Developers create and commit migration scripts to the repository
2. **CI/CD-Generated Scripts** - Pipeline automatically generates scripts during build

Both approaches are valid and industry-standard. The choice depends on your team's needs, compliance requirements, and organizational practices.

---

## Approach Comparison

| Aspect | Developer-Generated | CI/CD-Generated (Current) |
|--------|-------------------|---------------------------|
| **Script Creation** | Manual, before commit | Automatic, during build |
| **Version Control** | Scripts committed to repo | Scripts generated as artifacts |
| **Code Review** | SQL reviewed in PR | Migration classes reviewed in PR |
| **Audit Trail** | SQL in git history | Migration classes + workflow logs |
| **Enterprise Change Mgmt** | Easy to integrate | Requires artifact storage |
| **Risk of Drift** | Low (SQL is source of truth) | Very Low (C# is source of truth) |
| **Flexibility** | High (manual SQL edits) | Medium (requires migration changes) |
| **DBA Review** | Direct SQL review | Review generated scripts or migration code |
| **Complexity** | Higher setup | Lower setup |
| **Best For** | Regulated industries, manual DB changes | Agile teams, automated workflows |

---

## Approach 1: Developer-Generated Scripts

### When to Use

✅ **Use this approach if:**
- Your organization requires DBA review of SQL before deployment
- You have strict change management processes
- You need to manually optimize SQL for performance
- Your DBAs are not familiar with EF Core migrations
- You work in regulated industries (finance, healthcare) requiring SQL audit
- You need to customize SQL for database-specific features
- Your team prefers having SQL as source of truth

### Workflow

```
Developer Workflow:
1. Create EF Core migration class
2. Generate SQL script locally
3. Review and optimize SQL
4. Commit BOTH migration class AND SQL script
5. Create PR (includes C# migration + SQL script)
6. DBA reviews SQL in PR
7. Merge to main

CI/CD Workflow:
1. Build & Test
2. Download SQL script from repository
3. Execute SQL script on target database
4. Deploy application
```

### Implementation Steps

#### Step 1: Set Up Local Script Generation

Create a script for developers to generate SQL:

```bash
#!/bin/bash
# scripts/generate-migration-script.sh

MIGRATION_NAME=$1
PROJECT_PATH="./src/YourProject/YourProject.csproj"
SCRIPTS_DIR="./database/migrations"

if [ -z "$MIGRATION_NAME" ]; then
    echo "Usage: ./generate-migration-script.sh <MigrationName>"
    exit 1
fi

# Create migration
dotnet ef migrations add $MIGRATION_NAME --project $PROJECT_PATH

# Generate idempotent script
mkdir -p $SCRIPTS_DIR
dotnet ef migrations script --idempotent \
    --output $SCRIPTS_DIR/${MIGRATION_NAME}.sql \
    --project $PROJECT_PATH

echo "✓ Migration created: $MIGRATION_NAME"
echo "✓ SQL script generated: $SCRIPTS_DIR/${MIGRATION_NAME}.sql"
echo ""
echo "Next steps:"
echo "1. Review the SQL script"
echo "2. Optimize if needed"
echo "3. Commit both the migration class and SQL script"
echo "4. Create a PR for review"
```

#### Step 2: Directory Structure

```
your-repo/
├── src/
│   └── YourProject/
│       └── Migrations/           # EF Core migration classes
│           ├── 20250101_InitialCreate.cs
│           └── 20250102_AddUserTable.cs
├── database/
│   └── migrations/               # Generated SQL scripts
│       ├── InitialCreate.sql
│       └── AddUserTable.sql
└── scripts/
    └── generate-migration-script.sh
```

#### Step 3: Developer Workflow

```bash
# 1. Create migration and generate SQL
./scripts/generate-migration-script.sh AddEmailColumn

# 2. Review and optimize the SQL
# Edit database/migrations/AddEmailColumn.sql if needed

# 3. Commit both files
git add src/YourProject/Migrations/
git add database/migrations/
git commit -m "Add email column migration"

# 4. Push and create PR
git push origin feature/add-email-column
```

#### Step 4: Update CI/CD Workflow

```yaml
# .github/workflows/dotnet-cicd-with-migrations.yml

jobs:
  migrate-database-production:
    name: Migrate Database (Production)
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Find latest migration script
      id: find-script
      run: |
        # Get the latest migration script
        LATEST_SCRIPT=$(ls -t database/migrations/*.sql | head -n 1)
        echo "script=$LATEST_SCRIPT" >> $GITHUB_OUTPUT
        echo "Using migration script: $LATEST_SCRIPT"
        
    - name: Review migration script
      run: |
        echo "Migration script contents:"
        cat ${{ steps.find-script.outputs.script }}
        
    - name: Backup database
      run: |
        # Your backup command here
        echo "Creating backup..."
        
    - name: Execute migration script
      run: |
        # Execute the committed SQL script
        sqlcmd -S ${{ secrets.PROD_SQL_SERVER }} \
          -d ${{ secrets.PROD_DATABASE }} \
          -U ${{ secrets.PROD_SQL_USER }} \
          -P ${{ secrets.PROD_SQL_PASSWORD }} \
          -i ${{ steps.find-script.outputs.script }}
```

#### Step 5: Pull Request Template

Create `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Database Changes

- [ ] This PR includes database migrations
- [ ] SQL script has been generated and committed
- [ ] SQL script has been reviewed for performance
- [ ] SQL script is idempotent (can run multiple times)
- [ ] Rollback SQL script included (if applicable)

### Migration Details

**Migration Name:** `<migration-name>`

**SQL Script Location:** `database/migrations/<migration>.sql`

**Changes:**
- 

**Rollback Plan:**
- 

**DBA Review Required:** Yes / No
```

### Pros and Cons

**Advantages:**
- ✅ SQL is version controlled and easily reviewable in PRs
- ✅ DBAs can review actual SQL before execution
- ✅ Easy to manually optimize SQL for performance
- ✅ Works well with enterprise change management tools
- ✅ Clear audit trail (SQL in git history)
- ✅ Can handle complex migrations requiring manual SQL

**Disadvantages:**
- ❌ Extra step for developers (generate + commit script)
- ❌ Risk of forgetting to regenerate script after migration changes
- ❌ Need to ensure script matches migration class
- ❌ More files to maintain in repository
- ❌ Can become complex with multiple environments

---

## Approach 2: CI/CD-Generated Scripts (Current Implementation)

### When to Use

✅ **Use this approach if:**
- Your team is comfortable with EF Core migrations
- You want to minimize manual steps
- You trust the EF Core migration generation
- Your DBAs can review C# migration code
- You prefer automated workflows
- Your organization doesn't require pre-committed SQL scripts
- You want to avoid repository clutter

### Workflow

```
Developer Workflow:
1. Create EF Core migration class
2. Commit migration class to repository
3. Create PR (C# migration code reviewed)
4. Merge to main

CI/CD Workflow:
1. Build & Test
2. Generate SQL script from migrations (automatic)
3. Store script as artifact
4. Execute migrations using EF Core CLI
5. Deploy application
```

### Implementation (Already Done)

The current workflow already implements this approach:

```yaml
# In build-and-test job
- name: Generate migration SQL scripts
  run: |
    dotnet ef migrations script --idempotent \
      --output migrations.sql \
      --project ./src/YourProject.csproj
    
- name: Upload migration scripts
  uses: actions/upload-artifact@v4
  with:
    name: migration-scripts
    path: migrations.sql

# In migrate-database job
- name: Download migration scripts
  uses: actions/download-artifact@v4
  with:
    name: migration-scripts
    
- name: Run database migrations
  run: |
    dotnet ef database update \
      --project ./src/YourProject.csproj \
      --connection "${{ secrets.PROD_CONNECTION_STRING }}"
```

### Pros and Cons

**Advantages:**
- ✅ Simpler developer workflow (just commit migration class)
- ✅ No risk of script/migration mismatch
- ✅ Less repository clutter
- ✅ Automatic script generation
- ✅ EF Core handles all database differences
- ✅ Faster development cycle

**Disadvantages:**
- ❌ SQL script not visible until build runs
- ❌ Harder for DBAs to review (need to review C# or wait for build)
- ❌ Less control over exact SQL
- ❌ May not integrate with some enterprise tools

---

## Hybrid Approach (Recommended)

Combine both approaches for maximum flexibility:

### Workflow

1. **Developer generates scripts locally** (optional, for complex migrations)
2. **CI/CD always generates scripts** (automatic, for audit trail)
3. **Execute using EF Core CLI** (reliable, handles migration history)
4. **Store both as artifacts** (compliance, rollback)

### Implementation

```yaml
jobs:
  build-and-test:
    steps:
    # Developer may have committed SQL (optional)
    - name: Check for manual SQL scripts
      id: check-manual
      run: |
        if [ -d "database/migrations" ]; then
          echo "manual_scripts=true" >> $GITHUB_OUTPUT
        else
          echo "manual_scripts=false" >> $GITHUB_OUTPUT
        fi
    
    # Always generate SQL via CI/CD
    - name: Generate migration SQL scripts
      run: |
        dotnet ef migrations script --idempotent \
          --output migrations-auto.sql \
          --project ./src/YourProject.csproj
    
    # Upload both
    - name: Upload migration artifacts
      uses: actions/upload-artifact@v4
      with:
        name: migration-scripts
        path: |
          migrations-auto.sql
          database/migrations/*.sql

  migrate-database:
    steps:
    # Use EF Core CLI (most reliable)
    - name: Run migrations
      run: |
        dotnet ef database update \
          --project ./src/YourProject.csproj \
          --connection "$CONNECTION_STRING"
    
    # But keep manual scripts for audit/review
    - name: Archive migration scripts
      uses: actions/upload-artifact@v4
      with:
        name: migration-audit-${{ github.run_number }}
        path: database/migrations/
        retention-days: 90
```

---

## Recommendation Matrix

| Scenario | Recommended Approach |
|----------|---------------------|
| Agile team, fast iteration | **CI/CD-Generated** (Current) |
| Regulated industry (finance, healthcare) | **Developer-Generated** or **Hybrid** |
| DBA review required | **Developer-Generated** or **Hybrid** |
| Complex custom SQL needed | **Developer-Generated** |
| High trust in EF Core | **CI/CD-Generated** (Current) |
| Small team, simple schema | **CI/CD-Generated** (Current) |
| Enterprise with change management | **Developer-Generated** or **Hybrid** |
| Need manual SQL optimization | **Developer-Generated** |
| Want minimal developer overhead | **CI/CD-Generated** (Current) |

---

## Migration Strategy Decision Tree

```
Do you have strict DBA review requirements?
├─ YES → Do DBAs understand C# EF Core migrations?
│   ├─ YES → Use CI/CD-Generated (Current)
│   └─ NO → Use Developer-Generated
└─ NO → Do you need manual SQL optimization?
    ├─ YES → Use Developer-Generated or Hybrid
    └─ NO → Use CI/CD-Generated (Current) ✓
```

---

## Current Implementation Status

**Your repository is currently set up with Approach 2: CI/CD-Generated Scripts**

This is the **recommended approach for most teams** because:
- ✅ Simpler developer workflow
- ✅ No manual script generation steps
- ✅ Automatic and reliable
- ✅ Less maintenance overhead
- ✅ Industry-standard for agile teams

### Should You Change?

**Stick with current approach (CI/CD-Generated) if:**
- Your team doesn't have strict DBA SQL review requirements
- You trust EF Core migration generation
- You want to move fast with minimal friction
- Your DBAs can review C# migration code or generated scripts in artifacts

**Switch to Developer-Generated approach if:**
- Your organization requires SQL scripts committed to repository
- DBAs must review SQL before any deployment
- You work in regulated industry requiring SQL audit trail
- You frequently need to manually optimize SQL
- Your change management process requires pre-committed SQL

**Use Hybrid approach if:**
- You want flexibility for complex migrations
- You need both development speed and audit compliance
- Some migrations need manual SQL, others don't

---

## Switching Between Approaches

If you decide to switch approaches after reading this guide, detailed implementation steps are provided in each section above.

**Need help deciding?** Consider:
1. Your organization's compliance requirements
2. Your team's familiarity with EF Core
3. Your DBA involvement level
4. Your change management processes
5. Your development velocity priorities

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Related:** EF-CORE-MIGRATIONS-BEST-PRACTICES.md, IMPLEMENTATION-GUIDE.md
