#!/usr/bin/env python3
"""
Jobber OAuth 2.0 Flow Script
Generates access and refresh tokens for Jobber API
"""

import os
import json
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
JOBBER_AUTH_URL = "https://api.getjobber.com/api/oauth/authorize"
JOBBER_TOKEN_URL = "https://api.getjobber.com/api/oauth/token"

class OAuthCallbackHandler(BaseHTTPRequestHandler):
    """Handle OAuth callback"""
    
    def do_GET(self):
        """Handle GET request with authorization code"""
        query = urlparse(self.path).query
        params = parse_qs(query)
        
        if 'code' in params:
            self.server.auth_code = params['code'][0]
            self.server.state = params.get('state', [None])[0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            success_html = """
            <html>
            <head><title>Jobber OAuth Success</title></head>
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
            
            error = params.get('error', ['Unknown error'])[0]
            error_desc = params.get('error_description', [''])[0]
            
            error_html = f"""
            <html>
            <head><title>Jobber OAuth Error</title></head>
            <body style="font-family: Arial, sans-serif; padding: 50px; text-align: center;">
                <h1 style="color: #f44336;">✗ Authorization Failed</h1>
                <p>Error: {error}</p>
                <p>{error_desc}</p>
                <p>Please try again.</p>
            </body>
            </html>
            """
            self.wfile.write(error_html.encode())
    
    def log_message(self, format, *args):
        """Suppress log messages"""
        pass

def get_tokens():
    """Interactive flow to get Jobber tokens"""
    
    print("🔐 Jobber OAuth 2.0 Token Generator")
    print("===================================\n")
    
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
            if 'JOBBER_CLIENT_ID=' in line and line.strip().startswith('export'):
                client_id = line.split('"')[1]
            elif 'JOBBER_CLIENT_SECRET=' in line and line.strip().startswith('export'):
                client_secret = line.split('"')[1]
    
    if not client_id or not client_secret:
        print("❌ Jobber OAuth credentials not found in environment file.")
        print("   Client ID and Client Secret are required.")
        return
    
    print(f"✓ Found Jobber OAuth credentials")
    print(f"  Client ID: {client_id[:20]}...")
    
    # Check redirect URI preference
    print("\n📋 Which redirect URI is configured in your Jobber app?")
    print("1. http://localhost:8080/callback (for this script)")
    print("2. https://duetright.com/api/jobber/oauth/callback (your production URL)")
    choice = input("\nEnter choice (1 or 2): ").strip()
    
    if choice == "2":
        print("\n⚠️  Using production redirect URI requires handling the callback on your server.")
        print("   You'll need to manually copy the authorization code.")
        redirect_uri = "https://duetright.com/api/jobber/oauth/callback"
        manual_mode = True
    else:
        redirect_uri = REDIRECT_URI
        manual_mode = False
        print(f"\n✓ Using localhost redirect URI (automatically supported by Jobber)")
        print(f"   {redirect_uri}")
    
    # Generate state for security
    state = secrets.token_urlsafe(32)
    
    # Build authorization URL
    auth_params = {
        "response_type": "code",
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "state": state
    }
    
    auth_url = f"{JOBBER_AUTH_URL}?{urlencode(auth_params)}"
    
    print(f"\n🌐 Opening browser for authorization...")
    print(f"   If browser doesn't open, visit:")
    print(f"   {auth_url}\n")
    
    if manual_mode:
        # Manual mode for production redirect
        webbrowser.open(auth_url)
        print("⏳ After authorizing, you'll be redirected to your production URL.")
        print("   Copy the 'code' parameter from the URL.")
        print("   Example: https://duetright.com/api/jobber/oauth/callback?code=XXXXXX&state=YYYY")
        auth_code = input("\nEnter the authorization code: ").strip()
        
        if not auth_code:
            print("❌ No authorization code provided.")
            return
    else:
        # Local server mode
        server = HTTPServer(('localhost', 8080), OAuthCallbackHandler)
        server.auth_code = None
        server.state = None
        
        # Open browser
        webbrowser.open(auth_url)
        
        # Wait for callback
        print("⏳ Waiting for authorization...")
        
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
            return
        
        auth_code = server.auth_code
    
    print("\n✓ Authorization code received!")
    
    # Exchange code for tokens
    print("🔄 Exchanging code for tokens...")
    
    token_data = {
        'client_id': client_id,
        'client_secret': client_secret,
        'grant_type': 'authorization_code',
        'code': auth_code,
        'redirect_uri': redirect_uri
    }
    
    data = urllib.parse.urlencode(token_data).encode()
    req = urllib.request.Request(JOBBER_TOKEN_URL, data=data)
    req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    
    try:
        response = urllib.request.urlopen(req)
        tokens = json.loads(response.read().decode())
        
        if 'access_token' in tokens:
            access_token = tokens['access_token']
            refresh_token = tokens.get('refresh_token', '')
            expires_in = tokens.get('expires_in', 3600)
            
            print(f"\n✅ Success! Your tokens:")
            print(f"   Access Token: {access_token[:50]}...")
            print(f"   Refresh Token: {refresh_token[:50]}...")
            print(f"   Expires in: {expires_in} seconds")
            
            # Update environment file
            print("\n📝 Updating environment file...")
            
            # Read current file
            with open(env_file, 'r') as f:
                lines = f.readlines()
            
            # Update tokens
            for i, line in enumerate(lines):
                if 'JOBBER_API_KEY=' in line:
                    lines[i] = f'export JOBBER_ACCESS_TOKEN="{access_token}"\n'
                elif 'JOBBER_API_SECRET=' in line:
                    lines[i] = f'export JOBBER_REFRESH_TOKEN="{refresh_token}"\n'
            
            # Write back
            with open(env_file, 'w') as f:
                f.writelines(lines)
            
            print("✅ Environment file updated!")
            
            # Test the API
            print("\n🧪 Testing Jobber API connection...")
            test_url = "https://api.getjobber.com/api/graphql"
            test_query = '{"query": "{ currentUser { id email name } }"}'
            
            test_req = urllib.request.Request(test_url, test_query.encode())
            test_req.add_header('Authorization', f'Bearer {access_token}')
            test_req.add_header('Content-Type', 'application/json')
            test_req.add_header('X-JOBBER-GRAPHQL-VERSION', '2024-05-01')
            
            try:
                test_response = urllib.request.urlopen(test_req)
                test_data = json.loads(test_response.read().decode())
                
                if 'data' in test_data and 'currentUser' in test_data['data']:
                    user = test_data['data']['currentUser']
                    print(f"✅ API connection successful!")
                    print(f"   Logged in as: {user.get('name', 'Unknown')} ({user.get('email', 'Unknown')})")
                else:
                    print("⚠️  API connected but couldn't get user info")
                    
            except Exception as e:
                print(f"⚠️  API test failed: {e}")
            
            print(f"\n🎉 Jobber OAuth setup complete!")
            print(f"   Access token expires in {expires_in//60} minutes")
            print(f"   The MCP server will use the refresh token to get new access tokens automatically")
            
        else:
            print("\n❌ No access token received. Response:")
            print(json.dumps(tokens, indent=2))
            
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"\n❌ Error exchanging code: {e.code} {e.reason}")
        print(f"Error details: {error_body}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    try:
        get_tokens()
    except KeyboardInterrupt:
        print("\n\n👋 OAuth flow cancelled.")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")