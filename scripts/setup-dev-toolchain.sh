#!/bin/bash
#
# Automated Development Toolchain Setup
# Version: 1.0.0
# Date: 2025-01-08
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Development Toolchain Setup Script    ║${NC}"
echo -e "${BLUE}║  Version 1.0.0 - 2025-01-08           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Function to check command
check_cmd() {
    command -v "$1" &>/dev/null
}

# Function to log
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

# Function to error
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Function to warn
warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
log "Checking prerequisites..."
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script requires macOS"
fi

if [ "$SHELL" != "/bin/zsh" ]; then
    warn "This script is optimized for zsh. Current shell: $SHELL"
fi

# 1. Node.js Setup
log "Checking Node.js..."
NODE_OK=false
if check_cmd node; then
    NODE_VERSION=$(node -v)
    if [[ "$NODE_VERSION" =~ v2[0-9]\.[0-9]+\.[0-9]+ ]] || [[ "$NODE_VERSION" =~ v2[2-9]\.[0-9]+\.[0-9]+ ]]; then
        log "Node.js $NODE_VERSION is installed ✓"
        NODE_OK=true
    else
        warn "Node.js $NODE_VERSION is outdated"
    fi
else
    warn "Node.js not found"
fi

if [ "$NODE_OK" = false ]; then
    log "Installing Node.js via nvm..."
    if ! check_cmd nvm; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    nvm install 22
    nvm use 22
    nvm alias default 22
    log "Node.js installed ✓"
fi

# 2. Configure npm
log "Configuring npm..."
NPM_PREFIX="$HOME/.npm-global"
npm config set prefix "$NPM_PREFIX"
if ! echo $PATH | grep -q "$NPM_PREFIX/bin"; then
    echo "export PATH=\"\$PATH:$NPM_PREFIX/bin\"" >> ~/.zshrc
    export PATH="$PATH:$NPM_PREFIX/bin"
    log "Added npm global bin to PATH ✓"
else
    log "npm global bin already in PATH ✓"
fi

# 3. Install Claude CLI
log "Installing Claude Code CLI..."
if ! check_cmd claude; then
    npm install -g @anthropic-ai/claude-code
    log "Claude CLI installed ✓"
else
    log "Claude CLI already installed ✓"
fi

# 4. Add Playwright MCP server
log "Configuring Playwright MCP server..."
if ! claude mcp list 2>/dev/null | grep -q playwright; then
    claude mcp add playwright "npx @playwright/mcp@latest"
    log "Playwright MCP server added ✓"
else
    log "Playwright MCP server already configured ✓"
fi

# 5. Install Python uv
log "Installing Python uv..."
if ! check_cmd uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    log "Python uv installed ✓"
else
    log "Python uv already installed ✓"
fi

# 6. Install Bun
log "Installing Bun runtime..."
if ! [ -x "$HOME/.bun/bin/bun" ]; then
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    log "Bun installed ✓"
else
    log "Bun already installed ✓"
fi

# 7. Install n8n
log "Installing n8n CLI..."
if ! check_cmd n8n; then
    npm install -g n8n
    log "n8n installed ✓"
else
    log "n8n already installed ✓"
fi

# 8. Final verification
echo
log "Running verification..."
if [ -f "$(dirname "$0")/verify-toolchain.sh" ]; then
    bash "$(dirname "$0")/verify-toolchain.sh"
else
    warn "Verification script not found"
fi

# Summary
echo
echo -e "${GREEN}✅ Development toolchain setup complete!${NC}"
echo
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Run '/install GitHub app' in Claude Code if needed"
echo "3. Test the installation: verify-toolchain.sh"
echo
echo "For additional CLI tools integration, see the SOP documentation."