import os
import sys
import json
import time

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
PACKAGE_NAME = "com.omniverselabs.circulo"

def get_service():
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

def get_regional_configs(service, usd_units, usd_nanos):
    """Convierte el precio USD a las 174 regiones oficiales de Google Play."""
    body = {
        "price": {
            "currencyCode": "USD",
            "units": str(usd_units),
            "nanos": usd_nanos
        }
    }
    converted = service.monetization().convertRegionPrices(
        packageName=PACKAGE_NAME,
        body=body
    ).execute()

    region_version = converted.get("regionVersion", {}).get("version", "2026/01")
    converted_regions = converted.get("convertedRegionPrices", {})
    other_regions = converted.get("convertedOtherRegionsPrice", {})

    configs = []
    for r_code, r_data in sorted(converted_regions.items()):
        configs.append({
            "regionCode": r_code,
            "price": r_data["price"],
            "availability": "AVAILABLE"
        })

    return configs, other_regions, region_version

def setup_subscription(service):
    sub_id = "circulo_plus"
    print("\n" + "=" * 70)
    print(f"⭐ 1. CONFIGURING SUBSCRIPTION: {sub_id} (Círculo Plus)")
    print("=" * 70)

    # 4 Base Plans con descuentos progresivos
    plans_def = [
        {
            "id": "plus-monthly",
            "period": "P1M",
            "units": 4,
            "nanos": 990000000,
            "legacy": True, # Backward compatibility for legacy Play Billing querySkuDetailsAsync
            "desc": "1 mes ($4.99/mes - Base)"
        },
        {
            "id": "plus-quarterly",
            "period": "P3M",
            "units": 12,
            "nanos": 990000000,
            "legacy": False,
            "desc": "3 meses ($12.99 - $4.33/mes • 13% OFF)"
        },
        {
            "id": "plus-biannual",
            "period": "P6M",
            "units": 22,
            "nanos": 990000000,
            "legacy": False,
            "desc": "6 meses ($22.99 - $3.83/mes • 23% OFF)"
        },
        {
            "id": "plus-annual",
            "period": "P1Y",
            "units": 39,
            "nanos": 990000000,
            "legacy": False,
            "desc": "1 año ($39.99 - $3.33/mes • 33% OFF / 4 meses gratis)"
        },
    ]

    last_region_version = "2026/01"
    base_plans_payload = []
    for p in plans_def:
        print(f"   Converting regional prices for plan [{p['id']}] ({p['desc']})...")
        configs, others, r_ver = get_regional_configs(service, p["units"], p["nanos"])
        last_region_version = r_ver
        
        # Subscriptions API regionalConfigs takes a price object directly
        sub_regional_configs = []
        for c in configs:
            sub_regional_configs.append({
                "regionCode": c["regionCode"],
                "price": c["price"]
            })

        base_plan_obj = {
            "basePlanId": p["id"],
            "autoRenewingBasePlanType": {
                "billingPeriodDuration": p["period"],
                "legacyCompatible": p["legacy"],
                "resubscribeState": "RESUBSCRIBE_STATE_ACTIVE"
            },
            "regionalConfigs": sub_regional_configs
        }
        base_plans_payload.append(base_plan_obj)

    sub_body = {
        "packageName": PACKAGE_NAME,
        "productId": sub_id,
        "listings": [
            {
                "languageCode": "es-419",
                "title": "Círculo Plus",
                "description": "Membresía premium de Círculo: Swipes diarios ilimitados, fotos nítidas en quién te dio like, deshacer swipes, 1 Boost semanal gratis y cero publicidades.",
                "benefits": [
                    "Swipes diarios ilimitados",
                    "Ver quién te dio like con fotos nítidas",
                    "Deshacer (Rewind) swipes ilimitado",
                    "1 Boost semanal gratis y cero anuncios"
                ]
            },
            {
                "languageCode": "en-US",
                "title": "Círculo Plus",
                "description": "Círculo Premium Membership: Unlimited daily swipes, unblurred likes received, unlimited rewinds, 1 free weekly boost, and zero ads.",
                "benefits": [
                    "Unlimited daily swipes",
                    "See who liked you with unblurred photos",
                    "Unlimited swipe rewinds",
                    "1 free weekly boost & zero ads"
                ]
            }
        ],
        "basePlans": base_plans_payload,
        "taxAndComplianceSettings": {
            "eeaWithdrawalRightType": "WITHDRAWAL_RIGHT_DIGITAL_CONTENT"
        }
    }

    # Crear o actualizar suscripción
    try:
        print(f"\n   Creating subscription '{sub_id}' via subscriptions().create()...")
        res = service.monetization().subscriptions().create(
            packageName=PACKAGE_NAME,
            productId=sub_id,
            body=sub_body,
            regionsVersion_version=last_region_version
        ).execute()
        print(f"   ✅ Subscription '{sub_id}' created successfully!")
    except HttpError as e:
        err_str = str(e)
        if "already exists" in err_str or "conflict" in err_str.lower():
            print(f"   ℹ️ Subscription already exists. Updating via subscriptions().patch()...")
            res = service.monetization().subscriptions().patch(
                packageName=PACKAGE_NAME,
                productId=sub_id,
                updateMask="listings,taxAndComplianceSettings",
                body=sub_body,
                regionsVersion_version=last_region_version
            ).execute()
            print(f"   ✅ Subscription '{sub_id}' updated successfully!")
        else:
            raise e

    # Activar cada uno de los 4 base plans
    print("\n   Activating base plans...")
    for p in plans_def:
        bp_id = p["id"]
        try:
            service.monetization().subscriptions().basePlans().activate(
                packageName=PACKAGE_NAME,
                productId=sub_id,
                basePlanId=bp_id,
                body={}
            ).execute()
            print(f"   🟢 Base Plan [{bp_id}] ACTIVATED!")
        except HttpError as act_err:
            print(f"   Notice activating [{bp_id}]: {act_err}")

