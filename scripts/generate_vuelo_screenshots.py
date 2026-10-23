import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

apps_dir = r"c:\Projects\Omniverse Labs\apps\vuelo_controlado_staff"
fonts_dir = r"C:\Projects\Omniverse Labs\fonts"
store_dir = os.path.join(apps_dir, "store_assets", "play_store")
os.makedirs(store_dir, exist_ok=True)

logo_color = Image.open(os.path.join(apps_dir, "assets", "images", "logo_color.png")).convert("RGBA")
arr = np.array(logo_color)
is_green = (arr[:, :, 1] > 140) & (arr[:, :, 0] < 130) & (arr[:, :, 2] < 130) & (arr[:, :, 3] > 60)
is_text = (arr[:, :, 3] > 60) & ~is_green
composite = arr.copy()
composite[is_text, 0:3] = 255
alpha = composite[:, :, 3]
y_idx, x_idx = np.where(alpha > 20)
c_bbox = (x_idx.min(), y_idx.min(), x_idx.max() + 1, y_idx.max() + 1)
composite_cropped = Image.fromarray(composite, "RGBA").crop(c_bbox)

# Extract green wings
wings_arr = np.zeros_like(arr)
wings_arr[is_green] = arr[is_green]
wings_y, wings_x = np.where(is_green)
w_bbox = (wings_x.min(), wings_y.min(), wings_x.max() + 1, wings_y.max() + 1)
wings_cropped = Image.fromarray(wings_arr, "RGBA").crop(w_bbox)

font_headline = ImageFont.truetype(os.path.join(fonts_dir, "ClashGrotesk-Bold.ttf"), 54)
font_sub = ImageFont.truetype(os.path.join(fonts_dir, "montserrat.ttf"), 26)
font_body = ImageFont.truetype(os.path.join(fonts_dir, "montserrat.ttf"), 22)
font_card_title = ImageFont.truetype(os.path.join(fonts_dir, "montserrat.ttf"), 30)
font_btn = ImageFont.truetype(os.path.join(fonts_dir, "ClashGrotesk-Bold.ttf"), 28)

W, H = 1080, 1920

