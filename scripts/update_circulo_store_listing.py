import os
import sys
import json
import socket
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError

socket.setdefaulttimeout(120)
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
PACKAGE_NAME = "com.omniverselabs.circulo"

ES_TITLE = "Círculo: Amigos y Grupos"
ES_SHORT = "Descubrí personas afines, formá grupos de 4 amigos y coordiná salidas."
ES_FULL = """Círculo es una aplicación diseñada para facilitar la amistad y los planes grupales entre personas con intereses compartidos.

La aplicación ayuda a formar grupos de 4 personas en tu ciudad o zona para organizar salidas y actividades presenciales de forma segura y colaborativa.

¿CÓMO FUNCIONA CÍRCULO?

1. Creá tu perfil de intereses:
• Seleccioná tus actividades y pasatiempos favoritos (café, juegos de mesa, deportes, gastronomía, salidas al aire libre, cine, etc.).
• Elegí tu rol preferido en el grupo (organizador, conector, explorador o tranquilo) para lograr un grupo equilibrado.
• Indicá tus zonas frecuentes y tu disponibilidad habitual.

2. Descubrí personas y grupos en formación:
• Explorá perfiles de usuarios de tu zona que compartan tus mismos gustos.
• Cuando 4 personas coinciden mutuamente en intereses, se crea un "Círculo" automáticamente.

3. Chat grupal exclusivo:
• Cada grupo de 4 cuenta con su propia sala de mensajería privada.
• Compartí mensajes y ponete de acuerdo con los demás integrantes sin compartir tu número de teléfono.

4. Creación y votación de salidas:
• Proponé actividades con fecha, hora y punto de encuentro.
• Votá los planes propuestos por otros miembros del grupo.
• Realizá check-in grupal durante el encuentro para registrar las salidas completadas.

5. Modo Dupla:
• Vinculá tu cuenta con un amigo o amiga mediante un código de invitación para explorar y unirse a grupos juntos.

6. Seguridad y privacidad:
• Tus datos de contacto directo permanecen privados dentro de la app.
• Herramientas integradas para reportar y bloquear comportamientos inadecuados.
• Opción de eliminar tu cuenta y tus datos en cualquier momento desde los ajustes.

FUNCIONES OPCIONALES:
Círculo es de descarga y uso gratuito. De forma opcional, ofrece la suscripción "Círculo Plus" y elementos consumibles para obtener funciones adicionales como visualización anticipada de perfiles y destacados.

Requisitos:
• Dirigida exclusivamente a mayores de 18 años.
• Requiere conexión a internet activa."""

EN_TITLE = "Círculo: Group Friends & Meet"
EN_SHORT = "Meet like-minded friends, form balanced 4-person groups, and coordinate meetups."
EN_FULL = """Círculo is an app designed to foster genuine friendships and group activities among people with shared interests.

The app helps form 4-person circles in your city or neighborhood to organize safe, collaborative real-world outings.

HOW CÍRCULO WORKS:

1. Create Your Profile:
• Select your favorite activities and hobbies (specialty coffee, board games, sports, dining, outdoor events, movies, etc.).
• Pick your preferred group role (Organizer, Connector, Explorer, or Chill) for balanced group dynamics.
• Set your primary areas and general availability.

2. Discover People & Forming Circles:
• Explore local user profiles that share your passions.
• When 4 people mutually connect based on shared interests, a "Circle" is automatically established.

3. Dedicated Group Chat:
• Every 4-person circle has its own private group messaging space.
• Coordinate conversations and discuss meetup details without sharing personal phone numbers.

4. Plan and Vote on Outings:
• Suggest activities with specific times, dates, and meeting spots.
• Vote on plans proposed by circle members.
• Complete group check-ins during meetups to track verified outings.

5. Duo Mode:
• Pair your account with a close friend using an invite code to join forming circles together.

6. Safety and Privacy:
• Direct contact details remain protected within the app.
• Integrated reporting and blocking tools to maintain a safe community.
• Clear account and data deletion options available at any time in Settings.

OPTIONAL FEATURES:
Círculo is free to download and use. An optional "Círculo Plus" subscription and consumable items are available for extra features like early profile previews and profile spotlights.

Requirements:
• Intended exclusively for users aged 18 and older.
• Requires an active internet connection."""

