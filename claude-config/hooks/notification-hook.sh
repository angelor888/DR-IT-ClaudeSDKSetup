#!/bin/bash
#
# Notification Hook - Handles Claude Code notifications
# Triggered when Claude needs user input or provides notifications
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
NOTIFICATION_LOG="$LOG_DIR/notifications.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Get notification information
NOTIFICATION_TYPE="${CLAUDE_NOTIFICATION_TYPE:-${1:-info}}"
NOTIFICATION_MESSAGE="${CLAUDE_NOTIFICATION_MESSAGE:-${2:-No message provided}}"
NOTIFICATION_CONTEXT="${CLAUDE_NOTIFICATION_CONTEXT:-${3:-}}"

# Function to send system notification (macOS)
send_system_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"
    
    if command -v osascript &>/dev/null; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
    fi
}

# Function to send to webhook (optional)
send_webhook_notification() {
    local webhook_url="${CLAUDE_WEBHOOK_URL:-}"
    if [ -n "$webhook_url" ]; then
        curl -s -X POST "$webhook_url" \
            -H "Content-Type: application/json" \
            -d @- <<EOF
{
    "timestamp": "$TIMESTAMP",
    "type": "$NOTIFICATION_TYPE",
    "message": "$NOTIFICATION_MESSAGE",
    "context": "$NOTIFICATION_CONTEXT"
}
EOF
    fi
}

# Log the notification
{
    echo "[$TIMESTAMP] NOTIFICATION"
    echo "  Type: $NOTIFICATION_TYPE"
    echo "  Message: $NOTIFICATION_MESSAGE"
    if [ -n "$NOTIFICATION_CONTEXT" ]; then
        echo "  Context: $NOTIFICATION_CONTEXT"
    fi
    echo ""
} >> "$NOTIFICATION_LOG"

# Handle different notification types
case "$NOTIFICATION_TYPE" in
    "permission_required")
        send_system_notification "Claude Code - Permission Required" "$NOTIFICATION_MESSAGE" "Glass"
        ;;
    "task_completed")
        send_system_notification "Claude Code - Task Complete" "$NOTIFICATION_MESSAGE" "Hero"
        ;;
    "error")
        send_system_notification "Claude Code - Error" "$NOTIFICATION_MESSAGE" "Basso"
        ;;
    "warning")
        send_system_notification "Claude Code - Warning" "$NOTIFICATION_MESSAGE" "Purr"
        ;;
    "info"|*)
        # For info or unknown types, just log without system notification
        ;;
esac

# Send to webhook if configured
send_webhook_notification

# Voice announcement (enhanced, macOS only)
VOICE_ENABLED=$(jq -r '.notifications.voiceEnabled // false' ~/.config/claude/settings.json 2>/dev/null || echo "false")
if [ "$VOICE_ENABLED" = "true" ] && command -v say &>/dev/null; then
    case "$NOTIFICATION_TYPE" in
        "task_completed")
            VOICE_FOR_TASKS=$(jq -r '.notifications.voiceForTaskCompletion // false' ~/.config/claude/settings.json 2>/dev/null || echo "false")
            if [ "$VOICE_FOR_TASKS" = "true" ]; then
                say -v "Samantha" "Task completed: $NOTIFICATION_MESSAGE" &
            fi
            ;;
        "error")
            VOICE_FOR_ERRORS=$(jq -r '.notifications.voiceForErrors // false' ~/.config/claude/settings.json 2>/dev/null || echo "false")
            if [ "$VOICE_FOR_ERRORS" = "true" ]; then
                say -v "Alex" "Error occurred: $NOTIFICATION_MESSAGE" &
            fi
            ;;
        "permission_required")
            VOICE_FOR_MANUAL=$(jq -r '.notifications.voiceForManualIntervention // false' ~/.config/claude/settings.json 2>/dev/null || echo "false")
            if [ "$VOICE_FOR_MANUAL" = "true" ]; then
                say -v "Victoria" "Manual intervention required: $NOTIFICATION_MESSAGE" &
            fi
            ;;
        "warning")
            say -v "Fred" "Warning: $NOTIFICATION_MESSAGE" &
            ;;
        "agent_complete")
            say -v "Samantha" "Agent task completed" &
            ;;
        "all_agents_complete")
            say -v "Daniel" "All parallel agents have completed their tasks" &
            ;;
    esac
fi

# Log to hooks log
echo "[$TIMESTAMP] Notification hook executed: $NOTIFICATION_TYPE" >> "$LOG_DIR/hooks.log"