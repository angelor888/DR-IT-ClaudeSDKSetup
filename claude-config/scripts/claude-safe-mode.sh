#!/bin/bash
# Claude Safe Mode - Skip repetitive permissions for trusted operations
# Implements intelligent permission caching and safety overrides

set -euo pipefail

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
SAFE_MODE_CONFIG="$CLAUDE_CONFIG_DIR/safe-mode.json"
PERMISSIONS_CACHE="$CLAUDE_CONFIG_DIR/permissions-cache.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize safe mode
init_safe_mode() {
    mkdir -p "$CLAUDE_CONFIG_DIR"
    
    # Create safe mode configuration
    if [ ! -f "$SAFE_MODE_CONFIG" ]; then
        cat > "$SAFE_MODE_CONFIG" << 'EOF'
{
  "version": "1.0.0",
  "enabled": false,
  "strictMode": true,
  "trustedCommands": [
    "ls", "pwd", "cat", "head", "tail", "grep", "find", "git status", "git diff", "git log",
    "npm test", "npm run", "python -m pytest", "go test", "cargo test",
    "docker ps", "docker logs", "kubectl get", "kubectl describe"
  ],
  "dangerousCommands": [
    "rm -rf", "dd", "mkfs", "fdisk", "sudo rm", "sudo dd", "sudo mkfs",
    "chmod 777", "chown -R", "sudo chmod", "sudo chown",
    "curl | bash", "wget | bash", "> /dev/", "format", "del *"
  ],
  "cacheSettings": {
    "enabled": true,
    "expireHours": 24,
    "maxEntries": 1000,
    "requireReconfirmation": ["file deletion", "system modification", "network requests"]
  },
  "warningSettings": {
    "showWarnings": true,
    "requireConfirmation": true,
    "audioAlert": true,
    "logAllActions": true
  }
}
EOF
    fi
    
    # Initialize permissions cache
    if [ ! -f "$PERMISSIONS_CACHE" ]; then
        cat > "$PERMISSIONS_CACHE" << 'EOF'
{
  "version": "1.0.0",
  "cache": {},
  "statistics": {
    "totalQueries": 0,
    "cacheHits": 0,
    "cacheMisses": 0,
    "dangerousBlocked": 0
  }
}
EOF
    fi
    
    echo -e "${GREEN}✅ Safe mode initialized${NC}"
}

# Check if command is trusted
is_trusted_command() {
    local command="$1"
    
    # Check against trusted commands list
    if [ -f "$SAFE_MODE_CONFIG" ] && command -v jq &> /dev/null; then
        local trusted_commands
        trusted_commands=$(jq -r '.trustedCommands[]' "$SAFE_MODE_CONFIG" 2>/dev/null)
        
        # Check if command starts with any trusted pattern
        while IFS= read -r trusted; do
            if [[ "$command" == "$trusted"* ]]; then
                return 0
            fi
        done <<< "$trusted_commands"
    fi
    
    return 1
}

# Check if command is dangerous
is_dangerous_command() {
    local command="$1"
    
    # Check against dangerous commands list
    if [ -f "$SAFE_MODE_CONFIG" ] && command -v jq &> /dev/null; then
        local dangerous_commands
        dangerous_commands=$(jq -r '.dangerousCommands[]' "$SAFE_MODE_CONFIG" 2>/dev/null)
        
        # Check if command contains any dangerous pattern
        while IFS= read -r dangerous; do
            if [[ "$command" == *"$dangerous"* ]]; then
                return 0
            fi
        done <<< "$dangerous_commands"
    fi
    
    return 1
}

# Check permissions cache
check_permissions_cache() {
    local command="$1"
    local context="$2"
    
    if [ ! -f "$PERMISSIONS_CACHE" ] || ! command -v jq &> /dev/null; then
        return 1
    fi
    
    # Create cache key
    local cache_key
    cache_key=$(echo "$command:$context" | sha256sum | cut -d' ' -f1)
    
    # Check if cached and not expired
    local cached_entry
    cached_entry=$(jq -r ".cache[\"$cache_key\"]" "$PERMISSIONS_CACHE" 2>/dev/null)
    
    if [ "$cached_entry" != "null" ] && [ "$cached_entry" != "" ]; then
        local timestamp
        timestamp=$(echo "$cached_entry" | jq -r '.timestamp' 2>/dev/null)
        
        local expire_hours
        expire_hours=$(jq -r '.cacheSettings.expireHours // 24' "$SAFE_MODE_CONFIG" 2>/dev/null)
        
        local expire_seconds=$((expire_hours * 3600))
        local current_time=$(date +%s)
        
        if [ $((current_time - timestamp)) -lt $expire_seconds ]; then
            # Update cache hit statistics
            update_cache_stats "hit"
            return 0
        fi
    fi
    
    # Cache miss
    update_cache_stats "miss"
    return 1
}

