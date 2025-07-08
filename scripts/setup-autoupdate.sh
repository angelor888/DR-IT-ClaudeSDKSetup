#!/bin/bash
#
# DR-IT-ClaudeSDKSetup Auto-Update Configuration
# Version: 1.0.0
# Date: 2025-07-08
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AUTOUPDATE_SCRIPT="$HOME/.config/claude/scripts/auto-update.sh"
PLIST_FILE="$HOME/Library/LaunchAgents/com.claude.autoupdate.plist"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Copy auto-update script
setup_autoupdate_script() {
    log "Setting up auto-update script..."
    
    # Create script directory
    mkdir -p "$(dirname "$AUTOUPDATE_SCRIPT")"
    
    # Copy the script
    cp "$PROJECT_ROOT/configs/auto-update.sh" "$AUTOUPDATE_SCRIPT"
    chmod +x "$AUTOUPDATE_SCRIPT"
    
    log "✓ Auto-update script installed"
}

# Setup LaunchAgent
setup_launchagent() {
    log "Configuring LaunchAgent for scheduled updates..."
    
    # Create LaunchAgents directory if needed
    mkdir -p "$(dirname "$PLIST_FILE")"
    
    # Create plist file
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.autoupdate</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$AUTOUPDATE_SCRIPT</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    
    <key>StandardOutPath</key>
    <string>$HOME/.config/claude/logs/auto-update.log</string>
    
    <key>StandardErrorPath</key>
    <string>$HOME/.config/claude/logs/auto-update-error.log</string>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
</dict>
</plist>
EOF
    
    # Load the LaunchAgent
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    launchctl load "$PLIST_FILE"
    
    log "✓ LaunchAgent configured (runs daily at 2 AM)"
}

# Setup Watchtower for Docker
setup_watchtower() {
    log "Configuring Docker Watchtower..."
    
    # Watchtower is configured in docker-compose.yml
    # Just verify it's running
    if docker ps | grep -q watchtower; then
        log "✓ Watchtower is already running"
    else
        cd "$HOME/easy-mcp"
        docker-compose up -d watchtower
        log "✓ Watchtower started"
    fi
}

# Create monitoring script
setup_monitoring() {
    log "Setting up monitoring scripts..."
    
    MONITOR_SCRIPT="$HOME/.config/claude/scripts/monitor-services.sh"
    
    cat > "$MONITOR_SCRIPT" << 'EOF'
#!/bin/bash
# Service health check script

echo "=== Claude & MCP Services Health Check ==="
echo "Date: $(date)"
echo

# Check Docker services
echo "Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep mcp

echo -e "\nClaude CLI:"
claude --version 2>/dev/null || echo "Not installed"

echo -e "\nPython SDK:"
if [ -d ~/.config/claude/sdk-examples/python/venv ]; then
    source ~/.config/claude/sdk-examples/python/venv/bin/activate
    python -c "import anthropic; print(f'✓ Version {anthropic.__version__}')"
    deactivate
else
    echo "Not installed"
fi

echo -e "\nTypeScript SDK:"
if [ -f ~/.config/claude/sdk-examples/typescript/package.json ]; then
    cd ~/.config/claude/sdk-examples/typescript
    npm list @anthropic-ai/sdk 2>/dev/null | grep @anthropic-ai/sdk || echo "Not installed"
fi

echo -e "\nLast update run:"
tail -n 20 ~/.config/claude/logs/auto-update-*.log 2>/dev/null | grep -E "Starting|Completed" | tail -n 2

echo -e "\n=== End Health Check ==="
EOF
    
    chmod +x "$MONITOR_SCRIPT"
    
    log "✓ Monitoring scripts created"
}

# Main function
main() {
    log "Configuring auto-update system..."
    
    # Setup components
    setup_autoupdate_script
    setup_launchagent
    setup_watchtower
    setup_monitoring
    
    log "✓ Auto-update system configured"
    log "Updates will run daily at 2 AM"
    log "Run manually with: claude-update"
    log "Check status with: ~/.config/claude/scripts/monitor-services.sh"
}

# Run main function
main "$@"