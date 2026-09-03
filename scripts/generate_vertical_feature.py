import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ARTIFACTS_DIR = r"C:\Users\leobe\.gemini\antigravity\brain\42c1dcb7-5fbf-451b-91ce-5d992d2e93a3"
STORE_DIR = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\store"
BG_IMAGE = os.path.join(ARTIFACTS_DIR, "feature_poster_bg_1788441283996.jpg")
APP_ICON_PATH = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\app_icon.png"

TARGET_W, TARGET_H = 1080, 2400

# 1. Load and scale background to exact 1080x2400
with Image.open(BG_IMAGE) as bg_raw:
    w_ratio = TARGET_W / bg_raw.width
    h_ratio = TARGET_H / bg_raw.height
    scale = max(w_ratio, h_ratio)
    new_w = int(bg_raw.width * scale)
    new_h = int(bg_raw.height * scale)
    bg_resized = bg_raw.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    left = (new_w - TARGET_W) // 2
    top = (new_h - TARGET_H) // 2
    bg = bg_resized.crop((left, top, left + TARGET_W, top + TARGET_H)).convert("RGBA")

# 2. Add subtle lighting wash over parchment to ensure high text contrast
wash = Image.new("RGBA", (TARGET_W, TARGET_H), (0, 0, 0, 0))
w_draw = ImageDraw.Draw(wash)
# Center wash area
w_draw.rounded_rectangle(
    [120, 160, TARGET_W - 120, 2150],
    radius=40,
    fill=(254, 252, 246, 175)
)
wash_blurred = wash.filter(ImageFilter.GaussianBlur(30))
bg.alpha_composite(wash_blurred)

# 3. Transparent App Icon (Chef Hat with checkmark)
with Image.open(APP_ICON_PATH) as icon_raw:
    icon_w = 170
    icon_h = int(icon_w * (icon_raw.height / icon_raw.width))
    icon_resized = icon_raw.resize((icon_w, icon_h), Image.Resampling.LANCZOS).convert("RGBA")
    
    icon_x = (TARGET_W - icon_w) // 2
    icon_y = 230
    
    # Soft drop shadow for icon
    icon_shadow = Image.new("RGBA", (TARGET_W, TARGET_H), (0, 0, 0, 0))
    is_draw = ImageDraw.Draw(icon_shadow)
    alpha_mask = icon_resized.split()[3]
    shadow_stamp = Image.new("RGBA", (icon_w, icon_h), (40, 30, 18, 90))
    icon_shadow.paste(shadow_stamp, (icon_x + 3, icon_y + 5), mask=alpha_mask)
    bg.alpha_composite(icon_shadow.filter(ImageFilter.GaussianBlur(10)))
    
    bg.paste(icon_resized, (icon_x, icon_y), mask=icon_resized)

# 4. Typography
draw = ImageDraw.Draw(bg)
font_pill = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 24)
font_hero = ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", 88)
font_subtitle = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 34)
font_desc = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 26)

font_card_title = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 30)
font_card_desc = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 23)
font_footer = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 20)

# Top Pill
pill_text = "ASISTENTE CULINARIO INTEGRAL"
pb = font_pill.getbbox(pill_text)
pw = pb[2] - pb[0] + 44
ph = 48
px = (TARGET_W - pw) // 2
py = 155
draw.rounded_rectangle(
    [px, py, px + pw, py + ph],
    radius=24,
    fill=(228, 240, 222, 255),
    outline=(180, 206, 170, 255),
    width=2
)
draw.text((px + 22, py + 8), pill_text, font=font_pill, fill=(45, 82, 30, 255))

# Title "Menú Listo"
title_text = "Menú Listo"
tb = font_hero.getbbox(title_text)
tw = tb[2] - tb[0]
tx = (TARGET_W - tw) // 2
ty = 420
draw.text((tx, ty), title_text, font=font_hero, fill=(32, 45, 24, 255))

# Subtitle
sub_text = "Recetas · Planificador · Compras"
sb = font_subtitle.getbbox(sub_text)
sw = sb[2] - sb[0]
sx = (TARGET_W - sw) // 2
sy = ty + 115
draw.text((sx, sy), sub_text, font=font_subtitle, fill=(48, 66, 38, 255))

# Tagline phrase
tag_phrase = "La app definitiva para organizar tu cocina diaria"
tpb = font_desc.getbbox(tag_phrase)
tpw = tpb[2] - tpb[0]
tpx = (TARGET_W - tpw) // 2
tpy = sy + 52
draw.text((tpx, tpy), tag_phrase, font=font_desc, fill=(85, 105, 78, 255))

