import os, math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONTS_DIR = r"c:\Projects\Omniverse Labs\fonts"
ARTIFACTS_DIR = r"C:\Users\leobe\.gemini\antigravity\brain\0ee6d9d4-7c6e-486c-a4ba-8d4cb2a923f8"
UPLOADED_DIR = os.path.join(ARTIFACTS_DIR, ".user_uploaded")
CHARLEMOS_DIR = r"c:\Projects\Omniverse Labs\apps\charlemos\assets\store_listing"
RITMO_STORE_DIR = r"c:\Projects\Omniverse Labs\apps\rutina_journal\assets\store_listing"
RITMO_IMG_DIR = r"c:\Projects\Omniverse Labs\apps\rutina_journal\assets\images"
MENULISTO_DIR = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\store"
MENUS_OLD_BG = r"C:\Users\leobe\.gemini\antigravity\brain\42c1dcb7-5fbf-451b-91ce-5d992d2e93a3\menu_listo_feature_1788439824065.jpg"
W, H = 1024, 500

def font(name, size):
    for base in [FONTS_DIR, r"C:\Windows\Fonts"]:
        p = os.path.join(base, name)
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    raise FileNotFoundError(f"Font not found: {name}")

def fit_cover(img, w, h):
    ratio = max(w / img.width, h / img.height)
    nw, nh = int(img.width * ratio), int(img.height * ratio)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2; y = (nh - h) // 2
    return img.crop((x, y, x + w, y + h))

def rounded_rect_mask(w, h, r):
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, w-1, h-1], radius=r, fill=255)
    return mask

