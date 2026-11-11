import os
from PIL import Image, ImageDraw, ImageFont

ROOT = r"c:\Projects\Omniverse Labs"
APP_DIR = os.path.join(ROOT, "apps", "loud_guard")
ASSETS_DIR = os.path.join(APP_DIR, "assets", "images")
STORE_DIR = os.path.join(APP_DIR, "store_assets", "play_store")
RES_DIR = os.path.join(APP_DIR, "android", "app", "src", "main", "res")

FONT_BOLD = os.path.join(ROOT, "fonts", "ClashGrotesk-Bold.ttf")
FONT_BODY = os.path.join(ROOT, "fonts", "PlusJakartaSans.ttf")

BG = (9, 11, 14)
SURFACE = (18, 22, 28)
ELEVATED = (27, 33, 42)
BORDER = (38, 47, 59)
TEXT_PRIMARY = (244, 247, 250)
TEXT_SECONDARY = (154, 166, 184)
EMERALD = (16, 185, 129)
EMERALD_TINT = (15, 43, 34)
AMBER = (245, 158, 11)
AMBER_TINT = (43, 32, 13)
CORAL = (251, 113, 133)
CORAL_TINT = (46, 18, 26)
ON_ACCENT = (4, 34, 23)


def font(path, size):
    return ImageFont.truetype(path, size)


def draw_centered_text(draw, box, text, fnt, fill):
    x1, y1, x2, y2 = box
    tb = draw.textbbox((0, 0), text, font=fnt)
    tw = tb[2] - tb[0]
    th = tb[3] - tb[1]
    tx = x1 + (x2 - x1 - tw) / 2 - tb[0]
    ty = y1 + (y2 - y1 - th) / 2 - tb[1]
    draw.text((tx, ty), text, font=fnt, fill=fill)


def draw_icon(size=512):
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    margin = int(s * 0.04)
    radius = int(s * 0.22)
    d.rounded_rectangle(
        [margin, margin, s - margin, s - margin],
        radius=radius,
        fill=BG + (255,),
        outline=BORDER + (255,),
        width=int(s * 0.025),
    )

    cx, cy = s // 2, s // 2
    r_outer = int(s * 0.34)
    d.arc(
        [cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer],
        start=135,
        end=405,
        fill=EMERALD + (90,),
        width=int(s * 0.03),
    )

    bar_heights = [0.22, 0.38, 0.50, 0.34, 0.24]
    bar_colors = [EMERALD, EMERALD, AMBER, EMERALD, EMERALD]
    bar_w = int(s * 0.055)
    gap = int(s * 0.032)
    total_w = len(bar_heights) * bar_w + (len(bar_heights) - 1) * gap
    start_x = cx - total_w // 2

    for bh, col in zip(bar_heights, bar_colors):
        x = start_x
        start_x += bar_w + gap
        h = int(s * bh)
        y1 = cy - h // 2
        y2 = cy + h // 2
        d.rounded_rectangle(
            [x, y1, x + bar_w, y2],
            radius=bar_w // 2,
            fill=col + (255,),
        )

    dot_r = int(s * 0.032)
    dot_y = cy + int(s * 0.32)
    d.ellipse(
        [cx - dot_r, dot_y - dot_r, cx + dot_r, dot_y + dot_r],
        fill=AMBER + (255,),
    )

    return img.resize((size, size), Image.Resampling.LANCZOS)


def draw_phone_frame(draw, x, y, w, h):
    draw.rounded_rectangle(
        [x, y, x + w, y + h],
        radius=42,
        fill=BG,
        outline=BORDER,
        width=4,
    )


