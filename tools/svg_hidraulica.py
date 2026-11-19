"""Dibujos de la hidráulica (etapa 45): piezas del atlas en art/equipos, esquemas ISO 1219 de la
pestaña «Conexión» en art/esquemas y símbolos ISO 1219-1 en art/simbolos/iso1219.

Los SVG solo usan degradados (Godot no dibuja filtros ni texto): los rótulos van en las
«etiquetas» del JSON y el relieve fino lo añade tools/dibujos_realistas/realzar.py.

Uso, desde la raíz del repositorio:  python tools/svg_hidraulica.py
Las coordenadas de bocas y marcas de cada pieza están en PIEZAS (las usa el contenido)."""
import math, os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TINTA = "#20262c"

# ----------------------------------------------------------------------------- comunes
DEFS = '''
<linearGradient id="alu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f2f5f7"/><stop offset="0.35" stop-color="#c9d1d6"/><stop offset="0.75" stop-color="#97a2a9"/><stop offset="1" stop-color="#6d777e"/></linearGradient>
<linearGradient id="aluH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d777e"/><stop offset="0.3" stop-color="#c9d1d6"/><stop offset="0.55" stop-color="#f2f5f7"/><stop offset="1" stop-color="#7d878e"/></linearGradient>
<linearGradient id="cromo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="0.25" stop-color="#dfe5e9"/><stop offset="0.5" stop-color="#8c969d"/><stop offset="0.7" stop-color="#eef2f4"/><stop offset="1" stop-color="#6f7980"/></linearGradient>
<linearGradient id="cromoV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6f7980"/><stop offset="0.3" stop-color="#eef2f4"/><stop offset="0.5" stop-color="#8c969d"/><stop offset="0.75" stop-color="#ffffff"/><stop offset="1" stop-color="#7d878e"/></linearGradient>
<linearGradient id="pintura" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6f9fd0"/><stop offset="0.3" stop-color="#3a6ea6"/><stop offset="0.75" stop-color="#1f4675"/><stop offset="1" stop-color="#132c4b"/></linearGradient>
<linearGradient id="pinturaV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#132c4b"/><stop offset="0.25" stop-color="#2f5f96"/><stop offset="0.5" stop-color="#7aa8d6"/><stop offset="0.75" stop-color="#2f5f96"/><stop offset="1" stop-color="#132c4b"/></linearGradient>
<linearGradient id="negro" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#545a5f"/><stop offset="0.4" stop-color="#2a2e32"/><stop offset="1" stop-color="#101214"/></linearGradient>
<linearGradient id="laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f7dc8c"/><stop offset="0.5" stop-color="#c9a13a"/><stop offset="1" stop-color="#7d5f14"/></linearGradient>
<linearGradient id="placa" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f3f4"/><stop offset="1" stop-color="#b3bbc0"/></linearGradient>
<linearGradient id="verde" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6fae7c"/><stop offset="0.5" stop-color="#2f7a43"/><stop offset="1" stop-color="#174024"/></linearGradient>
<radialGradient id="acero" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#f6f8f9"/><stop offset="0.55" stop-color="#b3b9bd"/><stop offset="1" stop-color="#5a6166"/></radialGradient>
<radialGradient id="agujero" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="#050607"/><stop offset="0.7" stop-color="#15191c"/><stop offset="1" stop-color="#3a4044"/></radialGradient>
<radialGradient id="brilloR" cx="0.35" cy="0.3" r="0.7"><stop offset="0" stop-color="#ffffff" stop-opacity="0.55"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
'''


def svg(w, h, cuerpo, defs=DEFS):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n<defs>{defs}</defs>\n{cuerpo}\n</svg>\n'


def hexagono(x, y, r, giro=0.0):
    return " ".join(f"{x + r * math.cos(math.radians(60 * i + giro)):.1f},{y + r * math.sin(math.radians(60 * i + giro)):.1f}" for i in range(6))


def perno(x, y, r=7):
    return (f'<polygon points="{hexagono(x, y, r)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
            f'<circle cx="{x}" cy="{y}" r="{r * 0.55:.1f}" fill="none" stroke="#5a6166" stroke-width="0.8"/>')


def allen(x, y, r=6):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#acero)" stroke="#2d3236" stroke-width="1"/>'
            f'<polygon points="{hexagono(x, y, r * 0.45)}" fill="#15181a"/>')


def boca(x, y, r, rosca=True):
    """Boca roscada vista de frente: cara mecanizada, rosca y agujero oscuro."""
    s = f'<circle cx="{x}" cy="{y}" r="{r + 5}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#agujero)"/>'
    if rosca:
        for k in (0.82, 0.66):
            s += f'<circle cx="{x}" cy="{y}" r="{r * k:.1f}" fill="none" stroke="#4a5257" stroke-width="0.9"/>'
    s += f'<path d="M{x - r * 0.7:.1f},{y - r * 0.4:.1f} A{r},{r} 0 0 1 {x + r * 0.2:.1f},{y - r * 0.85:.1f}" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="1.4"/>'
    return s


def chapa(x, y, w, h):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#placa)" stroke="#59626a" stroke-width="1"/>'
    for cx, cy in ((x + 5, y + 5), (x + w - 5, y + 5), (x + 5, y + h - 5), (x + w - 5, y + h - 5)):
        s += f'<circle cx="{cx}" cy="{cy}" r="1.8" fill="#6a737a"/>'
    for k in range(1, 4):
        s += f'<rect x="{x + 10}" y="{y + h * k / 4.4 + 2:.1f}" width="{w - 20}" height="2.2" rx="1" fill="#8a949b" opacity="0.7"/>'
    return s


def brillo(x, y, w, h, rx=3, op=0.35):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="#fff" opacity="{op}"/>'


def sombra_suelo(cx, cy, rx, ry):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#000" opacity="0.18"/>'


def eje(x, y, largo, r, chaveta=True):
    """Eje que sale hacia la izquierda desde x, con chaveta."""
    s = f'<rect x="{x - largo}" y="{y - r}" width="{largo}" height="{2 * r}" rx="2" fill="url(#cromo)" stroke="#3b4247" stroke-width="1"/>'
    if chaveta:
        s += f'<rect x="{x - largo + 6}" y="{y - r - 3}" width="{largo * 0.55:.1f}" height="5" rx="1.5" fill="url(#alu)" stroke="#3b4247" stroke-width="0.8"/>'
    return s