# Cache permission decision
cache_permission() {
    local command="$1"
    local context="$2"
    local decision="$3"
    
    if [ ! -f "$PERMISSIONS_CACHE" ] || ! command -v jq &> /dev/null; then
        return 0
    fi
    
    # Create cache key
    local cache_key
    cache_key=$(echo "$command:$context" | sha256sum | cut -d' ' -f1)
    
    # Cache entry
    local timestamp
    timestamp=$(date +%s)
    
    local temp_cache="/tmp/permissions_cache.json"
    
    jq ".cache[\"$cache_key\"] = {
        \"command\": \"$command\",
        \"context\": \"$context\",
        \"decision\": \"$decision\",
        \"timestamp\": $timestamp
    }" "$PERMISSIONS_CACHE" > "$temp_cache"
    
    mv "$temp_cache" "$PERMISSIONS_CACHE"
    
    # Clean old entries
    clean_cache
}

# Update cache statistics
update_cache_stats() {
    local stat_type="$1"
    
    if [ ! -f "$PERMISSIONS_CACHE" ] || ! command -v jq &> /dev/null; then
        return 0
    fi
    
    local temp_cache="/tmp/permissions_cache.json"
    
    case "$stat_type" in
        "hit")
            jq '.statistics.totalQueries += 1 | .statistics.cacheHits += 1' "$PERMISSIONS_CACHE" > "$temp_cache"
            ;;
        "miss")
            jq '.statistics.totalQueries += 1 | .statistics.cacheMisses += 1' "$PERMISSIONS_CACHE" > "$temp_cache"
            ;;
        "blocked")
            jq '.statistics.dangerousBlocked += 1' "$PERMISSIONS_CACHE" > "$temp_cache"
            ;;
    esac
    
    mv "$temp_cache" "$PERMISSIONS_CACHE"
}

# Clean old cache entries
clean_cache() {
    if [ ! -f "$PERMISSIONS_CACHE" ] || ! command -v jq &> /dev/null; then
        return 0
    fi
    
    local expire_hours
    expire_hours=$(jq -r '.cacheSettings.expireHours // 24' "$SAFE_MODE_CONFIG" 2>/dev/null)
    
    local expire_seconds=$((expire_hours * 3600))
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - expire_seconds))
    
    local temp_cache="/tmp/permissions_cache.json"
    
    jq ".cache = (.cache | to_entries | map(select(.value.timestamp >= $cutoff_time)) | from_entries)" "$PERMISSIONS_CACHE" > "$temp_cache"
    
    mv "$temp_cache" "$PERMISSIONS_CACHE"
}

# Check permission with safe mode logic
check_permission() {
    local command="$1"
    local context="${2:-general}"
    
    # Check if safe mode is enabled
    local safe_mode_enabled
    safe_mode_enabled=$(jq -r '.enabled // false' "$SAFE_MODE_CONFIG" 2>/dev/null)
    
    if [ "$safe_mode_enabled" != "true" ]; then
        echo "permission_required"
        return 0
    fi
    
    # Check if command is dangerous
    if is_dangerous_command "$command"; then
        echo -e "${RED}🚨 DANGEROUS COMMAND DETECTED: $command${NC}" >&2
        echo -e "${RED}❌ This command is blocked for safety${NC}" >&2
        
        # Audio alert
        if [ -x ~/.config/claude/scripts/claude-audio-notifications.sh ]; then
            ~/.config/claude/scripts/claude-audio-notifications.sh context "error" "Dangerous command blocked" false &
        fi
        
        update_cache_stats "blocked"
        echo "blocked"
        return 0
    fi
    
    # Check cache first
    if check_permissions_cache "$command" "$context"; then
        echo "cached_approved"
        return 0
    fi
    
    # Check if command is trusted
    if is_trusted_command "$command"; then
        cache_permission "$command" "$context" "approved"
        echo "trusted_approved"
        return 0
    fi
    
    # Default: require permission
    echo "permission_required"
    return 0
}

# Enable safe mode
enable_safe_mode() {
    local strict_mode="${1:-true}"
    
    if [ -f "$SAFE_MODE_CONFIG" ] && command -v jq &> /dev/null; then
        local temp_config="/tmp/safe_mode_config.json"
        jq ".enabled = true | .strictMode = $strict_mode" "$SAFE_MODE_CONFIG" > "$temp_config"
        mv "$temp_config" "$SAFE_MODE_CONFIG"
        
        echo -e "${GREEN}✅ Safe mode enabled${NC}"
        if [ "$strict_mode" = "true" ]; then
            echo -e "${YELLOW}⚠️  Strict mode: Only trusted commands auto-approved${NC}"
        else
            echo -e "${BLUE}💡 Permissive mode: More commands auto-approved${NC}"
        fi
    fi
}

