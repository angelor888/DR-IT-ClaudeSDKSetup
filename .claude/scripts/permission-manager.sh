#!/bin/bash

# Permission Manager Script
# Manages permission caching and safe mode for faster development

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
PERMISSION_CONFIG="$CLAUDE_DIR/settings/permissions.json"
PERMISSION_CACHE="$CLAUDE_DIR/cache/permissions.json"
SESSION_STATE="$CLAUDE_DIR/session/permissions-state.json"
SETTINGS_FILE="$CLAUDE_DIR/settings/settings.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Permission scopes
PERMISSION_SCOPES=(
    "file_ops"
    "git_ops"
    "network_ops"
    "system_ops"
    "all"
)

# Safety levels
SAFETY_LEVELS=(
    "strict"
    "moderate"
    "permissive"
)

# Never skip these operations
NEVER_SKIP_OPERATIONS=(
    "sudo"
    "rm -rf /"
    "chmod 777 /"
    "chown root"
    "systemctl"
    "service"
    "passwd"
    "usermod"
    "userdel"
    "groupmod"
    "mount"
    "umount"
    "fdisk"
    "mkfs"
    "format"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[permission-manager] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[permission-manager] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[permission-manager] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[permission-manager] $1${NC}" >&2
}

# Initialize permission configuration
init_permission_config() {
    if [[ ! -f "$PERMISSION_CONFIG" ]]; then
        mkdir -p "$(dirname "$PERMISSION_CONFIG")"
        cat > "$PERMISSION_CONFIG" <<EOF
{
  "skip_permissions": false,
  "duration": "30m",
  "scope": "file_ops",
  "safety_level": "moderate",
  "enabled_at": null,
  "expires_at": null,
  "operations_cached": 0,
  "never_skip_operations": [
    "sudo",
    "rm -rf /",
    "chmod 777 /",
    "chown root",
    "systemctl",
    "service",
    "passwd",
    "usermod",
    "userdel",
    "groupmod",
    "mount",
    "umount",
    "fdisk",
    "mkfs",
    "format"
  ],
  "last_updated": "$TIMESTAMP"
}
EOF
    fi
}

# Initialize permission cache
init_permission_cache() {
    if [[ ! -f "$PERMISSION_CACHE" ]]; then
        mkdir -p "$(dirname "$PERMISSION_CACHE")"
        cat > "$PERMISSION_CACHE" <<EOF
{
  "cached_permissions": {},
  "operation_history": [],
  "safety_violations": [],
  "last_cleared": "$TIMESTAMP"
}
EOF
    fi
}

# Initialize session state
init_session_state() {
    mkdir -p "$(dirname "$SESSION_STATE")"
    cat > "$SESSION_STATE" <<EOF
{
  "session_id": "$(date +%s)",
  "permissions_skipped": false,
  "start_time": "$TIMESTAMP",
  "operations_count": 0,
  "warnings_shown": 0,
  "safety_violations": 0,
  "last_activity": "$TIMESTAMP"
}
EOF
}

# Check if permissions are currently being skipped
is_permissions_skipped() {
    if [[ -f "$SESSION_STATE" ]]; then
        local skipped=$(jq -r '.permissions_skipped // false' "$SESSION_STATE" 2>/dev/null)
        echo "$skipped"
    else
        echo "false"
    fi
}

# Check if permission skip has expired
is_permission_expired() {
    if [[ ! -f "$PERMISSION_CONFIG" ]]; then
        echo "true"
        return 0
    fi
    
    local expires_at=$(jq -r '.expires_at // null' "$PERMISSION_CONFIG" 2>/dev/null)
    
    if [[ "$expires_at" == "null" || "$expires_at" == "-1" ]]; then
        echo "false"
        return 0
    fi
    
    local current_time=$(date +%s)
    local expiry_time=$(date -d "$expires_at" +%s 2>/dev/null || echo "0")
    
    if [[ $current_time -gt $expiry_time ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Calculate expiry time
calculate_expiry() {
    local duration="$1"
    
    case "$duration" in
        "5m")
            date -d "+5 minutes" -u +"%Y-%m-%dT%H:%M:%SZ"
            ;;
        "15m")
            date -d "+15 minutes" -u +"%Y-%m-%dT%H:%M:%SZ"
            ;;
        "30m")
            date -d "+30 minutes" -u +"%Y-%m-%dT%H:%M:%SZ"
            ;;
        "1h")
            date -d "+1 hour" -u +"%Y-%m-%dT%H:%M:%SZ"
            ;;
        "session")
            echo "-1"
            ;;
        *)
            date -d "+30 minutes" -u +"%Y-%m-%dT%H:%M:%SZ"
            ;;
    esac
}

