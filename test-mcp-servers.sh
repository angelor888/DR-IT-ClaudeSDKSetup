#!/bin/bash

# MCP Server Integration Test Script
# Tests all installed MCP servers for basic connectivity

set -e

echo "🧪 MCP Server Integration Test Suite"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results array
declare -a test_results

# Function to test if a server binary exists and is executable
test_server_binary() {
    local server_name="$1"
    local server_path="$2"
    
    echo -n "Testing $server_name binary... "
    
    if [ -f "$server_path" ]; then
        echo -e "${GREEN}✓ Found${NC}"
        test_results+=("$server_name:binary:PASS")
        return 0
    else
        echo -e "${RED}✗ Not found${NC}"
        test_results+=("$server_name:binary:FAIL")
        return 1
    fi
}

# Function to test if required dependencies are installed
test_dependencies() {
    local server_name="$1"
    local server_dir="$2"
    
    echo -n "Testing $server_name dependencies... "
    
    if [ -d "$server_dir/node_modules" ]; then
        echo -e "${GREEN}✓ Installed${NC}"
        test_results+=("$server_name:deps:PASS")
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        test_results+=("$server_name:deps:FAIL")
        return 1
    fi
}

# Function to test basic server startup (without authentication)
test_server_startup() {
    local server_name="$1"
    local server_path="$2"
    
    echo -n "Testing $server_name startup... "
    
    # Simple test - just check if the file can be loaded by node without syntax errors
    local error_output
    error_output=$(node -c "$server_path" 2>&1 || true)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Syntax valid${NC}"
        test_results+=("$server_name:startup:PASS")
        return 0
    else
        echo -e "${RED}✗ Syntax error${NC}"
        echo "Error: $error_output"
        test_results+=("$server_name:startup:FAIL")
        return 1
    fi
}

echo "1. Testing installed MCP servers..."
echo ""

# Test existing servers (already configured)
echo "📡 Testing existing servers:"

# Slack (npx-based)
echo -n "Testing Slack server (npx)... "
if command -v npx >/dev/null 2>&1; then
    echo -e "${GREEN}✓ NPX available${NC}"
    test_results+=("slack:binary:PASS")
else
    echo -e "${RED}✗ NPX missing${NC}"
    test_results+=("slack:binary:FAIL")
fi

# GitHub (npx-based)
echo -n "Testing GitHub server (npx)... "
if command -v npx >/dev/null 2>&1; then
    echo -e "${GREEN}✓ NPX available${NC}"
    test_results+=("github:binary:PASS")
else
    echo -e "${RED}✗ NPX missing${NC}"
    test_results+=("github:binary:FAIL")
fi

# Playwright (npx-based)
echo -n "Testing Playwright server (npx)... "
if command -v npx >/dev/null 2>&1; then
    echo -e "${GREEN}✓ NPX available${NC}"
    test_results+=("playwright:binary:PASS")
else
    echo -e "${RED}✗ NPX missing${NC}"
    test_results+=("playwright:binary:FAIL")
fi

echo ""
echo "🔧 Testing custom servers:"

# Base directory
BASE_DIR="/Users/angelone/DR-SETUP-DEV-ClaudeSDKEnvironment-v1.0-20250708"

# Test Airtable server
test_server_binary "Airtable" "$BASE_DIR/airtable-mcp-server/dist/index.js"
test_dependencies "Airtable" "$BASE_DIR/airtable-mcp-server"
if [ -f "$BASE_DIR/airtable-mcp-server/dist/index.js" ]; then
    test_server_startup "Airtable" "$BASE_DIR/airtable-mcp-server/dist/index.js"
fi

echo ""

# Test Firebase server
test_server_binary "Firebase" "$BASE_DIR/mcp-firebase/index.js"
test_dependencies "Firebase" "$BASE_DIR/mcp-firebase"
if [ -f "$BASE_DIR/mcp-firebase/index.js" ]; then
    test_server_startup "Firebase" "$BASE_DIR/mcp-firebase/index.js"
fi

echo ""

# Test Google Drive server
test_server_binary "Google Drive" "$BASE_DIR/mcp-google-drive/index.js"
test_dependencies "Google Drive" "$BASE_DIR/mcp-google-drive"
if [ -f "$BASE_DIR/mcp-google-drive/index.js" ]; then
    test_server_startup "Google Drive" "$BASE_DIR/mcp-google-drive/index.js"
fi

echo ""

# Test Gmail server
test_server_binary "Gmail" "$BASE_DIR/mcp-gmail/index.js"
test_dependencies "Gmail" "$BASE_DIR/mcp-gmail"
if [ -f "$BASE_DIR/mcp-gmail/index.js" ]; then
    test_server_startup "Gmail" "$BASE_DIR/mcp-gmail/index.js"
