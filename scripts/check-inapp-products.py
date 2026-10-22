import os
import sys
import json

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

APPS = [
    {"name": "Central de Juegos", "package": "com.omniverselabs.anotadordejuegos", "expected_sku": "central_juegos_pro_unlock"},
    {"name": "Menú Listo", "package": "com.omniverselabs.menu_listo", "expected_sku": "menu_listo_pro_unlock"},
    {"name": "Ritmo: Hábitos & Diario", "package": "com.omniverselabs.ritmo", "expected_sku": "ritmo_pro_unlock"},
    {"name": "Charlemos", "package": "com.omniverselabs.charlemos", "expected_sku": "charlemos_pro_lifetime"},
    {"name": "OmniTrade", "package": "com.omniverselabs.omnitrade", "expected_sku": "omnitrade_pro_lifetime"},
    {"name": "EmpacArte", "package": "com.omniverselabs.empacarte", "expected_sku": "empacarte_pro_unlock"},
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

def format_money(price_obj):
    if not price_obj:
        return "N/A"
    curr = price_obj.get("currencyCode", "")
    units = price_obj.get("units", "0")
    nanos = price_obj.get("nanos", 0)
    val = float(units) + (float(nanos) / 1_000_000_000.0)
    return f"{curr} {val:.2f}"

def check_all_products():
    service = get_oauth_service()
    
    print("=" * 80)
    print("    OMNIVERSE LABS - GOOGLE PLAY IN-APP PRODUCTS AUDIT")
    print("=" * 80)
    
    for app in APPS:
        name = app["name"]
        pkg = app["package"]
        expected_sku = app["expected_sku"]
        
        print(f"\n================================================================================")
        print(f"📦 APP: {name}")
        print(f"   Package ID:   {pkg}")
        print(f"   Expected SKU: {expected_sku}")
        print(f"================================================================================")
        
        try:
            res = service.monetization().onetimeproducts().list(packageName=pkg).execute()
            products = res.get("oneTimeProducts", [])
            
            if not products:
                print("   ⚠️ NO ONE-TIME PRODUCTS FOUND in Google Play Console!")
                continue
                
            for prod in products:
                # product name format: "packages/{pkg}/oneTimeProducts/{productId}"
                full_name = prod.get("name", "")
                prod_id = prod.get("productId", full_name.split("/")[-1])
                match_status = "✅ MATCHES CODE" if prod_id == expected_sku else f"⚠️ MISMATCH (Expected {expected_sku})"
                
                print(f"\n   🔹 Product ID: '{prod_id}'  [{match_status}]")
                
                # Check listings
                listings = prod.get("listings", [])
                print(f"      Listings ({len(listings)} locales):")
                for l in listings:
                    lang = l.get("languageCode")
                    title = l.get("title")
                    desc = l.get("description")
                    print(f"        • [{lang}] \"{title}\" — \"{desc}\"")
                
                # Check purchase options
                p_options = prod.get("purchaseOptions", [])
                if not p_options:
                    print(f"      ⚠️ No purchase options configured!")
                for opt in p_options:
                    opt_id = opt.get("purchaseOptionId")
                    state = opt.get("state", "UNKNOWN")
                    state_icon = "🟢 ACTIVE" if state == "ACTIVE" else f"🔴 {state}"
                    print(f"      Purchase Option: '{opt_id}' | State: {state_icon}")
                    
                    regional_configs = opt.get("regionalPricingAndAvailabilityConfigs", [])
                    print(f"      Regional Coverage: {len(regional_configs)} countries/regions")
                    
                    # Highlight key sample markets
                    sample_markets = ["US", "AR", "BR", "ES", "MX", "GB", "DE", "CO", "CL", "UY"]
                    market_prices = {}
                    for reg in regional_configs:
                        r_code = reg.get("regionCode")
                        if r_code in sample_markets:
                            market_prices[r_code] = (format_money(reg.get("price")), reg.get("availability"))
                    
                    print(f"      Key Market Prices:")
                    for m in sample_markets:
                        if m in market_prices:
                            p_str, avail = market_prices[m]
                            print(f"        - {m}: {p_str} ({avail})")
                    
                    new_reg = opt.get("newRegionsConfig", {})
                    if new_reg:
                        usd = format_money(new_reg.get("usdPrice"))
                        eur = format_money(new_reg.get("eurPrice"))
                        print(f"      Default New Regions Pricing: USD {usd} | EUR {eur}")

        except HttpError as e:
            err_msg = e.content.decode("utf-8") if e.content else str(e)
            print(f"   ❌ HTTP Error: {e.resp.status} - {err_msg}")
        except Exception as e:
            print(f"   ❌ Unexpected Error: {e}")

if __name__ == "__main__":
    check_all_products()
