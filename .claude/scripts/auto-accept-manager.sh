#!/bin/bash

# Auto-Accept Manager Script
# Manages auto-accept mode for Claude Code sessions

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
AUTO_ACCEPT_CONFIG="$CLAUDE_DIR/settings/auto-accept.json"
SESSION_STATE="$CLAUDE_DIR/session/auto-accept-state.json"
SETTINGS_FILE="$CLAUDE_DIR/settings/settings.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Safety operations that should always require confirmation
DANGEROUS_OPERATIONS=(
    "rm -rf"
    "sudo"
    "chmod 777"
    "git push --force"
    "npm install"
    "pip install"
    "docker run"
    "systemctl"
    "killall"
    "pkill"
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
    echo -e "${BLUE}[auto-accept] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[auto-accept] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[auto-accept] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[auto-accept] $1${NC}" >&2
}

# Initialize auto-accept configuration
init_auto_accept_config() {
    if [[ ! -f "$AUTO_ACCEPT_CONFIG" ]]; then
        mkdir -p "$(dirname "$AUTO_ACCEPT_CONFIG")"
        cat > "$AUTO_ACCEPT_CONFIG" <<EOF
{
  "enabled": false,
  "timeout": 10,
  "safe_mode": true,
  "dangerous_operations": [
    "rm -rf",
    "sudo",
    "chmod 777",
    "git push --force",
    "npm install",
    "pip install",
    "docker run",
    "systemctl",
    "killall",
    "pkill"
  ],
  "always_confirm": [
    "file_deletion",
    "system_modification",
    "network_requests"
  ],
  "last_updated": "$TIMESTAMP"
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
  "auto_accept_enabled": false,
  "start_time": "$TIMESTAMP",
  "timeout": 10,
  "safe_mode": true,
  "operations_count": 0,
  "last_activity": "$TIMESTAMP"
}
EOF
}

# Get current auto-accept status
get_auto_accept_status() {
    if [[ -f "$SESSION_STATE" ]]; then
        jq -r '.auto_accept_enabled // false' "$SESSION_STATE" 2>/dev/null || echo "false"
    else
        echo "false"
    fi
}

# Get auto-accept timeout
get_auto_accept_timeout() {
    if [[ -f "$SESSION_STATE" ]]; then
        jq -r '.timeout // 10' "$SESSION_STATE" 2>/dev/null || echo "10"
    else
        echo "10"
    fi
}

# Check if operation is dangerous
is_dangerous_operation() {
    local operation="$1"
    
    for dangerous_op in "${DANGEROUS_OPERATIONS[@]}"; do
        if [[ "$operation" == *"$dangerous_op"* ]]; then
            return 0
        fi
    done
    return 1
}

# Enable auto-accept mode
enable_auto_accept() {
    local timeout=${1:-10}
    local safe_mode=${2:-true}
    
    log_message "Enabling auto-accept mode (timeout: ${timeout}s, safe: $safe_mode)"
    
    # Initialize if needed
    if [[ ! -f "$SESSION_STATE" ]]; then
        init_session_state
    fi
    
    # Update session state
    jq ".auto_accept_enabled = true | .timeout = $timeout | .safe_mode = $safe_mode | .last_activity = \"$TIMESTAMP\"" "$SESSION_STATE" > "$SESSION_STATE.tmp" && mv "$SESSION_STATE.tmp" "$SESSION_STATE"
    
    # Update settings file
    update_settings_file true
    
    log_success "Auto-accept mode enabled"
}

# Disable auto-accept mode
disable_auto_accept() {
    log_message "Disabling auto-accept mode"
    
    if [[ -f "$SESSION_STATE" ]]; then
        jq ".auto_accept_enabled = false | .last_activity = \"$TIMESTAMP\"" "$SESSION_STATE" > "$SESSION_STATE.tmp" && mv "$SESSION_STATE.tmp" "$SESSION_STATE"
    fi
    
    # Update settings file
    update_settings_file false
    
    log_success "Auto-accept mode disabled"
}

# Toggle auto-accept mode
toggle_auto_accept() {
    local current_status=$(get_auto_accept_status)
    
    if [[ "$current_status" == "true" ]]; then
        disable_auto_accept
    else
        enable_auto_accept
    fi
}

# Update settings file
update_settings_file() {
    local enabled="$1"
    
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Create backup
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
        
        # Update auto_accept setting
        jq ".interaction.auto_accept = $enabled" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        
        log_success "Settings file updated"
    else
        log_warning "Settings file not found"
    fi
}

