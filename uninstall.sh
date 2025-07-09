#!/bin/bash
# Claude Tools Uninstaller
# Safely removes Claude Tools and all associated files

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
BACKUP_DIR="$HOME/.config/claude-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
PACKAGE_REMOVAL=false
FORCE_REMOVAL=false
KEEP_BACKUPS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --package-removal)
            PACKAGE_REMOVAL=true
            shift
            ;;
        --force)
            FORCE_REMOVAL=true
            shift
            ;;
        --keep-backups)
            KEEP_BACKUPS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --package-removal   Called during package removal"
            echo "  --force            Skip confirmation prompts"
            echo "  --keep-backups     Keep backup files"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🧹 Claude Tools Uninstaller${NC}"
echo "==============================="

# Confirmation prompt
if [ "$FORCE_REMOVAL" = false ] && [ "$PACKAGE_REMOVAL" = false ]; then
    echo ""
    echo -e "${YELLOW}⚠️  This will remove Claude Tools and all associated files.${NC}"
    echo -e "${YELLOW}   A backup will be created at: $BACKUP_DIR${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
fi

# Create backup
if [ "$KEEP_BACKUPS" = true ] && [ -d "$CLAUDE_CONFIG_DIR" ]; then
    echo -e "${YELLOW}💾 Creating backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -r "$CLAUDE_CONFIG_DIR"/* "$BACKUP_DIR"/ 2>/dev/null || true
    echo "Backup created at: $BACKUP_DIR"
fi

# Stop running processes
echo -e "${YELLOW}🛑 Stopping running processes...${NC}"

# Kill any running Claude processes
pkill -f "claude-" 2>/dev/null || true

# Stop LaunchAgent if exists
if [ -f "$HOME/Library/LaunchAgents/com.duetright.claude-auto-update.plist" ]; then
    launchctl unload "$HOME/Library/LaunchAgents/com.duetright.claude-auto-update.plist" 2>/dev/null || true
    rm -f "$HOME/Library/LaunchAgents/com.duetright.claude-auto-update.plist"
    echo "Removed LaunchAgent"
fi

# Remove configuration directory
if [ -d "$CLAUDE_CONFIG_DIR" ]; then
    echo -e "${YELLOW}🗂️  Removing configuration directory...${NC}"
    rm -rf "$CLAUDE_CONFIG_DIR"
    echo "Removed: $CLAUDE_CONFIG_DIR"
fi

# Remove from shell profiles
echo -e "${YELLOW}🐚 Cleaning shell profiles...${NC}"

clean_shell_profile() {
    local profile="$1"
    if [ -f "$profile" ]; then
        # Remove Claude Tools lines
        sed -i '' '/# Claude Tools/d' "$profile" 2>/dev/null || true
        sed -i '' '/claude.*shell-integration/d' "$profile" 2>/dev/null || true
        sed -i '' '/source.*claude.*shell-integration/d' "$profile" 2>/dev/null || true
        
        # Remove Claude aliases
        sed -i '' '/alias.*claude/d' "$profile" 2>/dev/null || true
        sed -i '' '/alias.*cwt/d' "$profile" 2>/dev/null || true
        sed -i '' '/alias.*cide/d' "$profile" 2>/dev/null || true
        sed -i '' '/alias.*cdesign/d' "$profile" 2>/dev/null || true
        sed -i '' '/alias.*caudio/d' "$profile" 2>/dev/null || true
        sed -i '' '/alias.*cclip/d' "$profile" 2>/dev/null || true
        
        echo "Cleaned: $profile"
    fi
}

clean_shell_profile "$HOME/.zshrc"
clean_shell_profile "$HOME/.bashrc"
clean_shell_profile "$HOME/.bash_profile"

# Remove Homebrew installation
if command -v brew &> /dev/null; then
    echo -e "${YELLOW}🍺 Checking Homebrew installation...${NC}"
    if brew list claude-tools &> /dev/null; then
        echo "Removing Homebrew installation..."
        brew uninstall claude-tools 2>/dev/null || true
        echo "Removed Homebrew package"
    fi
fi

