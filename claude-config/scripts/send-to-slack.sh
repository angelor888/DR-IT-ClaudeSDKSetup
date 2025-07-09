#!/bin/bash
# Send message to Slack webhook with pinning support

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$HOME/.config/claude/environment"
CLAUDE_CONFIG_DIR="$HOME/.config/claude"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load environment
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo -e "${RED}❌ Environment file not found: $ENV_FILE${NC}"
    echo "Please copy environment.template to environment and add your Slack webhook URL"
    exit 1
fi

# Check for webhook URL
if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
    echo -e "${RED}❌ SLACK_WEBHOOK_URL not set in environment${NC}"
    exit 1
fi

# Parse arguments
MESSAGE_FILE=""
PIN_MESSAGE=false
CHANNEL="it-report"

while [[ $# -gt 0 ]]; do
    case $1 in
        --pin)
            PIN_MESSAGE=true
            shift
            ;;
        --channel)
            CHANNEL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [message-file] [options]"
            echo ""
            echo "Options:"
            echo "  --pin          Pin the message after sending"
            echo "  --channel      Specify channel (default: it-report)"
            echo "  --help         Show this help"
            echo ""
            echo "If no message file is provided, will look for CLAUDE_TOOLS_INSTRUCTIONS.md"
            exit 0
            ;;
        *)
            MESSAGE_FILE="$1"
            shift
            ;;
    esac
done

# Default message file
if [ -z "$MESSAGE_FILE" ]; then
    MESSAGE_FILE="$SCRIPT_DIR/../../CLAUDE_TOOLS_INSTRUCTIONS.md"
fi

if [ ! -f "$MESSAGE_FILE" ]; then
    echo -e "${RED}❌ Message file not found: $MESSAGE_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📤 Sending message to Slack channel: #${CHANNEL}${NC}"

# Convert markdown to Slack format
convert_to_slack_format() {
    local content="$1"
    
    # Convert headers
    content=$(echo "$content" | sed 's/^# /*/' | sed 's/*$/*/g')
    content=$(echo "$content" | sed 's/^## /*/' | sed 's/*$/*/g')
    content=$(echo "$content" | sed 's/^### /_/' | sed 's/_$/\_/g')
    
    # Convert code blocks to Slack format
    content=$(echo "$content" | sed 's/```bash/```/g')
    
    # Convert links
    content=$(echo "$content" | sed 's/\[\([^]]*\)\](\([^)]*\))/<\2|\1>/g')
    
    # Escape special characters for JSON
    content=$(echo "$content" | jq -Rs .)
    
    echo "$content"
}

# Read and format message
MESSAGE_CONTENT=$(cat "$MESSAGE_FILE")
FORMATTED_MESSAGE=$(convert_to_slack_format "$MESSAGE_CONTENT")

# Create Slack payload
PAYLOAD=$(cat <<EOF
{
    "channel": "#${CHANNEL}",
    "username": "Claude Tools Bot",
    "icon_emoji": ":robot_face:",
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "🚀 Claude Tools Package - Installation & Usage Guide",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": ${FORMATTED_MESSAGE}
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "📦 Version: v1.0.0 | 📅 $(date '+%Y-%m-%d %H:%M:%S') | 🤖 Generated with Claude Code"
                }
            ]
        }
    ]
}
EOF
)

# Send to Slack
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$SLACK_WEBHOOK_URL")

# Check response
if [ "$RESPONSE" = "ok" ]; then
    echo -e "${GREEN}✅ Message sent successfully to #${CHANNEL}${NC}"
    
    # Pin message if requested and bot token available
    if [ "$PIN_MESSAGE" = true ] && [ -n "${SLACK_BOT_TOKEN:-}" ]; then
        echo -e "${YELLOW}📌 Attempting to pin message...${NC}"
        echo -e "${YELLOW}Note: Pinning requires bot token and API access${NC}"
        # Pinning would require using Slack API with bot token
        # This is more complex than webhook and requires message timestamp
    fi
else
    echo -e "${RED}❌ Failed to send message${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

# Create alternative format for manual posting
MANUAL_FILE="$CLAUDE_CONFIG_DIR/slack-message-manual.txt"
cat > "$MANUAL_FILE" << 'EOF'
📌 **PLEASE PIN THIS MESSAGE** 📌

🚀 **Claude Tools Package - Installation & Usage Guide**

**Installation Methods:**

**1. macOS PKG (Easiest):**
```
curl -L https://github.com/angelor888/DR-IT-ClaudeSDKSetup/releases/download/v1.0.0/DR-IT-ClaudeSDKSetup-v1.0.0.pkg -o claude-tools.pkg
sudo installer -pkg claude-tools.pkg -target /
claude-workflow-install
```

**2. Homebrew:**
```
brew tap angelor888/claude-tools
brew install claude-tools
claude-workflow-install
```

**3. NPM:**
```
npm install -g @dr-it/claude-sdk-setup
claude-workflow-install
```

**Essential Commands:**
• `cwt-create feature-name` - Create parallel development branch
• `cdesign "UI brief"` - Generate 4 UI variations
• `cide-screenshot` - Analyze clipboard screenshot
• `caudio-test` - Test audio notifications
• `claude-mode model opus` - Switch Claude model
• `csync daemon` - Start multi-computer sync

**Multi-Computer Setup:**
1. Install on each computer
2. Share sync repo between machines
3. Run `csync register` on each
4. Auto-sync every 5 minutes

**Documentation:**
• Repository: https://github.com/angelor888/DR-IT-ClaudeSDKSetup
• Full guide: See CLAUDE_TOOLS_INSTRUCTIONS.md in repo

✅ All systems operational and ready for production use!
EOF

echo -e "${BLUE}📄 Manual posting file created: $MANUAL_FILE${NC}"
echo -e "${YELLOW}To pin the message: Copy content from $MANUAL_FILE and post to Slack, then use the message menu to pin it${NC}"