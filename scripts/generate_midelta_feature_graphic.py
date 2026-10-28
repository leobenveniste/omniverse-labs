import os
import sys
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

W, H = 1024, 500
FONTS_DIR = r"c:\Projects\Omniverse Labs\fonts"
ICON_PATH = r"c:\Projects\Omniverse Labs\apps\mi_delta\assets\store\icon_512x512.png"

STORE_OUT_1 = r"c:\Projects\Omniverse Labs\apps\mi_delta\assets\store"
STORE_OUT_2 = r"c:\Projects\Omniverse Labs\apps\mi_delta\store_assets\play_store"
os.makedirs(STORE_OUT_1, exist_ok=True)
os.makedirs(STORE_OUT_2, exist_ok=True)

def get_font(name, size):
    candidates = [
        os.path.join(FONTS_DIR, name),
        os.path.join(r"C:\Windows\Fonts", name),
    ]
    for p in candidates:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    # Fallback
    for fb in ["segoeuib.ttf", "arialbd.ttf", "segoeui.ttf", "arial.ttf"]:
        p = os.path.join(r"C:\Windows\Fonts", fb)
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

font_title = get_font("PlusJakartaSans.ttf", 62)
font_subtitle = get_font("PlusJakartaSans.ttf", 20)
font_tag = get_font("PlusJakartaSans.ttf", 13)
font_pill = get_font("PlusJakartaSans.ttf", 15)
font_card_title = get_font("PlusJakartaSans.ttf", 16)
font_card_body = get_font("PlusJakartaSans.ttf", 13)
font_card_code = get_font("PlusJakartaSans.ttf", 11)
font_brand = get_font("PlusJakartaSans.ttf", 13)

# 1. Base Gradient Canvas (Rich Civic Navy with luminous teal undertones)
canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
base_draw = ImageDraw.Draw(canvas)

# Radial / diagonal gradient simulation
for y in range(H):
    for x in range(W):
        # Diagonal factor
        diag = (x * 0.7 + y * 0.3) / (W * 0.7 + H * 0.3)
        # Glow center around (750, 200)
        dist_glow = math.hypot(x - 780, y - 180) / 600.0
        glow_factor = max(0.0, 1.0 - dist_glow)
        
        # Deep navy colors: #031527 to #09345D
        r = int((3 * (1 - diag) + 12 * diag) * (1 - glow_factor * 0.3) + 0 * glow_factor)
        g = int((21 * (1 - diag) + 52 * diag) * (1 - glow_factor * 0.4) + 60 * glow_factor)
        b = int((39 * (1 - diag) + 93 * diag) * (1 - glow_factor * 0.4) + 110 * glow_factor)
        
        canvas.putpixel((x, y), (min(255, r), min(255, g), min(255, b), 255))

# 2. Draw Decorative Delta River Waves in the background
wave_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
wave_draw = ImageDraw.Draw(wave_overlay)

def bezier_curve(p0, p1, p2, p3, steps=100):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1-t)**3 * p0[0] + 3*(1-t)**2*t * p1[0] + 3*(1-t)*t**2 * p2[0] + t**3 * p3[0]
        y = (1-t)**3 * p0[1] + 3*(1-t)**2*t * p1[1] + 3*(1-t)*t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts

# Flowing river bands
curve1 = bezier_curve((-100, 380), (300, 480), (600, 290), (1150, 360))
curve2 = bezier_curve((-100, 420), (320, 520), (620, 330), (1150, 400))
curve3 = bezier_curve((-100, 460), (340, 560), (640, 370), (1150, 440))

wave_draw.line(curve1, fill=(0, 200, 140, 35), width=28, joint="curve")
wave_draw.line(curve2, fill=(2, 132, 199, 40), width=36, joint="curve")
wave_draw.line(curve3, fill=(0, 168, 112, 30), width=44, joint="curve")