def flecha_giro(cx, cy, r, color="#c0392b"):
    a0, a1 = math.radians(200), math.radians(320)
    x0, y0 = cx + r * math.cos(a0), cy + r * math.sin(a0)
    x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
    return (f'<path d="M{x0:.1f},{y0:.1f} A{r},{r} 0 0 1 {x1:.1f},{y1:.1f}" fill="none" stroke="{color}" stroke-width="3"/>'
            f'<polygon points="{x1 + 7:.1f},{y1 - 2:.1f} {x1 - 4:.1f},{y1 - 7:.1f} {x1 - 1:.1f},{y1 + 6:.1f}" fill="{color}"/>')


# ----------------------------------------------------------------------------- piezas
# Cada pieza: tamaño, bocas (bornes del dibujo), marcas de las partes y etiquetas del dibujo.
PIEZAS = {}


def bomba_engranajes():
    w, h = 480, 300
    s = sombra_suelo(250, 262, 170, 14)
    # Brida de montaje SAE de dos tornillos y eje
    s += eje(118, 150, 70, 13)
    s += '<path d="M104,92 L128,92 L128,208 L104,208 Q92,150 104,92 Z" fill="url(#aluH)" stroke="#3b4247" stroke-width="1.4"/>'
    s += perno(112, 104, 7) + perno(112, 196, 7)
    # Cuerpo de aluminio en tres piezas: tapa delantera, cuerpo y tapa trasera
    s += '<rect x="128" y="88" width="56" height="124" rx="10" fill="url(#alu)" stroke="#3b4247" stroke-width="1.6"/>'
    s += '<rect x="184" y="84" width="140" height="132" rx="14" fill="url(#alu)" stroke="#3b4247" stroke-width="1.8"/>'
    s += '<rect x="324" y="88" width="50" height="124" rx="10" fill="url(#alu)" stroke="#3b4247" stroke-width="1.6"/>'
    s += brillo(134, 92, 44, 6) + brillo(190, 88, 128, 7) + brillo(330, 92, 38, 6)
    # Tornillos pasantes en la tapa trasera
    for x, y in ((340, 104), (360, 104), (340, 196), (360, 196)):
        s += allen(x, y, 6)
    # Bocas: aspiración grande (S) y presión pequeña (P) en la cara del cuerpo
    s += boca(222, 150, 17) + boca(288, 150, 11)
    # Flecha de giro fundida en el cuerpo
    s += flecha_giro(254, 112, 20, "#9aa3a9")
    s += chapa(206, 186, 96, 22)
    PIEZAS["bomba_engranajes"] = {
        "tamano": [w, h], "bocas": {"S": [222, 150], "P": [288, 150]},
        "marcas": {"eje": [70, 150], "brida": [112, 104], "aspiracion": [222, 150], "presion": [288, 150], "tornillos": [350, 196], "giro": [254, 98]},
        "etiquetas": [{"texto": "S", "x": 222, "y": 182, "tam": 14}, {"texto": "P", "x": 288, "y": 172, "tam": 14}],
    }
    return svg(w, h, s)


def bomba_pistones():
    w, h = 520, 300
    s = sombra_suelo(270, 266, 190, 14)
    s += eje(104, 166, 64, 14)
    # Brida cuadrada de montaje
    s += '<rect x="104" y="96" width="34" height="140" rx="6" fill="url(#aluH)" stroke="#3b4247" stroke-width="1.4"/>'
    s += perno(121, 110, 7) + perno(121, 222, 7)
    # Carcasa cilíndrica de fundición pintada y tapa de bocas
    s += '<rect x="138" y="100" width="230" height="132" rx="40" fill="url(#pintura)" stroke="#0f2238" stroke-width="1.8"/>'
    s += '<rect x="150" y="106" width="200" height="10" rx="5" fill="#fff" opacity="0.25"/>'
    for x in (190, 240, 290):
        s += f'<path d="M{x},104 V228" stroke="#0f2238" stroke-opacity="0.35" stroke-width="2"/>'
    s += '<rect x="368" y="104" width="70" height="124" rx="10" fill="url(#alu)" stroke="#3b4247" stroke-width="1.6"/>'
    s += brillo(374, 108, 58, 6)
    for x, y in ((380, 116), (426, 116), (380, 216), (426, 216)):
        s += allen(x, y, 6)
    # Compensador de presión encima: bloque, tornillo de ajuste y contratuerca
    s += '<rect x="250" y="56" width="92" height="46" rx="5" fill="url(#alu)" stroke="#3b4247" stroke-width="1.4"/>'
    s += brillo(254, 59, 84, 5)
    s += '<rect x="342" y="70" width="18" height="18" rx="2" fill="url(#acero)" stroke="#2d3236"/>'
    s += f'<polygon points="{hexagono(368, 79, 11, 30)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += '<rect x="378" y="74" width="34" height="10" rx="2" fill="url(#cromo)" stroke="#3b4247"/>'
    s += '<rect x="408" y="72" width="8" height="14" rx="1" fill="#15181a"/>'
    for x, y in ((262, 68), (330, 68), (262, 92), (330, 92)):
        s += allen(x, y, 4.5)
    # Bocas: aspiración y presión en la tapa, drenaje L arriba de la carcasa
    s += boca(403, 148, 15) + boca(403, 196, 10) + boca(200, 92, 7)
    s += chapa(160, 168, 92, 40)
    PIEZAS["bomba_pistones"] = {
        "tamano": [w, h], "bocas": {"S": [403, 148], "P": [403, 196], "L": [200, 92]},
        "marcas": {"eje": [56, 166], "carcasa": [300, 210], "compensador": [394, 79], "drenaje": [200, 92], "aspiracion": [403, 148], "presion": [403, 196]},
        "etiquetas": [{"texto": "S", "x": 452, "y": 148, "tam": 14}, {"texto": "P", "x": 452, "y": 196, "tam": 14}, {"texto": "L", "x": 200, "y": 70, "tam": 14}],
    }
    return svg(w, h, s)


