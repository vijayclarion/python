#!/bin/bash

# generate-migration-script.sh
# Helper script for developers to generate migration SQL scripts
# Use this if you've chosen the "Developer-Generated Scripts" approach
# See: docs/cicd/MIGRATION-APPROACHES.md for more details

set -e
set -u

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH=${PROJECT_PATH:-"./src/YourProject/YourProject.csproj"}
SCRIPTS_DIR=${SCRIPTS_DIR:-"./database/migrations"}
MIGRATION_NAME=${1:-""}

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   EF Core Migration Script Generator                              ║${NC}"
echo -e "${BLUE}║   For Developer-Generated Scripts Approach                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Usage check
if [ -z "$MIGRATION_NAME" ]; then
    echo -e "${RED}Error: Migration name is required${NC}"
    echo ""
    echo "Usage: $0 <MigrationName>"
    echo ""
    echo "Example:"
    echo "  $0 AddEmailColumn"
    echo "  $0 CreateUserTable"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_PATH - Path to .csproj file (default: ./src/YourProject/YourProject.csproj)"
    echo "  SCRIPTS_DIR  - Directory for SQL scripts (default: ./database/migrations)"
    echo ""
    exit 1
fi

# Check if project exists
if [ ! -f "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project file not found at $PROJECT_PATH${NC}"
    echo ""
    echo "Please set PROJECT_PATH environment variable or create the project file."
    echo ""
    echo "Example:"
    echo "  PROJECT_PATH=./src/MyApp/MyApp.csproj $0 $MIGRATION_NAME"
    echo ""
    exit 1
fi

# Check if dotnet-ef is installed
if ! command -v dotnet-ef &> /dev/null; then
    echo -e "${YELLOW}dotnet-ef tool not found. Installing...${NC}"
    dotnet tool install --global dotnet-ef
    export PATH="$PATH:$HOME/.dotnet/tools"
    echo ""
fi

# Create migrations directory if it doesn't exist
mkdir -p "$SCRIPTS_DIR"

# Step 1: Create the EF Core migration
echo -e "${GREEN}Step 1: Creating EF Core migration class...${NC}"
dotnet ef migrations add "$MIGRATION_NAME" --project "$PROJECT_PATH"
echo ""

# Step 2: Generate idempotent SQL script
echo -e "${GREEN}Step 2: Generating SQL script...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCRIPT_FILENAME="${TIMESTAMP}_${MIGRATION_NAME}.sql"
SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT_FILENAME"

dotnet ef migrations script --idempotent \
    --output "$SCRIPT_PATH" \
    --project "$PROJECT_PATH"

echo -e "${GREEN}✓ SQL script generated: $SCRIPT_PATH${NC}"
echo ""

# Step 3: Display script preview
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script Preview (first 30 lines):${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
head -n 30 "$SCRIPT_PATH"
echo ""
if [ $(wc -l < "$SCRIPT_PATH") -gt 30 ]; then
    echo "... ($(wc -l < "$SCRIPT_PATH") total lines)"
    echo ""
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Step 4: Summary and next steps
echo -e "${GREEN}✓ Migration created successfully!${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Migration Name: $MIGRATION_NAME"
echo "  Migration Class: Check src/.../Migrations/ directory"
echo "  SQL Script: $SCRIPT_PATH"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "  1. ${BLUE}Review the SQL script${NC}"
echo "     Open and review: $SCRIPT_PATH"
echo ""
echo "  2. ${BLUE}Optimize if needed${NC}"
echo "     - Add indexes for performance"
echo "     - Adjust data types"
echo "     - Add custom SQL"
echo ""
echo "  3. ${BLUE}Test locally${NC}"
echo "     Run: dotnet ef database update --project $PROJECT_PATH"
echo ""
echo "  4. ${BLUE}Commit both files${NC}"
echo "     git add src/"
echo "     git add $SCRIPTS_DIR/"
echo "     git commit -m \"Add $MIGRATION_NAME migration\""
echo ""
echo "  5. ${BLUE}Create Pull Request${NC}"
echo "     - Include migration class and SQL script"
echo "     - Request DBA review if required"
echo "     - Include rollback plan"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"

# Optional: Ask if user wants to view the full script
echo ""
read -p "View the full SQL script now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    less "$SCRIPT_PATH"
fi

# Optional: Create rollback script
echo ""
read -p "Generate rollback script? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ROLLBACK_SCRIPT="${TIMESTAMP}_${MIGRATION_NAME}_ROLLBACK.sql"
    ROLLBACK_PATH="$SCRIPTS_DIR/$ROLLBACK_SCRIPT"
    
    echo -e "${GREEN}Generating rollback script...${NC}"
    
    # Get previous migration name
    PREVIOUS_MIGRATION=$(dotnet ef migrations list --project "$PROJECT_PATH" --no-connect 2>&1 | grep -v "Build started" | grep -v "Build succeeded" | grep -v "$MIGRATION_NAME" | tail -1 | awk '{print $NF}')
    
    if [ -n "$PREVIOUS_MIGRATION" ]; then
        dotnet ef migrations script "$MIGRATION_NAME" "$PREVIOUS_MIGRATION" \
            --output "$ROLLBACK_PATH" \
            --project "$PROJECT_PATH"
        
        echo -e "${GREEN}✓ Rollback script generated: $ROLLBACK_PATH${NC}"
    else
        echo -e "${YELLOW}No previous migration found. Rollback script not generated.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Done! Happy migrating! 🚀${NC}"
echo ""