# Remove NPM global installation
if command -v npm &> /dev/null; then
    echo -e "${YELLOW}📦 Checking NPM installation...${NC}"
    if npm list -g @dr-it/claude-sdk-setup &> /dev/null; then
        echo "Removing NPM global installation..."
        npm uninstall -g @dr-it/claude-sdk-setup 2>/dev/null || true
        echo "Removed NPM package"
    fi
fi

# Remove binary symlinks
echo -e "${YELLOW}🔗 Removing binary symlinks...${NC}"
sudo rm -f /usr/local/bin/claude-workflow-install 2>/dev/null || true
sudo rm -f /usr/local/bin/claude-workflow-uninstall 2>/dev/null || true

# Remove installation directory
if [ -d "/usr/local/lib/claude-tools" ]; then
    echo -e "${YELLOW}📁 Removing installation directory...${NC}"
    sudo rm -rf "/usr/local/lib/claude-tools"
    echo "Removed: /usr/local/lib/claude-tools"
fi

# Clean up Docker containers (if any)
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Cleaning Docker containers...${NC}"
    docker ps -a --filter "name=mcp-" --format "{{.Names}}" | xargs -r docker rm -f 2>/dev/null || true
    echo "Cleaned Docker containers"
fi

# Remove worktrees if they exist
if [ -d "$HOME/Projects" ]; then
    echo -e "${YELLOW}🌳 Cleaning worktrees...${NC}"
    find "$HOME/Projects" -name ".worktrees" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "Cleaned worktrees"
fi

# Remove temporary files
echo -e "${YELLOW}🧹 Cleaning temporary files...${NC}"
rm -rf /tmp/claude-* 2>/dev/null || true
rm -rf /tmp/UI-iterations* 2>/dev/null || true

# Remove caches
rm -rf "$HOME/.cache/claude" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/claude-tools" 2>/dev/null || true

# Clean up logs
rm -rf "$HOME/Library/Logs/claude-tools" 2>/dev/null || true

# Verification
echo -e "${YELLOW}🔍 Verifying removal...${NC}"

verify_removal() {
    local path="$1"
    local description="$2"
    
    if [ -e "$path" ]; then
        echo -e "${RED}❌ Still exists: $description ($path)${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Removed: $description${NC}"
        return 0
    fi
}

REMOVAL_SUCCESS=true

verify_removal "$CLAUDE_CONFIG_DIR" "Configuration directory" || REMOVAL_SUCCESS=false
verify_removal "/usr/local/lib/claude-tools" "Installation directory" || REMOVAL_SUCCESS=false
verify_removal "/usr/local/bin/claude-workflow-install" "Install binary" || REMOVAL_SUCCESS=false
verify_removal "/usr/local/bin/claude-workflow-uninstall" "Uninstall binary" || REMOVAL_SUCCESS=false

# Check for remaining processes
if pgrep -f "claude-" > /dev/null 2>&1; then
    echo -e "${RED}❌ Claude processes still running${NC}"
    REMOVAL_SUCCESS=false
else
    echo -e "${GREEN}✅ No Claude processes running${NC}"
fi

# Final summary
echo ""
echo -e "${BLUE}📊 Uninstallation Summary${NC}"
echo "========================="

if [ "$REMOVAL_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ Claude Tools successfully removed${NC}"
else
    echo -e "${YELLOW}⚠️  Some files may remain - manual cleanup required${NC}"
fi

if [ "$KEEP_BACKUPS" = true ] && [ -d "$BACKUP_DIR" ]; then
    echo -e "${BLUE}💾 Backup available at: $BACKUP_DIR${NC}"
fi

echo ""
echo -e "${YELLOW}📋 Post-uninstallation steps:${NC}"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Verify removal: command -v claude-workflow-install"
echo "3. Remove any remaining manual configurations"

if [ "$KEEP_BACKUPS" = true ]; then
    echo "4. Delete backup if no longer needed: rm -rf $BACKUP_DIR"
fi

echo ""
if [ "$REMOVAL_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 Claude Tools has been successfully uninstalled!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Uninstallation completed with warnings${NC}"
    exit 1
fi