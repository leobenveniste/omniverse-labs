import os
import cv2
import numpy as np
from PIL import Image

SRC = r"C:\Users\leobe\.gemini\antigravity\brain\787de36e-c419-4b3a-bbad-ef1ddd14f9b7\.user_uploaded\media_1793719529478_457a5554.jpg"
OUT_TRANSPARENT = r"C:\Projects\Omniverse Labs\apps\circulo\assets\images\logo_transparent.png"
OUT_TRANSPARENT_CROPPED = r"C:\Projects\Omniverse Labs\apps\circulo\assets\images\logo_transparent_cropped.png"
OUT_ORIGINAL_PNG = r"C:\Projects\Omniverse Labs\apps\circulo\assets\images\logo_original.png"

os.makedirs(os.path.dirname(OUT_TRANSPARENT), exist_ok=True)

# 1. Copiar original como PNG de alta fidelidad
img_orig = Image.open(SRC).convert("RGB")
img_orig.save(OUT_ORIGINAL_PNG, "PNG")

# 2. Segmentación con GrabCut para remover fondo
bgr = cv2.imread(SRC)
h, w = bgr.shape[:2]

# Bounding box aproximado del símbolo "C" central
# Dejando un margen exterior seguro como background definido
margin_x = int(w * 0.15)
margin_y = int(h * 0.12)
rect = (margin_x, margin_y, w - 2 * margin_x, h - 2 * margin_y)

mask = np.zeros((h, w), np.uint8)
bgdModel = np.zeros((1, 65), np.float64)
fgdModel = np.zeros((1, 65), np.float64)

print("Ejecutando GrabCut...")
cv2.grabCut(bgr, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)

# Máscara binaria: 1 y 3 son foreground probable/seguro
fg_mask = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype("uint8")

# Suavizado de bordes con GaussianBlur para anti-aliasing profesional
blurred_mask = cv2.GaussianBlur(fg_mask, (7, 7), 0)

# Crear imagen RGBA
rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
rgba = np.dstack([rgb, blurred_mask])

# Guardar logo transparente completo
pil_transparent = Image.fromarray(rgba, "RGBA")
pil_transparent.save(OUT_TRANSPARENT, "PNG")
print(f"Logo transparente guardado: {OUT_TRANSPARENT}")

# Crop al bounding box exacto del símbolo
bbox = pil_transparent.getbbox()
if bbox:
    cropped = pil_transparent.crop(bbox)
    cropped.save(OUT_TRANSPARENT_CROPPED, "PNG")
    print(f"Logo recortado guardado: {OUT_TRANSPARENT_CROPPED} con tamaño {cropped.size}")
