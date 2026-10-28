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

ICON_PATH = os.path.join(WORKSPACE_DIR, "apps", "omni_trade", "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset", "Icon-App-1024x1024@1x.png")
if not os.path.exists(ICON_PATH):
    ICON_PATH = os.path.join(PLAY_STORE_DIR, "icon_512x512.png")

SRC_COCKPIT = os.path.join(USER_UPLOADED_DIR, "media_1792763063874_06ffde2f.jpg")
SRC_METRICS = os.path.join(USER_UPLOADED_DIR, "media_1792763063874_b4736705.jpg")

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

# Colors
C_DARK_BG_1 = (7, 10, 16)      # #070A10
C_DARK_BG_2 = (17, 24, 39)     # #111827
C_EMERALD = (0, 230, 118)      # #00E676
C_INDIGO = (99, 102, 241)      # #6366F1
C_CRIMSON = (255, 82, 82)      # #FF5252
C_AMBER = (245, 158, 11)       # #F59E0B
C_TEXT_MAIN = (255, 255, 255)
C_TEXT_MUTED = (148, 163, 184)

def draw_trading_bg(w, h, glow_x=780, glow_y=250):
    base = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(base)

    # Diagonal radial background
    for y in range(h):
        for x in range(w):
            diag = (x * 0.65 + y * 0.35) / (w * 0.65 + h * 0.35)
            dist_glow = math.hypot(x - glow_x, y - glow_y) / (max(w, h) * 0.6)
            glow = max(0.0, 1.0 - dist_glow)
            
            r = int((7 * (1 - diag) + 16 * diag) * (1 - glow * 0.25) + 0 * glow)
            g = int((10 * (1 - diag) + 26 * diag) * (1 - glow * 0.45) + 65 * glow)
            b = int((16 * (1 - diag) + 45 * diag) * (1 - glow * 0.45) + 75 * glow)
            base.putpixel((x, y), (min(255, r), min(255, g), min(255, b), 255))

    # Grid lines
    grid = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    for x in range(0, w, 64):
        gd.line([(x, 0), (x, h)], fill=(255, 255, 255, 8), width=1)
    for y in range(0, h, 64):
        gd.line([(0, y), (w, y)], fill=(255, 255, 255, 8), width=1)
    base.alpha_composite(grid)

    # Bullish glowing trendline in the deep background
    chart = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chart)
    chart_pts = [
        (int(w * 0.45), int(h * 0.82)),
        (int(w * 0.55), int(h * 0.72)),
        (int(w * 0.65), int(h * 0.76)),
        (int(w * 0.75), int(h * 0.58)),
        (int(w * 0.85), int(h * 0.64)),
        (int(w * 0.95), int(h * 0.38)),
        (int(w * 1.02), int(h * 0.22)),
    ]
    for i in range(len(chart_pts) - 1):
        cd.line([chart_pts[i], chart_pts[i+1]], fill=(0, 230, 118, 140), width=4)
    # Area under curve
    poly = [(int(w * 0.45), h)] + chart_pts + [(int(w * 1.02), h)]
    cd.polygon(poly, fill=(0, 230, 118, 20))
    base.alpha_composite(chart)

    return base

