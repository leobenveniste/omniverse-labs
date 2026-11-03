import os
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

WORKSPACE_DIR = r"C:\Projects\Omniverse Labs"
CIRCULO_DIR = os.path.join(WORKSPACE_DIR, "apps", "circulo")
STORE_ASSETS_DIR = os.path.join(CIRCULO_DIR, "store_assets")
ASSETS_IMG_DIR = os.path.join(CIRCULO_DIR, "assets", "images")
FONTS_DIR = os.path.join(WORKSPACE_DIR, "fonts")

SRC_ORIGINAL = os.path.join(ASSETS_IMG_DIR, "logo_original.png")
SRC_TRANSPARENT_CROPPED = os.path.join(ASSETS_IMG_DIR, "logo_transparent_cropped.png")
SRC_TRANSPARENT = os.path.join(ASSETS_IMG_DIR, "logo_transparent.png")

os.makedirs(ASSETS_IMG_DIR, exist_ok=True)
os.makedirs(STORE_ASSETS_DIR, exist_ok=True)

img_orig = Image.open(SRC_ORIGINAL).convert("RGB")
img_trans_cropped = Image.open(SRC_TRANSPARENT_CROPPED).convert("RGBA")
img_trans = Image.open(SRC_TRANSPARENT).convert("RGBA")

# 1. Standard in-app logo files
img_trans.save(os.path.join(ASSETS_IMG_DIR, "logo.png"), "PNG")
img_trans_cropped.save(os.path.join(ASSETS_IMG_DIR, "logo_cropped.png"), "PNG")
img_orig.save(os.path.join(ASSETS_IMG_DIR, "logo_with_bg.png"), "PNG")
print("✅ In-app logos saved in assets/images/")

# 2. Store Icon 512x512
icon_512 = img_orig.resize((512, 512), Image.Resampling.LANCZOS)
icon_512_path = os.path.join(STORE_ASSETS_DIR, "icon_512x512.png")
icon_512.save(icon_512_path, "PNG")
print(f"✅ Store icon 512x512 saved: {icon_512_path}")

# 3. Android Mipmap Launcher Icons
android_res_dir = os.path.join(CIRCULO_DIR, "android", "app", "src", "main", "res")
mipmaps = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in mipmaps.items():
    target_dir = os.path.join(android_res_dir, folder)
    os.makedirs(target_dir, exist_ok=True)
    resized_icon = img_orig.resize((size, size), Image.Resampling.LANCZOS)
    resized_icon.save(os.path.join(target_dir, "ic_launcher.png"), "PNG")
    print(f"✅ Android {folder} ({size}x{size}) saved")

# 4. Web Icons
web_icons_dir = os.path.join(CIRCULO_DIR, "web", "icons")
os.makedirs(web_icons_dir, exist_ok=True)
img_orig.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")
img_orig.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")
img_orig.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-maskable-192.png"), "PNG")
img_orig.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-maskable-512.png"), "PNG")
img_orig.resize((48, 48), Image.Resampling.LANCZOS).save(os.path.join(CIRCULO_DIR, "web", "favicon.png"), "PNG")
print("✅ Web icons & favicon saved")

# 5. iOS AppIcon
ios_icon_dir = os.path.join(CIRCULO_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(ios_icon_dir):
    img_orig.resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(ios_icon_dir, "Icon-App-1024x1024@1x.png"), "PNG")
    print("✅ iOS 1024x1024 icon saved")

# 6. Feature Graphic 1024x500
fw, fh = 1024, 500
feat = Image.new("RGBA", (fw, fh), (15, 13, 21, 255))
fdraw = ImageDraw.Draw(feat)

# Gradiente de fondo con iluminación ambiental
f_halo = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
fh_draw = ImageDraw.Draw(f_halo)
fh_draw.ellipse([fw - 480, -50, fw + 100, fh + 50], fill=(124, 58, 237, 70))
fh_draw.ellipse([-100, -100, 400, 300], fill=(244, 63, 94, 40))
f_halo = f_halo.filter(ImageFilter.GaussianBlur(80))
feat = Image.alpha_composite(feat, f_halo)
fdraw = ImageDraw.Draw(feat)

# Insertar el nuevo logo 3D estilizado a la derecha
logo_size = 420
logo_resized = img_trans_cropped.resize((int(logo_size * 0.71), logo_size), Image.Resampling.LANCZOS)
logo_x = fw - 380
logo_y = (fh - logo_size) // 2
feat.paste(logo_resized, (logo_x, logo_y), logo_resized)
fdraw = ImageDraw.Draw(feat)

# Cargar fuentes para el Feature Graphic
def get_font(name, size):
    candidates = [
        os.path.join(FONTS_DIR, name),
        os.path.join(r"C:\Windows\Fonts", name),
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    for fb in ["segoeuib.ttf", "arialbd.ttf", "segoeui.ttf"]:
        fp = os.path.join(r"C:\Windows\Fonts", fb)
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

f_tag = get_font("PlusJakartaSans.ttf", 16)
f_h1 = get_font("ClashGrotesk-Bold.ttf", 64)
f_sub = get_font("montserrat.ttf", 22)
f_badge = get_font("montserrat.ttf", 15)

# Textos a la izquierda
# Pill Omniverse Labs
fdraw.rounded_rectangle([60, 68, 260, 102], radius=12, fill=(124, 58, 237, 40), outline=(124, 58, 237), width=1)
fdraw.text((76, 76), "OMNIVERSE LABS", font=f_tag, fill=(196, 181, 253))

# Título Principal
fdraw.text((60, 120), "Círculo", font=f_h1, fill=(255, 255, 255))

# Subtítulo y propuesta de valor
fdraw.text((60, 215), "Amigos reales en grupos de 4 a 10 personas", font=f_sub, fill=(243, 244, 246))
fdraw.text((60, 248), "Chau a las citas individuales. Hola a planes reales.", font=f_sub, fill=(196, 181, 253))

# 4 Badges de pilares
badges = [
    ("🎯 Match Grupal 4/4", 60, 330, (244, 63, 94)),
    ("👥 Modo Dupla", 250, 330, (245, 158, 11)),
    ("📍 Salidas Reales", 410, 330, (16, 185, 129)),
    ("☕ Química de Roles", 590, 330, (6, 182, 212)),
]
for text, bx, by, col in badges:
    fdraw.rounded_rectangle([bx, by, bx + 160, by + 36], radius=10, fill=(35, 30, 48), outline=col, width=1)
    fdraw.text((bx + 12, by + 8), text, font=f_badge, fill=(255, 255, 255))

feat_path = os.path.join(STORE_ASSETS_DIR, "feature_graphic_1024x500.png")
feat.convert("RGB").save(feat_path, "PNG")
print(f"✅ Feature graphic 1024x500 saved: {feat_path}")