# Validate operation safety
validate_operation() {
    local operation="$1"
    local scope=${2:-"all"}
    local safety_level=${3:-"moderate"}
    
    # Check if operation should never be skipped
    for never_skip in "${NEVER_SKIP_OPERATIONS[@]}"; do
        if [[ "$operation" == *"$never_skip"* ]]; then
            log_warning "Operation '$operation' can never skip permissions"
            echo "NEVER_SKIP"
            return 1
        fi
    done
    
    # Check scope restrictions
    case "$scope" in
        "file_ops")
            if [[ "$operation" == *"git"* ]] || [[ "$operation" == *"curl"* ]] || [[ "$operation" == *"wget"* ]]; then
                echo "SCOPE_VIOLATION"
                return 1
            fi
            ;;
        "git_ops")
            if [[ "$operation" != *"git"* ]]; then
                echo "SCOPE_VIOLATION"
                return 1
            fi
            ;;
        "network_ops")
            if [[ "$operation" != *"curl"* ]] && [[ "$operation" != *"wget"* ]] && [[ "$operation" != *"ping"* ]]; then
                echo "SCOPE_VIOLATION"
                return 1
            fi
            ;;
        "system_ops")
            if [[ "$operation" != *"ps"* ]] && [[ "$operation" != *"kill"* ]] && [[ "$operation" != *"service"* ]]; then
                echo "SCOPE_VIOLATION"
                return 1
            fi
            ;;
    esac
    
    # Check safety level
    case "$safety_level" in
        "strict")
            if [[ "$operation" == *"rm"* ]] || [[ "$operation" == *"mv"* ]] || [[ "$operation" == *"cp"* ]]; then
                echo "SAFETY_VIOLATION"
                return 1
            fi
            ;;
        "moderate")
            if [[ "$operation" == *"rm -rf"* ]] || [[ "$operation" == *"chmod 777"* ]]; then
                echo "SAFETY_VIOLATION"
                return 1
            fi
            ;;
        "permissive")
            # Most operations allowed, but still check never_skip
            ;;
    esac
    
    echo "SAFE"
    return 0
}

# Enable permission skipping
enable_skip_permissions() {
    local duration=${1:-"30m"}
    local scope=${2:-"file_ops"}
    local safety_level=${3:-"moderate"}
    
    log_message "Enabling permission skipping (duration: $duration, scope: $scope, safety: $safety_level)"
    
    # Initialize if needed
    init_permission_config
    init_session_state
    
    # Calculate expiry
    local expires_at=$(calculate_expiry "$duration")
    
    # Update configuration
    jq ".skip_permissions = true | .duration = \"$duration\" | .scope = \"$scope\" | .safety_level = \"$safety_level\" | .enabled_at = \"$TIMESTAMP\" | .expires_at = \"$expires_at\" | .last_updated = \"$TIMESTAMP\"" "$PERMISSION_CONFIG" > "$PERMISSION_CONFIG.tmp" && mv "$PERMISSION_CONFIG.tmp" "$PERMISSION_CONFIG"
    
    # Update session state
    jq ".permissions_skipped = true | .last_activity = \"$TIMESTAMP\"" "$SESSION_STATE" > "$SESSION_STATE.tmp" && mv "$SESSION_STATE.tmp" "$SESSION_STATE"
    
    # Update settings file
    update_settings_file true
    
    log_success "Permission skipping enabled"
}

# Disable permission skipping
disable_skip_permissions() {
    log_message "Disabling permission skipping"
    
    if [[ -f "$PERMISSION_CONFIG" ]]; then
        jq ".skip_permissions = false | .enabled_at = null | .expires_at = null | .last_updated = \"$TIMESTAMP\"" "$PERMISSION_CONFIG" > "$PERMISSION_CONFIG.tmp" && mv "$PERMISSION_CONFIG.tmp" "$PERMISSION_CONFIG"
    fi
    
    if [[ -f "$SESSION_STATE" ]]; then
        jq ".permissions_skipped = false | .last_activity = \"$TIMESTAMP\"" "$SESSION_STATE" > "$SESSION_STATE.tmp" && mv "$SESSION_STATE.tmp" "$SESSION_STATE"
    fi
    
    # Update settings file
    update_settings_file false
    
    log_success "Permission skipping disabled"
}

