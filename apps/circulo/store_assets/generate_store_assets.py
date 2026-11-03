import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUTPUT_DIR = r"c:\Projects\Omniverse Labs\apps\circulo\store_assets"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def create_gradient(width, height, color1, color2, angle_degrees=45):
    """Genera una imagen con degradado suave entre dos colores."""
    im = Image.new("RGBA", (width, height))
    angle_rad = math.radians(angle_degrees)
    cos_a = math.cos(angle_rad)
    sin_a = math.sin(angle_rad)
    
    # Normalizar longitud máxima de proyección
    max_proj = abs(width * cos_a) + abs(height * sin_a)
    
    pixels = im.load()
    for y in range(height):
        for x in range(width):
            # Proyección a lo largo del vector del ángulo
            proj = (x - width / 2) * cos_a + (y - height / 2) * sin_a
            t = (proj / max_proj) + 0.5
            t = max(0.0, min(1.0, t))
            
            r = int(color1[0] * (1 - t) + color2[0] * t)
            g = int(color1[1] * (1 - t) + color2[1] * t)
            b = int(color1[2] * (1 - t) + color2[2] * t)
            pixels[x, y] = (r, g, b, 255)
    return im

def draw_circulo_nodes(draw, cx, cy, radius, node_radius, line_width, color_line, color_nodes):
    """Dibuja el isotipo de 4 nodos interconectados (Grafo K_4 de Círculo)."""
    # 4 nodos en cruz/diamante
    angles = [-math.pi/2, 0, math.pi/2, math.pi]
    points = [
        (cx + radius * math.cos(a), cy + radius * math.sin(a))
        for a in angles
    ]
    
    # 1. Dibujar anillo exterior
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.ellipse(bbox, outline=color_line, width=line_width)
    
    # 2. Dibujar interconexiones internas (todos con todos: K_4)
    for i in range(len(points)):
        for j in range(i + 1, len(points)):
            draw.line([points[i], points[j]], fill=color_line, width=int(line_width * 0.75))
            
    # 3. Dibujar los 4 nodos circulares
    for i, p in enumerate(points):
        # Color diferenciado para los 4 roles (Organizador, Conector, Explorador, Chill)
        node_col = color_nodes[i % len(color_nodes)]
        n_box = [p[0] - node_radius, p[1] - node_radius, p[0] + node_radius, p[1] + node_radius]
        draw.ellipse(n_box, fill=node_col, outline=(255, 255, 255, 255), width=int(line_width * 0.5))

def generate_app_icon():
    """Genera el App Icon oficial para Google Play Store (512x512 px)."""
    w, h = 512, 512
    # Fondo con degradado Electric Violet -> Deep Purple
    base = create_gradient(w, h, (76, 29, 149), (26, 11, 62), angle_degrees=135)
    draw = ImageDraw.Draw(base)
    
    # Halo brillante en el centro
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    halo_draw.ellipse([w*0.2, h*0.2, w*0.8, h*0.8], fill=(124, 58, 237, 70))
    halo = halo.filter(ImageFilter.GaussianBlur(30))
    base.alpha_composite(halo)
    draw = ImageDraw.Draw(base)
    
    # Colores para los 4 roles:
    # 1: Coral (#F43F5E), 2: Amber (#F59E0B), 3: Emerald (#10B981), 4: Cyan (#06B6D4)
    role_colors = [
        (244, 63, 94),   # Organizer (Coral)
        (245, 158, 11),  # Connector (Amber)
        (16, 185, 129),  # Explorer (Emerald)
        (6, 182, 212),   # Chill (Cyan)
    ]
    
    # Dibujar isotipo centrado
    draw_circulo_nodes(
        draw=draw,
        cx=w // 2,
        cy=h // 2,
        radius=130,
        node_radius=32,
        line_width=12,
        color_line=(255, 255, 255, 220),
        color_nodes=role_colors,
    )
    
    output_path = os.path.join(OUTPUT_DIR, "icon_512x512.png")
    base.convert("RGB").save(output_path, "PNG")
    print(f"App Icon generado: {output_path}")

