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

        if package_name == "com.omniverselabs.empacarte":
            icon_path = r"c:\Projects\Omniverse Labs\apps\empacarte\assets\images\store\app_icon_512x512.png"
            feature_path = r"c:\Projects\Omniverse Labs\apps\empacarte\assets\images\store\feature_graphic_1024x500.jpg"

            try:
                print("Updating Store Listing for EmpacArte...")
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="es-419",
                    body={
                        "title": "EmpacArte: Valija & Pasaporte",
                        "shortDescription": "El arte de empacar con listas inteligentes, pasaporte e itinerario de viaje.",
                        "fullDescription": (
                            "EmpacArte es tu compañero de viaje definitivo, diseñado para que empacar y organizar cada aventura sea un placer ordenado, elegante y sin estrés.\n\n"
                            "Con una estética artesanal en cuero burdeos y detalles en oro, EmpacArte combina un potente organizador de equipaje con recomendaciones según clima y días, pasaporte táctil personalizable, sellos consulares coleccionables, pases de abordar y herramientas esenciales para aeropuertos y mochileros, 100% offline y privado.\n\n"
                            "✈️ CARACTERÍSTICAS PRINCIPALES:\n\n"
                            "1. 🧳 ESTUDIO DE PACKING INTELIGENTE\n"
                            "• Listas recomendadas automáticas según los días de viaje y el clima del destino (cálido, templado, frío, lluvia, nieve).\n"
                            "• División de equipaje por bultos: Valija / Mochila Principal, Equipaje de Mano (Carry-On) y Artículo Personal.\n"
                            "• Artículos esenciales permanentes: Marca 'Siempre llevo esto' para que nunca falten en tus futuros viajes.\n"
                            "• Progreso visual y feedback háptico al marcar cada prenda o accesorio empacado.\n\n"
                            "2. 🛂 PASAPORTE TÁCTIL & SELLOS CONSULARES\n"
                            "• Tu propio pasaporte digital con diseño biométrico y zona MRZ estilizada.\n"
                            "• Colecciona sellos de aduana y visados exclusivos de destinos icónicos de todo el mundo.\n\n"
                            "3. 🎫 PASES DE ABORDAR E ITINERARIOS MULTI-DESTINO\n"
                            "• Crea y consulta tus tarjetas de embarque con código de barras simulado, terminal, puerta, asiento y hora límite de abordaje.\n"
                            "• Soporte completo para viajes con múltiples tramos y escalas.\n\n"
                            "4. 🛠️ HERRAMIENTAS ESENCIALES PARA VIAJEROS\n"
                            "• Convertidor de divisas offline con calculadora rápida.\n"
                            "• Lista de verificación para salida de aeropuerto y aduanas.\n"
                            "• Normativas de líquidos (100ml) y baterías en equipaje de mano.\n\n"
                            "5. 🌍 6 IDIOMAS Y 100% PRIVADO\n"
                            "• Disponible en Español, Inglés, Portugués, Francés, Alemán e Italiano.\n"
                            "• Sin registros, sin rastreadores ni anuncios: tus datos quedan exclusivamente en tu teléfono."
                        ),
                    }
                ).execute()

                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="en-US",
                    body={
                        "title": "EmpacArte: Packing & Passport",
                        "shortDescription": "The art of packing, smart luggage checklists, itinerary and travel passport.",
                        "fullDescription": (
                            "EmpacArte is your ultimate travel companion, crafted to make packing and organizing every journey an elegant, organized, and stress-free experience.\n\n"
                            "Featuring a rich burgundy leather aesthetic with gold foil accents, EmpacArte unites smart luggage packing with climate and duration recommendations, a tactile customizable passport, collectible consular stamps, simulated boarding passes, and essential airport travel tools—100% offline and private.\n\n"
                            "✈️ KEY FEATURES:\n\n"
                            "1. 🧳 SMART PACKING STUDIO\n"
                            "• Automated packing recommendations tailored to trip duration and destination weather (warm, mild, cold, rain, snow).\n"
                            "• Bag segregation: Checked Bag, Carry-On, and Personal Item.\n"
                            "• Permanent essentials: Flag items with 'Always pack this' so they automatically appear in future trips.\n"
                            "• Visual progress and tactile haptic feedback as you pack.\n\n"
                            "2. 🛂 TACTILE PASSPORT & COLLECTIBLE STAMPS\n"
                            "• Your own digital passport card with biometric styling and MRZ code.\n"
                            "• Collect customs stamps and consular visas from iconic destinations worldwide.\n\n"
                            "3. 🎫 BOARDING PASSES & MULTI-CITY ITINERARIES\n"
                            "• Interactive boarding pass cards with departure countdowns, terminal, gate, seat, and boarding limits.\n"
                            "• Full multi-destination itinerary support for road trips and connecting flights.\n\n"
                            "4. 🛠️ ESSENTIAL TRAVELER TOOLS\n"
                            "• Offline currency calculator.\n"
                            "• Airport checklist and customs baggage restrictions (100ml liquids, power banks).\n\n"
                            "5. 🌍 6 GLOBAL LANGUAGES & 100% PRIVATE\n"
                            "• Localized in English, Spanish, Portuguese, French, German, and Italian.\n"
                            "• Zero accounts, zero ads, zero telemetry: your travel plans belong strictly to you."
                        ),
                    }
                ).execute()
                print("EmpacArte Store Listings Updated (es-419 & en-US)!")
            except Exception as e:
                print(f"EmpacArte Listing notice: {e}")

            all_langs = ["es-419", "en-US"]
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
                        print(f"EmpacArte Icon updated for {lang}")
                    except Exception as e:
                        print(f"EmpacArte Icon notice ({lang}): {e}")

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
                        print(f"EmpacArte Feature Graphic updated for {lang}")
                    except Exception as e:
                        print(f"EmpacArte Feature Graphic notice ({lang}): {e}")

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

        if package_name == "com.omniverselabs.anotadordejuegos":
            try:
                print("Updating Store Listing for Central de Juegos / Game Night Hub...")
                # es-419
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="es-419",
                    body={
                        "title": "Central de Juegos",
                        "shortDescription": "Anotadores y utilidades de mesa: Truco, Generala, Burako, dados y ruleta.",
                        "fullDescription": (
                            "Central de Juegos es la suite definitiva e imprescindible para tus noches de juegos de mesa, cartas y reuniones con amigos y familia.\n\n"
                            "Olvídate de buscar papel, lápiz o discutir por el puntaje: reúne en una sola app anotadores oficiales especializados, un contador libre multi-jugador y todas las utilidades que tu mesa necesita, 100% offline y sin publicidad.\n\n"
                            "🎲 ANOTADORES ESPECIALIZADOS INCLUIDOS:\n\n"
                            "• Truco Argentino: Anotador oficial a 30 puntos con fósforos tradicionales o visualización numérica directa, control de buenas/malas y deshacer.\n"
                            "• Generala: Planilla completa con cálculo automático de categorías (1 al 6), Escalera, Full, Poker, Generala y Doble Generala, distinguiendo jugadas servidas.\n"
                            "• Diez Mil (10.000): Anotador con calculadora de tiros, apertura mínima configurable (500, 750 o 1.000 pts) y plantada por ronda.\n"
                            "• Burako: Planilla de Base y Puntos con indicador de salida limpia, canastas puras/impuras y meta a 3.000 puntos.\n"
                            "• Escoba del 15: Conteo de escobas, 7 de oro, oros, setenta y mayoría de cartas.\n"
                            "• Contador Libre (1 a 12 jugadores): Marcador universal con sumas y restas rápidas por toque (+1, +5, +10, -1) para cualquier juego de mesa.\n\n"
                            "🛠️ UTILIDADES DE MESA INTEGRADAS:\n\n"
                            "• Tirador de Dados 3D: Lanza de 1 a 6 dados con físicas y sonidos realistas.\n"
                            "• ¿Quién Empieza? (Ruleta de Dedos): Cada jugador apoya su dedo en la pantalla y la ruleta elige al azar al que inicia la ronda.\n"
                            "• Temporizador de Turno: Tiempos predefinidos (30s, 60s, 90s, 120s) con alarma para mantener el ritmo de la partida.\n"
                            "• Lanzador de Moneda: Cara o ceca con animación fluida para resolver disputas al instante.\n\n"
                            "⭐ MESA PRO (OPCIONAL DE POR VIDA):\n\n"
                            "• Salón de la Fama: Ranking automático con podio de victorias históricas y Win-Rate (%) por jugador.\n"
                            "• Historial Ilimitado: Guarda todas las noches de juego para siempre sin límite.\n"
                            "• 100% Offline y Privado: Tus partidas y estadísticas se quedan exclusivamente en tu dispositivo."
                        ),
                    }
                ).execute()

                # en-US
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="en-US",
                    body={
                        "title": "Game Night Hub: Score Tracker",
                        "shortDescription": "The ultimate offline board game companion: scorekeeper, dice, timer & roulette.",
                        "fullDescription": (
                            "Game Night Hub is the ultimate all-in-one companion for your board game sessions, card games, and tabletop nights with family and friends.\n\n"
                            "Say goodbye to missing pens, scratch paper, and scorekeeping arguments. Game Night Hub brings together dedicated official scorekeepers, a universal multi-player counter, and essential tabletop utilities in a single, beautiful offline app with zero ads.\n\n"
                            "🎲 BUILT-IN SCOREKEEPERS:\n\n"
                            "• Free Score Tracker (1 to 12 Players): Universal score counter with one-tap increments (+1, +5, +10, -1) for any card or board game.\n"
                            "• Farkle / Ten Thousand (10,000): Official scorekeeper with roll calculator, customizable entry thresholds, and bank tracking.\n"
                            "• Generala (Dice Poker): Complete digital scorecard with automatic sum calculations for numbers, Straight, Full House, Four of a Kind, and Generala bonuses.\n"
                            "• Burako / Rummikub: Meld & base scorecard with clean opening indicators and 3,000-point goal tracking.\n"
                            "• Truco: Traditional South American 30-point matchstick scorekeeper with buenas/malas tracking.\n"
                            "• Escoba (Broom of 15): Track cards, coins, seven of coins, and prime effortlessly.\n\n"
                            "🛠️ ESSENTIAL TABLETOP TOOLS:\n\n"
                            "• 3D Dice Roller: Roll 1 to 6 dice simultaneously with realistic physics and sound.\n"
                            "• Who Starts? (Finger Roulette): Everyone places a finger on the screen, and the hub selects the starting player at random.\n"
                            "• Turn Timer: Preset turn countdowns (30s, 60s, 90s, 120s) with alerts to keep game rounds snappy.\n"
                            "• Coin Flipper: Flip heads or tails with smooth haptics to resolve quick decisions.\n\n"
                            "⭐ MESA PRO (ONE-TIME LIFETIME UNLOCK):\n\n"
                            "• Hall of Fame Leaderboard: Automatic win-rate (%) and victory podium tracking across all your game night rivals.\n"
                            "• Unlimited Match History: Preserve every single game session forever with zero caps.\n"
                            "• 100% Offline & Private: No accounts, no data harvesting, and complete privacy."
                        ),
                    }
                ).execute()
                print("Central de Juegos / Game Night Hub Store Listings Updated (es-419 & en-US)!")
            except Exception as e:
                print(f"Central de Juegos Listing notice: {e}")

        if package_name == "com.omniverselabs.menu_listo":
            icon_path = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\store\app_icon_512x512.png"
            feature_path = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\store\feature_graphic_1024x500.png"
            all_langs = ["es-419", "en-US"]
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
                        print(f"Menú Listo Icon updated for {lang}")
                    except Exception as e:
                        print(f"Menú Listo Icon notice ({lang}): {e}")

                if os.path.exists(feature_path):
                    try:
                        feat_media = MediaFileUpload(feature_path, mimetype="image/png")
                        edits.images().upload(
                            packageName=package_name,
                            editId=edit_id,
                            language=lang,
                            imageType="featureGraphic",
                            media_body=feat_media
                        ).execute()
                        print(f"Menú Listo Feature Graphic updated for {lang}")
                    except Exception as e:
                        print(f"Menú Listo Feature Graphic notice ({lang}): {e}")

        if package_name == "com.omniverselabs.charlemos":
            icon_path = r"c:\Projects\Omniverse Labs\apps\charlemos\assets\store_listing\app_icon_512x512.png"
            feature_path = r"c:\Projects\Omniverse Labs\apps\charlemos\assets\store_listing\feature_graphic_1024x500.png"
            ss1_path = r"c:\Projects\Omniverse Labs\apps\charlemos\assets\store_listing\screenshot_01_gameplay.png"
            ss2_path = r"c:\Projects\Omniverse Labs\apps\charlemos\assets\store_listing\screenshot_02_decks.png"

            try:
                print("Updating Store Listing for Charlemos...")
                # es-419
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="es-419",
                    body={
                        "title": "Charlemos: Juego de Cartas",
                        "shortDescription": "Preguntas para conectar: 490+ cartas, 13 mazos y retos 100% offline.",
                        "fullDescription": (
                            "Charlemos es el juego de cartas conversacional diseñado para transformar cualquier encuentro, cita, sobremesa o fiesta en una charla inolvidable, profunda y llena de complicidad.\n\n"
                            "Inspirado en la magia de las preguntas auténticas, Charlemos reúne más de 490 cartas cuidadosamente creadas y organizadas en 13 mazos temáticos y distintos niveles de profundidad emocional, 100% offline y sin anuncios.\n\n"
                            "🎴 13 MAZOS TEMÁTICOS PARA CADA OCASIÓN:\n\n"
                            "• Citas & Primeras Salidas: Romper el hielo y conocerse con naturalidad.\n"
                            "• Parejas & Complicidad: Confianza mutua, acuerdos y proyectos compartidos.\n"
                            "• Fuego & Fantasías (+18): Intimidad, sensualidad y deseos para parejas.\n"
                            "• Picante & Tabú (+18): Verdades candentes sin filtro y confesiones íntimas.\n"
                            "• Retos Picantes (+18): Desafíos atrevidos, miradas fijas, susurros y penitencias.\n"
                            "• ¿Quién es más probable? (5-10 amigos): Votación simultánea señalando con el dedo.\n"
                            "• Yo Nunca Nunca (5-10 amigos): Confesiones grupales, tragos y revelaciones.\n"
                            "• Amigos & Sobremesas: Risas, anécdotas memorables y complicidad.\n"
                            "• La Previa & Fiesta: Juegos, momentos desinhibidos y risas en grupo.\n"
                            "• Retos & Dinámicas: Desafíos espontáneos y consignas activas.\n"
                            "• Dilemas & Filosofía: ¿Qué prefieres? y debates apasionados.\n"
                            "• Viajes & Rutas: Choques culturales, mochilazos y anécdotas en ruta.\n"
                            "• Familia & Raíces: Infancia, recuerdos y tradiciones familiares.\n\n"
                            "✨ EXPERIENCIA CUIDADA & MINIMALISTA:\n\n"
                            "• Una Sola Pantalla Limpia: Desliza o toca para pasar a la siguiente pregunta al instante.\n"
                            "• Selector Rápido de Mazos: Mezcla solo las categorías que quieras para la ocasión.\n"
                            "• Compartir al Instante: Envía cualquier pregunta a tus redes o chats con un toque.\n"
                            "• 3 Paletas Estéticas: Coral Mist, Plum Orchid y Sunset Slate en Modo Claro y Oscuro.\n"
                            "• 100% Offline & Privado: Sin cuentas, sin registros y sin recolección de datos.\n"
                            "• 5 Idiomas Globales: Disponible en Español, Inglés, Portugués, Francés e Italiano."
                        ),
                    }
                ).execute()

                # en-US
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="en-US",
                    body={
                        "title": "Charlemos: Deep Questions",
                        "shortDescription": "Meaningful questions to connect: 490+ cards, 13 decks & dares.",
                        "fullDescription": (
                            "Charlemos is the conversational card game crafted to turn any date, gathering, late-night talk, or party into an unforgettable, deep, and genuine connection.\n\n"
                            "Featuring over 490 carefully curated cards across 13 thematic decks and distinct emotional depths, Charlemos is 100% offline and completely ad-free.\n\n"
                            "🎴 13 THEMATIC DECKS FOR EVERY OCCASION:\n\n"
                            "• Dates & First Encounters: Break the ice and get to know each other authentically.\n"
                            "• Couples & Intimacy: Deepen trust, shared dreams, and mutual understanding.\n"
                            "• Fire & Desires (+18): Sensuality, unspoken fantasies, and passion for couples.\n"
                            "• Spicy & Taboo (+18): Unfiltered intimate truths and bold confessions.\n"
                            "• Spicy Dares (+18): Seductive dares, intense eye contact, whispers, and penalties.\n"
                            "• Most Likely To (5-10 friends): Simultaneous group voting game.\n"
                            "• Never Have I Ever (5-10 friends): Party confessions, sips, and secrets.\n"
                            "• Friends & Gatherings: Great laughter, road trip memories, and late-night talks.\n"
                            "• Pre-Party & Fun: Spontaneous games, wild laughs, and unhinged moments.\n"
                            "• Dares & Games: Bold prompts and active playful challenges.\n"
                            "• Dilemmas & Debates: Would you rather? and captivating discussions.\n"
                            "• Travel & Adventures: Route stories, culture shocks, and dream destinations.\n"
                            "• Family & Roots: Childhood stories, nostalgia, and beloved traditions.\n\n"
                            "• Family & Roots: Childhood stories, nostalgia, and beloved traditions.\n\n"
                            "✨ MINIMALIST CRAFTED EXPERIENCE:\n\n"
                            "• Pure Single Screen: Tap or swipe smoothly between cards with subtle haptics.\n"
                            "• Quick Deck Mixer: Choose and combine exactly the decks you want for the night.\n"
                            "• Instant Share: Share any prompt to messaging apps or social stories with one tap.\n"
                            "• 3 Aesthetic Themes: Coral Mist, Plum Orchid, and Sunset Slate in Light and Dark.\n"
                            "• 100% Offline & Private: No accounts required, no tracking, total data privacy.\n"
                            "• 5 Global Languages: Fully localized in English, Spanish, Portuguese, French, and Italian."
                        ),
                    }
                ).execute()
                # pt-BR
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="pt-BR",
                    body={
                        "title": "Charlemos: Jogo de Cartas",
                        "shortDescription": "Perguntas para conectar: 490+ cartas, 13 baralhos e desafios 100% offline.",
                        "fullDescription": (
                            "Charlemos é o jogo de cartas conversacional criado para transformar qualquer encontro, date, mesa com amigos ou festa em uma conversa inesquecível, profunda e cheia de cumplicidade.\n\n"
                            "Inspirado no poder das perguntas autênticas, Charlemos reúne mais de 490 cartas cuidadosamente elaboradas e organizadas em 13 baralhos temáticos e diferentes níveis de profundidade emocional, 100% offline e sem anúncios.\n\n"
                            "🎴 13 BARALHOS TEMÁTICOS PARA CADA OCASIÃO:\n\n"
                            "• Encontros & Primeiros Dates: Quebre o gelo e conheça alguém com total naturalidade.\n"
                            "• Casais & Cumplicidade: Confiança mútua, intimidade, sonhos e projetos a dois.\n"
                            "• Fogo & Fantasias (+18): Sensualidade, desejos ocultos e paixão para casais.\n"
                            "• Picante & Tabu (+18): Verdades íntimas sem filtro e confissões ousadas.\n"
                            "• Desafios Picantes (+18): Prendas atrevidas, contato visual intenso e sussurros ao pé do ouvido.\n"
                            "• Quem é mais provável? (5-10 amigos): Votação simultânea apontando o dedo na contagem de 3.\n"
                            "• Eu Nunca (5-10 amigos): Confissões em grupo, risadas e segredos revelados.\n"
                            "• Amigos & Resenhas: Histórias marcantes, gargalhadas e momentos inesquecíveis.\n"
                            "• O Esquenta & Festa: Jogos de festa, dinâmicas e momentos descontraídos.\n"
                            "• Desafios & Dinâmicas: Desafios espontâneos e tarefas divertidas.\n"
                            "• Dilemas & Filosofia: \"O que você prefere?\" e debates apaixonados.\n"
                            "• Viagens & Aventuras: Histórias de estrada, choques culturais e destinos dos sonhos.\n"
                            "• Família & Raízes: Infância, lembranças e tradições queridas.\n\n"
                            "✨ EXPERIÊNCIA ELEGANTE & MINIMALISTA:\n\n"
                            "• Tela Única e Fluida: Deslize ou toque para passar para a próxima pergunta com resposta tátil háptica.\n"
                            "• Misturador Rápido de Baralhos: Combine apenas as categorias que você deseja para a ocasião.\n"
                            "• Compartilhe no Instante: Envie qualquer pergunta para redes sociais ou chats com um toque.\n"
                            "• 3 Paletas Estéticas: Coral Mist, Plum Orchid e Sunset Slate em Modo Claro e Escuro.\n"
                            "• 100% Offline & Privado: Sem necessidade de cadastro, contas ou coleta de dados.\n"
                            "• 5 Idiomas Globais: Totalmente localizado em Português, Espanhol, Inglês, Francês e Italiano."
                        ),
                    }
                ).execute()

                # fr-FR
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="fr-FR",
                    body={
                        "title": "Charlemos: Jeu de Cartes",
                        "shortDescription": "Questions pour connecter : 490+ cartes, 13 jeux et défis 100% hors-ligne.",
                        "fullDescription": (
                            "Charlemos est le jeu de cartes conversationnel conçu pour transformer n'importe quel rendez-vous amoureux, apéro entre amis, fin de repas ou soirée en une discussion inoubliable, profonde et sincère.\n\n"
                            "Inspiré par la magie des questions authentiques, Charlemos réunit plus de 490 cartes soigneusement rédigées et réparties en 13 thématiques et différents niveaux de profondeur émotionnelle, 100% hors-ligne et sans publicité.\n\n"
                            "🎴 13 JEUX THÉMATIQUES POUR TOUTES LES OCCASIONS :\n\n"
                            "• Rendez-vous & Premières Rencontres : Briser la glace et apprendre à se connaître naturellement.\n"
                            "• Couples & Complicité : Confiance mutuelle, intimité, projets communs et accords à deux.\n"
                            "• Flamme & Désirs (+18) : Sensualité, fantasmes inavoués et passion amoureuse.\n"
                            "• Piquant & Tabou (+18) : Vérités intimes sans filtre et confessions osées.\n"
                            "• Défis Piquants (+18) : Gages audacieux, regards intenses, murmures et défis coquins.\n"
                            "• Qui est le plus susceptible de... (5-10 amis) : Vote simultané en pointant du doigt à 3.\n"
                            "• Je n'ai jamais (5-10 amis) : Le classique des soirées, confessions et fous rires.\n"
                            "• Amis & Retrouvailles : Souvenirs marquants, rires partagés et discussions nocturnes.\n"
                            "• L'Apéro & Fête : Jeux festifs, ambiance chaleureuse et moments décomplexés.\n"
                            "• Défis & Gages : Défis spontanés et consignes dynamiques.\n"
                            "• Dilemmes & Débats : \"Tu préfères ?\" et débats passionnants pendant des heures.\n"
                            "• Voyages & Aventures : Récits de route, chocs culturels et destinations de rêve.\n"
                            "• Famille & Racines : Souvenirs d'enfance, nostalgie et traditions familiales.\n\n"
                            "✨ EXPÉRIENCE ÉPURÉE & MINIMALISTE :\n\n"
                            "• Écran Unique & Fluide : Balayez ou touchez pour passer à la carte suivante avec retour haptique subtil.\n"
                            "• Sélecteur Rapide de Jeux : Mélangez uniquement les thèmes souhaités pour votre soirée.\n"
                            "• Partage Instantané : Partagez n'importe quelle question sur vos réseaux ou messageries en un clic.\n"
                            "• 3 Thèmes Esthétiques : Coral Mist, Plum Orchid et Sunset Slate en Mode Clair et Sombre.\n"
                            "• 100% Hors-Ligne & Privé : Aucun compte requis, aucune collecte de données personnelles.\n"
                            "• 5 Langues Mondiales : Entièrement disponible en Français, Espagnol, Anglais, Portugais et Italien."
                        ),
                    }
                ).execute()

                # it-IT
                edits.listings().update(
                    packageName=package_name,
                    editId=edit_id,
                    language="it-IT",
                    body={
                        "title": "Charlemos: Gioco di Carte",
                        "shortDescription": "Domande per connettersi: 490+ carte, 13 mazzi e sfide 100% offline.",
                        "fullDescription": (
                            "Charlemos è il gioco di carte conversazionale pensato per trasformare ogni appuntamento, cena con amici, dopocena o festa in una conversazione indimenticabile, profonda e complice.\n\n"
                            "Ispirato al potere delle domande autentiche, Charlemos raccoglie oltre 490 carte accuratamente create e organizzate in 13 mazzi tematici e vari livelli di profondità emotiva, 100% offline e senza pubblicità.\n\n"
                            "🎴 13 MAZZI TEMATICI PER OGNI OCCASIONE:\n\n"
                            "• Appuntamenti & Primi Incontri: Rompere il ghiaccio e conoscersi con spontaneità.\n"
                            "• Coppie & Complicità: Fiducia reciproca, intimità, desideri e progetti condivisi.\n"
                            "• Fuoco & Fantasie (+18): Sensualità, desideri nascosti e passione di coppia.\n"
                            "• Piccante & Tabù (+18): Verità intime senza filtri e confessioni proibite.\n"
                            "• Sfide Piccanti (+18): Sfide audaci, sguardi intensi, sussurri e penitenze piccanti.\n"
                            "• Chi è più probabile che... (5-10 amici): Votazione simultanea indicando a dito al conto di 3.\n"
                            "• Non ho mai (5-10 amici): Il classico dei pre-serata: confessioni, risate e segreti svelati.\n"
                            "• Amici & Serate Insieme: Aneddoti memorabili, risate a non finire e discorsi a cuore aperto.\n"
                            "• Pre-Serata & Festa: Giochi di gruppo, spensieratezza e atmosfera da festa.\n"
                            "• Sfide & Dinamiche: Prove spontanee e sfide divertenti.\n"
                            "• Dilemmi & Filosofia: \"Cosa preferisci?\" e accesi dibattiti per ore.\n"
                            "• Viaggi & Avventure: Avventure on the road, shock culturali e mete da sogno.\n"
                            "• Famiglia & Radici: Infanzia, ricordi cari e tradizioni di famiglia.\n\n"
                            "✨ ESPERIENZA CURATA & MINIMALISTA:\n\n"
                            "• Schermo Singolo Pulito: Scorri o tocca per passare alla carta successiva con feedback aptico delicato.\n"
                            "• Mixer Rapido dei Mazzi: Mescola solo le categorie desiderate per la serata.\n"
                            "• Condivisione Istantanea: Invia qualsiasi domanda sulle tue storie o app di messaggistica con un tocco.\n"
                            "• 3 Palette di Colore: Coral Mist, Plum Orchid e Sunset Slate in modalità Chiara e Scura.\n"
                            "• 100% Offline & Privato: Nessun account richiesto, zero tracciamento, totale privacy dei dati.\n"
                            "• 5 Lingue Globali: Interamente tradotto in Italiano, Spagnolo, Inglese, Portoghese e Francese."
                        ),
                    }
                ).execute()

                print("Charlemos Store Listings Updated (es-419, en-US, pt-BR, fr-FR, it-IT)!")
            except Exception as e:
                print(f"Charlemos Listing notice: {e}")

            all_langs = ["es-419", "en-US", "pt-BR", "fr-FR", "it-IT"]
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
                        print(f"Charlemos Icon updated for {lang}")
                    except Exception as e:
                        print(f"Charlemos Icon notice ({lang}): {e}")

                if os.path.exists(feature_path):
                    try:
                        feat_media = MediaFileUpload(feature_path, mimetype="image/png")
                        edits.images().upload(
                            packageName=package_name,
                            editId=edit_id,
                            language=lang,
                            imageType="featureGraphic",
                            media_body=feat_media
                        ).execute()
                        print(f"Charlemos Feature Graphic updated for {lang}")
                    except Exception as e:
                        print(f"Charlemos Feature Graphic notice ({lang}): {e}")

                # Clear previous screenshots first to avoid exceeding the max 8 screenshots limit
                try:
                    edits.images().deleteall(
                        packageName=package_name,
                        editId=edit_id,
                        language=lang,
                        imageType="phoneScreenshots"
                    ).execute()
                except Exception as e:
                    pass

                charlemos_screenshots = [
                    os.path.join(r"c:\Projects\Omniverse Labs\apps\charlemos\assets\store_listing", f)
                    for f in [
                        "screenshot_01_decks.png",
                        "screenshot_02_gameplay_familia.png",
                        "screenshot_03_gameplay_parejas.png",
                        "screenshot_04_gameplay_amigos.png",
                        "screenshot_05_gameplay_yonunca.png",
                    ]
                ]

                for ss_file in charlemos_screenshots:
                    if os.path.exists(ss_file):
                        try:
                            ss_media = MediaFileUpload(ss_file, mimetype="image/png")
                            edits.images().upload(
                                packageName=package_name,
                                editId=edit_id,
                                language=lang,
                                imageType="phoneScreenshots",
                                media_body=ss_media
                            ).execute()
                            print(f"Charlemos Screenshot {os.path.basename(ss_file)} updated for {lang}")
                        except Exception as e:
                            print(f"Charlemos Screenshot notice ({lang}): {e}")


        version_code = None
        existing_bundles = edits.bundles().list(packageName=package_name, editId=edit_id).execute().get("bundles", [])
        
        print(f"Uploading App Bundle ({os.path.getsize(aab_path) / (1024*1024):.2f} MB)...")
        media = MediaFileUpload(aab_path, mimetype="application/octet-stream", chunksize=10*1024*1024, resumable=True)
        bundle_req = edits.bundles().upload(packageName=package_name, editId=edit_id, media_body=media)
        
        response = None
        try:
            while response is None:
                status, response = bundle_req.next_chunk(num_retries=5)
                if status:
                    print(f"Uploaded {int(status.progress() * 100)}%...")

            version_code = response["versionCode"]
            print(f"Bundle Uploaded Successfully! (Version Code: {version_code})")
        except HttpError as e:
            error_data = json.loads(e.content.decode("utf-8")) if e.content else {}
            err_msg = error_data.get("error", {}).get("message", str(e))
            if "already been used" in err_msg.lower() and existing_bundles:
                version_code = max([b["versionCode"] for b in existing_bundles])
                print(f"Notice: Bundle already uploaded. Reusing latest existing Version Code: {version_code}")
            else:
                raise e

        if package_name == "com.omniverselabs.empacarte":
            rel_name = release_name or f"1.0.0 (Build {version_code})"
            rel_notes_es = notes_es or "Lanzamiento inicial de EmpacArte: El arte de empacar con pasaporte táctil, sellos consulares, tarjetas de embarque y 6 idiomas."
            rel_notes_en = notes_en or "Initial release of EmpacArte: The art of packing with tactile passport, collectible stamps, boarding passes, and 6 languages."
        elif package_name == "com.omniverselabs.ritmo":
            rel_name = release_name or f"1.0.8 (Build {version_code})"
            rel_notes_es = notes_es or "Protección de modo desarrollador, política de privacidad integrada, opción de eliminación completa de datos y mejoras de rendimiento."
            rel_notes_en = notes_en or "Developer mode protection, in-app privacy policy, complete data deletion rights, and performance improvements."
        elif package_name == "com.omniverselabs.anotadordejuegos":
            rel_name = release_name or f"1.0.9 (Build {version_code})"
            rel_notes_es = notes_es or "Protección de modo desarrollador, política de privacidad integrada, opción de eliminación completa de datos y mejoras de rendimiento."
            rel_notes_en = notes_en or "Developer mode protection, in-app privacy policy, complete data deletion rights, and performance improvements."
        elif package_name == "com.omniverselabs.charlemos":
            rel_name = release_name or f"1.0.12 (Build {version_code})"
            rel_notes_es = notes_es or "Protección de modo desarrollador, política de privacidad integrada, opción de eliminación completa de datos y mejoras de rendimiento."
            rel_notes_en = notes_en or "Developer mode protection, in-app privacy policy, complete data deletion rights, and performance improvements."
            rel_notes_pt = "Proteção do modo desenvolvedor, política de privacidade no aplicativo, exclusão completa de dados e melhorias de desempenho."
            rel_notes_fr = "Protection du mode développeur, politique de confidentialité intégrée, suppression complète des données et améliorations de performances."
            rel_notes_it = "Protezione della modalità sviluppatore, informativa sulla privacy in-app, cancellazione completa dei dati e miglioramenti delle prestazioni."
        else:
            rel_name = release_name or f"1.2.16 (Build {version_code})"
            rel_notes_es = notes_es or "Protección de modo desarrollador, política de privacidad integrada, opción de eliminación completa de datos y mejoras de rendimiento."
            rel_notes_en = notes_en or "Developer mode protection, in-app privacy policy, complete data deletion rights, and performance improvements."

        def make_track_body(t_name, status_val):
            r_notes = [
                {"language": "es-419", "text": rel_notes_es},
                {"language": "en-US", "text": rel_notes_en},
            ]
            if package_name == "com.omniverselabs.charlemos":
                r_notes.extend([
                    {"language": "pt-BR", "text": rel_notes_pt},
                    {"language": "fr-FR", "text": rel_notes_fr},
                    {"language": "it-IT", "text": rel_notes_it},
                ])
            return {
                "track": t_name,
                "releases": [
                    {
                        "name": rel_name,
                        "versionCodes": [str(version_code)],
                        "status": status_val,
                        "releaseNotes": r_notes
                    }
                ]
            }

        # Deploy to specified track(s)
        tracks_to_deploy = [t.strip() for t in track.split(",") if t.strip()]
        for t in tracks_to_deploy:
            print(f"Assigning Version Code {version_code} to track '{t}'...")
            edits.tracks().update(
                packageName=package_name,
                editId=edit_id,
                track=t,
                body=make_track_body(t, "completed")
            ).execute()
            print(f"Track '{t}' assigned.")

        # Validate edit session before committing
        print("Validating Edit session...")
        need_changes_not_sent = False
        try:
            edits.validate(packageName=package_name, editId=edit_id).execute()
        except HttpError as val_err:
            err_json = json.loads(val_err.content.decode("utf-8")) if val_err.content else {}
            err_str = err_json.get("error", {}).get("message", str(val_err))
            print(f"Validation notice: {err_str}")
            if "changesnotsentforreview" in err_str.lower():
                need_changes_not_sent = True
                print("Notice: changesNotSentForReview flag required.")
            elif "status draft" in err_str.lower():
                print("Notice: App is in draft mode on Google Play Console. Converting non-internal releases to 'draft' status...")
                for t in tracks_to_deploy:
                    status_to_use = "completed" if t == "internal" else "draft"
                    edits.tracks().update(
                        packageName=package_name,
                        editId=edit_id,
                        track=t,
                        body=make_track_body(t, status_to_use)
                    ).execute()
                try:
                    edits.validate(packageName=package_name, editId=edit_id).execute()
                    print("Validation succeeded with adapted release statuses.")
                except HttpError as val_err2:
                    err_json2 = json.loads(val_err2.content.decode("utf-8")) if val_err2.content else {}
                    err_str2 = err_json2.get("error", {}).get("message", str(val_err2))
                    if "changesnotsentforreview" in err_str2.lower():
                        need_changes_not_sent = True
                    else:
                        raise val_err2
            else:
                raise val_err

        print("Committing and Publishing Edit to Google Play...")
        try:
            if need_changes_not_sent:
                commit_res = edits.commit(packageName=package_name, editId=edit_id, changesNotSentForReview=True).execute()
            else:
                commit_res = edits.commit(packageName=package_name, editId=edit_id).execute()
        except HttpError as commit_err:
            err_json_c = json.loads(commit_err.content.decode("utf-8")) if commit_err.content else {}
            err_str_c = err_json_c.get("error", {}).get("message", str(commit_err))
            if "changesnotsentforreview" in err_str_c.lower():
                print("Retrying commit with changesNotSentForReview=True...")
                commit_res = edits.commit(packageName=package_name, editId=edit_id, changesNotSentForReview=True).execute()
            else:
                raise commit_err

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