def cilindro_hidraulico():
    w, h = 560, 220
    s = sombra_suelo(280, 196, 250, 10)
    # Vástago cromado que sale por la derecha, con su ojo
    s += '<rect x="372" y="94" width="138" height="24" rx="3" fill="url(#cromo)" stroke="#3b4247" stroke-width="1.2"/>'
    s += '<rect x="506" y="86" width="22" height="40" rx="4" fill="url(#acero)" stroke="#2d3236"/>'
    s += '<circle cx="538" cy="106" r="16" fill="url(#acero)" stroke="#2d3236" stroke-width="1.4"/><circle cx="538" cy="106" r="7" fill="url(#agujero)"/>'
    # Camisa pintada entre las dos culatas, con los tirantes
    s += '<rect x="86" y="70" width="264" height="72" rx="6" fill="url(#pintura)" stroke="#0f2238" stroke-width="1.6"/>'
    s += '<rect x="92" y="74" width="252" height="9" rx="4" fill="#fff" opacity="0.28"/>'
    for y in (64, 148):
        s += f'<rect x="60" y="{y - 3}" width="318" height="6" rx="3" fill="url(#cromo)" stroke="#3b4247" stroke-width="0.6"/>'
    # Culata trasera (A) y delantera (B), con tuercas de los tirantes
    s += '<rect x="52" y="54" width="40" height="104" rx="5" fill="url(#alu)" stroke="#3b4247" stroke-width="1.5"/>'
    s += '<rect x="344" y="54" width="40" height="104" rx="5" fill="url(#alu)" stroke="#3b4247" stroke-width="1.5"/>'
    for x in (56, 380):
        for y in (64, 148):
            s += perno(x, y, 6)
    # Rascador y casquillo en la culata delantera
    s += '<rect x="384" y="90" width="12" height="32" rx="3" fill="url(#negro)"/>'
    # Ojo trasero de fijación
    s += '<rect x="30" y="90" width="24" height="32" rx="3" fill="url(#acero)" stroke="#2d3236"/>'
    s += '<circle cx="22" cy="106" r="16" fill="url(#acero)" stroke="#2d3236" stroke-width="1.4"/><circle cx="22" cy="106" r="7" fill="url(#agujero)"/>'
    # Bocas A y B arriba de cada culata
    s += '<rect x="60" y="34" width="24" height="22" rx="3" fill="url(#acero)" stroke="#2d3236"/>'
    s += '<rect x="352" y="34" width="24" height="22" rx="3" fill="url(#acero)" stroke="#2d3236"/>'
    s += boca(72, 32, 7) + boca(364, 32, 7)
    s += chapa(170, 120, 96, 18)
    PIEZAS["cilindro_hidraulico"] = {
        "tamano": [w, h], "bocas": {"A": [72, 32], "B": [364, 32]},
        "marcas": {"camisa": [220, 96], "vastago": [450, 106], "culata_delantera": [364, 140], "culata_trasera": [72, 140], "tirantes": [300, 148], "ojos": [538, 106], "rascador": [390, 106]},
        "etiquetas": [{"texto": "A", "x": 72, "y": 10, "tam": 14}, {"texto": "B", "x": 364, "y": 10, "tam": 14}],
    }
    return svg(w, h, s)


def motor_hidraulico():
    w, h = 460, 300
    s = sombra_suelo(240, 264, 160, 14)
    s += eje(130, 150, 76, 14)
    # Brida de montaje con cuatro agujeros
    s += '<rect x="130" y="70" width="30" height="160" rx="8" fill="url(#aluH)" stroke="#3b4247" stroke-width="1.4"/>'
    for y in (84, 216):
        s += f'<circle cx="145" cy="{y}" r="7" fill="url(#agujero)"/>'
    # Carcasa del eje, cuerpo del orbital (gerotor) y tapa final
    s += '<rect x="160" y="88" width="70" height="124" rx="12" fill="url(#pintura)" stroke="#0f2238" stroke-width="1.6"/>'
    s += '<rect x="230" y="80" width="50" height="140" rx="6" fill="url(#alu)" stroke="#3b4247" stroke-width="1.5"/>'
    s += '<rect x="280" y="84" width="44" height="132" rx="6" fill="url(#pintura)" stroke="#0f2238" stroke-width="1.5"/>'
    s += '<rect x="324" y="90" width="26" height="120" rx="8" fill="url(#alu)" stroke="#3b4247" stroke-width="1.4"/>'
    s += brillo(166, 92, 58, 7) + brillo(236, 84, 38, 6) + brillo(286, 88, 32, 6)
    for x, y in ((337, 104), (337, 196), (337, 150)):
        s += allen(x, y, 5.5)
    # Bocas A y B en el costado, drenaje L
    s += boca(196, 124, 10) + boca(196, 176, 10) + boca(302, 108, 5)
    s += chapa(236, 176, 40, 34)
    PIEZAS["motor_hidraulico"] = {
        "tamano": [w, h], "bocas": {"A": [196, 124], "B": [196, 176], "L": [302, 108]},
        "marcas": {"eje": [80, 150], "brida": [145, 84], "gerotor": [255, 108], "bocas": [196, 150], "drenaje": [302, 108], "chapa": [256, 192]},
        "etiquetas": [{"texto": "A", "x": 176, "y": 124, "tam": 14}, {"texto": "B", "x": 176, "y": 176, "tam": 14}, {"texto": "L", "x": 302, "y": 86, "tam": 13}],
    }
    return svg(w, h, s)