def phone_mockup(screenshot_path, target_h, corner_r=32):
    """Create phone shell + cropped screenshot, returns RGBA."""
    ph_w = int(target_h * 9 / 19.5)
    ph_h = target_h
    with Image.open(screenshot_path) as ss:
        ss = fit_cover(ss.convert("RGBA"), ph_w - 10, ph_h - 10)
    phone = Image.new("RGBA", (ph_w, ph_h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(phone)
    sd.rounded_rectangle([0, 0, ph_w, ph_h], radius=corner_r, fill=(22, 22, 24, 255))
    screen = Image.new("RGBA", (ph_w - 10, ph_h - 10), (0, 0, 0, 255))
    screen.paste(ss, (0, 0))
    mask = rounded_rect_mask(ph_w - 10, ph_h - 10, corner_r - 5)
    phone.paste(screen, (5, 5), mask=mask)
    return phone

def drop_shadow(canvas_rgb, element_rgba, pos, blur=20, opacity=80):
    """Composite a blurred dark shadow then the element onto canvas (RGB)."""
    tmp = Image.new("RGBA", canvas_rgb.size, (0, 0, 0, 0))
    shadow_solid = Image.new("RGBA", element_rgba.size, (0, 0, 0, opacity))
    tmp.paste(shadow_solid, pos, mask=element_rgba.split()[3])
    blurred = tmp.filter(ImageFilter.GaussianBlur(blur))
    canvas_rgb.paste(blurred.convert("RGB"),
                     mask=blurred.split()[3])
    canvas_rgb.paste(element_rgba.convert("RGB"), pos, mask=element_rgba.split()[3])

def pill(draw, x, y, w, h, r, bg_rgb, border_rgb, border_w=1):
    """Draw a solid opaque pill on a draw object."""
    draw.rounded_rectangle([x, y, x+w, y+h], radius=r, fill=bg_rgb, outline=border_rgb, width=border_w)

# ============================================================
# 1. CHARLEMOS — crimson gradient, Pacifico title
# ============================================================
def gen_charlemos():
    print("Generating Charlemos...")
    # Build gradient on plain RGB image
    img = Image.new("RGB", (W, H))
    cx, cy = W * 0.40, H * 0.45
    max_r = math.hypot(W, H) * 0.72
    pixels = []
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - cx, y - cy)
            t = min(d / max_r, 1.0)
            pixels.append((int(139 + (38-139)*t), int(26 + (3-26)*t), int(42 + (8-42)*t)))
    img.putdata(pixels)

    # Grain overlay
    random.seed(42)
    grain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grain)
    for _ in range(15000):
        gx2 = random.randint(0, W-1); gy2 = random.randint(0, H-1)
        v = random.randint(210, 255); a = random.randint(0, 14)
        gd.point((gx2, gy2), fill=(v, v, v, a))
    img.paste(grain.convert("RGB"), mask=grain.split()[3])

    # Phone mockups (right side)
    card_ss = os.path.join(CHARLEMOS_DIR, "screenshot_03_gameplay_parejas.png")
    card_dk = os.path.join(CHARLEMOS_DIR, "screenshot_01_decks.png")
    if os.path.exists(card_dk):
        bm = phone_mockup(card_dk, 355, 24).rotate(-9, expand=True, resample=Image.Resampling.BICUBIC)
        bx = W - bm.width - 12; by = (H - bm.height)//2 + 38
        drop_shadow(img, bm, (bx, by), blur=18, opacity=65)
    if os.path.exists(card_ss):
        mm = phone_mockup(card_ss, 388, 28).rotate(5, expand=True, resample=Image.Resampling.BICUBIC)
        mx = W - mm.width - 62; my = (H - mm.height)//2 - 6
        drop_shadow(img, mm, (mx, my), blur=22, opacity=75)

    draw = ImageDraw.Draw(img)

    # App icon (white circle bg for clean look)
    ip = os.path.join(CHARLEMOS_DIR, "app_icon_512x512.png")
    if os.path.exists(ip):
        with Image.open(ip) as ic:
            ic = ic.convert("RGBA").resize((116, 116), Image.Resampling.LANCZOS)
        # draw circle bg
        circle_bg = Image.new("RGBA", (124, 124), (0,0,0,0))
        cd = ImageDraw.Draw(circle_bg)
        cd.ellipse([0,0,123,123], fill=(255,255,255,255))
        img.paste(circle_bg.convert("RGB"), (44, 44), mask=circle_bg.split()[3])
        img.paste(ic.convert("RGB"), (48, 48), mask=ic.split()[3])

    # Badge pill — white semi-transparent
    f_tag = font("Outfit.ttf", 14)
    tag_txt = "JUEGO DE CARTAS & CONEXION"
    tb = f_tag.getbbox(tag_txt); tw = tb[2]-tb[0]+28; th = 30
    tx, ty = 46, 183
    # Draw pill as semi-transparent RGBA then paste
    pill_img = Image.new("RGBA", (tw, th), (0,0,0,0))
    pd = ImageDraw.Draw(pill_img)
    pd.rounded_rectangle([0,0,tw,th], radius=15, fill=(255,255,255,55), outline=(255,255,255,120), width=1)
    img.paste(pill_img.convert("RGB"), (tx, ty), mask=pill_img.split()[3])
    draw = ImageDraw.Draw(img)
    draw.text((tx+14, ty+7), tag_txt, font=f_tag, fill=(255, 240, 235))

    # Title with soft glow
    f_title = font("Pacifico.ttf", 88)
    # glow pass
    glow_layer = Image.new("RGBA", (W, H), (0,0,0,0))
    gld = ImageDraw.Draw(glow_layer)
    gld.text((46, 220), "Charlemos", font=f_title, fill=(255, 140, 110, 60))
    glow_blurred = glow_layer.filter(ImageFilter.GaussianBlur(14))
    img.paste(glow_blurred.convert("RGB"), mask=glow_blurred.split()[3])
    draw = ImageDraw.Draw(img)
    draw.text((46, 220), "Charlemos", font=f_title, fill=(255, 255, 255))

    # Tagline
    draw.text((52, 338), "Conversaciones que conectan", font=font("Outfit.ttf", 22), fill=(255, 205, 190))

    # Brand
    draw.text((52, 464), "OMNIVERSE LABS", font=font("Outfit.ttf", 13), fill=(200, 160, 145))

    out = os.path.join(CHARLEMOS_DIR, "feature_graphic_1024x500.png")
    img.save(out, "PNG")
    prev = os.path.join(ARTIFACTS_DIR, "charlemos_feature_preview.png")
    img.save(prev, "PNG")
    print(f"  Saved: {out}"); return prev

