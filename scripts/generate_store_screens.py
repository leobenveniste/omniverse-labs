import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

STORE_DIR = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\store"
ARTIFACTS_DIR = r"C:\Users\leobe\.gemini\antigravity\brain\42c1dcb7-5fbf-451b-91ce-5d992d2e93a3"

CANVAS_W, CANVAS_H = 1080, 2400
PHONE_W, PHONE_H = 880, 1800
PHONE_X = (CANVAS_W - PHONE_W) // 2
PHONE_Y = 520
BEZEL = 14
SCREEN_W = PHONE_W - (BEZEL * 2)
SCREEN_H = PHONE_H - (BEZEL * 2)
SCREEN_X = PHONE_X + BEZEL
SCREEN_Y = PHONE_Y + BEZEL
PHONE_RADIUS = 54
SCREEN_RADIUS = 42

STATUS_BAR_H = 50

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"

font_pill = ImageFont.truetype(FONT_BOLD, 26)
font_title = ImageFont.truetype(FONT_BOLD, 54)
font_subtitle = ImageFont.truetype(FONT_REG, 30)
font_time = ImageFont.truetype(FONT_BOLD, 20)

screens_config = [
    {
        "src": os.path.join(ARTIFACTS_DIR, ".user_uploaded", "media_1788439352833.jpg"),
        "tag": "RECETARIO INTELIGENTE",
        "title": "Descubre Cientos de Recetas",
        "subtitle": "Filtros rápidos y sugerencias según tu heladera",
        "filename": "screenshot_01_recetas.png"
    },
    {
        "src": os.path.join(ARTIFACTS_DIR, ".user_uploaded", "media_1788439352879.jpg"),
        "tag": "PORCIONES DINÁMICAS",
        "title": "Adapta Porciones con un Toque",
        "subtitle": "Cantidades calculadas para el número exacto de comensales",
        "filename": "screenshot_02_detalle.png"
    },
    {
        "src": os.path.join(ARTIFACTS_DIR, ".user_uploaded", "media_1788439352834.jpg"),
        "tag": "CONTROL MANOS LIBRES",
        "title": "Modo Cocina con Gestos",
        "subtitle": "Temporizadores y pasos sin ensuciar la pantalla",
        "filename": "screenshot_03_modo_cocina.png"
    },
    {
        "src": os.path.join(ARTIFACTS_DIR, ".user_uploaded", "media_1788439352828.jpg"),
        "tag": "PLANIFICADOR SEMANAL",
        "title": "Organiza Toda tu Semana",
        "subtitle": "Desayuno, almuerzo, merienda y cena bajo control",
        "filename": "screenshot_04_planificador.png"
    },
    {
        "src": os.path.join(ARTIFACTS_DIR, ".user_uploaded", "media_1788439352871.jpg"),
        "tag": "COMPRAS INTELIGENTES",
        "title": "Lista de Supermercado Automática",
        "subtitle": "Generada desde tu menú y clasificada por rubro",
        "filename": "screenshot_05_compras.png"
    },
]

def create_gradient_canvas(w, h, top_color, bottom_color):
    base = Image.new("RGBA", (w, h), top_color)
    top_r, top_g, top_b = top_color[:3]
    bot_r, bot_g, bot_b = bottom_color[:3]
    draw = ImageDraw.Draw(base)
    for y in range(h):
        factor = y / float(h)
        r = int(top_r + (bot_r - top_r) * factor)
        g = int(top_g + (bot_g - top_g) * factor)
        b = int(top_b + (bot_b - top_b) * factor)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
    return base

