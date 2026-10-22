import os
import sys
import json

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

OAUTH_TOKEN_STORE = os.path.expanduser(r"~\.config\omniverse_labs\play_oauth_token.json")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

PACKAGE_NAME = "com.omniverselabs.omnitrade"
PRODUCT_ID = "omnitrade_pro_lifetime"
PURCHASE_OPTION_ID = "omnitrade-pro"
BASE_PRICE_USD_UNITS = "9"
BASE_PRICE_USD_NANOS = 990000000

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

def setup_omnitrade_product():
    service = get_oauth_service()
    
    print("=" * 80)
    print("🚀 CONFIGURING ONE-TIME PRODUCT FOR OMNITRADE")
    print(f"📦 Package: {PACKAGE_NAME}")
    print(f"🔹 Product ID: {PRODUCT_ID}")
    print(f"🔹 Option ID:  {PURCHASE_OPTION_ID}")
    print(f"💵 Base Price: ${BASE_PRICE_USD_UNITS}.{BASE_PRICE_USD_NANOS // 10000000:02d} USD")
    print("=" * 80)

    # 1. Convert regional prices using Google Play exchange rates & local rounding
    print("\n1️⃣ Converting regional prices via Google Play API...")
    convert_body = {
        "price": {
            "currencyCode": "USD",
            "units": BASE_PRICE_USD_UNITS,
            "nanos": BASE_PRICE_USD_NANOS
        }
    }
    
    converted = service.monetization().convertRegionPrices(
        packageName=PACKAGE_NAME,
        body=convert_body
    ).execute()

    region_version = converted.get("regionVersion", {}).get("version", "2026/01")
    converted_regions = converted.get("convertedRegionPrices", {})
    other_regions = converted.get("convertedOtherRegionsPrice", {})
    
    print(f"   ✅ Converted prices for {len(converted_regions)} regions (Version: {region_version})")

    # Build regional configs
    regional_configs = []
    for r_code, r_data in sorted(converted_regions.items()):
        regional_configs.append({
            "regionCode": r_code,
            "price": r_data["price"],
            "availability": "AVAILABLE"
        })

    # 2. Prepare listings and purchase option
    product_body = {
        "packageName": PACKAGE_NAME,
        "productId": PRODUCT_ID,
        "listings": [
            {
                "languageCode": "es-419",
                "title": "OmniTrade PRO - Desbloqueo Vitalicio",
                "description": "Acceso vitalicio: registro ilimitado de operaciones, analíticas y métricas institucionales avanzadas, curva de equidad y exportación total a CSV/JSON. Pago único sin suscripciones."
            },
            {
                "languageCode": "en-US",
                "title": "OmniTrade PRO - Lifetime Access",
                "description": "Lifetime unlock: unlimited trade logging, institutional performance analytics, equity curve, and full CSV/JSON data export. One-time payment, no subscriptions."
            }
        ],
        "purchaseOptions": [
            {
                "purchaseOptionId": PURCHASE_OPTION_ID,
                "buyOption": {
                    "legacyCompatible": True
                },
                "regionalPricingAndAvailabilityConfigs": regional_configs,
                "newRegionsConfig": {
                    "usdPrice": other_regions.get("usdPrice", {"currencyCode": "USD", "units": "9", "nanos": 990000000}),
                    "eurPrice": other_regions.get("eurPrice", {"currencyCode": "EUR", "units": "8", "nanos": 900000000}),
                    "availability": "AVAILABLE"
                },
                "taxAndComplianceSettings": {
                    "withdrawalRightType": "WITHDRAWAL_RIGHT_DIGITAL_CONTENT"
                }
            }
        ]
    }

    # 3. Patch / Create product
    print("\n2️⃣ Upserting one-time product via monetization API...")
    patch_params = {
        "packageName": PACKAGE_NAME,
        "productId": PRODUCT_ID,
        "allowMissing": True,
        "updateMask": "listings,purchaseOptions",
        "body": product_body,
        "regionsVersion_version": region_version
    }
    
    try:
        created_prod = service.monetization().onetimeproducts().patch(**patch_params).execute()
        print(f"   ✅ One-time product successfully saved! Product ID: {created_prod.get('productId')}")
    except HttpError as e:
        print(f"   ❌ Error saving product: {e.resp.status} - {e.content.decode('utf-8') if e.content else e}")
        return False

    # 4. Activate Purchase Option
    print(f"\n3️⃣ Activating purchase option '{PURCHASE_OPTION_ID}'...")
    activate_body = {
        "requests": [
            {
                "activatePurchaseOptionRequest": {
                    "packageName": PACKAGE_NAME,
                    "productId": PRODUCT_ID,
                    "purchaseOptionId": PURCHASE_OPTION_ID
                }
            }
        ]
    }

    try:
        act_res = service.monetization().onetimeproducts().purchaseOptions().batchUpdateStates(
            packageName=PACKAGE_NAME,
            productId=PRODUCT_ID,
            body=activate_body
        ).execute()
        print(f"   ✅ Purchase option successfully ACTIVATED!")
    except HttpError as e:
        print(f"   ❌ Error activating purchase option: {e.resp.status} - {e.content.decode('utf-8') if e.content else e}")
        return False

    print("\n🎉 SETUP COMPLETED SUCCESSFULLY!")
    return True

if __name__ == "__main__":
    setup_omnitrade_product()