def generate_feature_graphic():
    """Genera el Feature Graphic oficial para Google Play Store (1024x500 px)."""
    w, h = 1024, 500
    base = create_gradient(w, h, (46, 16, 101), (15, 12, 32), angle_degrees=90)
    
    # Halos de acento
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    halo_draw.ellipse([w*0.65, h*0.1, w*1.05, h*0.9], fill=(244, 63, 94, 60))
    halo_draw.ellipse([w*0.1, h*0.3, w*0.45, h*1.1], fill=(124, 58, 237, 50))
    halo = halo.filter(ImageFilter.GaussianBlur(50))
    base.alpha_composite(halo)
    
    draw = ImageDraw.Draw(base)
    
    # Dibujar Isotipo grande a la derecha
    role_colors = [
        (244, 63, 94),
        (245, 158, 11),
        (16, 185, 129),
        (6, 182, 212),
    ]
    draw_circulo_nodes(
        draw=draw,
        cx=int(w * 0.78),
        cy=int(h * 0.5),
        radius=135,
        node_radius=30,
        line_width=10,
        color_line=(255, 255, 255, 230),
        color_nodes=role_colors,
    )
    
    # Texto a la izquierda
    # Omniverse Labs Tag
    draw.text((80, 110), "OMNIVERSE LABS PRESENTA", fill=(245, 158, 11, 255))
    
    # Círculo Title
    draw.text((80, 140), "Círculo", fill=(255, 255, 255, 255))
    
    # Taglines
    draw.text((80, 240), "Amigos en grupos de 4 a 10 personas", fill=(255, 255, 255, 240))
    draw.text((80, 275), "Chau a la incomodidad de las citas 1 a 1", fill=(216, 180, 254, 255))
    
    # 4 Bullets con badges
    badges = [
        ("🎯 Match Grupal 4/4", 80, 340, (244, 63, 94)),
        ("👥 Modo Dupla", 270, 340, (245, 158, 11)),
        ("📍 Salidas Reales", 410, 340, (16, 185, 129)),
        ("🛡️ 100% Online", 570, 340, (6, 182, 212)),
    ]
    for text, bx, by, col in badges:
        draw.rectangle([bx, by, bx + 130, by + 34], fill=(255, 255, 255, 20), outline=col, width=2)
        draw.text((bx + 10, by + 9), text, fill=(255, 255, 255, 255))
        
    output_path = os.path.join(OUTPUT_DIR, "feature_graphic_1024x500.png")
    base.convert("RGB").save(output_path, "PNG")
    print(f"Feature Graphic generado: {output_path}")