# ============================================================
# 2. RITMO — clean sage gradient BG, DM Serif Display title
# ============================================================
def gen_ritmo():
    print("Generating Ritmo...")
    # Build clean sage gradient (no existing image with text)
    img = Image.new("RGB", (W, H))
    pixels = []
    for y in range(H):
        for x in range(W):
            # Top-left lighter, bottom-right slightly darker sage
            tx2 = x / W; ty2 = y / H
            base_r, base_g, base_b = 230, 238, 222  # light sage
            dark_r, dark_g, dark_b = 198, 216, 186  # deeper sage
            t2 = tx2 * 0.4 + ty2 * 0.6
            pixels.append((
                int(base_r + (dark_r - base_r) * t2),
                int(base_g + (dark_g - base_g) * t2),
                int(base_b + (dark_b - base_b) * t2),
            ))
    img.putdata(pixels)

    # Organic blob shapes (decorative, top-right area)
    blob_layer = Image.new("RGBA", (W, H), (0,0,0,0))
    bd = ImageDraw.Draw(blob_layer)
    # Large ellipse top-right
    bd.ellipse([620, -80, 1100, 340], fill=(210, 228, 200, 60))
    bd.ellipse([750, 200, 1150, 560], fill=(185, 212, 172, 45))
    # Small accent bottom-left
    bd.ellipse([-60, 300, 200, 560], fill=(210, 228, 200, 40))
    img.paste(blob_layer.convert("RGB"), mask=blob_layer.split()[3])

    # Phone mockup (right) — use user-uploaded screenshot
    rss = os.path.join(UPLOADED_DIR, "media_1788890284787.jpg")
    if os.path.exists(rss):
        ph = phone_mockup(rss, 418, 34)
        px = W - ph.width - 30; py = (H - ph.height)//2
        drop_shadow(img, ph, (px, py), blur=26, opacity=60)

    draw = ImageDraw.Draw(img)

    # Ritmo emblem icon
    ep = os.path.join(RITMO_IMG_DIR, "ritmo_emblem.png")
    if os.path.exists(ep):
        with Image.open(ep) as em:
            em = em.convert("RGBA")
            ew = int(92 * em.width / em.height)
            em = em.resize((ew, 92), Image.Resampling.LANCZOS)
        img.paste(em.convert("RGB"), (44, 44), mask=em.split()[3])

    # Badge pill — solid light green
    f_tag = font("Outfit.ttf", 13)
    tag_txt = "HABITOS - RUTINAS - DIARIO"
    tb = f_tag.getbbox(tag_txt); tw = tb[2]-tb[0]+26; tx, ty = 44, 156
    draw.rounded_rectangle([tx, ty, tx+tw, ty+26], radius=13,
                            fill=(200, 226, 188), outline=(140, 190, 120), width=1)
    draw.text((tx+13, ty+6), tag_txt, font=f_tag, fill=(30, 65, 12))

    # Title — DM Serif Display, dark forest green
    f_title = font("DMSerifDisplay.ttf", 100)
    # Subtle white glow
    gl = Image.new("RGBA", (W, H), (0,0,0,0))
    gld = ImageDraw.Draw(gl)
    gld.text((44, 190), "Ritmo", font=f_title, fill=(255,255,255,55))
    glb = gl.filter(ImageFilter.GaussianBlur(8))
    img.paste(glb.convert("RGB"), mask=glb.split()[3])
    draw = ImageDraw.Draw(img)
    draw.text((44, 190), "Ritmo", font=f_title, fill=(24, 54, 10))

    # Subtitle
    draw.text((48, 330), "Construye tus mejores habitos", font=font("lora.ttf", 22), fill=(38, 68, 18))

    # Feature pills — solid light sage
    f_pill = font("Outfit.ttf", 15)
    px_c = 48; py_p = 372
    for p in ["100% Offline", "Privacidad Total"]:
        pb = f_pill.getbbox(p); pw = pb[2]-pb[0]+24
        draw.rounded_rectangle([px_c, py_p, px_c+pw, py_p+30], radius=15,
                                fill=(195, 222, 182), outline=(130, 180, 110), width=1)
        draw.text((px_c+12, py_p+7), p, font=f_pill, fill=(28, 60, 12))
        px_c += pw + 10

    # Brand
    draw.text((48, 464), "OMNIVERSE LABS", font=font("Outfit.ttf", 13), fill=(85, 120, 60))

    os.makedirs(RITMO_STORE_DIR, exist_ok=True)
    out = os.path.join(RITMO_STORE_DIR, "feature_graphic_1024x500.png")
    img.save(out, "PNG")
    also = os.path.join(RITMO_IMG_DIR, "store", "feature_graphic_1024x500.jpg")
    img.save(also, "JPEG", quality=95)
    prev = os.path.join(ARTIFACTS_DIR, "ritmo_feature_preview.png")
    img.save(prev, "PNG")
    print(f"  Saved: {out}"); return prev

