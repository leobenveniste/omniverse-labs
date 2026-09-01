import os
import sys
import json
import argparse

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
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

def deploy_to_playstore(package_name: str, aab_path: str, track: str = "internal"):
    print("============================================================")
    print("   Omniverse Labs - Google Play API Direct Uploader         ")
    print("============================================================")
    print(f"📦 Package: {package_name}")
    print(f"🎯 Target Track: {track}")
    print(f"📁 AAB Path: {aab_path}\n")

    if not os.path.exists(aab_path):
        print(f"❌ Error: AAB file not found at: {aab_path}")
        return False

    service = get_oauth_service()

    try:
        # 1. Create Edit
        edits = service.edits()
        edit_req = edits.insert(body={}, packageName=package_name)
        edit_res = edit_req.execute()
        edit_id = edit_res["id"]
        print(f"✅ Edit Session Created: {edit_id}")

        # 2. Upload Bundle
        print(f"⏳ Uploading App Bundle ({os.path.getsize(aab_path) / (1024*1024):.2f} MB)...")
        media = MediaFileUpload(aab_path, mimetype="application/octet-stream", resumable=True)
        bundle_req = edits.bundles().upload(packageName=package_name, editId=edit_id, media_body=media)
        bundle_res = bundle_req.execute()
        version_code = bundle_res["versionCode"]
        print(f"✅ Bundle Uploaded Successfully! (Version Code: {version_code})")

        # 3. Update Track Release
        print(f"🚀 Assigning Version Code {version_code} to track '{track}'...")
        track_body = {
            "track": track,
            "releases": [
                {
                    "name": "1.0.0 (Release Initial)",
                    "versionCodes": [str(version_code)],
                    "status": "completed",
                    "releaseNotes": [
                        {
                            "language": "es-419",
                            "text": "Lanzamiento inicial de Menú Listo: Recetas y Planificador."
                        },
                        {
                            "language": "en-US",
                            "text": "Initial release of Menú Listo: Recipes & Meal Planner."
                        }
                    ]
                }
            ]
        }
        edits.tracks().update(
            packageName=package_name,
            editId=edit_id,
            track=track,
            body=track_body
        ).execute()

        # 4. Commit Edit
        print(f"💾 Committing and Publishing Edit...")
        commit_res = edits.commit(packageName=package_name, editId=edit_id).execute()
        print(f"🎉 SUCCESS! Released to Google Play [{track.upper()}] track (Commit ID: {commit_res.get('id', edit_id)})")
        return True

    except HttpError as e:
        error_content = json.loads(e.content.decode("utf-8"))
        error_msg = error_content.get("error", {}).get("message", str(e))
        error_code = e.resp.status
        print(f"\n❌ Google Play API Error ({error_code}): {error_msg}")
        if error_code == 404:
            print("👉 El paquete debe ser creado primero en la consola web: https://play.google.com/console")
        return False

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", default="com.omniverselabs.menu_listo")
    parser.add_argument("--aab", default=r"apps/menu_listo/build/app/outputs/bundle/release/app-release.aab")
    parser.add_argument("--track", default="internal")
    args = parser.parse_args()

    deploy_to_playstore(args.package, args.aab, args.track)

if __name__ == "__main__":
    main()
