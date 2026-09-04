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

def deploy_to_playstore(package_name: str, aab_path: str, track: str = "internal,beta", release_name: str = None, notes_es: str = None, notes_en: str = None):
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

        if package_name == "com.omniverselabs.ritmo":
            icon_path = r"c:\Projects\Omniverse Labs\apps\rutina_journal\assets\images\store\app_icon_512x512.png"
            feature_path = r"c:\Projects\Omniverse Labs\apps\rutina_journal\assets\images\store\feature_graphic_1024x500.jpg"

            try:
                print("Updating Store Listing for Ritmo...")
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="es-419",
                    body={
                        "title": "Ritmo: Hábitos & Diario",
                        "shortDescription": "Construye hábitos atómicos, rutinas guiadas y un diario reflexivo 100% offline.",
                        "fullDescription": (
                            "Transforma tu día a día con Ritmo, la aplicación integral diseñada para ayudarte a cultivar hábitos conscientes, "
                            "estructurar tus rutinas diarias y reflexionar con claridad mental, todo en una experiencia 100% privada, elegante y sin distracciones.\n\n"
                            "Ya sea que busques calma y serenidad o energía y alto rendimiento, Ritmo se adapta a tu estilo personal con tres identidades visuales únicas y una interfaz táctil diseñada al detalle.\n\n"
                            "✨ CARACTERÍSTICAS PRINCIPALES:\n\n"
                            "1. 🎯 HÁBITOS ATÓMICOS & GESTOS TÁCTILES\n"
                            "• Desliza para completar: Experimenta una respuesta táctil elástica y satisfactoria en cada logro.\n"
                            "• Hábitos medibles y contadores: Registra vasos de agua, páginas leídas, minutos de meditación o pasos con incrementos rápidos.\n"
                            "• Rachas y consistencia: Visualiza tu progreso con rachas actuales, mejores récords y un mapa de calor de 90 días.\n"
                            "• Categorías temáticas: Organiza tus metas en Salud, Mente, Productividad, Sueño, Finanzas y Crecimiento Personal.\n\n"
                            "2. ⏱️ RUTINAS SECUENCIALES & MODO ENFOQUE\n"
                            "• Flujos paso a paso: Diseña rutinas estructuradas para la mañana, tu jornada laboral o la noche.\n"
                            "• Temporizador de enfoque: Inicia el modo guiado con temporizadores automáticos que te acompañan paso a paso sin saturarte.\n"
                            "• Vinculación inteligente: Al completar un paso de tu rutina, tu hábito correspondiente se marca automáticamente.\n\n"
                            "3. 🌿 MICRO-DIARIO & ESFERAS DE ÁNIMO ATMOSFÉRICAS\n"
                            "• Selector de ánimo luminoso: Registra cómo te sientes mediante orbs atmosféricos con luz difusa y control de energía.\n"
                            "• Tres gratitudes diarias: Cultiva una mentalidad positiva anotando tres cosas buenas de tu jornada.\n"
                            "• Victoria del día & notas: Captura tus mayores aprendizajes e intenciones en segundos.\n"
                            "• Correlación inteligente: Descubre cómo el cumplimiento de tus hábitos impacta directamente en tu estado de ánimo.\n\n"
                            "4. 🎨 3 PRESETS ESTÉTICOS INTERCAMBIABLES\n"
                            "Elige el ambiente que mejor resuene contigo desde Ajustes:\n"
                            "• Calm Sage: Inspirado en la serenidad orgánica con tonos lino, salvia profunda y terracota cálido.\n"
                            "• Neo-Kinetic: Diseñado para el alto impulso y dinamismo con negro carbono, neo-menta y ámbar solar.\n"
                            "• Midnight Bento: Una estética moderna y premium inspirada en tableros bento con pizarra medianoche y acentos joya.\n"
                            "• Soporte completo para Modo Claro y Modo Oscuro en todos los temas.\n\n"
                            "5. 🔔 RECORDATORIOS NATIVOS INTELIGENTES\n"
                            "• Notificaciones locales precisas para recordarte tus hábitos y rutinas en el momento exacto.\n"
                            "• Alerta de protección de racha para no perder tu constancia.\n"
                            "• Reflexión nocturna suave para cerrar el día con gratitud.\n\n"
                            "6. 🛡️ PRIVACIDAD ABSOLUTA & SOBERANÍA DE DATOS\n"
                            "• 100% Offline-First: Tus datos se almacenan únicamente en la memoria interna de tu dispositivo.\n"
                            "• Sin cuentas obligatorias, sin servidores externos y sin recopilación de datos personales.\n"
                            "• Cero anuncios publicitarios y cero SDKs de rastreo o telemetría invasiva.\n"
                            "• Exportación e importación JSON para respaldar tus datos libremente.\n\n"
                            "7. 🌍 MULTI-IDIOMA INTEGRAL\n"
                            "Disponible en 5 idiomas: Español, Inglés, Portugués, Francés e Italiano."
                        ),
                    }
                ).execute()

                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="en-US",
                    body={
                        "title": "Ritmo: Habits & Journal",
                        "shortDescription": "Build atomic habits, guided routines, and a mindful micro-journal 100% offline.",
                        "fullDescription": (
                            "Transform your daily life with Ritmo, the all-in-one companion designed to help you build positive habits, "
                            "flow through guided daily routines, and reflect with mindful clarity—all in a private, distraction-free, and beautifully crafted offline experience.\n\n"
                            "Whether you seek calm mindfulness or high-energy momentum, Ritmo adapts to your lifestyle with three distinct aesthetic identities and fluid tactile interactions.\n\n"
                            "✨ CORE FEATURES:\n\n"
                            "1. 🎯 ATOMIC HABITS & TACTILE SWIPES\n"
                            "• Swipe to Complete: Satisfying elastic gestures with subtle haptic feedback make building consistency rewarding.\n"
                            "• Measurable Counter Habits: Track glasses of water, pages read, meditation minutes, or workout sets with quick steppers.\n"
                            "• Streaks & Momentum: Keep your drive alive with current streaks, personal bests, and a 90-day consistency heatmap.\n"
                            "• Categorized Focus: Organize habits across Health, Mind, Productivity, Sleep, Finance, and Personal Growth.\n\n"
                            "2. ⏱️ SEQUENTIAL ROUTINES & FOCUS RUNNER\n"
                            "• Step-by-Step Flows: Structure Morning, Work, and Evening routines tailored to your lifestyle.\n"
                            "• Focus Mode Runner: Launch hands-free guided sessions with integrated countdown timers for each step.\n"
                            "• Smart Habit Linking: Completing a step in your routine automatically marks the corresponding daily habit.\n\n"
                            "3. 🌿 MINDFUL MICRO-JOURNAL & GLOWING MOOD ORBS\n"
                            "• Atmospheric Mood Selector: Log your emotional state with glowing gradient spheres and interactive energy sliders.\n"
                            "• 3 Daily Gratitudes: Foster positive mindfulness by capturing three meaningful moments each day.\n"
                            "• Daily Win & Reflection: Jot down your key achievement and freeform reflections in under two minutes.\n"
                            "• Mood-Habit Insights: Understand how consistent habit completion uplifts your daily mood and well-being.\n\n"
                            "4. 🎨 3 SWITCHABLE AESTHETIC PRESETS\n"
                            "Customize your visual workspace anytime in Settings:\n"
                            "• Calm Sage: Mindful organic warmth featuring soft linen, deep forest sage, and earthy terracotta.\n"
                            "• Neo-Kinetic: High-momentum contrast crafted with carbon black, electric neo-mint, and solar amber.\n"
                            "• Midnight Bento: Sleek luxury inspired by modular bento layouts with midnight slate and jewel tones.\n"
                            "• Full support for seamless Light and Dark modes across all presets.\n\n"
                            "5. 🔔 NATIVE OFFLINE NOTIFICATIONS\n"
                            "• Exact local reminders schedule your habit cues and routine prompts precisely when you need them.\n"
                            "• Streak-protection notifications ensure your consistency remains intact.\n"
                            "• Gentle evening check-in alerts guide you through daily gratitude and reflection.\n\n"
                            "6. 🛡️ ABSOLUTE PRIVACY & DATA SOVEREIGNTY\n"
                            "• 100% Offline-First: All your habits, journals, streaks, and reflections remain stored strictly on your local device.\n"
                            "• No accounts required, no cloud uploads, and no personal data collection.\n"
                            "• Completely ad-free with zero telemetry, tracking SDKs, or behavioral profiling.\n"
                            "• JSON Backup & Restore: Export your complete data archive anytime for total peace of mind.\n\n"
                            "7. 🌍 5 GLOBAL LANGUAGES\n"
                            "Full native localization with instant switching: English, Spanish, Portuguese, French, and Italian."
                        ),
                    }
                ).execute()
                print("Ritmo Store Listings Updated (es-419 & en-US)!")
            except Exception as e:
                print(f"Ritmo Listing notice: {e}")

            # Sync graphics and listings across all supported locales
            extra_listings = {
                "pt-BR": {
                    "title": "Ritmo: Hábitos & Diário",
                    "shortDescription": "Hábitos atômicos, rotinas guiadas e diário pessoal 100% offline.",
                    "fullDescription": "Transforme seu dia a dia com Ritmo, o app completo para cultivar hábitos saudáveis, rotinas sequenciais e um diário consciente com total privacidade e 100% offline.\n\nDisponível em 5 idiomas, com 3 temas visuais exclusivos."
                },
                "fr-FR": {
                    "title": "Ritmo : Habitudes & Journal",
                    "shortDescription": "Habitudes atomiques, routines guidées et journal personnel 100% hors ligne.",
                    "fullDescription": "Transformez votre quotidien avec Ritmo, l’application complète conçue pour cultiver des habitudes saines, structurer des routines quotidiennes et tenir un journal réflexif 100% privé et hors ligne.\n\nDisponible en 5 langues avec 3 thèmes esthétiques uniques."
                },
                "it-IT": {
                    "title": "Ritmo: Abitudini & Diario",
                    "shortDescription": "Abitudini atomiche, routine guidate e diario personale 100% offline.",
                    "fullDescription": "Trasforma la tua vita quotidiana con Ritmo, l’app completa per coltivare abitudini sane, routine guidate e un diario riflessivo 100% privato e offline.\n\nDisponibile in 5 lingue con 3 stili estetici unici."
                },
                "es-ES": {
                    "title": "Ritmo: Hábitos & Diario",
                    "shortDescription": "Construye hábitos atómicos, rutinas guiadas y un diario reflexivo 100% offline.",
                    "fullDescription": "Transforma tu día a día con Ritmo, la aplicación integral diseñada para ayudarte a cultivar hábitos conscientes, estructurar tus rutinas diarias y reflexionar con claridad mental, todo en una experiencia 100% privada, elegante y sin distracciones.\n\nDisponible en 5 idiomas con 3 presets estéticos únicos."
                },
                "en-GB": {
                    "title": "Ritmo: Habits & Journal",
                    "shortDescription": "Build atomic habits, guided routines, and a mindful micro-journal 100% offline.",
                    "fullDescription": "Transform your daily life with Ritmo, the all-in-one companion designed to help you build positive habits, flow through guided daily routines, and reflect with mindful clarity—all in a private, distraction-free, and beautifully crafted offline experience.\n\nAvailable in 5 global languages with 3 switchable aesthetic presets."
                }
            }

            for extra_lang, extra_body in extra_listings.items():
                try:
                    edits.listings().update(
                        packageName=package_name,
                        editId=edit_id,
                        language=extra_lang,
                        body=extra_body
                    ).execute()
                except Exception as e:
                    print(f"Ritmo Listing notice ({extra_lang}): {e}")

            all_langs = ["es-419", "en-US", "en-GB", "es-ES", "pt-BR", "fr-FR", "it-IT"]
            for lang in all_langs:
                if os.path.exists(icon_path):
                    try:
                        icon_media = MediaFileUpload(icon_path, mimetype="image/png")
                        edits.images().upload(
                            packageName=package_name,
                            editId=edit_id,
                            language=lang,
                            imageType="icon",
                            media_body=icon_media
                        ).execute()
                    except Exception as e:
                        print(f"Ritmo Icon notice ({lang}): {e}")

                if os.path.exists(feature_path):
                    try:
                        feat_media = MediaFileUpload(feature_path, mimetype="image/jpeg")
                        edits.images().upload(
                            packageName=package_name,
                            editId=edit_id,
                            language=lang,
                            imageType="featureGraphic",
                            media_body=feat_media
                        ).execute()
                    except Exception as e:
                        print(f"Ritmo Feature Graphic notice ({lang}): {e}")
            print("Ritmo Icons & Graphics synced across all locales!")

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

        if package_name == "com.omniverselabs.ritmo":
            rel_name = release_name or f"1.0.0 (Build {version_code})"
            rel_notes_es = notes_es or "Lanzamiento inicial de Ritmo: Hábitos atómicos, rutinas guiadas y micro-diario reflexivo con 3 temas estéticos y 5 idiomas."
            rel_notes_en = notes_en or "Initial release of Ritmo: Atomic habit tracking, sequential routines, and mindful micro-journal with 3 aesthetic themes and 5 languages."
        elif package_name == "com.omniverselabs.anotadordejuegos":
            rel_name = release_name or f"1.0.2 (Build {version_code})"
            rel_notes_es = notes_es or "Anotador digital todo en uno para juegos de mesa por Omniverse Labs."
            rel_notes_en = notes_en or "All-in-one tabletop games scorekeeper by Omniverse Labs."
        else:
            rel_name = release_name or f"1.2.9 (Build {version_code})"
            rel_notes_es = notes_es or "Actualizaciones y mejoras continuas de rendimiento y estabilidad."
            rel_notes_en = notes_en or "Continuous performance and stability enhancements."

        # Deploy to specified track(s)
        tracks_to_deploy = [t.strip() for t in track.split(",") if t.strip()]
        for t in tracks_to_deploy:
            print(f"Assigning Version Code {version_code} to track '{t}'...")
            track_body = {
                "track": t,
                "releases": [
                    {
                        "name": rel_name,
                        "versionCodes": [str(version_code)],
                        "status": "completed",
                        "releaseNotes": [
                            {
                                "language": "es-419",
                                "text": rel_notes_es
                            },
                            {
                                "language": "en-US",
                                "text": rel_notes_en
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
    parser.add_argument("--track", default="internal")
    parser.add_argument("--name", default=None)
    parser.add_argument("--notes-es", default=None)
    parser.add_argument("--notes-en", default=None)
    args = parser.parse_args()

    deploy_to_playstore(
        package_name=args.package,
        aab_path=args.aab,
        track=args.track,
        release_name=args.name,
        notes_es=args.notes_es,
        notes_en=args.notes_en,
    )

if __name__ == "__main__":
    main()
