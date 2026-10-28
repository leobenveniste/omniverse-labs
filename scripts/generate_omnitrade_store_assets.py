import os
import sys
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Paths
FONTS_DIR = r"c:\Projects\Omniverse Labs\fonts"
WORKSPACE_DIR = r"c:\Projects\Omniverse Labs"
OMNI_STORE_DIR = os.path.join(WORKSPACE_DIR, "apps", "omni_trade", "store_assets")
PLAY_STORE_DIR = os.path.join(OMNI_STORE_DIR, "play_store")
ARTIFACTS_DIR = r"C:\Users\leobe\.gemini\antigravity\brain\0bc35466-239f-4343-9a84-cba5bde56ec8"
USER_UPLOADED_DIR = os.path.join(ARTIFACTS_DIR, ".user_uploaded")

os.makedirs(PLAY_STORE_DIR, exist_ok=True)
os.makedirs(ARTIFACTS_DIR, exist_ok=True)

# App Icon
ICON_PATH = os.path.join(WORKSPACE_DIR, "apps", "omni_trade", "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset", "Icon-App-1024x1024@1x.png")
if not os.path.exists(ICON_PATH):
    ICON_PATH = os.path.join(PLAY_STORE_DIR, "icon_512x512.png")

# Screenshots source paths
SRC_COCKPIT = os.path.join(USER_UPLOADED_DIR, "media_1792763063874_06ffde2f.jpg")
SRC_OPERATION = os.path.join(USER_UPLOADED_DIR, "media_1792763063874_c249be16.jpg")
SRC_METRICS = os.path.join(USER_UPLOADED_DIR, "media_1792763063874_b4736705.jpg")

# Dimensions - 1080 x 1920 (Standard Google Play Store Portrait)
CANVAS_W = 1080
CANVAS_H = 1920

# Strict 4px / 8px grid phone dimensions
PHONE_W = 768
SCREEN_W = 736
SCREEN_H = 1508
PHONE_H = SCREEN_H + 32  # 1540
PHONE_X = (CANVAS_W - PHONE_W) // 2  # 156
PHONE_Y = 304  # 304 + 1540 = 1844, bottom margin = 76 (approx 80)
BEZEL = 16
SCREEN_X = PHONE_X + BEZEL
SCREEN_Y = PHONE_Y + BEZEL
PHONE_RADIUS = 48
SCREEN_RADIUS = 36

# Load fonts
def get_font(name, size):
    candidates = [
        os.path.join(FONTS_DIR, name),
        os.path.join(r"C:\Windows\Fonts", name),
    ]
    for p in candidates:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    for fb in ["segoeuib.ttf", "arialbd.ttf", "segoeui.ttf", "arial.ttf"]:
        p = os.path.join(r"C:\Windows\Fonts", fb)
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

font_pill = get_font("PlusJakartaSans.ttf", 22)
font_title = get_font("PlusJakartaSans.ttf", 52)
font_subtitle = get_font("PlusJakartaSans.ttf", 26)
font_time = get_font("PlusJakartaSans.ttf", 18)

# Colors
COLOR_BG_DARK_TOP = (7, 10, 16)      # #070A10
COLOR_BG_DARK_BOT = (15, 23, 42)     # #0F172A
COLOR_EMERALD = (0, 230, 118)        # #00E676
COLOR_INDIGO = (99, 102, 241)        # #6366F1
COLOR_TEXT_MAIN = (255, 255, 255)
COLOR_TEXT_MUTED = (148, 163, 184)   # Slate 400
COLOR_PHONE_BORDER = (45, 60, 85)
COLOR_PHONE_BODY = (17, 24, 39)

