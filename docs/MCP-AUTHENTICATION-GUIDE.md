# MCP Servers Authentication Guide

## Overview

This guide provides step-by-step authentication setup for all installed MCP servers in your DuetRight development environment.

## Installed MCP Servers

| Server | Package | Status | Auth Required |
|--------|---------|--------|---------------|
| Playwright | `@playwright/mcp` | ✅ Installed | No |
| GitHub | `@andrebuzeli/github-mcp-v2` | ✅ Installed | Yes - GitHub Token |
| Slack | `@modelcontextprotocol/server-slack` | ✅ Installed | Yes - Slack OAuth |
| Google Calendar | `mcp-google-calendar-plus` | ✅ Installed | Yes - Google OAuth |
| Notion | `@notionhq/notion-mcp-server` | ✅ Installed | Yes - Notion Token |
| Gmail | `@gongrzhe/server-gmail-autoauth-mcp` | ✅ Installed | Yes - Google OAuth |
| OpenAI | `openai-mcp-server` | ✅ Installed | Yes - OpenAI API Key |

## Authentication Setup Instructions

### 1. GitHub MCP Server Authentication

#### Step 1: Generate GitHub Personal Access Token
1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes needed:
   - `repo` (for repository access)
   - `read:org` (for organization access)
   - `read:user` (for user information)
   - `read:project` (for project access)

#### Step 2: Configure Environment
```bash
# Add to your environment variables
export GITHUB_TOKEN="your_github_token_here"

# Or add to ~/.config/claude/environment
echo "GITHUB_TOKEN=your_github_token_here" >> ~/.config/claude/environment
```

#### Step 3: Test GitHub Integration
```bash
# Test with Claude
claude "List my GitHub repositories"
claude "Show recent commits in my main repository"
```

### 2. Slack MCP Server Authentication

#### Step 1: Create Slack App
1. Go to Slack API: https://api.slack.com/apps
2. Click "Create New App" > "From scratch"
3. Name your app (e.g., "DuetRight Claude Integration")
4. Select your workspace

#### Step 2: Configure OAuth & Permissions
1. Go to "OAuth & Permissions" in your app settings
2. Add Bot Token Scopes:
   - `chat:write` (send messages)
   - `channels:read` (read channel information)
   - `channels:history` (read channel history)
   - `users:read` (read user information)
   - `files:write` (upload files)

#### Step 3: Install App to Workspace
1. Click "Install to Workspace"
2. Authorize the app
3. Copy the "Bot User OAuth Token"

#### Step 4: Configure Environment
```bash
# Add to your environment variables
export SLACK_BOT_TOKEN="xoxb-your-slack-bot-token-here"

# Or add to ~/.config/claude/environment
echo "SLACK_BOT_TOKEN=xoxb-your-slack-bot-token-here" >> ~/.config/claude/environment
```

#### Step 5: Test Slack Integration
```bash
# Test with Claude
claude "Send a test message to #general channel"
claude "List all channels in my Slack workspace"
```

### 3. Google Calendar MCP Server Authentication

#### Step 1: Create Google Cloud Project
1. Go to Google Cloud Console: https://console.cloud.google.com
2. Create a new project or select existing one
3. Enable Google Calendar API

#### Step 2: Create OAuth 2.0 Credentials
1. Go to "Credentials" > "Create Credentials" > "OAuth 2.0 Client ID"
2. Application type: "Desktop application"
3. Name: "DuetRight Claude Calendar Integration"
4. Download credentials JSON file

#### Step 3: Configure Environment
```bash
# Add to your environment variables
export GOOGLE_CALENDAR_CLIENT_ID="your_client_id_here"
export GOOGLE_CALENDAR_CLIENT_SECRET="your_client_secret_here"

# Or add to ~/.config/claude/environment
echo "GOOGLE_CALENDAR_CLIENT_ID=your_client_id_here" >> ~/.config/claude/environment
echo "GOOGLE_CALENDAR_CLIENT_SECRET=your_client_secret_here" >> ~/.config/claude/environment
```

#### Step 4: Initial OAuth Flow
```bash
# First time setup will prompt for OAuth authorization
claude "List my upcoming calendar events"
```

#### Step 5: Test Calendar Integration
```bash
# Test with Claude
claude "Show my calendar events for today"
claude "Create a meeting for tomorrow at 2 PM"
```

### 4. Notion MCP Server Authentication

#### Step 1: Create Notion Integration
1. Go to Notion Integrations: https://www.notion.so/my-integrations
2. Click "New integration"
3. Name: "DuetRight Claude Integration"
4. Select workspace
5. Submit and copy the "Internal Integration Token"

#### Step 2: Grant Database Access
1. Go to your Notion workspace
2. Share relevant databases/pages with your integration
3. Type "@DuetRight Claude Integration" and grant access

#### Step 3: Configure Environment
```bash
# Add to your environment variables
export NOTION_TOKEN="secret_your_notion_token_here"

# Or add to ~/.config/claude/environment
echo "NOTION_TOKEN=secret_your_notion_token_here" >> ~/.config/claude/environment
```