def draw_console_screenshot_body(
    draw,
    px,
    py,
    pw,
    ph,
    db_text="64.2",
    zone_text="SAFE (< 70 dB)",
    zone_col=EMERALD,
    zone_tint=EMERALD_TINT,
    safe_text="24h+ Safe",
    dose_text="0.0%",
    dose_ratio=0.05,
    min_text="51.4 dB",
    peak_text="69.8 dB",
    context_text="Reference: Normal conversation / Office",
    bars=None,
):
    draw_phone_frame(draw, px, py, pw, ph)
    pad = 36
    # AppBar
    draw.text((px + pad, py + 38), "LoudGuard", font=font(FONT_BOLD, 38), fill=TEXT_PRIMARY)

    # Meter Card
    cy = py + 112
    ch = 550
    draw.rounded_rectangle([px + pad, cy, px + pw - pad, cy + ch], radius=24, fill=SURFACE, outline=BORDER, width=2)
    draw.rounded_rectangle([px + pad + 28, cy + 28, px + pad + 290, cy + 72], radius=22, fill=zone_tint, outline=zone_col, width=2)
    draw_centered_text(draw, (px + pad + 28, cy + 28, px + pad + 290, cy + 72), zone_text, font(FONT_BODY, 20), zone_col)
    draw.text((px + pw - pad - 155, cy + 40), "LIVE IN RAM", font=font(FONT_BODY, 20), fill=EMERALD)

    draw.text((px + pad + 28, cy + 104), db_text, font=font(FONT_BOLD, 108), fill=TEXT_PRIMARY)
    draw.text((px + pad + 275, cy + 168), "dB SPL", font=font(FONT_BODY, 26), fill=TEXT_SECONDARY)

    # Level bar
    by = cy + 244
    draw.rounded_rectangle([px + pad + 28, by, px + pw - pad - 28, by + 16], radius=8, fill=ELEVATED)
    fill_w = int((pw - 2 * pad - 56) * (0.76 if zone_col != EMERALD else 0.48))
    draw.rounded_rectangle([px + pad + 28, by, px + pad + 28 + fill_w, by + 16], radius=8, fill=zone_col)

    # Sparkline
    if bars is None:
        bars = [0.28, 0.34, 0.31, 0.40, 0.46, 0.42, 0.35, 0.48, 0.54, 0.44, 0.38, 0.50, 0.56, 0.51, 0.44, 0.41, 0.49, 0.52]
    sx = px + pad + 28
    sy = cy + 402
    bw = (pw - 2 * pad - 56) // len(bars)
    for idx, val in enumerate(bars):
        bh = int(122 * val)
        col = zone_col if val > 0.65 else EMERALD
        bx = sx + idx * bw + 3
        draw.rounded_rectangle([bx, sy - bh, bx + max(6, bw - 9), sy], radius=4, fill=col)

    # Min / Avg / Peak
    draw.line([px + pad + 28, cy + 432, px + pw - pad - 28, cy + 432], fill=BORDER, width=2)
    stats = [("MIN", min_text, TEXT_PRIMARY), ("AVG", f"{db_text} dB", EMERALD), ("PEAK", peak_text, zone_col)]
    col_w = (pw - 2 * pad - 56) // 3
    for i, (lbl, val, col) in enumerate(stats):
        tx = px + pad + 28 + i * col_w
        draw.text((tx, cy + 452), lbl, font=font(FONT_BODY, 18), fill=TEXT_SECONDARY)
        draw.text((tx, cy + 482), val, font=font(FONT_BOLD, 30), fill=col)

    # WHO Exposure Card
    ey = cy + ch + 28
    eh = 340
    draw.rounded_rectangle([px + pad, ey, px + pw - pad, ey + eh], radius=24, fill=SURFACE, outline=BORDER, width=2)
    draw.text((px + pad + 28, ey + 28), "WHO / NIOSH SAFE EXPOSURE", font=font(FONT_BODY, 20), fill=TEXT_SECONDARY)
    metrics = [("Safe limit now", safe_text, TEXT_PRIMARY), ("Session", "14m 20s", TEXT_PRIMARY), ("Daily dose", dose_text, zone_col)]
    for i, (lbl, val, col) in enumerate(metrics):
        tx = px + pad + 28 + i * col_w
        draw.text((tx, ey + 80), lbl, font=font(FONT_BODY, 19), fill=TEXT_SECONDARY)
        draw.text((tx, ey + 114), val, font=font(FONT_BOLD, 32), fill=col)

    draw.rounded_rectangle([px + pad + 28, ey + 186, px + pw - pad - 28, ey + 200], radius=7, fill=ELEVATED)
    dw = max(24, int((pw - 2 * pad - 56) * dose_ratio))
    draw.rounded_rectangle([px + pad + 28, ey + 186, px + pad + 28 + dw, ey + 200], radius=7, fill=zone_col)

    draw.rounded_rectangle([px + pad + 28, ey + 234, px + pw - pad - 28, ey + 306], radius=16, fill=ELEVATED, outline=BORDER, width=2)
    draw.text((px + pad + 52, ey + 258), context_text, font=font(FONT_BODY, 21), fill=TEXT_SECONDARY)

    # Bottom action bar
    by2 = py + ph - 124
    btn_h = 84
    draw.rounded_rectangle([px + pad, by2, px + pw - pad - 240, by2 + btn_h], radius=42, fill=EMERALD)
    draw_centered_text(draw, (px + pad, by2, px + pw - pad - 240, by2 + btn_h), "PAUSE", font(FONT_BOLD, 28), ON_ACCENT)
    draw.rounded_rectangle([px + pw - pad - 220, by2, px + pw - pad, by2 + btn_h], radius=20, fill=SURFACE, outline=BORDER, width=2)
    draw_centered_text(draw, (px + pw - pad - 220, by2, px + pw - pad, by2 + btn_h), "LOG CHECK", font(FONT_BOLD, 24), TEXT_PRIMARY)


