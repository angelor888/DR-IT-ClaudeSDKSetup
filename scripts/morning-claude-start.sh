#!/bin/bash
set -euo pipefail

# Morning Claude Startup Script
# One command to get your Claude environment ready for the day

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[✓]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
echo_error() { echo -e "${RED}[✗]${NC} $1"; }

clear

echo "================================================"
echo "       🌅 Good Morning! Starting Claude..."
echo "================================================"
echo

# Step 1: Update from git
echo_info "Checking for updates..."
cd "$PROJECT_ROOT"
git fetch --quiet

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ $LOCAL != $REMOTE ]; then
    echo_warning "Updates available! Pulling latest changes..."
    git pull
    echo_success "Updated to latest version"
    
    # Run sync from repo
    echo_info "Syncing configuration..."
    "$SCRIPT_DIR/sync-from-repo.sh"
else
    echo_success "Already up to date"
fi

# Step 2: Check Claude installation
echo_info "Checking Claude installation..."
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -n1)
    echo_success "Claude ready: $CLAUDE_VERSION"
else
    echo_error "Claude not found! Installing..."
    npm install -g @anthropic-ai/claude-code@latest
fi

# Step 3: Source shell integration
echo_info "Loading shell integration..."
if [ -f "$HOME/.config/claude/shell-integration.sh" ]; then
    source "$HOME/.config/claude/shell-integration.sh"
    echo_success "Shell integration loaded"
else
    echo_error "Shell integration not found!"
fi

# Step 4: Check environment file
echo_info "Checking API tokens..."
ENV_FILE="$HOME/.config/claude/environment"
if [ -f "$ENV_FILE" ]; then
    # Count configured tokens
    CONFIGURED_TOKENS=$(grep -E "^[A-Z_]+=.+" "$ENV_FILE" | grep -v "=$" | wc -l | tr -d ' ')
    TOTAL_TOKENS=$(grep -E "^[A-Z_]+=" "$ENV_FILE" | wc -l | tr -d ' ')
    echo_success "Tokens configured: $CONFIGURED_TOKENS/$TOTAL_TOKENS"
    
    if [ $CONFIGURED_TOKENS -lt $TOTAL_TOKENS ]; then
        echo_warning "Some tokens are missing. Run: nano $ENV_FILE"
    fi
else
    echo_error "Environment file not found! Creating template..."
    cp "$PROJECT_ROOT/claude-config/environment.template" "$ENV_FILE" 2>/dev/null || \
        echo "# Add your API tokens here" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

# Step 5: Check memory watch
echo_info "Checking memory watch..."
MEMORY_WATCH_PID=$(pgrep -f "memory-watch.sh" || true)
if [ -n "$MEMORY_WATCH_PID" ]; then
    echo_success "Memory watch active (PID: $MEMORY_WATCH_PID)"
else
    echo_warning "Memory watch not running. Start with: claude-memory-watch"
fi

# Step 6: Show current project
echo_info "Current directory: $(pwd)"
if [ -f "Claude.md" ]; then
    echo_success "Project Claude.md found"
elif [ -f ".claude/Claude.md" ]; then
    echo_success "Project .claude/Claude.md found"
else
    echo_info "No project-specific Claude.md"
fi

# Step 7: Quick system check
echo
echo "📊 Quick Status:"
echo "├─ Claude commands: $(type claude-init &>/dev/null && echo '✓' || echo '✗') claude-init"
echo "├─ Plan mode: $(type claude-plan &>/dev/null && echo '✓' || echo '✗') claude-plan"
echo "├─ Checkpoint: $(type claude-checkpoint &>/dev/null && echo '✓' || echo '✗') claude-checkpoint"
echo "├─ QA tools: $(type claude-qa &>/dev/null && echo '✓' || echo '✗') claude-qa"
echo "└─ Worktree: $(type claude-worktree &>/dev/null && echo '✓' || echo '✗') claude-worktree"

# Step 8: Show tips
echo
echo "💡 Quick Tips:"
echo "• Initialize project: claude-init"
echo "• Enter plan mode: Shift+Tab Shift+Tab (or claude-plan)"
echo "• Create checkpoint: claude-checkpoint \"message\""
echo "• View all commands: claude-help"

echo
echo_success "Claude is ready! Happy coding! 🚀"
echo

# Optional: Start in a specific project directory
# cd ~/Projects/current-project