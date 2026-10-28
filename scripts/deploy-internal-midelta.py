import os
import sys
import json
import importlib
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.append("scripts")
d = importlib.import_module("deploy-omnitrade")
service = d.get_oauth_service()
edits = service.edits()

PACKAGE_NAME = "com.omniverselabs.mi_delta"
AAB_PATH = r"c:\Projects\Omniverse Labs\apps\mi_delta\build\app\outputs\bundle\release\app-release.aab"

print("=" * 65)
print("🚀 OMNIVERSE LABS - DEPLOY MI DELTA TO INTERNAL TESTING TRACK")
print("=" * 65)
print(f"📦 Package: {PACKAGE_NAME}")
print(f"📂 AAB File: {AAB_PATH}")

if not os.path.exists(AAB_PATH):
    print(f"❌ Error: AAB file not found at: {AAB_PATH}")
    sys.exit(1)

file_size_mb = os.path.getsize(AAB_PATH) / (1024 * 1024)
print(f"📊 Bundle Size: {file_size_mb:.2f} MB")

# 1. Create edit session
print("\n1️⃣ Creating edit session on Google Play Console...")
edit = edits.insert(body={}, packageName=PACKAGE_NAME).execute()
edit_id = edit["id"]
print(f"   ✅ Edit session created (Edit ID: {edit_id})")

try:
    # 2. Upload App Bundle (.aab)
    print(f"\n2️⃣ Uploading App Bundle ({file_size_mb:.2f} MB)...")
    media = MediaFileUpload(AAB_PATH, mimetype="application/octet-stream", chunksize=10 * 1024 * 1024, resumable=True)
    bundle_req = edits.bundles().upload(packageName=PACKAGE_NAME, editId=edit_id, media_body=media)

    response = None
    while response is None:
        status, response = bundle_req.next_chunk(num_retries=5)
        if status:
            print(f"   ⏳ Uploaded {int(status.progress() * 100)}%...")

    version_code = response["versionCode"]
    sha256 = response.get("sha256", "")[:12]
    print(f"   ✅ Bundle uploaded successfully! Version Code: {version_code} (SHA256: {sha256}...)")

    # 3. Assign to track [INTERNAL] with status 'completed'
    print(f"\n3️⃣ Assigning version {version_code} to track [INTERNAL]...")
    notes = [
        {
            "language": "es-419",
            "text": "Actualización Mi Delta v1.0.2: Incorporación de acceso a políticas de privacidad, opción in-app de solicitud de eliminación permanente de datos/cuenta, y optimización de diseño adaptable conforme a directivas de Google Play."
        },
        {
            "language": "en-US",
            "text": "Mi Delta v1.0.2 update: In-app privacy policy access, in-app account and data deletion request option, and edge-to-edge layout optimizations adhering to Google Play policies."
        }
    ]

    track_body = {
        "track": "internal",
        "releases": [
            {
                "name": f"v{version_code} (1.0.2)",
                "versionCodes": [str(version_code)],
                "status": "completed",
                "releaseNotes": notes
            }
        ]
    }

    res_track = edits.tracks().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        track="internal",
        body=track_body
    ).execute()
    print("   ✅ Track [INTERNAL] updated!")

    # 4. Validate edit session
    print("\n4️⃣ Validating edit session...")
    edits.validate(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print("   ✅ Validation passed!")

    # 5. Commit edit
    print("\n5️⃣ Committing edit to Google Play Console...")
    res_commit = edits.commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    commit_id = res_commit.get("id", edit_id)

    print("=" * 65)
    print(f"🎉 SUCCESS! Mi Delta v1.0.1 (Build {version_code}) is LIVE on INTERNAL TESTING!")
    print(f"Commit ID: {commit_id}")
    print("=" * 65)

except HttpError as e:
    err_body = e.content.decode("utf-8", errors="ignore")
    print(f"\n❌ Google Play API Error (Status {e.resp.status}): {err_body}")
    try:
        edits.delete(packageName=PACKAGE_NAME, editId=edit_id).execute()
    except Exception:
        pass
    sys.exit(1)
except Exception as e:
    print(f"\n❌ Unexpected error: {e}")
    try:
        edits.delete(packageName=PACKAGE_NAME, editId=edit_id).execute()
    except Exception:
        pass
    sys.exit(1)
