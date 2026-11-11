import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = r"c:\Projects\Omniverse Labs"
APP_DIR = os.path.join(REPO_ROOT, "apps", "cancel_guard")
OUT_DIR = os.path.join(APP_DIR, "store_assets", "play_store")
FONTS_DIR = os.path.join(REPO_ROOT, "fonts")
os.makedirs(OUT_DIR, exist_ok=True)

# CancelGuard Design Tokens
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
AMBER_TEXT = (253, 230, 138, 255)
CORAL = (251, 113, 133, 255)   # #FB7185
CORAL_TEXT = (254, 205, 211, 255)


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


F_BOLD = ["ClashGrotesk-Bold.ttf", "PlusJakartaSans.ttf", "arialbd.ttf"]
F_REG = ["PlusJakartaSans.ttf", "Outfit.ttf", "montserrat.ttf", "arial.ttf"]


def add_radial_glow(base: Image.Image, cx: int, cy: int, radius: int, color_rgb: tuple, max_alpha: int):
    """Properly alpha-composites a smooth blurred radial glow onto an RGBA canvas."""
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(*color_rgb, max_alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(12, radius // 2)))
    return Image.alpha_composite(base, glow)


def draw_shield_emblem(draw: ImageDraw.ImageDraw, cx: int, cy: int, scale: float):
    """Draws the crisp geometric CancelGuard shield + stop-slash emblem."""
    pts = [
        (cx, cy - 145 * scale),
        (cx + 120 * scale, cy - 95 * scale),
        (cx + 110 * scale, cy + 25 * scale),
        (cx, cy + 145 * scale),
        (cx - 110 * scale, cy + 25 * scale),
        (cx - 120 * scale, cy - 95 * scale),
    ]
    draw.polygon(pts, fill=EMERALD_TINT, outline=EMERALD, width=max(3, int(10 * scale)))

    inner = [
        (cx, cy - 112 * scale),
        (cx + 90 * scale, cy - 72 * scale),
        (cx + 82 * scale, cy + 16 * scale),
        (cx, cy + 110 * scale),
        (cx - 82 * scale, cy + 16 * scale),
        (cx - 90 * scale, cy - 72 * scale),
    ]
    draw.polygon(inner, fill=(12, 26, 23, 255), outline=(16, 185, 129, 130), width=max(2, int(4 * scale)))

    r = 46 * scale
    draw.ellipse(
        [cx - r, cy - r - 6 * scale, cx + r, cy + r - 6 * scale],
        outline=EMERALD,
        width=max(3, int(12 * scale)),
    )
    offset = r * 0.65
    draw.line(
        [(cx - offset, cy - 6 * scale + offset), (cx + offset, cy - 6 * scale - offset)],
        fill=CORAL,
        width=max(3, int(12 * scale)),
    )


def draw_bell_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int, color):
    draw.arc([cx - 8, cy - 10, cx + 8, cy + 4], 180, 360, fill=color, width=2)
    draw.line([(cx - 8, cy - 3), (cx - 10, cy + 5), (cx + 10, cy + 5), (cx + 8, cy - 3)], fill=color, width=2)
    draw.ellipse([cx - 2, cy + 6, cx + 2, cy + 10], fill=color)


def draw_external_arrow(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, color):
    draw.line([(x, y + size), (x + size, y)], fill=color, width=2)
    draw.line([(x + size - 7, y), (x + size, y), (x + size, y + 7)], fill=color, width=2)


def center_x(draw, text, font, container_w, origin_x=0):
    box = draw.textbbox((0, 0), text, font=font)
    w = box[2] - box[0]
    return origin_x + (container_w - w) // 2


def draw_pill(draw, x, y, text, font, fill, text_color, outline=None, pad_x=18, pad_y=8):
    box = draw.textbbox((0, 0), text, font=font)
    tw = box[2] - box[0]
    th = box[3] - box[1]
    w = tw + pad_x * 2
    h = th + pad_y * 2
    draw.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=fill, outline=outline, width=1 if outline else 0)
    draw.text((x + pad_x, y + pad_y - 2), text, font=font, fill=text_color)
    return w, h