# ============================================================
# 3. MENU LISTO — food photo BG, Shrikhand title
# ============================================================
def gen_menulisto():
    print("Generating Menu Listo...")
    with Image.open(MENUS_OLD_BG) as b:
        img = fit_cover(b.convert("RGB"), W, H)

    # Left parchment gradient overlay for legibility
    wash = Image.new("RGBA", (W, H), (0,0,0,0))
    wd = ImageDraw.Draw(wash)
    for x in range(620):
        t = x / 620
        a = int(158 * (1 - t)**1.7)
        wd.line([(x,0),(x,H)], fill=(255, 252, 240, a))
    img.paste(wash.convert("RGB"), mask=wash.split()[3])

    # Phone mockup (right)
    mss = os.path.join(UPLOADED_DIR, "media_1788890284786.jpg")
    if os.path.exists(mss):
        ph = phone_mockup(mss, 418, 34)
        px = W - ph.width - 26; py = (H - ph.height)//2
        drop_shadow(img, ph, (px, py), blur=24, opacity=55)

    draw = ImageDraw.Draw(img)

    # App icon
    ip = r"c:\Projects\Omniverse Labs\apps\menu_listo\assets\images\app_icon.png"
    if os.path.exists(ip):
        with Image.open(ip) as ic:
            ic = ic.convert("RGBA").resize((96, 96), Image.Resampling.LANCZOS)
        img.paste(ic.convert("RGB"), (46, 46), mask=ic.split()[3])

    # Badge pill — solid olive green
    f_tag = font("Outfit.ttf", 13)
    tag_txt = "ASISTENTE CULINARIO"
    tb = f_tag.getbbox(tag_txt); tw = tb[2]-tb[0]+26; tx, ty = 154, 68
    draw.rounded_rectangle([tx, ty, tx+tw, ty+26], radius=13,
                            fill=(215, 228, 200), outline=(150, 175, 120), width=1)
    draw.text((tx+13, ty+6), tag_txt, font=f_tag, fill=(32, 48, 20))

    # Title — Shrikhand, dark olive
    f_title = font("Shrikhand.ttf", 86)
    gl = Image.new("RGBA", (W, H), (0,0,0,0))
    gld = ImageDraw.Draw(gl)
    gld.text((46, 178), "Menu Listo", font=f_title, fill=(255,255,255,80))
    glb = gl.filter(ImageFilter.GaussianBlur(10))
    img.paste(glb.convert("RGB"), mask=glb.split()[3])
    draw = ImageDraw.Draw(img)
    draw.text((46, 178), "Menu Listo", font=f_title, fill=(30, 44, 18))

    # Subtitle — single line
    draw.text((50, 308), "Recetas - Planificador - Lista de Compras", font=font("lora.ttf", 22), fill=(42, 58, 28))

    # Feature pills — solid
    f_pill = font("Outfit.ttf", 15)
    px_c = 50; py_p = 354
    for p in ["Modo Manos Libres", "Escaneo OCR", "100% Offline"]:
        pb = f_pill.getbbox(p); pw = pb[2]-pb[0]+24
        draw.rounded_rectangle([px_c, py_p, px_c+pw, py_p+30], radius=15,
                                fill=(210, 225, 195), outline=(145, 175, 115), width=1)
        draw.text((px_c+12, py_p+7), p, font=f_pill, fill=(30, 46, 18))
        px_c += pw + 10

    # Brand
    draw.text((50, 464), "OMNIVERSE LABS", font=font("Outfit.ttf", 13), fill=(90, 110, 65))

    out = os.path.join(MENULISTO_DIR, "feature_graphic_1024x500.png")
    img.save(out, "PNG")
    prev = os.path.join(ARTIFACTS_DIR, "menulisto_feature_preview.png")
    img.save(prev, "PNG")
    print(f"  Saved: {out}"); return prev

c = gen_charlemos()
r = gen_ritmo()
m = gen_menulisto()
print("\nAll done!"); print(c); print(r); print(m)
