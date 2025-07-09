#!/usr/bin/env python3
"""
Google OAuth Flow Script
Generates refresh token for Google services
"""

import os
import json
import webbrowser
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

# Configuration
REDIRECT_URI = "http://localhost:8080"
SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/drive.readonly"
]

class OAuthCallbackHandler(BaseHTTPRequestHandler):
    """Handle OAuth callback"""
    
    def do_GET(self):
        """Handle GET request with authorization code"""
        query = urlparse(self.path).query
        params = parse_qs(query)
        
        if 'code' in params:
            self.server.auth_code = params['code'][0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            success_html = """
            <html>
            <head><title>OAuth Success</title></head>
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
            <head><title>OAuth Error</title></head>
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

def get_refresh_token():
    """Interactive flow to get Google refresh token"""
    
    print("🔐 Google OAuth Refresh Token Generator")
    print("=====================================\n")
    
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
            if line.startswith('export GOOGLE_CLIENT_ID='):
                client_id = line.split('"')[1]
            elif line.startswith('export GOOGLE_CLIENT_SECRET='):
                client_secret = line.split('"')[1]
    
    if not client_id or not client_secret:
        print("❌ Google OAuth credentials not found in environment file.")
        print("   Please run: ./scripts/oauth-setup.sh")
        return
    
    print(f"✓ Found Google OAuth credentials")
    print(f"  Client ID: {client_id[:20]}...")
    
    # Build authorization URL
    auth_url = (
        "https://accounts.google.com/o/oauth2/v2/auth?"
        f"client_id={client_id}&"
        f"redirect_uri={REDIRECT_URI}&"
        "response_type=code&"
        f"scope={' '.join(SCOPES)}&"
        "access_type=offline&"
        "prompt=consent"
    )
    
    print(f"\n📋 Requesting scopes:")
    for scope in SCOPES:
        print(f"   • {scope.split('/')[-1]}")
    
    print(f"\n🌐 Opening browser for authorization...")
    print(f"   If browser doesn't open, visit:")
    print(f"   {auth_url}\n")
    
    # Start local server
    server = HTTPServer(('localhost', 8080), OAuthCallbackHandler)
    server.auth_code = None
    
    # Open browser
    webbrowser.open(auth_url)
    
    # Wait for callback
    print("⏳ Waiting for authorization...")
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    
    # Wait for auth code
    timeout = 120  # 2 minutes
    start_time = time.time()
    while server.auth_code is None and (time.time() - start_time) < timeout:
        time.sleep(0.5)
    
    server.shutdown()
    
    if not server.auth_code:
        print("\n❌ Authorization timeout. Please try again.")
        return
    
    print("\n✓ Authorization code received!")
    
    # Exchange code for tokens
    print("🔄 Exchanging code for refresh token...")
    
    import urllib.request
    import urllib.parse
    
    token_url = "https://oauth2.googleapis.com/token"
    token_data = {
        'code': server.auth_code,
        'client_id': client_id,
        'client_secret': client_secret,
        'redirect_uri': REDIRECT_URI,
        'grant_type': 'authorization_code'
    }
    
    data = urllib.parse.urlencode(token_data).encode()
    req = urllib.request.Request(token_url, data=data)
    
    try:
        response = urllib.request.urlopen(req)
        tokens = json.loads(response.read().decode())
        
        if 'refresh_token' in tokens:
            refresh_token = tokens['refresh_token']
            print(f"\n✅ Success! Your refresh token:")
            print(f"   {refresh_token}")
            
            # Update environment file
            print("\n📝 Update your environment file with:")
            print(f'   export GOOGLE_DRIVE_REFRESH_TOKEN="{refresh_token}"')
            
            print("\n💡 Would you like to automatically add this to your environment file? (y/N): ", end='')
            choice = input().strip().lower()
            
            if choice == 'y':
                # Add to environment file
                with open(env_file, 'a') as f:
                    f.write(f'\nexport GOOGLE_DRIVE_REFRESH_TOKEN="{refresh_token}"\n')
                print("✅ Added to environment file!")
            
        else:
            print("\n⚠️  No refresh token received. This might happen if you've already authorized this app.")
            print("   Try revoking access at: https://myaccount.google.com/permissions")
            print("   Then run this script again.")
            
    except Exception as e:
        print(f"\n❌ Error exchanging code: {e}")

if __name__ == "__main__":
    try:
        get_refresh_token()
    except KeyboardInterrupt:
        print("\n\n👋 OAuth flow cancelled.")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")