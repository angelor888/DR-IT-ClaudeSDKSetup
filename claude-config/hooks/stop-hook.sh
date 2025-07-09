#!/bin/bash
#
# Stop Hook - Logs completed conversations
# Triggered after each Claude completion
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
CHAT_LOG_DIR="$LOG_DIR/conversations"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CHAT_LOG="$CHAT_LOG_DIR/chat-$TIMESTAMP.md"

# Ensure directories exist
mkdir -p "$CHAT_LOG_DIR"

# Function to sanitize sensitive data
sanitize_content() {
    local content="$1"
    # Remove API keys, tokens, and secrets
    content=$(echo "$content" | sed -E 's/(sk-[a-zA-Z0-9-]+|ghp_[a-zA-Z0-9]+|xoxb-[a-zA-Z0-9-]+)/[REDACTED]/g')
    # Remove environment variable values that look like secrets
    content=$(echo "$content" | sed -E 's/([A-Z_]+_KEY|TOKEN|SECRET|PASSWORD)=["'\''"]?[^"'\'' ]+["'\''"]?/\1=[REDACTED]/g')
    echo "$content"
}

# Read conversation from stdin or environment
if [ -n "${CLAUDE_CONVERSATION:-}" ]; then
    CONVERSATION="$CLAUDE_CONVERSATION"
elif [ ! -t 0 ]; then
    CONVERSATION=$(cat)
else
    CONVERSATION="No conversation data available"
fi

# Sanitize and log the conversation
{
    echo "# Claude Conversation Log"
    echo "**Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Working Directory**: $(pwd)"
    echo "**User**: $USER"
    echo "**Model**: ${CLAUDE_MODEL:-unknown}"
    echo ""
    echo "---"
    echo ""
    sanitize_content "$CONVERSATION"
    echo ""
    echo "---"
    echo "**End of conversation**"
} > "$CHAT_LOG"

# Log success
echo "[$(date +'%H:%M:%S')] Conversation logged to: $CHAT_LOG" >> "$LOG_DIR/hooks.log"

# Project-specific audio notification
if [ -x ~/.config/claude/scripts/claude-audio-notifications.sh ]; then
    ~/.config/claude/scripts/claude-audio-notifications.sh context "complete" "Claude task completed" true &
fi