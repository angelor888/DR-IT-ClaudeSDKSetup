# **DR-SOP-IT-DevToolchain-v1.0-20250108**

## Standard Operating Procedure

### **Title**
Development Toolchain Setup for Claude Code Environment

### **Purpose**
Establish a standardized process for auditing and installing the complete development toolchain required for Claude Code and related development tools on macOS systems, ensuring all developers have a consistent and functional environment.

### **Scope**
Applies to all DuetRight developers, IT staff, and contractors setting up or maintaining development environments for Claude Code on macOS with zsh shell.

### **Prerequisites**
- macOS with zsh shell
- Homebrew installed
- Internet connection
- Terminal access

### **Required Tools Overview**

| Tool | Purpose | Required Version | Installation Method |
|------|---------|------------------|---------------------|
| Node.js | JavaScript runtime | ≥20.17 LTS or ≥22.9 | nvm or Homebrew |
| npm | Package manager | Latest | Comes with Node.js |
| Claude CLI | Claude Code interface | Latest | npm global |
| Playwright MCP | Browser automation | Latest | Claude MCP |
| GitHub App | GitHub integration | Latest | Claude Code |
| uv | Python package manager | Latest | curl installer |
| Bun | JavaScript runtime | Latest | curl installer |
| n8n | Workflow automation | Latest | npm global |

### **Procedure**

#### **1. Audit Existing Installation**

1.1. Check Node.js version:
```bash
node -v
# Expected: v20.17+ or v22.9+
```

1.2. Verify npm global bin in PATH:
```bash
npm root -g
echo $PATH | grep -q "npm-global/bin" && echo "✓ In PATH" || echo "✗ Not in PATH"
```

1.3. Check Claude CLI:
```bash
which claude && claude --version
```

1.4. List MCP servers:
```bash
claude mcp list
```

1.5. Check Python tools:
```bash
command -v uv && uv --version
```

1.6. Check optional tools:
```bash
~/.bun/bin/bun --version 2>/dev/null || echo "Bun not installed"
n8n --version 2>/dev/null || echo "n8n not installed"
```

#### **2. Install Required Baseline**

2.1. **Node.js Setup** (if needed):
```bash
# If Node version is unsupported, install via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.zshrc
nvm install 22
nvm use 22
nvm alias default 22
```

2.2. **Configure npm global path** (if needed):
```bash
# Set custom npm prefix to avoid permission issues
npm config set prefix ~/.npm-global
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### **3. Install Primary Tools**

3.1. **Claude Code CLI**:
```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

3.2. **Playwright MCP Server**:
```bash
claude mcp add playwright "npx @playwright/mcp@latest"
```

3.3. **GitHub App Integration**:
- Open Claude Code in interactive mode
- Run command: `/install GitHub app`
- Follow authentication prompts

#### **4. Install Developer Tools**

4.1. **Python uv**:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.zshrc
uv --version
```

4.2. **Bun Runtime**:
```bash
curl -fsSL https://bun.sh/install | bash
# Verify installation
~/.bun/bin/bun --version
```

4.3. **n8n Workflow Automation**:
```bash
npm install -g n8n
n8n --version
```

#### **5. Verification Script**

Create verification script `verify-toolchain.sh`:
```bash
#!/bin/bash
echo "=== Development Toolchain Verification ==="
echo

# Check Node.js
node_version=$(node -v 2>/dev/null)
if [[ "$node_version" =~ v(2[2-9]|[3-9][0-9]) ]]; then
    echo "✅ Node.js: $node_version"
else
    echo "❌ Node.js: $node_version (needs upgrade)"
fi

# Check npm global bin
if echo $PATH | grep -q "npm-global/bin"; then
    echo "✅ npm global bin in PATH"
else
    echo "❌ npm global bin not in PATH"
fi

# Check tools
tools=(
    "claude:Claude CLI"
    "uv:Python uv"
    "~/.bun/bin/bun:Bun runtime"
    "n8n:n8n CLI"
)

