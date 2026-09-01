import os
import sys
import json
import urllib.request
import urllib.parse
import http.client

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

TOKEN_FILE = os.path.expanduser("~/.config/omniverse_labs/play_oauth_token.json")
PACKAGE_NAME = "com.omniverselabs.anotadordejuegos"
AAB_PATH = r"C:\Projects\Omniverse Labs\apps\central_de_juegos\build\app\outputs\bundle\release\app-release.aab"

def get_access_token():
    if not os.path.exists(TOKEN_FILE):
        print(f"[ERROR] OAuth token file not found at {TOKEN_FILE}")
        sys.exit(1)
    
    with open(TOKEN_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    refresh_token = data.get("refresh_token")
    client_id = data.get("client_id")
    client_secret = data.get("client_secret")
    access_token = data.get("access_token")

    # Refresh token to make sure it's valid
    if refresh_token and client_id and client_secret:
        token_url = "https://oauth2.googleapis.com/token"
        req_data = urllib.parse.urlencode({
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }).encode("utf-8")
        
        req = urllib.request.Request(token_url, data=req_data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        try:
            with urllib.request.urlopen(req) as resp:
                res_json = json.loads(resp.read().decode("utf-8"))
                access_token = res_json["access_token"]
                data["access_token"] = access_token
                with open(TOKEN_FILE, "w", encoding="utf-8") as out:
                    json.dump(data, out, indent=2)
        except Exception as e:
            print(f"[WARN] Could not refresh access token: {e}. Using cached token.")

    return access_token

def deploy():
    if not os.path.exists(AAB_PATH):
        print(f"[ERROR] AAB bundle not found at {AAB_PATH}")
        sys.exit(1)

    file_size_mb = os.path.getsize(AAB_PATH) / (1024 * 1024)
    print("=" * 60)
    print("   Omniverse Labs - Google Play Automated Deployer")
    print("=" * 60)
    print(f"📦 Package Name: {PACKAGE_NAME}")
    print(f"📂 AAB File: {AAB_PATH} ({file_size_mb:.2f} MB)")

    access_token = get_access_token()
    base_url = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"

    # Step 1: Create an Edit
    print("\n1️⃣ Creating new edit session on Google Play Console...")
    create_edit_url = f"{base_url}/{PACKAGE_NAME}/edits"
    req = urllib.request.Request(create_edit_url, data=b"{}", method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    with urllib.request.urlopen(req) as resp:
        edit_data = json.loads(resp.read().decode("utf-8"))
        edit_id = edit_data["id"]
        print(f"   ✅ Edit session created! (Edit ID: {edit_id})")

    # Step 2: Upload AAB Bundle
    print(f"\n2️⃣ Uploading App Bundle ({file_size_mb:.2f} MB)... (Please wait)")
    upload_url = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE_NAME}/edits/{edit_id}/bundles?uploadType=media"
    
    with open(AAB_PATH, "rb") as aab_file:
        aab_bytes = aab_file.read()

    req = urllib.request.Request(upload_url, data=aab_bytes, method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/octet-stream")
    req.add_header("Content-Length", str(len(aab_bytes)))

    with urllib.request.urlopen(req) as resp:
        bundle_resp = json.loads(resp.read().decode("utf-8"))
        version_code = bundle_resp.get("versionCode")
        sha256 = bundle_resp.get("sha256", "")[:12]
        print(f"   ✅ Bundle uploaded successfully! Version Code: {version_code} (SHA256: {sha256}...)")

    # Step 3: Assign to Tracks (Internal & Beta)
    tracks_to_update = ["internal", "beta"]
    release_notes_text = (
        "Lanzamiento oficial de Central de Juegos por Omniverse Labs: Anotador digital todo en uno para juegos de mesa "
        "(Truco argentino a 30 puntos, Generala con planilla oficial, Diez Mil con aperturas configurables, Burako a 3.000 puntos, "
        "Escoba del 15 y Contador Libre multijugador interactivo con detección de líder). "
        "Incluye herramientas de mesa: lanzador de dados 3D con física, ruleta táctil para definir quién empieza, "
        "temporizador de turno con alerta sonora y lanzador de moneda 3D."
    )

    for track in tracks_to_update:
        print(f"\n3️⃣ Assigning release to track [{track.upper()}]...")
        track_url = f"{base_url}/{PACKAGE_NAME}/edits/{edit_id}/tracks/{track}"
        payload = {
            "track": track,
            "releases": [
                {
                    "name": f"{version_code} (1.0.2)",
                    "versionCodes": [str(version_code)],
                    "status": "completed",
                    "releaseNotes": [
                        {
                            "language": "es-419",
                            "text": release_notes_text
                        }
                    ]
                }
            ]
        }
        req_data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(track_url, data=req_data, method="PUT")
        req.add_header("Authorization", f"Bearer {access_token}")
        req.add_header("Content-Type", "application/json")

        with urllib.request.urlopen(req) as resp:
            track_resp = json.loads(resp.read().decode("utf-8"))
            print(f"   ✅ Track [{track.upper()}] configured with release {version_code} (1.0.2)")

    # Step 4: Commit Edit
    print(f"\n4️⃣ Committing and publishing changes to Google Play...")
    commit_url = f"{base_url}/{PACKAGE_NAME}/edits/{edit_id}:commit"
    req = urllib.request.Request(commit_url, data=b"", method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    with urllib.request.urlopen(req) as resp:
        commit_resp = json.loads(resp.read().decode("utf-8"))
        print("   🎉 SUCCESS! Release has been committed and published to Google Play Console!")
        print("=" * 60)

if __name__ == "__main__":
    try:
        deploy()
    except urllib.error.HTTPError as err:
        error_body = err.read().decode("utf-8", errors="ignore")
        print(f"\n❌ Google Play API HTTP Error {err.code}: {err.reason}")
        print(f"Details: {error_body}")
        sys.exit(1)
    except Exception as ex:
        print(f"\n❌ Unexpected error during deployment: {ex}")
        sys.exit(1)