def valvula_alivio():
    w, h = 360, 420
    s = sombra_suelo(180, 392, 130, 12)
    # Bloque de montaje con las bocas P (abajo) y T (lado)
    s += '<rect x="70" y="250" width="220" height="130" rx="8" fill="url(#alu)" stroke="#3b4247" stroke-width="1.8"/>'
    s += brillo(76, 254, 208, 8)
    for x, y in ((86, 266), (274, 266), (86, 364), (274, 364)):
        s += allen(x, y, 6)
    s += boca(140, 330, 13) + boca(232, 330, 11)
    # Cartucho: hexágono grande roscado en el bloque, cuerpo, contratuerca y tornillo con capuchón
    s += '<rect x="136" y="226" width="88" height="26" rx="2" fill="url(#acero)" stroke="#2d3236" stroke-width="1.4"/>'
    s += '<polygon points="130,226 230,226 222,206 138,206" fill="url(#acero)" stroke="#2d3236" stroke-width="1.4"/>'
    s += '<rect x="148" y="120" width="64" height="88" rx="4" fill="url(#cromoV)" stroke="#3b4247" stroke-width="1.4"/>'
    for y in range(128, 204, 8):
        s += f'<path d="M150,{y} H210" stroke="#59636a" stroke-opacity="0.5" stroke-width="0.8"/>'
    s += f'<polygon points="{hexagono(180, 108, 30, 0)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.4" transform="scale(1,0.45) translate(0,{108 / 0.45 - 108:.1f})"/>'
    s += '<rect x="150" y="96" width="60" height="18" rx="2" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += '<rect x="166" y="54" width="28" height="44" rx="3" fill="url(#cromoV)" stroke="#3b4247" stroke-width="1.2"/>'
    for y in range(58, 96, 4):
        s += f'<path d="M166,{y} H194" stroke="#59636a" stroke-width="0.8"/>'
    # Capuchón de plástico precintado y alambre del precinto
    s += '<rect x="160" y="26" width="40" height="32" rx="8" fill="url(#negro)" stroke="#0b0c0d"/>'
    s += brillo(164, 30, 10, 22, 4, 0.18)
    s += '<path d="M200,40 Q240,46 236,96 Q232,118 212,112" fill="none" stroke="#9aa3a9" stroke-width="1.6"/>'
    s += '<rect x="228" y="94" width="12" height="9" rx="2" fill="#c0392b"/>'
    PIEZAS["valvula_alivio"] = {
        "tamano": [w, h], "bocas": {"P": [140, 330], "T": [232, 330]},
        "marcas": {"capuchon": [162, 30], "tornillo": [194, 76], "contratuerca": [152, 106], "cartucho": [196, 180], "bloque": [86, 270], "presion": [140, 330], "tanque": [232, 330]},
        "etiquetas": [{"texto": "P", "x": 140, "y": 362, "tam": 15}, {"texto": "T", "x": 232, "y": 358, "tam": 15}],
    }
    return svg(w, h, s)


def estranguladora():
    w, h = 440, 260
    s = sombra_suelo(220, 228, 170, 12)
    # Cuerpo en línea con hexágonos en los extremos y las bocas 1 y 2
    s += '<rect x="96" y="120" width="248" height="70" rx="8" fill="url(#alu)" stroke="#3b4247" stroke-width="1.6"/>'
    s += brillo(102, 124, 236, 7)
    for x in (60, 344):
        s += f'<rect x="{x}" y="116" width="36" height="78" rx="4" fill="url(#acero)" stroke="#2d3236" stroke-width="1.4"/>'
        s += f'<path d="M{x},140 H{x + 36} M{x},170 H{x + 36}" stroke="#4a5257" stroke-width="1"/>'
    s += boca(44, 155, 13) + boca(396, 155, 13)
    # Flecha de sentido controlado grabada
    s += '<path d="M150,172 H286" stroke="#4a5257" stroke-width="3"/><polygon points="296,172 282,164 282,180" fill="#4a5257"/>'
    # Pomo moleteado con escala y tornillo de bloqueo
    s += '<rect x="184" y="88" width="72" height="34" rx="3" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += '<rect x="176" y="34" width="88" height="56" rx="10" fill="url(#negro)" stroke="#0b0c0d" stroke-width="1.2"/>'
    for x in range(182, 262, 6):
        s += f'<path d="M{x},38 V86" stroke="#4d5358" stroke-width="2"/>'
    s += brillo(180, 38, 80, 6, 3, 0.2)
    for i, x in enumerate(range(190, 252, 6)):
        alto = 10 if i % 5 == 0 else 6
        s += f'<path d="M{x},{98} V{98 + alto}" stroke="#20262c" stroke-width="1.2"/>'
    s += '<rect x="264" y="96" width="22" height="14" rx="3" fill="url(#laton)" stroke="#5a4310"/>'
    PIEZAS["estranguladora"] = {
        "tamano": [w, h], "bocas": {"1": [44, 155], "2": [396, 155]},
        "marcas": {"pomo": [220, 62], "escala": [210, 104], "bloqueo": [275, 103], "cuerpo": [130, 140], "flecha": [250, 172], "entrada": [44, 155], "salida": [396, 155]},
        "etiquetas": [{"texto": "1", "x": 44, "y": 190, "tam": 15}, {"texto": "2", "x": 396, "y": 190, "tam": 15}],
    }
    return svg(w, h, s)


