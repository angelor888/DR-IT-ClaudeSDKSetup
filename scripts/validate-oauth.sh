#!/bin/bash
#
# OAuth Validation Script
# Checks if all OAuth tokens are properly configured
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ENV_FILE="$HOME/.config/claude/environment"

echo -e "${BLUE}🔍 Claude MCP OAuth Validation${NC}"
echo "==============================="
echo ""

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Environment file not found at: $ENV_FILE${NC}"
    echo "   Run: /Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/oauth-setup.sh"
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Counter for statistics
TOTAL_SERVICES=0
CONFIGURED_SERVICES=0
MISSING_SERVICES=0

# Function to check token
check_token() {
    local var_name="$1"
    local service_name="$2"
    local setup_url="$3"
    local var_value="${!var_name:-}"
    
    ((TOTAL_SERVICES++))
    
    echo -n "  $service_name: "
    
    if [ -n "$var_value" ]; then
        # Mask the token for display
        local masked="${var_value:0:10}...${var_value: -4}"
        echo -e "${GREEN}✓ Configured${NC} ($masked)"
        ((CONFIGURED_SERVICES++))
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        echo -e "    ${YELLOW}→ Setup at: $setup_url${NC}"
        ((MISSING_SERVICES++))
        return 1
    fi
}

# Function to test API connection
test_connection() {
    local service_name="$1"
    local test_command="$2"
    
    echo -n "  Testing $service_name connection: "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Unable to verify${NC}"
        return 1
    fi
}

echo -e "${BLUE}1. GitHub Integration${NC}"
echo "====================="
check_token "GITHUB_TOKEN" "GitHub Token" "https://github.com/settings/tokens"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    test_connection "GitHub" "curl -s -H 'Authorization: token $GITHUB_TOKEN' https://api.github.com/user | grep -q login"
fi

echo -e "\n${BLUE}2. Google Services${NC}"
echo "=================="
check_token "GOOGLE_CLIENT_ID" "Google Client ID" "https://console.cloud.google.com"
check_token "GOOGLE_CLIENT_SECRET" "Google Client Secret" "https://console.cloud.google.com"
check_token "GMAIL_CLIENT_ID" "Gmail Client ID" "https://console.cloud.google.com"
check_token "GMAIL_CLIENT_SECRET" "Gmail Client Secret" "https://console.cloud.google.com"
check_token "GOOGLE_DRIVE_CLIENT_ID" "Drive Client ID" "https://console.cloud.google.com"
check_token "GOOGLE_DRIVE_CLIENT_SECRET" "Drive Client Secret" "https://console.cloud.google.com"
check_token "GOOGLE_DRIVE_REFRESH_TOKEN" "Drive Refresh Token" "Run: google-oauth-flow.py"

echo -e "\n${BLUE}3. QuickBooks${NC}"
echo "============="
check_token "QUICKBOOKS_CONSUMER_KEY" "Consumer Key" "https://developer.intuit.com"
check_token "QUICKBOOKS_CONSUMER_SECRET" "Consumer Secret" "https://developer.intuit.com"
check_token "QUICKBOOKS_ACCESS_TOKEN" "Access Token" "OAuth flow required"
check_token "QUICKBOOKS_ACCESS_TOKEN_SECRET" "Access Secret" "OAuth flow required"

echo -e "\n${BLUE}4. Productivity Tools${NC}"
echo "====================="
check_token "NOTION_TOKEN" "Notion Token" "https://www.notion.so/my-integrations"
check_token "AIRTABLE_API_KEY" "Airtable API Key" "https://airtable.com/create/tokens"
check_token "CONFLUENCE_API_TOKEN" "Confluence Token" "https://id.atlassian.com/manage-profile/security/api-tokens"

echo -e "\n${BLUE}5. Communication Services${NC}"
echo "========================="
check_token "SLACK_BOT_TOKEN" "Slack Bot Token" "https://api.slack.com/apps"
check_token "SENDGRID_API_KEY" "SendGrid API Key" "https://app.sendgrid.com/settings/api_keys"

echo -e "\n${BLUE}6. AI & Data Services${NC}"
echo "====================="
check_token "OPENAI_API_KEY" "OpenAI API Key" "https://platform.openai.com/api-keys"
check_token "FIRECRAWL_API_KEY" "Firecrawl API Key" "https://www.firecrawl.dev"
check_token "TAVILY_API_KEY" "Tavily API Key" "https://tavily.com"

echo -e "\n${BLUE}7. Infrastructure${NC}"
echo "================="
check_token "CLOUDFLARE_API_TOKEN" "Cloudflare Token" "https://dash.cloudflare.com/profile/api-tokens"
check_token "NEON_API_KEY" "Neon API Key" "https://console.neon.tech"
check_token "MATTERPORT_API_KEY" "Matterport API Key" "https://developers.matterport.com"

echo -e "\n${BLUE}Summary${NC}"
echo "======="
echo -e "Total Services: $TOTAL_SERVICES"
echo -e "Configured: ${GREEN}$CONFIGURED_SERVICES${NC}"
echo -e "Missing: ${RED}$MISSING_SERVICES${NC}"

# Calculate percentage
if [ $TOTAL_SERVICES -gt 0 ]; then
    PERCENTAGE=$((CONFIGURED_SERVICES * 100 / TOTAL_SERVICES))
    echo -e "Completion: ${YELLOW}$PERCENTAGE%${NC}"
fi

echo -e "\n${BLUE}MCP Service Status${NC}"
echo "=================="

# Check if Docker is running
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo -e "Docker: ${GREEN}✓ Running${NC}"
    
    # Check MCP containers
    if [ -f "$HOME/mcp-services/docker-compose.yml" ]; then
        echo -e "\nMCP Containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mcp-|claude-)" | while read -r line; do
            if echo "$line" | grep -q "Up"; then
                echo -e "  ${GREEN}✓${NC} $line"
            else
                echo -e "  ${RED}✗${NC} $line"
            fi
        done || echo "  No MCP containers running"
    fi
else
    echo -e "Docker: ${RED}✗ Not running${NC}"
fi

echo -e "\n${BLUE}Next Steps${NC}"
echo "==========="

if [ $MISSING_SERVICES -gt 0 ]; then
    echo "1. Complete OAuth setup for missing services:"
    echo "   ${GREEN}/Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/oauth-setup.sh${NC}"
    echo ""
fi

if [ -z "${GOOGLE_DRIVE_REFRESH_TOKEN:-}" ] && [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
    echo "2. Generate Google Drive refresh token:"
    echo "   ${GREEN}python3 /Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/google-oauth-flow.py${NC}"
    echo ""
fi

echo "3. Restart MCP services to apply changes:"
echo "   ${GREEN}docker-compose -f ~/mcp-services/docker-compose.yml restart${NC}"
echo ""

if [ $CONFIGURED_SERVICES -eq $TOTAL_SERVICES ]; then
    echo -e "${GREEN}🎉 All OAuth services are configured!${NC}"
else
    echo -e "${YELLOW}⚠️  Some services still need configuration.${NC}"
fi

# Check file permissions
if [ -f "$ENV_FILE" ]; then
    PERMS=$(stat -f "%A" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE" 2>/dev/null)
    if [ "$PERMS" != "600" ]; then
        echo -e "\n${YELLOW}⚠️  Security Warning: Environment file permissions should be 600${NC}"
        echo "   Run: chmod 600 $ENV_FILE"
    fi
fi