def generate_screenshots():
    """Genera 5 capturas de pantalla promocionales (1080x1920 px) para Google Play."""
    w, h = 1080, 1920
    
    screens = [
        {
            "filename": "screenshot_1_discover.png",
            "tag": "DESCUBRIMIENTO INTELIGENTE",
            "title": "Match Grupal al Conectar 4 Personas",
            "subtitle": "Conocé personas afines sin la presión de las citas individuales.",
            "card_title": "Círculo en Formación (3/4)",
            "card_sub": "Falta 1 amigo/a para armar el grupo • Café & Juegos",
            "accent": (124, 58, 237),
            "emoji": "🎯",
        },
        {
            "filename": "screenshot_2_celebration.png",
            "tag": "¡MATCH CON ÉXITO!",
            "title": "¡Círculo de 4 Formado!",
            "subtitle": "4 personas coincidieron mutuamente. El chat grupal se desbloquea al instante.",
            "card_title": "Club del Café & Charlas",
            "card_sub": "Valentina, Mateo, Camila y vos coinciden en intereses",
            "accent": (244, 63, 94),
            "emoji": "🎊",
        },
        {
            "filename": "screenshot_3_meetups.png",
            "tag": "VIDA SOCIAL REAL",
            "title": "Salidas Reales & Check-in Confirmado",
            "subtitle": "Proponé planes grupales y sumá insignias de asistencia real a tu perfil.",
            "card_title": "Merienda en Colegiales",
            "card_sub": "Cuervo Café • Sábado 17:00 hs • 4 confirmados",
            "accent": (16, 185, 129),
            "emoji": "☕",
        },
        {
            "filename": "screenshot_4_duo_mode.png",
            "tag": "MODO DUPLA",
            "title": "Buscá Amigos con tu Mejor Amigo/a",
            "subtitle": "Vinculá tu perfil y busquen juntos para completar círculos 2/4 a 4/4.",
            "card_title": "Dupla Activa: Leo & Lucas",
            "card_sub": "Buscando 2 personas afines para armar mesa de juegos",
            "accent": (245, 158, 11),
            "emoji": "👥",
        },
        {
            "filename": "screenshot_5_circulo_plus.png",
            "tag": "CÍRCULO PLUS & TIENDA",
            "title": "Swipes Ilimitados & Quién te Dio Like",
            "subtitle": "Desbloqueá todo tu potencial social, fotos nítidas y 0 publicidades.",
            "card_title": "Membresía Círculo Plus Activa ⭐",
            "card_sub": "1 Boost semanal incluido • Deshacer swipes ilimitado",
            "accent": (217, 119, 6),
            "emoji": "⭐",
        },
    ]
    
    for scr in screens:
        base = create_gradient(w, h, (30, 16, 60), (10, 8, 20), angle_degrees=135)
        
        # Acentos visuales
        halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        hdraw = ImageDraw.Draw(halo)
        hdraw.ellipse([w*0.1, h*0.2, w*0.9, h*0.65], fill=(scr["accent"][0], scr["accent"][1], scr["accent"][2], 40))
        halo = halo.filter(ImageFilter.GaussianBlur(60))
        base.alpha_composite(halo)
        
        draw = ImageDraw.Draw(base)
        
        # Tag superior
        draw.rectangle([w*0.5 - 160, 120, w*0.5 + 160, 165], fill=(scr["accent"][0], scr["accent"][1], scr["accent"][2], 180))
        draw.text((w*0.5 - 130, 132), scr["tag"], fill=(255, 255, 255, 255))
        
        # Título principal
        draw.text((80, 210), scr["title"], fill=(255, 255, 255, 255))
        draw.text((80, 270), scr["subtitle"], fill=(200, 200, 220, 255))
        
        # Mockup de Pantalla / Tarjeta de la App en el centro
        card_x1, card_y1 = 100, 420
        card_x2, card_y2 = w - 100, h - 180
        
        # Marco del teléfono
        draw.rounded_rectangle([card_x1, card_y1, card_x2, card_y2], radius=40, fill=(24, 20, 38, 250), outline=(255, 255, 255, 60), width=4)
        
        # App Bar simulada
        draw.rectangle([card_x1 + 4, card_y1 + 4, card_x2 - 4, card_y1 + 100], fill=(36, 30, 56, 255))
        draw.text((card_x1 + 40, card_y1 + 40), f"Círculo • {scr['emoji']}", fill=(255, 255, 255, 255))
        
        # Tarjeta interna simulada de la app
        sub_x1, sub_y1 = card_x1 + 40, card_y1 + 140
        sub_x2, sub_y2 = card_x2 - 40, card_y2 - 140
        draw.rounded_rectangle([sub_x1, sub_y1, sub_x2, sub_y2], radius=28, fill=(48, 40, 72, 255), outline=scr["accent"], width=3)
        
        # Contenido de la tarjeta
        draw.text((sub_x1 + 40, sub_y1 + 50), scr["card_title"], fill=(255, 255, 255, 255))
        draw.text((sub_x1 + 40, sub_y1 + 100), scr["card_sub"], fill=(220, 220, 240, 255))
        
        # Botón CTA de la pantalla
        btn_y = sub_y2 - 120
        draw.rounded_rectangle([sub_x1 + 40, btn_y, sub_x2 - 40, btn_y + 70], radius=18, fill=scr["accent"])
        draw.text((sub_x1 + 180, btn_y + 22), "EXPLORAR Y CONECTAR", fill=(255, 255, 255, 255))
        
        output_path = os.path.join(OUTPUT_DIR, scr["filename"])
        base.convert("RGB").save(output_path, "PNG")
        print(f"Screenshot generado: {output_path}")

if __name__ == "__main__":
    generate_app_icon()
    generate_feature_graphic()
    generate_screenshots()
    print("¡Todos los assets de Google Play Store fueron generados con éxito!")
