#!/bin/bash

# apply-migrations.sh
# Script to apply EF Core migrations in CI/CD pipeline
# Usage: ./apply-migrations.sh <environment> <connection-string>

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parameters
ENVIRONMENT=${1:-""}
CONNECTION_STRING=${2:-""}
PROJECT_PATH=${3:-"./src/YourProject.csproj"}
BACKUP_ENABLED=${BACKUP_ENABLED:-"true"}
DRY_RUN=${DRY_RUN:-"false"}

# Validation
if [ -z "$ENVIRONMENT" ]; then
    echo -e "${RED}Error: Environment parameter is required${NC}"
    echo "Usage: $0 <environment> <connection-string> [project-path]"
    exit 1
fi

if [ -z "$CONNECTION_STRING" ]; then
    echo -e "${RED}Error: Connection string parameter is required${NC}"
    exit 1
fi

echo -e "${GREEN}=== EF Core Migration Script ===${NC}"
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT_PATH"
echo "Dry Run: $DRY_RUN"
echo ""

# Check if dotnet-ef is installed
if ! command -v dotnet-ef &> /dev/null; then
    echo -e "${YELLOW}dotnet-ef not found, installing...${NC}"
    dotnet tool install --global dotnet-ef
    export PATH="$PATH:$HOME/.dotnet/tools"
fi

# Verify project exists
if [ ! -f "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project file not found at $PROJECT_PATH${NC}"
    exit 1
fi

# Check pending migrations
echo -e "${GREEN}Checking for pending migrations...${NC}"
PENDING_MIGRATIONS=$(dotnet ef migrations list --project "$PROJECT_PATH" --no-connect 2>&1 | grep -v "Build started" | grep -v "Build succeeded" || true)
echo "$PENDING_MIGRATIONS"

if echo "$PENDING_MIGRATIONS" | grep -q "No migrations found"; then
    echo -e "${YELLOW}No migrations to apply${NC}"
    exit 0
fi

# Generate migration script for review
echo -e "${GREEN}Generating migration script...${NC}"
SCRIPT_FILE="migrations_${ENVIRONMENT}_$(date +%Y%m%d_%H%M%S).sql"
dotnet ef migrations script --idempotent --output "$SCRIPT_FILE" --project "$PROJECT_PATH"

echo -e "${GREEN}Migration script generated: $SCRIPT_FILE${NC}"
echo "Script preview (first 20 lines):"
head -n 20 "$SCRIPT_FILE"
echo "..."

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}Dry run mode - not applying migrations${NC}"
    echo "Review the generated script at: $SCRIPT_FILE"
    exit 0
fi

# Backup database (if enabled and supported)
if [ "$BACKUP_ENABLED" = "true" ] && [ "$ENVIRONMENT" != "development" ]; then
    echo -e "${GREEN}Creating database backup...${NC}"
    # Add your backup logic here based on your database type
    # Example for SQL Server:
    # sqlcmd -S $SERVER -U $USER -P $PASSWORD -Q "BACKUP DATABASE [$DB] TO DISK = '/backups/backup_$(date +%Y%m%d_%H%M%S).bak'"
    echo -e "${YELLOW}Note: Backup logic needs to be implemented for your database type${NC}"
fi

# Apply migrations
echo -e "${GREEN}Applying migrations to $ENVIRONMENT...${NC}"
dotnet ef database update --project "$PROJECT_PATH" --connection "$CONNECTION_STRING" --verbose

# Verify migration
echo -e "${GREEN}Verifying migration...${NC}"
dotnet ef migrations list --project "$PROJECT_PATH" --connection "$CONNECTION_STRING"

# Cleanup
if [ -f "$SCRIPT_FILE" ]; then
    echo -e "${GREEN}Cleaning up temporary script file...${NC}"
    rm "$SCRIPT_FILE"
fi

echo -e "${GREEN}=== Migration completed successfully ===${NC}"
