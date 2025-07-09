#!/bin/bash
#
# DR-IT-ClaudeSDKSetup MCP Services Installation
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
MCP_DIR="$HOME/easy-mcp"

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

# Main MCP setup
main() {
    log "Setting up MCP services..."
    
    # Clone easy-mcp if not exists
    if [ ! -d "$MCP_DIR" ]; then
        log "Cloning easy-mcp repository..."
        git clone https://github.com/modelcontextprotocol/easy-mcp.git "$MCP_DIR"
    else
        log "easy-mcp already exists, pulling latest..."
        cd "$MCP_DIR" && git pull
    fi
    
    # Copy docker-compose configuration
    log "Copying Docker Compose configuration..."
    cp "$PROJECT_ROOT/configs/docker-compose.yml" "$MCP_DIR/"
    
    # Copy environment template
    if [ ! -f "$MCP_DIR/.env" ]; then
        cp "$PROJECT_ROOT/configs/.env.example" "$MCP_DIR/.env"
        warning "Created .env file - please add your API keys"
    fi
    
    # Set permissions
    chmod 600 "$MCP_DIR/.env"
    
    # Start Docker services
    log "Starting MCP services..."
    cd "$MCP_DIR"
    docker-compose pull
    docker-compose up -d
    
    # Wait for services to start
    log "Waiting for services to initialize..."
    sleep 10
    
    # Show status
    docker-compose ps
    
    # Configure Claude Desktop
    configure_claude_desktop
    
    log "✓ MCP services setup complete"
}

configure_claude_desktop() {
    log "Configuring Claude Desktop..."
    
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    
    # Create directory if needed
    mkdir -p "$CONFIG_DIR"
    
    # Backup existing config
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Copy new config
    cp "$PROJECT_ROOT/configs/claude-desktop-config.json" "$CONFIG_FILE"
    
    log "✓ Claude Desktop configured"
}

# Run main function
main "$@"