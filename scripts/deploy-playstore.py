import os
import sys
import json
import socket
import time
import argparse

socket.setdefaulttimeout(300)

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
    print(f"Package: {package_name}")
    print(f"Target Track: {track}")
    print(f"AAB Path: {aab_path}\n")

    if not os.path.exists(aab_path):
        print(f"Error: AAB file not found at: {aab_path}")
        return False

    service = get_oauth_service()

    try:
        edits = service.edits()
        edit_req = edits.insert(body={}, packageName=package_name)
        edit_res = edit_req.execute()
        edit_id = edit_res["id"]
        print(f"Edit Session Created: {edit_id}")

        icon_path = r"C:\Users\leobe\.gemini\antigravity\brain\dc1a3d74-c6b8-4283-b258-23b841335b2e\scratch\app_icon_512x512.png"
        feature_path = r"C:\Users\leobe\.gemini\antigravity\brain\dc1a3d74-c6b8-4283-b258-23b841335b2e\feature_graphic_1024x500.png"

        try:
            print("Updating Store Listing...")
            edits.listings().update(
                packageName=package_name,
                editId=edit_id,
                language="es-419",
                body={
                    "title": "Menú Listo: Recetas y Compras",
                    "shortDescription": "Planificador semanal de comidas, recetario inteligente y lista de compras.",
                    "fullDescription": "Menú Listo es tu asistente culinario integral para organizar tus comidas semanales, guardar tus recetas favoritas, escanear fotos de libros de cocina con OCR y generar tu lista de compras sin duplicados de forma 100% privada y offline.",
                }
            ).execute()

            edits.listings().update(
                packageName=package_name,
                editId=edit_id,
                language="en-US",
                body={
                    "title": "Menú Listo: Recipe & Grocery",
                    "shortDescription": "Weekly meal planner, smart recipe book, and grocery shopping list.",
                    "fullDescription": "Menú Listo is your all-in-one culinary assistant to organize your weekly meals, save recipes, scan cookbook photos with on-device OCR, and generate deduplicated grocery shopping lists.",
                }
            ).execute()
            print("Store Listings Updated!")
        except Exception as e:
            print(f"Listing notice: {e}")

        if os.path.exists(icon_path):
            try:
                print("Uploading App Icon (512x512)...")
                icon_media = MediaFileUpload(icon_path, mimetype="image/png")
                edits.images().upload(
                    packageName=package_name,
                    editId=edit_id,
                    language="es-419",
                    imageType="icon",
                    media_body=icon_media
                ).execute()
                print("App Icon Uploaded!")
            except Exception as e:
                print(f"Icon notice: {e}")

        if os.path.exists(feature_path):
            try:
                print("Uploading Feature Graphic (1024x500)...")
                feat_media = MediaFileUpload(feature_path, mimetype="image/png")
                edits.images().upload(
                    packageName=package_name,
                    editId=edit_id,
                    language="es-419",
                    imageType="featureGraphic",
                    media_body=feat_media
                ).execute()
                print("Feature Graphic Uploaded!")
            except Exception as e:
                print(f"Feature Graphic notice: {e}")

        print(f"Uploading App Bundle ({os.path.getsize(aab_path) / (1024*1024):.2f} MB)...")
        media = MediaFileUpload(aab_path, mimetype="application/octet-stream", chunksize=10*1024*1024, resumable=True)
        bundle_req = edits.bundles().upload(packageName=package_name, editId=edit_id, media_body=media)
        
        response = None
        while response is None:
            status, response = bundle_req.next_chunk(num_retries=5)
            if status:
                print(f"Uploaded {int(status.progress() * 100)}%...")

        version_code = response["versionCode"]
        print(f"Bundle Uploaded Successfully! (Version Code: {version_code})")

        # Deploy to specified track(s)
        tracks_to_deploy = [t.strip() for t in track.split(",") if t.strip()]
        for t in tracks_to_deploy:
            print(f"Assigning Version Code {version_code} to track '{t}'...")
            track_body = {
                "track": t,
                "releases": [
                    {
                        "name": f"1.1.3 (Build {version_code})",
                        "versionCodes": [str(version_code)],
                        "status": "completed",
                        "releaseNotes": [
                            {
                                "language": "es-419",
                                "text": "Guías de bienvenida interactivas al ingresar por primera vez a cada sección (Agenda, Modo Cocina, Lista de Compras, Modo Súper). Recetas precargadas aseguradas, plantillas de menú en la agenda, autocompletado sin distinción de tildes y mejoras de interfaz."
                            },
                            {
                                "language": "en-US",
                                "text": "Interactive contextual welcome guides for first-time visits (Planner, Cook Mode, Shopping List, Supermarket Mode). Guaranteed starter recipes on fresh install, weekly menu templates, accent-insensitive autocomplete, and UI polish."
                            }
                        ]
                    }
                ]
            }
            edits.tracks().update(
                packageName=package_name,
                editId=edit_id,
                track=t,
                body=track_body
            ).execute()
            print(f"Track '{t}' configured successfully!")

        print("Committing and Publishing Edit to Google Play...")
        commit_res = edits.commit(packageName=package_name, editId=edit_id).execute()
        print(f"SUCCESS! Released to Google Play [{', '.join(tracks_to_deploy).upper()}] tracks (Commit ID: {commit_res.get('id', edit_id)})")
        return True

    except HttpError as e:
        error_content = json.loads(e.content.decode("utf-8"))
        error_msg = error_content.get("error", {}).get("message", str(e))
        error_code = e.resp.status
        print(f"Google Play API Error ({error_code}): {error_msg}")
        return False

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", default="com.omniverselabs.menu_listo")
    parser.add_argument("--aab", default=r"apps/menu_listo/build/app/outputs/bundle/release/app-release.aab")
    parser.add_argument("--track", default="internal,alpha")
    args = parser.parse_args()

    deploy_to_playstore(args.package, args.aab, args.track)

if __name__ == "__main__":
    main()
