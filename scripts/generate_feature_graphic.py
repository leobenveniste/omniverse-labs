import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ARTIFACTS_DIR = r"C:\Users\leobe\.gemini\antigravity\brain\42c1dcb7-5fbf-451b-91ce-5d992d2e93a3"
STORE_DIR = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\store"
FEATURE_BG = os.path.join(ARTIFACTS_DIR, "menu_listo_feature_1788439824065.jpg")
APP_ICON_PATH = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\app_icon.png"

TARGET_W, TARGET_H = 1024, 500

# 1. Background image
with Image.open(FEATURE_BG) as bg_raw:
    w_ratio = TARGET_W / bg_raw.width
    h_ratio = TARGET_H / bg_raw.height
    scale = max(w_ratio, h_ratio)
    new_w = int(bg_raw.width * scale)
    new_h = int(bg_raw.height * scale)
    bg_resized = bg_raw.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    left = (new_w - TARGET_W) // 2
    top = (new_h - TARGET_H) // 2
    bg = bg_resized.crop((left, top, left + TARGET_W, top + TARGET_H)).convert("RGBA")

# 2. Add subtle warm parchment wash on the left to maximize text legibility
wash = Image.new("RGBA", (TARGET_W, TARGET_H), (0, 0, 0, 0))
w_draw = ImageDraw.Draw(wash)
for x in range(650):
    factor = 1.0 - (x / 650.0)
    alpha = int(90 * factor * factor)
    w_draw.line([(x, 0), (x, TARGET_H)], fill=(252, 250, 244, alpha))
bg.alpha_composite(wash)

# 3. Transparent App Icon (Chef Hat with checkmark)
with Image.open(APP_ICON_PATH) as icon_raw:
    icon_w = 115
    icon_h = int(icon_w * (icon_raw.height / icon_raw.width))
    icon_resized = icon_raw.resize((icon_w, icon_h), Image.Resampling.LANCZOS).convert("RGBA")
    
    # Soft drop shadow for icon
    icon_shadow = Image.new("RGBA", (TARGET_W, TARGET_H), (0, 0, 0, 0))
    is_draw = ImageDraw.Draw(icon_shadow)
    # Mask icon alpha for shadow
    alpha_mask = icon_resized.split()[3]
    shadow_stamp = Image.new("RGBA", (icon_w, icon_h), (50, 35, 20, 90))
    icon_shadow.paste(shadow_stamp, (72, 62), mask=alpha_mask)
    bg.alpha_composite(icon_shadow.filter(ImageFilter.GaussianBlur(6)))
    
    # Paste clean transparent icon
    bg.paste(icon_resized, (70, 58), mask=icon_resized)

# 4. Typography
draw = ImageDraw.Draw(bg)
font_title = ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", 68)
font_subtitle = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 24)
font_features = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
font_tag = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 15)

# Pill tag
tag_text = "ASISTENTE CULINARIO INTEGRAL"
tag_bbox = font_tag.getbbox(tag_text)
tag_w = tag_bbox[2] - tag_bbox[0] + 26
tag_h = 32
tag_x, tag_y = 205, 75
draw.rounded_rectangle(
    [tag_x, tag_y, tag_x + tag_w, tag_y + tag_h],
    radius=16,
    fill=(225, 238, 218, 255),
    outline=(180, 206, 170, 255),
    width=1
)
draw.text((tag_x + 13, tag_y + 6), tag_text, font=font_tag, fill=(45, 82, 30, 255))

# Title
title_text = "Menú Listo"
draw.text((70, 195), title_text, font=font_title, fill=(35, 48, 26, 255))

# Subtitle
sub_text = "Recetas · Planificador Semanal · Compras Inteligentes"
draw.text((72, 285), sub_text, font=font_subtitle, fill=(50, 68, 42, 255))

# Feature Pills row
features = ["Modo Manos Libres", "Escáner OCR", "Porciones Dinámicas", "100% Offline"]
cur_x = 72
pill_y = 335
for feat in features:
    fb = font_features.getbbox(feat)
    fw = fb[2] - fb[0] + 24
    fh = 34
    draw.rounded_rectangle(
        [cur_x, pill_y, cur_x + fw, pill_y + fh],
        radius=17,
        fill=(245, 248, 242, 230),
        outline=(205, 220, 198, 255),
        width=1
    )
    draw.text((cur_x + 12, pill_y + 6), feat, font=font_features, fill=(60, 80, 52, 255))
    cur_x += fw + 10

# Bottom Omniverse Labs mark
font_brand = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 14)
draw.text((74, 430), "OMNIVERSE LABS", font=font_brand, fill=(130, 145, 125, 255))

# Save outputs
out_store_png = os.path.join(STORE_DIR, "feature_graphic_v2_1024x500.png")
out_store_jpg = os.path.join(STORE_DIR, "feature_graphic_v2_1024x500.jpg")
out_artifact_png = os.path.join(ARTIFACTS_DIR, "feature_graphic_v2_1024x500.png")

bg.convert("RGB").save(out_store_png)
bg.convert("RGB").save(out_store_jpg, quality=95)
bg.convert("RGB").save(out_artifact_png)

print("Regenerated polished feature graphic successfully!")
