import os
import sys
import json
import argparse
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
ICON_PATH = r"c:\Projects\Omniverse Labs\apps\mi_delta\assets\store\icon_512x512.png"
FEATURE_PATH = r"c:\Projects\Omniverse Labs\apps\mi_delta\store_assets\play_store\feature_graphic_1024x500.jpg"

parser = argparse.ArgumentParser(description="Deploy Mi Delta to Google Play testing tracks")
parser.add_argument("--track", default=None, choices=["internal", "alpha", "beta"], help="Single target track")
parser.add_argument("--tracks", default="internal,beta", help="Comma-separated target tracks (e.g. internal,beta)")
args, _ = parser.parse_known_args()

if args.track:
    TARGET_TRACKS = [args.track.strip()]
else:
    TARGET_TRACKS = [t.strip() for t in args.tracks.split(",") if t.strip()]

print("=" * 70)
print(f"🚀 OMNIVERSE LABS - DEPLOY MI DELTA TO [{', '.join([t.upper() for t in TARGET_TRACKS])}] TRACKS")
print("=" * 70)
print(f"📦 Package: {PACKAGE_NAME}")
print(f"📂 AAB File: {AAB_PATH}")
print(f"🎯 Target Tracks: {', '.join(TARGET_TRACKS)}")

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
    # 2. Update Store Listings (es-419 & en-US)
    print("\n2️⃣ Updating Store Listings (Title, Descriptions)...")
    listing_es = {
        "title": "Mi Delta",
        "shortDescription": "Portal Ciudadano y Gestión Municipal Oficial de Altos del Delta.",
        "fullDescription": (
            "Mi Delta es la aplicación oficial para los vecinos de Altos del Delta y la región.\n\n"
            "Concebida para conectar al municipio con la comunidad en tiempo real, Mi Delta te permite "
            "gestionar trámites, reservar turnos y solicitar asistencias directamente desde tu celular.\n\n"
            "🏛️ FUNCIONALIDADES PRINCIPALES:\n\n"
            "• 🪪 CREDENCIAL DIGITAL SOY DELTA: Llevá tu credencial oficial con código QR siempre con vos "
            "para acceder a beneficios exclusivos en comercios locales adheridos.\n\n"
            "• 📅 TURNOS & TRÁMITES ONLINE: Solicitá y reprogramá turnos para licencias de conducir, "
            "atención ciudadana, salud y trámites municipales sin demoras ni filas.\n\n"
            "• ⚡ SEGUIMIENTO DE RECLAMOS: Reportá incidencias de alumbrado, poda, bacheo y residuos con "
            "geolocalización en mapa y fotos adjuntas, con notificaciones de resolución.\n\n"
            "• 🎭 AGENDA CULTURAL & ACTIVIDADES: Enterate de todos los eventos, talleres y propuestas en "
            "tu barrio y confirmá tu asistencia.\n\n"
            "• 🚨 BOTÓN SOS DE EMERGENCIAS: Comunicación directa y geolocalizada con el centro de "
            "monitoreo 103 ante urgencias médicas, bomberos o seguridad.\n\n"
            "• 🌓 MODO OSCURO COMPLETO: Interfaz intuitiva y accesible con soporte nativo de tema oscuro."
        )
    }

    listing_en = {
        "title": "Mi Delta",
        "shortDescription": "Official Citizen Portal and Municipal Services App for Altos del Delta.",
        "fullDescription": (
            "Mi Delta is the official municipal citizen application for Altos del Delta.\n\n"
            "Designed to connect the community and local government seamlessly, Mi Delta provides instant "
            "access to civic paperwork, appointment booking, digital IDs, and emergency services.\n\n"
            "🏛️ KEY FEATURES:\n\n"
            "• 🪪 SOY DELTA DIGITAL CREDENTIAL: Keep your verified resident ID card with secure QR code "
            "to unlock exclusive perks and discounts at local partner stores.\n\n"
            "• 📅 ONLINE APPOINTMENTS & PAPERWORK: Schedule visits for driver's licenses, citizen support, "
            "and health centers quickly and paperlessly.\n\n"
            "• ⚡ CITIZEN INCIDENT REPORTING: Report streetlight outages, road maintenance, and debris "
            "with map geolocation and photo uploads, tracking progress in real time.\n\n"
            "• 🎭 EVENTS & COMMUNITY AGENDA: Stay informed about local workshops, cultural events, and festivals.\n\n"
            "• 🚨 103 EMERGENCY SOS BUTTON: Direct connection with the civic monitoring center for immediate "
            "medical, fire, or police emergency assistance.\n\n"
            "• 🌓 COMPLETE DARK THEME: Accessible, modern design with seamless dark mode support."
        )
    }

    for lang_code, listing_data in [("es-419", listing_es), ("en-US", listing_en)]:
        try:
            edits.listings().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang_code,
                body=listing_data
            ).execute()
            print(f"   ✅ Listing updated for [{lang_code}]")
        except Exception as e:
            print(f"   ⚠️ Listing update warning for [{lang_code}]: {e}")

    # 3. Upload Store Images (Icon 512x512 & Feature Graphic 1024x500)
    print("\n3️⃣ Uploading Graphic Assets (App Icon & Feature Graphic)...")
    for lang in ["es-419", "en-US"]:
        if os.path.exists(ICON_PATH):
            try:
                media = MediaFileUpload(ICON_PATH, mimetype="image/png")
                edits.images().upload(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang,
                    imageType="icon",
                    media_body=media
                ).execute()
                print(f"   ✅ App Icon (512x512) uploaded for [{lang}]")
            except Exception as e:
                print(f"   ⚠️ Icon upload warning for [{lang}]: {e}")

        if os.path.exists(FEATURE_PATH):
            try:
                media = MediaFileUpload(FEATURE_PATH, mimetype="image/jpeg")
                edits.images().upload(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang,
                    imageType="featureGraphic",
                    media_body=media
                ).execute()
                print(f"   ✅ Feature Graphic (1024x500) uploaded for [{lang}]")
            except Exception as e:
                print(f"   ⚠️ Feature Graphic upload warning for [{lang}]: {e}")

    # 4. Upload App Bundle (.aab)
    print(f"\n4️⃣ Uploading App Bundle ({file_size_mb:.2f} MB)...")
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

    # 5. Assign to tracks with status 'completed'
    notes = [
        {
            "language": "es-419",
            "text": "Actualización Mi Delta v1.0.8: Actualización de perfil del vecino en cuenta demo y soporte de barra de navegación continua visible dentro de la pantalla de perfil."
        },
        {
            "language": "en-US",
            "text": "Mi Delta v1.0.8 update: Resident profile demo account update and persistent bottom navigation bar visible within profile screen."
        }
    ]

    for track in TARGET_TRACKS:
        print(f"\n5️⃣ Assigning version {version_code} to track [{track.upper()}]...")
        track_body = {
            "track": track,
            "releases": [
                {
                    "name": f"v{version_code} (1.0.8)",
                    "versionCodes": [str(version_code)],
                    "status": "completed",
                    "releaseNotes": notes
                }
            ]
        }

        res_track = edits.tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=track,
            body=track_body
        ).execute()
        print(f"   ✅ Track [{track.upper()}] updated!")

    # 6. Validate edit session
    print("\n6️⃣ Validating edit session...")
    edits.validate(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print("   ✅ Validation passed!")

    # 7. Commit edit
    print("\n7️⃣ Committing edit to Google Play Console...")
    res_commit = edits.commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    commit_id = res_commit.get("id", edit_id)

    print("\n" + "=" * 70)
    print(f"🎉 SUCCESS! Mi Delta v1.0.5 (Build {version_code}) is LIVE on [{', '.join([t.upper() for t in TARGET_TRACKS])}] tracks!")
    print(f"Commit ID: {commit_id}")
    print("=" * 70)

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