def draw_phone_frame(canvas, screen_img):
    # 1. Multi-layered drop shadow
    shadow_mask = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_mask)
    s_draw.rounded_rectangle(
        [PHONE_X - 12, PHONE_Y + 28, PHONE_X + PHONE_W + 12, PHONE_Y + PHONE_H + 38],
        radius=PHONE_RADIUS + 4,
        fill=(25, 38, 20, 65)
    )
    s_draw.rounded_rectangle(
        [PHONE_X - 2, PHONE_Y + 14, PHONE_X + PHONE_W + 2, PHONE_Y + PHONE_H + 20],
        radius=PHONE_RADIUS,
        fill=(15, 24, 12, 110)
    )
    shadow_blurred = shadow_mask.filter(ImageFilter.GaussianBlur(36))
    canvas.alpha_composite(shadow_blurred)

    # 2. Outer phone frame (Titanium dark slate rim)
    phone_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    p_draw = ImageDraw.Draw(phone_layer)
    p_draw.rounded_rectangle(
        [PHONE_X, PHONE_Y, PHONE_X + PHONE_W, PHONE_Y + PHONE_H],
        radius=PHONE_RADIUS,
        fill=(26, 32, 24, 255),
        outline=(70, 84, 66, 255),
        width=3
    )
    # Subtle inner bevel
    p_draw.rounded_rectangle(
        [PHONE_X + 4, PHONE_Y + 4, PHONE_X + PHONE_W - 4, PHONE_Y + PHONE_H - 4],
        radius=PHONE_RADIUS - 3,
        outline=(45, 54, 40, 255),
        width=2
    )
    canvas.alpha_composite(phone_layer)

    # 3. Create screen canvas with Status Bar + App Screenshot
    screen_canvas = Image.new("RGBA", (SCREEN_W, SCREEN_H), (248, 250, 246, 255))
    sc_draw = ImageDraw.Draw(screen_canvas)

    # Sample top background color from screenshot
    top_color = screen_img.convert("RGB").getpixel((screen_img.width // 2, 4))
    sc_draw.rectangle([0, 0, SCREEN_W, STATUS_BAR_H], fill=top_color + (255,))

    # Resize screenshot to fit below status bar
    app_h = SCREEN_H - STATUS_BAR_H
    resized_app = screen_img.resize((SCREEN_W, app_h), Image.Resampling.LANCZOS).convert("RGBA")
    screen_canvas.paste(resized_app, (0, STATUS_BAR_H))

    # Draw Status Bar details
    # Time (9:41)
    is_dark_bg = (top_color[0] + top_color[1] + top_color[2]) / 3 < 128
    sb_text_color = (240, 245, 238, 240) if is_dark_bg else (40, 50, 36, 240)
    sc_draw.text((36, 14), "9:41", font=font_time, fill=sb_text_color)

    # Status Bar Icons (Wi-Fi & Battery)
    # Wi-Fi arcs/dot
    wx = SCREEN_W - 90
    wy = 22
    sc_draw.arc([wx - 10, wy - 8, wx + 10, wy + 8], start=210, end=330, fill=sb_text_color, width=2)
    sc_draw.arc([wx - 6, wy - 4, wx + 6, wy + 4], start=210, end=330, fill=sb_text_color, width=2)
    sc_draw.ellipse([wx - 2, wy + 4, wx + 2, wy + 8], fill=sb_text_color)

    # Battery
    bx = SCREEN_W - 55
    by = 18
    sc_draw.rounded_rectangle([bx, by, bx + 24, by + 13], radius=3, outline=sb_text_color, width=2)
    sc_draw.rectangle([bx + 24, by + 3, bx + 26, by + 10], fill=sb_text_color)
    sc_draw.rounded_rectangle([bx + 3, by + 3, bx + 18, by + 10], radius=1, fill=sb_text_color)

    # Camera punch hole centered in status bar
    cam_x = SCREEN_W // 2
    cam_y = STATUS_BAR_H // 2
    cam_r = 11
    sc_draw.ellipse([cam_x - cam_r, cam_y - cam_r, cam_x + cam_r, cam_y + cam_r], fill=(12, 16, 12, 255))
    sc_draw.ellipse([cam_x - 3, cam_y - 3, cam_x + 1, cam_y + 1], fill=(42, 75, 55, 180))

    # Bottom Android Gesture Navigation Pill
    nav_w = 120
    nav_h = 5
    nav_x = (SCREEN_W - nav_w) // 2
    nav_y = SCREEN_H - 16
    sc_draw.rounded_rectangle([nav_x, nav_y, nav_x + nav_w, nav_y + nav_h], radius=3, fill=(60, 75, 55, 140))

    # 4. Mask and paste screen onto canvas
    screen_mask = Image.new("L", (SCREEN_W, SCREEN_H), 0)
    m_draw = ImageDraw.Draw(screen_mask)
    m_draw.rounded_rectangle([0, 0, SCREEN_W, SCREEN_H], radius=SCREEN_RADIUS, fill=255)

    canvas.paste(screen_canvas, (SCREEN_X, SCREEN_Y), mask=screen_mask)

    # 5. Speaker ear-piece micro slit at top bezel
    speaker_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    sp_draw = ImageDraw.Draw(speaker_layer)
    cam_center_x = CANVAS_W // 2
    sp_draw.rounded_rectangle(
        [cam_center_x - 45, PHONE_Y + 5, cam_center_x + 45, PHONE_Y + 8],
        radius=2,
        fill=(18, 22, 16, 255)
    )
    canvas.alpha_composite(speaker_layer)

print("Generating 5 enhanced Play Store screenshots...")
for idx, cfg in enumerate(screens_config):
    print(f"Generating [{idx+1}/5]: {cfg['title']}...")
    canvas = create_gradient_canvas(CANVAS_W, CANVAS_H, (247, 249, 245), (232, 240, 228))
    
    glow = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    g_draw.ellipse([-200, -200, 600, 600], fill=(215, 235, 205, 90))
    g_draw.ellipse([CANVAS_W - 400, 300, CANVAS_W + 300, 1000], fill=(210, 230, 200, 80))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(100)))

    draw = ImageDraw.Draw(canvas)

    # 1. Pill badge
    pill_text = cfg["tag"]
    pill_bbox = font_pill.getbbox(pill_text)
    pill_w = pill_bbox[2] - pill_bbox[0] + 48
    pill_h = 50
    pill_x = (CANVAS_W - pill_w) // 2
    pill_y = 100
    draw.rounded_rectangle(
        [pill_x, pill_y, pill_x + pill_w, pill_y + pill_h],
        radius=25,
        fill=(222, 236, 215, 255),
        outline=(180, 208, 170, 255),
        width=2
    )
    text_x = pill_x + (pill_w - (pill_bbox[2] - pill_bbox[0])) // 2 - pill_bbox[0]
    text_y = pill_y + (pill_h - (pill_bbox[3] - pill_bbox[1])) // 2 - pill_bbox[1]
    draw.text((text_x, text_y), pill_text, font=font_pill, fill=(45, 85, 30, 255))

    # 2. Main Title
    title_text = cfg["title"]
    t_bbox = font_title.getbbox(title_text)
    t_w = t_bbox[2] - t_bbox[0]
    t_x = (CANVAS_W - t_w) // 2
    t_y = pill_y + pill_h + 30
    draw.text((t_x, t_y), title_text, font=font_title, fill=(22, 35, 18, 255))

    # 3. Subtitle
    sub_text = cfg["subtitle"]
    s_bbox = font_subtitle.getbbox(sub_text)
    s_w = s_bbox[2] - s_bbox[0]
    s_x = (CANVAS_W - s_w) // 2
    s_y = t_y + 75
    draw.text((s_x, s_y), sub_text, font=font_subtitle, fill=(75, 95, 70, 255))

    # 4. Load screenshot and draw phone frame
    with Image.open(cfg["src"]) as sc_img:
        draw_phone_frame(canvas, sc_img)

    out_store = os.path.join(STORE_DIR, cfg["filename"])
    out_artifact = os.path.join(ARTIFACTS_DIR, cfg["filename"])
    canvas.convert("RGB").save(out_store, quality=95)
    canvas.convert("RGB").save(out_artifact, quality=95)
    print(f"Saved: {out_store}")

print("All 5 enhanced screenshots successfully created!")
