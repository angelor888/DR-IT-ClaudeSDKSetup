#!/bin/bash
#
# DR-IT-ClaudeSDKSetup Installation Verification
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

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Test functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Verification tests
verify_system_requirements() {
    header "System Requirements"
    
    # macOS check
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pass "macOS detected"
    else
        fail "macOS required"
    fi
    
    # Homebrew
    if command -v brew &> /dev/null; then
        pass "Homebrew installed"
    else
        fail "Homebrew not found"
    fi
    
    # Docker
    if docker info &> /dev/null; then
        pass "Docker running"
    else
        fail "Docker not running or not installed"
    fi
    
    # Git
    if command -v git &> /dev/null; then
        pass "Git installed"
    else
        fail "Git not found"
    fi
}

verify_directories() {
    header "Directory Structure"
    
    DIRS=(
        "$HOME/.config/claude"
        "$HOME/.config/claude/scripts"
        "$HOME/.config/claude/logs"
        "$HOME/.config/claude/sdk-examples"
        "$HOME/easy-mcp"
    )
    
    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            pass "Directory exists: $dir"
        else
            fail "Directory missing: $dir"
        fi
    done
}

verify_environment_variables() {
    header "Environment Variables"
    
    # Check if variables are set
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        pass "ANTHROPIC_API_KEY is set"
    else
        warn "ANTHROPIC_API_KEY not set in current shell"
    fi
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        pass "GITHUB_TOKEN is set"
    else
        warn "GITHUB_TOKEN not set in current shell"
    fi
    
    # Check .env file
    if [ -f "$HOME/easy-mcp/.env" ]; then
        pass ".env file exists"
        
        # Check permissions
        PERMS=$(stat -f "%OLp" "$HOME/easy-mcp/.env" 2>/dev/null || stat -c "%a" "$HOME/easy-mcp/.env" 2>/dev/null)
        if [ "$PERMS" = "600" ]; then
            pass ".env has secure permissions (600)"
        else
            warn ".env permissions not secure (current: $PERMS, should be 600)"
        fi
    else
        fail ".env file missing"
    fi
}

verify_mcp_services() {
    header "MCP Services"
    
    # Check if docker-compose file exists
    if [ -f "$HOME/easy-mcp/docker-compose.yml" ]; then
        pass "docker-compose.yml exists"
    else
        fail "docker-compose.yml missing"
    fi
    
    # Check running containers
    SERVICES=("mcp-filesystem-enhanced" "mcp-memory-enhanced" "mcp-puppeteer-enhanced" "mcp-everything-enhanced" "mcp-watchtower")
    
    for service in "${SERVICES[@]}"; do
        if docker ps | grep -q "$service"; then
            pass "$service is running"
        else
            warn "$service is not running"
        fi
    done
}

verify_claude_sdk() {
    header "Claude SDK"
    
    # Python SDK
    if [ -d "$HOME/.config/claude/sdk-examples/python/venv" ]; then
        pass "Python virtual environment exists"
        
        # Check if anthropic is installed
        if source "$HOME/.config/claude/sdk-examples/python/venv/bin/activate" 2>/dev/null && python -c "import anthropic" 2>/dev/null; then
            pass "Python anthropic package installed"
            deactivate
        else
            fail "Python anthropic package not installed"
        fi
    else
        fail "Python virtual environment missing"
    fi
    
    # TypeScript SDK
    if [ -f "$HOME/.config/claude/sdk-examples/typescript/package.json" ]; then
        pass "TypeScript project initialized"
        
        if [ -d "$HOME/.config/claude/sdk-examples/typescript/node_modules/@anthropic-ai" ]; then
            pass "TypeScript SDK installed"
        else
            fail "TypeScript SDK not installed"
        fi
    else
        fail "TypeScript project not initialized"
    fi
}

verify_autoupdate() {
    header "Auto-Update System"
    
    # Check auto-update script
    if [ -x "$HOME/.config/claude/scripts/auto-update.sh" ]; then
        pass "Auto-update script is executable"
    else
        fail "Auto-update script missing or not executable"
    fi
    
    # Check LaunchAgent
    PLIST="$HOME/Library/LaunchAgents/com.claude.autoupdate.plist"
    if [ -f "$PLIST" ]; then
        pass "LaunchAgent plist exists"
        
        if launchctl list | grep -q "com.claude.autoupdate"; then
            pass "LaunchAgent is loaded"
        else
            warn "LaunchAgent exists but not loaded"
        fi
    else
        fail "LaunchAgent plist missing"
    fi
    
    # Check Watchtower
    if docker ps | grep -q watchtower; then
        pass "Docker Watchtower is running"
    else
        warn "Docker Watchtower not running"
    fi
}

verify_shell_integration() {
    header "Shell Integration"
    
    # Check if integration file exists
    if [ -f "$HOME/.config/claude/shell-integration.sh" ]; then
        pass "Shell integration file exists"
    else
        fail "Shell integration file missing"
    fi
    
    # Check if sourced in shell profile
    SHELL_PROFILE=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_PROFILE" ] && grep -q "claude/shell-integration.sh" "$SHELL_PROFILE"; then
        pass "Shell integration added to profile"
    else
        warn "Shell integration not found in profile"
    fi
}

run_api_test() {
    header "API Connectivity Test"
    
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        echo "Testing Claude API..."
        
        # Try Python test
        if [ -f "$HOME/.config/claude/sdk-examples/python/test-api.py" ]; then
            cd "$HOME/.config/claude/sdk-examples/python"
            if source venv/bin/activate 2>/dev/null && python test-api.py 2>&1 | grep -q "API test successful"; then
                pass "Claude API test successful"
                deactivate
            else
                fail "Claude API test failed"
                deactivate 2>/dev/null
            fi
        else
            warn "API test script not found"
        fi
    else
        warn "Skipping API test (ANTHROPIC_API_KEY not set)"
    fi
}

# Main verification
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  DR-IT Claude Setup Verification       ║${NC}"
    echo -e "${BLUE}║  Version 1.0.0 - 2025-07-08           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    
    # Run all verifications
    verify_system_requirements
    verify_directories
    verify_environment_variables
    verify_mcp_services
    verify_claude_sdk
    verify_autoupdate
    verify_shell_integration
    run_api_test
    
    # Summary
    echo -e "\n${BLUE}=== Verification Summary ===${NC}"
    echo -e "Passed:   ${GREEN}$PASSED${NC}"
    echo -e "Failed:   ${RED}$FAILED${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✅ All critical checks passed!${NC}"
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Some warnings need attention${NC}"
        fi
        exit 0
    else
        echo -e "\n${RED}❌ Some checks failed. Please review and fix the issues.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"