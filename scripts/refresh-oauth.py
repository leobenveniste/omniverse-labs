import os
import sys
import json
import http.server
import urllib.parse
import webbrowser
import requests

TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = "https://www.googleapis.com/auth/androidpublisher"
AUTH_URI = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URI = "https://oauth2.googleapis.com/token"

def main():
    if not os.path.exists(TOKEN_STORE):
        print(f"Error: {TOKEN_STORE} not found.")
        sys.exit(1)

    with open(TOKEN_STORE, "r", encoding="utf-8") as f:
        data = json.load(f)

    client_id = data.get("client_id")
    client_secret = data.get("client_secret")

    if not client_id or not client_secret:
        print("Error: Missing client_id or client_secret in token file.")
        sys.exit(1)

    auth_code = None

    class OAuthHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            nonlocal auth_code
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            if "code" in params:
                auth_code = params["code"][0]
                self.send_response(200)
                self.send_header("Content-type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write("<h1>Autenticacion exitosa en Omniverse Labs!</h1><p>Ya podes volver.</p>".encode("utf-8"))
            else:
                self.send_response(400)
                self.end_headers()

        def log_message(self, format, *args):
            return

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
    print("\n============================================================")
    print("   Google Play Console - Re-autenticacion OAuth 2.0         ")
    print("============================================================")
    print(f"\nAbriendo navegador para autorizar cuenta...\n{auth_url}\n")
    webbrowser.open(auth_url)

    print("Esperando autorizacion en el navegador...")
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
            tokens["client_id"] = client_id
            tokens["client_secret"] = client_secret
            with open(TOKEN_STORE, "w", encoding="utf-8") as f:
                json.dump(tokens, f, indent=2)
            print("\nToken actualizado exitosamente en:", TOKEN_STORE)
            return True
        else:
            print("\nError al intercambiar codigo por tokens:", tokens)
            return False
    else:
        print("\nNo se recibio codigo de autorizacion.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
