#!/bin/bash
#
# Development Toolchain Verification Script
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

echo -e "${BLUE}=== Development Toolchain Verification ===${NC}"
echo -e "${BLUE}Date: $(date)${NC}"
echo

# Track overall status
ALL_GOOD=true

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        ALL_GOOD=false
    fi
}

# Function to check version
check_version() {
    local cmd=$1
    local name=$2
    local version_cmd=${3:-"--version"}
    
    if command -v "$cmd" &>/dev/null 2>&1 || [[ -x "$cmd" ]]; then
        version=$("$cmd" $version_cmd 2>/dev/null | head -1 || echo "unknown version")
        echo -e "${GREEN}✅ $name: $version${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: not installed${NC}"
        ALL_GOOD=false
        return 1
    fi
}

# 1. Check Node.js
echo -e "${YELLOW}Checking Node.js...${NC}"
node_version=$(node -v 2>/dev/null || echo "not installed")
if [[ "$node_version" =~ v2[0-9]\.[0-9]+\.[0-9]+ ]] || [[ "$node_version" =~ v2[2-9]\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${GREEN}✅ Node.js: $node_version${NC}"
else
    echo -e "${RED}❌ Node.js: $node_version (needs v20.17+ or v22.9+)${NC}"
    ALL_GOOD=false
fi
echo

# 2. Check npm global bin in PATH
echo -e "${YELLOW}Checking npm configuration...${NC}"
npm_prefix=$(npm config get prefix 2>/dev/null || echo "")
if echo $PATH | grep -q "npm-global/bin" || echo $PATH | grep -q "$npm_prefix/bin"; then
    echo -e "${GREEN}✅ npm global bin in PATH${NC}"
    echo "   Global prefix: $npm_prefix"
else
    echo -e "${RED}❌ npm global bin not in PATH${NC}"
    echo "   Add to PATH: $npm_prefix/bin"
    ALL_GOOD=false
fi
echo

# 3. Check primary tools
echo -e "${YELLOW}Checking primary tools...${NC}"
check_version "claude" "Claude CLI"
check_version "uv" "Python uv"
check_version "$HOME/.bun/bin/bun" "Bun runtime"
check_version "n8n" "n8n CLI"
echo

# 4. Check MCP servers
echo -e "${YELLOW}Checking MCP servers...${NC}"
if command -v claude &>/dev/null; then
    mcp_list=$(claude mcp list 2>/dev/null || echo "Error listing MCP servers")
    if [[ "$mcp_list" == *"No MCP servers configured"* ]] || [[ "$mcp_list" == *"Error"* ]]; then
        echo -e "${RED}❌ No MCP servers configured${NC}"
        ALL_GOOD=false
    else
        echo -e "${GREEN}✅ MCP servers configured:${NC}"
        echo "$mcp_list" | sed 's/^/   /'
    fi
else
    echo -e "${RED}❌ Claude CLI not available to check MCP servers${NC}"
    ALL_GOOD=false
fi
echo

# 5. Check optional developer tools
echo -e "${YELLOW}Checking optional developer tools...${NC}"
optional_tools=(
    "gh:GitHub CLI"
    "docker:Docker"
    "git:Git"
    "python3:Python 3"
    "pip3:pip"
)

for tool_spec in "${optional_tools[@]}"; do
    IFS=: read -r cmd name <<< "$tool_spec"
    if command -v "$cmd" &>/dev/null; then
        version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}✓ $name: $version${NC}"
    else
        echo -e "${YELLOW}○ $name: not installed (optional)${NC}"
    fi
done
echo

# 6. System information
echo -e "${YELLOW}System information:${NC}"
echo "OS: $(uname -s) $(uname -r)"
echo "Shell: $SHELL"
echo "Terminal: $TERM"
echo

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✅ All required tools are properly installed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tools need attention. Please review the output above.${NC}"
    echo
    echo "Quick fixes:"
    echo "1. Update Node.js: nvm install 22 && nvm use 22"
    echo "2. Install Claude CLI: npm install -g @anthropic-ai/claude-code"
    echo "3. Add Playwright MCP: claude mcp add playwright \"npx @playwright/mcp@latest\""
    echo "4. Install Bun: curl -fsSL https://bun.sh/install | bash"
    echo "5. Install n8n: npm install -g n8n"
    exit 1
fi