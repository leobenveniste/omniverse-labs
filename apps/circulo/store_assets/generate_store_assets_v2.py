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

OUTPUT_DIR = r"c:\Projects\Omniverse Labs\apps\circulo\store_assets"
FONTS_DIR = r"C:\Projects\Omniverse Labs\fonts"
LOGO_PATH = r"C:\Projects\Omniverse Labs\apps\circulo\assets\images\logo_transparent_cropped.png"
os.makedirs(OUTPUT_DIR, exist_ok=True)

logo_img = Image.open(LOGO_PATH).convert("RGBA") if os.path.exists(LOGO_PATH) else None

# Dimensiones estándar Google Play Store Portrait
W, H = 1080, 1920

# Dimensiones del teléfono en pantalla (estilo smartphone moderno sin bordes)
PHONE_W = 860
PHONE_H = 1580
PHONE_X = (W - PHONE_W) // 2
PHONE_Y = 270

BEZEL = 12
SCREEN_W = PHONE_W - (BEZEL * 2)
SCREEN_H = PHONE_H - (BEZEL * 2)
SCREEN_X = PHONE_X + BEZEL
SCREEN_Y = PHONE_Y + BEZEL

# Colores de Círculo
ELECTRIC_VIOLET = (124, 58, 237)
VIBRANT_CORAL = (244, 63, 94)
GOLDEN_AMBER = (245, 158, 11)
EMERALD_GREEN = (16, 185, 129)
CYAN_ORGANIZER = (6, 182, 212)
DARK_SURFACE = (26, 22, 37)
ONYX_DEEP = (15, 13, 21)
CARD_BG = (35, 30, 48)
BORDER_COL = (55, 48, 75)