# Soft glow filter on waves
wave_overlay = wave_overlay.filter(ImageFilter.GaussianBlur(12))
canvas.alpha_composite(wave_overlay)

# Add delicate grid / architectural tech dots on top-right
dots_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
dots_draw = ImageDraw.Draw(dots_overlay)
for gx in range(540, 1000, 32):
    for gy in range(30, 220, 32):
        dots_draw.ellipse([gx, gy, gx + 2, gy + 2], fill=(255, 255, 255, 30))
canvas.alpha_composite(dots_overlay)

# 3. Create Left Section: App Logo + Title + Tagline + Feature Badges
# Load & stamp App Icon
if os.path.exists(ICON_PATH):
    with Image.open(ICON_PATH) as icon_raw:
        icon_size = 88
        icon_resized = icon_raw.resize((icon_size, icon_size), Image.Resampling.LANCZOS).convert("RGBA")
        
        # Shadow for icon
        icon_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        is_draw = ImageDraw.Draw(icon_shadow)
        mask_a = icon_resized.split()[3]
        shadow_stamp = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 160))
        icon_shadow.paste(shadow_stamp, (56, 52), mask=mask_a)
        canvas.alpha_composite(icon_shadow.filter(ImageFilter.GaussianBlur(10)))
        
        # Paste Icon
        canvas.paste(icon_resized, (56, 48), mask=icon_resized)

draw = ImageDraw.Draw(canvas)

# Top Eyebrow Pill
eyebrow_text = "PORTAL CIUDADANO OFICIAL"
eb_box = font_tag.getbbox(eyebrow_text)
eb_w = eb_box[2] - eb_box[0] + 32
eb_h = 28
eb_x = 162
eb_y = 50

# Pill background
draw.rounded_rectangle([eb_x, eb_y, eb_x + eb_w, eb_y + eb_h], radius=14, fill=(0, 168, 112, 50), outline=(0, 200, 140, 190), width=1)
# Green pulse dot
draw.ellipse([eb_x + 11, eb_y + 9, eb_x + 20, eb_y + 18], fill=(0, 230, 150, 255))
# Text
draw.text((eb_x + 26, eb_y + 5), eyebrow_text, font=font_tag, fill=(220, 255, 240, 255))

# App Name: Mi Delta
title_text = "Mi Delta"
draw.text((162, 82), title_text, font=font_title, fill=(255, 255, 255, 255))

# Subtitle (2 clean lines with excellent contrast & spacing)
draw.text((58, 158), "Portal Ciudadano & Gestión Municipal", font=font_subtitle, fill=(255, 255, 255, 245))
draw.text((58, 186), "Trámites, turnos y servicios en tus manos", font=get_font("PlusJakartaSans.ttf", 17), fill=(160, 198, 232, 230))

# Feature Highlights: 4 Pills (2 rows of 2)
pills_data = [
    ("Credencial Digital", "Soy Delta con QR", "id"),
    ("Turnos & Trámites", "Gestión online", "cal"),
    ("Reporte Reclamos", "Con foto y mapa", "bolt"),
    ("Botón SOS 103", "Emergencias directas", "sos"),
]

pill_start_x = 58
pill_start_y = 232
pill_w = 210
pill_h = 60

