#!/bin/bash
#
# DR-IT-ClaudeSDKSetup Quick Installer
# Downloads and runs the setup from GitHub
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    DR-IT Claude SDK Quick Installer    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check prerequisites
echo "Checking prerequisites..."

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This installer requires macOS${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is required. Install Xcode Command Line Tools${NC}"
    exit 1
fi

if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is required. Install from https://brew.sh${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker Desktop must be installed and running${NC}"
    exit 1
fi

# Clone repository
INSTALL_DIR="$HOME/Projects/DR-IT-ClaudeSDKSetup"
echo -e "${GREEN}Cloning repository to $INSTALL_DIR...${NC}"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory exists. Pulling latest changes...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/angelor888/DR-IT-ClaudeSDKSetup.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Make scripts executable
chmod +x scripts/*.sh

# Run setup
echo -e "${GREEN}Starting setup...${NC}"
./scripts/setup-all.sh

echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set your API keys in ~/.env"
echo "2. Restart your terminal or run: source ~/.zshrc"
echo "3. Test with: claude-py && python test-api.py"
echo "4. View available commands: claude-help"