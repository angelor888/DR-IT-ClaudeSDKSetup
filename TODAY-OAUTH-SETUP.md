# OAuth Setup for Today's New MCP Servers

**Date**: July 8, 2025  
**Services to Configure**: 10 new MCP servers installed today

## 🚀 Quick Setup for Today's Services

Based on our work today, here are the services that need OAuth/API keys:

### 1. Gmail MCP Server
**Status**: Needs OAuth  
**Steps**:
1. Go to https://console.cloud.google.com
2. Enable Gmail API
3. Create OAuth credentials (Desktop app)
4. Add to environment:
   - `GMAIL_CLIENT_ID`
   - `GMAIL_CLIENT_SECRET`

### 2. Google Calendar MCP Server
**Status**: Needs OAuth  
**Steps**:
1. Same Google Cloud project as Gmail
2. Enable Google Calendar API
3. Can use same OAuth credentials as Gmail
4. Add to environment:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`

### 3. Google Drive MCP Server
**Status**: Needs OAuth + Refresh Token  
**Steps**:
1. Same Google Cloud project
2. Enable Google Drive API
3. Use same OAuth credentials
4. Run: `python3 /Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/google-oauth-flow.py`
5. Add to environment:
   - `GOOGLE_DRIVE_CLIENT_ID`
   - `GOOGLE_DRIVE_CLIENT_SECRET`
   - `GOOGLE_DRIVE_REFRESH_TOKEN`

### 4. Airtable MCP Server
**Status**: Needs API Key  
**Steps**:
1. Go to https://airtable.com/create/tokens
2. Create personal access token
3. Select scopes: data.records:read, data.records:write
4. Add to environment:
   - `AIRTABLE_API_KEY`
   - `AIRTABLE_BASE_ID` (from your Airtable URL)

### 5. Firebase MCP Server
**Status**: Needs Service Account  
**Steps**:
1. Go to https://console.firebase.google.com
2. Project Settings → Service Accounts
3. Generate new private key
4. Extract from JSON and add to environment:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_PRIVATE_KEY`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_DATABASE_URL`

### 6. SendGrid MCP Server (Custom Built)
**Status**: Needs API Key  
**Steps**:
1. Go to https://app.sendgrid.com/settings/api_keys
2. Create API Key with full access
3. Add to environment:
   - `SENDGRID_API_KEY`
   - `SENDGRID_FROM_EMAIL` (your verified sender email)

### 7. Jobber MCP Server (Custom Built)
**Status**: Needs API Credentials  
**Steps**:
1. Go to https://developer.getjobber.com
2. Create app in Developer Portal
3. Get API credentials
4. Add to environment:
   - `JOBBER_API_KEY`
   - `JOBBER_API_SECRET`

### 8. Matterport MCP Server (Custom Built)
**Status**: Needs API Key  
**Steps**:
1. Go to https://developers.matterport.com
2. Sign up for developer account
3. Create application
4. Add to environment:
   - `MATTERPORT_API_KEY`

### 9. QuickBooks MCP Server (Custom Built)
**Status**: Needs OAuth  
**Steps**:
1. Go to https://developer.intuit.com
2. Create app (QuickBooks Online)
3. Get OAuth 2.0 credentials
4. Add to environment:
   - `QUICKBOOKS_CONSUMER_KEY`
   - `QUICKBOOKS_CONSUMER_SECRET`
   - `QUICKBOOKS_REALM_ID` (Company ID)
   - Note: Access tokens generated via OAuth flow

### 10. Confluence MCP Server
**Status**: Needs API Token  
**Steps**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create API token
3. Add to environment:
   - `CONFLUENCE_BASE_URL` (https://yoursite.atlassian.net/wiki)
   - `CONFLUENCE_USERNAME` (your email)
   - `CONFLUENCE_API_TOKEN`

## 🏃 Quick Run Script

Run this to set up all services interactively:

```bash
# Run the OAuth setup helper
/Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/oauth-setup.sh

# For Google Drive refresh token
python3 /Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/google-oauth-flow.py

# Validate everything
/Users/angelone/Projects/DR-IT-ClaudeSDKSetup/scripts/validate-oauth.sh
```

## 📊 Today's Services Priority

1. **Google Services** (Gmail, Calendar, Drive) - Most complex, do first
2. **SendGrid** - For email automation
3. **Airtable** - For data management
4. **QuickBooks** - For financial integration
5. **Jobber** - For field service management
6. **Firebase** - For real-time data
7. **Matterport** - For 3D spaces
8. **Confluence** - For documentation

## 🎯 After Setup

1. Restart MCP services:
   ```bash
   docker-compose -f ~/mcp-services/docker-compose.yml restart
   ```

2. Test each service in Claude:
   ```bash
   claude "List my Gmail messages from today"
   claude "Show my Google Calendar events"
   claude "List files in my Google Drive"
   claude "Show Airtable bases"
   ```

---

**Ready to enable the 10 new MCP servers installed today!**