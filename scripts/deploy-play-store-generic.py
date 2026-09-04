import os
import sys
import json
import urllib.request
import urllib.parse
import argparse

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

TOKEN_FILE = os.path.expanduser("~/.config/omniverse_labs/play_oauth_token.json")

def get_access_token():
    if not os.path.exists(TOKEN_FILE):
        print(f"[ERROR] OAuth token file not found at {TOKEN_FILE}")
        sys.exit(1)
    
    with open(TOKEN_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    refresh_token = data.get("refresh_token")
    client_id = data.get("client_id")
    client_secret = data.get("client_secret")
    access_token = data.get("access_token")

    if refresh_token and client_id and client_secret:
        token_url = "https://oauth2.googleapis.com/token"
        req_data = urllib.parse.urlencode({
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }).encode("utf-8")
        
        req = urllib.request.Request(token_url, data=req_data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        try:
            with urllib.request.urlopen(req) as resp:
                res_json = json.loads(resp.read().decode("utf-8"))
                access_token = res_json["access_token"]
                data["access_token"] = access_token
                with open(TOKEN_FILE, "w", encoding="utf-8") as out:
                    json.dump(data, out, indent=2)
        except Exception as e:
            print(f"[WARN] Could not refresh access token: {e}. Using cached token.")

    return access_token

def deploy_app(package_name, aab_path, release_notes_es, track="internal"):
    if not os.path.exists(aab_path):
        print(f"[ERROR] AAB bundle not found at {aab_path}")
        sys.exit(1)

    file_size_mb = os.path.getsize(aab_path) / (1024 * 1024)
    print("=" * 60)
    print(f"🚀 Deploying to Google Play: {package_name}")
    print("=" * 60)
    print(f"📦 Package: {package_name}")
    print(f"📂 AAB: {aab_path} ({file_size_mb:.2f} MB)")
    print(f"🎯 Target Track: [{track.upper()}]")

    access_token = get_access_token()
    base_url = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"

    # 1. Create an Edit session
    print("\n1️⃣ Creating edit session on Google Play Console...")
    create_edit_url = f"{base_url}/{package_name}/edits"
    req = urllib.request.Request(create_edit_url, data=b"{}", method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    with urllib.request.urlopen(req) as resp:
        edit_data = json.loads(resp.read().decode("utf-8"))
        edit_id = edit_data["id"]
        print(f"   ✅ Edit session created (Edit ID: {edit_id})")

    # 2. Upload App Bundle
    print(f"\n2️⃣ Uploading App Bundle ({file_size_mb:.2f} MB)...")
    upload_url = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{package_name}/edits/{edit_id}/bundles?uploadType=media"
    
    with open(aab_path, "rb") as aab_file:
        aab_bytes = aab_file.read()

    req = urllib.request.Request(upload_url, data=aab_bytes, method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/octet-stream")
    req.add_header("Content-Length", str(len(aab_bytes)))

    with urllib.request.urlopen(req) as resp:
        bundle_resp = json.loads(resp.read().decode("utf-8"))
        version_code = bundle_resp.get("versionCode")
        sha256 = bundle_resp.get("sha256", "")[:12]
        print(f"   ✅ Bundle uploaded! Version Code: {version_code} (SHA256: {sha256}...)")

    # 3. Assign to Track
    print(f"\n3️⃣ Assigning version {version_code} to track [{track.upper()}]...")
    track_url = f"{base_url}/{package_name}/edits/{edit_id}/tracks/{track}"
    payload = {
        "track": track,
        "releases": [
            {
                "name": f"v{version_code}",
                "versionCodes": [str(version_code)],
                "status": "completed",
                "releaseNotes": [
                    {
                        "language": "es-419",
                        "text": release_notes_es
                    }
                ]
            }
        ]
    }
    req_data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(track_url, data=req_data, method="PUT")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    with urllib.request.urlopen(req) as resp:
        track_resp = json.loads(resp.read().decode("utf-8"))
        print(f"   ✅ Track [{track.upper()}] updated!")

    # 4. Commit Edit
    print(f"\n4️⃣ Committing and publishing changes...")
    commit_url = f"{base_url}/{package_name}/edits/{edit_id}:commit"
    req = urllib.request.Request(commit_url, data=b"", method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    with urllib.request.urlopen(req) as resp:
        commit_resp = json.loads(resp.read().decode("utf-8"))
        print(f"   🎉 SUCCESS! {package_name} v{version_code} published to {track.upper()}!")
        print("=" * 60)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", required=True)
    parser.add_argument("--aab", required=True)
    parser.add_argument("--notes", required=True)
    parser.add_argument("--track", default="internal")
    args = parser.parse_args()

    try:
        deploy_app(args.package, args.aab, args.notes, args.track)
    except urllib.error.HTTPError as err:
        error_body = err.read().decode("utf-8", errors="ignore")
        print(f"\n❌ Google Play API HTTP Error {err.code}: {err.reason}")
        print(f"Details: {error_body}")
        sys.exit(1)
    except Exception as ex:
        print(f"\n❌ Unexpected error: {ex}")
        sys.exit(1)
