"""
Omniverse Labs - Google Play OAuth 2.0 Login (No Service Account Key Needed)
Authenticates via standard browser login and saves a reusable token for CLI status checks and deployment.
"""

import os
import json
import http.server
import urllib.parse
import webbrowser
import requests

TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = "https://www.googleapis.com/auth/androidpublisher"

# Google Play Developer default CLI endpoints
AUTH_URI = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URI = "https://oauth2.googleapis.com/token"

print("\n============================================================")
print("   Omniverse Labs - Google Play OAuth 2.0 Authentication     ")
print("============================================================")
print("\nTo connect via OAuth without service account keys:")
print("1. Open Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=omniverselabs")
print("2. Click 'Create Credentials' -> 'OAuth client ID' -> 'Desktop app'")
print("3. Enter your Client ID and Client Secret below:")

client_id = input("\nEnter Client ID: ").strip()
client_secret = input("Enter Client Secret: ").strip()

if not client_id or not client_secret:
    print("\n❌ Client ID and Client Secret are required.")
    exit(1)

# Start local server to capture redirect
auth_code = None

class OAuthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        global auth_code
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        if "code" in params:
            auth_code = params["code"][0]
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>Authentication successful!</h1><p>You can close this window now.</p>")
        else:
            self.send_response(400)
            self.end_headers()

    def log_message(self, format, *args):
        return  # Suppress server logs

server = http.server.HTTPServer(("127.0.0.1", 8989), OAuthHandler)
redirect_uri = "http://127.0.0.1:8989"

params = {
    "client_id": client_id,
    "redirect_uri": redirect_uri,
    "response_type": "code",
    "scope": SCOPES,
    "access_type": "offline",
    "prompt": "consent",
}

auth_url = f"{AUTH_URI}?{urllib.parse.urlencode(params)}"
print(f"\n🌐 Opening browser for Google login:\n{auth_url}\n")
webbrowser.open(auth_url)

print("Waiting for authentication...")
server.handle_request()

if auth_code:
    res = requests.post(
        TOKEN_URI,
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "code": auth_code,
            "grant_type": "authorization_code",
            "redirect_uri": redirect_uri,
        },
    )
    tokens = res.json()
    if "access_token" in tokens:
        os.makedirs(os.path.dirname(TOKEN_STORE), exist_ok=True)
        tokens["client_id"] = client_id
        tokens["client_secret"] = client_secret
        with open(TOKEN_STORE, "w") as f:
            json.dump(tokens, f, indent=2)
        print(f"\n✅ Successfully logged in! Reusable OAuth token saved to: {TOKEN_STORE}")
        print("You can now run status checks and automated deployments without service account keys!")
    else:
        print(f"\n❌ Error exchanging code: {tokens}")
else:
    print("\n❌ Failed to capture auth code.")
