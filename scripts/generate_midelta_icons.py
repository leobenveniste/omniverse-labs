import os
import sys
import math
from PIL import Image, ImageDraw

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

res_dir = r"c:\Projects\Omniverse Labs\apps\mi_delta\android\app\src\main\res"

# Generate high-resolution 1024x1024 master icon
size = 1024
master = Image.new("RGBA", (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(master)

# We draw the Municipality Logo emblem
# Dimensions
w, h = size, size

# Coordinates for shield
# Point top center: (w*0.5, h*0.05)
# Top-right curve: (w*0.88, h*0.34)
# Bottom tip: (w*0.5, h*0.94)
# Top-left curve: (w*0.12, h*0.34)

# Create shield polygon / mask
mask = Image.new("L", (w, h), 0)
mask_draw = ImageDraw.Draw(mask)

# Approximate bezier shield path with polygon points
points = []
# Top center to top right
for t in [i / 50.0 for i in range(51)]:
    # Cubic bezier: P0=(0.5, 0.05), P1=(0.72, 0.05), P2=(0.88, 0.16), P3=(0.88, 0.34)
    x = (1-t)**3 * 0.5 + 3*(1-t)**2*t * 0.72 + 3*(1-t)*t**2 * 0.88 + t**3 * 0.88
    y = (1-t)**3 * 0.05 + 3*(1-t)**2*t * 0.05 + 3*(1-t)*t**2 * 0.16 + t**3 * 0.34
    points.append((x * w, y * h))

# Top right to bottom tip
for t in [i / 50.0 for i in range(1, 51)]:
    # P0=(0.88, 0.34), P1=(0.88, 0.64), P2=(0.5, 0.94), P3=(0.5, 0.94)
    x = (1-t)**3 * 0.88 + 3*(1-t)**2*t * 0.88 + 3*(1-t)*t**2 * 0.5 + t**3 * 0.5
    y = (1-t)**3 * 0.34 + 3*(1-t)**2*t * 0.64 + 3*(1-t)*t**2 * 0.94 + t**3 * 0.94
    points.append((x * w, y * h))

# Bottom tip to top left
for t in [i / 50.0 for i in range(1, 51)]:
    # P0=(0.5, 0.94), P1=(0.5, 0.94), P2=(0.12, 0.64), P3=(0.12, 0.34)
    x = (1-t)**3 * 0.5 + 3*(1-t)**2*t * 0.5 + 3*(1-t)*t**2 * 0.12 + t**3 * 0.12
    y = (1-t)**3 * 0.94 + 3*(1-t)**2*t * 0.94 + 3*(1-t)*t**2 * 0.64 + t**3 * 0.34
    points.append((x * w, y * h))

# Top left to top center
for t in [i / 50.0 for i in range(1, 51)]:
    # P0=(0.12, 0.34), P1=(0.12, 0.16), P2=(0.28, 0.05), P3=(0.5, 0.05)
    x = (1-t)**3 * 0.12 + 3*(1-t)**2*t * 0.12 + 3*(1-t)*t**2 * 0.28 + t**3 * 0.5
    y = (1-t)**3 * 0.34 + 3*(1-t)**2*t * 0.16 + 3*(1-t)*t**2 * 0.05 + t**3 * 0.05
    points.append((x * w, y * h))

mask_draw.polygon(points, fill=255)

# Gradient background for shield: deep navy/cyan (#032244 to #0284C7)
shield_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
shield_draw = ImageDraw.Draw(shield_img)
for y in range(h):
    ratio = y / h
    r = int(3 * (1 - ratio) + 2 * ratio)
    g = int(34 * (1 - ratio) + 132 * ratio)
    b = int(68 * (1 - ratio) + 199 * ratio)
    shield_draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

shield_masked = Image.new("RGBA", (w, h), (0, 0, 0, 0))
shield_masked.paste(shield_img, (0, 0), mask)

# Draw teal border around shield
border_draw = ImageDraw.Draw(shield_masked)
border_draw.line(points + [points[0]], fill=(0, 168, 112, 255), width=int(w * 0.035), joint="curve")

# Golden Sun in the upper half
sun_center = (int(w * 0.5), int(h * 0.32))
sun_radius = int(w * 0.13)
border_draw.ellipse(
    [
        (sun_center[0] - sun_radius, sun_center[1] - sun_radius),
        (sun_center[0] + sun_radius, sun_center[1] + sun_radius),
    ],
    fill=(251, 191, 36, 255),
)

# Delta river wave 1 (white)
wave1_pts = []
for t in [i / 50.0 for i in range(51)]:
    x = (1-t)**3 * 0.26 + 3*(1-t)**2*t * 0.34 + 3*(1-t)*t**2 * 0.42 + t**3 * 0.50
    y = (1-t)**3 * 0.50 + 3*(1-t)**2*t * 0.44 + 3*(1-t)*t**2 * 0.54 + t**3 * 0.48
    wave1_pts.append((x * w, y * h))
for t in [i / 50.0 for i in range(1, 51)]:
    x = (1-t)**3 * 0.50 + 3*(1-t)**2*t * 0.58 + 3*(1-t)*t**2 * 0.66 + t**3 * 0.74
    y = (1-t)**3 * 0.48 + 3*(1-t)**2*t * 0.42 + 3*(1-t)*t**2 * 0.52 + t**3 * 0.46
    wave1_pts.append((x * w, y * h))
border_draw.line(wave1_pts, fill=(255, 255, 255, 230), width=int(w * 0.04), joint="curve")

# Delta river wave 2 (teal / emerald)
wave2_pts = []
for t in [i / 50.0 for i in range(51)]:
    x = (1-t)**3 * 0.22 + 3*(1-t)**2*t * 0.32 + 3*(1-t)*t**2 * 0.40 + t**3 * 0.50
    y = (1-t)**3 * 0.62 + 3*(1-t)**2*t * 0.54 + 3*(1-t)*t**2 * 0.66 + t**3 * 0.58
    wave2_pts.append((x * w, y * h))
for t in [i / 50.0 for i in range(1, 51)]:
    x = (1-t)**3 * 0.50 + 3*(1-t)**2*t * 0.60 + 3*(1-t)*t**2 * 0.68 + t**3 * 0.78
    y = (1-t)**3 * 0.58 + 3*(1-t)**2*t * 0.50 + 3*(1-t)*t**2 * 0.62 + t**3 * 0.54
    wave2_pts.append((x * w, y * h))
border_draw.line(wave2_pts, fill=(0, 200, 140, 255), width=int(w * 0.045), joint="curve")

# Save high-res master icon
store_assets_dir = r"c:\Projects\Omniverse Labs\apps\mi_delta\assets\store"
os.makedirs(store_assets_dir, exist_ok=True)
master_path = os.path.join(store_assets_dir, "icon_512x512.png")
icon_512 = shield_masked.resize((512, 512), Image.Resampling.LANCZOS)
icon_512.save(master_path, "PNG")

# Densities
adaptive_densities = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

legacy_densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# 1. Adaptive foregrounds (centered inside transparent 108dp base canvas, 66% size)
for folder, s in adaptive_densities.items():
    target = os.path.join(res_dir, folder)
    os.makedirs(target, exist_ok=True)
    canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    emblem_size = int(s * 0.66)
    emblem = shield_masked.resize((emblem_size, emblem_size), Image.Resampling.LANCZOS)
    offset = (s - emblem_size) // 2
    canvas.paste(emblem, (offset, offset), emblem)
    canvas.save(os.path.join(target, "ic_launcher_foreground.png"), "PNG")

# 2. Legacy icons (with circular white backdrop + emblem for older Android)
for folder, s in legacy_densities.items():
    target = os.path.join(res_dir, folder)
    os.makedirs(target, exist_ok=True)
    bg = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    bg_draw.ellipse([(0, 0), (s - 1, s - 1)], fill=(255, 255, 255, 255))
    emblem_size = int(s * 0.75)
    emblem = shield_masked.resize((emblem_size, emblem_size), Image.Resampling.LANCZOS)
    offset = (s - emblem_size) // 2
    bg.paste(emblem, (offset, offset), emblem)
    bg.save(os.path.join(target, "ic_launcher.png"), "PNG")

# 3. Create anydpi-v26 adaptive icon XML
anydpi_dir = os.path.join(res_dir, "mipmap-anydpi-v26")
os.makedirs(anydpi_dir, exist_ok=True)
xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
    f.write(xml_content)

# 4. Values colors
values_dir = os.path.join(res_dir, "values")
os.makedirs(values_dir, exist_ok=True)
colors_content = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
"""
with open(os.path.join(values_dir, "colors.xml"), "w", encoding="utf-8") as f:
    f.write(colors_content)

print("✅ Mi Delta App Icons generated successfully in all densities!")