def antirretorno_pilotada():
    w, h = 440, 280
    s = sombra_suelo(220, 250, 170, 12)
    # Bloque de acero con bocas V (de la válvula), C (al cilindro) y X (piloto)
    s += '<rect x="80" y="90" width="280" height="130" rx="8" fill="url(#alu)" stroke="#3b4247" stroke-width="1.8"/>'
    s += brillo(86, 94, 268, 8)
    for x, y in ((96, 106), (344, 106), (96, 204), (344, 204)):
        s += allen(x, y, 6)
    s += boca(140, 160, 14) + boca(300, 160, 14) + boca(220, 196, 7)
    # Tapón del pistón de pilotaje en el lado y tapón superior
    s += '<rect x="360" y="134" width="22" height="52" rx="4" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += f'<polygon points="{hexagono(220, 78, 18)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += '<rect x="206" y="80" width="28" height="12" fill="url(#acero)" stroke="#2d3236"/>'
    # Flechas grabadas del sentido libre
    s += '<path d="M168,126 H262" stroke="#4a5257" stroke-width="2.6"/><polygon points="272,126 258,119 258,133" fill="#4a5257"/>'
    PIEZAS["antirretorno_pilotada"] = {
        "tamano": [w, h], "bocas": {"V": [140, 160], "C": [300, 160], "X": [220, 196]},
        "marcas": {"bloque": [344, 204], "entrada": [140, 160], "cilindro": [300, 160], "piloto": [220, 196], "tapon": [220, 78], "flecha": [220, 126], "piston": [371, 160]},
        "etiquetas": [{"texto": "V", "x": 140, "y": 194, "tam": 15}, {"texto": "C", "x": 300, "y": 194, "tam": 15}, {"texto": "X", "x": 220, "y": 216, "tam": 12}],
    }
    return svg(w, h, s)


def acumulador():
    w, h = 300, 440
    s = sombra_suelo(150, 420, 90, 10)
    # Botella de acero pintada
    s += '<path d="M90,96 Q90,48 150,44 Q210,48 210,96 L210,350 Q210,392 150,396 Q90,392 90,350 Z" fill="url(#pinturaV)" stroke="#0f2238" stroke-width="2"/>'
    s += '<path d="M104,92 Q108,62 132,56 L132,384 Q110,376 104,350 Z" fill="#fff" opacity="0.16"/>'
    # Válvula de carga de gas arriba con su tapa
    s += '<rect x="134" y="20" width="32" height="28" rx="3" fill="url(#cromoV)" stroke="#2d3236" stroke-width="1.2"/>'
    s += '<rect x="140" y="6" width="20" height="16" rx="3" fill="url(#acero)" stroke="#2d3236"/>'
    s += '<rect x="138" y="34" width="24" height="5" fill="#fff" opacity="0.3"/>'
    # Conexión de aceite abajo, con la válvula antiextrusión dentro
    s += '<rect x="130" y="392" width="40" height="22" rx="3" fill="url(#cromoV)" stroke="#2d3236" stroke-width="1.2"/>'
    s += f'<polygon points="{hexagono(150, 418, 16)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2" transform="scale(1,0.5) translate(0,418)"/>'
    # Abrazadera de sujeción
    s += '<rect x="82" y="300" width="136" height="22" rx="4" fill="url(#negro)" stroke="#0b0c0d"/>'
    s += perno(226, 311, 7)
    # Chapa y etiqueta amarilla de gas
    s += chapa(112, 170, 76, 70)
    s += '<rect x="116" y="110" width="68" height="20" rx="3" fill="url(#laton)" stroke="#5a4310"/>'
    PIEZAS["acumulador"] = {
        "tamano": [w, h], "bocas": {"N2": [150, 14], "P": [150, 404]},
        "marcas": {"valvula_gas": [150, 14], "botella": [180, 250], "chapa": [150, 205], "aviso_gas": [150, 120], "aceite": [150, 404], "abrazadera": [226, 311]},
        "etiquetas": [{"texto": "SOLO N₂", "x": 150, "y": 120, "tam": 11, "color": "#2a1a00"}],
    }
    return svg(w, h, s)


# ----------------------------------------------------------------------------- símbolos ISO 1219-1
G = 3.0  # grosor de las líneas de trabajo


def linea(x1, y1, x2, y2, g=G, trazos=False):
    d = ' stroke-dasharray="8 6"' if trazos else ''
    return f'<path d="M{x1},{y1} L{x2},{y2}" stroke="{TINTA}" stroke-width="{g}" fill="none"{d}/>'


def polilinea(puntos, g=G, trazos=False):
    d = ' stroke-dasharray="8 6"' if trazos else ''
    return f'<path d="M' + " L".join(f"{x},{y}" for x, y in puntos) + f'" stroke="{TINTA}" stroke-width="{g}" fill="none" stroke-linejoin="round"{d}/>'


def triangulo(cx, cy, tam, hacia, relleno=TINTA):
    """Triángulo lleno con la punta hacia (dx, dy)."""
    dx, dy = hacia
    px, py = -dy, dx
    a = (cx + dx * tam, cy + dy * tam)
    b = (cx - dx * tam * 0.2 + px * tam * 0.7, cy - dy * tam * 0.2 + py * tam * 0.7)
    c = (cx - dx * tam * 0.2 - px * tam * 0.7, cy - dy * tam * 0.2 - py * tam * 0.7)
    return f'<polygon points="{a[0]:.1f},{a[1]:.1f} {b[0]:.1f},{b[1]:.1f} {c[0]:.1f},{c[1]:.1f}" fill="{relleno}" stroke="{TINTA}" stroke-width="1"/>'


def muelle(x1, y1, x2, y2, n=6, ancho=10):
    dx, dy = x2 - x1, y2 - y1
    largo = math.hypot(dx, dy)
    ux, uy = dx / largo, dy / largo
    px, py = -uy, ux
    puntos = [(x1, y1)]
    for i in range(1, 2 * n):
        t = i / (2 * n)
        lado = ancho if i % 2 else -ancho
        puntos.append((x1 + dx * t + px * lado, y1 + dy * t + py * lado))
    puntos.append((x2, y2))
    return polilinea([(round(x, 1), round(y, 1)) for x, y in puntos], 2.2)


def flecha_ajuste(cx, cy, r):
    """Flecha diagonal de «ajustable»."""
    return linea(cx - r, cy + r, cx + r, cy - r, 2.2) + triangulo(cx + r, cy - r, 9, (0.707, -0.707))


def bomba_sim(cx, cy, r=34, variable=False, motor=False, eje=True):
    s = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    if motor:
        s += triangulo(cx, cy - r + 2, 12, (0, 1))
    else:
        s += triangulo(cx, cy - r + 13, 12, (0, -1))
    if variable:
        s += flecha_ajuste(cx, cy, r * 0.9)
    if eje:
        s += linea(cx - r - 26, cy - 4, cx - r, cy - 4, 2) + linea(cx - r - 26, cy + 4, cx - r, cy + 4, 2)
    return s


def cilindro_sim(x, y, w=150, h=46, simple=False, vastago=50):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    xp = x + w * 0.35
    s += linea(xp, y, xp, y + h) + linea(xp, y + h / 2, x + w + vastago, y + h / 2, 4)
    if simple:
        s += muelle(xp + 6, y + h / 2 - 12, x + w - 6, y + h / 2 - 12, 5, 6)
    return s


def valvula_presion(cx, cy, normalmente_abierta=False, piloto_desde="entrada"):
    """Caja con la flecha de paso, muelle ajustable y piloto de trazos (alivio o reductora)."""
    a = 40
    s = f'<rect x="{cx - a}" y="{cy - a}" width="{2 * a}" height="{2 * a}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    dx = 0 if normalmente_abierta else -12
    s += linea(cx + dx, cy + a - 8, cx + dx, cy - a + 18, 2.4) + triangulo(cx + dx, cy - a + 14, 10, (0, -1))
    s += muelle(cx + a, cy, cx + a + 44, cy, 4, 9) + linea(cx + a + 10, cy + 16, cx + a + 36, cy - 16, 2) + triangulo(cx + a + 36, cy - 16, 7, (0.63, -0.77))
    if piloto_desde == "entrada":
        s += polilinea([(cx, cy + a + 18), (cx - a - 18, cy + a + 18), (cx - a - 18, cy), (cx - a, cy)], 2, True)
    else:
        s += polilinea([(cx, cy - a - 18), (cx - a - 18, cy - a - 18), (cx - a - 18, cy), (cx - a, cy)], 2, True)
    return s


def estrangulador_sim(cx, cy, ajustable=True, largo=46):
    s = f'<path d="M{cx - 14},{cy - largo / 2} Q{cx - 2},{cy} {cx - 14},{cy + largo / 2}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    s += f'<path d="M{cx + 14},{cy - largo / 2} Q{cx + 2},{cy} {cx + 14},{cy + largo / 2}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    if ajustable:
        s += flecha_ajuste(cx, cy, 26)
    return s


def antirretorno_sim(cx, cy, r=12, hacia_arriba=True):
    """Bola contra el asiento en V: pasa en el sentido en que la bola se separa del asiento."""
    if hacia_arriba:
        return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
                + polilinea([(cx - r - 7, cy - r - 2), (cx, cy + r + 4), (cx + r + 7, cy - r - 2)]))
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
            + polilinea([(cx - r - 7, cy + r + 2), (cx, cy - r - 4), (cx + r + 7, cy + r + 2)]))