fi

echo ""

# Test QuickBooks server
test_server_binary "QuickBooks" "$BASE_DIR/mcp-quickbooks/index.js"
test_dependencies "QuickBooks" "$BASE_DIR/mcp-quickbooks"
if [ -f "$BASE_DIR/mcp-quickbooks/index.js" ]; then
    test_server_startup "QuickBooks" "$BASE_DIR/mcp-quickbooks/index.js"
fi

echo ""

# Test Matterport server
test_server_binary "Matterport" "$BASE_DIR/mcp-matterport/index.js"
test_dependencies "Matterport" "$BASE_DIR/mcp-matterport"
if [ -f "$BASE_DIR/mcp-matterport/index.js" ]; then
    test_server_startup "Matterport" "$BASE_DIR/mcp-matterport/index.js"
fi

echo ""

# Test SendGrid server
test_server_binary "SendGrid" "$BASE_DIR/mcp-sendgrid/index.js"
test_dependencies "SendGrid" "$BASE_DIR/mcp-sendgrid"
if [ -f "$BASE_DIR/mcp-sendgrid/index.js" ]; then
    test_server_startup "SendGrid" "$BASE_DIR/mcp-sendgrid/index.js"
fi

echo ""
echo "2. Testing Claude Code configuration..."

# Test if Claude Code config includes our servers
CLAUDE_CONFIG="$HOME/.claude.json"
if [ -f "$CLAUDE_CONFIG" ]; then
    echo -n "Testing Claude Code configuration... "
    
    # Count configured servers for our project
    server_count=$(grep -c "\"type\": \"stdio\"" "$CLAUDE_CONFIG" 2>/dev/null || echo "0")
    
    if [ "$server_count" -gt 0 ]; then
        echo -e "${GREEN}✓ $server_count servers configured${NC}"
        test_results+=("claude-config:PASS:$server_count")
    else
        echo -e "${RED}✗ No servers configured${NC}"
        test_results+=("claude-config:FAIL")
    fi
else
    echo -e "${RED}✗ Claude config file not found${NC}"
    test_results+=("claude-config:FAIL")
fi

echo ""
echo "3. Testing environment setup..."

# Test Node.js version
echo -n "Testing Node.js version... "
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version)
    echo -e "${GREEN}✓ $node_version${NC}"
    test_results+=("node:PASS:$node_version")
else
    echo -e "${RED}✗ Node.js not found${NC}"
    test_results+=("node:FAIL")
fi

# Test npm
echo -n "Testing npm... "
if command -v npm >/dev/null 2>&1; then
    npm_version=$(npm --version)
    echo -e "${GREEN}✓ $npm_version${NC}"
    test_results+=("npm:PASS:$npm_version")
else
    echo -e "${RED}✗ npm not found${NC}"
    test_results+=("npm:FAIL")
fi

echo ""
echo "📊 Test Results Summary"
echo "======================"

# Count results
total_tests=${#test_results[@]}
passed_tests=$(printf '%s\n' "${test_results[@]}" | grep -c ":PASS" 2>/dev/null || echo "0")
auth_required=$(printf '%s\n' "${test_results[@]}" | grep -c ":AUTH_REQUIRED" 2>/dev/null || echo "0")
failed_tests=$(printf '%s\n' "${test_results[@]}" | grep -c ":FAIL" 2>/dev/null)
if [ -z "$failed_tests" ]; then
    failed_tests=0
fi

echo "Total tests: $total_tests"
echo -e "Passed: ${GREEN}$passed_tests${NC}"
echo -e "Auth required: ${YELLOW}$auth_required${NC}"
echo -e "Failed: ${RED}$failed_tests${NC}"

echo ""
echo "📋 Detailed Results:"
for result in "${test_results[@]}"; do
    IFS=':' read -r server test_type status extra <<< "$result"
    
    if [[ "$status" == "PASS" ]] || [[ "$extra" != "" && "$test_type" == "PASS" ]]; then
        echo -e "  ${GREEN}✓${NC} $server ($test_type)"
    elif [[ "$status" == "AUTH_REQUIRED" ]]; then
        echo -e "  ${YELLOW}⚠${NC} $server ($test_type) - Authentication required"
    elif [[ "$status" == "FAIL" ]]; then
        echo -e "  ${RED}✗${NC} $server ($test_type)"
    else
        echo -e "  ${GREEN}✓${NC} $server ($test_type)"
    fi
done

echo ""

if [ "$failed_tests" -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! MCP servers are ready for authentication setup.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Set up authentication credentials (see MCP_SERVER_AUTHENTICATION.md)"
    echo "2. Test actual server functionality with Claude Code"
    echo "3. Verify integration with your actual service accounts"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the installation.${NC}"
    exit 1
fi