# Cargar fuentes
def get_font(name, size):
    candidates = [
        os.path.join(FONTS_DIR, name),
        os.path.join(r"C:\Windows\Fonts", name),
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    for fb in ["segoeuib.ttf", "arialbd.ttf", "segoeui.ttf", "arial.ttf"]:
        fp = os.path.join(r"C:\Windows\Fonts", fb)
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

font_tag = get_font("PlusJakartaSans.ttf", 22)
font_title = get_font("ClashGrotesk-Bold.ttf", 46)
font_ui_bold = get_font("PlusJakartaSans.ttf", 28)
font_ui_sub = get_font("montserrat.ttf", 20)
font_ui_small = get_font("montserrat.ttf", 16)
font_ui_micro = get_font("montserrat.ttf", 14)

def draw_phone_bezel(draw, x, y, w, h):
    """Dibuja el chasis del teléfono con borde metálico y esquinas redondeadas."""
    radius = 54
    # Sombra del teléfono
    # Borde exterior oscuro
    draw.rounded_rectangle([x-4, y-4, x+w+4, y+h+4], radius=radius+4, fill=(45, 40, 60))
    draw.rounded_rectangle([x, y, x+w, y+h], radius=radius, fill=(20, 18, 28))

def draw_status_bar(draw, x, y, w):
    """Dibuja la barra de estado de Android (12:30, WiFi, Batería 100%)."""
    time_str = "12:30"
    draw.text((x + 28, y + 14), time_str, font=font_ui_small, fill=(255, 255, 255, 230))
    
    # Dynamic Island / Cámara central
    cx = x + w // 2
    draw.rounded_rectangle([cx - 45, y + 10, cx + 45, y + 34], radius=12, fill=(8, 6, 12))
    
    # Iconos derecha (WiFi, Red, Batería)
    rx = x + w - 90
    draw.text((rx, y + 14), "5G  📶 🔋", font=font_ui_micro, fill=(255, 255, 255, 230))

def draw_nav_bar(draw, x, y, w, active_idx=0):
    """Dibuja la barra de navegación inferior de Círculo."""
    bar_h = 75
    by = y - bar_h
    draw.rectangle([x, by, x + w, y], fill=DARK_SURFACE)
    draw.line([x, by, x + w, by], fill=BORDER_COL, width=1)
    
    tabs = [
        ("⭕", "Descubrir"),
        ("👥", "Mis Círculos"),
        ("👤", "Perfil"),
    ]
    
    tw = w // len(tabs)
    for i, (ico, name) in enumerate(tabs):
        tx = x + i * tw + tw // 2
        is_active = (i == active_idx)
        col = ELECTRIC_VIOLET if is_active else (156, 163, 175)
        
        # Icono
        draw.text((tx - 10, by + 12), ico, font=font_ui_bold, fill=col)
        # Texto
        draw.text((tx - 24, by + 46), name, font=font_ui_micro, fill=col)
        
    # Barra de gestos de Android
    draw.rounded_rectangle([x + w//2 - 60, y - 10, x + w//2 + 60, y - 6], radius=2, fill=(255, 255, 255, 120))

def draw_app_header(draw, x, y, w, screen_img=None, title="Círculo", subtitle="Amigos en grupos de 4"):
    """Dibuja la barra superior de Círculo con el nuevo isotipo 3D."""
    text_x = x + 24
    if screen_img is not None and logo_img is not None:
        l_h = 44
        l_w = int(logo_img.width * (l_h / logo_img.height))
        l_resized = logo_img.resize((l_w, l_h), Image.Resampling.LANCZOS)
        screen_img.paste(l_resized, (x + 20, y + 14), l_resized)
        text_x = x + 20 + l_w + 14

    draw.text((text_x, y + 12), title, font=font_ui_bold, fill=(255, 255, 255))
    draw.text((text_x, y + 44), subtitle, font=font_ui_micro, fill=(196, 181, 253))
    
    # Botón filtro & Círculo Plus
    draw.rounded_rectangle([x + w - 110, y + 18, x + w - 24, y + 54], radius=16, fill=(245, 158, 11, 40), outline=GOLDEN_AMBER, width=1)
    draw.text((x + w - 100, y + 24), "⭐ PLUS", font=font_ui_micro, fill=GOLDEN_AMBER)

def draw_avatar_illustration(draw, cx, cy, radius, bg_col, hair_col, emoji_acc=""):
    """Dibuja un avatar moderno y expresivo."""
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=bg_col)
    # Cara
    face_r = int(radius * 0.65)
    draw.ellipse([cx - face_r, cy - face_r + 4, cx + face_r, cy + face_r + 4], fill=(254, 215, 170))
    # Cabello
    draw.arc([cx - face_r, cy - face_r, cx + face_r, cy + face_r], 180, 360, fill=hair_col, width=int(radius*0.35))
    # Ojos sonrientes
    draw.text((cx - 18, cy - 8), "•", font=font_ui_bold, fill=(30, 20, 20))
    draw.text((cx + 8, cy - 8), "•", font=font_ui_bold, fill=(30, 20, 20))
    # Sonrisa
    draw.arc([cx - 12, cy + 2, cx + 12, cy + 18], 20, 160, fill=(30, 20, 20), width=2)
    if emoji_acc:
        draw.text((cx + radius - 16, cy + radius - 20), emoji_acc, font=font_ui_small)

# SCREEN 1: Mazo de Descubrimiento (Discover Screen)
def render_screen_1(draw, sx, sy, sw, sh, screen_img=None):
    draw_status_bar(draw, sx, sy, sw)
    draw_app_header(draw, sx, sy + 44, sw, screen_img=screen_img)
    
    # Tarjeta de Usuario Deslizable (Card principal)
    cx = sx + 20
    cy = sy + 126
    cw = sw - 40
    ch = sh - 220
    
    # Fondo de la tarjeta con gradiente elegante
    draw.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=28, fill=CARD_BG, outline=BORDER_COL, width=2)
    
    # Área de Foto / Gran Avatar Central
    photo_h = int(ch * 0.52)
    draw.rounded_rectangle([cx + 12, cy + 12, cx + cw - 12, cy + photo_h], radius=20, fill=(45, 36, 65))
    draw_avatar_illustration(draw, cx + cw//2, cy + photo_h//2, 85, ELECTRIC_VIOLET, (60, 30, 20), "✨")
    
    # Badge flotante de Rol Social (Organizador)
    draw.rounded_rectangle([cx + 28, cy + 28, cx + 195, cy + 66], radius=14, fill=CYAN_ORGANIZER)
    draw.text((cx + 38, cy + 34), "🎯 Organizador", font=font_ui_small, fill=(255, 255, 255))
    
    # Chip de Afinidad Grupal
    draw.rounded_rectangle([cx + cw - 165, cy + 28, cx + cw - 28, cy + 66], radius=14, fill=(16, 185, 129, 230))
    draw.text((cx + cw - 152, cy + 34), "96% Afinidad", font=font_ui_small, fill=(255, 255, 255))
    
    # Información del Usuario
    info_y = cy + photo_h + 20
    draw.text((cx + 24, info_y), "Valentina, 24", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((cx + 24, info_y + 36), "📍 Palermo, CABA • a 2.4 km", font=font_ui_micro, fill=(156, 163, 175))
    
    # Biografía
    draw.text((cx + 24, info_y + 68), "Amante del café de especialidad y armar planes", font=font_ui_sub, fill=(243, 244, 246))
    draw.text((cx + 24, info_y + 96), "los findes. Siempre lista para un escape room 🙌", font=font_ui_sub, fill=(243, 244, 246))
    
    # Tags de Intereses
    tag_y = info_y + 138
    tags = ["☕ Café especialidad", "🎲 Juegos de mesa", "🏃 Running"]
    tx = cx + 24
    for t in tags:
        draw.rounded_rectangle([tx, tag_y, tx + 160, tag_y + 34], radius=10, fill=(50, 42, 70), outline=BORDER_COL, width=1)
        draw.text((tx + 10, tag_y + 8), t, font=font_ui_micro, fill=(216, 180, 254))
        tx += 172
        
    # Botones de Acción de Swipe (Rewind, Reject, Super-Onda, Like)
    btn_y = cy + ch - 82
    btn_cx = cx + cw // 2
    buttons = [
        (btn_cx - 150, "↩️", (75, 65, 95), 24),
        (btn_cx - 60, "❌", (239, 68, 68), 30),
        (btn_cx + 40, "⭐", GOLDEN_AMBER, 26),
        (btn_cx + 130, "❤️", VIBRANT_CORAL, 32),
    ]
    for bx, emoji, col, rad in buttons:
        draw.ellipse([bx - rad, btn_y - rad, bx + rad, btn_y + rad], fill=(30, 25, 42), outline=col, width=2)
        draw.text((bx - 12, btn_y - 12), emoji, font=font_ui_small)
        
    draw_nav_bar(draw, sx, sy + sh, sw, active_idx=0)

# SCREEN 2: Química de Roles y Círculo 4/4 Desbloqueado
def render_screen_2(draw, sx, sy, sw, sh, screen_img=None):
    draw_status_bar(draw, sx, sy, sw)
    draw_app_header(draw, sx, sy + 44, sw, screen_img=screen_img, title="Círculos en Formación", subtitle="Completando el 4º Asiento")
    
    # Card principal de Círculo en Formación (3/4)
    cx = sx + 20
    cy = sy + 130
    cw = sw - 40
    
    draw.rounded_rectangle([cx, cy, cx + cw, cy + 280], radius=24, fill=CARD_BG, outline=BORDER_COL, width=2)
    draw.text((cx + 24, cy + 20), "☕ Tarde de Café & Charlas", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((cx + 24, cy + 54), "3 de 4 miembros confirmados • ¡Falta 1 amigo/a!", font=font_ui_micro, fill=(156, 163, 175))
    
    # 4 Asientos de Roles
    roles = [
        ("Valentina", "🎯 Organizador", CYAN_ORGANIZER, cx + 45),
        ("Mateo", "💬 Conector", VIBRANT_CORAL, cx + 185),
        ("Camila", "🧭 Explorador", EMERALD_GREEN, cx + 325),
        ("Vos", "☕ Chill (4/4)", (167, 139, 250), cx + 465),
    ]
    for name, r_name, col, rx in roles:
        draw_avatar_illustration(draw, rx + 40, cy + 130, 36, col, (40, 30, 20))
        draw.text((rx + 16, cy + 175), name, font=font_ui_micro, fill=(255, 255, 255))
        draw.rounded_rectangle([rx + 8, cy + 200, rx + 75, cy + 224], radius=6, fill=col)
        draw.text((rx + 14, cy + 204), r_name.split()[0], font=font_ui_micro, fill=(255, 255, 255))
        
    # Modal Celebratorio de Match 4/4
    my = cy + 310
    mw = cw
    mh = 480
    draw.rounded_rectangle([cx, my, cx + mw, my + mh], radius=24, fill=(28, 20, 44), outline=GOLDEN_AMBER, width=2)
    
    # Confetti / Estrellas
    draw.text((cx + mw//2 - 24, my + 24), "🎉", font=font_ui_bold)
    draw.text((cx + mw//2 - 140, my + 70), "¡CÍRCULO 4/4 COMPLETADO!", font=font_ui_bold, fill=GOLDEN_AMBER)
    draw.text((cx + 36, my + 115), "¡Felicitaciones! Se logró la química perfecta entre los 4 roles.", font=font_ui_sub, fill=(243, 244, 246))
    
    # Conexión visual K4 (grafo de 4 nodos)
    gcx = cx + mw // 2
    gcy = my + 230
    gr = 65
    points = [
        (gcx, gcy - gr),
        (gcx + gr, gcy),
        (gcx, gcy + gr),
        (gcx - gr, gcy),
    ]
    for i in range(len(points)):
        for j in range(i+1, len(points)):
            draw.line([points[i], points[j]], fill=(124, 58, 237, 180), width=2)
    for p in points:
        draw.ellipse([p[0]-14, p[1]-14, p[0]+14, p[1]+14], fill=VIBRANT_CORAL, outline=(255, 255, 255), width=2)
        
    # Botón CTA principal
    draw.rounded_rectangle([cx + 30, my + mh - 90, cx + mw - 30, my + mh - 30], radius=16, fill=VIBRANT_CORAL)
    draw.text((cx + mw//2 - 95, my + mh - 70), "Abrir Chat Grupal (4/4)", font=font_ui_bold, fill=(255, 255, 255))
    
    draw_nav_bar(draw, sx, sy + sh, sw, active_idx=1)

# SCREEN 3: Chat Grupal & Plan de Salida Real
def render_screen_3(draw, sx, sy, sw, sh, screen_img=None):
    draw_status_bar(draw, sx, sy, sw)
    
    # Header de Chat con 4 Miembros
    hy = sy + 44
    draw.rectangle([sx, hy, sx + sw, hy + 75], fill=DARK_SURFACE)
    draw.line([sx, hy + 75, sx + sw, hy + 75], fill=BORDER_COL, width=1)
    draw.text((sx + 24, hy + 14), "☕ Club del Café & Juegos", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((sx + 24, hy + 46), "Valentina, Mateo, Camila y vos • 4 online", font=font_ui_micro, fill=EMERALD_GREEN)
    
    # Tarjeta de Salida Real Anclada (Meetup Card)
    my = hy + 90
    draw.rounded_rectangle([sx + 20, my, sx + sw - 20, my + 130], radius=18, fill=(20, 35, 30), outline=EMERALD_GREEN, width=1)
    draw.text((sx + 36, my + 16), "📍 PLAN CONFIRMADO (4/4)", font=font_ui_micro, fill=EMERALD_GREEN)
    draw.text((sx + 36, my + 42), "Merienda & Juegos en Cuervo Café", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((sx + 36, my + 78), "Sábado 17:00 hs • Colegiales • Check-in listo (+1)", font=font_ui_sub, fill=(209, 250, 229))
    
    # Burbujas de Chat Reales
    chat_y = my + 155
    messages = [
        ("Valentina (Organizador)", "¡Hola a todos! Qué alegría que armamos el grupo 🙌", False, CYAN_ORGANIZER),
        ("Mateo (Conector)", "¿Les parece si nos vemos este sábado a las 17 hs en Cuervo?", False, VIBRANT_CORAL),
        ("Vos (Chill)", "¡Me re prendo! Llevo el Catan y el Dixit 🎲", True, ELECTRIC_VIOLET),
        ("Camila (Explorador)", "¡Genial! Ya voté confirmado en la encuesta 📍", False, EMERALD_GREEN),
        ("Valentina (Organizador)", "¡Excelente! Reserva hecha para 4 personas ☕", False, CYAN_ORGANIZER),
    ]
    
    for sender, msg, is_me, col in messages:
        if is_me:
            bx = sx + sw - 380
            draw.rounded_rectangle([bx, chat_y, sx + sw - 24, chat_y + 80], radius=16, fill=ELECTRIC_VIOLET)
            draw.text((bx + 16, chat_y + 12), "Vos", font=font_ui_micro, fill=(216, 180, 254))
            draw.text((bx + 16, chat_y + 36), msg, font=font_ui_sub, fill=(255, 255, 255))
        else:
            bx = sx + 24
            draw.rounded_rectangle([bx, chat_y, bx + 440, chat_y + 80], radius=16, fill=CARD_BG, outline=BORDER_COL, width=1)
            draw.text((bx + 16, chat_y + 12), sender, font=font_ui_micro, fill=col)
            draw.text((bx + 16, chat_y + 36), msg, font=font_ui_sub, fill=(243, 244, 246))
        chat_y += 94
        
    # Barra de entrada de texto
    iy = sy + sh - 150
    draw.rounded_rectangle([sx + 20, iy, sx + sw - 80, iy + 54], radius=24, fill=CARD_BG, outline=BORDER_COL, width=1)
    draw.text((sx + 40, iy + 16), "Escribe un mensaje al Círculo...", font=font_ui_sub, fill=(156, 163, 175))
    draw.ellipse([sx + sw - 70, iy, sx + sw - 20, iy + 50], fill=VIBRANT_CORAL)
    draw.text((sx + sw - 52, iy + 14), "➤", font=font_ui_sub, fill=(255, 255, 255))
    
    draw_nav_bar(draw, sx, sy + sh, sw, active_idx=1)

# SCREEN 4: Modo Dupla
def render_screen_4(draw, sx, sy, sw, sh, screen_img=None):
    draw_status_bar(draw, sx, sy, sw)
    draw_app_header(draw, sx, sy + 44, sw, screen_img=screen_img, title="Modo Dupla 👥", subtitle="Buscá Amigos con tu Mejor Amigo/a")
    
    # Card de Dupla Activa
    cx = sx + 20
    cy = sy + 130
    cw = sw - 40
    
    draw.rounded_rectangle([cx, cy, cx + cw, cy + 240], radius=24, fill=(35, 28, 52), outline=GOLDEN_AMBER, width=2)
    draw.text((cx + 24, cy + 20), "👥 DUPLA VINCULADA: LEO & LUCAS", font=font_ui_bold, fill=GOLDEN_AMBER)
    draw.text((cx + 24, cy + 56), "Código de Dupla: DUO-8821 • Vinculados con éxito", font=font_ui_micro, fill=(216, 180, 254))
    
    # 2 Avatares enlazados
    draw_avatar_illustration(draw, cx + 90, cy + 145, 42, ELECTRIC_VIOLET, (30, 20, 20))
    draw_avatar_illustration(draw, cx + 190, cy + 145, 42, VIBRANT_CORAL, (80, 50, 30))
    draw.line([cx + 132, cy + 145, cx + 148, cy + 145], fill=GOLDEN_AMBER, width=3)
    
    draw.text((cx + 270, cy + 125), "Ocupan 2 plazas en bloque", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((cx + 270, cy + 160), "Completan círculos 2/4 a 4/4 en 1 paso", font=font_ui_micro, fill=(156, 163, 175))
    
    # Mazo de Dupla: Grupo 2/4 buscando otra Dupla
    dy = cy + 270
    draw.rounded_rectangle([cx, dy, cx + cw, dy + 380], radius=24, fill=CARD_BG, outline=BORDER_COL, width=2)
    draw.text((cx + 24, dy + 24), "🎯 Círculo 2/4 Buscando Amigos", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((cx + 24, dy + 60), "Sofía (Organizador) y Lucas (Explorador)", font=font_ui_sub, fill=(196, 181, 253))
    
    # Chips
    draw.rounded_rectangle([cx + 24, dy + 100, cx + 190, dy + 134], radius=10, fill=(45, 36, 65))
    draw.text((cx + 36, dy + 108), "🎲 Noche de Catan", font=font_ui_micro, fill=(255, 255, 255))
    
    draw.rounded_rectangle([cx + 205, dy + 100, cx + 370, dy + 134], radius=10, fill=(45, 36, 65))
    draw.text((cx + 218, dy + 108), "🍺 Cerveza artesanal", font=font_ui_micro, fill=(255, 255, 255))
    
    draw.text((cx + 24, dy + 160), "Buscamos 2 personas más para completar mesa.", font=font_ui_sub, fill=(243, 244, 246))
    draw.text((cx + 24, dy + 190), "¡Tu dupla encaja perfecto con nuestros intereses!", font=font_ui_sub, fill=(16, 185, 129))
    
    # Botón Match en Dupla
    draw.rounded_rectangle([cx + 24, dy + 280, cx + cw - 24, dy + 345], radius=16, fill=GOLDEN_AMBER)
    draw.text((cx + cw//2 - 130, dy + 300), "Unirnos en Dupla (Cerrar 4/4)", font=font_ui_bold, fill=(20, 15, 30))
    
    draw_nav_bar(draw, sx, sy + sh, sw, active_idx=0)

# SCREEN 5: Círculo Plus & Perfil
def render_screen_5(draw, sx, sy, sw, sh, screen_img=None):
    draw_status_bar(draw, sx, sy, sw)
    draw_app_header(draw, sx, sy + 44, sw, screen_img=screen_img, title="Mi Perfil & Membresía", subtitle="Gestión de Círculo Plus")
    
    cx = sx + 20
    cy = sy + 130
    cw = sw - 40
    
    # Tarjeta Dorada de Membresía Plus
    draw.rounded_rectangle([cx, cy, cx + cw, cy + 220], radius=24, fill=(40, 30, 20), outline=GOLDEN_AMBER, width=2)
    draw.text((cx + 24, cy + 20), "⭐ CÍRCULO PLUS ACTIVO", font=font_ui_bold, fill=GOLDEN_AMBER)
    draw.text((cx + 24, cy + 54), "Membresía Anual • Renovación en Octubre 2027", font=font_ui_micro, fill=(254, 243, 199))
    
    # 3 Métricas Plus
    metrics = [
        ("Swipes", "Ilimitados ♾️", cx + 24),
        ("Boosts", "1 Gratis/sem", cx + 180),
        ("Publicidad", "0 Ads 🛡️", cx + 360),
    ]
    for lbl, val, mx in metrics:
        draw.text((mx, cy + 110), lbl, font=font_ui_micro, fill=(217, 119, 6))
        draw.text((mx, cy + 140), val, font=font_ui_bold, fill=(255, 255, 255))
        
    # Bandeja Quién te dio like (Sin desenfoque para Plus)
    ly = cy + 250
    draw.rounded_rectangle([cx, ly, cx + cw, ly + 280], radius=24, fill=CARD_BG, outline=BORDER_COL, width=2)
    draw.text((cx + 24, ly + 20), "❤️ Quién te dio Like (14 personas)", font=font_ui_bold, fill=(255, 255, 255))
    draw.text((cx + 24, ly + 54), "Fotos nítidas y match directo desbloqueado por Círculo Plus", font=font_ui_micro, fill=(16, 185, 129))
    
    # Fila de avatares nítidos
    admirers = [
        ("Camila, 23", (244, 63, 94), cx + 30),
        ("Lucas, 25", (6, 182, 212), cx + 150),
        ("Martina, 22", (16, 185, 129), cx + 270),
        ("Tomás, 26", (167, 139, 250), cx + 390),
    ]
    for name, col, ax in admirers:
        draw_avatar_illustration(draw, ax + 45, ly + 140, 38, col, (40, 30, 20))
        draw.text((ax + 20, ly + 195), name, font=font_ui_micro, fill=(255, 255, 255))
        draw.rounded_rectangle([ax + 20, ly + 225, ax + 75, ly + 250], radius=8, fill=VIBRANT_CORAL)
        draw.text((ax + 30, ly + 229), "Match", font=font_ui_micro, fill=(255, 255, 255))
        
    # Consumibles en inventario
    by = ly + 310
    draw.rounded_rectangle([cx, by, cx + cw, by + 120], radius=18, fill=(25, 20, 35), outline=BORDER_COL, width=1)
    draw.text((cx + 24, by + 20), "⚡ Consumibles: 3 Boosts • 5 Super-Ondas disponibles", font=font_ui_sub, fill=(255, 255, 255))
    draw.text((cx + 24, by + 60), "Multiplica tu visibilidad x3 en el mazo durante 60 minutos", font=font_ui_micro, fill=(156, 163, 175))
    
    draw_nav_bar(draw, sx, sy + sh, sw, active_idx=2)

def generate_all():
    configs = [
        {
            "filename": "screenshot_1_discover.png",
            "tag": "DESCUBRIMIENTO GRUPAL",
            "title": "Conocé Amigos en Grupos Reales",
            "render_func": render_screen_1,
        },
        {
            "filename": "screenshot_2_celebration.png",
            "tag": "QUÍMICA DE ROLES",
            "title": "Match Grupal al Completar 4/4",
            "render_func": render_screen_2,
        },
        {
            "filename": "screenshot_3_meetups.png",
            "tag": "CHAT Y SALIDAS REALES",
            "title": "Organizá Planes Fuera de la Pantalla",
            "render_func": render_screen_3,
        },
        {
            "filename": "screenshot_4_duo_mode.png",
            "tag": "MODO DUPLA",
            "title": "Buscá Amigos con tu Mejor Amigo/a",
            "render_func": render_screen_4,
        },
        {
            "filename": "screenshot_5_circulo_plus.png",
            "tag": "CÍRCULO PLUS",
            "title": "Swipes Ilimitados y Fotos Nítidas",
            "render_func": render_screen_5,
        },
    ]
    
    for cfg in configs:
        # Canvas principal con gradiente oscuro y elegante de fondo
        img = Image.new("RGBA", (W, H), ONYX_DEEP)
        draw = ImageDraw.Draw(img)
        
        # Halo sutil de iluminación en la parte superior
        halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        hdraw = ImageDraw.Draw(halo)
        hdraw.ellipse([W*0.1, 40, W*0.9, 500], fill=(124, 58, 237, 35))
        halo = halo.filter(ImageFilter.GaussianBlur(60))
        img = Image.alpha_composite(img, halo)
        draw = ImageDraw.Draw(img)
        
        # Tag pill superior
        tag_text = cfg["tag"]
        tb = draw.textbbox((0, 0), tag_text, font=font_tag)
        tw = tb[2] - tb[0]
        tx = (W - tw) // 2
        ty = 80
        draw.rounded_rectangle([tx - 20, ty - 6, tx + tw + 20, ty + 30], radius=16, fill=(124, 58, 237, 30), outline=ELECTRIC_VIOLET, width=1)
        draw.text((tx, ty), tag_text, font=font_tag, fill=(196, 181, 253))
        
        # Título principal de la captura
        title_text = cfg["title"]
        ttb = draw.textbbox((0, 0), title_text, font=font_title)
        title_w = ttb[2] - ttb[0]
        draw.text(((W - title_w) // 2, 140), title_text, font=font_title, fill=(255, 255, 255))
        
        # Dibuja el Chasis del Teléfono (Smartphone Frame)
        draw_phone_bezel(draw, PHONE_X, PHONE_Y, PHONE_W, PHONE_H)
        
        # Renderiza la Pantalla In-App Real dentro del Smartphone
        screen_img = Image.new("RGBA", (SCREEN_W, SCREEN_H), ONYX_DEEP)
        sdraw = ImageDraw.Draw(screen_img)
        cfg["render_func"](sdraw, 0, 0, SCREEN_W, SCREEN_H, screen_img=screen_img)
        
        # Máscara con esquinas redondeadas para la pantalla
        mask = Image.new("L", (SCREEN_W, SCREEN_H), 0)
        mdraw = ImageDraw.Draw(mask)
        mdraw.rounded_rectangle([0, 0, SCREEN_W, SCREEN_H], radius=42, fill=255)
        
        img.paste(screen_img, (SCREEN_X, SCREEN_Y), mask)
        
        out_path = os.path.join(OUTPUT_DIR, cfg["filename"])
        img.convert("RGB").save(out_path, "PNG")
        print(f"✅ Generada captura in-app real: {out_path}")

if __name__ == "__main__":
    generate_all()
