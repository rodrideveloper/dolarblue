from PIL import Image, ImageDraw, ImageFont
import math
import os
import random
import platform

# Dimensiones requeridas por Google Play
WIDTH = 1024
HEIGHT = 500


def find_system_font(preferred_name, fallback_size):
    """Busca una fuente del sistema disponible según el OS."""
    system = platform.system()
    candidates = []
    if system == "Darwin":  # macOS
        candidates = [
            f"/System/Library/Fonts/Supplemental/{preferred_name}",
            f"/System/Library/Fonts/{preferred_name}",
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/Arial.ttf",
        ]
    elif system == "Windows":
        font_dir = os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")
        candidates = [
            os.path.join(font_dir, "arialbd.ttf"),
            os.path.join(font_dir, "arial.ttf"),
            os.path.join(font_dir, "segoeuib.ttf"),
            os.path.join(font_dir, "segoeui.ttf"),
            os.path.join(font_dir, "calibrib.ttf"),
            os.path.join(font_dir, "calibri.ttf"),
        ]
    else:  # Linux / otros
        candidates = [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        ]

    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, fallback_size)
            except Exception:
                continue
    return ImageFont.load_default()


def main():
    random.seed(42)

    # Crear imagen base
    img = Image.new("RGB", (WIDTH, HEIGHT))

    # Gradiente radial desde el centro
    cx, cy = WIDTH // 2, HEIGHT // 2
    max_dist = math.sqrt(cx**2 + cy**2)
    for y in range(HEIGHT):
        for x in range(WIDTH):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            factor = dist / max_dist
            r = int(15 + (1 - factor) * 25)
            g = int(20 + (1 - factor) * 35)
            b = int(45 + (1 - factor) * 50)
            img.putpixel((x, y), (r, g, b))

    draw = ImageDraw.Draw(img)

    # Cargar fuentes
    font_title = find_system_font("Arial Bold.ttf", 95)
    font_subtitle = find_system_font("Arial.ttf", 32)
    font_price = find_system_font("Arial Bold.ttf", 70)
    font_small = find_system_font("Arial.ttf", 24)
    font_badge = find_system_font("Arial Bold.ttf", 18)

    # Líneas decorativas
    for i in range(5):
        y_base = 350 + i * 30
        points = []
        for x in range(0, WIDTH, 5):
            y = y_base + math.sin(x * 0.015 + i * 0.5) * (20 - i * 3)
            points.append((x, y))
        if len(points) > 1:
            draw.line(points, fill=(255, 215, 0), width=1)

    # Partículas doradas
    for _ in range(50):
        x = random.randint(0, WIDTH)
        y = random.randint(0, HEIGHT)
        size = random.randint(1, 3)
        brightness = random.randint(100, 255)
        draw.ellipse(
            [x - size, y - size, x + size, y + size],
            fill=(brightness, int(brightness * 0.85), 0),
        )

    # Lado izquierdo
    title = "DolarBlue"
    title_x = 60
    title_y = 80

    # Glow effect
    for offset in range(8, 0, -2):
        draw.text(
            (title_x + offset // 2, title_y + offset // 2),
            title,
            fill=(255, 200, 0),
            font=font_title,
        )

    draw.text((title_x, title_y), title, fill=(255, 215, 0), font=font_title)

    subtitle = "Cotización en tiempo real"
    draw.text(
        (title_x, title_y + 100), subtitle, fill=(255, 255, 255), font=font_subtitle
    )

    draw.line(
        [(title_x, title_y + 145), (title_x + 350, title_y + 145)],
        fill=(255, 215, 0),
        width=3,
    )

    features_y = 260
    features = [
        ((33, 150, 243), "Dólar Blue"),
        ((76, 175, 80), "Dólar Oficial"),
        ((255, 193, 7), "Euro & Historial"),
    ]

    for i, (color, text) in enumerate(features):
        y_pos = features_y + i * 45
        circle_x = title_x + 10
        circle_y = y_pos + 12
        draw.ellipse(
            [circle_x - 8, circle_y - 8, circle_x + 8, circle_y + 8], fill=color
        )
        draw.text((title_x + 30, y_pos), text, fill=(255, 255, 255), font=font_small)

    # Badges
    badge_x, badge_y = title_x, 410
    draw.rounded_rectangle(
        [badge_x, badge_y, badge_x + 100, badge_y + 35], radius=17, fill=(76, 175, 80)
    )
    draw.text((badge_x + 18, badge_y + 7), "GRATIS", fill=(255, 255, 255), font=font_badge)

    badge2_x = badge_x + 115
    draw.rounded_rectangle(
        [badge2_x, badge_y, badge2_x + 110, badge_y + 35],
        radius=17,
        fill=(244, 67, 54),
    )
    draw.ellipse(
        [badge2_x + 10, badge_y + 12, badge2_x + 22, badge_y + 24],
        fill=(255, 255, 255),
    )
    draw.text(
        (badge2_x + 28, badge_y + 7), "EN VIVO", fill=(255, 255, 255), font=font_badge
    )

    # Lado derecho: simulación de teléfono
    phone_x = 580
    phone_y = 40
    phone_w = 380
    phone_h = 420

    # Sombra
    for i in range(20, 0, -2):
        draw.rounded_rectangle(
            [
                phone_x + i,
                phone_y + i,
                phone_x + phone_w + i,
                phone_y + phone_h + i,
            ],
            radius=35,
            fill=(0, 0, 0),
        )

    # Marco
    draw.rounded_rectangle(
        [phone_x - 5, phone_y - 5, phone_x + phone_w + 5, phone_y + phone_h + 5],
        radius=38,
        fill=(60, 60, 70),
    )

    # Pantalla
    draw.rounded_rectangle(
        [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
        radius=35,
        fill=(35, 37, 58),
    )

    # Barra superior
    draw.rounded_rectangle(
        [phone_x + 10, phone_y + 10, phone_x + phone_w - 10, phone_y + 100],
        radius=25,
        fill=(255, 193, 7),
    )

    draw.ellipse(
        [phone_x + 25, phone_y + 30, phone_x + 65, phone_y + 70], fill=(255, 255, 255)
    )
    draw.text((phone_x + 35, phone_y + 32), "$", fill=(0, 100, 0), font=font_subtitle)
    draw.text(
        (phone_x + 75, phone_y + 40), "DolarBlue", fill=(0, 0, 0), font=font_small
    )

    # Cards
    card1_x, card1_y = phone_x + 20, phone_y + 120
    draw.rounded_rectangle(
        [card1_x, card1_y, card1_x + 160, card1_y + 100], radius=15, fill=(33, 150, 243)
    )
    draw.text((card1_x + 15, card1_y + 10), "BLUE", fill=(255, 255, 255), font=font_badge)
    draw.text(
        (card1_x + 15, card1_y + 40), "$1.250", fill=(255, 255, 255), font=font_subtitle
    )
    draw.text(
        (card1_x + 15, card1_y + 75), "Compra", fill=(200, 220, 255), font=font_badge
    )

    card2_x = phone_x + 195
    draw.rounded_rectangle(
        [card2_x, card1_y, card2_x + 160, card1_y + 100],
        radius=15,
        fill=(76, 175, 80),
    )
    draw.text(
        (card2_x + 15, card1_y + 10), "OFICIAL", fill=(255, 255, 255), font=font_badge
    )
    draw.text(
        (card2_x + 15, card1_y + 40), "$1.050", fill=(255, 255, 255), font=font_subtitle
    )
    draw.text(
        (card2_x + 15, card1_y + 75), "Compra", fill=(200, 255, 220), font=font_badge
    )

    # Calculadora simulada
    calc_y = card1_y + 115
    draw.rounded_rectangle(
        [phone_x + 20, calc_y, phone_x + phone_w - 20, calc_y + 130],
        radius=15,
        fill=(45, 47, 68),
        outline=(255, 215, 0),
        width=2,
    )
    draw.text(
        (phone_x + 40, calc_y + 15), "Calculadora", fill=(255, 215, 0), font=font_badge
    )

    draw.rounded_rectangle(
        [phone_x + 40, calc_y + 45, phone_x + 150, calc_y + 75],
        radius=8,
        fill=(60, 62, 85),
    )
    draw.text(
        (phone_x + 50, calc_y + 50), "$ 10.000", fill=(255, 255, 255), font=font_badge
    )

    draw.text((phone_x + 165, calc_y + 50), "⇄", fill=(255, 215, 0), font=font_small)

    draw.rounded_rectangle(
        [phone_x + 200, calc_y + 45, phone_x + 340, calc_y + 75],
        radius=8,
        fill=(60, 62, 85),
    )
    draw.text(
        (phone_x + 210, calc_y + 50), "US$ 8.00", fill=(255, 255, 255), font=font_badge
    )

    draw.ellipse(
        [phone_x + 155, calc_y + 85, phone_x + 215, calc_y + 125],
        fill=(255, 193, 7),
    )
    draw.text(
        (phone_x + 162, calc_y + 95), "CALC", fill=(0, 0, 0), font=font_badge
    )

    # Bandera argentina decorativa
    flag_x, flag_y = 920, 460
    draw.rectangle([flag_x, flag_y, flag_x + 80, flag_y + 15], fill=(116, 172, 223))
    draw.rectangle([flag_x, flag_y + 15, flag_x + 80, flag_y + 30], fill=(255, 255, 255))
    draw.rectangle([flag_x, flag_y + 30, flag_x + 80, flag_y + 45], fill=(116, 172, 223))
    draw.ellipse(
        [flag_x + 33, flag_y + 13, flag_x + 47, flag_y + 27], fill=(255, 215, 0)
    )

    # Guardar en el directorio del script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, "feature_graphic.png")
    img.save(output_path, "PNG", quality=95, optimize=True)

    file_size = os.path.getsize(output_path)
    print(f"✅ Imagen creada: {output_path}")
    print(f"📐 Dimensiones: {WIDTH}x{HEIGHT} px")
    print(f"📦 Tamaño: {file_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