def build_feature_graphic(icon_img):
    W, H = 1024, 500
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    d.rounded_rectangle([24, 24, W - 24, H - 24], radius=28, fill=SURFACE, outline=BORDER, width=2)
    icon_small = icon_img.resize((96, 96), Image.Resampling.LANCZOS)
    img.paste(icon_small, (64, 68), icon_small)

    d.text((180, 80), "LoudGuard", font=font(FONT_BOLD, 48), fill=TEXT_PRIMARY)
    d.text((180, 136), "OFFLINE DECIBEL METER", font=font(FONT_BODY, 16), fill=EMERALD)

    d.text((64, 206), "Measure Sound.\nProtect Your Ears.", font=font(FONT_BOLD, 50), fill=TEXT_PRIMARY)
    d.text((64, 344), "WHO safe-exposure timer · RAM-only audio\nZero ads · Zero internet · $1.49 once", font=font(FONT_BODY, 20), fill=TEXT_SECONDARY)

    # Dedicated compact Meter + WHO preview card on the right (zero overlap)
    cx, cy, cw, ch = 582, 56, 386, 388
    d.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=24, fill=BG, outline=BORDER, width=3)
    d.rounded_rectangle([cx + 22, cy + 22, cx + 224, cy + 56], radius=17, fill=AMBER_TINT, outline=AMBER, width=1)
    draw_centered_text(d, (cx + 22, cy + 22, cx + 224, cy + 56), "CAUTION (85-94 dB)", font(FONT_BODY, 15), AMBER)
    d.text((cx + cw - 122, cy + 31), "LIVE IN RAM", font=font(FONT_BODY, 14), fill=EMERALD)

    d.text((cx + 22, cy + 74), "86.4", font=font(FONT_BOLD, 72), fill=TEXT_PRIMARY)
    d.text((cx + 190, cy + 118), "dB SPL", font=font(FONT_BODY, 19), fill=TEXT_SECONDARY)

    d.rounded_rectangle([cx + 22, cy + 164, cx + cw - 22, cy + 176], radius=6, fill=ELEVATED)
    d.rounded_rectangle([cx + 22, cy + 164, cx + 276, cy + 176], radius=6, fill=AMBER)

    bars = [0.42, 0.56, 0.64, 0.72, 0.68, 0.78, 0.86, 0.75, 0.80, 0.88, 0.74, 0.66, 0.79, 0.84]
    bx = cx + 22
    by = cy + 266
    bw = (cw - 44) // len(bars)
    for val in bars:
        bh = int(70 * val)
        col = AMBER if val >= 0.72 else EMERALD
        d.rounded_rectangle([bx + 2, by - bh, bx + bw - 5, by], radius=3, fill=col)
        bx += bw

    d.line([cx + 22, cy + 286, cx + cw - 22, cy + 286], fill=BORDER, width=1)
    d.text((cx + 22, cy + 304), "Safe limit now", font=font(FONT_BODY, 14), fill=TEXT_SECONDARY)
    d.text((cx + 22, cy + 328), "5h 46m", font=font(FONT_BOLD, 24), fill=TEXT_PRIMARY)
    d.text((cx + 220, cy + 304), "Peak", font=font(FONT_BODY, 14), fill=TEXT_SECONDARY)
    d.text((cx + 220, cy + 328), "91.8 dB", font=font(FONT_BOLD, 24), fill=AMBER)

    png_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.png")
    jpg_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.jpg")
    img.save(png_path, "PNG")
    img.convert("RGB").save(jpg_path, "JPEG", quality=95)


