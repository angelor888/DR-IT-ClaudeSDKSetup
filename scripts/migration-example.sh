#!/bin/bash
# Example Migration Script Template
# Use this pattern for complex package modifications

set -euo pipefail

# Version information
OLD_VERSION="1.0.0"
NEW_VERSION="1.1.0"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔄 Migrating from v$OLD_VERSION to v$NEW_VERSION${NC}"

# 1. Backup current configuration
backup_current_config() {
    echo "Backing up current configuration..."
    mkdir -p ~/.config/claude/backups/v$OLD_VERSION
    cp -r ~/.config/claude/scripts ~/.config/claude/backups/v$OLD_VERSION/
    cp -r ~/.config/claude/commands ~/.config/claude/backups/v$OLD_VERSION/
    echo "✅ Backup completed"
}

# 2. Migrate configuration files
migrate_config() {
    echo "Migrating configuration files..."
    
    # Example: Convert old format to new format
    if [ -f ~/.config/claude/old-config.json ]; then
        # Convert and move to new location
        jq '.newFormat = .oldFormat' ~/.config/claude/old-config.json > ~/.config/claude/new-config.json
        rm ~/.config/claude/old-config.json
    fi
    
    echo "✅ Configuration migrated"
}

# 3. Update file permissions
update_permissions() {
    echo "Updating file permissions..."
    find ~/.config/claude/scripts -name "*.sh" -exec chmod +x {} \;
    echo "✅ Permissions updated"
}

# 4. Test migration
test_migration() {
    echo "Testing migration..."
    ~/.config/claude/scripts/claude-workflow-test.sh quick
    echo "✅ Migration tested"
}

# 5. Clean up old files
cleanup_old_files() {
    echo "Cleaning up old files..."
    rm -f ~/.config/claude/scripts/deprecated-*.sh
    echo "✅ Cleanup completed"
}

# Main migration process
main() {
    echo -e "${YELLOW}Starting migration process...${NC}"
    
    backup_current_config
    migrate_config
    update_permissions
    test_migration
    cleanup_old_files
    
    echo -e "${GREEN}🎉 Migration to v$NEW_VERSION completed successfully!${NC}"
    echo -e "${YELLOW}ℹ️  Backup available at: ~/.config/claude/backups/v$OLD_VERSION${NC}"
}

# Run migration
main "$@"