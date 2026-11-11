import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = r"c:\Projects\Omniverse Labs"
APP_DIR = os.path.join(REPO_ROOT, "apps", "pulse_pocket")
OUT_DIR = os.path.join(APP_DIR, "store_assets", "play_store")
ASSETS_IMG = os.path.join(APP_DIR, "assets", "images")
ANDROID_RES = os.path.join(APP_DIR, "android", "app", "src", "main", "res")
FONTS_DIR = os.path.join(REPO_ROOT, "fonts")

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(ASSETS_IMG, exist_ok=True)

# Omniverse Labs Utility Design Tokens (matching CancelGuard)
BG = (9, 11, 14, 255)          # #090B0E
SURFACE = (18, 22, 28, 255)    # #12161C
ELEVATED = (27, 33, 42, 255)   # #1B212A
BORDER = (38, 47, 59, 255)     # #262F3B
TEXT_1 = (244, 247, 250, 255)  # #F4F7FA
TEXT_2 = (154, 166, 184, 255)  # #9AA6B8
EMERALD = (16, 185, 129, 255)  # #10B981
ON_EMERALD = (4, 34, 23, 255)  # #042217
EMERALD_TINT = (15, 43, 34, 255)
AMBER = (245, 158, 11, 255)    # #F59E0B
AMBER_TINT = (43, 32, 13, 255)
CORAL = (251, 113, 133, 255)   # #FB7185

F_BOLD = ["ClashGrotesk-Bold.ttf", "PlusJakartaSans.ttf", "arialbd.ttf"]
F_REG = ["PlusJakartaSans.ttf", "Outfit.ttf", "montserrat.ttf", "arial.ttf"]


def load_font(candidates, size):
    for name in candidates:
        path = os.path.join(FONTS_DIR, name)
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
        try:
            return ImageFont.truetype(name, size)
        except Exception:
            pass
    return ImageFont.load_default()


