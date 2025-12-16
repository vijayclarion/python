#!/bin/bash

# rollback-migration.sh
# Script to rollback EF Core migrations
# Usage: ./rollback-migration.sh <environment> <target-migration> <connection-string>

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT=${1:-""}
TARGET_MIGRATION=${2:-""}
CONNECTION_STRING=${3:-""}
PROJECT_PATH=${4:-"./src/YourProject.csproj"}

# Validation
if [ -z "$ENVIRONMENT" ] || [ -z "$TARGET_MIGRATION" ] || [ -z "$CONNECTION_STRING" ]; then
    echo -e "${RED}Error: Missing required parameters${NC}"
    echo "Usage: $0 <environment> <target-migration> <connection-string> [project-path]"
    exit 1
fi

# Safety check for production
if [ "$ENVIRONMENT" = "production" ] || [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${RED}WARNING: You are about to rollback migrations in PRODUCTION${NC}"
    echo -e "${RED}Target migration: $TARGET_MIGRATION${NC}"
    echo -e "${YELLOW}This operation may result in data loss!${NC}"
    echo ""
    echo "Type 'ROLLBACK PRODUCTION' to confirm:"
    read -r confirmation
    
    if [ "$confirmation" != "ROLLBACK PRODUCTION" ]; then
        echo -e "${RED}Rollback cancelled${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}=== EF Core Migration Rollback ===${NC}"
echo "Environment: $ENVIRONMENT"
echo "Target Migration: $TARGET_MIGRATION"
echo "Project: $PROJECT_PATH"
echo ""

# Generate rollback script
echo -e "${GREEN}Generating rollback script...${NC}"
ROLLBACK_SCRIPT="rollback_${ENVIRONMENT}_$(date +%Y%m%d_%H%M%S).sql"
dotnet ef migrations script "$TARGET_MIGRATION" --output "$ROLLBACK_SCRIPT" --project "$PROJECT_PATH"

echo -e "${YELLOW}Rollback script generated: $ROLLBACK_SCRIPT${NC}"
echo "Review the script before proceeding:"
cat "$ROLLBACK_SCRIPT"
echo ""

echo "Do you want to execute this rollback? (yes/no):"
read -r execute_confirmation

if [ "$execute_confirmation" != "yes" ]; then
    echo -e "${YELLOW}Rollback cancelled. Script saved at: $ROLLBACK_SCRIPT${NC}"
    exit 0
fi

# Execute rollback
echo -e "${GREEN}Executing rollback...${NC}"
dotnet ef database update "$TARGET_MIGRATION" --project "$PROJECT_PATH" --connection "$CONNECTION_STRING"

echo -e "${GREEN}Rollback completed successfully${NC}"
echo -e "${YELLOW}Please verify the database state and application functionality${NC}"