def create_base_canvas(w, h, glow_accent="emerald"):
    """Creates a sleek dark obsidian trading background with ambient glow & chart watermarks."""
    base = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(base)

    # Vertical gradient
    r1, g1, b1 = COLOR_BG_DARK_TOP
    r2, g2, b2 = COLOR_BG_DARK_BOT
    for y in range(h):
        t = y / float(h)
        r = int(r1 + (r2 - r1) * t)
        g = int(g1 + (g2 - g1) * t)
        b = int(b1 + (b2 - b1) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    # Grid lines / watermark (faint trading grid)
    grid_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(grid_overlay)
    
    # Grid steps: 80px horizontal, 120px vertical
    grid_color = (255, 255, 255, 7)
    for x in range(0, w, 80):
        g_draw.line([(x, 0), (x, h)], fill=grid_color, width=1)
    for y in range(0, h, 80):
        g_draw.line([(0, y), (w, y)], fill=grid_color, width=1)
        
    # Ambient radial glow
    glow_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gl_draw = ImageDraw.Draw(glow_overlay)
    
    if glow_accent == "emerald":
        # Top right emerald glow + bottom left indigo glow
        gl_draw.ellipse([w - 400, -100, w + 300, 600], fill=(0, 230, 118, 28))
        gl_draw.ellipse([-200, 200, 400, 800], fill=(99, 102, 241, 20))
        gl_draw.ellipse([w // 2 - 300, h - 500, w // 2 + 300, h + 100], fill=(0, 230, 118, 16))
    elif glow_accent == "indigo":
        gl_draw.ellipse([w - 300, 100, w + 300, 700], fill=(99, 102, 241, 32))
        gl_draw.ellipse([-150, -50, 450, 550], fill=(0, 230, 118, 22))
        gl_draw.ellipse([w // 2 - 250, h - 450, w // 2 + 250, h + 150], fill=(99, 102, 241, 20))
    else:  # cyan/mixed
        gl_draw.ellipse([w - 350, 50, w + 350, 750], fill=(6, 182, 212, 28))
        gl_draw.ellipse([-200, 150, 400, 750], fill=(0, 230, 118, 24))
        
    glow_blurred = glow_overlay.filter(ImageFilter.GaussianBlur(90))
    base.alpha_composite(grid_overlay)
    base.alpha_composite(glow_blurred)
    return base

def draw_header(canvas, pill_text, title_text, subtitle_text, pill_color=COLOR_EMERALD):
    draw = ImageDraw.Draw(canvas)
    
    # 1. Pill badge
    pb = font_pill.getbbox(pill_text)
    pw = pb[2] - pb[0] + 48  # strictly 48px padding (8px scale)
    ph = 40                  # strictly 40px (8px scale)
    px = (CANVAS_W - pw) // 2
    py = 64                  # 64px top margin (8px scale)
    
    # Pill background + border
    pill_overlay = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    po_draw = ImageDraw.Draw(pill_overlay)
    po_draw.rounded_rectangle(
        [px, py, px + pw, py + ph],
        radius=20,
        fill=(pill_color[0], pill_color[1], pill_color[2], 30),
        outline=(pill_color[0], pill_color[1], pill_color[2], 120),
        width=2
    )
    canvas.alpha_composite(pill_overlay)
    
    # Pill text
    draw = ImageDraw.Draw(canvas)
    pt_x = px + (pw - (pb[2] - pb[0])) // 2 - pb[0]
    pt_y = py + (ph - (pb[3] - pb[1])) // 2 - pb[1]
    draw.text((pt_x, pt_y), pill_text, font=font_pill, fill=pill_color)
    
    # 2. Main Title (Y = 128, strictly 24px gap)
    tb = font_title.getbbox(title_text)
    tw = tb[2] - tb[0]
    tx = (CANVAS_W - tw) // 2
    ty = py + ph + 24
    draw.text((tx, ty), title_text, font=font_title, fill=COLOR_TEXT_MAIN)
    
    # 3. Subtitle (Y = ty + 64 + 8 = ty + 72)
    sb = font_subtitle.getbbox(subtitle_text)
    sw = sb[2] - sb[0]
    sx = (CANVAS_W - sw) // 2
    sy = ty + 64
    draw.text((sx, sy), subtitle_text, font=font_subtitle, fill=COLOR_TEXT_MUTED)

def draw_phone_mockup(canvas, src_img_path):
    """Renders a smartphone frame around the screenshot with realistic shadows, glass and bevels."""
    with Image.open(src_img_path) as raw_img:
        screen_raw = raw_img.convert("RGBA")
        
    # Resize screenshot to fit exact inner screen (736 x 1508)
    screen_resized = screen_raw.resize((SCREEN_W, SCREEN_H), Image.Resampling.LANCZOS)
    
    # 1. Multi-layered realistic drop shadow
    shadow_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow_layer)
    # Deep ambient drop shadow
    sh_draw.rounded_rectangle(
        [PHONE_X - 16, PHONE_Y + 24, PHONE_X + PHONE_W + 16, PHONE_Y + PHONE_H + 32],
        radius=PHONE_RADIUS + 8,
        fill=(0, 0, 0, 180)
    )
    # Core contact shadow
    sh_draw.rounded_rectangle(
        [PHONE_X - 4, PHONE_Y + 12, PHONE_X + PHONE_W + 4, PHONE_Y + PHONE_H + 16],
        radius=PHONE_RADIUS + 2,
        fill=(0, 0, 0, 220)
    )
    # Subtle emerald ambient rim shadow
    sh_draw.rounded_rectangle(
        [PHONE_X - 8, PHONE_Y - 4, PHONE_X + PHONE_W + 8, PHONE_Y + PHONE_H + 8],
        radius=PHONE_RADIUS + 4,
        fill=(0, 230, 118, 35)
    )
    shadow_blurred = shadow_layer.filter(ImageFilter.GaussianBlur(32))
    canvas.alpha_composite(shadow_blurred)
    
    # 2. Outer Phone Chassis (Dark Titanium Slate with dual metallic chamfer)
    phone_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    p_draw = ImageDraw.Draw(phone_layer)
    
    # Outer frame
    p_draw.rounded_rectangle(
        [PHONE_X, PHONE_Y, PHONE_X + PHONE_W, PHONE_Y + PHONE_H],
        radius=PHONE_RADIUS,
        fill=(17, 24, 39, 255),
        outline=(51, 65, 85, 255),
        width=3
    )
    # Inner metallic bezel accent
    p_draw.rounded_rectangle(
        [PHONE_X + 3, PHONE_Y + 3, PHONE_X + PHONE_W - 3, PHONE_Y + PHONE_H - 3],
        radius=PHONE_RADIUS - 2,
        outline=(30, 41, 59, 255),
        width=2
    )
    canvas.alpha_composite(phone_layer)
    
    # 3. Create screen canvas with Status Bar & App Screenshot
    screen_canvas = Image.new("RGBA", (SCREEN_W, SCREEN_H), (11, 14, 20, 255))
    sc_draw = ImageDraw.Draw(screen_canvas)
    
    # Screen screenshot paste
    screen_canvas.paste(screen_resized, (0, 0))
    
    # Modern Front Camera Pill (Punch Hole)
    pill_cam_w = 96
    pill_cam_h = 24
    pill_cam_x = (SCREEN_W - pill_cam_w) // 2
    pill_cam_y = 10
    sc_draw.rounded_rectangle(
        [pill_cam_x, pill_cam_y, pill_cam_x + pill_cam_w, pill_cam_y + pill_cam_h],
        radius=12,
        fill=(5, 7, 10, 255),
        outline=(26, 34, 48, 160),
        width=1
    )
    # Camera sensor lens reflection
    sc_draw.ellipse([pill_cam_x + 20, pill_cam_y + 6, pill_cam_x + 32, pill_cam_y + 18], fill=(12, 22, 38, 255))
    sc_draw.ellipse([pill_cam_x + 24, pill_cam_y + 8, pill_cam_x + 28, pill_cam_y + 12], fill=(20, 60, 90, 180))
    
    # Top Status Bar details: Time "9:41"
    sc_draw.text((36, 12), "9:41", font=font_time, fill=(241, 245, 249, 230))
    
    # Status Bar Icons: 5G & Battery (right side)
    bx = SCREEN_W - 54
    by = 16
    # Battery frame
    sc_draw.rounded_rectangle([bx, by, bx + 22, by + 12], radius=3, outline=(241, 245, 249, 220), width=2)
    sc_draw.rectangle([bx + 22, by + 3, bx + 24, by + 9], fill=(241, 245, 249, 220))
    sc_draw.rounded_rectangle([bx + 3, by + 3, bx + 16, by + 9], radius=1, fill=(0, 230, 118, 230))
    
    # 5G indicator
    sc_draw.text((bx - 44, by - 2), "5G", font=font_time, fill=(241, 245, 249, 200))
    
    # Bottom Android Gesture navigation bar
    nav_w = 140
    nav_h = 4
    nav_x = (SCREEN_W - nav_w) // 2
    nav_y = SCREEN_H - 12
    sc_draw.rounded_rectangle([nav_x, nav_y, nav_x + nav_w, nav_y + nav_h], radius=2, fill=(255, 255, 255, 140))
    
    # Mask screen with rounded corners
    screen_mask = Image.new("L", (SCREEN_W, SCREEN_H), 0)
    m_draw = ImageDraw.Draw(screen_mask)
    m_draw.rounded_rectangle([0, 0, SCREEN_W, SCREEN_H], radius=SCREEN_RADIUS, fill=255)
    
    canvas.paste(screen_canvas, (SCREEN_X, SCREEN_Y), mask=screen_mask)
    
    # 4. Subtle top speaker micro slit
    sp_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    sp_draw = ImageDraw.Draw(sp_layer)
    cam_center_x = CANVAS_W // 2
    sp_draw.rounded_rectangle(
        [cam_center_x - 36, PHONE_Y + 5, cam_center_x + 36, PHONE_Y + 8],
        radius=2,
        fill=(10, 15, 24, 255)
    )
    canvas.alpha_composite(sp_layer)

def generate_screenshots():
    """Generates the 3 Play Store screenshots with real app captures."""
    configs = [
        {
            "src": SRC_COCKPIT,
            "pill": "TERMINAL DE TRADING EN VIVO",
            "title": "Control Total de tu Portafolio",
            "subtitle": "Métricas en tiempo real, equidad y posiciones activas",
            "accent": "emerald",
            "pill_color": COLOR_EMERALD,
            "filename": "screenshot_01_cockpit.png",
            "play_store_name": "screenshot_1_dashboard.png"
        },
        {
            "src": SRC_OPERATION,
            "pill": "BITÁCORA PROFESIONAL",
            "title": "Registra Cada Operación al Detalle",
            "subtitle": "Multi-activo, ratios R:R, setups técnicos y psicología",
            "accent": "indigo",
            "pill_color": (129, 140, 248),  # Indigo 400
            "filename": "screenshot_02_new_operation.png",
            "play_store_name": "screenshot_2_calculator.png"  # Keep compatible with deploy script
        },
        {
            "src": SRC_METRICS,
            "pill": "ANALÍTICAS INSTITUCIONALES",
            "title": "Audita tu Ventaja Matemática",
            "subtitle": "Win Rate %, Profit Factor, Esperanza (R) y curva de balance",
            "accent": "cyan",
            "pill_color": (34, 211, 238),  # Cyan 400
            "filename": "screenshot_03_analytics.png",
            "play_store_name": "screenshot_3_analytics.png"
        }
    ]
    
    print("\n📸 Generating 3 Play Store Screenshots (1080 x 1920)...")
    for idx, cfg in enumerate(configs, 1):
        print(f"[{idx}/3] Generating {cfg['filename']} - {cfg['title']}...")
        canvas = create_base_canvas(CANVAS_W, CANVAS_H, glow_accent=cfg["accent"])
        draw_header(canvas, cfg["pill"], cfg["title"], cfg["subtitle"], pill_color=cfg["pill_color"])
        draw_phone_mockup(canvas, cfg["src"])
        
        # Save to artifact dir
        out_art = os.path.join(ARTIFACTS_DIR, cfg["filename"])
        canvas.save(out_art, format="PNG", optimize=True)
        
        # Save to apps/omni_trade/store_assets/play_store/
        out_play = os.path.join(PLAY_STORE_DIR, cfg["filename"])
        canvas.save(out_play, format="PNG", optimize=True)
        
        # Also save with deploy script naming
        out_compat = os.path.join(PLAY_STORE_DIR, cfg["play_store_name"])
        canvas.save(out_compat, format="PNG", optimize=True)
        print(f"   ✅ Saved to: {out_play}")

def generate_vertical_feature():
    """Generates a vertical 'Feature' poster in the EXACT same size (1080 x 1920)."""
    print("\n⭐ Generating Vertical Feature Poster (1080 x 1920)...")
    canvas = create_base_canvas(CANVAS_W, CANVAS_H, glow_accent="emerald")
    
    # 1. Subtle central ambient wash for cards
    wash = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(wash)
    w_draw.rounded_rectangle([72, 540, CANVAS_W - 72, 1840], radius=40, fill=(15, 23, 42, 100))
    wash_blurred = wash.filter(ImageFilter.GaussianBlur(32))
    canvas.alpha_composite(wash_blurred)
    
    # 2. Top Pill
    pill_text = "SISTEMA INTEGRAL DE TRADING"
    font_pill_feat = get_font("PlusJakartaSans.ttf", 22)
    pb = font_pill_feat.getbbox(pill_text)
    pw = pb[2] - pb[0] + 48
    ph = 44
    px = (CANVAS_W - pw) // 2
    py = 64
    
    p_overlay = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    po_draw = ImageDraw.Draw(p_overlay)
    po_draw.rounded_rectangle(
        [px, py, px + pw, py + ph],
        radius=22,
        fill=(0, 230, 118, 25),
        outline=(0, 230, 118, 120),
        width=2
    )
    canvas.alpha_composite(p_overlay)
    
    draw = ImageDraw.Draw(canvas)
    pt_x = px + (pw - (pb[2] - pb[0])) // 2 - pb[0]
    pt_y = py + (ph - (pb[3] - pb[1])) // 2 - pb[1]
    draw.text((pt_x, pt_y), pill_text, font=font_pill_feat, fill=COLOR_EMERALD)
    
    # 3. App Icon with glowing emerald halo
    if os.path.exists(ICON_PATH):
        with Image.open(ICON_PATH) as raw_icon:
            icon_size = 144
            icon_resized = raw_icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS).convert("RGBA")
            
            # Mask icon with smooth rounded rectangle
            icon_mask = Image.new("L", (icon_size, icon_size), 0)
            im_draw = ImageDraw.Draw(icon_mask)
            im_draw.rounded_rectangle([0, 0, icon_size, icon_size], radius=34, fill=255)
            
            icon_x = (CANVAS_W - icon_size) // 2
            icon_y = py + ph + 32  # Y = 140
            
            # Glowing halo
            halo = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
            h_draw = ImageDraw.Draw(halo)
            h_draw.ellipse(
                [icon_x - 48, icon_y - 48, icon_x + icon_size + 48, icon_y + icon_size + 48],
                fill=(0, 230, 118, 60)
            )
            canvas.alpha_composite(halo.filter(ImageFilter.GaussianBlur(36)))
            
            # Drop shadow
            sh = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
            s_draw = ImageDraw.Draw(sh)
            s_draw.rounded_rectangle(
                [icon_x - 4, icon_y + 12, icon_x + icon_size + 4, icon_y + icon_size + 18],
                radius=36,
                fill=(0, 0, 0, 180)
            )
            canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(16)))
            
            # Paste icon
            canvas.paste(icon_resized, (icon_x, icon_y), mask=icon_mask)
            
            # Border around icon
            b_overlay = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
            bo_draw = ImageDraw.Draw(b_overlay)
            bo_draw.rounded_rectangle(
                [icon_x, icon_y, icon_x + icon_size, icon_y + icon_size],
                radius=34,
                outline=(52, 211, 153, 160),
                width=2
            )
            canvas.alpha_composite(b_overlay)
    
    # 4. App Title & Taglines
    font_hero = get_font("PlusJakartaSans.ttf", 64)
    font_hero_sub = get_font("PlusJakartaSans.ttf", 26)
    font_hero_tag = get_font("PlusJakartaSans.ttf", 22)
    
    title_text = "OmniTrade"
    tb = font_hero.getbbox(title_text)
    tw = tb[2] - tb[0]
    tx = (CANVAS_W - tw) // 2
    ty = 308
    draw.text((tx, ty), title_text, font=font_hero, fill=COLOR_TEXT_MAIN)
    
    sub_text = "Bitácora Cuantitativa · Gestión de Riesgo · Analíticas"
    sb = font_hero_sub.getbbox(sub_text)
    sw = sb[2] - sb[0]
    sx = (CANVAS_W - sw) // 2
    sy = ty + 76
    draw.text((sx, sy), sub_text, font=font_hero_sub, fill=(226, 232, 240))
    
    tag_phrase = "Diseñado para traders que operan con disciplina y rigor matemático"
    tpb = font_hero_tag.getbbox(tag_phrase)
    tpw = tpb[2] - tpb[0]
    tpx = (CANVAS_W - tpw) // 2
    tpy = sy + 38
    draw.text((tpx, tpy), tag_phrase, font=font_hero_tag, fill=COLOR_TEXT_MUTED)
    
    # 5. Bento Feature Cards (4 Cards)
    cards = [
        {
            "tag": "BITÁCORA MULTI-ACTIVO",
            "tag_color": (52, 211, 153),      # Emerald 400
            "tag_bg": (6, 78, 59, 140),
            "title": "Registro Completo de Operaciones",
            "desc": "Opera Cripto, Acciones, Forex, Futuros y Opciones. Registra entradas, stops, targets, multiplicador y seguimiento emocional (FOMO, disciplina, venganza).",
            "badge": "Crypto • Stocks • Forex • Futuros • Opciones",
            "border_color": (16, 185, 129, 90)
        },
        {
            "tag": "GESTIÓN CUANTITATIVA",
            "tag_color": (129, 140, 248),     # Indigo 400
            "tag_bg": (49, 46, 129, 140),
            "title": "Calculadora de Riesgo & Ratio R:R",
            "desc": "Calcula el tamaño óptimo de posición en unidades y contratos según tu balance y tolerancia de riesgo (1% R). Convierte cálculos a trades en un solo toque.",
            "badge": "Gestión 1% R • Tamaño Óptimo • Ratio R:R Dinámico",
            "border_color": (99, 102, 241, 90)
        },
        {
            "tag": "MÉTRICAS INSTITUCIONALES",
            "tag_color": (56, 189, 248),      # Sky 400
            "tag_bg": (12, 74, 110, 140),
            "title": "Analíticas Avanzadas & Curva de Equidad",
            "desc": "Conoce tu ventaja estadística real: Win Rate %, Profit Factor, Esperanza Matemática R, ganancia media y rendimiento desglosado por setup o estrategia.",
            "badge": "Curva de Equidad • Win Rate • Profit Factor • Expectancy",
            "border_color": (14, 165, 233, 90)
        },
        {
            "tag": "MÁXIMA PRIVACIDAD & SOBERANÍA",
            "tag_color": (251, 191, 36),      # Amber 400
            "tag_bg": (120, 53, 15, 140),
            "title": "100% Offline-First & Seguridad Biométrica",
            "desc": "Tus datos financieros jamás salen de tu móvil. Base local SQLite encriptada, bloqueo biométrico con huella/PIN y exportación completa a CSV o JSON.",
            "badge": "Sin Servidores • Sin Trackers • Bloqueo Biométrico • Backup CSV",
            "border_color": (245, 158, 11, 90)
        }
    ]
    
    card_w = 936  # Strictly 936px (8px grid scale)
    card_x = (CANVAS_W - card_w) // 2  # 72px margin each side
    start_y = 504
    card_spacing = 312
    card_h = 288
    
    font_c_tag = get_font("PlusJakartaSans.ttf", 18)
    font_c_title = get_font("PlusJakartaSans.ttf", 32)
    font_c_desc = get_font("PlusJakartaSans.ttf", 20)
    font_c_badge = get_font("PlusJakartaSans.ttf", 16)
    
    card_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    cl_draw = ImageDraw.Draw(card_layer)
    
    for idx, c in enumerate(cards):
        cy = start_y + (idx * card_spacing)
        
        # Card Background (translucent obsidian terminal with soft border)
        cl_draw.rounded_rectangle(
            [card_x, cy, card_x + card_w, cy + card_h],
            radius=24,
            fill=(17, 24, 39, 215),
            outline=c["border_color"],
            width=2
        )
        
        # Inner Tag pill
        tag_t = c["tag"]
        tb = font_c_tag.getbbox(tag_t)
        tw = tb[2] - tb[0] + 32
        th = 32
        tx = card_x + 32
        ty = cy + 24
        cl_draw.rounded_rectangle(
            [tx, ty, tx + tw, ty + th],
            radius=16,
            fill=c["tag_bg"],
            outline=(c["tag_color"][0], c["tag_color"][1], c["tag_color"][2], 180),
            width=1
        )
        cl_draw.text((tx + 16, ty + 6), tag_t, font=font_c_tag, fill=c["tag_color"])
        
        # Title
        title_y = ty + th + 14
        cl_draw.text((card_x + 32, title_y), c["title"], font=font_c_title, fill=COLOR_TEXT_MAIN)
        
        # Description (2 lines text wrapped)
        desc_y = title_y + 44
        # Manual wrap
        words = c["desc"].split()
        line1, line2 = "", ""
        for w in words:
            test = line1 + (" " if line1 else "") + w
            if len(test) < 70:
                line1 = test
            else:
                line2 += (" " if line2 else "") + w
                
        cl_draw.text((card_x + 32, desc_y), line1, font=font_c_desc, fill=(203, 213, 225))
        cl_draw.text((card_x + 32, desc_y + 28), line2, font=font_c_desc, fill=(203, 213, 225))
        
        # Bottom highlight badge
        badge_y = cy + card_h - 44
        cl_draw.rounded_rectangle(
            [card_x + 32, badge_y, card_x + card_w - 32, badge_y + 28],
            radius=8,
            fill=(11, 15, 25, 230)
        )
        cl_draw.text((card_x + 44, badge_y + 4), "✦ " + c["badge"], font=font_c_badge, fill=c["tag_color"])
        
    canvas.alpha_composite(card_layer)
    
    # 6. Bottom Brand Footer
    font_footer = get_font("PlusJakartaSans.ttf", 20)
    footer_text = "OMNIVERSE LABS • PRIVACIDAD FINANCIERA • 100% OFFLINE"
    fb = font_footer.getbbox(footer_text)
    fw = fb[2] - fb[0]
    fx = (CANVAS_W - fw) // 2
    fy = CANVAS_H - 72
    
    draw = ImageDraw.Draw(canvas)
    draw.text((fx, fy), footer_text, font=font_footer, fill=(100, 116, 139))
    
    # Save vertical feature image
    out_feat_art = os.path.join(ARTIFACTS_DIR, "screenshot_04_feature_vertical.png")
    canvas.save(out_feat_art, format="PNG", optimize=True)
    
    out_feat_play = os.path.join(PLAY_STORE_DIR, "screenshot_04_feature_vertical.png")
    canvas.save(out_feat_play, format="PNG", optimize=True)
    print(f"   ✅ Saved to: {out_feat_play}")

def generate_playstore_feature_graphic_banner():
    """Generates the official Play Store Feature Graphic Banner (1024 x 500 px)."""
    print("\n🎨 Generating Official Play Store Feature Graphic (1024 x 500)...")
    W, H = 1024, 500
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(canvas)
    
    # Diagonal dark gradient
    for y in range(H):
        for x in range(W):
            diag = (x * 0.7 + y * 0.3) / (W * 0.7 + H * 0.3)
            # Center glow around (820, 240)
            dist_glow = math.hypot(x - 800, y - 220) / 450.0
            glow = max(0.0, 1.0 - dist_glow)
            
            # Slate navy #070A10 to #0F172A
            r = int((7 * (1 - diag) + 15 * diag) * (1 - glow * 0.2) + 0 * glow)
            g = int((10 * (1 - diag) + 23 * diag) * (1 - glow * 0.4) + 60 * glow)
            b = int((16 * (1 - diag) + 42 * diag) * (1 - glow * 0.4) + 70 * glow)
            canvas.putpixel((x, y), (min(255, r), min(255, g), min(255, b), 255))
            
    # Chart waveform curves in the background
    chart_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(chart_overlay)
    
    # Financial trend curve
    points = [
        (480, 420), (560, 360), (640, 390), (720, 280),
        (800, 310), (880, 190), (960, 210), (1030, 130)
    ]
    for i in range(len(points) - 1):
        c_draw.line([points[i], points[i+1]], fill=(0, 230, 118, 160), width=4)
        c_draw.ellipse([points[i][0]-4, points[i][1]-4, points[i][0]+4, points[i][1]+4], fill=(0, 230, 118, 220))
    c_draw.ellipse([points[-1][0]-6, points[-1][1]-6, points[-1][0]+6, points[-1][1]+6], fill=(52, 211, 153, 255))
    
    # Area under the curve
    poly_points = [(480, 500)] + points + [(1030, 500)]
    c_draw.polygon(poly_points, fill=(0, 230, 118, 25))
    canvas.alpha_composite(chart_overlay)
    
    # Left Content: App Icon + Branding + Taglines + Badges
    icon_size = 96
    if os.path.exists(ICON_PATH):
        with Image.open(ICON_PATH) as raw_icon:
            icon_resized = raw_icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS).convert("RGBA")
            icon_mask = Image.new("L", (icon_size, icon_size), 0)
            im_draw = ImageDraw.Draw(icon_mask)
            im_draw.rounded_rectangle([0, 0, icon_size, icon_size], radius=24, fill=255)
            
            ix, iy = 64, 56
            # Glow
            iglow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            ig_draw = ImageDraw.Draw(iglow)
            ig_draw.ellipse([ix - 24, iy - 24, ix + icon_size + 24, iy + icon_size + 24], fill=(0, 230, 118, 50))
            canvas.alpha_composite(iglow.filter(ImageFilter.GaussianBlur(24)))
            
            canvas.paste(icon_resized, (ix, iy), mask=icon_mask)
            
            # Border
            iborder = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            ibo_draw = ImageDraw.Draw(iborder)
            ibo_draw.rounded_rectangle([ix, iy, ix + icon_size, iy + icon_size], radius=24, outline=(52, 211, 153, 160), width=2)
            canvas.alpha_composite(iborder)
            
    # Pill next to icon
    font_f_pill = get_font("PlusJakartaSans.ttf", 16)
    font_f_title = get_font("PlusJakartaSans.ttf", 60)
    font_f_sub = get_font("PlusJakartaSans.ttf", 22)
    font_f_badge = get_font("PlusJakartaSans.ttf", 16)
    
    pill_text = "BITÁCORA PROFESIONAL & CALCULADORA 1% R"
    pb = font_f_pill.getbbox(pill_text)
    pw = pb[2] - pb[0] + 32
    ph = 32
    px, py = 184, 60
    
    p_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pl_draw = ImageDraw.Draw(p_layer)
    pl_draw.rounded_rectangle([px, py, px + pw, py + ph], radius=16, fill=(0, 230, 118, 25), outline=(0, 230, 118, 120), width=1)
    pl_draw.text((px + 16, py + 6), pill_text, font=font_f_pill, fill=COLOR_EMERALD)
    canvas.alpha_composite(p_layer)
    
    # Title
    t_draw = ImageDraw.Draw(canvas)
    t_draw.text((184, 100), "OmniTrade", font=font_f_title, fill=COLOR_TEXT_MAIN)
    
    # Subtitle
    t_draw.text((64, 180), "Bitácora Cuantitativa · Gestión de Riesgo · Analíticas", font=font_f_sub, fill=(226, 232, 240))
    t_draw.text((64, 218), "El terminal offline definitivo para traders que operan con disciplina", font=font_f_pill, fill=COLOR_TEXT_MUTED)
    
    # Feature Badges Row (4 Badges)
    badges = [
        ("✦ Bitácora Multi-Activo", (52, 211, 153), (6, 78, 59)),
        ("✦ Gestión 1% R", (129, 140, 248), (49, 46, 129)),
        ("✦ Métricas Institucionales", (56, 189, 248), (12, 74, 110)),
        ("✦ 100% Offline & Privado", (251, 191, 36), (120, 53, 15))
    ]
    
    cur_x = 64
    by = 280
    b_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bl_draw = ImageDraw.Draw(b_layer)
    
    for text, text_col, bg_col in badges:
        bb = font_f_badge.getbbox(text)
        bw = bb[2] - bb[0] + 32
        bh = 38
        bl_draw.rounded_rectangle(
            [cur_x, by, cur_x + bw, by + bh],
            radius=19,
            fill=(bg_col[0], bg_col[1], bg_col[2], 140),
            outline=(text_col[0], text_col[1], text_col[2], 160),
            width=1
        )
        bl_draw.text((cur_x + 16, by + 8), text, font=font_f_badge, fill=text_col)
        cur_x += bw + 14
        
    # Floating mini-cockpit metrics card preview on the right
    card_w, card_h = 340, 140
    cx, cy = 620, 330
    bl_draw.rounded_rectangle(
        [cx, cy, cx + card_w, cy + card_h],
        radius=18,
        fill=(17, 24, 39, 230),
        outline=(52, 211, 153, 100),
        width=2
    )
    # Card mini stats
    font_mini_val = get_font("PlusJakartaSans.ttf", 22)
    font_mini_lbl = get_font("PlusJakartaSans.ttf", 13)
    
    # Left column: ROI + Portfolio
    bl_draw.text((cx + 20, cy + 18), "PORTFOLIO", font=font_mini_lbl, fill=(148, 163, 184))
    bl_draw.text((cx + 20, cy + 36), "$10,000.00", font=font_mini_val, fill=COLOR_TEXT_MAIN)
    bl_draw.text((cx + 20, cy + 68), "+0.00% ROI", font=font_mini_lbl, fill=COLOR_EMERALD)
    
    # Right column: Win Rate & Profit Factor
    bl_draw.text((cx + 190, cy + 18), "WIN RATE", font=font_mini_lbl, fill=(148, 163, 184))
    bl_draw.text((cx + 190, cy + 36), "68.5%", font=font_mini_val, fill=(52, 211, 153))
    bl_draw.text((cx + 190, cy + 68), "PROFIT FACTOR: 2.4", font=font_mini_lbl, fill=(129, 140, 248))
    
    # Bottom tag
    bl_draw.rounded_rectangle([cx + 20, cy + 96, cx + card_w - 20, cy + 124], radius=6, fill=(11, 15, 25, 255))
    bl_draw.text((cx + 32, cy + 102), "ESTADÍSTICAS CUANTITATIVAS", font=font_mini_lbl, fill=(34, 211, 238))
    
    canvas.alpha_composite(b_layer)
    
    # Bottom brand footer
    font_brand = get_font("PlusJakartaSans.ttf", 14)
    brand_draw = ImageDraw.Draw(canvas)
    brand_draw.text((64, H - 36), "OMNIVERSE LABS • SEGURIDAD FINANCIERA • SQLITE LOCAL", font=font_brand, fill=(100, 116, 139))
    
    # Save PNG and JPG versions
    out_fg_png = os.path.join(PLAY_STORE_DIR, "feature_graphic_1024x500.png")
    out_fg_jpg = os.path.join(PLAY_STORE_DIR, "feature_graphic_1024x500.jpg")
    out_art_png = os.path.join(ARTIFACTS_DIR, "feature_graphic_1024x500.png")
    
    canvas.save(out_fg_png, format="PNG", optimize=True)
    canvas.save(out_art_png, format="PNG", optimize=True)
    canvas.convert("RGB").save(out_fg_jpg, format="JPEG", quality=95)
    print(f"   ✅ Saved Feature Graphic to: {out_fg_png} and {out_fg_jpg}")

if __name__ == "__main__":
    generate_screenshots()
    generate_vertical_feature()
    generate_playstore_feature_graphic_banner()
    print("\n🎉 ALL OMNITRADE STORE GRAPHICS GENERATED SUCCESSFULLY!")
