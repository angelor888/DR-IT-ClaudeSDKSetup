#!/bin/bash
set -euo pipefail

# Master Claude Environment Installation Script
# Syncs Claude setup across multiple computers
# Created: $(date +%Y-%m-%d)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
BACKUP_DIR="$HOME/.config/claude-backup-$(date +%Y%m%d-%H%M%S)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo_error "This script is designed for macOS. Please modify for other platforms."
    exit 1
fi

echo "================================================"
echo "    Claude Multi-Computer Setup Installer"
echo "================================================"
echo

# Step 1: Check prerequisites
echo_info "Checking prerequisites..."

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo_error "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo_warning "Node.js not found. Installing via Homebrew..."
    brew install node
else
    echo_success "Node.js $(node --version) found"
fi

# Check for git
if ! command -v git &> /dev/null; then
    echo_error "Git not found. Please install git first."
    exit 1
fi

# Step 2: Backup existing configuration
if [ -d "$CLAUDE_CONFIG_DIR" ]; then
    echo_info "Backing up existing Claude configuration..."
    mkdir -p "$BACKUP_DIR"
    cp -R "$CLAUDE_CONFIG_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    echo_success "Backup created at: $BACKUP_DIR"
fi

# Step 3: Install Claude Code globally
echo_info "Installing/updating Claude Code..."
npm install -g @anthropic-ai/claude-code@latest
echo_success "Claude Code installed"

# Step 4: Create Claude config directory
echo_info "Creating Claude configuration directory..."
mkdir -p "$CLAUDE_CONFIG_DIR"
mkdir -p "$CLAUDE_CONFIG_DIR/scripts"
mkdir -p "$CLAUDE_CONFIG_DIR/templates"
mkdir -p "$CLAUDE_CONFIG_DIR/commands"
mkdir -p "$CLAUDE_CONFIG_DIR/hooks"
mkdir -p "$CLAUDE_CONFIG_DIR/logs"
mkdir -p "$CLAUDE_CONFIG_DIR/audio"
mkdir -p "$CLAUDE_CONFIG_DIR/clipboard"
mkdir -p "$CLAUDE_CONFIG_DIR/ide"

# Step 5: Copy configuration files from repo
echo_info "Copying configuration files..."