# Display detailed status
display_status() {
    local current_status=$(get_auto_accept_status)
    local timeout=$(get_auto_accept_timeout)
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}🔄 Auto-Accept Mode Status${NC}                                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    
    if [[ "$current_status" == "true" ]]; then
        echo -e "${PURPLE}║${NC}  ${GREEN}🟢 Status: ENABLED${NC}                                                        ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${YELLOW}⏱️  Timeout: ${timeout} seconds${NC}                                                 ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}🛡️  Safety checks: Active${NC}                                                 ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${YELLOW}⚠️  Warning: Operations will be auto-accepted after timeout${NC}             ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${YELLOW}⚠️  Dangerous operations still require manual confirmation${NC}               ${PURPLE}║${NC}"
    else
        echo -e "${PURPLE}║${NC}  ${RED}🔴 Status: DISABLED${NC}                                                       ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}🛡️  All operations require manual confirmation${NC}                           ${PURPLE}║${NC}"
    fi
    
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${BLUE}📋 Controls:${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}• Use /auto-accept toggle to switch modes${NC}                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}• Use Ctrl+A keyboard shortcut for quick toggle${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}• Use /auto-accept status to check current mode${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Show simple status
show_status() {
    local current_status=$(get_auto_accept_status)
    
    if [[ "$current_status" == "true" ]]; then
        echo -e "${GREEN}🟢 Auto-accept mode: ENABLED${NC}"
        echo -e "${YELLOW}⏱️  Timeout: $(get_auto_accept_timeout) seconds${NC}"
    else
        echo -e "${RED}🔴 Auto-accept mode: DISABLED${NC}"
    fi
}

# Save current settings
save_settings() {
    init_auto_accept_config
    
    local current_status=$(get_auto_accept_status)
    local timeout=$(get_auto_accept_timeout)
    
    # Update configuration file
    jq ".enabled = $current_status | .timeout = $timeout | .last_updated = \"$TIMESTAMP\"" "$AUTO_ACCEPT_CONFIG" > "$AUTO_ACCEPT_CONFIG.tmp" && mv "$AUTO_ACCEPT_CONFIG.tmp" "$AUTO_ACCEPT_CONFIG"
    
    log_success "Auto-accept settings saved"
}

# Validate operation safety
validate_operation() {
    local operation="$1"
    
    if is_dangerous_operation "$operation"; then
        log_warning "Dangerous operation detected: $operation"
        echo "DANGEROUS"
        return 1
    else
        echo "SAFE"
        return 0
    fi
}

# Get session statistics
get_session_stats() {
    if [[ -f "$SESSION_STATE" ]]; then
        local session_id=$(jq -r '.session_id // "unknown"' "$SESSION_STATE" 2>/dev/null)
        local start_time=$(jq -r '.start_time // "unknown"' "$SESSION_STATE" 2>/dev/null)
        local operations_count=$(jq -r '.operations_count // 0' "$SESSION_STATE" 2>/dev/null)
        
        echo -e "${BLUE}Session Statistics:${NC}"
        echo -e "${CYAN}Session ID: $session_id${NC}"
        echo -e "${CYAN}Start Time: $start_time${NC}"
        echo -e "${CYAN}Operations: $operations_count${NC}"
    else
        echo -e "${YELLOW}No session data available${NC}"
    fi
}

# Main command handling
main() {
    local action=${1:-"status"}
    
    case "$action" in
        "on"|"enable")
            local timeout=${2:-10}
            local safe_mode=${3:-true}
            enable_auto_accept "$timeout" "$safe_mode"
            ;;
        "off"|"disable")
            disable_auto_accept
            ;;
        "toggle")
            toggle_auto_accept
            ;;
        "status")
            show_status
            ;;
        "display-status")
            display_status
            ;;
        "save-settings")
            save_settings
            ;;
        "validate")
            local operation=${2:-""}
            if [[ -z "$operation" ]]; then
                log_error "Please provide an operation to validate"
                return 1
            fi
            validate_operation "$operation"
            ;;
        "stats")
            get_session_stats
            ;;
        "init")
            init_auto_accept_config
            init_session_state
            log_success "Auto-accept system initialized"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [on|off|toggle|status|display-status|save-settings|validate|stats|init]"
            echo ""
            echo "Commands:"
            echo "  on [timeout] [safe_mode]    Enable auto-accept mode"
            echo "  off                         Disable auto-accept mode"
            echo "  toggle                      Toggle auto-accept mode"
            echo "  status                      Show current status"
            echo "  display-status             Show detailed status"
            echo "  save-settings              Save current settings"
            echo "  validate <operation>       Check if operation is safe"
            echo "  stats                      Show session statistics"
            echo "  init                       Initialize auto-accept system"
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