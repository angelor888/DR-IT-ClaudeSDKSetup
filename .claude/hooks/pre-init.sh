#!/bin/bash

# Pre-init Hook - Runs before Claude Code initialization

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[pre-init] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[pre-init] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[pre-init] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[pre-init] $1${NC}" >&2
}

# Check prerequisites
check_prerequisites() {
    log_message "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if ! command -v claude >/dev/null 2>&1; then
        missing_deps+=("claude")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_message "Please install the missing dependencies and try again"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Prepare environment
prepare_environment() {
    log_message "Preparing environment..."
    
    # Create essential directories
    mkdir -p "$CLAUDE_DIR"/{scripts,hooks,commands,settings,logs,backups,memory,sounds,templates}
    
    # Set proper permissions
    chmod 755 "$CLAUDE_DIR"
    chmod 755 "$CLAUDE_DIR"/{scripts,hooks,commands,settings,logs,backups,memory,sounds,templates}
    
    # Create logs directory with proper permissions
    touch "$CLAUDE_DIR/logs/claude.log"
    chmod 644 "$CLAUDE_DIR/logs/claude.log"
    
    log_success "Environment prepared"
}

# Check git repository status
check_git_status() {
    log_message "Checking git repository status..."
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_warning "Not in a git repository"
        return 0
    fi
    
    local git_status=$(git status --porcelain 2>/dev/null || echo "")
    if [[ -n "$git_status" ]]; then
        log_message "Git repository has uncommitted changes"
        log_message "Consider committing changes before initialization"
    else
        log_success "Git repository is clean"
    fi
    
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    log_message "Current branch: $current_branch"
}

# Backup existing configuration
backup_existing_config() {
    log_message "Backing up existing configuration..."
    
    local backup_dir="$CLAUDE_DIR/backups/pre-init-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing Claude.md
    if [[ -f "Claude.md" ]]; then
        cp "Claude.md" "$backup_dir/Claude.md"
        log_message "Backed up existing Claude.md"
    fi
    
    # Backup existing settings
    if [[ -f "$CLAUDE_DIR/settings/settings.json" ]]; then
        cp "$CLAUDE_DIR/settings/settings.json" "$backup_dir/settings.json"
        log_message "Backed up existing settings"
    fi
    
    log_success "Configuration backup completed"
}

# Initialize logging
initialize_logging() {
    log_message "Initializing logging..."
    
    # Create log entry for initialization
    cat >> "$CLAUDE_DIR/logs/claude.log" <<EOF
[$TIMESTAMP] Pre-init hook started
[$TIMESTAMP] Project: $(basename "$(pwd)")
[$TIMESTAMP] Working directory: $(pwd)
[$TIMESTAMP] Git status: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files modified
[$TIMESTAMP] Claude version: $(claude --version 2>/dev/null || echo 'unknown')
EOF
    
    log_success "Logging initialized"
}

# Main execution
main() {
    log_message "Starting pre-init hook..."
    
    check_prerequisites
    prepare_environment
    check_git_status
    backup_existing_config
    initialize_logging
    
    log_success "Pre-init hook completed successfully"
}

# Execute main function
main "$@"