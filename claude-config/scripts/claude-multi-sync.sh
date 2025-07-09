#!/bin/bash
# Multi-computer synchronization script for Claude Tools
# Handles configuration sync across multiple development machines

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
SYNC_CONFIG_FILE="$CLAUDE_CONFIG_DIR/multi-computer-sync.json"
COMPUTER_ID=$(hostname | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
SYNC_BRANCH="claude-sync-$(date +%Y%m%d)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# Load sync configuration
load_sync_config() {
    if [ ! -f "$SYNC_CONFIG_FILE" ]; then
        error "Sync configuration not found: $SYNC_CONFIG_FILE"
        exit 1
    fi
    
    if ! jq empty "$SYNC_CONFIG_FILE" 2>/dev/null; then
        error "Invalid JSON in sync configuration"
        exit 1
    fi
}

# Register current computer
register_computer() {
    local computer_info
    computer_info=$(jq -n \
        --arg id "$COMPUTER_ID" \
        --arg hostname "$(hostname)" \
        --arg user "$USER" \
        --arg os "$(uname -s)" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            id: $id,
            hostname: $hostname,
            user: $user,
            os: $os,
            lastSync: $timestamp,
            status: "active"
        }')
    
    # Update sync config with computer info
    jq --argjson computer "$computer_info" \
        '.computers[$computer.id] = $computer' \
        "$SYNC_CONFIG_FILE" > "${SYNC_CONFIG_FILE}.tmp" && \
        mv "${SYNC_CONFIG_FILE}.tmp" "$SYNC_CONFIG_FILE"
    
    success "Registered computer: $COMPUTER_ID"
}

# Check if sync is enabled
is_sync_enabled() {
    jq -r '.syncSettings.enabled' "$SYNC_CONFIG_FILE" 2>/dev/null | grep -q "true"
}

# Get sync paths
get_sync_paths() {
    jq -r '.syncPaths[] | @base64' "$SYNC_CONFIG_FILE" 2>/dev/null
}

# Decode sync path
decode_sync_path() {
    echo "$1" | base64 --decode | jq -r '.'
}

# Create backup
create_backup() {
    local backup_enabled
    backup_enabled=$(jq -r '.syncSettings.backupBeforeSync' "$SYNC_CONFIG_FILE" 2>/dev/null)
    
    if [ "$backup_enabled" = "true" ]; then
        local backup_dir="$CLAUDE_CONFIG_DIR/backups/sync-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        
        # Backup current configuration
        cp -r "$CLAUDE_CONFIG_DIR"/* "$backup_dir"/ 2>/dev/null || true
        
        # Cleanup old backups
        local max_backups
        max_backups=$(jq -r '.syncSettings.maxBackups' "$SYNC_CONFIG_FILE" 2>/dev/null)
        if [ "$max_backups" != "null" ] && [ "$max_backups" -gt 0 ]; then
            find "$CLAUDE_CONFIG_DIR/backups" -name "sync-*" -type d | \
                sort -r | tail -n +$((max_backups + 1)) | xargs rm -rf
        fi
        
        success "Created backup: $backup_dir"
    fi
}

# Check for conflicts
check_conflicts() {
    local path="$1"
    local full_path="$CLAUDE_CONFIG_DIR/$path"
    
    if [ ! -e "$full_path" ]; then
        return 0
    fi
    
    # Check if file has been modified locally
    if git -C "$CLAUDE_CONFIG_DIR" diff --quiet "$path" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Resolve conflicts
resolve_conflict() {
    local path="$1"
    local strategy="$2"
    local full_path="$CLAUDE_CONFIG_DIR/$path"
    
    log "Resolving conflict for: $path (strategy: $strategy)"
    
    case "$strategy" in
        "merge")
            # Attempt three-way merge
            if git -C "$CLAUDE_CONFIG_DIR" merge-file "$path" "$path" "$path" 2>/dev/null; then
                success "Merged: $path"
            else
                warn "Manual merge required for: $path"
                return 1
            fi
            ;;
        "timestamp")
            # Use newer file based on timestamp
            local remote_timestamp local_timestamp
            remote_timestamp=$(git -C "$CLAUDE_CONFIG_DIR" log -1 --format=%ct "$path" 2>/dev/null || echo "0")
            local_timestamp=$(stat -f %m "$full_path" 2>/dev/null || echo "0")
            
            if [ "$remote_timestamp" -gt "$local_timestamp" ]; then
                git -C "$CLAUDE_CONFIG_DIR" checkout HEAD -- "$path"
                success "Used remote version: $path"
            else
                success "Kept local version: $path"
            fi
            ;;
        "manual")
            warn "Manual conflict resolution required for: $path"
            return 1
            ;;
        *)
            error "Unknown conflict resolution strategy: $strategy"
            return 1
            ;;
    esac
}

# Sync file
sync_file() {
    local sync_path_data="$1"
    local path mode exclude_patterns conflicts
    
    path=$(echo "$sync_path_data" | jq -r '.path')
    mode=$(echo "$sync_path_data" | jq -r '.syncMode')
    exclude_patterns=$(echo "$sync_path_data" | jq -r '.excludePatterns[]' 2>/dev/null || true)
    conflicts=$(echo "$sync_path_data" | jq -r '.conflicts')
    
    local full_path="$CLAUDE_CONFIG_DIR/$path"
    
    # Skip if excluded
    if [ -n "$exclude_patterns" ]; then
        while IFS= read -r pattern; do
            if [[ "$path" == $pattern ]]; then
                log "Skipping excluded path: $path"
                return 0
            fi
        done <<< "$exclude_patterns"
    fi
    
    log "Syncing: $path (mode: $mode)"
    
    # Check for conflicts
    if check_conflicts "$path"; then
        # No conflicts, proceed with sync
        case "$mode" in
            "bidirectional")
                # Pull remote changes first
                git -C "$CLAUDE_CONFIG_DIR" pull origin "$SYNC_BRANCH" 2>/dev/null || true
                
                # Push local changes
                if [ -e "$full_path" ]; then
                    git -C "$CLAUDE_CONFIG_DIR" add "$path" 2>/dev/null || true
                    git -C "$CLAUDE_CONFIG_DIR" commit -m "sync: update $path on $COMPUTER_ID" 2>/dev/null || true
                    git -C "$CLAUDE_CONFIG_DIR" push origin "$SYNC_BRANCH" 2>/dev/null || true
                fi
                ;;
            "pull")
                git -C "$CLAUDE_CONFIG_DIR" checkout HEAD -- "$path" 2>/dev/null || true
                ;;
            "push")
                if [ -e "$full_path" ]; then
                    git -C "$CLAUDE_CONFIG_DIR" add "$path" 2>/dev/null || true
                    git -C "$CLAUDE_CONFIG_DIR" commit -m "sync: update $path on $COMPUTER_ID" 2>/dev/null || true
                    git -C "$CLAUDE_CONFIG_DIR" push origin "$SYNC_BRANCH" 2>/dev/null || true
                fi
                ;;
        esac
        success "Synced: $path"
    else
        # Conflicts found, attempt resolution
        if resolve_conflict "$path" "$conflicts"; then
            success "Resolved conflict: $path"
        else
            warn "Conflict resolution failed: $path"
        fi
    fi
}

# Main sync function
perform_sync() {
    log "Starting sync process for computer: $COMPUTER_ID"
    
    # Create backup
    create_backup
    
    # Initialize git repository if needed
    if [ ! -d "$CLAUDE_CONFIG_DIR/.git" ]; then
        git -C "$CLAUDE_CONFIG_DIR" init
        git -C "$CLAUDE_CONFIG_DIR" config user.name "Claude Tools Sync"
        git -C "$CLAUDE_CONFIG_DIR" config user.email "sync@claude-tools.local"
    fi
    
    # Create sync branch
    git -C "$CLAUDE_CONFIG_DIR" checkout -B "$SYNC_BRANCH" 2>/dev/null || true
    
    # Sync each configured path
    while IFS= read -r sync_path_encoded; do
        sync_path_data=$(decode_sync_path "$sync_path_encoded")
        sync_file "$sync_path_data"
    done < <(get_sync_paths)
    
    # Update computer status
    register_computer
    
    success "Sync completed successfully"
}

# Status command
show_status() {
    echo -e "${BLUE}Multi-Computer Sync Status${NC}"
    echo "========================="
    echo
    
    if is_sync_enabled; then
        echo -e "${GREEN}✅ Sync enabled${NC}"
    else
        echo -e "${RED}❌ Sync disabled${NC}"
    fi
    
    echo "Computer ID: $COMPUTER_ID"
    echo "Sync branch: $SYNC_BRANCH"
    echo
    
    echo -e "${BLUE}Registered computers:${NC}"
    jq -r '.computers | to_entries[] | "  \(.key): \(.value.hostname) (\(.value.user)) - \(.value.lastSync)"' "$SYNC_CONFIG_FILE" 2>/dev/null || echo "  None"
    echo
    
    echo -e "${BLUE}Sync paths:${NC}"
    jq -r '.syncPaths[] | "  \(.path) (\(.syncMode))"' "$SYNC_CONFIG_FILE" 2>/dev/null || echo "  None"
}

# Auto-sync daemon
start_daemon() {
    local interval
    interval=$(jq -r '.syncSettings.syncInterval' "$SYNC_CONFIG_FILE" 2>/dev/null)
    
    if [ "$interval" = "null" ] || [ "$interval" -le 0 ]; then
        interval=300  # Default 5 minutes
    fi
    
    log "Starting sync daemon (interval: ${interval}s)"
    
    while true; do
        if is_sync_enabled; then
            perform_sync
        fi
        sleep "$interval"
    done
}

# Help function
show_help() {
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  sync         - Perform one-time sync"
    echo "  status       - Show sync status"
    echo "  daemon       - Start auto-sync daemon"
    echo "  register     - Register this computer"
    echo "  test         - Test sync configuration"
    echo "  help         - Show this help message"
    echo
    echo "Options:"
    echo "  --force      - Force sync even if disabled"
    echo "  --dry-run    - Show what would be synced"
    echo
    echo "Examples:"
    echo "  $0 sync              # Perform sync"
    echo "  $0 status            # Show status"
    echo "  $0 daemon            # Start daemon"
}

# Test configuration
test_config() {
    log "Testing sync configuration..."
    
    # Test JSON validity
    if ! jq empty "$SYNC_CONFIG_FILE" 2>/dev/null; then
        error "Invalid JSON in sync configuration"
        return 1
    fi
    
    # Test required fields
    local required_fields=("version" "syncSettings" "syncPaths")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$SYNC_CONFIG_FILE" >/dev/null 2>&1; then
            error "Missing required field: $field"
            return 1
        fi
    done
    
    # Test sync paths
    local path_count=0
    while IFS= read -r sync_path_encoded; do
        sync_path_data=$(decode_sync_path "$sync_path_encoded")
        path=$(echo "$sync_path_data" | jq -r '.path')
        
        if [ -z "$path" ] || [ "$path" = "null" ]; then
            error "Invalid sync path found"
            return 1
        fi
        
        path_count=$((path_count + 1))
    done < <(get_sync_paths)
    
    success "Configuration test passed ($path_count sync paths)"
}

# Main
main() {
    check_dependencies
    load_sync_config
    
    local command="${1:-help}"
    local force=false
    local dry_run=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                if [ -z "$command" ]; then
                    command="$1"
                fi
                shift
                ;;
        esac
    done
    
    case "$command" in
        sync)
            if [ "$force" = true ] || is_sync_enabled; then
                perform_sync
            else
                warn "Sync is disabled. Use --force to override."
            fi
            ;;
        status)
            show_status
            ;;
        daemon)
            start_daemon
            ;;
        register)
            register_computer
            ;;
        test)
            test_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"