# Disable safe mode
disable_safe_mode() {
    if [ -f "$SAFE_MODE_CONFIG" ] && command -v jq &> /dev/null; then
        local temp_config="/tmp/safe_mode_config.json"
        jq '.enabled = false' "$SAFE_MODE_CONFIG" > "$temp_config"
        mv "$temp_config" "$SAFE_MODE_CONFIG"
        
        echo -e "${YELLOW}⚠️  Safe mode disabled${NC}"
        echo -e "${BLUE}💡 All commands will require permission${NC}"
    fi
}

# Show safe mode status
show_safe_mode_status() {
    echo -e "${BLUE}🛡️  Claude Safe Mode Status${NC}"
    echo "=========================="
    
    if [ -f "$SAFE_MODE_CONFIG" ] && command -v jq &> /dev/null; then
        local enabled
        enabled=$(jq -r '.enabled // false' "$SAFE_MODE_CONFIG")
        
        local strict_mode
        strict_mode=$(jq -r '.strictMode // true' "$SAFE_MODE_CONFIG")
        
        echo -e "${BLUE}Status:${NC} $([ "$enabled" = "true" ] && echo "Enabled" || echo "Disabled")"
        echo -e "${BLUE}Mode:${NC} $([ "$strict_mode" = "true" ] && echo "Strict" || echo "Permissive")"
        
        # Cache statistics
        if [ -f "$PERMISSIONS_CACHE" ]; then
            local total_queries
            total_queries=$(jq -r '.statistics.totalQueries // 0' "$PERMISSIONS_CACHE")
            
            local cache_hits
            cache_hits=$(jq -r '.statistics.cacheHits // 0' "$PERMISSIONS_CACHE")
            
            local cache_misses
            cache_misses=$(jq -r '.statistics.cacheMisses // 0' "$PERMISSIONS_CACHE")
            
            local dangerous_blocked
            dangerous_blocked=$(jq -r '.statistics.dangerousBlocked // 0' "$PERMISSIONS_CACHE")
            
            echo ""
            echo -e "${BLUE}Cache Statistics:${NC}"
            echo "  Total queries: $total_queries"
            echo "  Cache hits: $cache_hits"
            echo "  Cache misses: $cache_misses"
            echo "  Dangerous blocked: $dangerous_blocked"
            
            if [ "$total_queries" -gt 0 ]; then
                local hit_rate
                hit_rate=$(echo "scale=1; $cache_hits * 100 / $total_queries" | bc -l 2>/dev/null || echo "0")
                echo "  Hit rate: ${hit_rate}%"
            fi
        fi
    else
        echo -e "${RED}❌ Safe mode not initialized${NC}"
    fi
}

# Clear cache
clear_cache() {
    if [ -f "$PERMISSIONS_CACHE" ]; then
        cat > "$PERMISSIONS_CACHE" << 'EOF'
{
  "version": "1.0.0",
  "cache": {},
  "statistics": {
    "totalQueries": 0,
    "cacheHits": 0,
    "cacheMisses": 0,
    "dangerousBlocked": 0
  }
}
EOF
        echo -e "${GREEN}✅ Permissions cache cleared${NC}"
    fi
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_safe_mode
            ;;
        "enable")
            enable_safe_mode "${2:-true}"
            ;;
        "disable")
            disable_safe_mode
            ;;
        "status")
            show_safe_mode_status
            ;;
        "check")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-safe-mode check <command> [context]"
                return 1
            fi
            check_permission "$2" "${3:-general}"
            ;;
        "clear-cache")
            clear_cache
            ;;
        "help"|"-h"|"--help")
            echo "Claude Safe Mode - Intelligent Permission Management"
            echo ""
            echo "Usage: claude-safe-mode <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                    Initialize safe mode"
            echo "  enable [strict]         Enable safe mode (strict=true/false)"
            echo "  disable                 Disable safe mode"
            echo "  status                  Show safe mode status"
            echo "  check <cmd> [context]   Check command permission"
            echo "  clear-cache             Clear permissions cache"
            echo "  help                    Show this help message"
            echo ""
            echo "Features:"
            echo "  • Intelligent permission caching"
            echo "  • Trusted command auto-approval"
            echo "  • Dangerous command blocking"
            echo "  • Cache expiration and cleanup"
            echo "  • Audio alerts for dangerous commands"
            echo "  • Detailed statistics and logging"
            echo ""
            echo "Examples:"
            echo "  claude-safe-mode enable strict"
            echo "  claude-safe-mode check 'ls -la'"
            echo "  claude-safe-mode status"
            echo "  claude-safe-mode clear-cache"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run 'claude-safe-mode help' for usage information"
            return 1
            ;;
    esac
}

# Initialize on first run
if [ ! -f "$SAFE_MODE_CONFIG" ]; then
    echo -e "${YELLOW}🔧 First run: Initializing safe mode...${NC}"
    init_safe_mode
fi

# Run main function
main "$@"