# 5. Feature Highlight Cards (Bento Style)
cards = [
    {
        "badge": "RECETARIO INTELIGENTE",
        "badge_color": (45, 85, 30),
        "badge_bg": (224, 238, 218),
        "title": "Explora y Cocina con lo que Tienes",
        "desc": "Cientos de recetas seleccionadas, filtros por ingredientes de tu heladera y escáner OCR de fotos y libros de cocina.",
    },
    {
        "badge": "PLANIFICADOR SEMANAL",
        "badge_color": (40, 75, 95),
        "badge_bg": (218, 234, 242),
        "title": "Organiza Todas tus Comidas",
        "desc": "Distribuye desayunos, almuerzos, meriendas y cenas día por día. Visualiza el menú completo de un vistazo.",
    },
    {
        "badge": "COMPRAS INTELIGENTES",
        "badge_color": (120, 65, 25),
        "badge_bg": (248, 232, 218),
        "title": "Lista de Súper en 1 Toque",
        "desc": "Generación automática consolidada por góndolas y rubros. Ahorra tiempo y no compres de más.",
    },
    {
        "badge": "MODO COCINA INTERACTIVO",
        "badge_color": (35, 85, 55),
        "badge_bg": (220, 240, 230),
        "title": "Control Manos Libres y Timers",
        "desc": "Pasa los pasos cocinando con gestos sin tocar la pantalla con las manos sucias y con temporizadores activos.",
    },
]

card_w = 840
card_x = (TARGET_W - card_w) // 2
start_card_y = 690
card_spacing = 330

card_layer = Image.new("RGBA", (TARGET_W, TARGET_H), (0, 0, 0, 0))
cl_draw = ImageDraw.Draw(card_layer)

for idx, c in enumerate(cards):
    cy = start_card_y + (idx * card_spacing)
    card_h = 285
    
    # Subtle card drop shadow
    cl_draw.rounded_rectangle(
        [card_x - 2, cy + 8, card_x + card_w + 2, cy + card_h + 10],
        radius=32,
        fill=(30, 42, 22, 35)
    )
    # Card surface
    cl_draw.rounded_rectangle(
        [card_x, cy, card_x + card_w, cy + card_h],
        radius=30,
        fill=(255, 255, 255, 235),
        outline=(225, 236, 220, 255),
        width=2
    )
    
    # Feature pill badge
    f_badge = c["badge"]
    f_bb = font_pill.getbbox(f_badge)
    f_bw = f_bb[2] - f_bb[0] + 32
    f_bh = 40
    cl_draw.rounded_rectangle(
        [card_x + 28, cy + 26, card_x + 28 + f_bw, cy + 26 + f_bh],
        radius=14,
        fill=c["badge_bg"] + (255,),
        outline=(205, 222, 198, 255),
        width=1
    )
    cl_draw.text((card_x + 44, cy + 32), f_badge, font=font_pill, fill=c["badge_color"] + (255,))
    
    # Card Title
    cl_draw.text((card_x + 28, cy + 84), c["title"], font=font_card_title, fill=(28, 38, 22, 255))
    
    # Card Description (wrapped in 2 lines)
    words = c["desc"].split()
    line1, line2 = "", ""
    for w in words:
        test_line = (line1 + " " + w).strip()
        if font_card_desc.getbbox(test_line)[2] < (card_w - 56):
            line1 = test_line
        else:
            line2 = (line2 + " " + w).strip()
            
    cl_draw.text((card_x + 28, cy + 144), line1, font=font_card_desc, fill=(75, 92, 70, 255))
    if line2:
        cl_draw.text((card_x + 28, cy + 180), line2, font=font_card_desc, fill=(75, 92, 70, 255))

bg.alpha_composite(card_layer)

# 6. Bottom Banner / Badges
draw = ImageDraw.Draw(bg)
bottom_card_y = 2030

# Bottom Badge Container
badge_w = 660
badge_x = (TARGET_W - badge_w) // 2
draw.rounded_rectangle(
    [badge_x, bottom_card_y, badge_x + badge_w, bottom_card_y + 60],
    radius=30,
    fill=(236, 244, 232, 240),
    outline=(195, 218, 185, 255),
    width=2
)
badge_text = "100% OFFLINE · SIN ANUNCIOS MOLESTOS · PRIVACIDAD TOTAL"
bb = font_footer.getbbox(badge_text)
bw = bb[2] - bb[0]
draw.text((badge_x + (badge_w - bw) // 2, bottom_card_y + 18), badge_text, font=font_footer, fill=(45, 78, 32, 255))

# Footer Attribution
draw.text((380, 2130), "OMNIVERSE LABS", font=font_footer, fill=(135, 150, 130, 255))

# Save outputs
out_store_png = os.path.join(STORE_DIR, "feature_vertical_1080x2400.png")
out_store_jpg = os.path.join(STORE_DIR, "feature_vertical_1080x2400.jpg")
out_artifact_png = os.path.join(ARTIFACTS_DIR, "feature_vertical_1080x2400.png")

bg.convert("RGB").save(out_store_png, quality=95)
bg.convert("RGB").save(out_store_jpg, quality=95)
bg.convert("RGB").save(out_artifact_png, quality=95)

print("Vertical Feature Image successfully created (1080x2400):")
print(out_store_png)
