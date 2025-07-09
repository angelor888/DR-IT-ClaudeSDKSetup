# OAuth Setup Learnings - July 8, 2025

## Key Discoveries

### 1. Jobber OAuth - Localhost Auto-Support
**Discovery**: Jobber automatically supports localhost redirect URIs without needing to add them to the app configuration.

When creating a Jobber app, you get the message:
> 'localhost' is supported automatically and shouldn't be listed

This makes development much easier - you can use `http://localhost:8080/callback` for local OAuth flows without any configuration.

### 2. QuickBooks OAuth - Strict HTTPS Requirements
**Challenge**: QuickBooks requires HTTPS for all redirect URIs except localhost in development mode.
**Solution**: Use the OAuth Playground at https://developer.intuit.com/app/developer/playground for easier token generation.

### 3. Google OAuth - Single App for Multiple Services
**Efficiency**: One Google OAuth app can provide credentials for multiple services:
- Google Calendar
- Gmail  
- Google Drive

All three services can share the same Client ID and Client Secret.

## OAuth Implementation Patterns

### Pattern 1: Local Server OAuth Flow
Best for: GitHub, Google services, Jobber

```python
# Start local server on port 8080
server = HTTPServer(('localhost', 8080), OAuthCallbackHandler)
# Open browser to authorization URL
webbrowser.open(auth_url)
# Capture authorization code from callback
# Exchange for access/refresh tokens
```

### Pattern 2: OAuth Playground
Best for: QuickBooks, complex OAuth providers

1. Use provider's OAuth playground
2. Manually copy tokens
3. Add to environment configuration

### Pattern 3: Simple API Keys
Best for: SendGrid, Airtable, Notion, OpenAI

- No OAuth flow needed
- Just generate API key from provider's dashboard
- Add directly to environment

## Services Configured Today

| Service | Auth Type | Complexity | Special Notes |
|---------|-----------|------------|---------------|
| GitHub | PAT | Easy | Personal Access Token with scopes |
| Google Services | OAuth 2.0 | Medium | Refresh token needed for Drive |
| SendGrid | API Key | Easy | Requires verified sender email |
| QuickBooks | OAuth 2.0 | Hard | Strict redirect URI requirements |
| Airtable | API Key | Easy | Personal Access Token |
| Jobber | OAuth 2.0 | Medium | Auto-supports localhost |

## Token Management Best Practices

1. **Access Token Expiry**: Most OAuth access tokens expire in 60 minutes
2. **Refresh Tokens**: Essential for long-running services
3. **Environment Variables**: Store all tokens in `~/.config/claude/environment`
4. **Security**: Never commit tokens to version control

## Scripts Created

1. **oauth-setup.sh**: Interactive script for adding tokens to environment
2. **google-oauth-flow.py**: Handles Google OAuth with refresh token generation
3. **quickbooks-oauth-flow.py**: Attempted local OAuth (use playground instead)
4. **jobber-oauth-flow.py**: Successfully handles Jobber OAuth with localhost
5. **validate-oauth.sh**: Checks which services are configured

## Troubleshooting Tips

### Google Drive Refresh Token
- Must request offline access
- Use `prompt=consent` to ensure refresh token is returned

### QuickBooks Redirect URI
- Production apps cannot use localhost
- Development/Sandbox can use HTTP localhost
- Consider using OAuth Playground for easier setup

### Jobber API Testing
- GraphQL endpoint might be at `/api/graphql` (not documented clearly)
- Use X-JOBBER-GRAPHQL-VERSION header
- Check their latest API documentation for endpoints

## Next Steps for Remaining Services

1. **Notion**: Generate integration token at https://www.notion.so/my-integrations
2. **OpenAI**: Get API key from https://platform.openai.com/api-keys
3. **Matterport**: Requires developer account and API key
4. **Firebase**: Need service account JSON file
5. **Confluence**: Atlassian API token required

## Environment File Structure

The `~/.config/claude/environment` file now contains:
- Export statements for all tokens
- Comments indicating where to get each token
- Proper formatting for Docker container consumption

---

*These learnings will help streamline future OAuth setups and troubleshooting.*