def acumulador_sim(cx, cy):
    return (f'<rect x="{cx - 24}" y="{cy - 46}" width="48" height="84" rx="24" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
            + linea(cx - 24, cy - 6, cx + 24, cy - 6) + triangulo(cx, cy - 30, 9, (0, 1)) + linea(cx, cy + 38, cx, cy + 60))


def tanque_sim(cx, cy, w=44, h=24):
    return polilinea([(cx - w / 2, cy - h), (cx - w / 2, cy), (cx + w / 2, cy), (cx + w / 2, cy - h)])


def direccional_sim(cx, cy, c=44, posicion=0):
    """4/3 de centro cerrado con dos solenoides y centrada por muelles. Bocas abajo P T, arriba A B."""
    s = ''
    x0 = cx - 1.5 * c
    for k in range(3):
        x = x0 + k * c
        s += f'<rect x="{x}" y="{cy - c / 2}" width="{c}" height="{c}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    a, b = 0.28 * c, 0.72 * c
    # Izquierda: P→A, B→T (flechas paralelas)
    x = x0
    s += linea(x + a, cy + c / 2, x + a, cy - c / 2 + 9, 2.2) + triangulo(x + a, cy - c / 2 + 7, 7, (0, -1))
    s += linea(x + b, cy - c / 2, x + b, cy + c / 2 - 9, 2.2) + triangulo(x + b, cy + c / 2 - 7, 7, (0, 1))
    # Centro cerrado: cuatro tapones en T
    x = x0 + c
    for xx in (x + a, x + b):
        s += linea(xx, cy - c / 2, xx, cy - c / 2 + 9, 2.2) + linea(xx - 6, cy - c / 2 + 9, xx + 6, cy - c / 2 + 9, 2.2)
        s += linea(xx, cy + c / 2, xx, cy + c / 2 - 9, 2.2) + linea(xx - 6, cy + c / 2 - 9, xx + 6, cy + c / 2 - 9, 2.2)
    # Derecha: P→B, A→T (cruzadas)
    x = x0 + 2 * c
    s += linea(x + a, cy + c / 2, x + b, cy - c / 2 + 9, 2.2) + triangulo(x + b - 2, cy - c / 2 + 8, 7, (0.45, -0.89))
    s += linea(x + b, cy + c / 2, x + a, cy - c / 2 + 9, 2.2) + triangulo(x + a + 2, cy - c / 2 + 8, 7, (-0.45, -0.89))
    # Solenoides y muelles
    for lado in (-1, 1):
        xs = x0 - 26 if lado < 0 else x0 + 3 * c
        s += f'<rect x="{xs}" y="{cy - 12}" width="26" height="24" fill="none" stroke="{TINTA}" stroke-width="2.4"/>'
        s += linea(xs + 4, cy + 10, xs + 22, cy - 10, 2)
        xm = xs - 30 if lado < 0 else xs + 26
        s += muelle(xm, cy, xm + 30, cy, 3, 7)
    return s


def filtro_sim(cx, cy):
    return (f'<path d="M{cx},{cy - 30} L{cx + 30},{cy} L{cx},{cy + 30} L{cx - 30},{cy} Z" fill="none" stroke="{TINTA}" stroke-width="{G}" stroke-linejoin="round"/>'
            + linea(cx - 30, cy, cx + 30, cy, 2, True))


def enfriador_sim(cx, cy):
    return (f'<path d="M{cx},{cy - 30} L{cx + 30},{cy} L{cx},{cy + 30} L{cx - 30},{cy} Z" fill="none" stroke="{TINTA}" stroke-width="{G}" stroke-linejoin="round"/>'
            + linea(cx - 30, cy, cx + 30, cy, 2) + triangulo(cx - 10, cy - 12, 7, (0, -1)) + triangulo(cx + 10, cy - 12, 7, (0, -1)))


def manometro_sim(cx, cy, r=20):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
            + linea(cx - r * 0.6, cy + r * 0.6, cx + r * 0.55, cy - r * 0.55, 2) + triangulo(cx + r * 0.6, cy - r * 0.6, 7, (0.707, -0.707)))


def motor_electrico_sim(cx, cy, r=26):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'


def antirretorno_pilotada_sim(cx, cy):
    s = antirretorno_sim(cx, cy, 12, True)
    s += f'<rect x="{cx - 34}" y="{cy - 34}" width="68" height="62" fill="none" stroke="{TINTA}" stroke-width="1.6" stroke-dasharray="5 4"/>'
    s += polilinea([(cx + 52, cy + 6), (cx + 20, cy + 6), (cx + 4, cy - 4)], 2, True)
    return s