for idx, (p_title, p_sub, p_type) in enumerate(pills_data):
    row = idx // 2
    col = idx % 2
    px = pill_start_x + col * (pill_w + 14)
    py = pill_start_y + row * (pill_h + 12)
    
    # Pill background
    is_active = (idx == 0)
    bg_fill = (12, 38, 68, 220)
    border_col = (0, 200, 140, 180) if is_active else (40, 85, 130, 140)
    draw.rounded_rectangle(
        [px, py, px + pill_w, py + pill_h],
        radius=14,
        fill=bg_fill,
        outline=border_col,
        width=1
    )
    
    # Custom drawn vector icon circle
    ic_cx, ic_cy = px + 24, py + 30
    ic_r = 13
    icon_col = (0, 200, 140) if p_type in ["id", "bolt"] else ((2, 132, 199) if p_type == "cal" else (239, 68, 68))
    draw.ellipse([ic_cx - ic_r, ic_cy - ic_r, ic_cx + ic_r, ic_cy + ic_r], fill=(icon_col[0], icon_col[1], icon_col[2], 50), outline=icon_col + (220,), width=1)
    
    # Mini icon symbol
    if p_type == "id":
        draw.rounded_rectangle([ic_cx - 6, ic_cy - 5, ic_cx + 6, ic_cy + 5], radius=2, outline=(255, 255, 255, 230), width=1)
        draw.ellipse([ic_cx - 3, ic_cy - 3, ic_cx - 1, ic_cy - 1], fill=(255, 255, 255, 230))
        draw.line([(ic_cx + 1, ic_cy - 2), (ic_cx + 4, ic_cy - 2)], fill=(255, 255, 255, 200), width=1)
        draw.line([(ic_cx + 1, ic_cy + 1), (ic_cx + 4, ic_cy + 1)], fill=(255, 255, 255, 200), width=1)
    elif p_type == "cal":
        draw.rounded_rectangle([ic_cx - 6, ic_cy - 6, ic_cx + 6, ic_cy + 6], radius=2, outline=(255, 255, 255, 230), width=1)
        draw.rectangle([ic_cx - 6, ic_cy - 6, ic_cx + 6, ic_cy - 2], fill=(2, 132, 199, 255))
        draw.point((ic_cx - 2, ic_cy + 1), fill=(255, 255, 255, 255))
        draw.point((ic_cx + 2, ic_cy + 1), fill=(255, 255, 255, 255))
    elif p_type == "bolt":
        draw.line([(ic_cx + 1, ic_cy - 6), (ic_cx - 3, ic_cy), (ic_cx, ic_cy), (ic_cx - 1, ic_cy + 6), (ic_cx + 4, ic_cy - 1), (ic_cx + 1, ic_cy - 1)], fill=(255, 215, 0, 255), width=2)
    elif p_type == "sos":
        draw.line([(ic_cx, ic_cy - 5), (ic_cx, ic_cy + 1)], fill=(255, 255, 255, 255), width=2)
        draw.point((ic_cx, ic_cy + 4), fill=(255, 255, 255, 255))

    draw.text((px + 45, py + 12), p_title, font=font_pill, fill=(255, 255, 255, 255))
    draw.text((px + 45, py + 33), p_sub, font=font_card_code, fill=(160, 195, 230, 220))

# Bottom Brand Footprint
draw.text((58, 436), "OMNIVERSE LABS · MUNICIPIO CONECTADO · TIGRE & DELTA", font=font_brand, fill=(110, 155, 195, 180))


# 4. Right Section: Showcase Cards (Credencial Card + Notification / Reclamo Card + Turno Card)
cards_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
c_draw = ImageDraw.Draw(cards_layer)

# --- CARD A: Credencial Digital Soy Delta (Hero Card) ---
c_w, c_h = 390, 225
c_x, c_y = 575, 70

# Card base gradient (Civic emerald-navy with gold delta emblem)
card_img = Image.new("RGBA", (c_w, c_h), (0, 0, 0, 0))
card_draw = ImageDraw.Draw(card_img)

for cy in range(c_h):
    ratio = cy / c_h
    r = int(2 * (1 - ratio) + 0 * ratio)
    g = int(45 * (1 - ratio) + 95 * ratio)
    b = int(85 * (1 - ratio) + 65 * ratio)
    card_draw.line([(0, cy), (c_w, cy)], fill=(r, g, b, 255))

# Golden Sun & subtle waves watermark placed carefully on bottom/right without overlapping texts
card_draw.ellipse([c_w - 75, -45, c_w + 35, 65], fill=(251, 191, 36, 45))
card_draw.arc([c_w - 140, 50, c_w + 100, 290], start=180, end=340, fill=(0, 230, 150, 40), width=16)