def generate_hero_feature_graphic_1024x500():
    print("🎨 Generating 3D Hero Feature Graphic (1024 x 500 px)...")
    W, H = 1024, 500
    canvas = draw_trading_bg(W, H, glow_x=800, glow_y=240)

    # --- LEFT SECTION: App Icon + Branding + Taglines ---
    # Icon with rounded corners and glowing halo
    icon_size = 96
    ix, iy = 64, 56
    if os.path.exists(ICON_PATH):
        with Image.open(ICON_PATH) as raw_icon:
            icon_resized = raw_icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS).convert("RGBA")
            mask = Image.new("L", (icon_size, icon_size), 0)
            md = ImageDraw.Draw(mask)
            md.rounded_rectangle([0, 0, icon_size, icon_size], radius=24, fill=255)
            
            # Halo
            halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            hd = ImageDraw.Draw(halo)
            hd.ellipse([ix - 24, iy - 24, ix + icon_size + 24, iy + icon_size + 24], fill=(0, 230, 118, 55))
            canvas.alpha_composite(halo.filter(ImageFilter.GaussianBlur(24)))
            
            canvas.paste(icon_resized, (ix, iy), mask=mask)
            
            # Border
            iborder = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            bd = ImageDraw.Draw(iborder)
            bd.rounded_rectangle([ix, iy, ix + icon_size, iy + icon_size], radius=24, outline=(52, 211, 153, 180), width=2)
            canvas.alpha_composite(iborder)

    font_pill = get_font("PlusJakartaSans.ttf", 15)
    font_title = get_font("PlusJakartaSans.ttf", 60)
    font_sub = get_font("PlusJakartaSans.ttf", 22)
    font_desc = get_font("PlusJakartaSans.ttf", 16)
    font_kpi_title = get_font("PlusJakartaSans.ttf", 13)
    font_kpi_val = get_font("PlusJakartaSans.ttf", 22)
    font_kpi_sub = get_font("PlusJakartaSans.ttf", 12)

    # Pill tag
    pill_text = "BITÁCORA PROFESIONAL • CALENDARIO P&L • 100% OFFLINE"
    pb = font_pill.getbbox(pill_text)
    pw = pb[2] - pb[0] + 32
    ph = 32
    px, py = 184, 58

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle([px, py, px + pw, py + ph], radius=16, fill=(0, 230, 118, 25), outline=(0, 230, 118, 140), width=1)
    od.text((px + 16, py + 6), pill_text, font=font_pill, fill=C_EMERALD)
    canvas.alpha_composite(overlay)

    # Title "OmniTrade"
    td = ImageDraw.Draw(canvas)
    td.text((184, 98), "OmniTrade", font=font_title, fill=C_TEXT_MAIN)

    # Subtitle
    td.text((64, 180), "Bitácora Cuantitativa & Gestión de Riesgo", font=font_sub, fill=(241, 245, 249))
    td.text((64, 218), "El terminal privado para traders que operan con rigor matemático", font=font_desc, fill=C_TEXT_MUTED)

    # Feature Badges Row
    badges = [
        ("✦ Calendario P&L (Heatmap)", (52, 211, 153), (6, 78, 59)),
        ("✦ Capturas Setup / Salida", (129, 140, 248), (49, 46, 129)),
        ("✦ Gestión 1% R", (56, 189, 248), (12, 74, 110)),
        ("✦ SQLite 100% Offline", (251, 191, 36), (120, 53, 15)),
    ]
    cur_x = 64
    by = 276
    bl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bld = ImageDraw.Draw(bl)
    for text, tc, bg in badges:
        bb = font_pill.getbbox(text)
        bw = bb[2] - bb[0] + 28
        bh = 34
        bld.rounded_rectangle([cur_x, by, cur_x + bw, by + bh], radius=17, fill=(bg[0], bg[1], bg[2], 150), outline=(tc[0], tc[1], tc[2], 160), width=1)
        bld.text((cur_x + 14, by + 7), text, font=font_pill, fill=tc)
        cur_x += bw + 12
    canvas.alpha_composite(bl)

    # --- RIGHT SECTION: 3D HERO PHONE MOCKUP WITH PERSPECTIVE & FLOATING CARDS ---
    phone_w, phone_h = 240, 480
    px_pos, py_pos = 730, 40

    if os.path.exists(SRC_COCKPIT):
        with Image.open(SRC_COCKPIT) as raw_ss:
            ss_resized = raw_ss.resize((phone_w - 16, phone_h - 16), Image.Resampling.LANCZOS).convert("RGBA")
            
            # Phone shadow
            psh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            psd = ImageDraw.Draw(psh)
            psd.rounded_rectangle([px_pos - 12, py_pos + 12, px_pos + phone_w + 12, py_pos + phone_h + 20], radius=32, fill=(0, 0, 0, 220))
            psd.rounded_rectangle([px_pos - 24, py_pos - 8, px_pos + phone_w + 24, py_pos + phone_h + 8], radius=36, fill=(0, 230, 118, 40))
            canvas.alpha_composite(psh.filter(ImageFilter.GaussianBlur(24)))

            # Phone chassis
            phone = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
            pd = ImageDraw.Draw(phone)
            pd.rounded_rectangle([0, 0, phone_w, phone_h], radius=28, fill=(17, 24, 39, 255), outline=(51, 65, 85, 255), width=2)
            
            # Screen paste
            s_mask = Image.new("L", (phone_w - 16, phone_h - 16), 0)
            smd = ImageDraw.Draw(s_mask)
            smd.rounded_rectangle([0, 0, phone_w - 16, phone_h - 16], radius=22, fill=255)
            phone.paste(ss_resized, (8, 8), mask=s_mask)
            
            # Subtle camera punch hole
            pd.rounded_rectangle([phone_w // 2 - 24, 12, phone_w // 2 + 24, 22], radius=5, fill=(5, 7, 10, 255))
            
            canvas.alpha_composite(phone, (px_pos, py_pos))

    # --- FLOATING KPI CARDS WITH 3D GLASS EFFECT ---
    # Floating Card 1: Win Rate & Profit Factor (Top Left of phone)
    fc1_w, fc1_h = 220, 92
    fc1_x, fc1_y = 560, 110
    
    fc1_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fcd1 = ImageDraw.Draw(fc1_layer)
    # Shadow
    fcd1.rounded_rectangle([fc1_x - 4, fc1_y + 8, fc1_x + fc1_w + 4, fc1_y + fc1_h + 12], radius=18, fill=(0, 0, 0, 180))
    fc1_shadow = fc1_layer.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(fc1_shadow)

    fc1_box = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fcd1_box = ImageDraw.Draw(fc1_box)
    fcd1_box.rounded_rectangle([fc1_x, fc1_y, fc1_x + fc1_w, fc1_y + fc1_h], radius=16, fill=(17, 24, 39, 235), outline=(52, 211, 153, 140), width=1)
    # Content
    fcd1_box.text((fc1_x + 16, fc1_y + 14), "WIN RATE", font=font_kpi_title, fill=C_TEXT_MUTED)
    fcd1_box.text((fc1_x + 16, fc1_y + 32), "68.5%", font=font_kpi_val, fill=C_EMERALD)
    fcd1_box.text((fc1_x + 16, fc1_y + 64), "Profit Factor: 2.40", font=font_kpi_sub, fill=(129, 140, 248))
    # Mini Icon
    fcd1_box.ellipse([fc1_x + fc1_w - 44, fc1_y + 16, fc1_x + fc1_w - 16, fc1_y + 44], fill=(0, 230, 118, 30))
    fcd1_box.text((fc1_x + fc1_w - 36, fc1_y + 20), "▲", font=font_pill, fill=C_EMERALD)
    canvas.alpha_composite(fc1_box)

    # Floating Card 2: Net P&L & Heatmap (Bottom Left of phone)
    fc2_w, fc2_h = 240, 96
    fc2_x, fc2_y = 540, 320
    
    fc2_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fcd2 = ImageDraw.Draw(fc2_layer)
    fcd2.rounded_rectangle([fc2_x - 4, fc2_y + 8, fc2_x + fc2_w + 4, fc2_y + fc2_h + 12], radius=18, fill=(0, 0, 0, 180))
    fc2_shadow = fc2_layer.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(fc2_shadow)

    fc2_box = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fcd2_box = ImageDraw.Draw(fc2_box)
    fcd2_box.rounded_rectangle([fc2_x, fc2_y, fc2_x + fc2_w, fc2_y + fc2_h], radius=16, fill=(17, 24, 39, 235), outline=(99, 102, 241, 140), width=1)
    # Content
    fcd2_box.text((fc2_x + 16, fc2_y + 14), "NET P&L REALIZADO", font=font_kpi_title, fill=C_TEXT_MUTED)
    fcd2_box.text((fc2_x + 16, fc2_y + 32), "+$1,250.00", font=font_kpi_val, fill=C_EMERALD)
    fcd2_box.text((fc2_x + 16, fc2_y + 66), "✦ Calendario: 14 Verdes • 4 Rojos", font=font_kpi_sub, fill=(56, 189, 248))
    canvas.alpha_composite(fc2_box)

    # Footer
    font_footer = get_font("PlusJakartaSans.ttf", 13)
    fd = ImageDraw.Draw(canvas)
    fd.text((64, H - 36), "OMNIVERSE LABS • SEGURIDAD FINANCIERA • SQLITE LOCAL • SIN CLOUD", font=font_footer, fill=(100, 116, 139))

    # Save PNG and JPG
    out_png = os.path.join(PLAY_STORE_DIR, "feature_graphic_1024x500.png")
    out_jpg = os.path.join(PLAY_STORE_DIR, "feature_graphic_1024x500.jpg")
    out_art = os.path.join(ARTIFACTS_DIR, "feature_graphic_1024x500.png")
    
    canvas.save(out_png, format="PNG", optimize=True)
    canvas.save(out_art, format="PNG", optimize=True)
    canvas.convert("RGB").save(out_jpg, format="JPEG", quality=95)
    print(f"   ✅ Saved: {out_png}")

def generate_vertical_hero_poster_1080x1920():
    print("⭐ Generating Vertical 3D Hero Poster (1080 x 1920 px)...")
    W, H = 1080, 1920
    canvas = draw_trading_bg(W, H, glow_x=540, glow_y=750)

    # --- TOP HEADER: Icon, Title, Badges ---
    font_pill = get_font("PlusJakartaSans.ttf", 22)
    font_hero = get_font("PlusJakartaSans.ttf", 64)
    font_sub = get_font("PlusJakartaSans.ttf", 28)
    font_desc = get_font("PlusJakartaSans.ttf", 22)
    font_kpi_title = get_font("PlusJakartaSans.ttf", 18)
    font_kpi_val = get_font("PlusJakartaSans.ttf", 34)
    font_kpi_sub = get_font("PlusJakartaSans.ttf", 17)

    # Top Pill
    pill_text = "SISTEMA INTEGRAL DE TRADING"
    pb = font_pill.getbbox(pill_text)
    pw = pb[2] - pb[0] + 48
    ph = 44
    px = (W - pw) // 2
    py = 64

    ol = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    old = ImageDraw.Draw(ol)
    old.rounded_rectangle([px, py, px + pw, py + ph], radius=22, fill=(0, 230, 118, 25), outline=(0, 230, 118, 140), width=2)
    old.text((px + 24, py + 8), pill_text, font=font_pill, fill=C_EMERALD)
    canvas.alpha_composite(ol)

    # Title & Subtitle
    td = ImageDraw.Draw(canvas)
    title = "OmniTrade"
    tb = font_hero.getbbox(title)
    tw = tb[2] - tb[0]
    td.text(((W - tw) // 2, 136), title, font=font_hero, fill=C_TEXT_MAIN)

    subtitle = "Bitácora Cuantitativa · Calendario P&L · Analíticas"
    sb = font_sub.getbbox(subtitle)
    sw = sb[2] - sb[0]
    td.text(((W - sw) // 2, 218), subtitle, font=font_sub, fill=(226, 232, 240))

    tagline = "El terminal offline definitivo para traders disciplinados"
    tgb = font_desc.getbbox(tagline)
    tgw = tgb[2] - tgb[0]
    td.text(((W - tgw) // 2, 260), tagline, font=font_desc, fill=C_TEXT_MUTED)

    # --- CENTER HERO PHONE ---
    phone_w, phone_h = 620, 1020
    phone_x = (W - phone_w) // 2
    phone_y = 340

    if os.path.exists(SRC_COCKPIT):
        with Image.open(SRC_COCKPIT) as raw_ss:
            ss_resized = raw_ss.resize((phone_w - 24, phone_h - 24), Image.Resampling.LANCZOS).convert("RGBA")

            # Dual soft drop shadow
            psh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            psd = ImageDraw.Draw(psh)
            psd.rounded_rectangle([phone_x - 16, phone_y + 24, phone_x + phone_w + 16, phone_y + phone_h + 36], radius=48, fill=(0, 0, 0, 220))
            psd.rounded_rectangle([phone_x - 32, phone_y - 12, phone_x + phone_w + 32, phone_y + phone_h + 12], radius=52, fill=(0, 230, 118, 50))
            canvas.alpha_composite(psh.filter(ImageFilter.GaussianBlur(32)))

            # Phone chassis
            phone = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
            pd = ImageDraw.Draw(phone)
            pd.rounded_rectangle([0, 0, phone_w, phone_h], radius=44, fill=(17, 24, 39, 255), outline=(51, 65, 85, 255), width=3)
            
            # Screen paste
            s_mask = Image.new("L", (phone_w - 24, phone_h - 24), 0)
            smd = ImageDraw.Draw(s_mask)
            smd.rounded_rectangle([0, 0, phone_w - 24, phone_h - 24], radius=36, fill=255)
            phone.paste(ss_resized, (12, 12), mask=s_mask)

            # Punch hole
            pd.rounded_rectangle([phone_w // 2 - 36, 18, phone_w // 2 + 36, 32], radius=7, fill=(5, 7, 10, 255))
            canvas.alpha_composite(phone, (phone_x, phone_y))

    # --- FLOATING 3D GLASS KPI CARDS (Left & Right) ---
    # Card Left: Win Rate & Profit Factor
    c1_w, c1_h = 320, 140
    c1_x, c1_y = 48, 480

    c1_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd1 = ImageDraw.Draw(c1_layer)
    cd1.rounded_rectangle([c1_x - 6, c1_y + 12, c1_x + c1_w + 6, c1_y + c1_h + 16], radius=24, fill=(0, 0, 0, 200))
    canvas.alpha_composite(c1_layer.filter(ImageFilter.GaussianBlur(18)))

    c1_box = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd1b = ImageDraw.Draw(c1_box)
    cd1b.rounded_rectangle([c1_x, c1_y, c1_x + c1_w, c1_y + c1_h], radius=22, fill=(17, 24, 39, 240), outline=(52, 211, 153, 160), width=2)
    cd1b.text((c1_x + 24, c1_y + 20), "VENTAJA CUANTITATIVA", font=font_kpi_title, fill=C_TEXT_MUTED)
    cd1b.text((c1_x + 24, c1_y + 46), "68.5% WIN RATE", font=font_kpi_val, fill=C_EMERALD)
    cd1b.text((c1_x + 24, c1_y + 96), "Profit Factor: 2.40 • R:R 1:2.5", font=font_kpi_sub, fill=(129, 140, 248))
    canvas.alpha_composite(c1_box)

    # Card Right: P&L Calendar Heatmap
    c2_w, c2_h = 330, 140
    c2_x, c2_y = W - c2_w - 48, 880

    c2_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd2 = ImageDraw.Draw(c2_layer)
    cd2.rounded_rectangle([c2_x - 6, c2_y + 12, c2_x + c2_w + 6, c2_y + c2_h + 16], radius=24, fill=(0, 0, 0, 200))
    canvas.alpha_composite(c2_layer.filter(ImageFilter.GaussianBlur(18)))

    c2_box = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd2b = ImageDraw.Draw(c2_box)
    cd2b.rounded_rectangle([c2_x, c2_y, c2_x + c2_w, c2_y + c2_h], radius=22, fill=(17, 24, 39, 240), outline=(99, 102, 241, 160), width=2)
    cd2b.text((c2_x + 24, c2_y + 20), "CALENDARIO P&L MENSUAL", font=font_kpi_title, fill=C_TEXT_MUTED)
    cd2b.text((c2_x + 24, c2_y + 46), "+$1,250.00 NET", font=font_kpi_val, fill=C_EMERALD)
    cd2b.text((c2_x + 24, c2_y + 96), "🟢 14 Días Verdes • 🔴 4 Rojos", font=font_kpi_sub, fill=(56, 189, 248))
    canvas.alpha_composite(c2_box)

    # --- BOTTOM BENTO HIGHLIGHTS (4 Pillars) ---
    pillars = [
        ("✦ Bitácora Multi-Activo", "Crypto, Stocks, Forex, Futuros & Opciones con capturas de gráficos"),
        ("✦ Gestión de Riesgo 1% R", "Dimensionamiento de posición y ratio R:R calculado en tiempo real"),
        ("✦ Calendario P&L (Heatmap)", "Visualiza tus días verdes/rojos y audita tu consistencia mensual"),
        ("✦ 100% Offline & Biometría", "SQLite local encriptado, PIN/huella dactilar y exportación CSV"),
    ]

    py_start = 1400
    for idx, (p_title, p_desc) in enumerate(pillars):
        cy = py_start + (idx * 110)
        card_w = 984
        cx = (W - card_w) // 2

        card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        cd = ImageDraw.Draw(card)
        cd.rounded_rectangle([cx, cy, cx + card_w, cy + 96], radius=18, fill=(17, 24, 39, 215), outline=(45, 60, 85, 200), width=1)
        cd.text((cx + 24, cy + 18), p_title, font=font_kpi_title, fill=C_EMERALD)
        cd.text((cx + 24, cy + 50), p_desc, font=font_kpi_sub, fill=(203, 213, 225))
        canvas.alpha_composite(card)

    # Bottom footer
    font_footer = get_font("PlusJakartaSans.ttf", 20)
    footer_text = "OMNIVERSE LABS • PRIVACIDAD FINANCIERA • 100% OFFLINE"
    fb = font_footer.getbbox(footer_text)
    fw = fb[2] - fb[0]
    fx = (W - fw) // 2
    fy = H - 64
    draw = ImageDraw.Draw(canvas)
    draw.text((fx, fy), footer_text, font=font_footer, fill=(100, 116, 139))

    # Save
    out_vert_play = os.path.join(PLAY_STORE_DIR, "screenshot_04_feature_vertical.png")
    out_vert_art = os.path.join(ARTIFACTS_DIR, "screenshot_04_feature_vertical.png")
    canvas.save(out_vert_play, format="PNG", optimize=True)
    canvas.save(out_vert_art, format="PNG", optimize=True)
    print(f"   ✅ Saved: {out_vert_play}")

if __name__ == "__main__":
    generate_hero_feature_graphic_1024x500()
    generate_vertical_hero_poster_1080x1920()
    print("\n🎉 ALL HERO FEATURE GRAPHICS GENERATED SUCCESSFULLY!")
