#!/bin/bash
#
# Enhanced Post-Tool-Use Hook - Comprehensive logging with structured metadata
# Triggered after executing any tool or command
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
TOOL_LOG="$LOG_DIR/tool-invocations.log"
METADATA_LOG="$LOG_DIR/tool-metadata.jsonl"
PERFORMANCE_LOG="$LOG_DIR/performance-metrics.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
START_TIME="${CLAUDE_START_TIME:-$(date +%s%3N)}"
END_TIME=$(date +%s%3N)
DURATION=$((END_TIME - START_TIME))

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Get execution information
TOOL_NAME="${CLAUDE_TOOL_NAME:-${1:-unknown}}"
EXIT_CODE="${CLAUDE_EXIT_CODE:-${2:-0}}"
OUTPUT="${CLAUDE_OUTPUT:-}"
SESSION_ID="${CLAUDE_SESSION_ID:-$(uuidgen 2>/dev/null || echo "session-$(date +%s)")}"
USER_INPUT="${CLAUDE_USER_INPUT:-}"
WORKING_DIR=$(pwd)

# Read output from stdin if available
if [ -z "$OUTPUT" ] && [ ! -t 0 ]; then
    OUTPUT=$(cat)
fi

# Function to calculate output metrics
calculate_metrics() {
    local output="$1"
    local line_count=0
    local char_count=0
    local word_count=0
    
    if [ -n "$output" ]; then
        line_count=$(echo "$output" | wc -l | tr -d ' ')
        char_count=$(echo "$output" | wc -c | tr -d ' ')
        word_count=$(echo "$output" | wc -w | tr -d ' ')
    fi
    
    echo "{\"lines\": $line_count, \"characters\": $char_count, \"words\": $word_count}"
}

# Function to sanitize sensitive data
sanitize_content() {
    local content="$1"
    # Remove API keys, tokens, and secrets
    content=$(echo "$content" | sed -E 's/(sk-[a-zA-Z0-9-]+|ghp_[a-zA-Z0-9]+|xoxb-[a-zA-Z0-9-]+)/[REDACTED]/g')
    content=$(echo "$content" | sed -E 's/([A-Z_]+_KEY|TOKEN|SECRET|PASSWORD)=["'\''"]?[^"'\'' ]+["'\''"]?/\1=[REDACTED]/g')
    echo "$content"
}

# Function to extract tool arguments safely
extract_tool_args() {
    local tool_name="$1"
    local args=""
    
    case "$tool_name" in
        "Bash")
            args=$(echo "$CLAUDE_TOOL_ARGS" | jq -r '.command // empty' 2>/dev/null || echo "")
            ;;
        "Read"|"Edit"|"Write")
            args=$(echo "$CLAUDE_TOOL_ARGS" | jq -r '.file_path // .path // empty' 2>/dev/null || echo "")
            ;;
        "Glob"|"Grep")
            args=$(echo "$CLAUDE_TOOL_ARGS" | jq -r '.pattern // empty' 2>/dev/null || echo "")
            ;;
        *)
            args="$CLAUDE_TOOL_ARGS"
            ;;
    esac
    
    echo "$args"
}

# Calculate metrics
OUTPUT_METRICS=$(calculate_metrics "$OUTPUT")
SAFE_OUTPUT=$(sanitize_content "$OUTPUT")
TOOL_ARGS=$(extract_tool_args "$TOOL_NAME")
SAFE_ARGS=$(sanitize_content "$TOOL_ARGS")

# Determine success/failure
if [ "$EXIT_CODE" -eq 0 ]; then
    STATUS="success"
    SEVERITY="info"
else
    STATUS="failure"
    SEVERITY="error"
fi

# Create structured metadata JSON
METADATA_JSON=$(cat <<EOF
{
    "timestamp": "$TIMESTAMP_ISO",
    "session_id": "$SESSION_ID",
    "tool": {
        "name": "$TOOL_NAME",
        "arguments": $(echo "$SAFE_ARGS" | jq -R . 2>/dev/null || echo "\"$SAFE_ARGS\""),
        "working_directory": "$WORKING_DIR"
    },
    "execution": {
        "status": "$STATUS",
        "exit_code": $EXIT_CODE,
        "duration_ms": $DURATION,
        "start_time": $START_TIME,
        "end_time": $END_TIME
    },
    "output": {
        "metrics": $OUTPUT_METRICS,
        "preview": $(echo "$SAFE_OUTPUT" | head -5 | jq -Rs . 2>/dev/null || echo "\"\"")
    },
    "environment": {
        "user": "$USER",
        "hostname": "$(hostname)",
        "pid": $$
    },
    "severity": "$SEVERITY"
}
EOF
)

# Log structured metadata to JSONL file
echo "$METADATA_JSON" >> "$METADATA_LOG"

# Log to human-readable tool log
{
    echo "[$TIMESTAMP] POST-RUN: $TOOL_NAME"
    echo "  Session ID: $SESSION_ID"
    echo "  Exit Code: $EXIT_CODE"
    echo "  Duration: ${DURATION}ms"
    echo "  Working Dir: $WORKING_DIR"
    echo "  Output Lines: $(echo "$OUTPUT_METRICS" | jq -r '.lines')"
    echo "  Arguments: $(echo "$SAFE_ARGS" | head -c 100)..."
} >> "$TOOL_LOG"

# Log performance metrics
{
    echo "[$TIMESTAMP] PERFORMANCE: $TOOL_NAME"
    echo "  Duration: ${DURATION}ms"
    echo "  Exit Code: $EXIT_CODE"
    echo "  Output Size: $(echo "$OUTPUT_METRICS" | jq -r '.characters') chars"
    echo "  Session: $SESSION_ID"
} >> "$PERFORMANCE_LOG"

# Generate TypeScript interfaces periodically (every 10th execution)
EXECUTION_COUNT=$(wc -l < "$METADATA_LOG" 2>/dev/null || echo "0")
if [ $((EXECUTION_COUNT % 10)) -eq 0 ] && [ "$EXECUTION_COUNT" -gt 0 ]; then
    # Trigger interface generation asynchronously
    (
        sleep 1
        ~/.config/claude/hooks/generate-log-interfaces.ts "$METADATA_LOG" 2>/dev/null || true
    ) &
fi

# Send notification for long-running tasks (>30 seconds)
if [ "$DURATION" -gt 30000 ]; then
    # Trigger notification hook
    echo "task_completed" | CLAUDE_NOTIFICATION_TYPE="task_completed" \
        CLAUDE_NOTIFICATION_MESSAGE="$TOOL_NAME completed after ${DURATION}ms" \
        CLAUDE_NOTIFICATION_CONTEXT="Long-running task finished" \
        ~/.config/claude/hooks/notification-hook.sh &
fi

# Log to hooks log
echo "[$TIMESTAMP] Enhanced post-tool-use hook executed for: $TOOL_NAME (${DURATION}ms, exit: $EXIT_CODE)" >> "$LOG_DIR/hooks.log"

# Return success
exit 0