# Copy main configuration files from claude-config in repo
if [ -d "$PROJECT_ROOT/claude-config" ]; then
    # Copy settings.json
    if [ -f "$PROJECT_ROOT/claude-config/settings.json" ]; then
        cp "$PROJECT_ROOT/claude-config/settings.json" "$CLAUDE_CONFIG_DIR/"
        echo_success "Copied settings.json"
    fi
    
    # Copy shell integration
    if [ -f "$PROJECT_ROOT/claude-config/shell-integration.sh" ]; then
        cp "$PROJECT_ROOT/claude-config/shell-integration.sh" "$CLAUDE_CONFIG_DIR/"
        echo_success "Copied shell-integration.sh"
    fi
    
    # Copy all scripts
    if [ -d "$PROJECT_ROOT/claude-config/scripts" ]; then
        cp -R "$PROJECT_ROOT/claude-config/scripts/"* "$CLAUDE_CONFIG_DIR/scripts/"
        chmod +x "$CLAUDE_CONFIG_DIR/scripts/"*.sh
        echo_success "Copied and made scripts executable"
    fi
    
    # Copy templates
    if [ -d "$PROJECT_ROOT/claude-config/templates" ]; then
        cp -R "$PROJECT_ROOT/claude-config/templates/"* "$CLAUDE_CONFIG_DIR/templates/"
        echo_success "Copied templates"
    fi
    
    # Copy commands
    if [ -d "$PROJECT_ROOT/claude-config/commands" ]; then
        cp -R "$PROJECT_ROOT/claude-config/commands/"* "$CLAUDE_CONFIG_DIR/commands/"
        echo_success "Copied commands"
    fi
    
    # Copy hooks
    if [ -d "$PROJECT_ROOT/claude-config/hooks" ]; then
        cp -R "$PROJECT_ROOT/claude-config/hooks/"* "$CLAUDE_CONFIG_DIR/hooks/"
        chmod +x "$CLAUDE_CONFIG_DIR/hooks/"*.sh
        chmod +x "$CLAUDE_CONFIG_DIR/hooks/"**/*.sh 2>/dev/null || true
        echo_success "Copied hooks"
    fi
    
    # Copy other config files
    for config_file in mode-config.json safe-mode.json multi-computer-sync.json worktrees.json; do
        if [ -f "$PROJECT_ROOT/claude-config/$config_file" ]; then
            cp "$PROJECT_ROOT/claude-config/$config_file" "$CLAUDE_CONFIG_DIR/"
            echo_success "Copied $config_file"
        fi
    done
fi

# Step 6: Set up shell integration
echo_info "Setting up shell integration..."

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.zshrc"  # Default to zsh on macOS
fi

# Add source line to shell RC if not already present
if ! grep -q "source.*claude.*shell-integration.sh" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Claude Shell Integration" >> "$SHELL_RC"
    echo "[ -f ~/.config/claude/shell-integration.sh ] && source ~/.config/claude/shell-integration.sh" >> "$SHELL_RC"
    echo_success "Added Claude shell integration to $SHELL_RC"
else
    echo_info "Shell integration already configured"
fi

# Step 7: Create environment file template if it doesn't exist
if [ ! -f "$CLAUDE_CONFIG_DIR/environment" ]; then
    echo_info "Creating environment template..."
    cp "$PROJECT_ROOT/claude-config/environment.template" "$CLAUDE_CONFIG_DIR/environment" 2>/dev/null || \
    cat > "$CLAUDE_CONFIG_DIR/environment" << 'EOF'
# Claude MCP Server Environment Configuration
# Add your tokens and credentials below

# GitHub MCP Server
GITHUB_TOKEN=

# Slack MCP Server  
SLACK_BOT_TOKEN=
SLACK_SIGNING_SECRET=
SLACK_APP_TOKEN=

# Google Services
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GMAIL_CLIENT_ID=
GMAIL_CLIENT_SECRET=

# Add other tokens as needed...
EOF
    chmod 600 "$CLAUDE_CONFIG_DIR/environment"
    echo_warning "Created environment template. Please add your API tokens!"
fi

# Step 8: Set proper permissions
echo_info "Setting file permissions..."
chmod 700 "$CLAUDE_CONFIG_DIR"
chmod 600 "$CLAUDE_CONFIG_DIR/environment" 2>/dev/null || true
chmod 600 "$CLAUDE_CONFIG_DIR/environment.backup"* 2>/dev/null || true

# Step 9: Create symlink for easy access
if [ ! -L "$HOME/claude-setup" ]; then
    ln -s "$PROJECT_ROOT" "$HOME/claude-setup"
    echo_success "Created symlink: ~/claude-setup -> $PROJECT_ROOT"
fi

# Step 10: Run validation
echo_info "Running validation..."
if [ -x "$CLAUDE_CONFIG_DIR/scripts/validate-workflow-setup.sh" ]; then
    "$CLAUDE_CONFIG_DIR/scripts/validate-workflow-setup.sh" || true
fi

# Summary
echo
echo "================================================"
echo "    Installation Complete!"
echo "================================================"
echo
echo_success "Claude environment has been set up successfully!"
echo
echo "Next steps:"
echo "1. Add your API tokens to: $CLAUDE_CONFIG_DIR/environment"
echo "2. Restart your terminal or run: source $SHELL_RC"
echo "3. Test with: claude --version"
echo "4. Initialize a project with: claude-init"
echo
echo "For daily sync:"
echo "- Morning: cd ~/claude-setup && git pull && ./scripts/sync-from-repo.sh"
echo "- Evening: cd ~/claude-setup && ./scripts/sync-to-repo.sh && git push"
echo
echo "Documentation: ~/claude-setup/CLAUDE-SYNC-MANIFEST.md"