import os
from PIL import Image, ImageOps

source_path = r'C:\Projects\Omniverse Labs\apps\central_de_juegos\assets\images\logo_light.png'
res_dir = r'C:\Projects\Omniverse Labs\apps\central_de_juegos\android\app\src\main\res'

img = Image.open(source_path).convert('RGBA')

# Trim transparent bounding box
bbox = img.getbbox()
if bbox:
    img = img.crop(bbox)

# Adaptive foreground sizes (108dp base)
adaptive_densities = {
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432
}

# Legacy icon sizes (48dp base)
legacy_densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

# 1. Create Adaptive Foreground Icons (60% safe zone inside transparent 108dp canvas)
for folder, size in adaptive_densities.items():
    target_folder = os.path.join(res_dir, folder)
    os.makedirs(target_folder, exist_ok=True)
    
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    emblem_size = int(size * 0.60) # 60% safe zone, leaving 20% margin on all sides
    
    emblem = ImageOps.contain(img, (emblem_size, emblem_size), Image.Resampling.LANCZOS)
    
    offset_x = (size - emblem.width) // 2
    offset_y = (size - emblem.height) // 2
    canvas.paste(emblem, (offset_x, offset_y), emblem)
    
    canvas.save(os.path.join(target_folder, 'ic_launcher_foreground.png'), 'PNG')

# 2. Create Legacy Launcher Icons (with white circular/rounded background + centered emblem)
for folder, size in legacy_densities.items():
    target_folder = os.path.join(res_dir, folder)
    os.makedirs(target_folder, exist_ok=True)
    
    bg = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    emblem_size = int(size * 0.72)
    emblem = ImageOps.contain(img, (emblem_size, emblem_size), Image.Resampling.LANCZOS)
    
    offset_x = (size - emblem.width) // 2
    offset_y = (size - emblem.height) // 2
    bg.paste(emblem, (offset_x, offset_y), emblem)
    
    bg.save(os.path.join(target_folder, 'ic_launcher.png'), 'PNG')

# 3. Create anydpi-v26 adaptive icon XML
anydpi_dir = os.path.join(res_dir, 'mipmap-anydpi-v26')
os.makedirs(anydpi_dir, exist_ok=True)

xml_content = '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@color/ic_launcher_background"/>\n    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n'
with open(os.path.join(anydpi_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
    f.write(xml_content)

# 4. Ensure values/colors.xml has ic_launcher_background
values_dir = os.path.join(res_dir, 'values')
os.makedirs(values_dir, exist_ok=True)
colors_content = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>\n'
with open(os.path.join(values_dir, 'colors.xml'), 'w', encoding='utf-8') as f:
    f.write(colors_content)

print('Adaptive and Legacy launcher icons successfully generated with full safe-zone padding!')