def get_service():
    if not os.path.exists(OAUTH_TOKEN_STORE):
        print(f"[ERROR] OAuth token not found at {OAUTH_TOKEN_STORE}")
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

def main():
    service = get_service()
    edits = service.edits()

    print("=================================================================")
    print("📝 Updating Google Play Store Listings for Círculo")
    print("=================================================================")
    edit_res = edits.insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit_res["id"]
    print(f"✅ Session opened (Edit ID: {edit_id})")

    # 1. Update es-419
    print("\n1️⃣ Updating [es-419] Store Listing...")
    es_body = {
        "language": "es-419",
        "title": ES_TITLE,
        "shortDescription": ES_SHORT,
        "fullDescription": ES_FULL
    }
    edits.listings().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        language="es-419",
        body=es_body
    ).execute()
    print("   ✅ [es-419] updated successfully!")

    # 2. Update en-US
    print("\n2️⃣ Updating [en-US] Store Listing...")
    en_body = {
        "language": "en-US",
        "title": EN_TITLE,
        "shortDescription": EN_SHORT,
        "fullDescription": EN_FULL
    }
    edits.listings().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        language="en-US",
        body=en_body
    ).execute()
    print("   ✅ [en-US] updated successfully!")

    # 3. Upload Store Listing Graphics (Icon & Feature Graphic)
    print("\n3️⃣ Uploading App Icon and Feature Graphic...")
    store_assets_dir = os.path.join(r"C:\Projects\Omniverse Labs\apps\circulo\store_assets")
    icon_path = os.path.join(store_assets_dir, "icon_512x512.png")
    fg_path = os.path.join(store_assets_dir, "feature_graphic_1024x500.png")

    for lang in ["es-419", "en-US"]:
        if os.path.exists(icon_path):
            try:
                edits.images().deleteall(
                    packageName=PACKAGE_NAME, editId=edit_id, language=lang, imageType="icon"
                ).execute()
            except Exception:
                pass
            media = MediaFileUpload(icon_path, mimetype="image/png")
            edits.images().upload(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang,
                imageType="icon",
                media_body=media
            ).execute()
            print(f"   ✅ [icon] uploaded for [{lang}]")

        if os.path.exists(fg_path):
            try:
                edits.images().deleteall(
                    packageName=PACKAGE_NAME, editId=edit_id, language=lang, imageType="featureGraphic"
                ).execute()
            except Exception:
                pass
            media = MediaFileUpload(fg_path, mimetype="image/png")
            edits.images().upload(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang,
                imageType="featureGraphic",
                media_body=media
            ).execute()
            print(f"   ✅ [featureGraphic] uploaded for [{lang}]")

    # 4. Validate
    print("\n4️⃣ Validating edit session...")
    need_changes_not_sent = False
    try:
        edits.validate(packageName=PACKAGE_NAME, editId=edit_id).execute()
        print("   ✅ Validation passed!")
    except HttpError as val_err:
        err_json = json.loads(val_err.content.decode("utf-8")) if val_err.content else {}
        err_msg = err_json.get("error", {}).get("message", str(val_err))
        print(f"   ℹ️ Notice: {err_msg}")
        if "changesnotsentforreview" in err_msg.lower():
            need_changes_not_sent = True

    # 5. Commit
    print("\n5️⃣ Committing to Google Play Console...")
    if need_changes_not_sent:
        edits.commit(packageName=PACKAGE_NAME, editId=edit_id, changesNotSentForReview=True).execute()
    else:
        edits.commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print("   🎉 SUCCESS! Both store listings published to Google Play Console.")

if __name__ == "__main__":
    main()