# Toggle permission skipping
toggle_skip_permissions() {
    local current_status=$(is_permissions_skipped)
    
    if [[ "$current_status" == "true" ]]; then
        disable_skip_permissions
    else
        enable_skip_permissions
    fi
}

# Update settings file
update_settings_file() {
    local skip_enabled="$1"
    
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Create backup
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
        
        # Update skip_permissions setting
        jq ".permissions.skip_repetitive_checks = $skip_enabled" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        
        log_success "Settings file updated"
    else
        log_warning "Settings file not found"
    fi
}

# Display detailed status
display_status() {
    local current_status=$(is_permissions_skipped)
    local is_expired=$(is_permission_expired)
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}🔒 Permission Management Status${NC}                                            ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    
    if [[ "$current_status" == "true" ]] && [[ "$is_expired" == "false" ]]; then
        local duration=$(jq -r '.duration // "unknown"' "$PERMISSION_CONFIG" 2>/dev/null)
        local scope=$(jq -r '.scope // "unknown"' "$PERMISSION_CONFIG" 2>/dev/null)
        local safety_level=$(jq -r '.safety_level // "unknown"' "$PERMISSION_CONFIG" 2>/dev/null)
        local expires_at=$(jq -r '.expires_at // "unknown"' "$PERMISSION_CONFIG" 2>/dev/null)
        
        echo -e "${PURPLE}║${NC}  ${YELLOW}⚠️  Status: PERMISSIONS SKIPPED${NC}                                         ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}⏱️  Duration: $duration${NC}                                                     ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}🎯 Scope: $scope${NC}                                                           ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}🛡️  Safety Level: $safety_level${NC}                                           ${PURPLE}║${NC}"
        
        if [[ "$expires_at" != "-1" ]]; then
            echo -e "${PURPLE}║${NC}  ${YELLOW}⏰ Expires: $expires_at${NC}                                           ${PURPLE}║${NC}"
        else
            echo -e "${PURPLE}║${NC}  ${YELLOW}⏰ Expires: End of session${NC}                                         ${PURPLE}║${NC}"
        fi
        
        echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${RED}⚠️  WARNING: Use with caution - some safety checks are disabled${NC}       ${PURPLE}║${NC}"
    else
        echo -e "${PURPLE}║${NC}  ${GREEN}🔒 Status: PERMISSIONS REQUIRED${NC}                                        ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}🛡️  All operations require explicit confirmation${NC}                       ${PURPLE}║${NC}"
        
        if [[ "$is_expired" == "true" ]]; then
            echo -e "${PURPLE}║${NC}  ${YELLOW}⏰ Previous permission skip has expired${NC}                             ${PURPLE}║${NC}"
        fi
    fi
    
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${BLUE}📋 Controls:${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}• Use /skip-permissions toggle to switch modes${NC}                         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}• Use /skip-permissions status to check current mode${NC}                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}• Use /skip-permissions clear to reset cache${NC}                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Show simple status
show_status() {
    local current_status=$(is_permissions_skipped)
    local is_expired=$(is_permission_expired)
    
    if [[ "$current_status" == "true" ]] && [[ "$is_expired" == "false" ]]; then
        echo -e "${YELLOW}⚠️  Permission skipping: ENABLED${NC}"
        local duration=$(jq -r '.duration // "unknown"' "$PERMISSION_CONFIG" 2>/dev/null)
        local scope=$(jq -r '.scope // "unknown"' "$PERMISSION_CONFIG" 2>/dev/null)
        echo -e "${CYAN}⏱️  Duration: $duration, Scope: $scope${NC}"
    else
        echo -e "${GREEN}🔒 Permission skipping: DISABLED${NC}"
    fi
}

