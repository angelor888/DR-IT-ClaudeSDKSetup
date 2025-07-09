#!/bin/bash
#
# Claude Code Workflow Validation Script
# Validates the complete highly efficient AI coding setup
#

set -euo pipefail

echo "🤖 Claude Code Workflow Validation"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counter for validation results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    ((TESTS_TOTAL++))
    
    echo -n "  Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        local result=$?
        if [ $result -eq $expected_result ]; then
            echo -e "${GREEN}✅ PASS${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ FAIL${NC} (Exit code: $result)"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}❌ FAIL${NC} (Command failed)"
        ((TESTS_FAILED++))
    fi
}

# Function to check file exists
check_file_exists() {
    local file="$1"
    local description="$2"
    
    ((TESTS_TOTAL++))
    
    echo -n "  Checking: $description... "
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ EXISTS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ MISSING${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to check directory exists
check_dir_exists() {
    local dir="$1"
    local description="$2"
    
    ((TESTS_TOTAL++))
    
    echo -n "  Checking: $description... "
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ EXISTS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ MISSING${NC}"
        ((TESTS_FAILED++))
    fi
}

echo -e "\n${BLUE}1. Basic Claude Code Installation${NC}"
echo "================================="
run_test "Claude Code installed" "command -v claude"
run_test "Claude Code version" "claude --version"

echo -e "\n${BLUE}2. Configuration Files${NC}"
echo "======================"
check_file_exists "$HOME/.config/claude/settings.json" "Main settings file"
check_file_exists "$HOME/.config/claude/scripts/claude-workflow-integration.sh" "Workflow integration script"
check_file_exists "$HOME/.config/claude/scripts/claude-template-manager.sh" "Template manager script"
check_file_exists "$HOME/.config/claude/scripts/validate-workflow-setup.sh" "Validation script"

echo -e "\n${BLUE}3. Hook System${NC}"
echo "==============="
check_dir_exists "$HOME/.config/claude/hooks" "Hooks directory"
check_file_exists "$HOME/.config/claude/hooks/safety/pre-tool-use-safety.sh" "Safety hook"
check_file_exists "$HOME/.config/claude/hooks/logging/enhanced-post-tool-use.sh" "Enhanced logging hook"
check_file_exists "$HOME/.config/claude/hooks/notifications/notification-hook.sh" "Notification hook"
check_file_exists "$HOME/.config/claude/hooks/coordination/sub-agent-stop-hook.sh" "Sub-agent coordination hook"

echo -e "\n${BLUE}4. Templates System${NC}"
echo "==================="
check_dir_exists "$HOME/.config/claude/templates" "Templates directory"
check_file_exists "$HOME/.config/claude/templates/CLAUDE-default.md" "Default template"
check_file_exists "$HOME/.config/claude/templates/CLAUDE-react.md" "React template"
check_file_exists "$HOME/.config/claude/templates/CLAUDE-nodejs.md" "Node.js template"
check_file_exists "$HOME/.config/claude/templates/CLAUDE-python.md" "Python template"

echo -e "\n${BLUE}5. Custom Slash Commands${NC}"
echo "========================"
check_dir_exists "$HOME/.config/claude/commands" "Commands directory"
check_file_exists "$HOME/.config/claude/commands/plan.md" "Plan command"
check_file_exists "$HOME/.config/claude/commands/checkpoint.md" "Checkpoint command"
check_file_exists "$HOME/.config/claude/commands/qa.md" "Quality assurance command"
check_file_exists "$HOME/.config/claude/commands/docs.md" "Documentation command"
check_file_exists "$HOME/.config/claude/commands/parallel.md" "Parallel execution command"

echo -e "\n${BLUE}6. Settings Configuration${NC}"
echo "========================="

# Check key settings in settings.json
if [ -f "$HOME/.config/claude/settings.json" ]; then
    run_test "Plan mode enabled" "grep -q 'planMode' ~/.config/claude/settings.json"
    run_test "Claude Opus model configured" "grep -q 'claude-opus-4' ~/.config/claude/settings.json"
    run_test "Hooks enabled" "grep -q '\"enabled\": true' ~/.config/claude/settings.json"
    run_test "Voice notifications configured" "grep -q 'voiceEnabled' ~/.config/claude/settings.json"
    run_test "Workflow settings present" "grep -q 'gitIntegration' ~/.config/claude/settings.json"
fi

echo -e "\n${BLUE}7. Shell Integration${NC}"
echo "===================="

# Check if shell integration is installed
SHELL_RC=""
case "$SHELL" in
    */bash) SHELL_RC="$HOME/.bashrc" ;;
    */zsh) SHELL_RC="$HOME/.zshrc" ;;
    *) echo "  Unknown shell: $SHELL" ;;