def add_radial_glow(base: Image.Image, cx: int, cy: int, radius: int, color_rgb: tuple, max_alpha: int):
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(*color_rgb, max_alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(12, radius // 2)))
    return Image.alpha_composite(base, glow)


def center_x(draw, text, font, container_w, origin_x=0):
    box = draw.textbbox((0, 0), text, font=font)
    w = box[2] - box[0]
    return origin_x + (container_w - w) // 2


def draw_pulse_emblem(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float):
    """Crisp concentric haptic pulse emblem + amber Beat-1 accent dot + lock arch."""
    # Outer dark elevated ring
    r_outer = 148 * scale
    draw.ellipse(
        [cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer],
        fill=EMERALD_TINT,
        outline=EMERALD,
        width=max(3, int(10 * scale)),
    )
    # Middle haptic wave ring
    r_mid = 104 * scale
    draw.ellipse(
        [cx - r_mid, cy - r_mid, cx + r_mid, cy + r_mid],
        outline=(16, 185, 129, 145),
        width=max(2, int(6 * scale)),
    )
    # Inner core circle
    r_core = 54 * scale
    draw.ellipse(
        [cx - r_core, cy - r_core, cx + r_core, cy + r_core],
        fill=(12, 26, 23, 255),
        outline=EMERALD,
        width=max(3, int(8 * scale)),
    )
    # Center silent pulse waveform bar + amber Beat 1 accent dot at top of outer ring
    w_bar = max(4, int(12 * scale))
    bars = [(-22, 18), (0, 34), (22, 18)]
    for dx, h_half in bars:
        x_pos = cx + dx * scale
        draw.line(
            [(x_pos, cy - h_half * scale), (x_pos, cy + h_half * scale)],
            fill=EMERALD,
            width=w_bar,
        )
    # Beat 1 Amber accent orb at top 12-o'clock position
    r_orb = 18 * scale
    orb_cy = cy - r_mid
    draw.ellipse(
        [cx - r_orb, orb_cy - r_orb, cx + r_orb, orb_cy + r_orb],
        fill=AMBER,
        outline=BG,
        width=max(2, int(4 * scale)),
    )


def build_icons():
    size = 512
    img = Image.new("RGBA", (size, size), BG)
    img = add_radial_glow(img, 256, 256, 210, (16, 185, 129), 65)
    img = add_radial_glow(img, 256, 150, 90, (245, 158, 11), 35)
    d = ImageDraw.Draw(img)

    d.rounded_rectangle([18, 18, 494, 494], radius=108, fill=(14, 18, 24, 245), outline=BORDER, width=4)
    draw_pulse_emblem(d, 256, 256, 1.05)

    out_store = os.path.join(OUT_DIR, "icon_512x512.png")
    img.save(out_store, "PNG")
    print(f"Saved: {out_store}")

    # App asset logo
    app_logo = img.resize((256, 256), Image.Resampling.LANCZOS)
    app_logo_path = os.path.join(ASSETS_IMG, "app_logo.png")
    app_logo.save(app_logo_path, "PNG")
    print(f"Saved: {app_logo_path}")

    # Android mipmap launcher icons
    mipmaps = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in mipmaps.items():
        target_dir = os.path.join(ANDROID_RES, folder)
        os.makedirs(target_dir, exist_ok=True)
        resized = img.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(os.path.join(target_dir, "ic_launcher.png"), "PNG")


def build_feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGBA", (w, h), BG)
    img = add_radial_glow(img, 220, 250, 260, (16, 185, 129), 52)
    img = add_radial_glow(img, 860, 260, 220, (245, 158, 11), 32)
    d = ImageDraw.Draw(img)

    f_badge = load_font(F_BOLD, 18)
    f_title = load_font(F_BOLD, 66)
    f_sub = load_font(F_REG, 27)
    f_pill = load_font(F_BOLD, 20)

    draw_pulse_emblem(d, 175, 250, 0.88)

    tx = 345
    d.rounded_rectangle([tx, 74, tx + 295, 114], radius=20, fill=EMERALD_TINT, outline=EMERALD, width=1)
    d.text((tx + 18, 84), "OMNIVERSE LABS UTILITY", font=f_badge, fill=EMERALD)

    d.text((tx, 136), "PulsePocket", font=f_title, fill=TEXT_1)
    d.text((tx, 218), "Silent Pocket Metronome & Tap Tempo.", font=f_sub, fill=TEXT_2)
    d.text((tx, 254), "Zero mic bleed. Pocket Lock stage guard.", font=f_sub, fill=TEXT_2)

    pills = [
        ("Silent Haptic", EMERALD_TINT, EMERALD),
        ("Pocket Lock", ELEVATED, TEXT_1),
        ("$1.49 Once", AMBER_TINT, AMBER),
    ]
    px = tx
    for label, fill_c, text_c in pills:
        bw = d.textbbox((0, 0), label, font=f_pill)[2] + 34
        d.rounded_rectangle([px, 326, px + bw, 376], radius=25, fill=fill_c, outline=BORDER, width=1)
        d.text((px + 17, 340), label, font=f_pill, fill=text_c)
        px += bw + 14

    out_png = os.path.join(OUT_DIR, "feature_graphic_1024x500.png")
    out_jpg = os.path.join(OUT_DIR, "feature_graphic_1024x500.jpg")
    img.save(out_png, "PNG")
    img.convert("RGB").save(out_jpg, "JPEG", quality=95)
    print(f"Saved: {out_png} & .jpg")


CW, CH = 1080, 1920
PX, PY, PW, PH = 110, 340, 860, 1480


def start_phone_canvas(tag: str, headline: str, subheadline: str):
    img = Image.new("RGBA", (CW, CH), BG)
    img = add_radial_glow(img, 540, 220, 420, (16, 185, 129), 34)
    img = add_radial_glow(img, 540, 1650, 380, (245, 158, 11), 22)
    d = ImageDraw.Draw(img)

    f_tag = load_font(F_BOLD, 24)
    f_head = load_font(F_BOLD, 56)
    f_sub = load_font(F_REG, 29)

    tw = d.textbbox((0, 0), tag, font=f_tag)[2] + 44
    tx = (CW - tw) // 2
    d.rounded_rectangle([tx, 76, tx + tw, 124], radius=24, fill=EMERALD_TINT, outline=EMERALD, width=1)
    d.text((tx + 22, 87), tag, font=f_tag, fill=EMERALD)

    hx = center_x(d, headline, f_head, CW)
    d.text((hx, 152), headline, font=f_head, fill=TEXT_1)

    sx = center_x(d, subheadline, f_sub, CW)
    d.text((sx, 232), subheadline, font=f_sub, fill=TEXT_2)

    d.rounded_rectangle([PX - 8, PY - 8, PX + PW + 8, PY + PH + 8], radius=56, fill=(28, 35, 45, 255))
    d.rounded_rectangle([PX, PY, PX + PW, PY + PH], radius=48, fill=BG, outline=BORDER, width=2)
    d.rounded_rectangle([PX + PW // 2 - 70, PY + 22, PX + PW // 2 + 70, PY + 40], radius=9, fill=(20, 25, 32, 255))
    return img, d


def draw_app_topbar(d: ImageDraw.ImageDraw):
    f_app = load_font(F_BOLD, 34)
    draw_pulse_emblem(d, PX + 62, PY + 114, 0.14)
    d.text((PX + 104, PY + 94), "PulsePocket", font=f_app, fill=TEXT_1)
    # Settings gear circle
    gx, gy = PX + PW - 64, PY + 112
    d.ellipse([gx - 14, gy - 14, gx + 14, gy + 14], outline=TEXT_2, width=3)
    d.ellipse([gx - 5, gy - 5, gx + 5, gy + 5], outline=TEXT_2, width=2)


def draw_setlist_strip(d: ImageDraw.ImageDraw, y: int, active_index: int = 1):
    f_sec = load_font(F_BOLD, 20)
    f_pill = load_font(F_BOLD, 22)
    d.text((PX + 36, y), "SETLIST SLOTS", font=f_sec, fill=TEXT_2)
    d.text((PX + PW - 160, y), "+ Save Slot", font=f_sec, fill=EMERALD)

    slots = ["Warmup · 90", "Stage Groove · 120", "Encore · 138"]
    sx = PX + 36
    py = y + 36
    for i, label in enumerate(slots):
        sel = i == active_index
        w = d.textbbox((0, 0), label, font=f_pill)[2] + 44
        d.rounded_rectangle(
            [sx, py, sx + w, py + 58],
            radius=29,
            fill=EMERALD if sel else SURFACE,
            outline=EMERALD if sel else BORDER,
            width=2,
        )
        d.text((sx + 22, py + 15), label, font=f_pill, fill=ON_EMERALD if sel else TEXT_1)
        sx += w + 14


def build_screenshot_1():
    img, d = start_phone_canvas(
        "SILENT STAGE METRONOME",
        "Feel Every Beat. Zero Bleed.",
        "Pure haptic pulse + visual rhythm • No audio into mics",
    )
    draw_app_topbar(d)
    draw_setlist_strip(d, PY + 168, active_index=1)

    cx, cy = PX + 36, PY + 292
    cw = PW - 72
    d.rounded_rectangle([cx, cy, cx + cw, cy + 560], radius=28, fill=SURFACE, outline=BORDER, width=2)

    f_badge = load_font(F_BOLD, 20)
    f_sec = load_font(F_BOLD, 21)
    f_bpm = load_font(F_BOLD, 128)
    f_chip = load_font(F_BOLD, 22)

    d.rounded_rectangle([cx + 28, cy + 28, cx + 380, cy + 72], radius=22, fill=EMERALD_TINT)
    d.text((cx + 46, cy + 38), "SILENT HAPTIC · ZERO AUDIO", font=f_badge, fill=EMERALD)
    d.text((cx + cw - 72, cy + 38), "4/4", font=f_chip, fill=TEXT_2)

    # Beat dots
    dot_y = cy + 132
    dot_xs = [cx + cw // 2 - 120, cx + cw // 2 - 40, cx + cw // 2 + 40, cx + cw // 2 + 120]
    for i, dx in enumerate(dot_xs):
        r = 22 if i == 0 else 16
        fill_c = AMBER if i == 0 else ELEVATED
        out_c = AMBER if i == 0 else BORDER
        d.ellipse([dx - r, dot_y - r, dx + r, dot_y + r], fill=fill_c, outline=out_c, width=3)
    ax = center_x(d, "BEAT 1 ACCENT", f_sec, cw, cx)
    d.text((ax, dot_y + 38), "BEAT 1 ACCENT", font=f_sec, fill=TEXT_2)

    d.line([(cx + 28, cy + 210), (cx + cw - 28, cy + 210)], fill=BORDER, width=1)

    # Meter chips
    meters = ["2/4", "3/4", "4/4", "5/4", "6/8", "7/8"]
    mx = cx + 52
    for m in meters:
        sel = m == "4/4"
        d.rounded_rectangle([mx, cy + 236, mx + 104, cy + 292], radius=18, fill=EMERALD if sel else ELEVATED, outline=EMERALD if sel else BORDER, width=2)
        tx = center_x(d, m, f_chip, 104, mx)
        d.text((tx, cy + 250), m, font=f_chip, fill=ON_EMERALD if sel else TEXT_1)
        mx += 116

    # BPM Display + step buttons
    bx = center_x(d, "120", f_bpm, cw, cx)
    d.text((bx, cy + 322), "120", font=f_bpm, fill=TEXT_1)
    ux = center_x(d, "BPM", f_sec, cw, cx)
    d.text((ux, cy + 462), "BPM", font=f_sec, fill=TEXT_2)

    # Slider track
    d.rounded_rectangle([cx + 48, cy + 510, cx + cw - 48, cy + 522], radius=6, fill=ELEVATED)
    d.rounded_rectangle([cx + 48, cy + 510, cx + 360, cy + 522], radius=6, fill=EMERALD)
    d.ellipse([cx + 344, cy + 498, cx + 378, cy + 532], fill=EMERALD)

    # TAP TEMPO pad
    ty = cy + 590
    d.rounded_rectangle([cx, ty, cx + cw, ty + 168], radius=28, fill=SURFACE, outline=BORDER, width=2)
    f_tap = load_font(F_BOLD, 34)
    f_sub2 = load_font(F_REG, 24)
    ttx = center_x(d, "TAP TEMPO", f_tap, cw, cx)
    d.text((ttx, ty + 42), "TAP TEMPO", font=f_tap, fill=TEXT_1)
    thx = center_x(d, "Tap 2+ times to lock BPM", f_sub2, cw, cx)
    d.text((thx, ty + 96), "Tap 2+ times to lock BPM", font=f_sub2, fill=TEXT_2)

    # Bottom Start + Pocket Lock buttons
    by = PY + PH - 134
    d.rounded_rectangle([cx, by, cx + 448, by + 92], radius=46, fill=EMERALD)
    sx = center_x(d, "START", f_tap, 448, cx)
    d.text((sx, by + 26), "START", font=f_tap, fill=ON_EMERALD)

    d.rounded_rectangle([cx + 468, by, cx + cw, by + 92], radius=24, fill=SURFACE, outline=BORDER, width=2)
    lx = center_x(d, "POCKET LOCK", load_font(F_BOLD, 26), cw - 468, cx + 468)
    d.text((lx, by + 30), "POCKET LOCK", font=load_font(F_BOLD, 26), fill=TEXT_1)

    out = os.path.join(OUT_DIR, "screenshot_01_stage_console.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


def build_screenshot_2():
    img, d = start_phone_canvas(
        "POCKET LOCK BLACKOUT",
        "Lock Screen. Keep Groove.",
        "Pure OLED touch-guard blocks pocket & fabric taps",
    )
    # Full OLED blackout screen inside phone frame
    d.rounded_rectangle([PX + 10, PY + 10, PX + PW - 10, PY + PH - 10], radius=44, fill=(2, 3, 4, 255))

    cx, cy = PX + PW // 2, PY + PH // 2
    d.ellipse([cx - 18, cy - 230, cx + 18, cy - 194], fill=AMBER)

    f_sec = load_font(F_BOLD, 24)
    f_bpm = load_font(F_BOLD, 64)
    f_body = load_font(F_REG, 28)

    tx1 = center_x(d, "POCKET LOCKED", f_sec, PW, PX)
    d.text((tx1, cy - 140), "POCKET LOCKED", font=f_sec, fill=TEXT_2)

    tx2 = center_x(d, "120 BPM · 4/4", f_bpm, PW, PX)
    d.text((tx2, cy - 72), "120 BPM · 4/4", font=f_bpm, fill=TEXT_2)

    # Progress ring
    d.ellipse([cx - 72, cy + 54, cx + 72, cy + 198], outline=BORDER, width=8)
    d.arc([cx - 72, cy + 54, cx + 72, cy + 198], -90, 145, fill=EMERALD, width=10)
    d.rounded_rectangle([cx - 22, cy + 116, cx + 22, cy + 154], radius=8, outline=EMERALD, width=4)
    d.arc([cx - 14, cy + 92, cx + 14, cy + 124], 180, 360, fill=EMERALD, width=4)

    tx3 = center_x(d, "Hold anywhere for 1.2s to unlock", f_body, PW, PX)
    d.text((tx3, cy + 250), "Hold anywhere for 1.2s to unlock", font=f_body, fill=TEXT_2)

    out = os.path.join(OUT_DIR, "screenshot_02_pocket_lock.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


def build_screenshot_3():
    img, d = start_phone_canvas(
        "1-TAP SETLIST SLOTS",
        "Jump Between Songs Fast",
        "Save up to 12 BPM + meter presets locally",
    )
    draw_app_topbar(d)
    draw_setlist_strip(d, PY + 168, active_index=2)

    cx, cy = PX + 36, PY + 306
    cw = PW - 72
    f_h = load_font(F_BOLD, 30)
    f_b = load_font(F_REG, 24)
    f_pill = load_font(F_BOLD, 24)

    songs = [
        ("Warmup", "90 BPM · 4/4", False),
        ("Stage Groove", "120 BPM · 4/4", False),
        ("Encore Drive", "138 BPM · 6/8", True),
        ("Acoustic Waltz", "74 BPM · 3/4", False),
    ]
    y = cy
    for title, sub, active in songs:
        d.rounded_rectangle(
            [cx, y, cx + cw, y + 146],
            radius=24,
            fill=SURFACE,
            outline=EMERALD if active else BORDER,
            width=3 if active else 2,
        )
        d.ellipse([cx + 28, y + 58, cx + 48, y + 78], fill=EMERALD if active else TEXT_2)
        d.text((cx + 72, y + 34), title, font=f_h, fill=TEXT_1)
        d.text((cx + 72, y + 82), sub, font=f_b, fill=TEXT_2)
        if active:
            d.rounded_rectangle([cx + cw - 150, y + 46, cx + cw - 28, y + 100], radius=27, fill=EMERALD_TINT)
            d.text((cx + cw - 126, y + 60), "ACTIVE", font=f_pill, fill=EMERALD)
        y += 170

    # Save Setlist Sheet footer preview
    d.rounded_rectangle([PX + 10, PY + PH - 300, PX + PW - 10, PY + PH - 10], radius=36, fill=ELEVATED, outline=BORDER, width=2)
    d.text((PX + 48, PY + PH - 260), "Save Setlist Slot", font=f_h, fill=TEXT_1)
    d.rounded_rectangle([PX + 48, PY + PH - 196, PX + PW - 48, PY + PH - 116], radius=20, fill=BG, outline=EMERALD, width=2)
    d.text((PX + 72, PY + PH - 170), "Chorus Bridge · 132 BPM · 4/4", font=f_b, fill=TEXT_1)

    out = os.path.join(OUT_DIR, "screenshot_03_setlist_slots.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


def build_screenshot_4():
    img, d = start_phone_canvas(
        "STAGE CALIBRATION & THEMES",
        "Dark OLED or Light Mode",
        "3 haptic strength levels • EN/ES • 100% Offline",
    )
    draw_app_topbar(d)

    cx, cy = PX + 36, PY + 186
    cw = PW - 72
    f_sec = load_font(F_BOLD, 20)
    f_h = load_font(F_BOLD, 26)
    f_b = load_font(F_REG, 22)

    d.text((cx, cy), "APPEARANCE", font=f_sec, fill=TEXT_2)
    d.rounded_rectangle([cx, cy + 34, cx + cw, cy + 144], radius=24, fill=SURFACE, outline=BORDER, width=2)
    chips = [("System", False), ("Light", False), ("Dark", True)]
    ox = cx + 28
    for label, sel in chips:
        w = 190
        d.rounded_rectangle([ox, cy + 58, ox + w, cy + 120], radius=20, fill=EMERALD if sel else ELEVATED, outline=EMERALD if sel else BORDER, width=2)
        tx = center_x(d, label, f_h, w, ox)
        d.text((tx, cy + 74), label, font=f_h, fill=ON_EMERALD if sel else TEXT_1)
        ox += w + 20

    y2 = cy + 180
    d.text((cx, y2), "PREFERENCES", font=f_sec, fill=TEXT_2)
    d.rounded_rectangle([cx, y2 + 34, cx + cw, y2 + 410], radius=24, fill=SURFACE, outline=BORDER, width=2)
    d.text((cx + 28, y2 + 64), "Haptic strength", font=f_h, fill=TEXT_1)
    d.text((cx + cw - 170, y2 + 66), "Test Pulse", font=f_h, fill=EMERALD)

    levels = [("Normal", False), ("Strong", False), ("Stage Max", True)]
    lx = cx + 28
    for label, sel in levels:
        w = 220
        d.rounded_rectangle([lx, y2 + 122, lx + w, y2 + 186], radius=20, fill=EMERALD if sel else ELEVATED, outline=EMERALD if sel else BORDER, width=2)
        tx = center_x(d, label, f_h, w, lx)
        d.text((tx, y2 + 138), label, font=f_h, fill=ON_EMERALD if sel else TEXT_1)
        lx += w + 16

    d.line([(cx + 28, y2 + 224), (cx + cw - 28, y2 + 224)], fill=BORDER, width=1)
    d.text((cx + 28, y2 + 250), "Visual beat flash", font=f_h, fill=TEXT_1)
    d.text((cx + 28, y2 + 288), "Highlight beat dots in sync with each pulse", font=f_b, fill=TEXT_2)
    d.rounded_rectangle([cx + cw - 110, y2 + 256, cx + cw - 28, y2 + 304], radius=24, fill=EMERALD)
    d.ellipse([cx + cw - 72, y2 + 262, cx + cw - 34, y2 + 298], fill=ON_EMERALD)

    # Omniverse Labs Contact + About preview
    y3 = y2 + 448
    d.text((cx, y3), "CONTACT & SUGGESTIONS", font=f_sec, fill=TEXT_2)
    d.rounded_rectangle([cx, y3 + 34, cx + cw, y3 + 148], radius=24, fill=SURFACE, outline=BORDER, width=2)
    d.text((cx + 28, y3 + 56), "Send us a message", font=f_h, fill=TEXT_1)
    d.text((cx + 28, y3 + 96), "leo.benveniste@gmail.com", font=f_b, fill=TEXT_2)

    y4 = y3 + 186
    d.rounded_rectangle([cx, y4, cx + cw, y4 + 270], radius=24, fill=SURFACE, outline=BORDER, width=2)
    ox_t = center_x(d, "OMNIVERSE LABS", f_h, cw, cx)
    d.text((ox_t, y4 + 38), "OMNIVERSE LABS", font=f_h, fill=TEXT_1)
    mx = center_x(d, "100% Offline & Zero Audio. Zero bleed into mics.", f_b, cw, cx)
    d.text((mx, y4 + 104), "100% Offline & Zero Audio. Zero bleed into mics.", font=f_b, fill=TEXT_2)
    d.rounded_rectangle([cx + 28, y4 + 168, cx + cw - 28, y4 + 236], radius=16, fill=ELEVATED, outline=BORDER, width=1)
    d.text((cx + 52, y4 + 188), "com.omniverselabs.pulse_pocket  •  v1.0.0", font=f_b, fill=EMERALD)

    out = os.path.join(OUT_DIR, "screenshot_04_settings_haptics.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


if __name__ == "__main__":
    build_icons()
    build_feature_graphic()
    build_screenshot_1()
    build_screenshot_2()
    build_screenshot_3()
    build_screenshot_4()
