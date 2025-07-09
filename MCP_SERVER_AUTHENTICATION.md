# MCP Server Authentication Setup Guide

This guide provides authentication setup instructions for all installed MCP servers.

## Overview

All 10 requested MCP servers have been successfully installed and configured:

1. ✅ **Slack** - Already configured
2. ✅ **Gmail** - Custom implementation using Google Workspace APIs  
3. ✅ **Google Drive** - Custom implementation using Google Drive API
4. ✅ **Google Calendar** - Already configured
5. ✅ **Jobber** - Already configured
6. ✅ **Airtable** - Community implementation
7. ✅ **QuickBooks** - Custom implementation using Intuit APIs
8. ✅ **Firebase** - Custom implementation using Firebase Admin SDK
9. ✅ **Matterport** - Custom implementation using Matterport API
10. ✅ **SendGrid** - Custom implementation using Twilio SendGrid API

## Authentication Instructions

### 1. Slack (Already Configured)
Set these environment variables:
```bash
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_TEAM_ID="your-team-id"
export SLACK_CHANNEL_IDS="channel1,channel2"
```

### 2. Gmail (Custom Implementation)
Requires Google OAuth2 credentials:
```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export GOOGLE_REFRESH_TOKEN="your-refresh-token"
```

**Setup Steps:**
1. Create project in Google Cloud Console
2. Enable Gmail API
3. Create OAuth2 credentials
4. Generate refresh token using OAuth2 flow

### 3. Google Drive (Official Package)
Uses Google OAuth2 credentials:
```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"  
export GOOGLE_REFRESH_TOKEN="your-refresh-token"
```

**Setup Steps:**
1. Enable Google Drive API in Google Cloud Console
2. Create OAuth2 credentials or use same as Gmail
3. Run `npx @modelcontextprotocol/server-gdrive auth` to authenticate

### 4. Google Calendar (Already Configured)
Uses same Google OAuth2 credentials:
```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export GOOGLE_REFRESH_TOKEN="your-refresh-token"
```

### 5. Jobber (Already Configured)
```bash
export JOBBER_ACCESS_TOKEN="your-jobber-access-token"
```

### 6. Airtable (Official Package)
```bash
export AIRTABLE_API_KEY="your-airtable-api-key"
```

**Setup Steps:**
1. Go to https://airtable.com/account
2. Generate personal access token
3. Set appropriate scopes for your bases
4. Package automatically uses environment variable

### 7. QuickBooks (Custom Implementation)
```bash
export QB_ACCESS_TOKEN="your-quickbooks-access-token"
export QB_COMPANY_ID="your-company-id"
export QB_SANDBOX="true"  # Set to "false" for production
```

**Setup Steps:**
1. Create app in Intuit Developer Dashboard
2. Configure OAuth2 and get access token
3. Get company ID from QuickBooks company settings

### 8. Firebase (Official Package)
```bash
export FIREBASE_PROJECT_ID="your-project-id"
export FIREBASE_SERVICE_ACCOUNT_KEY="path-to-service-account-json"
```

**Setup Steps:**
1. Create Firebase project
2. Generate service account key in Firebase Console
3. Download JSON credentials file
4. Set FIREBASE_SERVICE_ACCOUNT_KEY to the file path

### 9. Matterport (Custom Implementation)
```bash
export MATTERPORT_ACCESS_TOKEN="your-matterport-access-token"
```

**Setup Steps:**
1. Create Matterport developer account
2. Generate API access token
3. Set appropriate permissions for model access

### 10. SendGrid (Custom Implementation)
```bash
export SENDGRID_API_KEY="your-sendgrid-api-key"
export SENDGRID_FROM_EMAIL="your-verified-sender-email"
```

**Setup Steps:**
1. Create SendGrid account
2. Generate API key with appropriate permissions
3. Verify sender email address

## Environment Variable Setup

### Option 1: Using .env file (Recommended)
Create `/Users/angelone/DR-SETUP-DEV-ClaudeSDKEnvironment-v1.0-20250708/.env`:

```bash
# Google Services (Gmail, Drive, Calendar)
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"
GOOGLE_REFRESH_TOKEN="your-refresh-token"

# Slack
SLACK_BOT_TOKEN="xoxb-your-bot-token"
SLACK_TEAM_ID="your-team-id"
SLACK_CHANNEL_IDS="channel1,channel2"

# Jobber
JOBBER_ACCESS_TOKEN="your-jobber-access-token"

# Airtable
AIRTABLE_API_KEY="your-airtable-api-key"

# QuickBooks
QB_ACCESS_TOKEN="your-quickbooks-access-token"
QB_COMPANY_ID="your-company-id"
QB_SANDBOX="true"

# Firebase
FIREBASE_PROJECT_ID="your-project-id"
FIREBASE_SERVICE_ACCOUNT_KEY="path-to-service-account-json"

# Matterport
MATTERPORT_ACCESS_TOKEN="your-matterport-access-token"

# SendGrid
SENDGRID_API_KEY="your-sendgrid-api-key"
SENDGRID_FROM_EMAIL="your-verified-sender-email"
```

### Option 2: Shell exports
Add to your `~/.zshrc`:

```bash
# MCP Server Environment Variables
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export GOOGLE_REFRESH_TOKEN="your-refresh-token"
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_TEAM_ID="your-team-id"
export SLACK_CHANNEL_IDS="channel1,channel2"
export JOBBER_ACCESS_TOKEN="your-jobber-access-token"
export AIRTABLE_API_KEY="your-airtable-api-key"
export QB_ACCESS_TOKEN="your-quickbooks-access-token"
export QB_COMPANY_ID="your-company-id"
export QB_SANDBOX="true"
export FIREBASE_PROJECT_ID="your-project-id"
export FIREBASE_SERVICE_ACCOUNT_KEY="path-to-service-account-json"
export MATTERPORT_ACCESS_TOKEN="your-matterport-access-token"
export SENDGRID_API_KEY="your-sendgrid-api-key"
export SENDGRID_FROM_EMAIL="your-verified-sender-email"
```

## Testing Connections

After setting up authentication, restart Claude Code and test each server:

1. **Test Gmail**: Ask Claude to "List my recent emails"
2. **Test Google Drive**: Ask Claude to "List files in my Google Drive"
3. **Test QuickBooks**: Ask Claude to "Get company information from QuickBooks"
4. **Test Firebase**: Ask Claude to "Read data from Firebase"
5. **Test Matterport**: Ask Claude to "List my Matterport models"
6. **Test SendGrid**: Ask Claude to "Send a test email via SendGrid"
7. **Test Airtable**: Ask Claude to "List records from Airtable"

## Server Locations

All MCP servers are installed in:
```
/Users/angelone/DR-SETUP-DEV-ClaudeSDKEnvironment-v1.0-20250708/
├── airtable-mcp-server/     # Community Airtable server
├── mcp-firebase/            # Custom Firebase server
├── mcp-google-drive/        # Custom Google Drive server
├── mcp-gmail/              # Custom Gmail server
├── mcp-quickbooks/         # Custom QuickBooks server
├── mcp-matterport/         # Custom Matterport server
└── mcp-sendgrid/           # Custom SendGrid server
```

## Security Notes

- Never commit actual credentials to version control
- Use environment variables or secure credential storage
- Rotate API keys regularly
- Use sandbox/development environments when available
- Review and limit API permissions to minimum required scope

## Next Steps

1. Set up authentication credentials for each service
2. Test each MCP server integration
3. Configure any additional service-specific settings
4. Create verification scripts for ongoing health checks