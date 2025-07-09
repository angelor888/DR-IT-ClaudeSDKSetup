#!/bin/bash
#
# Post-Run Hook - Records exit codes and trims output
# Triggered after executing any tool or command
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
TOOL_LOG="$LOG_DIR/tool-invocations.log"
OUTPUT_LOG="$LOG_DIR/tool-outputs.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MAX_LINES=500
TRIM_LINES=50

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Get execution information
TOOL_NAME="${CLAUDE_TOOL_NAME:-${1:-unknown}}"
EXIT_CODE="${CLAUDE_EXIT_CODE:-${2:-0}}"
OUTPUT="${CLAUDE_OUTPUT:-}"

# Function to trim output if too long
trim_output() {
    local output="$1"
    local line_count=$(echo "$output" | wc -l)
    
    if [ "$line_count" -gt "$MAX_LINES" ]; then
        local head_output=$(echo "$output" | head -n "$TRIM_LINES")
        local tail_output=$(echo "$output" | tail -n "$TRIM_LINES")
        
        echo "$head_output"
        echo ""
        echo "... [$(($line_count - 2 * $TRIM_LINES)) lines trimmed] ..."
        echo ""
        echo "$tail_output"
    else
        echo "$output"
    fi
}

# Sanitize output
sanitize_output() {
    local output="$1"
    # Remove sensitive data
    output=$(echo "$output" | sed -E 's/(sk-[a-zA-Z0-9-]+|ghp_[a-zA-Z0-9]+|xoxb-[a-zA-Z0-9-]+)/[REDACTED]/g')
    output=$(echo "$output" | sed -E 's/([A-Z_]+_KEY|TOKEN|SECRET|PASSWORD)=["'\''"]?[^"'\'' ]+["'\''"]?/\1=[REDACTED]/g')
    echo "$output"
}

# Read output from stdin if available
if [ -z "$OUTPUT" ] && [ ! -t 0 ]; then
    OUTPUT=$(cat)
fi

# Process and log output
SAFE_OUTPUT=$(sanitize_output "$OUTPUT")
TRIMMED_OUTPUT=$(trim_output "$SAFE_OUTPUT")

# Log execution result
{
    echo "[$TIMESTAMP] POST-RUN: $TOOL_NAME"
    echo "  Exit Code: $EXIT_CODE"
    echo "  Output Lines: $(echo "$OUTPUT" | wc -l)"
} >> "$TOOL_LOG"

# Log trimmed output separately
if [ -n "$TRIMMED_OUTPUT" ]; then
    {
        echo "[$TIMESTAMP] OUTPUT for $TOOL_NAME (exit: $EXIT_CODE)"
        echo "----------------------------------------"
        echo "$TRIMMED_OUTPUT"
        echo "----------------------------------------"
        echo ""
    } >> "$OUTPUT_LOG"
fi

# Log to hooks log
echo "[$TIMESTAMP] Post-run hook executed for: $TOOL_NAME (exit: $EXIT_CODE)" >> "$LOG_DIR/hooks.log"