esac

if [ -n "$SHELL_RC" ]; then
    run_test "Shell integration installed" "grep -q 'claude-workflow-integration.sh' $SHELL_RC"
fi

echo -e "\n${BLUE}8. Functional Testing${NC}"
echo "===================="

# Test template manager
run_test "Template manager executable" "test -x ~/.config/claude/scripts/claude-template-manager.sh"
run_test "Template manager detects projects" "~/.config/claude/scripts/claude-template-manager.sh detect"

# Test workflow integration
run_test "Workflow integration script executable" "test -x ~/.config/claude/scripts/claude-workflow-integration.sh"

echo -e "\n${BLUE}9. Dependencies Check${NC}"
echo "===================="
run_test "jq installed" "command -v jq"
run_test "git installed" "command -v git"
run_test "curl installed" "command -v curl"
run_test "Node.js installed" "command -v node"

echo -e "\n${BLUE}10. Log Directories${NC}"
echo "==================="
check_dir_exists "$HOME/.config/claude/logs" "Logs directory"

# Create log directories if they don't exist
mkdir -p "$HOME/.config/claude/logs"
mkdir -p "$HOME/.config/claude/logs/conversations"
mkdir -p "$HOME/.config/claude/logs/sub-agents"

echo -e "\n${BLUE}Validation Results${NC}"
echo "=================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total tests: $TESTS_TOTAL"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! Your Claude Code workflow is fully configured.${NC}"
else
    echo -e "\n${YELLOW}⚠️  Some tests failed. Please review the issues above.${NC}"
fi

echo -e "\n${BLUE}Next Steps${NC}"
echo "=========="
echo "1. 🔄 Restart your terminal or run: source $SHELL_RC"
echo "2. 🚀 Test the workflow with: claude-init"
echo "3. 📋 Try plan mode with: claude-plan 'Create a simple function'"
echo "4. 🔍 Use quality assurance: claude-qa 'recent changes'"
echo "5. 💾 Create checkpoints: claude-checkpoint 'Setup complete'"

echo -e "\n${BLUE}Available Commands${NC}"
echo "=================="
echo "• claude-init [name]          - Initialize project with smart templates"
echo "• claude-context 'text'       - Add context to CLAUDE.md"
echo "• claude-plan 'request'       - Start with execution plan"
echo "• claude-checkpoint ['msg']   - Create Git checkpoint"
echo "• claude-qa ['scope']         - Run quality assurance review"
echo "• claude-docs 'url'           - Fetch documentation"
echo "• claude-switch /path         - Switch projects with context"
echo "• claude-multi /path1 /path2  - Work across multiple projects"
echo "• claude-help                 - Show all available commands"

echo -e "\n${BLUE}Slash Commands in Claude Code${NC}"
echo "============================="
echo "• /plan                       - Enter plan mode"
echo "• /checkpoint                 - Git checkpoint prompt"
echo "• /qa                         - Quality assurance review"
echo "• /docs                       - Fetch documentation"
echo "• /parallel                   - Parallel execution analysis"
echo "• /tools                      - Show available tools"
echo "• /memory                     - Edit memory files"

if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi