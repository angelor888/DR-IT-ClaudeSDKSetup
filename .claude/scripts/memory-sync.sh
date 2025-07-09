#!/bin/bash

# Memory Sync Script - Maintains persistent project memory across Claude sessions

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
CLAUDE_MD="Claude.md"
MEMORY_DIR="$CLAUDE_DIR/memory"
SESSION_LOG="$MEMORY_DIR/session.log"
CONTEXT_CACHE="$MEMORY_DIR/context.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[memory-sync] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[memory-sync] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[memory-sync] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[memory-sync] $1${NC}" >&2
}

# Initialize memory directory structure
init_memory_structure() {
    log_message "Initializing memory structure..."
    
    mkdir -p "$MEMORY_DIR"/{sessions,context,tasks,files}
    
    # Create session log if it doesn't exist
    if [[ ! -f "$SESSION_LOG" ]]; then
        cat > "$SESSION_LOG" <<EOF
# Claude Code Session Log
# This file tracks all Claude sessions and their contexts

## Session History
EOF
    fi
    
    log_success "Memory structure initialized"
}

# Capture current session context
capture_session_context() {
    log_message "Capturing session context..."
    
    local session_id=$(date +%s)
    local git_branch="unknown"
    local git_commit="unknown"
    local files_modified=0
    
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        files_modified=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Capture project state
    local project_state=$(cat <<EOF
{
  "session_id": "$session_id",
  "timestamp": "$TIMESTAMP",
  "project_root": "$(pwd)",
  "git_branch": "$git_branch",
  "git_commit": "$git_commit",
  "files_modified": $files_modified,
  "claude_version": "$(claude --version 2>/dev/null || echo 'unknown')",
  "working_directory": "$(pwd)",
  "environment": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "shell": "${SHELL##*/}"
  }
}
EOF
)
    
    # Save context to cache
    echo "$project_state" > "$CONTEXT_CACHE"
    
    # Add session entry to log
    cat >> "$SESSION_LOG" <<EOF

### Session $session_id - $(date '+%Y-%m-%d %H:%M:%S')
- **Branch**: $git_branch
- **Commit**: $git_commit
- **Modified Files**: $files_modified
- **Working Directory**: $(pwd)
- **Status**: Active
EOF
    
    log_success "Session context captured (ID: $session_id)"
}

# Sync memory with Claude.md
sync_memory_to_claude_md() {
    log_message "Syncing memory to Claude.md..."
    
    if [[ ! -f "$CLAUDE_MD" ]]; then
        log_warning "Claude.md not found, running auto-init..."
        if [[ -f "$CLAUDE_DIR/scripts/auto-init.sh" ]]; then
            "$CLAUDE_DIR/scripts/auto-init.sh"
        else
            log_error "Auto-init script not found"
            return 1
        fi
    fi
    
    # Extract key information from context cache
    if [[ -f "$CONTEXT_CACHE" ]]; then
        local session_id=$(jq -r '.session_id' "$CONTEXT_CACHE" 2>/dev/null || echo "unknown")
        local git_branch=$(jq -r '.git_branch' "$CONTEXT_CACHE" 2>/dev/null || echo "unknown")
        local files_modified=$(jq -r '.files_modified' "$CONTEXT_CACHE" 2>/dev/null || echo "0")
        
        # Create memory sync entry
        local memory_entry="
### Memory Sync - $(date '+%Y-%m-%d %H:%M:%S')
- **Session ID**: $session_id
- **Branch**: $git_branch
- **Modified Files**: $files_modified
- **Context**: Synchronized with persistent memory
- **Status**: Active session
"
        
        # Insert before the auto-update comment or append to end
        if grep -q "<!-- This section will be automatically updated" "$CLAUDE_MD"; then
            # Create a temporary file with the memory entry
            echo "$memory_entry" > /tmp/claude_memory.txt
            sed -i.bak '/<!-- This section will be automatically updated/r /tmp/claude_memory.txt' "$CLAUDE_MD"
            rm -f /tmp/claude_memory.txt
        else
            echo "$memory_entry" >> "$CLAUDE_MD"
        fi
        
        log_success "Memory synced to Claude.md"
    else
        log_warning "No context cache found"
    fi
}

# Load previous session context
load_previous_context() {
    log_message "Loading previous session context..."
    
    if [[ -f "$CONTEXT_CACHE" ]]; then
        local last_session=$(jq -r '.session_id' "$CONTEXT_CACHE" 2>/dev/null || echo "unknown")
        local last_timestamp=$(jq -r '.timestamp' "$CONTEXT_CACHE" 2>/dev/null || echo "unknown")
        
        log_success "Previous session loaded: $last_session ($last_timestamp)"
        
        # Display context summary
        if [[ -f "$CLAUDE_MD" ]]; then
            local project_name=$(head -1 "$CLAUDE_MD" | sed 's/^# //' | sed 's/ Project Context//')
            log_message "Project: $project_name"
        fi
        
        return 0
    else
        log_warning "No previous context found"
        return 1
    fi
}

# Watch for file changes and update memory
watch_project_changes() {
    log_message "Starting project change monitoring..."
    
    # Create file watcher script
    cat > "$MEMORY_DIR/file-watcher.sh" <<'EOF'
#!/bin/bash

# File Watcher - Monitors project changes and updates memory

MEMORY_DIR=".claude/memory"
CLAUDE_MD="Claude.md"
WATCH_DIRS=("src" "lib" "components" "pages" "api" "utils" "config" "scripts")

# Function to update memory on file change
update_memory_on_change() {
    local changed_file="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log change to memory
    echo "[$timestamp] File changed: $changed_file" >> "$MEMORY_DIR/file-changes.log"
    
    # Update Claude.md if it exists
    if [[ -f "$CLAUDE_MD" ]]; then
        local update_entry="
### File Change - $timestamp
- **Modified**: $changed_file
- **Action**: Auto-detected by memory watcher
- **Status**: Development active
"
        
        # Insert before the auto-update comment
        sed -i.bak '/<!-- This section will be automatically updated/i\
'"$update_entry"'
' "$CLAUDE_MD"
    fi
}

# Main monitoring loop
if [[ $# -gt 0 ]]; then
    update_memory_on_change "$1"
fi
EOF
    
    chmod +x "$MEMORY_DIR/file-watcher.sh"
    log_success "Project change monitoring setup complete"
}

# Generate memory report
generate_memory_report() {
    log_message "Generating memory report..."
    
    local report_file="$MEMORY_DIR/memory-report.md"
    
    cat > "$report_file" <<EOF
# Claude Code Memory Report
Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Session Summary
$(if [[ -f "$CONTEXT_CACHE" ]]; then
    echo "- **Current Session**: $(jq -r '.session_id' "$CONTEXT_CACHE" 2>/dev/null || echo 'unknown')"
    echo "- **Start Time**: $(jq -r '.timestamp' "$CONTEXT_CACHE" 2>/dev/null || echo 'unknown')"
    echo "- **Git Branch**: $(jq -r '.git_branch' "$CONTEXT_CACHE" 2>/dev/null || echo 'unknown')"
    echo "- **Modified Files**: $(jq -r '.files_modified' "$CONTEXT_CACHE" 2>/dev/null || echo '0')"
else
    echo "- **Status**: No active session context"
fi)

## Memory Files
- **Session Log**: $(wc -l < "$SESSION_LOG" 2>/dev/null || echo '0') lines
- **Context Cache**: $(if [[ -f "$CONTEXT_CACHE" ]]; then echo "Present"; else echo "Missing"; fi)
- **File Changes**: $(if [[ -f "$MEMORY_DIR/file-changes.log" ]]; then wc -l < "$MEMORY_DIR/file-changes.log"; else echo '0'; fi) entries

## Recent Activity
$(if [[ -f "$MEMORY_DIR/file-changes.log" ]]; then
    echo "### File Changes"
    tail -n 5 "$MEMORY_DIR/file-changes.log" 2>/dev/null || echo "No recent changes"
else
    echo "No file change history available"
fi)

## Session History
$(if [[ -f "$SESSION_LOG" ]]; then
    echo "### Recent Sessions"
    tail -n 10 "$SESSION_LOG" | grep -E "^###" | head -n 3 || echo "No session history"
else
    echo "No session history available"
fi)

---
Generated by Claude Code Memory Sync System
EOF
    
    log_success "Memory report generated: $report_file"
}

# Main execution
main() {
    local action=${1:-"sync"}
    
    log_message "Starting memory sync (action: $action)..."
    
    # Initialize memory structure
    init_memory_structure
    
    case "$action" in
        "sync")
            capture_session_context
            sync_memory_to_claude_md
            ;;
        "load")
            load_previous_context
            ;;
        "watch")
            watch_project_changes
            ;;
        "report")
            generate_memory_report
            ;;
        *)
            log_error "Unknown action: $action"
            log_message "Usage: $0 [sync|load|watch|report]"
            exit 1
            ;;
    esac
    
    log_success "Memory sync completed successfully"
}

# Execute main function
main "$@"