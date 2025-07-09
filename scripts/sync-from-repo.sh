#!/bin/bash
set -euo pipefail

# Sync Claude Configuration FROM Repository to Local
# Use this in the morning to get latest configs

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
echo "    Syncing Claude Config FROM Repository"
echo "================================================"
echo

# Check if we're in a git repo
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo_error "Not in a git repository. Please run from DR-IT-ClaudeSDKSetup directory."
    exit 1
fi

# Pull latest changes
echo_info "Pulling latest changes from git..."
cd "$PROJECT_ROOT"
git pull || echo_warning "Could not pull latest changes. Continuing with local version..."

# Create backup of current config
BACKUP_DIR="$CLAUDE_CONFIG_DIR/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo_info "Creating backup at $BACKUP_DIR..."

# Backup critical files
for file in settings.json mode-config.json shell-integration.sh; do
    if [ -f "$CLAUDE_CONFIG_DIR/$file" ]; then
        cp "$CLAUDE_CONFIG_DIR/$file" "$BACKUP_DIR/"
    fi
done

# Sync configuration files
echo_info "Syncing configuration files..."

# Main config files
for config in settings.json mode-config.json safe-mode.json multi-computer-sync.json worktrees.json shell-integration.sh; do
    if [ -f "$REPO_CONFIG_DIR/$config" ]; then
        cp "$REPO_CONFIG_DIR/$config" "$CLAUDE_CONFIG_DIR/"
        echo_success "Updated $config"
    fi
done

# Sync scripts directory
echo_info "Syncing scripts..."
if [ -d "$REPO_CONFIG_DIR/scripts" ]; then
    rsync -av --delete \
        --exclude "*.log" \
        --exclude "*.tmp" \
        "$REPO_CONFIG_DIR/scripts/" "$CLAUDE_CONFIG_DIR/scripts/"
    chmod +x "$CLAUDE_CONFIG_DIR/scripts/"*.sh
    echo_success "Scripts synchronized"
fi

# Sync templates
echo_info "Syncing templates..."
if [ -d "$REPO_CONFIG_DIR/templates" ]; then
    rsync -av --delete "$REPO_CONFIG_DIR/templates/" "$CLAUDE_CONFIG_DIR/templates/"
    echo_success "Templates synchronized"
fi

# Sync commands
echo_info "Syncing commands..."
if [ -d "$REPO_CONFIG_DIR/commands" ]; then
    rsync -av --delete "$REPO_CONFIG_DIR/commands/" "$CLAUDE_CONFIG_DIR/commands/"
    echo_success "Commands synchronized"
fi

# Sync hooks
echo_info "Syncing hooks..."
if [ -d "$REPO_CONFIG_DIR/hooks" ]; then
    rsync -av --delete \
        --exclude "*.log" \
        "$REPO_CONFIG_DIR/hooks/" "$CLAUDE_CONFIG_DIR/hooks/"
    find "$CLAUDE_CONFIG_DIR/hooks" -name "*.sh" -exec chmod +x {} \;
    echo_success "Hooks synchronized"
fi

# Sync audio and clipboard configs
for dir in audio clipboard ide; do
    if [ -d "$REPO_CONFIG_DIR/$dir" ]; then
        mkdir -p "$CLAUDE_CONFIG_DIR/$dir"
        rsync -av "$REPO_CONFIG_DIR/$dir/" "$CLAUDE_CONFIG_DIR/$dir/"
        echo_success "Synchronized $dir configuration"
    fi
done

# Update Claude.md if exists
if [ -f "$PROJECT_ROOT/Claude.md" ]; then
    # Check if there's a project-specific Claude.md
    CURRENT_PROJECT_DIR="$(pwd)"
    if [ "$CURRENT_PROJECT_DIR" != "$PROJECT_ROOT" ] && [ -f "$CURRENT_PROJECT_DIR/Claude.md" ]; then
        echo_info "Updating project Claude.md with latest learnings..."
        # Append new learnings section if it exists
        if grep -q "### Memory Sync" "$PROJECT_ROOT/Claude.md"; then
            # Extract learnings section and append to current project's Claude.md
            sed -n '/### Memory Sync/,$p' "$PROJECT_ROOT/Claude.md" >> "$CURRENT_PROJECT_DIR/Claude.md"
            echo_success "Updated project Claude.md"
        fi
    fi
fi

# Verify critical files
echo_info "Verifying synchronization..."
MISSING_FILES=0
for critical_file in settings.json shell-integration.sh; do
    if [ ! -f "$CLAUDE_CONFIG_DIR/$critical_file" ]; then
        echo_error "Critical file missing: $critical_file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    echo_success "All critical files synchronized successfully!"
else
    echo_error "Some critical files are missing. Please check the sync."
    exit 1
fi

# Reload shell integration if in interactive shell
if [ -n "$PS1" ]; then
    echo_info "Reloading shell integration..."
    source "$CLAUDE_CONFIG_DIR/shell-integration.sh"
    echo_success "Shell integration reloaded"
fi

echo
echo_success "Synchronization complete!"
echo
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.config/claude/shell-integration.sh"
echo "2. Verify settings with: claude --version"
echo "3. Check your environment file has all required tokens"
echo
echo "Backup created at: $BACKUP_DIR"