# Show warning message
show_warning() {
    local current_status=$(is_permissions_skipped)
    
    if [[ "$current_status" == "true" ]]; then
        echo -e "${RED}⚠️  WARNING: Permissions are being skipped!${NC}"
        echo -e "${YELLOW}⚠️  Some safety checks are disabled - use with caution${NC}"
        echo -e "${CYAN}ℹ️  Use /skip-permissions disable to re-enable full safety${NC}"
    fi
}

# Update permission cache
update_cache() {
    init_permission_cache
    
    local operation=${1:-""}
    local result=${2:-"allowed"}
    
    if [[ -n "$operation" ]]; then
        # Add to operation history
        local cache_entry="{\"operation\": \"$operation\", \"result\": \"$result\", \"timestamp\": \"$TIMESTAMP\"}"
        
        jq ".operation_history += [$cache_entry]" "$PERMISSION_CACHE" > "$PERMISSION_CACHE.tmp" && mv "$PERMISSION_CACHE.tmp" "$PERMISSION_CACHE"
        
        log_success "Permission cache updated"
    fi
}

# Clear permission cache
clear_cache() {
    log_message "Clearing permission cache"
    
    if [[ -f "$PERMISSION_CACHE" ]]; then
        jq ".cached_permissions = {} | .operation_history = [] | .safety_violations = [] | .last_cleared = \"$TIMESTAMP\"" "$PERMISSION_CACHE" > "$PERMISSION_CACHE.tmp" && mv "$PERMISSION_CACHE.tmp" "$PERMISSION_CACHE"
    fi
    
    log_success "Permission cache cleared"
}

# Get cache statistics
get_cache_stats() {
    if [[ -f "$PERMISSION_CACHE" ]]; then
        local operations_count=$(jq '.operation_history | length' "$PERMISSION_CACHE" 2>/dev/null)
        local violations_count=$(jq '.safety_violations | length' "$PERMISSION_CACHE" 2>/dev/null)
        local last_cleared=$(jq -r '.last_cleared // "unknown"' "$PERMISSION_CACHE" 2>/dev/null)
        
        echo -e "${BLUE}Permission Cache Statistics:${NC}"
        echo -e "${CYAN}Operations cached: $operations_count${NC}"
        echo -e "${CYAN}Safety violations: $violations_count${NC}"
        echo -e "${CYAN}Last cleared: $last_cleared${NC}"
    else
        echo -e "${YELLOW}No cache statistics available${NC}"
    fi
}

# Main command handling
main() {
    local action=${1:-"status"}
    
    case "$action" in
        "enable")
            local duration=${2:-"30m"}
            local scope=${3:-"file_ops"}
            local safety_level=${4:-"moderate"}
            enable_skip_permissions "$duration" "$scope" "$safety_level"
            ;;
        "disable")
            disable_skip_permissions
            ;;
        "toggle")
            toggle_skip_permissions
            ;;
        "status")
            show_status
            ;;
        "display-status")
            display_status
            ;;
        "validate")
            local operation=${2:-""}
            local scope=${3:-"all"}
            local safety_level=${4:-"moderate"}
            
            if [[ -z "$operation" ]]; then
                log_error "Please provide an operation to validate"
                return 1
            fi
            
            validate_operation "$operation" "$scope" "$safety_level"
            ;;
        "cache-update")
            local operation=${2:-""}
            local result=${3:-"allowed"}
            update_cache "$operation" "$result"
            ;;
        "cache")
            get_cache_stats
            ;;
        "clear")
            clear_cache
            ;;
        "show-warning")
            show_warning
            ;;
        "init")
            init_permission_config
            init_permission_cache
            init_session_state
            log_success "Permission management system initialized"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [enable|disable|toggle|status|display-status|validate|cache-update|cache|clear|show-warning|init]"
            echo ""
            echo "Commands:"
            echo "  enable [duration] [scope] [safety]  Enable permission skipping"
            echo "  disable                             Disable permission skipping"
            echo "  toggle                              Toggle permission skipping"
            echo "  status                              Show current status"
            echo "  display-status                      Show detailed status"
            echo "  validate <operation> [scope] [safety] Validate operation safety"
            echo "  cache-update <operation> [result]   Update permission cache"
            echo "  cache                               Show cache statistics"
            echo "  clear                               Clear permission cache"
            echo "  show-warning                        Show warning if permissions skipped"
            echo "  init                                Initialize permission system"
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Execute main function
main "$@"