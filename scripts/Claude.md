# Scripts Directory Context

## Purpose
Automation scripts for setting up and maintaining the Claude SDK development environment. All scripts follow bash best practices with error handling and logging.

## Public Interfaces

### setup-all.sh
- **Purpose**: Master setup script that orchestrates all installations
- **Dependencies**: macOS, Homebrew, Docker Desktop, Git
- **Usage**: `./setup-all.sh`
- **Actions**: Runs all other setup scripts in proper order

### setup-mcp.sh
- **Purpose**: Installs and configures MCP Docker services
- **Key Steps**:
  - Clones easy-mcp repository
  - Copies docker-compose configuration
  - Starts all MCP services
  - Configures Claude Desktop

### setup-sdk.sh
- **Purpose**: Installs Claude SDK for Python and TypeScript
- **Creates**:
  - Python venv at ~/.config/claude/sdk-examples/python/
  - TypeScript project at ~/.config/claude/sdk-examples/typescript/
- **Dependencies**: Python 3, Node.js, npm

### setup-autoupdate.sh
- **Purpose**: Configures automatic daily updates
- **Creates**:
  - LaunchAgent plist
  - Auto-update script
  - Monitoring utilities
- **Schedule**: 2 AM daily

### setup-dev-toolchain.sh
- **Purpose**: Installs development tools (Node.js, Claude CLI, MCP servers, etc.)
- **Tools**: Node.js v22+, Claude CLI, Playwright MCP, uv, Bun, n8n
- **Usage**: `./setup-dev-toolchain.sh`

### verify-installation.sh
- **Purpose**: Comprehensive health check of all components
- **Checks**: System requirements, directories, environment variables, services
- **Output**: Pass/fail status for each component

### verify-toolchain.sh
- **Purpose**: Verifies development toolchain installation
- **Checks**: Node.js version, npm PATH, all dev tools
- **Usage**: Run after setup-dev-toolchain.sh

## Script Standards
- All scripts use `set -euo pipefail` for safety
- Color-coded output (RED=error, GREEN=success, YELLOW=warning)
- Comprehensive logging to ~/.config/claude/logs/
- Non-destructive (check before overwrite)
- No sudo unless absolutely necessary

## Learned Facts
<!-- Auto-updated by memory watch -->