# ---------------------------------------------------------
# 1. APP ICON (512 x 512)
# ---------------------------------------------------------
def build_icon():
    img = Image.new("RGBA", (512, 512), BG)
    img = add_radial_glow(img, 256, 256, 150, (16, 185, 129), 52)
    draw = ImageDraw.Draw(img)

    draw.rounded_rectangle([14, 14, 498, 498], radius=108, outline=BORDER, width=3)
    draw_shield_emblem(draw, 256, 258, 1.15)

    out_path = os.path.join(OUT_DIR, "icon_512x512.png")
    img.save(out_path, "PNG")
    print(f"Saved: {out_path}")


# ---------------------------------------------------------
# 2. FEATURE GRAPHIC (1024 x 500)
# ---------------------------------------------------------
def build_feature_graphic():
    img = Image.new("RGBA", (1024, 500), BG)
    img = add_radial_glow(img, 210, 250, 170, (16, 185, 129), 48)
    draw = ImageDraw.Draw(img)

    # Subtle dark grid lines
    for x in range(0, 1024, 48):
        draw.line([(x, 0), (x, 500)], fill=(255, 255, 255, 9), width=1)
    for y in range(0, 500, 48):
        draw.line([(0, y), (1024, y)], fill=(255, 255, 255, 9), width=1)

    draw.rounded_rectangle([84, 124, 336, 376], radius=56, fill=SURFACE, outline=BORDER, width=2)
    draw_shield_emblem(draw, 210, 250, 0.68)

    f_tag = load_font(F_BOLD, 18)
    f_title = load_font(F_BOLD, 64)
    f_sub = load_font(F_REG, 26)
    f_meta = load_font(F_BOLD, 20)

    rx = 390
    draw_pill(draw, rx, 98, "100% OFFLINE • ZERO SUBSCRIPTIONS", f_tag, EMERALD_TINT, EMERALD, outline=EMERALD)
    draw.text((rx, 152), "CancelGuard", font=f_title, fill=TEXT_1)
    draw.text((rx, 232), "Stop paying for forgotten free trials.", font=f_sub, fill=TEXT_2)
    draw.text((rx, 272), "48h & 24h alerts + 1-tap cancel escape.", font=f_sub, fill=TEXT_2)

    w1, _ = draw_pill(draw, rx, 342, "PAY $1.49 ONCE", f_meta, ELEVATED, TEXT_1, outline=BORDER, pad_x=20, pad_y=11)
    draw_pill(draw, rx + w1 + 14, 342, "SAVE $30+ INSTANTLY", f_meta, EMERALD, ON_EMERALD, pad_x=20, pad_y=11)

    png_path = os.path.join(OUT_DIR, "feature_graphic_1024x500.png")
    jpg_path = os.path.join(OUT_DIR, "feature_graphic_1024x500.jpg")
    img.save(png_path, "PNG")
    img.convert("RGB").save(jpg_path, "JPEG", quality=95)
    print(f"Saved: {png_path}")
    print(f"Saved: {jpg_path}")


# ---------------------------------------------------------
# 3. 4 PHONE SCREENSHOTS (1080 x 1920)
# ---------------------------------------------------------
W, H = 1080, 1920
PX, PY, PW, PH = 96, 330, 888, 1510


