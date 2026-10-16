import os
import sys
import json
import socket
import argparse
import urllib.request
import urllib.parse

socket.setdefaulttimeout(300)

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
PACKAGE_NAME = "com.omniverselabs.omnitrade"

def get_oauth_service():
    if not os.path.exists(OAUTH_TOKEN_STORE):
        raise FileNotFoundError(f"OAuth token not found at: {OAUTH_TOKEN_STORE}")

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

def deploy_omnitrade(aab_path: str, target_track: str = "beta"):
    print("=" * 60)
    print(f"🚀 Omniverse Labs - Deploying {PACKAGE_NAME} to Google Play")
    print("=" * 60)
    print(f"📦 Package: {PACKAGE_NAME}")
    print(f"📂 AAB Bundle: {aab_path}")
    print(f"🎯 Target Track: [{target_track.upper()}] (Open Testing)")

    service = get_oauth_service()
    edits = service.edits()

    # 1. Create Edit session
    print("\n1️⃣ Creating edit session on Google Play Console...")
    edit_req = edits.insert(body={}, packageName=PACKAGE_NAME)
    edit_res = edit_req.execute()
    edit_id = edit_res["id"]
    print(f"   ✅ Edit session created (Edit ID: {edit_id})")

    # 2. Upload Store Listings (es-419 & en-US)
    print("\n2️⃣ Updating Store Listings (es-419 & en-US)...")
    listing_es = {
        "title": "OmniTrade: Registro de Trades",
        "shortDescription": "Bitácora de trading, calculadora de riesgo, gestión de capital y analíticas.",
        "fullDescription": (
            "OmniTrade es la bitácora financiera integral y calculadora de gestión de riesgo diseñada para traders que operan con disciplina y precisión matemática.\n\n"
            "Construida con un enfoque 100% Offline-First y estética de terminal profesional, OmniTrade te brinda control absoluto sobre tu operativa en Criptomonedas, Acciones, Forex, Futuros y Opciones sin servidores externos ni rastreadores.\n\n"
            "📊 CARACTERÍSTICAS PRINCIPALES:\n\n"
            "1. 📝 BITÁCORA Y REGISTRO DE OPERACIONES\n"
            "• Registra trades Long y Short con precios de entrada, salida, stop loss, take profit y comisiones.\n"
            "• Cálculo automático en tiempo real de ratio Riesgo/Beneficio (R:R), P&L neto y porcentaje de retorno.\n"
            "• Etiquetas de estrategia (Breakout, Pullback, Scalp, Swing) y seguimiento psicológico de emociones (Disciplinado, FOMO, Venganza, Paciencia).\n\n"
            "2. 📐 CALCULADORA DE POSICIÓN & GESTIÓN 1% R\n"
            "• Determina el tamaño exacto de posición (unidades/contratos) según el capital de tu cuenta y el porcentaje de riesgo máximo permitido.\n"
            "• Botón de transferencia directa para convertir el cálculo en una operación registrada en un toque.\n\n"
            "3. 📈 ANALÍTICAS AVANZADAS & CURVA DE PATRIMONIO\n"
            "• Métricas institucionales: Win Rate, Profit Factor, Expectancy matemática, ganancia media y peor trade.\n"
            "• Gráfica interactiva de curva de equidad y desglose de rendimiento por estrategia.\n\n"
            "4. 🛡️ SEGURIDAD BIOMÉTRICA & PRIVACIDAD TOTAL\n"
            "• Bloqueo con PIN de 4 dígitos o huella dactilar nativa con auto-bloqueo configurable.\n"
            "• Respaldo completo en JSON y exportación tabular CSV para análisis en Excel o Google Sheets.\n"
            "• 100% Fuera de línea: Tus datos financieros nunca abandonan tu dispositivo.\n\n"
            "5. 🌍 MULTI-IDIOMA INTEGRAL\n"
            "• Disponible en Español, Inglés, Portugués, Francés e Italiano."
        )
    }

    listing_en = {
        "title": "OmniTrade: Trading Journal",
        "shortDescription": "Trading journal, position size calculator, risk management and trade analytics.",
        "fullDescription": (
            "OmniTrade is the comprehensive financial trade journal and position size calculator built for disciplined traders focused on quantitative execution.\n\n"
            "Engineered with a 100% Offline-First architecture and sleek obsidian terminal aesthetics, OmniTrade gives you complete control over your Crypto, Stocks, Forex, Futures, and Options trading without third-party tracking or cloud dependency.\n\n"
            "📊 KEY FEATURES:\n\n"
            "1. 📝 TRADE JOURNAL & EXECUTION LOGGING\n"
            "• Log Long & Short positions with entry, exit, stop loss, take profit, multiplier, and commission fees.\n"
            "• Real-time automated calculations for Risk:Reward (R:R) ratio, net realized P&L, and return percentage.\n"
            "• Strategy tagging (Breakout, Pullback, Scalp, Swing) and mindset tracking (Disciplined, FOMO, Revenge, Patient).\n\n"
            "2. 📐 RISK & POSITION SIZE CALCULATOR\n"
            "• Calculate optimal position sizing (units/contracts) based on account capital and risk percentage tolerance.\n"
            "• One-tap transfer to convert calculations directly into active trades.\n\n"
            "3. 📈 QUANTITATIVE METRICS & EQUITY CURVE\n"
            "• Key performance KPIs: Win Rate, Profit Factor, Mathematical Expectancy, average win/loss, and drawdown metrics.\n"
            "• Dynamic equity curve chart and setup win-rate breakdown.\n\n"
            "4. 🛡️ BIOMETRIC SECURITY & TOTAL PRIVACY\n"
            "• 4-digit PIN protection or native fingerprint biometric authentication with configurable auto-lock.\n"
            "• Full JSON database backup and CSV export for spreadsheets.\n"
            "• 100% Offline: Your financial records remain strictly on your local device.\n\n"
            "5. 🌍 FULL MULTI-LANGUAGE SUPPORT\n"
            "• Available in English, Spanish, Portuguese, French, and Italian."
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
            print(f"   ⚠️ Listing warning for [{lang_code}]: {e}")

    # 3. Upload Store Images
    print("\n3️⃣ Uploading Graphic Assets (Icon, Feature Graphic, Screenshots)...")
    icon_path = r"c:\Projects\Omniverse Labs\apps\omni_trade\store_assets\play_store\icon_512x512.png"
    feature_path = r"c:\Projects\Omniverse Labs\apps\omni_trade\store_assets\play_store\feature_graphic_1024x500.jpg"
    screenshot1_path = r"c:\Projects\Omniverse Labs\apps\omni_trade\store_assets\play_store\screenshot_1_dashboard.png"
    screenshot2_path = r"c:\Projects\Omniverse Labs\apps\omni_trade\store_assets\play_store\screenshot_2_calculator.png"

    for lang in ["es-419", "en-US"]:
        if os.path.exists(icon_path):
            try:
                media = MediaFileUpload(icon_path, mimetype="image/png")
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

        if os.path.exists(feature_path):
            try:
                media = MediaFileUpload(feature_path, mimetype="image/jpeg")
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

        # Screenshots
        for s_idx, s_path in enumerate([screenshot1_path, screenshot2_path], start=1):
            if os.path.exists(s_path):
                try:
                    media = MediaFileUpload(s_path, mimetype="image/png")
                    edits.images().upload(
                        packageName=PACKAGE_NAME,
                        editId=edit_id,
                        language=lang,
                        imageType="phoneScreenshots",
                        media_body=media
                    ).execute()
                    print(f"   ✅ Phone Screenshot #{s_idx} uploaded for [{lang}]")
                except Exception as e:
                    print(f"   ⚠️ Screenshot #{s_idx} upload warning for [{lang}]: {e}")

    # 4. Upload App Bundle
    file_size_mb = os.path.getsize(aab_path) / (1024 * 1024)
    print(f"\n4️⃣ Uploading App Bundle ({file_size_mb:.2f} MB)...")
    bundle_media = MediaFileUpload(aab_path, mimetype="application/octet-stream", resumable=True)
    bundle_res = edits.bundles().upload(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        media_body=bundle_media
    ).execute()

    version_code = bundle_res.get("versionCode")
    sha256 = bundle_res.get("sha256", "")[:12]
    print(f"   ✅ App Bundle uploaded! Version Code: {version_code} (SHA256: {sha256}...)")

    # 5. Assign to Track
    print(f"\n5️⃣ Assigning version {version_code} to track [{target_track.upper()}]...")
    notes = [
        {"language": "es-419", "text": "OmniTrade v1.0.2: Nueva política de privacidad integrada, función de purga y eliminación de datos locales, diálogos de soporte y mejoras de seguridad."},
        {"language": "en-US", "text": "OmniTrade v1.0.2: Built-in privacy policy, local data purge/deletion options, about & support dialogs, and security enhancements."}
    ]

    def make_track_body(track_name, status):
        return {
            "track": track_name,
            "releases": [
                {
                    "name": f"v{version_code} (1.0.2)",
                    "versionCodes": [str(version_code)],
                    "status": status,
                    "releaseNotes": notes
                }
            ]
        }

    status_to_use = "completed"
    try:
        edits.tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=target_track,
            body=make_track_body(target_track, status_to_use)
        ).execute()
        print(f"   ✅ Track [{target_track.upper()}] configured with status '{status_to_use}'")
    except HttpError as e:
        print(f"   ⚠️ Track update error with '{status_to_use}', attempting 'draft' status: {e}")
        status_to_use = "draft"
        edits.tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=target_track,
            body=make_track_body(target_track, status_to_use)
        ).execute()
        print(f"   ✅ Track [{target_track.upper()}] configured with status 'draft'")

    # Also update internal track if we are deploying beta
    if target_track != "internal":
        try:
            edits.tracks().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                track="internal",
                body=make_track_body("internal", "completed")
            ).execute()
            print("   ✅ Track [INTERNAL] also updated with new bundle!")
        except Exception as e_internal:
            print(f"   ℹ️ Notice: Track [INTERNAL] update skipped: {e_internal}")

    # 6. Validate Edit
    print("\n6️⃣ Validating edit session...")
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
        elif "status draft" in err_msg.lower() and status_to_use != "draft":
            print("   Retrying validation with 'draft' status...")
            status_to_use = "draft"
            edits.tracks().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                track=target_track,
                body=make_track_body(target_track, status_to_use)
            ).execute()
            try:
                edits.validate(packageName=PACKAGE_NAME, editId=edit_id).execute()
                print("   ✅ Validation passed with draft status!")
            except HttpError as v2_err:
                err_json2 = json.loads(v2_err.content.decode("utf-8")) if v2_err.content else {}
                err_msg2 = err_json2.get("error", {}).get("message", str(v2_err))
                if "changesnotsentforreview" in err_msg2.lower():
                    need_changes_not_sent = True

    # 7. Commit Edit
    print("\n7️⃣ Committing and publishing changes to Google Play...")
    try:
        if need_changes_not_sent:
            commit_res = edits.commit(packageName=PACKAGE_NAME, editId=edit_id, changesNotSentForReview=True).execute()
        else:
            commit_res = edits.commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    except HttpError as commit_err:
        err_json = json.loads(commit_err.content.decode("utf-8")) if commit_err.content else {}
        err_msg = err_json.get("error", {}).get("message", str(commit_err))
        if "changesnotsentforreview" in err_msg.lower():
            print("   ℹ️ Retrying commit with changesNotSentForReview=True...")
            commit_res = edits.commit(packageName=PACKAGE_NAME, editId=edit_id, changesNotSentForReview=True).execute()
        else:
            raise commit_err
    print(f"   🎉 SUCCESS! Released to Google Play [{target_track.upper()}]! (Commit ID: {commit_res.get('id', edit_id)})")
    print("=" * 60)
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--aab", default=r"apps/omni_trade/build/app/outputs/bundle/release/app-release.aab")
    parser.add_argument("--track", default="beta")
    args = parser.parse_args()

    deploy_omnitrade(args.aab, args.track)
