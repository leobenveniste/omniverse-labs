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
    except Exception:
        pass

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
PACKAGE_NAME = "com.omniverselabs.vuelocontrolado"
STORE_DIR = r"c:\Projects\Omniverse Labs\apps\vuelo_controlado_staff\store_assets\play_store"

def get_service():
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
        creds.refresh(Request())
        data["access_token"] = creds.token
        with open(OAUTH_TOKEN_STORE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

def main():
    service = get_service()
    edits = service.edits()

    print("Creating new edit session on Google Play Console...")
    edit_res = edits.insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit_res["id"]
    print(f"Edit session created: {edit_id}")

    # Texts
    title_es = "Vuelo Controlado Staff"
    short_es = "Gestión de staff, guardias de eventos y reducción de daños offline."
    full_es = (
        "Aplicación móvil oficial de Fundación Vuelo Controlado para la coordinación operativa "
        "del equipo de staff en eventos, festivales y fiestas.\n\n"
        "Diseñada con arquitectura offline-first para funcionar de manera fluida y 100% autónoma en predios sin conectividad a internet ni cobertura celular:\n\n"
        "• Gestión y Guardias de Eventos: Visualización de eventos programados, horarios de apertura de puertas, inicio y cierre, y confirmación de asistencia del staff a guardias.\n"
        "• Fichas de Casos de Reducción de Daños: Registro ágil durante el transcurso de eventos sobre atenciones, contención emocional, hidratación, primeros auxilios, síntomas y observaciones del equipo de cuidado.\n"
        "• Sincronización Automática: Consolidación y exportación de fichas de casos a Google Drive y planillas de cálculo (Sheets/Excel) en un solo toque al recuperar conexión.\n"
        "• Control de Roles y Accesos: Módulos específicos para Miembros, Organización, RRHH, Producción y Comercial.\n\n"
        "Fundación Vuelo Controlado — Promoviendo el cuidado, la prevención y la reducción de riesgos y daños en espacios de entretenimiento y nocturnidad."
    )

    title_en = "Vuelo Controlado Staff"
    short_en = "Event staff management, shift tracking, and harm reduction case logs."
    full_en = (
        "Official mobile application for Fundación Vuelo Controlado's operational staff and volunteers at nightlife events and festivals.\n\n"
        "Built offline-first to perform reliably in venues without mobile network or Wi-Fi coverage:\n\n"
        "• Event Shift Management: View schedules, door opening times, start and closing hours, and sign up for shifts.\n"
        "• Live Harm Reduction Case Logs: Rapid on-site reporting of care interventions, hydration, active listening, first aid, and clinical observations.\n"
        "• Google Drive Sync: Seamlessly compile and upload consolidated case spreadsheets to Google Drive once connectivity is restored.\n"
        "• Role-Based Access: Dedicated permissions for Members, Organization, HR, Production, and Commercial teams."
    )

    languages = [
        ("es-419", title_es, short_es, full_es),
        ("en-US", title_en, short_en, full_en),
    ]

    for lang, title, short, full in languages:
        print(f"Updating store listing for {lang}...")
        try:
            edits.listings().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang,
                body={
                    "title": title,
                    "shortDescription": short,
                    "fullDescription": full,
                }
            ).execute()
            print(f"✓ Listing texts updated for {lang}")
        except Exception as e:
            print(f"! Error updating texts for {lang}: {e}")

        # Upload Icon
        icon_path = os.path.join(STORE_DIR, "icon_512x512.png")
        if os.path.exists(icon_path):
            try:
                print(f"Uploading App Icon for {lang}...")
                media = MediaFileUpload(icon_path, mimetype="image/png")
                edits.images().upload(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang,
                    imageType="icon",
                    media_body=media,
                ).execute()
                print(f"✓ App Icon uploaded for {lang}")
            except Exception as e:
                print(f"! Error uploading icon for {lang}: {e}")

        # Upload Feature Graphic
        fg_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.png")
        if os.path.exists(fg_path):
            try:
                print(f"Uploading Feature Graphic for {lang}...")
                media = MediaFileUpload(fg_path, mimetype="image/png")
                edits.images().upload(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang,
                    imageType="featureGraphic",
                    media_body=media,
                ).execute()
                print(f"✓ Feature Graphic uploaded for {lang}")
            except Exception as e:
                print(f"! Error uploading feature graphic for {lang}: {e}")

        # Clear and Upload Phone Screenshots
        try:
            edits.images().deleteall(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang,
                imageType="phoneScreenshots"
            ).execute()
        except Exception:
            pass

        screenshots = [
            "screenshot_01_login.png",
            "screenshot_02_eventos.png",
            "screenshot_03_ficha_caso.png",
            "screenshot_04_drive_sync.png",
        ]

        for s_file in screenshots:
            s_path = os.path.join(STORE_DIR, s_file)
            if os.path.exists(s_path):
                try:
                    media = MediaFileUpload(s_path, mimetype="image/png")
                    edits.images().upload(
                        packageName=PACKAGE_NAME,
                        editId=edit_id,
                        language=lang,
                        imageType="phoneScreenshots",
                        media_body=media,
                    ).execute()
                    print(f"✓ Screenshot {s_file} uploaded for {lang}")
                except Exception as e:
                    print(f"! Error uploading screenshot {s_file} for {lang}: {e}")

    # Commit edit session
    print("Committing and Publishing store listing changes to Google Play...")
    try:
        commit_res = edits.commit(packageName=PACKAGE_NAME, editId=edit_id, changesNotSentForReview=True).execute()
        print(f"SUCCESS! Store listing committed with ID: {commit_res.get('id', edit_id)}")
    except HttpError as err:
        error_content = json.loads(err.content.decode("utf-8")) if err.content else {}
        err_msg = error_content.get("error", {}).get("message", str(err))
        print(f"Error during commit: {err_msg}")
        # Try regular commit without flag if draft allows
        try:
            commit_res = edits.commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
            print(f"SUCCESS! Store listing committed: {commit_res.get('id', edit_id)}")
        except Exception as e2:
            print(f"Fatal commit error: {e2}")

if __name__ == "__main__":
    main()
