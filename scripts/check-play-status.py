import os
import sys
import json
import argparse
import requests

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def get_oauth_service():
    if not os.path.exists(OAUTH_TOKEN_STORE):
        raise FileNotFoundError(f"OAuth token not found at: {OAUTH_TOKEN_STORE}")

    with open(OAUTH_TOKEN_STORE, "r") as f:
        data = json.load(f)

    creds = Credentials(
        token=data.get("access_token"),
        refresh_token=data.get("refresh_token"),
        token_uri="https://oauth2.googleapis.com/token",
        client_id=data.get("client_id"),
        client_secret=data.get("client_secret"),
        scopes=SCOPES,
    )

    if creds.expired or not creds.valid:
        creds.refresh(Request())
        data["access_token"] = creds.token
        with open(OAUTH_TOKEN_STORE, "w") as f:
            json.dump(data, f, indent=2)

    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def check_app_status(package_name: str):
    print("\n============================================================")
    print("   Omniverse Labs - Google Play Live Status Checker         ")
    print("============================================================")
    print(f"📦 Package: {package_name}\n")

    service = get_oauth_service()

    try:
        # 1. Create Edit
        edits = service.edits()
        edit_req = edits.insert(body={}, packageName=package_name)
        edit_res = edit_req.execute()
        edit_id = edit_res["id"]
        print(f"✅ Authenticated & Connected to Google Play Developer API (Session ID: {edit_id})")

        # 2. Query Tracks
        tracks_res = edits.tracks().list(packageName=package_name, editId=edit_id).execute()
        tracks = tracks_res.get("tracks", [])

        print(f"\n📊 Release Tracks Status:")
        for t in tracks:
            track_name = t.get("track", "Unknown").upper()
            releases = t.get("releases", [])
            print(f"\n  🔹 Track: [{track_name}]")
            if not releases:
                print("     - No releases currently in this track.")
            for r in releases:
                status = r.get("status", "N/A").upper()
                name = r.get("name", "N/A")
                version_codes = r.get("versionCodes", [])
                fraction = r.get("userFraction", 1.0) * 100
                print(f"     • Version Name: {name} (Version Code(s): {', '.join(map(str, version_codes))})")
                print(f"       - Status: {status}")
                if status == "INPROGRESS":
                    print(f"       - Rollout: {fraction:.1f}%")
                
                notes = r.get("releaseNotes", [])
                if notes:
                    for n in notes:
                        print(f"       - Release Notes [{n.get('language', 'und')}]: {n.get('text', '').strip()}")

        # 3. Query Store Listings
        try:
            listings_res = edits.listings().list(packageName=package_name, editId=edit_id).execute()
            listings = listings_res.get("listings", [])
            print(f"\n🌐 Store Listings Configured: {len(listings)}")
            for lst in listings:
                print(f"  • [{lst.get('language')}] '{lst.get('title')}'")
                if lst.get('shortDescription'):
                    print(f"    Short: {lst.get('shortDescription')}")
        except Exception:
            pass

        # Clean up
        try:
            edits.delete(packageName=package_name, editId=edit_id).execute()
        except Exception:
            pass

    except HttpError as e:
        error_content = json.loads(e.content.decode("utf-8"))
        error_msg = error_content.get("error", {}).get("message", str(e))
        error_code = e.resp.status
        print(f"\n❌ Google Play API Response ({error_code}): {error_msg}")
        if error_code == 404:
            print("   👉 Note: The package exists or needs an initial draft created in the Console.")
        elif error_code == 403:
            print(f"   👉 Note: Permission check failed: {error_msg}")


def main():
    pkg = sys.argv[1] if len(sys.argv) > 1 else "com.omniverselabs.anotadordejuegos"
    check_app_status(pkg)


if __name__ == "__main__":
    main()
