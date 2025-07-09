#!/bin/bash
#
# Pre-Run Hook - Logs tool/command invocations
# Triggered before executing any tool or command
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
TOOL_LOG="$LOG_DIR/tool-invocations.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Get tool information from environment or arguments
TOOL_NAME="${CLAUDE_TOOL_NAME:-${1:-unknown}}"
TOOL_ARGS="${CLAUDE_TOOL_ARGS:-${*:2}}"

# Sanitize arguments to remove sensitive data
sanitize_args() {
    local args="$1"
    # Remove potential secrets
    args=$(echo "$args" | sed -E 's/(--password|--token|--key)[ =][^ ]+/\1=[REDACTED]/g')
    args=$(echo "$args" | sed -E 's/(sk-[a-zA-Z0-9-]+|ghp_[a-zA-Z0-9]+|xoxb-[a-zA-Z0-9-]+)/[REDACTED]/g')
    echo "$args"
}

SAFE_ARGS=$(sanitize_args "$TOOL_ARGS")

# Log the tool invocation
{
    echo "[$TIMESTAMP] PRE-RUN: $TOOL_NAME"
    echo "  Working Directory: $(pwd)"
    echo "  Arguments: $SAFE_ARGS"
    echo "  User: $USER"
    echo "  PID: $$"
} >> "$TOOL_LOG"

# Also log to hooks log
echo "[$TIMESTAMP] Pre-run hook executed for: $TOOL_NAME" >> "$LOG_DIR/hooks.log"