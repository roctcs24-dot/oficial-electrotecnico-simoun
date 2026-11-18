"""Bornes de paso sobre carril DIN (400×280) sobre su SVG: carril con ranuras y pestañas iluminadas,
topes finales con su tornillo, cuerpos de poliamida con nervios, pozo y tornillo de cada borne,
orificios de prueba, canal de puentes, marcador con brillo, y los cables del tablero (marrón, negro y
gris) y del campo entrando con su puntera. El dibujo original solo deja ver el primer color arriba
(líneas verticales sueltas): aquí se dibujan los tres."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="bo_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="bo_cuerpo" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.3"/><stop offset="0.12" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/><stop offset="0.85" stop-color="#000" stop-opacity="0.08"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="bo_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.5"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
'''


def tornillo(x, y, r):
    return (f'<rect x="{x - r - 4}" y="{y - r - 4}" width="{2 * r + 8}" height="{2 * r + 8}" rx="3" fill="#2a2e31"/>'
            f'<rect x="{x - r - 4}" y="{y - r - 4}" width="{2 * r + 8}" height="3" rx="1.5" fill="#000" opacity="0.5"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#bo_cabeza)" stroke="#2b3034" stroke-width="0.8"/>'
            f'<path d="M{x - r * 0.72},{y} H{x + r * 0.72} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
            f'<path d="M{x - r * 0.72},{y + r * 0.17} H{x + r * 0.72}" stroke="#fff" stroke-width="0.6" opacity="0.45"/>'
            f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')


def cable(x, y0, y1, color, ancho=8):
    return (f'<rect x="{x - ancho / 2 + 1.5}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>'
            f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="{color}"/>'
            f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" fill="url(#bo_cable)"/>')


def puntera(x, y, color, alto=9):
    s = (f'<rect x="{x - 6}" y="{y}" width="12" height="{alto}" rx="2" fill="{color}"/>'
         f'<rect x="{x - 6}" y="{y}" width="12" height="{alto}" rx="2" fill="url(#bo_cable)"/>')
    for k in range(3, alto - 1, 3):
        s += f'<path d="M{x - 6},{y + k} H{x + 6}" stroke="#000" stroke-width="0.5" opacity="0.4"/>'
    return s


d = []
a = d.append

# Carril DIN: pestañas iluminadas y ranuras en los huecos
for x0, x1 in ((40, 50), (152, 168), (232, 248), (350, 360)):
    a(f'<rect x="{x0}" y="112" width="{x1 - x0}" height="3" fill="#fff" opacity="0.55"/><rect x="{x0}" y="155" width="{x1 - x0}" height="3" fill="#000" opacity="0.3"/>')
    a(f'<rect x="{x0 + 2}" y="129" width="{x1 - x0 - 4}" height="12" rx="4" fill="#4a5054"/>')
    a(f'<rect x="{x0 + 2}" y="139" width="{x1 - x0 - 4}" height="1.4" fill="#fff" opacity="0.5"/>')
# Sombra de los bornes sobre el carril
for x in (152, 232, 312):
    a(f'<rect x="{x}" y="115" width="4" height="40" fill="#000" opacity="0.3"/>')

# Topes finales: nervios y tornillo de apriete al carril
for x0 in (50, 314):
    for i in range(4):
        a(f'<rect x="{x0 + 6 + i * 7}" y="28" width="3" height="70" rx="1.5" fill="#454b50"/>')
        a(f'<rect x="{x0 + 6 + i * 7}" y="172" width="3" height="70" rx="1.5" fill="#454b50"/>')
    a(tornillo(x0 + 18, 135, 6))

# Cuerpos de los bornes: volumen, nervios laterales, orificios de prueba y canal de puentes
for x0 in (88, 168, 248):
    xc = x0 + 32
    a(f'<rect x="{x0}" y="30" width="64" height="210" rx="6" fill="url(#bo_cuerpo)"/>')
    a(f'<rect x="{x0 + 3}" y="31" width="58" height="2" rx="1" fill="#fff" opacity="0.35"/>')
    for yy in (90, 104, 166, 180):
        a(f'<rect x="{x0 + 4}" y="{yy}" width="56" height="2" rx="1" fill="#6c7378"/><rect x="{x0 + 4}" y="{yy + 2}" width="56" height="1" fill="#fff" opacity="0.3"/>')
    for yy in (97, 173):
        a(f'<circle cx="{xc + 18}" cy="{yy}" r="3.2" fill="#121416"/><circle cx="{xc + 18}" cy="{yy + 0.8}" r="2" fill="#5d6468" opacity="0.6"/>')
        a(f'<rect x="{xc - 22}" y="{yy - 3}" width="22" height="6" rx="3" fill="#121416"/>')
    # Marcador con brillo
    a(f'<rect x="{x0 + 10}" y="118" width="44" height="12" rx="2" fill="#fff" opacity="0.35"/>')
    # Tornillos de los bornes (A arriba y B abajo)
    a(tornillo(xc, 60, 8.5))
    a(tornillo(xc, 210, 8.5))
    # Bocas de las jaulas
    a(f'<rect x="{xc - 9}" y="31" width="18" height="6" rx="1.5" fill="#050607"/>')
    a(f'<rect x="{xc - 9}" y="233" width="18" height="6" rx="1.5" fill="#050607"/>')

# Cables: arriba los del tablero (marrón, negro y gris); abajo los del campo (azul oscuro)
for x, color in ((120, "#6b3f20"), (200, "#1a1b1d"), (280, "#8a8f93")):
    a(cable(x, 0, 32, color))
    a(f'<rect x="{x - 7}" y="28" width="14" height="8" rx="2" fill="#e8eaeb"/><rect x="{x - 7}" y="28" width="14" height="8" rx="2" fill="url(#bo_cable)"/>')
    a(puntera(x, 35, "#c9cdd0", 15))
    a(cable(x, 240, 280, "#22262b"))
    a(puntera(x, 220, "#c9cdd0", 15))
    a(f'<rect x="{x - 7}" y="234" width="14" height="8" rx="2" fill="#e8eaeb"/><rect x="{x - 7}" y="234" width="14" height="8" rx="2" fill="url(#bo_cable)"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "bornera.svg"), "".join(d), P.DEFS + DEFS)