#### Step 4: Test Notion Integration
```bash
# Test with Claude
claude "List my Notion databases"
claude "Create a new page in my project database"
```

### 5. Gmail MCP Server Authentication

#### Step 1: Use Same Google Cloud Project
1. Use the same project from Google Calendar setup
2. Enable Gmail API in Google Cloud Console

#### Step 2: Configure OAuth Scopes
1. Go to "OAuth consent screen"
2. Add scopes:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/gmail.modify`

#### Step 3: Configure Environment
```bash
# Add to your environment variables (same as Calendar)
export GMAIL_CLIENT_ID="your_client_id_here"
export GMAIL_CLIENT_SECRET="your_client_secret_here"

# Or add to ~/.config/claude/environment
echo "GMAIL_CLIENT_ID=your_client_id_here" >> ~/.config/claude/environment
echo "GMAIL_CLIENT_SECRET=your_client_secret_here" >> ~/.config/claude/environment
```

#### Step 4: Test Gmail Integration
```bash
# Test with Claude
claude "Show my recent emails"
claude "Send a test email to myself"
```

### 6. OpenAI MCP Server Authentication

#### Step 1: Get OpenAI API Key
1. Go to OpenAI Platform: https://platform.openai.com/api-keys
2. Create new secret key
3. Copy the API key

#### Step 2: Configure Environment
```bash
# Add to your environment variables
export OPENAI_API_KEY="sk-your-openai-api-key-here"

# Or add to ~/.config/claude/environment
echo "OPENAI_API_KEY=sk-your-openai-api-key-here" >> ~/.config/claude/environment
```

#### Step 3: Test OpenAI Integration
```bash
# Test with Claude
claude "Use OpenAI to generate a creative writing prompt"
claude "Ask OpenAI to explain quantum computing"
```

## Environment Variables Summary

Create a consolidated environment file:

```bash
# ~/.config/claude/environment
GITHUB_TOKEN=your_github_token_here
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token-here
GOOGLE_CALENDAR_CLIENT_ID=your_google_client_id_here
GOOGLE_CALENDAR_CLIENT_SECRET=your_google_client_secret_here
GMAIL_CLIENT_ID=your_google_client_id_here
GMAIL_CLIENT_SECRET=your_google_client_secret_here
NOTION_TOKEN=secret_your_notion_token_here
OPENAI_API_KEY=sk-your-openai-api-key-here
```

## Testing All Integrations

### Quick Test Script
```bash
#!/bin/bash
# test-mcp-integrations.sh

echo "Testing GitHub integration..."
claude "List my GitHub repositories" | head -5

echo "Testing Slack integration..."
claude "List Slack channels" | head -5

echo "Testing Google Calendar integration..."
claude "Show today's calendar events" | head -5

echo "Testing Notion integration..."
claude "List my Notion databases" | head -5

echo "Testing Gmail integration..."
claude "Show recent emails" | head -5

echo "Testing OpenAI integration..."
claude "Use OpenAI to explain MCP in one sentence" | head -5

echo "All integrations tested!"
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Check environment variables are set correctly
   - Verify tokens/keys are valid and not expired
   - Ensure proper permissions are granted

2. **Permission Denied**
   - Check OAuth scopes are sufficient
   - Verify app is installed in correct workspace/organization
   - Ensure databases/resources are shared with integration

3. **Rate Limiting**
   - Implement exponential backoff
   - Check API quotas and usage limits
   - Consider caching frequently accessed data

4. **Network Issues**
   - Verify internet connectivity
   - Check if corporate firewall blocks API endpoints
   - Test with curl/wget to isolate issues

### Debug Commands

```bash
# Check environment variables
env | grep -E "(GITHUB|SLACK|GOOGLE|NOTION|OPENAI)"

# Test individual MCP servers
npx @andrebuzeli/github-mcp-v2@latest --help
npx @modelcontextprotocol/server-slack@latest --help
npx mcp-google-calendar-plus@latest --help
npx @notionhq/notion-mcp-server@latest --help
npx @gongrzhe/server-gmail-autoauth-mcp@latest --help
npx openai-mcp-server@latest --help
```

## Security Best Practices

1. **Token Management**
   - Use environment variables, never hardcode tokens
   - Rotate tokens regularly
   - Use least privilege principle for permissions

2. **Access Control**
   - Limit integration scope to necessary resources
   - Review and audit permissions regularly
   - Use dedicated service accounts where possible

3. **Monitoring**
   - Log API usage and errors
   - Set up alerts for unusual activity
   - Monitor rate limits and quotas

4. **Backup**
   - Keep backup of integration configurations
   - Document all authentication setups
   - Test restoration procedures

## Next Steps

1. ✅ Install all MCP servers
2. ⏳ Complete authentication setup for each service
3. ⏳ Test basic functionality
4. ⏳ Implement error handling and monitoring
5. ⏳ Document team access and permissions
6. ⏳ Set up automated testing for integrations

---

**Note**: This authentication setup is required for full functionality. Each service has its own authentication requirements and OAuth flows. Complete setup may take 1-2 hours depending on familiarity with each platform.