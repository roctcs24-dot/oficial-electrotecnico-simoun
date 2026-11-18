"""Caja de bornes del motor conectada en estrella (480×400) sobre su SVG: caja de fundición con pernos
de la tapa y junta de goma, placa de bornes con sus tornillos y nervios aislantes, puentes de cobre
con brillo, terminales de ojo estañados bajo las tuercas, tuercas hexagonales de latón con sus caras,
espárragos roscados, cables de red con brillo y manguito, prensaestopas y toma de tierra. El dibujo
original pierde los cables (líneas verticales sueltas): aquí se dibujan. bornera_delta.py usa lo mismo."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="bm_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.5"/><stop offset="0.28" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
<linearGradient id="bm_estano" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7d8387"/><stop offset="0.4" stop-color="#f1f3f4"/><stop offset="1" stop-color="#6f7579"/></linearGradient>
<radialGradient id="bm_ojo" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.6" stop-color="#c8cdd0"/><stop offset="1" stop-color="#70767a"/></radialGradient>
<linearGradient id="bm_puenteH" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6c49a" stop-opacity="0.9"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#3a1a06" stop-opacity="0.45"/></linearGradient>
<linearGradient id="bm_puenteV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#f6c49a" stop-opacity="0.9"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#3a1a06" stop-opacity="0.45"/></linearGradient>
<radialGradient id="bm_laton" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff2c4"/><stop offset="0.45" stop-color="#d6a84c"/><stop offset="1" stop-color="#6f4e1a"/></radialGradient>
'''

COLUMNAS = (130, 240, 350)
COLORES = ("#6b3f20", "#17181a", "#85898c")


def tuerca(x, y):
    """Tuerca hexagonal de latón con las caras iluminadas de forma distinta y el espárrago roscado."""
    s = f'<circle cx="{x + 1.5}" cy="{y + 2.5}" r="21" fill="#000" opacity="0.45" filter="url(#sombraCorta)"/>'
    pts = [(x + 20 * math.cos(math.radians(-90 + 60 * i)), y + 20 * math.sin(math.radians(-90 + 60 * i))) for i in range(6)]
    s += '<polygon points="' + " ".join(f"{px:.1f},{py:.1f}" for px, py in pts) + '" fill="url(#bm_laton)" stroke="#4a3210" stroke-width="1.2"/>'
    luces = (0.35, 0.12, -0.15, -0.3, -0.1, 0.2)
    for i in range(6):
        p1, p2 = pts[i], pts[(i + 1) % 6]
        c = "#fff" if luces[i] > 0 else "#000"
        s += f'<polygon points="{x},{y} {p1[0]:.1f},{p1[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}" fill="{c}" opacity="{abs(luces[i]) * 0.6:.2f}"/>'
    s += f'<circle cx="{x}" cy="{y}" r="13" fill="url(#bm_laton)" stroke="#6f4e1a" stroke-width="0.8"/>'
    # Espárrago: punta roscada con sus hilos
    s += f'<circle cx="{x}" cy="{y}" r="8" fill="url(#bm_ojo)" stroke="#5e4a20" stroke-width="1"/>'
    for r in (6.2, 4.4, 2.6):
        s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#6e5a2a" stroke-width="0.6" opacity="0.7"/>'
    s += f'<ellipse cx="{x - 3}" cy="{y - 3.5}" rx="3" ry="1.6" fill="#fff" opacity="0.7"/>'
    return s


def terminal_ojo(x, y):
    """Terminal de ojo estañado bajo la tuerca, con su caña engastada hacia abajo."""
    s = f'<circle cx="{x}" cy="{y}" r="24" fill="url(#bm_ojo)" stroke="#4f5558" stroke-width="1"/>'
    s += f'<path d="M{x - 10},{y + 18} L{x - 9},{y + 40} H{x + 9} L{x + 10},{y + 18} Z" fill="url(#bm_estano)" stroke="#4f5558" stroke-width="0.8"/>'
    for dy in (26, 32):
        s += f'<path d="M{x - 9},{y + dy} H{x + 9}" stroke="#4f5558" stroke-width="1.2" opacity="0.7"/>'
    return s


def cable(x, color, y0, y1, ancho=16):
    s = f'<rect x="{x - ancho / 2 + 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="#000" opacity="0.45" filter="url(#sombraCorta)"/>'
    s += f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="{color}"/>'
    s += f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="url(#bm_cable)"/>'
    return s


def tierra_cable(x, y0, y1, ancho=10):
    s = cable(x, "#2f9e4a", y0, y1, ancho)
    yy = y0
    while yy < y1:
        s += f'<rect x="{x - ancho / 2}" y="{yy}" width="{ancho}" height="{min(8, y1 - yy)}" fill="#f2c200"/>'
        yy += 16
    s += f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="url(#bm_cable)"/>'
    return s


def prensaestopas(x, y, r):
    s = f'<rect x="{x - r - 6}" y="{y}" width="{2 * r + 12}" height="10" rx="2" fill="#2d3236" stroke="#111" stroke-width="0.8"/>'
    for i in range(1, 6):
        xx = x - r - 6 + i * (2 * r + 12) / 6
        s += f'<path d="M{xx:.1f},{y + 1} V{y + 9}" stroke="#4f565b" stroke-width="1.4"/>'
    s += f'<rect x="{x - r - 6}" y="{y}" width="{2 * r + 12}" height="2" fill="#fff" opacity="0.25"/>'
    s += f'<rect x="{x - r - 3}" y="{y - 6}" width="{2 * r + 6}" height="6" rx="1.5" fill="#3c4246"/>'
    return s


def detalles(delta):
    d = []
    a = d.append
    # Caja: pernos de la tapa en las esquinas y junta de goma
    a('<rect x="36" y="36" width="408" height="288" rx="8" fill="none" stroke="#0e1114" stroke-width="4"/>')
    a('<rect x="36" y="36" width="408" height="288" rx="8" fill="none" stroke="#fff" stroke-width="0.8" opacity="0.12" transform="translate(-1,-1.5)"/>')
    for x, y in ((24, 24), (456, 24), (24, 336), (456, 336), (240, 24)):
        a(f'<circle cx="{x}" cy="{y}" r="8" fill="#1a2a37" opacity="0.8"/>')
        a(P.perno(x, y, 6.5))
    # Placa de bornes: tornillos de fijación y nervios aislantes entre fases
    for x, y in ((62, 62), (418, 62), (62, 298)):
        a(f'<circle cx="{x}" cy="{y}" r="6" fill="#1b1d1f"/><circle cx="{x}" cy="{y}" r="4.6" fill="url(#am_acero)"/>')
        a(f'<path d="M{x - 2.8},{y} H{x + 2.8}" stroke="#2a2e31" stroke-width="1.4"/>')
    for x in (185, 295):
        y0 = 70 if delta else 136
        a(f'<rect x="{x - 4}" y="{y0}" width="8" height="{290 - y0}" rx="3" fill="#3e4245"/>')
        a(f'<rect x="{x - 4}" y="{y0}" width="2" height="{290 - y0}" fill="#fff" opacity="0.18"/>')
        a(f'<rect x="{x + 3}" y="{y0}" width="2" height="{290 - y0}" fill="#000" opacity="0.4"/>')
    # Cables de red desde los prensaestopas hasta el terminal de ojo
    for x, color in zip(COLUMNAS, COLORES):
        a(cable(x, color, 278, 400))
        a(f'<rect x="{x - 9}" y="272" width="18" height="16" rx="2" fill="#1d1f21"/>')
        a(f'<rect x="{x - 9}" y="272" width="18" height="16" rx="2" fill="url(#bm_cable)"/>')
    a(tierra_cable(412, 296, 400))
    for x in COLUMNAS:
        a(prensaestopas(x, 338, 8))
    a(prensaestopas(412, 338, 5))
    # Toma de tierra en la placa
    a(f'<rect x="402" y="262" width="20" height="40" rx="3" fill="url(#bm_estano)" stroke="#4f5558" stroke-width="0.8"/>')
    a(P.perno(412, 276, 6))
    a('<path d="M406,292 H418 M408,296 H416 M410,300 H414" stroke="#20242a" stroke-width="1.4"/>')
    # Brillo de los puentes de cobre
    if delta:
        for x in COLUMNAS:
            a(f'<rect x="{x - 12}" y="92" width="24" height="166" rx="5" fill="url(#bm_puenteV)"/>')
    else:
        a('<rect x="112" y="98" width="256" height="24" rx="5" fill="url(#bm_puenteH)"/>')
    # Terminales de ojo de los cables y tuercas encima de todo
    for x in COLUMNAS:
        a(terminal_ojo(x, 240))
    for y in (110, 240):
        for x in COLUMNAS:
            a(tuerca(x, y))
    return "".join(d)


ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "bornera_estrella.svg"), detalles(False), P.DEFS + DEFS)
