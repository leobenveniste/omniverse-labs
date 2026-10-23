import os
from PIL import Image, ImageDraw, ImageFont

APPS_DIR = r"c:\Projects\Omniverse Labs\apps\vuelo_controlado_staff"
STORE_DIR = os.path.join(APPS_DIR, "store_assets", "play_store")
os.makedirs(STORE_DIR, exist_ok=True)

LOGO_COLOR_PATH = os.path.join(APPS_DIR, "assets", "images", "logo_color.png")
LOGO_WHITE_PATH = os.path.join(APPS_DIR, "assets", "images", "logo_white.png")

logo_color = Image.open(LOGO_COLOR_PATH).convert("RGBA")
logo_white = Image.open(LOGO_WHITE_PATH).convert("RGBA")

# 1. Generate 512x512 App Icon
icon_size = (512, 512)
icon_img = Image.new("RGBA", icon_size, (13, 13, 17, 255)) # Dark background #0D0D11
icon_draw = ImageDraw.Draw(icon_img)

# Subtle rounded glow border inside
icon_draw.rounded_rectangle([4, 4, 507, 507], radius=90, outline=(0, 255, 42, 60), width=3)

# Resize logo to fit nicely in the center (width ~420px)
target_w = 420
scale = target_w / logo_color.width
target_h = int(logo_color.height * scale)
scaled_logo = logo_color.resize((target_w, target_h), Image.Resampling.LANCZOS)

paste_x = (512 - target_w) // 2
paste_y = (512 - target_h) // 2
icon_img.paste(scaled_logo, (paste_x, paste_y), scaled_logo)

icon_path = os.path.join(STORE_DIR, "icon_512x512.png")
icon_img.save(icon_path, "PNG")
print(f"Generated Icon: {icon_path}")

# 2. Generate 1024x500 Feature Graphic
fg_size = (1024, 500)
fg_img = Image.new("RGBA", fg_size, (13, 13, 17, 255))
fg_draw = ImageDraw.Draw(fg_img)

# Futuristic subtle grid lines with neon tint
for x in range(0, 1024, 40):
    fg_draw.line([(x, 0), (x + 200, 500)], fill=(0, 255, 42, 12), width=1)

# Subtle radial glow in the center
for r in range(250, 0, -25):
    alpha = int(18 * (1 - r / 250))
    fg_draw.ellipse([512 - r, 250 - r, 512 + r, 250 + r], outline=(0, 255, 42, alpha), width=2)

# Place logo in center top
fg_logo_w = 540
fg_scale = fg_logo_w / logo_color.width
fg_logo_h = int(logo_color.height * fg_scale)
fg_logo = logo_color.resize((fg_logo_w, fg_logo_h), Image.Resampling.LANCZOS)

fg_x = (1024 - fg_logo_w) // 2
fg_y = 110
fg_img.paste(fg_logo, (fg_x, fg_y), fg_logo)

# Subtitle badge text
# Try default font or sys font
try:
    font_bold = ImageFont.truetype("arialbd.ttf", 26)
    font_sub = ImageFont.truetype("arial.ttf", 20)
except Exception:
    font_bold = ImageFont.load_default()
    font_sub = ImageFont.load_default()

badge_text = "PORTAL DE STAFF"
badge_bbox = fg_draw.textbbox((0, 0), badge_text, font=font_bold)
bw = badge_bbox[2] - badge_bbox[0]
bh = badge_bbox[3] - badge_bbox[1]

bx = (1024 - bw) // 2
by = fg_y + fg_logo_h + 35
fg_draw.rounded_rectangle([bx - 18, by - 6, bx + bw + 18, by + bh + 8], radius=16, fill=(0, 255, 42, 35), outline=(0, 255, 42, 180), width=1)
fg_draw.text((bx, by - 2), badge_text, font=font_bold, fill=(0, 255, 42, 255))

sub_text = "Gestión Operativa de Guardias & Reducción de Daños"
sub_bbox = fg_draw.textbbox((0, 0), sub_text, font=font_sub)
sw = sub_bbox[2] - sub_bbox[0]
sx = (1024 - sw) // 2
sy = by + bh + 24
fg_draw.text((sx, sy), sub_text, font=font_sub, fill=(180, 180, 195, 255))

fg_png_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.png")
fg_jpg_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.jpg")
fg_img.save(fg_png_path, "PNG")
fg_img.convert("RGB").save(fg_jpg_path, "JPEG", quality=95)
print(f"Generated Feature Graphic: {fg_png_path}")
print(f"Generated Feature Graphic (JPG): {fg_jpg_path}")
