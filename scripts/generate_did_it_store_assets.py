import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = r"c:\Projects\Omniverse Labs"
APP_DIR = os.path.join(REPO_ROOT, "apps", "did_it")
ASSETS_DIR = os.path.join(APP_DIR, "assets", "images")
STORE_DIR = os.path.join(APP_DIR, "store_assets", "play_store")
RES_DIR = os.path.join(APP_DIR, "android", "app", "src", "main", "res")
WEB_DIR = os.path.join(APP_DIR, "web")
IOS_DIR = os.path.join(APP_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
FONTS_DIR = os.path.join(REPO_ROOT, "fonts")

BG = (9, 11, 14, 255)
SURFACE = (18, 22, 28, 255)
ELEVATED = (27, 33, 42, 255)
BORDER = (38, 47, 59, 255)
TEXT_PRIMARY = (244, 247, 250, 255)
TEXT_SECONDARY = (154, 166, 184, 255)
EMERALD = (16, 185, 129, 255)
ON_EMERALD = (4, 34, 23, 255)
EMERALD_TINT = (15, 43, 34, 255)
AMBER = (245, 158, 11, 255)
AMBER_TINT = (43, 32, 13, 255)
CORAL = (251, 113, 133, 255)
CORAL_TINT = (46, 18, 26, 255)


def load_font(candidates, size):
    for name in candidates:
        p = os.path.join(FONTS_DIR, name)
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
        try:
            return ImageFont.truetype(name, size)
        except Exception:
            pass
    return ImageFont.load_default()


F_BOLD = ["ClashGrotesk-Bold.ttf", "PlusJakartaSans.ttf", "arialbd.ttf"]
F_REG = ["PlusJakartaSans.ttf", "Outfit.ttf", "arial.ttf"]


def add_radial_glow(base: Image.Image, cx: int, cy: int, radius: int, rgb: tuple, alpha: int):
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(*rgb, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(14, radius // 2)))
    return Image.alpha_composite(base, glow)


def draw_centered_text(draw, box, text, fnt, fill):
    x1, y1, x2, y2 = box
    tb = draw.textbbox((0, 0), text, font=fnt)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    draw.text((x1 + (x2 - x1 - tw) // 2, y1 + (y2 - y1 - th) // 2 - 2), text, font=fnt, fill=fill)


def draw_emblem(canvas: Image.Image, cx: int, cy: int, scale: float):
    d = ImageDraw.Draw(canvas)
    # Outer loop arc + arrow + bold checkmark
    r = int(124 * scale)
    stroke = max(4, int(22 * scale))
    # Subtle inner backing disc
    d.ellipse(
        [cx - int(136 * scale), cy - int(136 * scale), cx + int(136 * scale), cy + int(136 * scale)],
        fill=(15, 43, 34, 240),
        outline=EMERALD,
        width=max(2, int(4 * scale)),
    )
    # Continuous emerald loop arc (~285 deg)
    d.arc(
        [cx - r, cy - r, cx + r, cy + r],
        start=30,
        end=315,
        fill=EMERALD,
        width=stroke,
    )
    # Arrowhead at top-right gap (315 deg -> loop clockwise cue)
    ang = math.radians(320)
    ax = cx + r * math.cos(ang)
    ay = cy + r * math.sin(ang)
    tip = (ax + 18 * scale, ay + 24 * scale)
    p1 = (ax - 22 * scale, ay + 8 * scale)
    p2 = (ax + 16 * scale, ay - 16 * scale)
    d.polygon([tip, p1, p2], fill=EMERALD)

    # Center amber confirmation pulse + crisp checkmark
    c1 = (cx - int(46 * scale), cy + int(4 * scale))
    c2 = (cx - int(12 * scale), cy + int(38 * scale))
    c3 = (cx + int(56 * scale), cy - int(34 * scale))
    d.line([c1, c2, c3], fill=(244, 247, 250, 255), width=max(5, int(24 * scale)), joint="curve")
    # Highlight dot showing auto-repeat state
    dot_r = int(16 * scale)
    dot_y = cy - r
    d.ellipse([cx - dot_r, dot_y - dot_r, cx + dot_r, dot_y + dot_r], fill=AMBER, outline=BG, width=max(2, int(4 * scale)))


def load_source_icon():
    src_path = os.path.join(APP_DIR, "store_assets", "source_icon.jpg")
    return Image.open(src_path).convert("RGBA")


def make_aa_squircle_mask(size: int, radius: int) -> Image.Image:
    scale = 4
    hi = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(hi).rounded_rectangle(
        [0, 0, size * scale - 1, size * scale - 1],
        radius=radius * scale,
        fill=255,
    )
    return hi.resize((size, size), Image.Resampling.LANCZOS)


def build_transparent_logo():
    src = load_source_icon()
    cropped = src.crop((108, 108, 916, 916)).resize((512, 512), Image.Resampling.LANCZOS)
    mask = make_aa_squircle_mask(512, 116)
    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    out.paste(cropped, (0, 0), mask)
    # Supersampled hairline rim for clean separation on dark and light surfaces
    rim = Image.new("RGBA", (2048, 2048), (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle(
        [4, 4, 2043, 2043],
        radius=464,
        outline=(78, 104, 152, 175),
        width=8,
    )
    out = Image.alpha_composite(out, rim.resize((512, 512), Image.Resampling.LANCZOS))
    return out


def build_store_icon():
    src = load_source_icon()
    return src.crop((80, 80, 944, 944)).resize((512, 512), Image.Resampling.LANCZOS)


def build_feature_graphic(icon_rgba: Image.Image):
    w, h = 1024, 500
    img = Image.new("RGBA", (w, h), BG)
    img = add_radial_glow(img, 188, 250, 230, (20, 184, 166), 64)
    img = add_radial_glow(img, 240, 320, 180, (99, 102, 241), 42)
    img = add_radial_glow(img, 860, 260, 210, (245, 158, 11), 30)

    # Composite subtle grid lines cleanly on separate layer
    grid = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    for x in range(0, w, 48):
        gd.line([(x, 0), (x, h)], fill=(255, 255, 255, 10), width=1)
    for y in range(0, h, 48):
        gd.line([(0, y), (w, y)], fill=(255, 255, 255, 10), width=1)
    img = Image.alpha_composite(img, grid)

    badge = Image.new("RGBA", (252, 252), (0, 0, 0, 0))
    mask = make_aa_squircle_mask(252, 56)
    badge.paste(icon_rgba.resize((252, 252), Image.Resampling.LANCZOS), (0, 0), mask)
    img.paste(badge, (64, 124), badge)

    d = ImageDraw.Draw(img)
    tx = 352
    f_badge = load_font(F_BOLD, 17)
    f_title = load_font(F_BOLD, 66)
    f_sub = load_font(F_REG, 27)
    f_pill = load_font(F_BOLD, 19)

    d.rounded_rectangle([tx, 76, tx + 320, 116], radius=20, fill=EMERALD_TINT, outline=EMERALD, width=1)
    d.text((tx + 18, 86), "100% OFFLINE · MEMORY PROOF", font=f_badge, fill=EMERALD)

    d.text((tx, 138), "DidIt", font=f_title, fill=TEXT_PRIMARY)
    d.text((tx, 222), "Remember what you just did.", font=f_sub, fill=TEXT_SECONDARY)
    d.text((tx, 258), "Automate loops, chains & flows.", font=f_sub, fill=TEXT_SECONDARY)

    pills = [
        ("Proof Timestamps", EMERALD_TINT, EMERALD),
        ("Auto Flows", ELEVATED, TEXT_PRIMARY),
        ("$1.49 Once", AMBER_TINT, AMBER),
    ]
    px = tx
    for label, fill_c, text_c in pills:
        bw = d.textbbox((0, 0), label, font=f_pill)[2] + 34
        d.rounded_rectangle([px, 330, px + bw, 380], radius=25, fill=fill_c, outline=BORDER, width=1)
        d.text((px + 17, 344), label, font=f_pill, fill=text_c)
        px += bw + 14

    png_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.png")
    jpg_path = os.path.join(STORE_DIR, "feature_graphic_1024x500.jpg")
    img.save(png_path, "PNG")
    img.convert("RGB").save(jpg_path, "JPEG", quality=95)


def make_screenshot(filename, headline, subline, mode):
    w, h = 1080, 1920
    img = Image.new("RGBA", (w, h), BG)
    img = add_radial_glow(img, 540, 280, 420, (16, 185, 129), 44)
    d = ImageDraw.Draw(img)

    f_h = load_font(F_BOLD, 64)
    f_sub = load_font(F_REG, 30)
    f_title = load_font(F_BOLD, 34)
    f_body = load_font(F_REG, 24)
    f_lbl = load_font(F_BOLD, 20)

    d.text((80, 96), headline, font=f_h, fill=TEXT_PRIMARY)
    d.text((80, 260), subline, font=f_sub, fill=TEXT_SECONDARY)

    px, py, pw, ph = 90, 360, 900, 1460
    d.rounded_rectangle([px, py, px + pw, py + ph], radius=44, fill=BG, outline=BORDER, width=4)
    d.text((px + 40, py + 42), "DidIt", font=load_font(F_BOLD, 40), fill=TEXT_PRIMARY)

    if mode == "queue":
        d.rounded_rectangle([px + 36, py + 120, px + pw - 36, py + 230], radius=22, fill=SURFACE, outline=BORDER, width=2)
        d.text((px + 64, py + 150), "2 due now · 5 confirmed today", font=f_title, fill=TEXT_PRIMARY)

        # Card 1: Due Now
        cy = py + 266
        d.rounded_rectangle([px + 36, cy, px + pw - 36, cy + 280], radius=24, fill=SURFACE, outline=CORAL, width=2)
        d.rounded_rectangle([px + pw - 190, cy + 28, px + pw - 64, cy + 68], radius=20, fill=CORAL_TINT)
        draw_centered_text(d, (px + pw - 190, cy + 28, px + pw - 64, cy + 68), "OVERDUE", f_lbl, CORAL)
        d.text((px + 64, cy + 32), "Take Dose / Vitamin D", font=f_title, fill=TEXT_PRIMARY)
        d.text((px + 64, cy + 84), "Done 8h 15m ago (09:05) · Repeat 8h from done", font=f_body, fill=TEXT_SECONDARY)
        d.rounded_rectangle([px + 64, cy + 178, px + pw - 64, cy + 244], radius=16, fill=EMERALD)
        draw_centered_text(d, (px + 64, cy + 178, px + pw - 64, cy + 244), "DID IT", f_lbl, ON_EMERALD)

        # Card 2: Recently Done Proof
        cy2 = cy + 312
        d.rounded_rectangle([px + 36, cy2, px + pw - 36, cy2 + 270], radius=24, fill=SURFACE, outline=BORDER, width=2)
        d.rounded_rectangle([px + pw - 210, cy2 + 28, px + pw - 64, cy2 + 68], radius=20, fill=EMERALD_TINT)
        draw_centered_text(d, (px + pw - 210, cy2 + 28, px + pw - 64, cy2 + 68), "CONFIRMED", f_lbl, EMERALD)
        d.text((px + 64, cy2 + 32), "Feed Dog (Dinner)", font=f_title, fill=TEXT_PRIMARY)
        d.text((px + 64, cy2 + 84), "Done 18m ago (17:04) · Cooldown guard 42m", font=f_body, fill=EMERALD)
        d.text((px + 64, cy2 + 128), "Next due tomorrow at 18:00", font=f_body, fill=TEXT_SECONDARY)

        # Card 3: Laundry Chain
        cy3 = cy2 + 302
        d.rounded_rectangle([px + 36, cy3, px + pw - 36, cy3 + 220], radius=24, fill=SURFACE, outline=BORDER, width=2)
        d.text((px + 64, cy3 + 32), "Move Laundry to Dryer", font=f_title, fill=TEXT_PRIMARY)
        d.text((px + 64, cy3 + 84), "Auto-triggered after Start Washer · Due in 42m", font=f_body, fill=TEXT_SECONDARY)

    elif mode == "flows":
        cy = py + 128
        d.rounded_rectangle([px + 36, cy, px + pw - 36, cy + 520], radius=24, fill=SURFACE, outline=BORDER, width=2)
        d.text((px + 64, cy + 32), "Leaving Home Check", font=f_title, fill=TEXT_PRIMARY)
        d.text((px + 64, cy + 82), "Auto-resets 15m after all steps · 14 runs", font=f_body, fill=TEXT_SECONDARY)
        d.rounded_rectangle([px + 64, cy + 134, px + pw - 64, cy + 150], radius=8, fill=ELEVATED)
        d.rounded_rectangle([px + 64, cy + 134, px + 640, cy + 150], radius=8, fill=EMERALD)

        steps = [("Stove & appliances off", True), ("Windows closed", True), ("Grab keys & wallet", True), ("Front door locked", False)]
        sy = cy + 188
        for txt, done in steps:
            col = EMERALD if done else TEXT_PRIMARY
            mark = "[x]" if done else "[ ]"
            d.text((px + 64, sy), f"{mark}  {txt}", font=f_body, fill=col)
            sy += 74

        cy2 = cy + 560
        d.rounded_rectangle([px + 36, cy2, px + pw - 36, cy2 + 280], radius=24, fill=SURFACE, outline=BORDER, width=2)
        d.text((px + 64, cy2 + 32), "Pet Care Daily Flow", font=f_title, fill=TEXT_PRIMARY)
        d.text((px + 64, cy2 + 82), "Resets daily at 06:00 · 3/3 done today", font=f_body, fill=EMERALD)
        d.text((px + 64, cy2 + 148), "Breakfast · Main Walk · Dinner", font=f_body, fill=TEXT_SECONDARY)

    elif mode == "cooldown":
        d.rounded_rectangle([px + 80, py + 280, px + pw - 80, py + 820], radius=28, fill=SURFACE, outline=AMBER, width=3)
        d.text((px + 130, py + 340), "Already done recently?", font=load_font(F_BOLD, 42), fill=TEXT_PRIMARY)
        d.text((px + 130, py + 430), 'You confirmed "Ibuprofen 400mg"\n18m ago.\n\nDouble-tap lock active (1h 42m left).\nMark it done again anyway?', font=f_sub, fill=TEXT_SECONDARY)
        d.rounded_rectangle([px + 130, py + 700, px + 410, py + 772], radius=16, fill=ELEVATED, outline=BORDER, width=2)
        draw_centered_text(d, (px + 130, py + 700, px + 410, py + 772), "Cancel", f_lbl, TEXT_PRIMARY)
        d.rounded_rectangle([px + 440, py + 700, px + pw - 130, py + 772], radius=16, fill=EMERALD)
        draw_centered_text(d, (px + 440, py + 700, px + pw - 130, py + 772), "Mark Again", f_lbl, ON_EMERALD)

    else:
        cy = py + 128
        logs = [
            ("Take Vitamin D", "Today · 09:05 · Done 8h ago", "APP"),
            ("Water Monstera Plant", "Yesterday · 19:20 · Done 1d ago", "NOTIF"),
            ("Front door locked", "Nov 10 · 22:45 · Flow run #14", "FLOW"),
            ("Move Laundry to Dryer", "Nov 10 · 16:12 · Chained step", "APP"),
            ("Change AC Filter", "Sep 14 · Done 58d ago", "APP"),
        ]
        for title, meta, src in logs:
            d.rounded_rectangle([px + 36, cy, px + pw - 36, cy + 160], radius=22, fill=SURFACE, outline=BORDER, width=2)
            d.text((px + 64, cy + 28), title, font=f_title, fill=TEXT_PRIMARY)
            d.text((px + 64, cy + 84), meta, font=f_body, fill=TEXT_SECONDARY)
            d.rounded_rectangle([px + pw - 170, cy + 32, px + pw - 64, cy + 72], radius=18, fill=EMERALD_TINT)
            draw_centered_text(d, (px + pw - 170, cy + 32, px + pw - 64, cy + 72), src, f_lbl, EMERALD)
            cy += 190

    img.save(os.path.join(STORE_DIR, filename), "PNG")


def main():
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(STORE_DIR, exist_ok=True)

    logo = build_transparent_logo()
    logo.save(os.path.join(ASSETS_DIR, "app_logo.png"), "PNG")

    icon = build_store_icon()
    icon.save(os.path.join(STORE_DIR, "icon_512x512.png"), "PNG")

    mipmaps = {"mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96, "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192}
    for folder, px in mipmaps.items():
        d_out = os.path.join(RES_DIR, folder)
        os.makedirs(d_out, exist_ok=True)
        icon.resize((px, px), Image.Resampling.LANCZOS).save(os.path.join(d_out, "ic_launcher.png"), "PNG")

    os.makedirs(os.path.join(WEB_DIR, "icons"), exist_ok=True)
    icon.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(WEB_DIR, "icons", "Icon-192.png"), "PNG")
    icon.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(WEB_DIR, "icons", "Icon-512.png"), "PNG")
    icon.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(WEB_DIR, "icons", "Icon-maskable-192.png"), "PNG")
    icon.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(WEB_DIR, "icons", "Icon-maskable-512.png"), "PNG")
    logo.resize((64, 64), Image.Resampling.LANCZOS).save(os.path.join(WEB_DIR, "favicon.png"), "PNG")

    # iOS AppIcon (RGB without alpha)
    icon_rgb = icon.convert("RGB")
    if os.path.exists(IOS_DIR):
        ios_sizes = {
            "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40, "Icon-App-20x20@3x.png": 60,
            "Icon-App-29x29@1x.png": 29, "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
            "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80, "Icon-App-40x40@3x.png": 120,
            "Icon-App-60x60@2x.png": 120, "Icon-App-60x60@3x.png": 180,
            "Icon-App-76x76@1x.png": 76, "Icon-App-76x76@2x.png": 152,
            "Icon-App-83.5x83.5@2x.png": 167, "Icon-App-1024x1024@1x.png": 1024,
        }
        for fname, px in ios_sizes.items():
            p = os.path.join(IOS_DIR, fname)
            if os.path.exists(p):
                icon_rgb.resize((px, px), Image.Resampling.LANCZOS).save(p, "PNG")

    build_feature_graphic(icon)
    make_screenshot("screenshot_01_queue_proof.png", "Instant Done Proof.\nZero Second-Guessing.", "Exact elapsed timestamps · Notification quick actions", "queue")
    make_screenshot("screenshot_02_flows_chains.png", "Auto-Resetting Flows\n& Chained Triggers", "Leave-home checklists · Washer -> Dryer auto-timers", "flows")
    make_screenshot("screenshot_03_cooldown_guard.png", "Anti-Double-Do\nCooldown Protection", "Blocks accidental repeat taps on doses & feeding", "cooldown")
    make_screenshot("screenshot_04_logbook_settings.png", "100% Offline\nConfirmation Logbook", "Audit history on-device · Zero internet permission", "logbook")
    print("Generated all DidIt icons, banners, and Play Store screenshots successfully.")


if __name__ == "__main__":
    main()