def create_base_canvas(tag_text, title_text, sub_text):
    img = Image.new("RGBA", (W, H), (11, 11, 15, 255))
    d = ImageDraw.Draw(img)

    # Diagonal futuristic background lines
    for x in range(-200, W + 400, 60):
        d.line([(x, 0), (x + 300, H)], fill=(0, 255, 42, 8), width=1)

    # Top Tag Capsule
    tag_bbox = d.textbbox((0, 0), tag_text, font=font_sub)
    tw = tag_bbox[2] - tag_bbox[0]
    th = tag_bbox[3] - tag_bbox[1]
    tx = (W - tw) // 2
    ty = 100
    d.rounded_rectangle([tx - 24, ty - 8, tx + tw + 24, ty + th + 10], radius=20, fill=(0, 255, 42, 35), outline=(0, 255, 42, 200), width=1)
    d.text((tx, ty - 2), tag_text, font=font_sub, fill=(0, 255, 42, 255))

    # Main Headline
    h_bbox = d.textbbox((0, 0), title_text, font=font_headline)
    hw = h_bbox[2] - h_bbox[0]
    hx = (W - hw) // 2
    d.text((hx, 175), title_text, font=font_headline, fill=(255, 255, 255, 255))

    # Subtitle
    s_bbox = d.textbbox((0, 0), sub_text, font=font_sub)
    sw = s_bbox[2] - s_bbox[0]
    sx = (W - sw) // 2
    d.text((sx, 255), sub_text, font=font_sub, fill=(160, 160, 180, 255))

    # Phone Frame Body
    px, py, pw, ph = 120, 340, 840, 1480
    d.rounded_rectangle([px, py, px + pw, py + ph], radius=56, fill=(18, 18, 24, 255), outline=(40, 40, 50, 255), width=4)
    # Notch / dynamic island
    d.rounded_rectangle([W // 2 - 80, py + 16, W // 2 + 80, py + 44], radius=14, fill=(11, 11, 15, 255))

    return img, d, (px, py, pw, ph)

# -------------------------------------------------------------
# SCREENSHOT 1: PORTAL DE STAFF & INGRESO OFFLINE
# -------------------------------------------------------------
s1, d1, (px, py, pw, ph) = create_base_canvas(
    "FUNDACIÓN VUELO CONTROLADO",
    "PORTAL DE STAFF OFFLINE",
    "Autenticación segura y guardias sin señal de internet"
)

# In-phone logo
l_w = 480
l_scale = l_w / composite_cropped.width
l_h = int(composite_cropped.height * l_scale)
scaled_logo = composite_cropped.resize((l_w, l_h), Image.Resampling.LANCZOS)
s1.paste(scaled_logo, (px + (pw - l_w) // 2, py + 140), scaled_logo)

# In-phone badge
d1.rounded_rectangle([px + pw // 2 - 110, py + 140 + l_h + 30, px + pw // 2 + 110, py + 140 + l_h + 74], radius=20, fill=(0, 255, 42, 35), outline=(0, 255, 42, 180), width=1)
d1.text((px + pw // 2 - 76, py + 140 + l_h + 38), "STAFF OFICIAL", font=font_sub, fill=(0, 255, 42, 255))

# Input 1: Correo
iy1 = py + 480
d1.text((px + 70, iy1), "Correo electrónico", font=font_body, fill=(160, 160, 180))
d1.rounded_rectangle([px + 70, iy1 + 34, px + pw - 70, iy1 + 110], radius=16, fill=(24, 24, 32), outline=(44, 44, 56), width=1)
d1.text((px + 100, iy1 + 54), "leobenveniste@vuelocontrolado.org", font=font_body, fill=(255, 255, 255))

# Input 2: Contraseña
iy2 = iy1 + 140
d1.text((px + 70, iy2), "Contraseña inicial (Número de documento)", font=font_body, fill=(160, 160, 180))
d1.rounded_rectangle([px + 70, iy2 + 34, px + pw - 70, iy2 + 110], radius=16, fill=(24, 24, 32), outline=(44, 44, 56), width=1)
d1.text((px + 100, iy2 + 54), "••••••••", font=font_body, fill=(255, 255, 255))

# Botón Ingresar
by = iy2 + 180
d1.rounded_rectangle([px + 70, by, px + pw - 70, by + 90], radius=18, fill=(0, 255, 42, 255))
d1.text((px + pw // 2 - 130, by + 26), "INGRESAR AL SISTEMA", font=font_btn, fill=(0, 0, 0, 255))

# Offline pill
d1.rounded_rectangle([px + 70, by + 120, px + pw - 70, by + 190], radius=14, fill=(30, 30, 40), outline=(0, 255, 42, 80), width=1)
d1.ellipse([px + 95, by + 145, px + 115, by + 165], fill=(0, 255, 42))
d1.text((px + 130, by + 142), "Modo 100% Offline Activo en el celular", font=font_body, fill=(0, 255, 42))

s1.save(os.path.join(store_dir, "screenshot_01_login.png"), "PNG")
print("Saved screenshot_01_login.png")

# -------------------------------------------------------------
# SCREENSHOT 2: GESTIÓN Y GUARDIAS DE EVENTOS
# -------------------------------------------------------------
s2, d2, (px, py, pw, ph) = create_base_canvas(
    "COORDINACIÓN OPERATIVA",
    "EVENTOS Y GUARDIAS",
    "Horarios de puertas, cierre y confirmación de staff"
)

# Header in app
d2.text((px + 60, py + 80), "Eventos Próximos", font=font_card_title, fill=(255, 255, 255))

# Event Card 1
cy1 = py + 150
d2.rounded_rectangle([px + 50, cy1, px + pw - 50, cy1 + 380], radius=24, fill=(26, 26, 36), outline=(0, 255, 42, 120), width=2)
# Status Badge
d2.rounded_rectangle([px + pw - 210, cy1 + 30, px + pw - 80, cy1 + 75], radius=14, fill=(0, 255, 42, 35), outline=(0, 255, 42, 200), width=1)
d2.text((px + pw - 190, cy1 + 40), "EN CURSO", font=ImageFont.truetype(os.path.join(fonts_dir, "ClashGrotesk-Bold.ttf"), 18), fill=(0, 255, 42))

d2.text((px + 80, cy1 + 35), "Festival Under Vuelo Controlado", font=font_card_title, fill=(255, 255, 255))
d2.text((px + 80, cy1 + 80), "📍 Costanera Norte, CABA", font=font_body, fill=(160, 160, 180))
d2.text((px + 80, cy1 + 120), "📅 Viernes 24 de Octubre", font=font_body, fill=(0, 255, 42))

# Schedule Box inside card
d2.rounded_rectangle([px + 80, cy1 + 170, px + pw - 80, cy1 + 260], radius=16, fill=(18, 18, 24))
d2.text((px + 110, cy1 + 185), "Puertas: 21:00 hs   •   Inicio: 22:00 hs   •   Cierre: 06:00 hs", font=font_body, fill=(255, 255, 255))

# Staff signed up
d2.text((px + 80, cy1 + 295), "👥 Staff asignado: 12 miembros", font=font_body, fill=(160, 160, 180))
d2.rounded_rectangle([px + pw - 240, cy1 + 285, px + pw - 80, cy1 + 345], radius=14, fill=(0, 255, 42, 25), outline=(0, 255, 42, 150), width=1)
d2.text((px + pw - 225, cy1 + 300), "✓ Sumado a guardia", font=ImageFont.truetype(os.path.join(fonts_dir, "montserrat.ttf"), 16), fill=(0, 255, 42))

# Event Card 2
cy2 = cy1 + 420
d2.rounded_rectangle([px + 50, cy2, px + pw - 50, cy2 + 360], radius=24, fill=(26, 26, 36), outline=(44, 44, 56), width=1)
d2.rounded_rectangle([px + pw - 200, cy2 + 30, px + pw - 80, cy2 + 75], radius=14, fill=(40, 40, 50))
d2.text((px + pw - 180, cy2 + 40), "PRÓXIMO", font=ImageFont.truetype(os.path.join(fonts_dir, "ClashGrotesk-Bold.ttf"), 18), fill=(180, 180, 200))
d2.text((px + 80, cy2 + 35), "Edición Especial Clubbing", font=font_card_title, fill=(255, 255, 255))
d2.text((px + 80, cy2 + 80), "📍 Complejo Art Media, CABA", font=font_body, fill=(160, 160, 180))
d2.text((px + 80, cy2 + 120), "📅 Sábado 1 de Noviembre", font=font_body, fill=(255, 255, 255))
d2.rounded_rectangle([px + 80, cy2 + 170, px + pw - 80, cy2 + 260], radius=16, fill=(18, 18, 24))
d2.text((px + 110, cy2 + 185), "Puertas: 23:00 hs   •   Inicio: 00:00 hs   •   Cierre: 07:00 hs", font=font_body, fill=(255, 255, 255))

s2.save(os.path.join(store_dir, "screenshot_02_eventos.png"), "PNG")
print("Saved screenshot_02_eventos.png")

# -------------------------------------------------------------
# SCREENSHOT 3: FICHAS DE CASOS DE REDUCCIÓN DE DAÑOS
# -------------------------------------------------------------
s3, d3, (px, py, pw, ph) = create_base_canvas(
    "REDUCCIÓN DE DAÑOS",
    "FICHAS DE CASOS EN VIVO",
    "Registro ágil de contención, sustancias y síntomas"
)

fy = py + 70
d3.text((px + 60, fy), "Nueva Ficha de Intervención", font=font_card_title, fill=(255, 255, 255))
d3.text((px + 60, fy + 45), "Evento: Festival Under Vuelo Controlado", font=font_body, fill=(0, 255, 42))

# Section 1: Persona
d3.text((px + 60, fy + 110), "1. Persona: Camila (22 años) • Género: Femenino", font=font_body, fill=(160, 160, 180))

# Section 2: Tipo de Intervención (Chips)
d3.text((px + 60, fy + 160), "2. Tipo de Intervención:", font=font_body, fill=(255, 255, 255))
chips = ["✓ Contención Emocional", "Hidratación", "Baja de Presión", "Primeros Auxilios"]
cx = px + 60
for c in chips:
    is_active = c.startswith("✓")
    d3.rounded_rectangle([cx, fy + 205, cx + 180, fy + 260], radius=14, fill=(0, 255, 42, 40) if is_active else (26, 26, 36), outline=(0, 255, 42) if is_active else (44, 44, 56), width=1)
    d3.text((cx + 15, fy + 220), c, font=ImageFont.truetype(os.path.join(fonts_dir, "montserrat.ttf"), 14), fill=(0, 255, 42) if is_active else (180, 180, 200))
    cx += 190

# Section 3: Sustancias referidas
d3.text((px + 60, fy + 290), "3. Sustancias Involucradas:", font=font_body, fill=(255, 255, 255))
sub_chips = ["Alcohol", "Cannabis", "Éxtasis / MDMA", "Psicodélicos"]
cx = px + 60
for c in sub_chips:
    d3.rounded_rectangle([cx, fy + 335, cx + 160, fy + 385], radius=14, fill=(26, 26, 36), outline=(0, 255, 42, 100), width=1)
    d3.text((cx + 20, fy + 350), c, font=ImageFont.truetype(os.path.join(fonts_dir, "montserrat.ttf"), 14), fill=(255, 255, 255))
    cx += 175

# Section 4: Síntomas y acciones (Form fields)
d3.text((px + 60, fy + 420), "4. Síntomas / Motivo de Consulta:", font=font_body, fill=(160, 160, 180))
d3.rounded_rectangle([px + 60, fy + 455, px + pw - 60, fy + 535], radius=16, fill=(24, 24, 32), outline=(44, 44, 56))
d3.text((px + 80, fy + 475), "Angustia, sobrecalentamiento y mareos leves.", font=font_body, fill=(255, 255, 255))

d3.text((px + 60, fy + 560), "5. Acciones Brindadas por el Staff:", font=font_body, fill=(160, 160, 180))
d3.rounded_rectangle([px + 60, fy + 595, px + pw - 60, fy + 685], radius=16, fill=(24, 24, 32), outline=(44, 44, 56))
d3.text((px + 80, fy + 615), "Suministro de agua fresca, reposo en carpa chill out\ny contención psicológica activa (25 min).", font=font_body, fill=(255, 255, 255))

# Botón Guardar Ficha
d3.rounded_rectangle([px + 60, fy + 720, px + pw - 60, fy + 810], radius=18, fill=(0, 255, 42, 255))
d3.text((px + pw // 2 - 170, fy + 745), "GUARDAR FICHA DE CASO", font=font_btn, fill=(0, 0, 0, 255))

s3.save(os.path.join(store_dir, "screenshot_03_ficha_caso.png"), "PNG")
print("Saved screenshot_03_ficha_caso.png")

# -------------------------------------------------------------
# SCREENSHOT 4: SINCRONIZACIÓN A GOOGLE DRIVE
# -------------------------------------------------------------
s4, d4, (px, py, pw, ph) = create_base_canvas(
    "REPORTES & RESGUARDO",
    "SINCRONIZACIÓN GOOGLE DRIVE",
    "Planillas consolidadas de casos en un solo toque"
)

sy = py + 120
# Big Cloud Icon
d4.rounded_rectangle([px + pw // 2 - 60, sy, px + pw // 2 + 60, sy + 120], radius=30, fill=(0, 255, 42, 35), outline=(0, 255, 42, 200), width=2)
d4.text((px + pw // 2 - 30, sy + 30), "☁️", font=ImageFont.truetype(os.path.join(fonts_dir, "ClashGrotesk-Bold.ttf"), 46))

d4.text((px + pw // 2 - 160, sy + 160), "Sincronización a Drive", font=font_card_title, fill=(255, 255, 255))
d4.text((px + pw // 2 - 210, sy + 210), "Exportación automática a Google Sheets / Excel", font=font_body, fill=(160, 160, 180))

# Stats Card
d4.rounded_rectangle([px + 60, sy + 280, px + pw - 60, sy + 510], radius=24, fill=(26, 26, 36), outline=(0, 255, 42, 100), width=1)
d4.text((px + 100, sy + 320), "• Total de fichas en guardia: 18 casos", font=font_body, fill=(255, 255, 255))
d4.text((px + 100, sy + 370), "• Sincronizados a Drive: 18 de 18", font=font_body, fill=(0, 255, 42))
d4.text((px + 100, sy + 420), "• Carpeta institucional: Vuelo Controlado 2026", font=font_body, fill=(160, 160, 180))

# Action Button: Sincronizar
d4.rounded_rectangle([px + 60, sy + 560, px + pw - 60, sy + 650], radius=18, fill=(0, 255, 42, 255))
d4.text((px + pw // 2 - 190, sy + 585), "SINCRONIZAR A GOOGLE DRIVE", font=font_btn, fill=(0, 0, 0, 255))

# Secondary Button: Exportar CSV
d4.rounded_rectangle([px + 60, sy + 680, px + pw - 60, sy + 770], radius=18, fill=(24, 24, 32), outline=(0, 255, 42, 180), width=1)
d4.text((px + pw // 2 - 170, sy + 705), "COMPARTIR PLANILLA CSV", font=font_btn, fill=(0, 255, 42, 255))

s4.save(os.path.join(store_dir, "screenshot_04_drive_sync.png"), "PNG")
print("Saved screenshot_04_drive_sync.png")
