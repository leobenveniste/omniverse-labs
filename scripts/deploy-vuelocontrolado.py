import os
import sys
import json
import socket
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError

socket.setdefaulttimeout(300)
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
PACKAGE_NAME = "com.omniverselabs.vuelocontrolado"
AAB_PATH = r"C:\Projects\Omniverse Labs\apps\vuelo_controlado_staff\build\app\outputs\bundle\release\app-release.aab"
ICON_PATH = r"C:\Projects\Omniverse Labs\apps\vuelo_controlado_staff\assets\images\playstore_icon_512.png"

def get_service():
    if not os.path.exists(OAUTH_TOKEN_STORE):
        print(f"[ERROR] OAuth token file not found at {OAUTH_TOKEN_STORE}")
        sys.exit(1)

    with open(OAUTH_TOKEN_STORE, "r", encoding="utf-8") as f:
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
        print("Refreshing expired OAuth token...")
        creds.refresh(Request())
        data["access_token"] = creds.token
        with open(OAUTH_TOKEN_STORE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

def deploy():
    if not os.path.exists(AAB_PATH):
        print(f"[ERROR] AAB bundle not found at {AAB_PATH}")
        sys.exit(1)

    file_size_mb = os.path.getsize(AAB_PATH) / (1024 * 1024)
    print("=" * 65)
    print(f"🚀 Deploying to Google Play: {PACKAGE_NAME}")
    print("=" * 65)
    print(f"📦 Package: {PACKAGE_NAME}")
    print(f"📂 AAB: {AAB_PATH} ({file_size_mb:.2f} MB)")
    print(f"🎯 Tracks: ['internal', 'alpha']")

    service = get_service()
    edits = service.edits()

    # 1. Create Edit Session
    print("\n1️⃣ Creating edit session on Google Play Console...")
    edit_res = edits.insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit_res["id"]
    print(f"   ✅ Edit session created (Edit ID: {edit_id})")

    # 2. Upload App Bundle (resumable)
    print(f"\n2️⃣ Uploading App Bundle ({file_size_mb:.2f} MB) via resumable chunked stream...")
    bundle_media = MediaFileUpload(AAB_PATH, mimetype="application/octet-stream", resumable=True)
    version_code = None
    try:
        bundle_res = edits.bundles().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            media_body=bundle_media
        ).execute()
        version_code = bundle_res.get("versionCode")
        sha256 = bundle_res.get("sha256", "")[:12]
        print(f"   ✅ App Bundle uploaded! Version Code: {version_code} (SHA256: {sha256}...)")
    except HttpError as up_err:
        if "already been used" in str(up_err).lower():
            print(f"   ℹ️ Bundle version already uploaded in previous release. Querying existing bundles...")
            bundles_list = edits.bundles().list(packageName=PACKAGE_NAME, editId=edit_id).execute().get("bundles", [])
            if bundles_list:
                latest_bundle = max(bundles_list, key=lambda b: b.get("versionCode", 0))
                version_code = latest_bundle.get("versionCode")
                print(f"   ✅ Using existing Bundle Version Code: {version_code}")
            else:
                raise up_err
        else:
            raise up_err

    # 3. Upload Store Listing Icon
    if os.path.exists(ICON_PATH):
        print(f"\n3️⃣ Uploading new app icon to Google Play Store listing...")
        try:
            listings_res = edits.listings().list(packageName=PACKAGE_NAME, editId=edit_id).execute()
            languages = [l["language"] for l in listings_res.get("listings", [])]
            if not languages:
                languages = ["es-419", "en-US"]
            for lang in languages:
                print(f"   Uploading icon for language [{lang}]...")
                try:
                    edits.images().deleteall(packageName=PACKAGE_NAME, editId=edit_id, language=lang, imageType="icon").execute()
                except Exception as del_err:
                    print(f"   Notice clearing previous icon for {lang}: {del_err}")
                icon_media = MediaFileUpload(ICON_PATH, mimetype="image/png")
                img_res = edits.images().upload(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang,
                    imageType="icon",
                    media_body=icon_media
                ).execute()
                img_id = img_res.get("image", {}).get("id", "OK")
                print(f"   ✅ Icon uploaded for [{lang}] (Image ID: {img_id})")
        except Exception as img_err:
            print(f"   ⚠️ Could not upload store listing icon: {img_err}")
    else:
        print(f"⚠️ Icon file not found at {ICON_PATH}")

    # 4. Assign to Tracks
    notes = [
        {
            "language": "es-419",
            "text": "Nueva gestión de parejas de guardia por roles de Organización y Producción, registro de rondas con bottom sheet táctil, y actualización de foto de perfil desde ajustes."
        },
        {
            "language": "en-US",
            "text": "New guard pair management for Organization and Production roles, round logs bottom sheet, and profile picture upload."
        }
    ]

    tracks_to_deploy = ["internal", "alpha"]
    print(f"\n4️⃣ Assigning version {version_code} to tracks: {tracks_to_deploy}...")

    def make_track_body(track_name, status):
        return {
            "track": track_name,
            "releases": [
                {
                    "name": f"1.0.23 (Build {version_code})",
                    "versionCodes": [str(version_code)],
                    "status": status,
                    "releaseNotes": notes
                }
            ]
        }

    for t in tracks_to_deploy:
        status_to_use = "completed"
        try:
            edits.tracks().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                track=t,
                body=make_track_body(t, status_to_use)
            ).execute()
            print(f"   ✅ Track [{t.upper()}] configured with status '{status_to_use}'")
        except HttpError as e:
            print(f"   ⚠️ Track update error on [{t}] with '{status_to_use}', attempting 'draft' status: {e}")
            status_to_use = "draft"
            edits.tracks().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                track=t,
                body=make_track_body(t, status_to_use)
            ).execute()
            print(f"   ✅ Track [{t.upper()}] configured with status 'draft'")

    # 5. Validate Edit
    print("\n5️⃣ Validating edit session...")
    need_changes_not_sent = False
    try:
        edits.validate(packageName=PACKAGE_NAME, editId=edit_id).execute()
        print("   ✅ Edit validation passed!")
    except HttpError as val_err:
        err_json = json.loads(val_err.content.decode("utf-8")) if val_err.content else {}
        err_msg = err_json.get("error", {}).get("message", str(val_err))
        print(f"   ⚠️ Validation notice: {err_msg}")
        if "changesnotsentforreview" in err_msg.lower():
            need_changes_not_sent = True
            print("   ℹ️ Will commit with changesNotSentForReview=True.")

    # 6. Commit Edit
    print("\n6️⃣ Committing and publishing changes to Google Play Console...")
    try:
        if need_changes_not_sent:
            commit_res = edits.commit(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                changesNotSentForReview=True
            ).execute()
        else:
            commit_res = edits.commit(
                packageName=PACKAGE_NAME,
                editId=edit_id
            ).execute()
        print(f"   🎉 SUCCESS! {PACKAGE_NAME} v{version_code} published to {tracks_to_deploy}!")
        print(f"   Commit Result: {commit_res}")
        print("=" * 65)
    except HttpError as c_err:
        err_json_c = json.loads(c_err.content.decode("utf-8")) if c_err.content else {}
        err_str_c = err_json_c.get("error", {}).get("message", str(c_err))
        if "changesnotsentforreview" in err_str_c.lower() and "must not be set" not in err_str_c.lower():
            print("   Retrying commit with changesNotSentForReview=True...")
            commit_res = edits.commit(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                changesNotSentForReview=True
            ).execute()
            print(f"   🎉 SUCCESS! {PACKAGE_NAME} v{version_code} published with changesNotSentForReview=True!")
            print(f"   Commit Result: {commit_res}")
            print("=" * 65)
        else:
            raise c_err

if __name__ == "__main__":
    try:
        deploy()
    except HttpError as err:
        error_body = err.content.decode("utf-8") if err.content else str(err)
        print(f"\n❌ Google Play API HTTP Error: {err.resp.status if hasattr(err, 'resp') else 'Unknown'}")
        print(f"Details: {error_body}")
        sys.exit(1)
    except Exception as ex:
        print(f"\n❌ Unexpected error: {ex}")
        sys.exit(1)