def make_screenshot(filename, headline, subline, mode):
    W, H = 1080, 1920
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    d.rounded_rectangle([80, 92, 355, 140], radius=24, fill=EMERALD_TINT, outline=EMERALD, width=2)
    draw_centered_text(d, (80, 92, 355, 140), "100% OFFLINE · NO ADS", font(FONT_BODY, 17), EMERALD)
    d.text((80, 172), headline, font=font(FONT_BOLD, 66), fill=TEXT_PRIMARY)
    d.text((80, 344), subline, font=font(FONT_BODY, 30), fill=TEXT_SECONDARY)

    px, py, pw, ph = 90, 456, 900, 1380
    if mode == "console":
        draw_console_screenshot_body(d, px, py, pw, ph)
    elif mode == "exposure":
        bars = [0.55, 0.62, 0.74, 0.80, 0.85, 0.78, 0.88, 0.92, 0.84, 0.79, 0.86, 0.90, 0.95, 0.88, 0.82, 0.87, 0.91, 0.85]
        draw_console_screenshot_body(
            d,
            px,
            py,
            pw,
            ph,
            db_text="94.0",
            zone_text="CAUTION (85-94 dB)",
            zone_col=AMBER,
            zone_tint=AMBER_TINT,
            safe_text="1h 00m",
            dose_text="24.5%",
            dose_ratio=0.25,
            min_text="81.2 dB",
            peak_text="98.4 dB",
            context_text="Live concert / Club — Ear protection advised",
            bars=bars,
        )
    elif mode == "saved":
        draw_phone_frame(d, px, py, pw, ph)
        pad = 40
        d.text((px + pad, py + 48), "Saved Sound Checks", font=font(FONT_BOLD, 42), fill=TEXT_PRIMARY)
        d.rounded_rectangle([px + pad, py + 128, px + pw - pad, py + 214], radius=18, fill=ELEVATED, outline=BORDER, width=2)
        d.text((px + pad + 28, py + 154), "Main Stage — Soundcheck", font=font(FONT_BODY, 28), fill=TEXT_PRIMARY)
        d.rounded_rectangle([px + pad, py + 242, px + pw - pad, py + 324], radius=41, fill=EMERALD)
        draw_centered_text(d, (px + pad, py + 242, px + pw - pad, py + 324), "Save Check", font(FONT_BOLD, 30), ON_ACCENT)

        rows = [
            ("Baby Nursery", "AVG 44.2 dB · PEAK 49.8 dB · 11/11 14:20", EMERALD),
            ("Main Stage Floor", "AVG 94.6 dB · PEAK 101.4 dB · 11/11 13:05", CORAL),
            ("Woodshop Router", "AVG 88.1 dB · PEAK 93.2 dB · 11/10 17:42", AMBER),
            ("Home Office", "AVG 48.0 dB · PEAK 54.1 dB · 11/10 09:15", EMERALD),
            ("Subway Platform", "AVG 86.4 dB · PEAK 92.0 dB · 11/09 18:10", AMBER),
        ]
        ry = py + 378
        for title, meta, col in rows:
            d.rounded_rectangle([px + pad, ry, px + pw - pad, ry + 160], radius=20, fill=SURFACE, outline=BORDER, width=2)
            d.rounded_rectangle([px + pad + 24, ry + 28, px + pad + 32, ry + 132], radius=4, fill=col)
            d.text((px + pad + 56, ry + 36), title, font=font(FONT_BOLD, 32), fill=TEXT_PRIMARY)
            d.text((px + pad + 56, ry + 92), meta, font=font(FONT_BODY, 23), fill=TEXT_SECONDARY)
            ry += 186
    elif mode == "settings":
        draw_phone_frame(d, px, py, pw, ph)
        pad = 40
        d.text((px + pad, py + 48), "Settings", font=font(FONT_BOLD, 42), fill=TEXT_PRIMARY)
        d.text((px + pad, py + 124), "APPEARANCE", font=font(FONT_BODY, 20), fill=TEXT_SECONDARY)
        d.rounded_rectangle([px + pad, py + 160, px + pw - pad, py + 272], radius=22, fill=SURFACE, outline=BORDER, width=2)
        chips = [("System", False), ("Light", False), ("Dark", True)]
        cx = px + pad + 24
        for lbl, active in chips:
            d.rounded_rectangle([cx, py + 186, cx + 190, py + 246], radius=14, fill=EMERALD if active else ELEVATED, outline=EMERALD if active else BORDER, width=2)
            draw_centered_text(d, (cx, py + 186, cx + 190, py + 246), lbl, font(FONT_BODY, 24), ON_ACCENT if active else TEXT_PRIMARY)
            cx += 210

        d.text((px + pad, py + 308), "PREFERENCES", font=font(FONT_BODY, 20), fill=TEXT_SECONDARY)
        d.rounded_rectangle([px + pad, py + 344, px + pw - pad, py + 980], radius=22, fill=SURFACE, outline=BORDER, width=2)
        d.text((px + pad + 24, py + 374), "Microphone Calibration", font=font(FONT_BODY, 28), fill=TEXT_PRIMARY)
        d.text((px + pw - pad - 150, py + 372), "+1.5 dB", font=font(FONT_BOLD, 30), fill=EMERALD)
        d.text((px + pad + 24, py + 422), "Fine-tune offset to match a reference SPL meter.", font=font(FONT_BODY, 20), fill=TEXT_SECONDARY)

        steps = ["-1.0", "-0.5", "Reset", "+0.5", "+1.0"]
        sx = px + pad + 24
        for lbl in steps:
            d.rounded_rectangle([sx, py + 474, sx + 136, py + 532], radius=14, fill=ELEVATED, outline=BORDER, width=2)
            draw_centered_text(d, (sx, py + 474, sx + 136, py + 532), lbl, font(FONT_BODY, 22), TEXT_PRIMARY)
            sx += 152

        d.line([px + pad + 24, py + 572, px + pw - pad - 24, py + 572], fill=BORDER, width=2)
        d.text((px + pad + 24, py + 602), "Haptic Threshold Alert", font=font(FONT_BODY, 28), fill=TEXT_PRIMARY)
        tchips = [("Off", False), ("85 dB", False), ("90 dB", True), ("95 dB", False)]
        tx = px + pad + 24
        for lbl, active in tchips:
            d.rounded_rectangle([tx, py + 658, tx + 165, py + 716], radius=14, fill=EMERALD if active else ELEVATED, outline=EMERALD if active else BORDER, width=2)
            draw_centered_text(d, (tx, py + 658, tx + 165, py + 716), lbl, font(FONT_BODY, 22), ON_ACCENT if active else TEXT_PRIMARY)
            tx += 182

        d.line([px + pad + 24, py + 758, px + pw - pad - 24, py + 758], fill=BORDER, width=2)
        d.text((px + pad + 24, py + 796), "Keep Screen Awake", font=font(FONT_BODY, 28), fill=TEXT_PRIMARY)
        d.text((px + pad + 24, py + 842), "Prevent display sleep while measuring.", font=font(FONT_BODY, 20), fill=TEXT_SECONDARY)
        d.rounded_rectangle([px + pw - pad - 110, py + 808, px + pw - pad - 28, py + 852], radius=22, fill=EMERALD)
        d.ellipse([px + pw - pad - 68, py + 812, px + pw - pad - 32, py + 848], fill=ON_ACCENT)

        d.rounded_rectangle([px + pad, py + 1020, px + pw - pad, py + 1310], radius=22, fill=SURFACE, outline=BORDER, width=2)
        draw_centered_text(d, (px + pad, py + 1054, px + pw - pad, py + 1104), "OMNIVERSE LABS", font(FONT_BOLD, 30), TEXT_PRIMARY)
        draw_centered_text(d, (px + pad + 40, py + 1126, px + pw - pad - 40, py + 1236), "100% offline · Zero audio recording\nZero internet permission", font(FONT_BODY, 24), TEXT_SECONDARY)

    img.save(os.path.join(STORE_DIR, filename), "PNG")


