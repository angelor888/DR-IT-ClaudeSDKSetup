#!/bin/bash
set -euo pipefail

# Sync Claude Configuration FROM Local to Repository
# Use this in the evening to save your config changes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
REPO_CONFIG_DIR="$PROJECT_ROOT/claude-config"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "================================================"
echo "    Syncing Claude Config TO Repository"
echo "================================================"
echo

# Check if we're in a git repo
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo_error "Not in a git repository. Please run from DR-IT-ClaudeSDKSetup directory."
    exit 1
fi

# Create repo config directory if it doesn't exist
mkdir -p "$REPO_CONFIG_DIR"
mkdir -p "$REPO_CONFIG_DIR/scripts"
mkdir -p "$REPO_CONFIG_DIR/templates"
mkdir -p "$REPO_CONFIG_DIR/commands"
mkdir -p "$REPO_CONFIG_DIR/hooks"
mkdir -p "$REPO_CONFIG_DIR/audio"
mkdir -p "$REPO_CONFIG_DIR/clipboard"
mkdir -p "$REPO_CONFIG_DIR/ide"

# Check for uncommitted changes
cd "$PROJECT_ROOT"
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo_warning "You have uncommitted changes in the repository."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Sync cancelled."
        exit 0
    fi
fi

# Sync configuration files
echo_info "Syncing configuration files to repository..."

# Main config files (excluding sensitive ones)
for config in settings.json mode-config.json safe-mode.json multi-computer-sync.json worktrees.json shell-integration.sh; do
    if [ -f "$CLAUDE_CONFIG_DIR/$config" ]; then
        cp "$CLAUDE_CONFIG_DIR/$config" "$REPO_CONFIG_DIR/"
        echo_success "Copied $config"
    fi
done

# Sync scripts directory
echo_info "Syncing scripts..."
if [ -d "$CLAUDE_CONFIG_DIR/scripts" ]; then
    rsync -av \
        --exclude "*.log" \
        --exclude "*.tmp" \
        --exclude "*.cache" \
        "$CLAUDE_CONFIG_DIR/scripts/" "$REPO_CONFIG_DIR/scripts/"
    echo_success "Scripts synchronized"
fi

# Sync templates
echo_info "Syncing templates..."
if [ -d "$CLAUDE_CONFIG_DIR/templates" ]; then
    rsync -av "$CLAUDE_CONFIG_DIR/templates/" "$REPO_CONFIG_DIR/templates/"
    echo_success "Templates synchronized"
fi

# Sync commands
echo_info "Syncing commands..."
if [ -d "$CLAUDE_CONFIG_DIR/commands" ]; then
    rsync -av "$CLAUDE_CONFIG_DIR/commands/" "$REPO_CONFIG_DIR/commands/"
    echo_success "Commands synchronized"
fi

# Sync hooks
echo_info "Syncing hooks..."
if [ -d "$CLAUDE_CONFIG_DIR/hooks" ]; then
    rsync -av \
        --exclude "*.log" \
        --exclude "*.pid" \
        "$CLAUDE_CONFIG_DIR/hooks/" "$REPO_CONFIG_DIR/hooks/"
    echo_success "Hooks synchronized"
fi

# Sync other config directories
for dir in audio clipboard ide; do
    if [ -d "$CLAUDE_CONFIG_DIR/$dir" ]; then
        rsync -av \
            --exclude "*.log" \
            --exclude "*.cache" \
            "$CLAUDE_CONFIG_DIR/$dir/" "$REPO_CONFIG_DIR/$dir/"
        echo_success "Synchronized $dir configuration"
    fi
done

# Create environment template if it doesn't exist
if [ ! -f "$REPO_CONFIG_DIR/environment.template" ] && [ -f "$CLAUDE_CONFIG_DIR/environment" ]; then
    echo_info "Creating environment template..."
    # Create template with empty values
    sed 's/=.*/=/' "$CLAUDE_CONFIG_DIR/environment" > "$REPO_CONFIG_DIR/environment.template"
    echo_success "Created environment.template"
fi

# Update .gitignore to ensure sensitive files are excluded
echo_info "Updating .gitignore..."
GITIGNORE_FILE="$REPO_CONFIG_DIR/.gitignore"
touch "$GITIGNORE_FILE"

# Add entries if not present
for pattern in "environment" "environment.backup*" "*.log" "*.cache" "permissions-cache.json" ".DS_Store"; do
    if ! grep -q "^$pattern$" "$GITIGNORE_FILE" 2>/dev/null; then
        echo "$pattern" >> "$GITIGNORE_FILE"
    fi
done

# Show what will be committed
echo_info "Files to be added to git:"
cd "$PROJECT_ROOT"
git add claude-config/
git status --porcelain | grep "^A\|^M" | grep "claude-config/" || echo "  No changes in claude-config/"

# Count changes
CHANGES=$(git status --porcelain | grep "claude-config/" | wc -l | tr -d ' ')

if [ "$CHANGES" -eq 0 ]; then
    echo_info "No configuration changes to sync."
else
    echo
    echo_success "Found $CHANGES configuration changes"
    echo
    
    # Show diff summary
    echo_info "Summary of changes:"
    git diff --cached --stat | grep "claude-config/" || true
    
    echo
    read -p "Would you like to commit these changes? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Get commit message
        echo
        read -p "Enter commit message (or press Enter for default): " commit_msg
        
        if [ -z "$commit_msg" ]; then
            commit_msg="Update Claude configuration files"
        fi
        
        # Commit changes
        git commit -m "$commit_msg" -m "Updated via sync-to-repo.sh" \
            -m "" \
            -m "Co-Authored-By: Claude <noreply@anthropic.com>"
        
        echo_success "Changes committed!"
        echo
        echo "To push changes to remote: git push"
    else
        echo_info "Commit cancelled. Changes are staged but not committed."
    fi
fi

echo
echo_success "Sync to repository complete!"
echo
echo "Next steps:"
echo "1. Review the changes: git diff --cached"
echo "2. Push to remote: git push"
echo "3. On other computer: git pull && ./scripts/sync-from-repo.sh"
echo
echo "Remember: Never commit the 'environment' file with actual tokens!"