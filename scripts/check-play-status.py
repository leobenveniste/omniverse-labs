"""
Omniverse Labs - Google Play Android Developer API Status Checker
Queries track releases, status, review state, and app details using service account credentials.
"""

import os
import sys
import json
import argparse
from typing import Dict, Any

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    print("\n[!] Missing Google API dependencies. Install via: pip install google-api-python-client google-auth\n")
    sys.exit(1)

SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def get_authenticated_service(key_path: str):
    if not os.path.exists(key_path):
        raise FileNotFoundError(f"Service account key file not found at: {key_path}")
    
    credentials = service_account.Credentials.from_service_account_file(
        key_path, scopes=SCOPES
    )
    return build("androidpublisher", "v3", credentials=credentials, cache_discovery=False)


def check_app_status(service, package_name: str):
    print(f"\n============================================================")
    print(f"   Omniverse Labs - Google Play App Status Checker          ")
    print(f"============================================================")
    print(f"📦 Package Name: {package_name}\n")

    try:
        # 1. Create an Edit session (read-only verification)
        edits = service.edits()
        edit_request = edits.insert(body={}, packageName=package_name)
        edit_response = edit_request.execute()
        edit_id = edit_response["id"]

        print(f"✅ Successfully connected to Google Play Developer API (Edit ID: {edit_id})")

        # 2. Query Tracks (internal, alpha, beta, production)
        tracks_response = edits.tracks().list(packageName=package_name, editId=edit_id).execute()
        tracks = tracks_response.get("tracks", [])

        if not tracks:
            print("\n⚠️ No release tracks found for this package yet.")
        else:
            print("\n📊 Active Release Tracks & Status:")
            for track in tracks:
                track_name = track.get("track", "Unknown")
                releases = track.get("releases", [])
                print(f"\n  🔹 Track: [{track_name.upper()}]")
                if not releases:
                    print("     - No releases currently in this track.")
                for rel in releases:
                    status = rel.get("status", "N/A")
                    name = rel.get("name", "N/A")
                    version_codes = rel.get("versionCodes", [])
                    fraction = rel.get("userFraction", 1.0) * 100
                    print(f"     • Version: {name} (Version Code(s): {', '.join(map(str, version_codes))})")
                    print(f"       - Status: {status.upper()}")
                    if status == "inProgress":
                        print(f"       - Rollout: {fraction:.1f}%")
                    
                    release_notes = rel.get("releaseNotes", [])
                    if release_notes:
                        for rn in release_notes:
                            lang = rn.get("language", "und")
                            text = rn.get("text", "").strip()
                            print(f"       - Release Notes [{lang}]: {text}")

        # 3. Query Store Listings
        try:
            listings_response = edits.listings().list(packageName=package_name, editId=edit_id).execute()
            listings = listings_response.get("listings", [])
            print(f"\n🌐 Store Listings Configured: {len(listings)}")
            for lst in listings:
                lang = lst.get("language", "default")
                title = lst.get("title", "N/A")
                short_desc = lst.get("shortDescription", "N/A")
                print(f"  • [{lang}] Title: '{title}'")
                print(f"    Short Description: '{short_desc}'")
        except Exception as e:
            print(f"  (Store listings query: {e})")

        # Clean up / Delete Edit session
        try:
            edits.delete(packageName=package_name, editId=edit_id).execute()
        except Exception:
            pass

    except HttpError as e:
        error_content = json.loads(e.content.decode("utf-8"))
        error_msg = error_content.get("error", {}).get("message", str(e))
        error_code = e.resp.status
        print(f"\n❌ Google Play API Error ({error_code}): {error_msg}")
        if error_code == 404:
            print("   👉 Cause: The app has not been created in Google Play Console yet, or the package name differs.")
        elif error_code == 403:
            print("   👉 Cause: The service account email needs 'Releases' or 'Admin' permissions invited in Play Console > Users and Permissions.")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Check app status on Google Play Console")
    parser.add_argument(
        "--package",
        default="com.omniverselabs.anotadordejuegos",
        help="Package name (default: com.omniverselabs.anotadordejuegos)",
    )
    parser.add_argument(
        "--key",
        default=os.environ.get("PLAY_CONSOLE_JSON_KEY_PATH", "service_account.json"),
        help="Path to service account JSON key file",
    )
    args = parser.parse_args()

    try:
        service = get_authenticated_service(args.key)
        check_app_status(service, args.package)
    except Exception as ex:
        print(f"\n[ERROR] {ex}")
        sys.exit(1)


if __name__ == "__main__":
    main()
