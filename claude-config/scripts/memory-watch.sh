#!/bin/bash
#
# Memory Watch Task for Claude
# Monitors for "# memorize" patterns and appends to nearest Claude.md
# Version: 1.0.0
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.config/claude/logs"
MEMORY_LOG="$LOG_DIR/memory-watch.log"
WATCH_PIPE="/tmp/claude-memory-watch.pipe"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MEMORY_LOG"
}

# Find nearest Claude.md file
find_nearest_claude_md() {
    local current_dir="$1"
    
    # Check current directory first
    if [ -f "$current_dir/Claude.md" ]; then
        echo "$current_dir/Claude.md"
        return
    fi
    
    # Check parent directories
    while [ "$current_dir" != "/" ]; do
        current_dir="$(dirname "$current_dir")"
        if [ -f "$current_dir/Claude.md" ]; then
            echo "$current_dir/Claude.md"
            return
        fi
    done
    
    # Default to home Claude.md
    echo "$HOME/Claude.md"
}

# Append memory to Claude.md
append_memory() {
    local memory_text="$1"
    local working_dir="${2:-$(pwd)}"
    local claude_md=$(find_nearest_claude_md "$working_dir")
    
    log "Memorizing in $claude_md: $memory_text"
    
    # Ensure Learned Facts section exists
    if ! grep -q "## Learned Facts" "$claude_md" 2>/dev/null; then
        echo -e "\n## Learned Facts" >> "$claude_md"
        echo "<!-- This section is automatically updated by memory watch task -->" >> "$claude_md"
    fi
    
    # Append the memory with timestamp
    echo "# [$(date +'%Y-%m-%d %H:%M')] $memory_text" >> "$claude_md"
    
    log "Memory saved successfully"
}

# Process memory command
process_memory() {
    local input="$1"
    local working_dir="${2:-$(pwd)}"
    
    # Extract text after "# memorize"
    if [[ "$input" =~ ^#[[:space:]]*memorize[[:space:]]+(.+)$ ]]; then
        local memory_text="${BASH_REMATCH[1]}"
        append_memory "$memory_text" "$working_dir"
        return 0
    fi
    
    return 1
}

# Main watch loop (for testing/manual use)
main() {
    log "Memory watch started"
    
    # Create named pipe if it doesn't exist
    if [ ! -p "$WATCH_PIPE" ]; then
        mkfifo "$WATCH_PIPE"
        log "Created watch pipe at $WATCH_PIPE"
    fi
    
    echo "Memory watch active. Send '# memorize <text>' commands to $WATCH_PIPE"
    echo "Example: echo '# memorize This is important' > $WATCH_PIPE"
    
    # Watch for incoming memories
    while true; do
        if read -r line < "$WATCH_PIPE"; then
            if process_memory "$line"; then
                echo "✓ Memory saved"
            fi
        fi
    done
}

# Export functions for use by other scripts
export -f find_nearest_claude_md
export -f append_memory
export -f process_memory

# Run main if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-watch}" in
        watch)
            main
            ;;
        memorize)
            shift
            process_memory "# memorize $*" "$(pwd)"
            ;;
        test)
            echo "Testing memory watch..."
            process_memory "# memorize Test memory entry" "$(pwd)"
            echo "✓ Test complete"
            ;;
        *)
            echo "Usage: $0 [watch|memorize <text>|test]"
            exit 1
            ;;
    esac
fi