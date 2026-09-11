import sys
import json
import importlib

sys.path.append("scripts")
m = importlib.import_module("deploy-omnitrade")
service = m.get_oauth_service()
edits = service.edits()

edit = edits.insert(body={}, packageName=m.PACKAGE_NAME).execute()
edit_id = edit["id"]
print("1️⃣ Edit session created:", edit_id)

print("2️⃣ Assigning version 1 to track [INTERNAL] with status 'completed'...")
notes = [
    {
        "language": "es-419",
        "text": "Versión interna de OmniTrade: Bitácora de trading multi-activo, calculadora de posición 1% R, analíticas avanzadas, curva de equidad y seguridad biométrica."
    },
    {
        "language": "en-US",
        "text": "Internal testing release of OmniTrade: Multi-asset trading journal, 1% R position size calculator, advanced analytics, equity curve, and biometric security."
    }
]

track_body = {
    "track": "internal",
    "releases": [
        {
            "name": "v1 (1.0.0)",
            "versionCodes": ["1"],
            "status": "completed",
            "releaseNotes": notes
        }
    ]
}

res_track = edits.tracks().update(
    packageName=m.PACKAGE_NAME,
    editId=edit_id,
    track="internal",
    body=track_body
).execute()
print("   ✅ Track [INTERNAL] updated!")

print("3️⃣ Validating edit session...")
edits.validate(packageName=m.PACKAGE_NAME, editId=edit_id).execute()
print("   ✅ Validation passed!")

print("4️⃣ Committing edit to Google Play Console...")
res_commit = edits.commit(packageName=m.PACKAGE_NAME, editId=edit_id).execute()
commit_id = res_commit.get("id", edit_id)
print("=" * 60)
print(f"🎉 SUCCESS! OmniTrade v1 (1.0.0) is LIVE on INTERNAL TESTING!")
print(f"Commit ID: {commit_id}")
print("=" * 60)
