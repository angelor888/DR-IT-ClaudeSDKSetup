# QuickBooks OAuth Setup via OAuth Playground

Since the redirect URI is causing issues, let's use the QuickBooks OAuth Playground instead.

## Steps:

1. **Go to the OAuth Playground**: https://developer.intuit.com/app/developer/playground

2. **Select your app**: Choose "Claude MCP Integration"

3. **Select scopes**: Check "Accounting"

4. **Get Authorization Code**: Click "Get authorization code"

5. **Authorize**: Log into your QuickBooks account and authorize

6. **Get Tokens**: Click "Get tokens" button

7. **Copy the tokens**:
   - Access Token
   - Refresh Token
   - Note your Company ID (Realm ID) - shown in the response

8. **Add to environment** - I'll help you add these once you have them

## What you need to copy:
- Access Token (starts with `eyJ...`)
- Refresh Token (usually starts with `AB11...`)
- Company ID / Realm ID (a number like `4620816365310615880`)

This method bypasses the redirect URI issue entirely!