# Clip card to rounded rectangle
mask_card = Image.new("L", (c_w, c_h), 0)
ImageDraw.Draw(mask_card).rounded_rectangle([0, 0, c_w, c_h], radius=18, fill=255)
card_img.putalpha(mask_card)

# Border around card
card_draw_border = ImageDraw.Draw(card_img)
card_draw_border.rounded_rectangle([0, 0, c_w - 1, c_h - 1], radius=18, outline=(0, 210, 150, 180), width=2)

# Card Content
card_text_draw = ImageDraw.Draw(card_img)
# Header: Mi Delta Soy Delta
card_text_draw.text((22, 18), "CREDENCIAL DIGITAL", font=font_tag, fill=(180, 240, 215, 255))
card_text_draw.text((22, 38), "SOY DELTA", font=get_font("PlusJakartaSans.ttf", 24), fill=(255, 255, 255, 255))

# Citizen photo avatar box
avatar_box = [22, 85, 78, 145]
card_text_draw.rounded_rectangle(avatar_box, radius=12, fill=(255, 255, 255, 25), outline=(255, 255, 255, 100), width=1)
# Avatar silhouette
card_text_draw.ellipse([35, 95, 65, 125], fill=(255, 255, 255, 180))
card_text_draw.arc([26, 120, 74, 155], start=0, end=180, fill=(255, 255, 255, 180), width=8)

# Citizen details
card_text_draw.text((92, 86), "JUAN MANUEL PÉREZ", font=get_font("PlusJakartaSans.ttf", 15), fill=(255, 255, 255, 255))
card_text_draw.text((92, 108), "DNI: 34.892.104 · VECINO DELTA", font=font_card_code, fill=(200, 230, 245, 220))
card_text_draw.text((92, 126), "ESTADO: VERIFICADO OFICIAL", font=font_card_code, fill=(0, 230, 160, 255))

# QR Code simulated representation
qr_x, qr_y, qr_s = c_w - 82, 86, 62
card_text_draw.rounded_rectangle([qr_x, qr_y, qr_x + qr_s, qr_y + qr_s], radius=8, fill=(255, 255, 255, 245))
# QR pattern mock dots
qr_d = ImageDraw.Draw(card_img)
for qxi in range(4):
    for qyi in range(4):
        if (qxi + qyi) % 2 == 0 or (qxi == 0 and qyi == 0) or (qxi == 3 and qyi == 3):
            qr_d.rectangle([qr_x + 8 + qxi * 12, qr_y + 8 + qyi * 12, qr_x + 16 + qxi * 12, qr_y + 16 + qyi * 12], fill=(2, 34, 68, 255))

# Card footer bar
card_text_draw.rounded_rectangle([0, c_h - 40, c_w, c_h], radius=0, fill=(1, 35, 60, 210))
card_text_draw.text((22, c_h - 28), "MUNICIPIO DE TIGRE & DELTA · VIGENCIA 2026", font=font_card_code, fill=(160, 205, 225, 200))

# Drop Shadow for Card A
shadow_a = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow_a).rounded_rectangle([c_x + 4, c_y + 12, c_x + c_w + 4, c_y + c_h + 12], radius=22, fill=(0, 0, 0, 160))
canvas.alpha_composite(shadow_a.filter(ImageFilter.GaussianBlur(16)))
canvas.paste(card_img, (c_x, c_y), mask=card_img)


# --- CARD B: Reclamo Resuelto Floating Pill (overlapping lower left of showcase) ---
b_w, b_h = 320, 72
b_x, b_y = 530, 320