def setup_onetime_product(service, product_id, title_es, desc_es, title_en, desc_en, usd_units, usd_nanos):
    print("\n" + "=" * 70)
    print(f"🛍️ 2. CONFIGURING ONE-TIME CONSUMABLE: {product_id} (${usd_units}.{usd_nanos//10000000:02d} USD)")
    print("=" * 70)

    configs, others, r_version = get_regional_configs(service, usd_units, usd_nanos)

    prod_body = {
        "packageName": PACKAGE_NAME,
        "productId": product_id,
        "listings": [
            {
                "languageCode": "es-419",
                "title": title_es,
                "description": desc_es
            },
            {
                "languageCode": "en-US",
                "title": title_en,
                "description": desc_en
            }
        ],
        "purchaseOptions": [
            {
                "purchaseOptionId": f"{product_id.replace('_', '-')}-opt",
                "buyOption": {
                    "legacyCompatible": True
                },
                "regionalPricingAndAvailabilityConfigs": configs,
                "newRegionsConfig": {
                    "usdPrice": others.get("usdPrice", {"currencyCode": "USD", "units": str(usd_units), "nanos": usd_nanos}),
                    "eurPrice": others.get("eurPrice", {"currencyCode": "EUR", "units": str(max(1, usd_units - 1)), "nanos": 900000000}),
                    "availability": "AVAILABLE"
                },
                "taxAndComplianceSettings": {
                    "withdrawalRightType": "WITHDRAWAL_RIGHT_DIGITAL_CONTENT"
                }
            }
        ]
    }

    patch_params = {
        "packageName": PACKAGE_NAME,
        "productId": product_id,
        "allowMissing": True,
        "updateMask": "listings,purchaseOptions",
        "body": prod_body,
        "regionsVersion_version": r_version
    }

    try:
        res = service.monetization().onetimeproducts().patch(**patch_params).execute()
        print(f"   🟢 One-time product [{product_id}] saved successfully!")
    except HttpError as err:
        print(f"   ❌ Error saving [{product_id}]: {err}")
        raise err

def main():
    service = get_service()

    # 1. Suscripción Círculo Plus con sus 4 planes
    setup_subscription(service)

    # 2. Los 2 Productos Consumibles (One-time products que se pueden comprar múltiples veces)
    # Consumible 1: Boost de Perfil
    setup_onetime_product(
        service=service,
        product_id="circulo_boost",
        title_es="Perfil Destacado (Boost)",
        desc_es="Multiplica x3 tu visibilidad en el mazo durante 60 minutos con badge en vivo para recibir más postulaciones a círculos.",
        title_en="Profile Boost",
        desc_en="Multiplies your discovery deck visibility by 3x for 60 minutes with a live badge to get more circle applications.",
        usd_units=1,
        usd_nanos=990000000 # $1.99 USD
    )

    # Pack x5 Boosts
    setup_onetime_product(
        service=service,
        product_id="circulo_boost_5",
        title_es="Pack 5x Boosts de Perfil",
        desc_es="Paquete de 5 Perfiles Destacados con 20% de descuento para multiplicar tu visibilidad.",
        title_en="5x Profile Boosts Pack",
        desc_en="Pack of 5 Profile Boosts with 20% discount to multiply your social visibility.",
        usd_units=7,
        usd_nanos=990000000 # $7.99 USD
    )

    # Consumible 2: Super-Onda
    setup_onetime_product(
        service=service,
        product_id="circulo_superonda",
        title_es="Super-Onda",
        desc_es="Envía una señal directa de interés con marco de energía dorada para priorizar tu ingreso al círculo.",
        title_en="Super-Onda",
        desc_en="Send an instant direct interest signal with a golden halo to prioritize your spot in the circle.",
        usd_units=0,
        usd_nanos=990000000 # $0.99 USD
    )

    # Pack x3 Super-Ondas
    setup_onetime_product(
        service=service,
        product_id="circulo_superonda_3",
        title_es="Pack 3x Super-Ondas",
        desc_es="Paquete de 3 Super-Ondas doradas para priorizar tu unión a círculos en formación.",
        title_en="3x Super-Ondas Pack",
        desc_en="Pack of 3 golden Super-Ondas to prioritize your entrance into forming circles.",
        usd_units=2,
        usd_nanos=490000000 # $2.49 USD
    )

    # Pack x10 Super-Ondas
    setup_onetime_product(
        service=service,
        product_id="circulo_superonda_10",
        title_es="Pack 10x Super-Ondas",
        desc_es="Paquete de 10 Super-Ondas con 30% de descuento para máxima conexión social.",
        title_en="10x Super-Ondas Pack",
        desc_en="Pack of 10 Super-Ondas with 30% discount for maximum social connection.",
        usd_units=6,
        usd_nanos=990000000 # $6.99 USD
    )

    print("\n" + "=" * 70)
    print("🎉 ALL MONETIZATION ITEMS CONFIGURED AND PUBLISHED ON GOOGLE PLAY!")
    print("=" * 70)

if __name__ == "__main__":
    main()
