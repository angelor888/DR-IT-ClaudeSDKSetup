# OAuth Setup Guide for Claude MCP Services

**Date**: July 8, 2025  
**Status**: Ready for OAuth Configuration  

## 🔐 Overview

This guide walks through setting up OAuth authentication for all MCP services that require it. After completing this setup, you'll have full access to 25+ integrated services.

## 📋 Services Requiring OAuth Setup

### 1. GitHub Personal Access Token
**Service**: GitHub MCP Server  
**Environment Variable**: `GITHUB_TOKEN`

#### Setup Steps:
1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Name: "Claude MCP Integration"
4. Expiration: 90 days (or custom)
5. Select scopes:
   - ✅ repo (Full control of private repositories)
   - ✅ read:org (Read org and team membership)
   - ✅ read:user (Read user profile data)
   - ✅ read:project (Read project data)
6. Click "Generate token"
7. Copy the token immediately (won't be shown again)

### 2. Google Services OAuth (Calendar & Gmail)
**Services**: Google Calendar & Gmail MCP Servers  
**Environment Variables**: 
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GMAIL_CLIENT_ID`
- `GMAIL_CLIENT_SECRET`

#### Setup Steps:
1. Go to https://console.cloud.google.com
2. Create new project or select existing: "Claude MCP Integration"
3. Enable APIs:
   - Go to "APIs & Services" → "Enable APIs and services"
   - Search and enable: "Google Calendar API"
   - Search and enable: "Gmail API"
4. Create OAuth credentials:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Configure consent screen if needed:
     - User Type: Internal (if using workspace) or External
     - App name: "Claude MCP Integration"
     - Add scopes: calendar.readonly, gmail.readonly, gmail.send
   - Application type: "Desktop app"
   - Name: "Claude MCP Client"
5. Download credentials JSON
6. Extract `client_id` and `client_secret` from JSON

### 3. Google Drive OAuth
**Service**: Google Drive MCP Server  
**Environment Variables**:
- `GOOGLE_DRIVE_CLIENT_ID`
- `GOOGLE_DRIVE_CLIENT_SECRET`
- `GOOGLE_DRIVE_REFRESH_TOKEN`

#### Setup Steps:
1. In same Google Cloud project, enable "Google Drive API"
2. Can use same OAuth client ID from above, or create new one
3. For refresh token, you'll need to run OAuth flow:
   ```bash
   # Install Google OAuth CLI tool
   pip install google-auth-oauthlib google-auth-httplib2
   
   # Run OAuth flow (we'll create a script for this)
   python3 /Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/google-oauth-flow.py
   ```

### 4. QuickBooks OAuth
**Service**: QuickBooks MCP Server  
**Environment Variables**:
- `QUICKBOOKS_CONSUMER_KEY`
- `QUICKBOOKS_CONSUMER_SECRET`
- `QUICKBOOKS_ACCESS_TOKEN`
- `QUICKBOOKS_ACCESS_TOKEN_SECRET`

#### Setup Steps:
1. Go to https://developer.intuit.com
2. Sign in with Intuit account
3. Go to "My Apps" → "Create an app"
4. Select "QuickBooks Online and Payments"
5. App name: "Claude MCP Integration"
6. Select scopes:
   - Accounting (read/write)
   - Payments (if needed)
7. Get OAuth 2.0 credentials from app settings
8. Configure redirect URI: `http://localhost:8080/callback`

### 5. Notion Integration Token
**Service**: Notion MCP Server  
**Environment Variable**: `NOTION_TOKEN`

#### Setup Steps:
1. Go to https://www.notion.so/my-integrations
2. Click "New integration"
3. Name: "Claude MCP Integration"
4. Select workspace
5. Capabilities: Read, Update, Insert content
6. Copy "Internal Integration Token"
7. Share Notion pages with integration:
   - Open Notion pages/databases you want to access
   - Click "..." → "Add connections" → Select your integration

### 6. Additional API Keys

#### OpenAI
1. Go to https://platform.openai.com/api-keys
2. Create new secret key
3. Name: "Claude MCP Integration"
4. Copy key for `OPENAI_API_KEY`

#### Airtable
1. Go to https://airtable.com/create/tokens
2. Create new personal access token
3. Name: "Claude MCP Integration"
4. Scopes: data.records:read, data.records:write
5. Access: Select bases to access
6. Copy token for `AIRTABLE_API_KEY`

#### SendGrid
1. Go to https://app.sendgrid.com/settings/api_keys
2. Create API Key
3. Name: "Claude MCP Integration"
4. API Key Permissions: Full Access
5. Copy key for `SENDGRID_API_KEY`

#### Cloudflare
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Create Token
3. Template: Custom token
4. Permissions: Zone:Read, DNS:Edit
5. Copy token for `CLOUDFLARE_API_TOKEN`

## 🚀 Quick Setup Script

After gathering all tokens, run this to update your environment:

```bash
# Edit the environment file
nano ~/.config/claude/environment

# Or use our setup script (to be created)
/Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/oauth-setup.sh
```

## 📝 Environment File Template

```bash
# GitHub
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Google Services
export GOOGLE_CLIENT_ID="xxxxxxxxxxxxx.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="GOCSPX-xxxxxxxxxxxxxxxxxxxx"
export GMAIL_CLIENT_ID="xxxxxxxxxxxxx.apps.googleusercontent.com"
export GMAIL_CLIENT_SECRET="GOCSPX-xxxxxxxxxxxxxxxxxxxx"
export GOOGLE_DRIVE_CLIENT_ID="xxxxxxxxxxxxx.apps.googleusercontent.com"
export GOOGLE_DRIVE_CLIENT_SECRET="GOCSPX-xxxxxxxxxxxxxxxxxxxx"
export GOOGLE_DRIVE_REFRESH_TOKEN="1//xxxxxxxxxxxxxxxxxxxx"

# QuickBooks
export QUICKBOOKS_CONSUMER_KEY="xxxxxxxxxxxxxxxxxxxx"
export QUICKBOOKS_CONSUMER_SECRET="xxxxxxxxxxxxxxxxxxxx"
export QUICKBOOKS_ACCESS_TOKEN="xxxxxxxxxxxxxxxxxxxx"
export QUICKBOOKS_ACCESS_TOKEN_SECRET="xxxxxxxxxxxxxxxxxxxx"

# Other Services
export NOTION_TOKEN="secret_xxxxxxxxxxxxxxxxxxxx"
export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxx"
export AIRTABLE_API_KEY="patxxxxxxxxxxxxxxxxxxxx"
export SENDGRID_API_KEY="SG.xxxxxxxxxxxxxxxxxxxx"
export CLOUDFLARE_API_TOKEN="xxxxxxxxxxxxxxxxxxxx"
```

## 🔄 After Setup

1. **Restart MCP Docker containers**:
   ```bash
   docker-compose -f ~/mcp-services/docker-compose.yml restart
   ```

2. **Validate OAuth connections**:
   ```bash
   /Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/validate-oauth.sh
   ```

3. **Test each service**:
   ```bash
   # Test GitHub
   claude "List my GitHub repositories"
   
   # Test Google Calendar
   claude "Show my calendar events for this week"
   
   # Test Gmail
   claude "Check my recent emails"
   ```

## 🔒 Security Notes

1. **Never commit tokens**: The `.gitignore` is configured to exclude environment files
2. **Use secure storage**: Consider using 1Password CLI or similar for token management
3. **Rotate regularly**: Set calendar reminders to rotate tokens
4. **Minimal scopes**: Only request permissions you need
5. **File permissions**: Ensure `chmod 600 ~/.config/claude/environment`

## 📊 Status Tracking

| Service | OAuth Required | Status | Notes |
|---------|---------------|--------|-------|
| Slack | ✅ | ✅ Configured | Already working |
| GitHub | ✅ | ⏳ Pending | Need PAT |
| Google Calendar | ✅ | ⏳ Pending | Need OAuth |
| Gmail | ✅ | ⏳ Pending | Need OAuth |
| Google Drive | ✅ | ⏳ Pending | Need OAuth + refresh |
| QuickBooks | ✅ | ⏳ Pending | Need OAuth |
| Notion | ✅ | ⏳ Pending | Need integration token |
| OpenAI | ✅ | ⏳ Pending | Need API key |
| Airtable | ✅ | ⏳ Pending | Need PAT |
| SendGrid | ✅ | ⏳ Pending | Need API key |
| Cloudflare | ✅ | ⏳ Pending | Need API token |

## 🎯 Next Steps

1. Start with GitHub token (easiest)
2. Set up Google services (most complex)
3. Add remaining API keys
4. Run validation script
5. Test each integration

---

*Ready to enable full MCP ecosystem capabilities!*