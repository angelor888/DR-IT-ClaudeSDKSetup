#!/usr/bin/env python3
"""
QuickBooks OAuth 2.0 Flow Script
Generates access and refresh tokens for QuickBooks
"""

import os
import json
import base64
import secrets
import webbrowser
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, urlencode
import threading
import time
import urllib.request
import urllib.parse

# Configuration
REDIRECT_URI = "http://localhost:8080/callback"
SCOPES = "com.intuit.quickbooks.accounting"

class OAuthCallbackHandler(BaseHTTPRequestHandler):
    """Handle OAuth callback"""
    
    def do_GET(self):
        """Handle GET request with authorization code"""
        query = urlparse(self.path).query
        params = parse_qs(query)
        
        if 'code' in params:
            self.server.auth_code = params['code'][0]
            self.server.realm_id = params.get('realmId', [None])[0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            success_html = """
            <html>
            <head><title>QuickBooks OAuth Success</title></head>
            <body style="font-family: Arial, sans-serif; padding: 50px; text-align: center;">
                <h1 style="color: #4CAF50;">✓ Authorization Successful!</h1>
                <p>You can close this window and return to the terminal.</p>
                <script>setTimeout(() => window.close(), 3000);</script>
            </body>
            </html>
            """
            self.wfile.write(success_html.encode())
        else:
            self.send_response(400)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            error_html = """
            <html>
            <head><title>QuickBooks OAuth Error</title></head>
            <body style="font-family: Arial, sans-serif; padding: 50px; text-align: center;">
                <h1 style="color: #f44336;">✗ Authorization Failed</h1>
                <p>Please try again.</p>
            </body>
            </html>
            """
            self.wfile.write(error_html.encode())
    
    def log_message(self, format, *args):
        """Suppress log messages"""
        pass

def get_tokens():
    """Interactive flow to get QuickBooks tokens"""
    
    print("🔐 QuickBooks OAuth 2.0 Token Generator")
    print("======================================\n")
    
    # Read environment file
    env_file = Path.home() / ".config" / "claude" / "environment"
    if not env_file.exists():
        print("❌ Environment file not found. Run oauth-setup.sh first!")
        return
    
    # Extract client credentials
    client_id = None
    client_secret = None
    
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('export QUICKBOOKS_CONSUMER_KEY='):
                client_id = line.split('"')[1]
            elif line.startswith('export QUICKBOOKS_CONSUMER_SECRET='):
                client_secret = line.split('"')[1]
    
    if not client_id or not client_secret:
        print("❌ QuickBooks OAuth credentials not found in environment file.")
        print("   Please add QUICKBOOKS_CONSUMER_KEY and QUICKBOOKS_CONSUMER_SECRET")
        return
    
    print(f"✓ Found QuickBooks OAuth credentials")
    print(f"  Client ID: {client_id[:20]}...")
    
    # Check if sandbox or production
    print("\n📋 Which QuickBooks environment are you using?")
    print("1. Sandbox (for testing)")
    print("2. Production (for real data)")
    choice = input("\nEnter choice (1 or 2): ").strip()
    
    is_sandbox = choice == "1"
    base_url = "https://sandbox-quickbooks.api.intuit.com" if is_sandbox else "https://quickbooks.api.intuit.com"
    auth_base = "https://appcenter.intuit.com/connect/oauth2"
    
    # Generate state for security
    state = secrets.token_urlsafe(32)
    
    # Build authorization URL
    auth_params = {
        "client_id": client_id,
        "scope": SCOPES,
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "state": state
    }
    
    auth_url = f"{auth_base}?{urlencode(auth_params)}"
    
    print(f"\n🌐 Opening browser for authorization...")
    print(f"   If browser doesn't open, visit:")
    print(f"   {auth_url}\n")
    
    # Start local server
    server = HTTPServer(('localhost', 8080), OAuthCallbackHandler)
    server.auth_code = None
    server.realm_id = None
    
    # Open browser
    webbrowser.open(auth_url)
    
    # Wait for callback
    print("⏳ Waiting for authorization...")
    print("   Note: Make sure your QuickBooks app has redirect URI set to:")
    print(f"   {REDIRECT_URI}\n")
    
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    
    # Wait for auth code
    timeout = 300  # 5 minutes
    start_time = time.time()
    while server.auth_code is None and (time.time() - start_time) < timeout:
        time.sleep(0.5)
    
    server.shutdown()
    
    if not server.auth_code:
        print("\n❌ Authorization timeout. Please try again.")
        print("   Make sure your redirect URI is set to: " + REDIRECT_URI)
        return
    
    print("\n✓ Authorization code received!")
    if server.realm_id:
        print(f"✓ Company ID (Realm ID): {server.realm_id}")
    
    # Exchange code for tokens
    print("🔄 Exchanging code for tokens...")
    
    # Prepare token request
    token_url = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
    
    # Create Basic Auth header
    auth_string = f"{client_id}:{client_secret}"
    auth_bytes = auth_string.encode('ascii')
    auth_b64 = base64.b64encode(auth_bytes).decode('ascii')
    
    token_data = {
        'grant_type': 'authorization_code',
        'code': server.auth_code,
        'redirect_uri': REDIRECT_URI
    }
    
    data = urllib.parse.urlencode(token_data).encode()
    req = urllib.request.Request(token_url, data=data)
    req.add_header('Authorization', f'Basic {auth_b64}')
    req.add_header('Accept', 'application/json')
    req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    
    try:
        response = urllib.request.urlopen(req)
        tokens = json.loads(response.read().decode())
        
        if 'access_token' in tokens:
            access_token = tokens['access_token']
            refresh_token = tokens.get('refresh_token', '')
            
            print(f"\n✅ Success! Your tokens:")
            print(f"   Access Token: {access_token[:50]}...")
            print(f"   Refresh Token: {refresh_token[:50]}...")
            
            # Update environment file
            print("\n📝 Updating environment file...")
            
            # Read current file
            with open(env_file, 'r') as f:
                lines = f.readlines()
            
            # Update tokens
            updated = False
            for i, line in enumerate(lines):
                if line.startswith('QUICKBOOKS_ACCESS_TOKEN='):
                    lines[i] = f'export QUICKBOOKS_ACCESS_TOKEN="{access_token}"\n'
                    updated = True
                elif line.startswith('QUICKBOOKS_ACCESS_TOKEN_SECRET='):
                    lines[i] = f'export QUICKBOOKS_REFRESH_TOKEN="{refresh_token}"\n'
                    
            # Add tokens if not found
            if not updated:
                # Find QuickBooks section
                for i, line in enumerate(lines):
                    if 'QUICKBOOKS_ACCESS_TOKEN=' in line:
                        lines[i] = f'export QUICKBOOKS_ACCESS_TOKEN="{access_token}"\n'
                    elif 'QUICKBOOKS_ACCESS_TOKEN_SECRET=' in line:
                        lines[i] = f'export QUICKBOOKS_REFRESH_TOKEN="{refresh_token}"\n'
            
            # Update realm ID if we have it
            if server.realm_id:
                for i, line in enumerate(lines):
                    if 'QUICKBOOKS_REALM_ID=' in line:
                        lines[i] = f'export QUICKBOOKS_REALM_ID="{server.realm_id}"\n'
            
            # Update sandbox setting
            for i, line in enumerate(lines):
                if 'QUICKBOOKS_SANDBOX=' in line:
                    lines[i] = f'export QUICKBOOKS_SANDBOX={"true" if is_sandbox else "false"}\n'
            
            # Write back
            with open(env_file, 'w') as f:
                f.writelines(lines)
            
            print("✅ Environment file updated!")
            print(f"\n🎉 QuickBooks OAuth setup complete!")
            print(f"   Environment: {'Sandbox' if is_sandbox else 'Production'}")
            print(f"   Company ID: {server.realm_id or 'Not set - add manually'}")
            
        else:
            print("\n❌ No access token received. Response:")
            print(json.dumps(tokens, indent=2))
            
    except Exception as e:
        print(f"\n❌ Error exchanging code: {e}")
        try:
            error_response = e.read().decode()
            print(f"Error details: {error_response}")
        except:
            pass

if __name__ == "__main__":
    try:
        get_tokens()
    except KeyboardInterrupt:
        print("\n\n👋 OAuth flow cancelled.")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")