card_b = Image.new("RGBA", (b_w, b_h), (0, 0, 0, 0))
ImageDraw.Draw(card_b).rounded_rectangle([0, 0, b_w, b_h], radius=16, fill=(8, 28, 52, 245), outline=(0, 200, 140, 160), width=1)
# Green check icon circle
ImageDraw.Draw(card_b).ellipse([16, 18, 52, 54], fill=(0, 168, 112, 60), outline=(0, 220, 150, 255), width=2)
# Draw checkmark
ImageDraw.Draw(card_b).line([(26, 36), (32, 42), (43, 29)], fill=(0, 230, 160, 255), width=3)
# Texts
ImageDraw.Draw(card_b).text((64, 16), "Reclamo #1094: Resuelto", font=font_card_title, fill=(255, 255, 255, 255))
ImageDraw.Draw(card_b).text((64, 38), "Alumbrado reparado · Hace 20 min", font=font_card_code, fill=(170, 210, 235, 220))

# Shadow for Card B
shadow_b = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow_b).rounded_rectangle([b_x + 2, b_y + 8, b_x + b_w + 2, b_y + b_h + 8], radius=18, fill=(0, 0, 0, 170))
canvas.alpha_composite(shadow_b.filter(ImageFilter.GaussianBlur(14)))
canvas.paste(card_b, (b_x, b_y), mask=card_b)


# --- CARD C: Turno Confirmado Floating Pill (overlapping lower right) ---
c2_w, c2_h = 300, 72
c2_x, c2_y = 695, 395

card_c = Image.new("RGBA", (c2_w, c2_h), (0, 0, 0, 0))
ImageDraw.Draw(card_c).rounded_rectangle([0, 0, c2_w, c2_h], radius=16, fill=(10, 36, 66, 245), outline=(2, 132, 199, 160), width=1)
# Calendar icon circle
ImageDraw.Draw(card_c).ellipse([16, 18, 52, 54], fill=(2, 132, 199, 50), outline=(56, 189, 248, 255), width=2)
# Mini calendar icon drawing
ImageDraw.Draw(card_c).rounded_rectangle([25, 28, 43, 44], radius=2, fill=(255, 255, 255, 220))
ImageDraw.Draw(card_c).rectangle([25, 28, 43, 32], fill=(2, 132, 199, 255))
# Texts
ImageDraw.Draw(card_c).text((64, 16), "Turno Confirmado", font=font_card_title, fill=(255, 255, 255, 255))
ImageDraw.Draw(card_c).text((64, 38), "Renovación Licencia · Mañana 10:30", font=font_card_code, fill=(170, 210, 235, 220))

# Shadow for Card C
shadow_c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow_c).rounded_rectangle([c2_x + 2, c2_y + 8, c2_x + c2_w + 2, c2_y + c2_h + 8], radius=18, fill=(0, 0, 0, 180))
canvas.alpha_composite(shadow_c.filter(ImageFilter.GaussianBlur(14)))
canvas.paste(card_c, (c2_x, c2_y), mask=card_c)

# 5. Export to PNG and JPG (both store listing standards)
final_rgb = canvas.convert("RGB")

out_png_1 = os.path.join(STORE_OUT_1, "feature_graphic_1024x500.png")
out_jpg_1 = os.path.join(STORE_OUT_1, "feature_graphic_1024x500.jpg")
out_png_2 = os.path.join(STORE_OUT_2, "feature_graphic_1024x500.png")
out_jpg_2 = os.path.join(STORE_OUT_2, "feature_graphic_1024x500.jpg")

final_rgb.save(out_png_1, "PNG", optimize=True)
final_rgb.save(out_jpg_1, "JPEG", quality=95, optimize=True)
final_rgb.save(out_png_2, "PNG", optimize=True)
final_rgb.save(out_jpg_2, "JPEG", quality=95, optimize=True)

print(f"✅ Generated 1024x500 Feature Graphic successfully!")
print(f"   -> {out_png_1}")
print(f"   -> {out_jpg_1}")
print(f"   -> {out_png_2}")
print(f"   -> {out_jpg_2}")