for tool_spec in "${tools[@]}"; do
    IFS=: read -r cmd name <<< "$tool_spec"
    if command -v "$cmd" &>/dev/null || [[ -x "$cmd" ]]; then
        version=$("$cmd" --version 2>/dev/null | head -1)
        echo "✅ $name: $version"
    else
        echo "❌ $name: not installed"
    fi
done

# Check MCP servers
echo
echo "MCP Servers:"
claude mcp list 2>/dev/null || echo "❌ No MCP servers configured"
```

#### **6. Additional CLI Integration**

6.1. Document custom CLI tools:
```bash
# For each custom tool, capture help documentation
TOOL_NAME="your-tool"
$TOOL_NAME --help > ~/Projects/DR-IT-ClaudeSDKSetup/docs/cli-tools/${TOOL_NAME}-help.txt
```

6.2. Common developer tools to consider:
- `gh` - GitHub CLI
- `docker` & `docker-compose`
- `terraform`
- `kubectl`
- `aws` CLI
- `vercel`
- Custom project CLIs

### **Quality Checks**

- [ ] Node.js version ≥22.9
- [ ] npm global bin directory in PATH
- [ ] Claude CLI installed and accessible
- [ ] Playwright MCP server configured
- [ ] GitHub App linked (when needed)
- [ ] Python uv installed
- [ ] Bun runtime installed
- [ ] n8n CLI installed
- [ ] All tools verified with version output

### **Troubleshooting**

| Issue | Solution |
|-------|----------|
| Node version outdated | Use nvm to install and switch versions |
| npm permission errors | Use custom prefix: `npm config set prefix ~/.npm-global` |
| PATH not updated | Run `source ~/.zshrc` or restart terminal |
| MCP server errors | Check Claude CLI version: `npm update -g @anthropic-ai/claude-code` |
| Bun not in PATH | Add to .zshrc: `export PATH="$HOME/.bun/bin:$PATH"` |
| Tool version conflicts | Use version managers (nvm, pyenv, etc.) |

### **Best Practices**

1. **Version Management**:
   - Use nvm for Node.js versions
   - Pin tool versions in project documentation
   - Regular updates via automated scripts

2. **Security**:
   - Never install with sudo for user tools
   - Use `~/.npm-global` for npm globals
   - Regular security audits: `npm audit`

3. **Documentation**:
   - Keep CLI help outputs updated
   - Document project-specific tools
   - Maintain compatibility matrix

### **Automation Script**

Complete setup automation:
```bash
#!/bin/bash
# setup-dev-toolchain.sh

set -euo pipefail

echo "🔧 Setting up development toolchain..."

# Function to check command
check_cmd() {
    command -v "$1" &>/dev/null
}

# Install Node.js if needed
if ! check_cmd node || [[ ! "$(node -v)" =~ v2[2-9] ]]; then
    echo "Installing Node.js via nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    source ~/.zshrc
    nvm install 22
    nvm use 22
fi

# Configure npm
npm config set prefix ~/.npm-global
grep -q "npm-global/bin" ~/.zshrc || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc

# Install tools
npm install -g @anthropic-ai/claude-code
claude mcp add playwright "npx @playwright/mcp@latest"

# Install optional tools
if ! check_cmd uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! check_cmd bun; then
    curl -fsSL https://bun.sh/install | bash
fi

npm install -g n8n

echo "✅ Toolchain setup complete!"
echo "Run 'source ~/.zshrc' to reload your shell"
```

### **Maintenance**

- Weekly: Run verification script
- Monthly: Check for tool updates
- Quarterly: Review and update SOP
- Ongoing: Document new tools as added

### **References**

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides)
- [npm Documentation](https://docs.npmjs.com)
- Internal: DR-SOP-IT-ClaudeSetup-v1.0

### **Revision History**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-01-08 | IT Team | Initial release - Development toolchain setup |

### **Approval**

- **Created by**: DuetRight IT Team
- **Reviewed by**: [Pending]
- **Approved by**: [Pending]
- **Effective Date**: 2025-01-08