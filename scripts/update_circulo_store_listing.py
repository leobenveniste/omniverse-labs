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
ES_SHORT = "Red social para conectar con personas afines, formar grupos y planear salidas."
ES_FULL = """Círculo es una aplicación social diseñada para conectar personas afines, facilitar la formación de grupos de amistades y coordinar salidas presenciales a partir de intereses compartidos.

A diferencia de las plataformas tradicionales de interacción individual, Círculo organiza la experiencia en torno a grupos equilibrados de 4 o más integrantes, promoviendo dinámicas sociales colaborativas.

CARACTERÍSTICAS PRINCIPALES:

1. Perfil de intereses y afinidad social
• Crea tu perfil seleccionando tus pasatiempos favoritos: café de especialidad, juegos de mesa, deportes, música en vivo, cine o gastronomía.
• Define tu rol en el grupo (organizador, conector, explorador o tranquilo) para permitir un balance adecuado en cada círculo.
• Especifica tus zonas frecuentes y tus momentos de disponibilidad durante la semana.

2. Descubrimiento y formación de grupos
• Explora perfiles y círculos en proceso de formación en tu zona.
• Conexión grupal: cuando 4 personas con intereses mutuos coinciden, el círculo se consolida y se habilita automáticamente el espacio grupal.

3. Chat y mensajería grupal
• Sala de chat exclusiva para cada grupo conformado.
• Comparte mensajes, propuestas de salidas y coordina detalles del encuentro de manera segura.

4. Planificación de actividades y salidas
• Sistema integrado para crear planes y votar fechas, horarios y lugares de encuentro.
• Registro de asistencia grupal (check-in) para validar los encuentros completados en la vida real.

5. Modo Dupla
• Posibilidad de vincular tu cuenta con un amigo mediante un código de invitación para explorar grupos juntos.

6. Privacidad, seguridad y moderación
• Tu información de contacto directo se mantiene privada hasta que decidas compartirla dentro de tu grupo.
• Herramientas de reporte y bloqueo para mantener una comunidad segura y respetuosa.

SUSCRIPCIÓN OPCIONAL Y FUNCIONES ADICIONALES:
Círculo ofrece la suscripción opcional Círculo Plus con funciones como swipes adicionales, visualización anticipada de postulantes y experiencia sin anuncios publicitarios, además de consumibles opcionales (destacados de perfil).

Requisitos: Aplicación orientada a usuarios mayores de 18 años. Requiere conexión a internet."""

EN_TITLE = "Círculo: Group Friends & Meet"
EN_SHORT = "Social network to meet like-minded people, form groups, and plan real meetups."
EN_FULL = """Círculo is a social networking app designed to help you discover like-minded people, form real-world friendship groups, and organize social outings based on shared hobbies and availability.

Unlike traditional one-on-one networking apps, Círculo focuses on balanced group connections of 4 or more people, making it natural and pressure-free to meet new friends.

KEY FEATURES:

1. Detailed Profiles & Shared Interests
• Build your profile by selecting your favorite activities: specialty coffee, board games, running, live music, dining, tech, and cultural events.
• Choose your group dynamic role (Organizer, Connector, Explorer, or Chill) to ensure balanced groups.
• Set your favorite neighborhoods and weekly availability.

2. Group Matching & Formation
• Discover compatible individuals and forming groups in your local area.
• Group match system: once 4 compatible members connect, the group is unlocked and a private group space is activated.

3. Private Group Messaging
• Dedicated chat rooms for each formed circle.
• Coordinate conversations, share ideas, and plan activities within the group.

4. Meetup & Event Planning
• Built-in tools to propose dates, pick locations, and vote on activities.
• Meetup confirmation and check-in badges for completed in-person gatherings.

5. Duo Mode
• Pair your account with a close friend using an invite code to join forming circles together.

6. Privacy & Safety Standards
• Personal contact details remain protected until you choose to share them with your confirmed circle.
• Comprehensive reporting and blocking tools to maintain a safe, welcoming community.

OPTIONAL MEMBERSHIP & PREMIUM FEATURES:
Círculo offers an optional subscription (Círculo Plus) providing extra discovery swipes, previewing interested members, and an ad-free experience, alongside optional profile boosts.

Requirements: Designed for users aged 18 and older. Requires an active internet connection."""

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