def main():
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(STORE_DIR, exist_ok=True)

    icon = draw_icon(512)
    icon.save(os.path.join(ASSETS_DIR, "app_logo.png"), "PNG")
    icon.save(os.path.join(STORE_DIR, "icon_512x512.png"), "PNG")

    mipmaps = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in mipmaps.items():
        out = os.path.join(RES_DIR, folder, "ic_launcher.png")
        icon.resize((px, px), Image.Resampling.LANCZOS).save(out, "PNG")

    build_feature_graphic(icon)

    make_screenshot(
        "screenshot_01_sound_console.png",
        "Instant Offline\nDecibel Meter",
        "Live Min, Avg & Peak dB SPL · RAM-only audio",
        "console",
    )
    make_screenshot(
        "screenshot_02_safe_exposure.png",
        "WHO Safe-Exposure\n& Noise Dose Timer",
        "Know how long your ears are safe at any level",
        "exposure",
    )
    make_screenshot(
        "screenshot_03_saved_checks.png",
        "Save Timestamped\nRoom & Stage Checks",
        "Log nurseries, gigs, or workshops locally",
        "saved",
    )
    make_screenshot(
        "screenshot_04_settings_calibration.png",
        "Mic Calibration &\nHaptic Alerts",
        "Fine-tune dB offset & silent pocket alerts",
        "settings",
    )
    print("Regenerated polished LoudGuard Play Store assets successfully.")


if __name__ == "__main__":
    main()