def start_phone_canvas(tag: str, headline: str, subline: str):
    img = Image.new("RGBA", (W, H), BG)
    img = add_radial_glow(img, W // 2, 220, 260, (16, 185, 129), 34)
    d = ImageDraw.Draw(img)

    f_tag = load_font(F_BOLD, 22)
    f_h1 = load_font(F_BOLD, 56)
    f_sub = load_font(F_REG, 27)

    t_box = d.textbbox((0, 0), tag, font=f_tag)
    tw = t_box[2] - t_box[0] + 40
    draw_pill(d, (W - tw) // 2, 72, tag, f_tag, EMERALD_TINT, EMERALD, outline=EMERALD, pad_x=20, pad_y=8)

    hx = center_x(d, headline, f_h1, W)
    d.text((hx, 146), headline, font=f_h1, fill=TEXT_1)

    sx = center_x(d, subline, f_sub, W)
    d.text((sx, 226), subline, font=f_sub, fill=TEXT_2)

    d.rounded_rectangle([PX - 6, PY - 6, PX + PW + 6, PY + PH + 6], radius=64, fill=BORDER)
    d.rounded_rectangle([PX, PY, PX + PW, PY + PH], radius=58, fill=BG, outline=(52, 64, 80, 255), width=2)
    d.rounded_rectangle([W // 2 - 72, PY + 20, W // 2 + 72, PY + 44], radius=12, fill=SURFACE)

    return img, d


def draw_app_topbar(d):
    f_app = load_font(F_BOLD, 34)
    f_tiny = load_font(F_REG, 20)
    f_chip = load_font(F_BOLD, 22)

    y = PY + 76
    d.text((PX + 36, y), "CancelGuard", font=f_app, fill=TEXT_1)
    d.text((PX + 36, y + 42), "100% offline • Zero accounts", font=f_tiny, fill=TEXT_2)

    draw_pill(d, PX + PW - 224, y + 6, "$", f_chip, SURFACE, TEXT_1, outline=BORDER, pad_x=16, pad_y=8)
    draw_pill(d, PX + PW - 154, y + 6, "EN", f_chip, SURFACE, TEXT_1, outline=BORDER, pad_x=14, pad_y=8)
    d.ellipse([PX + PW - 76, y + 6, PX + PW - 34, y + 48], fill=EMERALD_TINT, outline=EMERALD, width=2)
    draw_bell_icon(d, PX + PW - 55, y + 27, EMERALD)


def draw_hero_metrics(d, y, risk_val, saved_val, roi_label):
    f_lbl = load_font(F_BOLD, 19)
    f_num = load_font(F_BOLD, 48)
    f_badge = load_font(F_BOLD, 19)

    gap = 20
    cw = (PW - 72 - gap) // 2
    x1 = PX + 36
    x2 = x1 + cw + gap
    h = 180

    d.rounded_rectangle([x1, y, x1 + cw, y + h], radius=24, fill=SURFACE, outline=AMBER, width=2)
    d.text((x1 + 24, y + 24), "AT RISK (30D)", font=f_lbl, fill=TEXT_2)
    d.text((x1 + 24, y + 60), risk_val, font=f_num, fill=AMBER_TEXT)

    d.rounded_rectangle([x2, y, x2 + cw, y + h], radius=24, fill=SURFACE, outline=EMERALD, width=2)
    d.text((x2 + 24, y + 24), "TOTAL SAVED", font=f_lbl, fill=TEXT_2)
    d.text((x2 + 24, y + 60), saved_val, font=f_num, fill=EMERALD)
    draw_pill(d, x2 + 24, y + 124, roi_label, f_badge, EMERALD_TINT, EMERALD, pad_x=14, pad_y=5)


def draw_segmented_toggle(d, y, active_label, history_label, active_selected=True):
    f_seg = load_font(F_BOLD, 22)
    x = PX + 36
    w = PW - 72
    h = 68
    d.rounded_rectangle([x, y, x + w, y + h], radius=34, fill=SURFACE, outline=BORDER, width=1)

    half = (w - 12) // 2
    sel_x = x + 6 if active_selected else x + 6 + half
    d.rounded_rectangle([sel_x, y + 6, sel_x + half, y + h - 6], radius=28, fill=ELEVATED)

    ax = center_x(d, active_label, f_seg, half, x + 6)
    hx = center_x(d, history_label, f_seg, half, x + 6 + half)
    d.text((ax, y + 20), active_label, font=f_seg, fill=TEXT_1 if active_selected else TEXT_2)
    d.text((hx, y + 20), history_label, font=f_seg, fill=TEXT_2 if active_selected else TEXT_1)


def draw_trial_card(d, y, name, status_text, price, cycle, dot_color, border_color, status_color, note="", highlight=False):
    f_name = load_font(F_BOLD, 30)
    f_body = load_font(F_REG, 22)
    f_note = load_font(F_REG, 20)
    f_btn = load_font(F_BOLD, 21)

    x = PX + 36
    w = PW - 72
    h = 264 if note else 224
    bg = ELEVATED if highlight else SURFACE
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=bg, outline=border_color, width=3 if highlight else 2)

    d.ellipse([x + 26, y + 34, x + 40, y + 48], fill=dot_color)
    d.text((x + 56, y + 24), name, font=f_name, fill=TEXT_1)
    d.text((x + 56, y + 66), status_text, font=f_body, fill=status_color)

    p_box = d.textbbox((0, 0), price, font=f_name)
    d.text((x + w - 26 - (p_box[2] - p_box[0]), y + 24), price, font=f_name, fill=TEXT_1)
    c_box = d.textbbox((0, 0), cycle, font=f_note)
    d.text((x + w - 26 - (c_box[2] - c_box[0]), y + 64), cycle, font=f_note, fill=TEXT_2)

    btn_y = y + 128
    if note:
        d.text((x + 56, y + 104), note, font=f_note, fill=TEXT_2)
        btn_y = y + 158

    bw = (w - 52 - 16) // 2
    d.rounded_rectangle([x + 26, btn_y, x + 26 + bw, btn_y + 72], radius=18, outline=BORDER, width=2)
    b1x = center_x(d, "Open Cancel Link", f_btn, bw - 22, x + 26)
    d.text((b1x, btn_y + 22), "Open Cancel Link", font=f_btn, fill=TEXT_1)
    t_box = d.textbbox((0, 0), "Open Cancel Link", font=f_btn)
    draw_external_arrow(d, b1x + (t_box[2] - t_box[0]) + 10, btn_y + 28, 14, TEXT_1)

    bx2 = x + 26 + bw + 16
    d.rounded_rectangle([bx2, btn_y, bx2 + bw, btn_y + 72], radius=36, fill=EMERALD)
    b2x = center_x(d, "Mark Cancelled", f_btn, bw, bx2)
    d.text((b2x, btn_y + 22), "Mark Cancelled", font=f_btn, fill=ON_EMERALD)
    return y + h


def draw_fab(d):
    f_fab = load_font(F_BOLD, 26)
    label = "+ Guard Trial"
    box = d.textbbox((0, 0), label, font=f_fab)
    fw = (box[2] - box[0]) + 64
    fh = 84
    fx = PX + PW - 36 - fw
    fy = PY + PH - 36 - fh
    d.rounded_rectangle([fx, fy, fx + fw, fy + fh], radius=42, fill=EMERALD)
    tx = center_x(d, label, f_fab, fw, fx)
    d.text((tx, fy + 26), label, font=f_fab, fill=ON_EMERALD)


def build_screenshot_1():
    img, d = start_phone_canvas(
        "ZERO-CLUTTER GUARDIAN VAULT",
        "Catch Trials Before They Charge",
        "Automatic 48h & 24h alerts • 100% offline on-device",
    )
    draw_app_topbar(d)
    draw_hero_metrics(d, PY + 186, "$74.99", "$89.97", "60x ROI")
    draw_segmented_toggle(d, PY + 394, "Active (3)", "Saved History (4)", active_selected=True)

    f_sec = load_font(F_BOLD, 20)
    d.text((PX + 36, PY + 492), "URGENT — CANCEL WINDOW OPEN", font=f_sec, fill=CORAL_TEXT)
    next_y = draw_trial_card(
        d, PY + 528,
        "Adobe Creative Cloud", "Cancel in 19h • Nov 12", "$54.99", "/mo",
        CORAL, CORAL, CORAL_TEXT,
        note="Check early termination terms before day 7",
    )
    d.text((PX + 36, next_y + 28), "PROTECTED — SAFE WINDOW", font=f_sec, fill=TEXT_2)
    next_y = draw_trial_card(
        d, next_y + 64,
        "ChatGPT Plus", "Cancel in 10d 4h • Nov 21", "$20.00", "/mo",
        EMERALD, BORDER, TEXT_2,
    )
    draw_trial_card(
        d, next_y + 20,
        "Spotify Duo", "Cancel in 18d 9h • Nov 29", "$14.99", "/mo",
        EMERALD, BORDER, TEXT_2,
    )
    draw_fab(d)

    out = os.path.join(OUT_DIR, "screenshot_01_vault.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


def build_screenshot_2():
    img, d = start_phone_canvas(
        "10-SECOND TRIAL ENTRY",
        "Log Any Free Trial in 3 Taps",
        "Built-in presets, custom dates, and dual buffer alarms",
    )
    draw_app_topbar(d)
    draw_hero_metrics(d, PY + 186, "$20.00", "$34.99", "23x ROI")

    sy = PY + 330
    d.rounded_rectangle([PX + 2, sy, PX + PW - 2, PY + PH - 2], radius=48, fill=SURFACE, outline=BORDER, width=2)
    d.rounded_rectangle([W // 2 - 48, sy + 20, W // 2 + 48, sy + 28], radius=4, fill=BORDER)

    f_title = load_font(F_BOLD, 32)
    f_lbl = load_font(F_BOLD, 20)
    f_val = load_font(F_REG, 26)
    f_chip = load_font(F_BOLD, 22)
    f_cta = load_font(F_BOLD, 28)

    sx = PX + 40
    sw = PW - 80
    d.text((sx, sy + 52), "Guard Trial or Renewal", font=f_title, fill=TEXT_1)

    d.text((sx, sy + 114), "QUICK PRESETS", font=f_lbl, fill=TEXT_2)
    cx = sx
    for p, sel in [("Netflix", False), ("Spotify", False), ("Adobe CC", True), ("ChatGPT", False)]:
        pw_c, _ = draw_pill(
            d, cx, sy + 148, p, f_chip,
            EMERALD_TINT if sel else ELEVATED,
            EMERALD if sel else TEXT_1,
            outline=EMERALD if sel else BORDER,
            pad_x=22, pad_y=12,
        )
        cx += pw_c + 12

    d.rounded_rectangle([sx, sy + 226, sx + 480, sy + 322], radius=18, fill=ELEVATED, outline=EMERALD, width=2)
    d.text((sx + 20, sy + 238), "Service / App", font=f_lbl, fill=EMERALD)
    d.text((sx + 20, sy + 272), "Adobe Creative Cloud", font=f_val, fill=TEXT_1)

    d.rounded_rectangle([sx + 498, sy + 226, sx + sw, sy + 322], radius=18, fill=ELEVATED, outline=BORDER, width=2)
    d.text((sx + 518, sy + 238), "Renewal price", font=f_lbl, fill=TEXT_2)
    d.text((sx + 518, sy + 272), "$ 54.99", font=f_val, fill=TEXT_1)

    d.text((sx, sy + 354), "TYPE", font=f_lbl, fill=TEXT_2)
    w1, _ = draw_pill(d, sx, sy + 388, "Free Trial", f_chip, EMERALD, ON_EMERALD, pad_x=24, pad_y=12)
    draw_pill(d, sx + w1 + 12, sy + 388, "Recurring", f_chip, ELEVATED, TEXT_1, outline=BORDER, pad_x=24, pad_y=12)

    d.text((sx, sy + 468), "CHARGE / TRIAL END DATE", font=f_lbl, fill=TEXT_2)
    dx = sx
    for label, sel in [("7d", True), ("14d", False), ("30d", False), ("Pick date: Nov 18", False)]:
        pw_d, _ = draw_pill(
            d, dx, sy + 502, label, f_chip,
            EMERALD if sel else ELEVATED,
            ON_EMERALD if sel else TEXT_1,
            outline=None if sel else BORDER,
            pad_x=22, pad_y=12,
        )
        dx += pw_d + 12

    d.text((sx, sy + 584), "CANCEL-BY BUFFER ALERTS", font=f_lbl, fill=TEXT_2)
    ax = sx
    for label, sel in [("48h + 24h", True), ("24h only", False), ("72h + 24h", False), ("7d + 48h", False)]:
        pw_a, _ = draw_pill(
            d, ax, sy + 618, label, f_chip,
            EMERALD if sel else ELEVATED,
            ON_EMERALD if sel else TEXT_1,
            outline=None if sel else BORDER,
            pad_x=20, pad_y=12,
        )
        ax += pw_a + 12

    d.rounded_rectangle([sx, sy + 706, sx + sw, sy + 802], radius=18, fill=ELEVATED, outline=BORDER, width=2)
    d.text((sx + 20, sy + 718), "Cancel link (Escape Hatch)", font=f_lbl, fill=TEXT_2)
    d.text((sx + 20, sy + 752), "https://account.adobe.com/plans", font=f_val, fill=TEXT_1)

    cta_y = PY + PH - 134
    d.rounded_rectangle([sx, cta_y, sx + sw, cta_y + 84], radius=42, fill=EMERALD)
    tx = center_x(d, "Activate Shield", f_cta, sw, sx)
    d.text((tx, cta_y + 25), "Activate Shield", font=f_cta, fill=ON_EMERALD)

    out = os.path.join(OUT_DIR, "screenshot_02_quick_add.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


def build_screenshot_3():
    img, d = start_phone_canvas(
        "1-TAP CANCEL ESCAPE HATCH",
        "Get Warned Before They Bill You",
        "Tap your alert to jump straight to the cancel page",
    )

    ny = PY + 72
    nx = PX + 32
    nw = PW - 64
    d.rounded_rectangle([nx, ny, nx + nw, ny + 188], radius=28, fill=ELEVATED, outline=EMERALD, width=2)
    f_notif_t = load_font(F_BOLD, 25)
    f_notif_b = load_font(F_REG, 22)
    f_notif_tag = load_font(F_BOLD, 18)
    d.text((nx + 28, ny + 22), "CancelGuard • now", font=f_notif_tag, fill=EMERALD)
    d.text((nx + 28, ny + 56), "Final Warning: Cancel Adobe CC today", font=f_notif_t, fill=TEXT_1)
    d.text((nx + 28, ny + 98), "Avoid the $54.99 charge. Tap to open", font=f_notif_b, fill=TEXT_2)
    d.text((nx + 28, ny + 128), "your Cancel Escape Hatch.", font=f_notif_b, fill=TEXT_2)

    f_sec = load_font(F_BOLD, 20)
    d.text((PX + 36, ny + 226), "OPENED FROM NOTIFICATION", font=f_sec, fill=EMERALD)
    next_y = draw_trial_card(
        d, ny + 264,
        "Adobe Creative Cloud", "Cancel in 18h • Tomorrow", "$54.99", "/mo",
        CORAL, EMERALD, CORAL_TEXT,
        note="https://account.adobe.com/plans",
        highlight=True,
    )

    ex_y = next_y + 34
    d.rounded_rectangle([PX + 36, ex_y, PX + PW - 36, ex_y + 310], radius=24, fill=SURFACE, outline=BORDER, width=2)
    f_card_t = load_font(F_BOLD, 28)
    f_card_b = load_font(F_REG, 23)
    d.text((PX + 68, ex_y + 34), "2-Tap Cancel Escape Flow", font=f_card_t, fill=TEXT_1)
    d.text((PX + 68, ex_y + 90), "1. 48h & 24h local alarms fire on-device", font=f_card_b, fill=TEXT_2)
    d.text((PX + 68, ex_y + 134), "2. Tap Open Cancel Link to cancel fast", font=f_card_b, fill=TEXT_2)
    d.text((PX + 68, ex_y + 178), "3. Tap Mark Cancelled to bank $54.99 saved", font=f_card_b, fill=EMERALD)
    draw_pill(d, PX + 68, ex_y + 230, "SUPPORTS GOOGLE PLAY & WEB LINKS", load_font(F_BOLD, 18), EMERALD_TINT, EMERALD, pad_x=16, pad_y=8)

    draw_fab(d)

    out = os.path.join(OUT_DIR, "screenshot_03_escape_hatch.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


def draw_trash_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int, color):
    draw.line([(cx - 10, cy - 8), (cx + 10, cy - 8)], fill=color, width=2)
    draw.rectangle([cx - 4, cy - 12, cx + 4, cy - 8], outline=color, width=2)
    draw.rectangle([cx - 8, cy - 8, cx + 8, cy + 10], outline=color, width=2)


def draw_history_card(d, y, name, date_str, price, cycle):
    f_name = load_font(F_BOLD, 28)
    f_body = load_font(F_REG, 22)
    f_btn = load_font(F_BOLD, 21)

    x = PX + 36
    w = PW - 72
    h = 196
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=SURFACE, outline=BORDER, width=1)
    d.ellipse([x + 26, y + 34, x + 38, y + 46], fill=TEXT_2)
    d.text((x + 54, y + 24), name, font=f_name, fill=TEXT_1)
    d.text((x + 54, y + 66), date_str, font=f_body, fill=TEXT_2)

    p_box = d.textbbox((0, 0), price, font=f_name)
    d.text((x + w - 26 - (p_box[2] - p_box[0]), y + 24), price, font=f_name, fill=EMERALD)
    c_box = d.textbbox((0, 0), cycle, font=f_body)
    d.text((x + w - 26 - (c_box[2] - c_box[0]), y + 64), cycle, font=f_body, fill=TEXT_2)

    btn_y = y + 114
    rw = w - 52 - 72 - 14
    d.rounded_rectangle([x + 26, btn_y, x + 26 + rw, btn_y + 60], radius=16, outline=BORDER, width=2)
    rx = center_x(d, "Restore", f_btn, rw, x + 26)
    d.text((rx, btn_y + 16), "Restore", font=f_btn, fill=TEXT_1)

    dx = x + 26 + rw + 14
    d.rounded_rectangle([dx, btn_y, dx + 72, btn_y + 60], radius=16, outline=BORDER, width=2)
    draw_trash_icon(d, dx + 36, btn_y + 30, CORAL_TEXT)
    return y + h


def build_screenshot_4():
    img, d = start_phone_canvas(
        "PAYS FOR ITSELF ON DAY ONE",
        "Track Every Dollar You Save",
        "Pay $1.49 once • Zero subscriptions • 100% private",
    )
    draw_app_topbar(d)
    draw_hero_metrics(d, PY + 186, "$0.00", "$123.47", "83x ROI")
    draw_segmented_toggle(d, PY + 394, "Active (0)", "Saved History (4)", active_selected=False)

    f_sec = load_font(F_BOLD, 20)
    d.text((PX + 36, PY + 492), "DODGED CHARGES & CANCELLED", font=f_sec, fill=EMERALD)

    y = draw_history_card(d, PY + 528, "Adobe Creative Cloud", "48h + 24h • Nov 12", "$54.99", "/mo")
    y = draw_history_card(d, y + 18, "Gym / Club Trial", "48h + 24h • Nov 08", "$39.00", "/mo")
    y = draw_history_card(d, y + 18, "Netflix Standard", "48h + 24h • Nov 03", "$15.49", "/mo")
    draw_history_card(d, y + 18, "YouTube Premium", "24h only • Oct 28", "$13.99", "/mo")
    draw_fab(d)

    out = os.path.join(OUT_DIR, "screenshot_04_roi_history.png")
    img.save(out, "PNG")
    print(f"Saved: {out}")


if __name__ == "__main__":
    build_icon()
    build_feature_graphic()
    build_screenshot_1()
    build_screenshot_2()
    build_screenshot_3()
    build_screenshot_4()