SIMBOLOS = {
    # id: (dibujo, etiquetas)
    "bomba_fija": (lambda: bomba_sim(130, 100) + linea(130, 66, 130, 22) + linea(130, 134, 130, 178), []),
    "bomba_variable": (lambda: bomba_sim(130, 100, variable=True) + linea(130, 66, 130, 22) + linea(130, 134, 130, 178), []),
    "motor_hidraulico": (lambda: bomba_sim(130, 100, motor=True) + linea(130, 66, 130, 22) + linea(130, 134, 130, 178), []),
    "motor_electrico": (lambda: motor_electrico_sim(120, 100, 34), [{"texto": "M", "x": 120, "y": 100, "tam": 30}]),
    "cilindro_doble": (lambda: cilindro_sim(30, 70) + linea(52, 116, 52, 160) + linea(162, 116, 162, 160), []),
    "cilindro_simple": (lambda: cilindro_sim(30, 70, simple=True) + linea(52, 116, 52, 160), []),
    "valvula_alivio": (lambda: valvula_presion(110, 100) + linea(110, 140, 110, 182) + linea(110, 60, 110, 20), []),
    "valvula_reductora": (lambda: valvula_presion(110, 100, True, "salida") + linea(110, 140, 110, 182) + linea(110, 60, 110, 20), []),
    "estranguladora": (lambda: estrangulador_sim(120, 100) + linea(120, 20, 120, 77) + linea(120, 123, 120, 180), []),
    "estranguladora_antirretorno": (lambda: estrangulador_sim(90, 100) + linea(90, 20, 90, 77) + linea(90, 123, 90, 180)
                                    + polilinea([(90, 44), (160, 44), (160, 86)]) + antirretorno_sim(160, 100, 11, False) + polilinea([(160, 114), (160, 156), (90, 156)])
                                    + f'<rect x="54" y="30" width="136" height="140" fill="none" stroke="{TINTA}" stroke-width="1.6" stroke-dasharray="5 4"/>', []),
    "antirretorno": (lambda: antirretorno_sim(120, 100) + linea(120, 20, 120, 86) + linea(120, 116, 120, 180), []),
    "antirretorno_pilotada": (lambda: antirretorno_pilotada_sim(110, 100) + linea(110, 20, 110, 66) + linea(110, 116, 110, 180), []),
    "direccional_43": (lambda: direccional_sim(120, 100, 40) + linea(80 + 11.2, 120, 80 + 11.2, 170) + linea(80 + 28.8, 120, 80 + 28.8, 170)
                       + linea(80 + 11.2, 80, 80 + 11.2, 30) + linea(80 + 28.8, 80, 80 + 28.8, 30), []),
    "acumulador": (lambda: acumulador_sim(120, 96), []),
    "filtro": (lambda: filtro_sim(120, 100) + linea(120, 20, 120, 70) + linea(120, 130, 120, 180), []),
    "enfriador": (lambda: enfriador_sim(120, 100) + linea(60, 100, 90, 100) + linea(150, 100, 180, 100), []),
    "tanque": (lambda: tanque_sim(120, 150, 90, 50) + linea(120, 40, 120, 136), []),
    "manometro": (lambda: manometro_sim(120, 90, 32) + linea(120, 122, 120, 178), []),
}


def simbolo_svg(id_):
    return svg(240, 200, SIMBOLOS[id_][0](), "")


# ----------------------------------------------------------------------------- esquemas de «Conexión»
def resalte(x, y, w, h):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="#ffc23a" fill-opacity="0.22" stroke="#d99614" stroke-width="2" stroke-dasharray="6 4"/>'


def base_bomba(cx=86, cy=218):
    """Tanque, motor eléctrico y bomba abajo a la izquierda; devuelve la salida de presión."""
    s = tanque_sim(cx, 282, 60, 20) + linea(cx, 264, cx, cy + 30)
    s += bomba_sim(cx, cy, 28, eje=False) + linea(cx - 28, cy, cx - 46, cy, 2) + motor_electrico_sim(cx - 60, cy, 14)
    return s, (cx, cy - 28)


ESQUEMAS = {}


def esquema_circuito(foco):
    """Circuito base: bomba, alivio, direccional 4/3 y actuador, con el componente del foco resaltado."""
    s, (px, py) = base_bomba()
    bornes, etiquetas = {}, []
    # Línea de presión hasta la direccional, alivio en derivación
    s += polilinea([(px, py), (px, 150), (232, 150), (232, 266), (255.4, 266), (255.4, 247)])
    # Alivio: entrada arriba desde la línea de presión, salida a tanque abajo
    s += linea(150, 150, 150, 178) + _alivio_pequeno(150, 200) + linea(150, 222, 150, 262) + tanque_sim(150, 282, 40, 16)
    # Manómetro
    s += linea(110, 150, 110, 128) + manometro_sim(110, 112, 14)
    # Direccional
    s += direccional_sim(262, 232, 30, 0)
    xa, xb = 262 - 15 + 8.4, 262 - 15 + 21.6
    s += tanque_sim(xb, 282, 22, 12) + linea(xb, 247, xb, 270)
    # Actuador según el foco
    if foco == "motor_hidraulico":
        s += polilinea([(xa, 217), (xa, 120), (318, 120), (318, 92)]) + polilinea([(xb, 217), (xb, 130), (352, 130), (352, 60), (318, 60), (318, 52)])
        s += bomba_sim(318, 72, 20, motor=True, eje=False) + linea(338, 68, 364, 68, 2) + linea(338, 76, 364, 76, 2)
        s += resalte(288, 40, 84, 64)
        bornes = {"A": [318, 98], "B": [318, 48], "L": [300, 92]}
        s += polilinea([(300, 86), (290, 96), (290, 104)], 2, True)
    else:
        s += cilindro_sim(254, 36, 90, 34, vastago=34)
        s += polilinea([(xa, 217), (xa, 110), (270, 110), (270, 70)]) + polilinea([(xb, 217), (xb, 120), (332, 120), (332, 70)])
        bornes = {"A": [270, 76], "B": [332, 76]}
        if foco == "cilindro_hidraulico":
            s += resalte(244, 26, 148, 54)
    if foco == "valvula_alivio":
        s += resalte(118, 168, 64, 64)
        bornes = {"P": [150, 172], "T": [150, 228]}
    if foco in ("bomba_engranajes", "bomba_pistones"):
        s += resalte(48, 182, 78, 72)
        bornes = {"S": [86, 252], "P": [86, 184]}
        if foco == "bomba_pistones":
            s += bomba_sim(86, 218, 28, variable=True, eje=False)
            s += polilinea([(110, 234), (124, 248), (124, 262)], 2, True)
            bornes["L"] = [110, 234]
    return s, bornes


