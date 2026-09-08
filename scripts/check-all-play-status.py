import os
import sys
import json

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

APPS = [
    {"name": "Central de Juegos", "package": "com.omniverselabs.anotadordejuegos"},
    {"name": "Menú Listo", "package": "com.omniverselabs.menu_listo"},
    {"name": "Ritmo: Hábitos & Diario", "package": "com.omniverselabs.ritmo"},
    {"name": "EmpacArte", "package": "com.omniverselabs.empacarte"},
    {"name": "Charlemos", "package": "com.omniverselabs.charlemos"},
]

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

def check_all():
    print("=" * 70)
    print("   OMNIVERSE LABS - GOOGLE PLAY CONSOLE AUDIT REPORT")
    print("=" * 70)

    try:
        service = get_oauth_service()
    except Exception as e:
        print(f"Error authenticating: {e}")
        return False

    results = []

    for app in APPS:
        pkg = app["package"]
        app_name = app["name"]
        print(f"\nScanning [{app_name}] ({pkg})...")
        app_info = {
            "name": app_name,
            "package": pkg,
            "tracks": {},
            "listings": [],
            "error": None
        }

        try:
            edits = service.edits()
            edit_req = edits.insert(body={}, packageName=pkg)
            edit_res = edit_req.execute()
            edit_id = edit_res["id"]

            tracks_res = edits.tracks().list(packageName=pkg, editId=edit_id).execute()
            tracks = tracks_res.get("tracks", [])

            for t in tracks:
                track_name = t.get("track", "unknown").lower()
                releases = t.get("releases", [])
                app_info["tracks"][track_name] = []
                for r in releases:
                    app_info["tracks"][track_name].append({
                        "name": r.get("name", "N/A"),
                        "versionCodes": r.get("versionCodes", []),
                        "status": r.get("status", "N/A"),
                        "userFraction": r.get("userFraction", 1.0) if "userFraction" in r else None,
                        "releaseNotes": r.get("releaseNotes", [])
                    })

            try:
                listings_res = edits.listings().list(packageName=pkg, editId=edit_id).execute()
                listings = listings_res.get("listings", [])
                for lst in listings:
                    app_info["listings"].append({
                        "language": lst.get("language"),
                        "title": lst.get("title"),
                        "shortDescription": lst.get("shortDescription")
                    })
            except Exception:
                pass

            try:
                edits.delete(packageName=pkg, editId=edit_id).execute()
            except Exception:
                pass

        except HttpError as e:
            error_content = json.loads(e.content.decode("utf-8")) if e.content else {}
            error_msg = error_content.get("error", {}).get("message", str(e))
            error_code = e.resp.status
            app_info["error"] = f"HTTP {error_code}: {error_msg}"
        except Exception as e:
            app_info["error"] = str(e)

        results.append(app_info)

    # Print summary
    print("\n" + "=" * 70)
    print("                    AUDIT SUMMARY RESULTS")
    print("=" * 70)

    for info in results:
        print(f"\n📦 App: {info['name']} ({info['package']})")
        if info["error"]:
            print(f"   ❌ Status: {info['error']}")
            continue

        prod = info["tracks"].get("production", [])
        if not prod:
            print("   🔴 PRODUCTION: No release found / Not in Production")
        else:
            for r in prod:
                status = r['status'].upper()
                vname = r['name']
                vcodes = ', '.join(map(str, r['versionCodes']))
                frac = f" (Rollout: {r['userFraction']*100:.1f}%)" if r.get('userFraction') is not None else ""
                print(f"   🟢 PRODUCTION: Version {vname} [Codes: {vcodes}] - Status: {status}{frac}")

        # Other tracks
        for tr_name, rels in info["tracks"].items():
            if tr_name == "production":
                continue
            if not rels:
                continue
            for r in rels:
                status = r['status'].upper()
                vname = r['name']
                vcodes = ', '.join(map(str, r['versionCodes']))
                frac = f" (Rollout: {r['userFraction']*100:.1f}%)" if r.get('userFraction') is not None else ""
                print(f"   🔹 [{tr_name.upper()}]: Version {vname} [Codes: {vcodes}] - Status: {status}{frac}")

        if info["listings"]:
            print(f"   🌐 Locales: {len(info['listings'])} configured ({', '.join([l['language'] for l in info['listings'][:4]])}...)")

    return True

if __name__ == "__main__":
    check_all()
