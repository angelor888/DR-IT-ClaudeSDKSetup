#!/bin/bash
#
# DR-IT-ClaudeSDKSetup Main Installation Script
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
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

# Logging
LOG_FILE="$HOME/.config/claude/logs/setup-$TIMESTAMP.log"
mkdir -p "$HOME/.config/claude/logs"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo -e "\n${BLUE}==== $1 ====${NC}" | tee -a "$LOG_FILE"
}

# Main setup function
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    DR-IT Claude SDK Setup Script       ║${NC}"
    echo -e "${BLUE}║    Version 1.0.0 - 2025-07-08         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    
    header "Checking Prerequisites"
    check_prerequisites
    
    header "Setting Up Configuration"
    setup_config
    
    header "Installing MCP Services"
    "$SCRIPT_DIR/setup-mcp.sh"
    
    header "Installing Claude SDK"
    "$SCRIPT_DIR/setup-sdk.sh"
    
    header "Configuring Auto-Updates"
    "$SCRIPT_DIR/setup-autoupdate.sh"
    
    header "Setting Up Shell Integration"
    setup_shell_integration
    
    header "Running Verification"
    "$SCRIPT_DIR/verify-installation.sh"
    
    echo -e "\n${GREEN}✅ Setup completed successfully!${NC}"
    echo -e "${GREEN}📝 Logs saved to: $LOG_FILE${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Set your API keys in ~/.env"
    echo "3. Test with: claude-py && python test-api.py"
    echo "4. View commands: claude-help"
}

check_prerequisites() {
    log "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "This script requires macOS"
    fi
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        error "Homebrew is required. Install from https://brew.sh"
    fi
    
    # Check Docker
    if ! docker info &> /dev/null; then
        error "Docker Desktop must be installed and running"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        error "Git is required. Run: brew install git"
    fi
    
    log "✓ All prerequisites met"
}

setup_config() {
    log "Setting up configuration files..."
    
    # Create directory structure
    mkdir -p ~/.config/claude/{scripts,logs,databases,backups}
    mkdir -p ~/easy-mcp/secrets
    
    # Copy configuration files
    if [ -f "$PROJECT_ROOT/configs/.env.example" ]; then
        cp "$PROJECT_ROOT/configs/.env.example" ~/easy-mcp/.env.example
        if [ ! -f ~/easy-mcp/.env ]; then
            cp ~/easy-mcp/.env.example ~/easy-mcp/.env
            warning "Created .env file - please add your API keys"
        fi
    fi
    
    # Set permissions
    chmod 600 ~/easy-mcp/.env 2>/dev/null || true
    
    log "✓ Configuration files created"
}

setup_shell_integration() {
    log "Setting up shell integration..."
    
    # Copy shell integration file
    cp "$PROJECT_ROOT/configs/shell-integration.sh" ~/.config/claude/
    
    # Add to shell profile
    SHELL_PROFILE=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_PROFILE" ]; then
        if ! grep -q "claude/shell-integration.sh" "$SHELL_PROFILE"; then
            echo "" >> "$SHELL_PROFILE"
            echo "# Claude & MCP Shell Integration" >> "$SHELL_PROFILE"
            echo "if [ -f ~/.config/claude/shell-integration.sh ]; then" >> "$SHELL_PROFILE"
            echo "    source ~/.config/claude/shell-integration.sh" >> "$SHELL_PROFILE"
            echo "fi" >> "$SHELL_PROFILE"
            log "✓ Added shell integration to $SHELL_PROFILE"
        else
            log "✓ Shell integration already configured"
        fi
    fi
}

# Run main function
main "$@"