def _alivio_pequeno(cx, cy, a=20):
    s = f'<rect x="{cx - a}" y="{cy - a}" width="{2 * a}" height="{2 * a}" fill="none" stroke="{TINTA}" stroke-width="2.6"/>'
    s += linea(cx - 6, cy + a - 4, cx - 6, cy - a + 9, 2) + triangulo(cx - 6, cy - a + 7, 6, (0, -1))
    s += muelle(cx + a, cy, cx + a + 24, cy, 3, 6) + linea(cx + a + 4, cy + 10, cx + a + 20, cy - 10, 1.6)
    s += polilinea([(cx, cy - a - 8), (cx - a - 10, cy - a - 8), (cx - a - 10, cy), (cx - a, cy)], 1.8, True)
    return s


def esquema_estranguladora():
    s, (px, py) = base_bomba()
    s += polilinea([(px, py), (px, 150), (232, 150), (232, 266), (255.4, 266), (255.4, 247)])
    s += linea(150, 150, 150, 178) + _alivio_pequeno(150, 200) + linea(150, 222, 150, 262) + tanque_sim(150, 282, 40, 16)
    s += direccional_sim(262, 232, 30, 0)
    xa, xb = 262 - 15 + 8.4, 262 - 15 + 21.6
    s += tanque_sim(xb, 282, 22, 12) + linea(xb, 247, xb, 270)
    s += cilindro_sim(240, 30, 90, 32, vastago=34)
    s += polilinea([(xa, 217), (xa, 110), (256, 110), (256, 62)])
    # Estranguladora con antirretorno en la línea B (meter-out)
    s += polilinea([(xb, 217), (xb, 186), (360, 186), (360, 150)])
    s += estrangulador_sim(360, 128, True, 34) + polilinea([(360, 106), (360, 90), (330, 90), (330, 62)])
    s += polilinea([(360, 96), (386, 96), (386, 120)]) + antirretorno_sim(386, 130, 8, False) + polilinea([(386, 140), (386, 164), (360, 164)])
    s += resalte(334, 84, 70, 98)
    return s, {"1": [330, 90], "2": [360, 176]}


def esquema_pilotada():
    s, (px, py) = base_bomba()
    s += polilinea([(px, py), (px, 150), (232, 150), (232, 266), (255.4, 266), (255.4, 247)])
    s += linea(150, 150, 150, 178) + _alivio_pequeno(150, 200) + linea(150, 222, 150, 262) + tanque_sim(150, 282, 40, 16)
    s += direccional_sim(262, 232, 30, 0)
    xa, xb = 262 - 15 + 8.4, 262 - 15 + 21.6
    s += tanque_sim(xb, 282, 22, 12) + linea(xb, 247, xb, 270)
    # Cilindro vertical colgando la carga: A abajo (sostiene), B arriba
    s += f'<rect x="330" y="20" width="40" height="110" fill="none" stroke="{TINTA}" stroke-width="{G}"/>' + linea(330, 92, 370, 92) + linea(350, 92, 350, 160, 4)
    s += f'<rect x="334" y="160" width="32" height="16" fill="{TINTA}"/>'
    s += polilinea([(xa, 217), (xa, 190), (300, 190), (300, 150)])
    s += antirretorno_sim(300, 128, 10, True) + f'<rect x="276" y="100" width="48" height="52" fill="none" stroke="{TINTA}" stroke-width="1.6" stroke-dasharray="5 4"/>'
    s += polilinea([(300, 116), (300, 84), (330, 84)])
    s += polilinea([(xb, 217), (xb, 200), (390, 200), (390, 36), (370, 36)])
    s += polilinea([(390, 160), (318, 160), (310, 136)], 2, True)
    s += resalte(268, 92, 64, 66)
    return s, {"V": [300, 150], "C": [300, 100], "X": [324, 160]}


def esquema_acumulador():
    s, (px, py) = base_bomba()
    s += polilinea([(px, py), (px, 150), (300, 150)])
    s += linea(150, 150, 150, 178) + _alivio_pequeno(150, 200) + linea(150, 222, 150, 262) + tanque_sim(150, 282, 40, 16)
    # Antirretorno tras la bomba, acumulador y su válvula de descarga a tanque
    s += linea(250, 150, 250, 118) + acumulador_sim(250, 70)
    s += polilinea([(250, 140), (210, 140), (210, 167)]) + estrangulador_sim(210, 190, False, 26) + linea(210, 203, 210, 262) + tanque_sim(210, 282, 28, 12)
    s += manometro_sim(290, 120, 13) + linea(290, 133, 290, 150)
    s += resalte(216, 14, 68, 122)
    return s, {"P": [250, 128], "N2": [250, 26]}


def esquema(id_):
    if id_ == "estranguladora":
        cuerpo, bornes = esquema_estranguladora()
    elif id_ == "antirretorno_pilotada":
        cuerpo, bornes = esquema_pilotada()
    elif id_ == "acumulador":
        cuerpo, bornes = esquema_acumulador()
    else:
        cuerpo, bornes = esquema_circuito(id_)
    ESQUEMAS[id_] = bornes
    return svg(400, 290, cuerpo, "")


# ----------------------------------------------------------------------------- escribir
def escribir(relativa, texto):
    ruta = os.path.join(REPO, relativa)
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    open(ruta, "w", encoding="utf-8", newline="\n").write(texto)
    imp = ruta + ".import"
    if not os.path.exists(imp):
        open(imp, "w", encoding="utf-8", newline="\n").write('[remap]\n\nimporter="keep"\n')


FUNCIONES = [bomba_engranajes, bomba_pistones, cilindro_hidraulico, motor_hidraulico, valvula_alivio, estranguladora, antirretorno_pilotada, acumulador]


def generar():
    for f in FUNCIONES:
        escribir(f"art/equipos/{f.__name__}.svg", f())
        escribir(f"art/esquemas/atlas_{f.__name__}.svg", esquema(f.__name__))
    for id_ in SIMBOLOS:
        escribir(f"art/simbolos/iso1219/{id_}.svg", simbolo_svg(id_))


if __name__ == "__main__":
    generar()
    import json
    print(json.dumps({"piezas": {k: {"bocas": v["bocas"], "marcas": v["marcas"]} for k, v in PIEZAS.items()}, "esquemas": ESQUEMAS}, ensure_ascii=False, indent=1))
