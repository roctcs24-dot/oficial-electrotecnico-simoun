"""Arrancador suave con pantalla (360×540) sobre su SVG: disipador de aletas a los lados, rejillas de
ventilación con fondo, bornes de potencia de caja con su tornillo y los cables de red entrando por
arriba con el cobre pelado, bornes de mando con tornillo y separadores, banda de color con brillo,
pantalla con sombra interior, retroiluminación y reflejo del cristal, teclas con relieve, tornillos
de la carcasa y adhesivo de peligro. Las etiquetas de bornes y de la pantalla las pinta el juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="as_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="as_aleta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5d6367"/><stop offset="0.45" stop-color="#e2e5e7"/><stop offset="1" stop-color="#555b5f"/></linearGradient>
<linearGradient id="as_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.2"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.04"/><stop offset="0.51" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<radialGradient id="as_luz" cx="0.5" cy="0.5" r="0.7"><stop offset="0" stop-color="#2f8f63" stop-opacity="0.5"/><stop offset="1" stop-color="#2f8f63" stop-opacity="0"/></radialGradient>
<linearGradient id="as_brillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.18"/></linearGradient>
<linearGradient id="as_cobre" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a3f14"/><stop offset="0.4" stop-color="#f0b07c"/><stop offset="1" stop-color="#7a3f14"/></linearGradient>
<linearGradient id="as_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.5"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
<linearGradient id="as_jaula" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a7074"/><stop offset="0.5" stop-color="#e3e6e8"/><stop offset="1" stop-color="#7d8387"/></linearGradient>
'''


def tornillo(x, y, r, cruz=True):
    s = (f'<circle cx="{x}" cy="{y + 0.8}" r="{r + 2.4}" fill="#0b0d0f" opacity="0.75"/>'
         f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#as_cabeza)" stroke="#2b3034" stroke-width="0.8"/>'
         f'<path d="M{x - r * 0.72},{y} H{x + r * 0.72}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>')
    if cruz:
        s += f'<path d="M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
    s += (f'<path d="M{x - r * 0.72},{y + r * 0.17} H{x + r * 0.72}" stroke="#fff" stroke-width="0.6" opacity="0.45"/>'
          f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')
    return s


def ranuras(x0, x1, y, alto, paso=9):
    s = ""
    x = x0
    while x + 5 <= x1:
        s += f'<rect x="{x}" y="{y}" width="5" height="{alto}" rx="2.5" fill="#15181b"/>'
        s += f'<rect x="{x + 5}" y="{y + 1}" width="1" height="{alto - 2}" fill="#fff" opacity="0.55"/>'
        x += paso
    return s


d = []
a = d.append

# Disipador: aletas de aluminio extruido a los lados
for x0 in (1, 339):
    a(f'<rect x="{x0}" y="16" width="20" height="508" rx="3" fill="#3d4246"/>')
    for i in range(4):
        a(f'<rect x="{x0 + 1.5 + i * 4.6:.1f}" y="18" width="3" height="504" rx="1.2" fill="url(#as_aleta)"/>')

# Tornillos de fijación de la carcasa
for x, y in ((38, 18), (322, 18), (38, 522), (322, 522)):
    a(f'<circle cx="{x}" cy="{y}" r="6" fill="#4e5559"/><circle cx="{x}" cy="{y}" r="4.8" fill="url(#as_cabeza)"/>')
    a(f'<path d="M{x - 3},{y} H{x + 3} M{x},{y - 3} V{y + 3}" stroke="#30353a" stroke-width="1.3"/>')

# Rejillas de ventilación (sustituyen las rayas del dibujo)
a('<rect x="56" y="92" width="248" height="16" rx="3" fill="#a3a8aa"/>')
a(ranuras(60, 300, 94, 12))
a('<rect x="56" y="440" width="248" height="16" rx="3" fill="#a3a8aa"/>')
a(ranuras(60, 300, 442, 12))

# Cables de red entrando por arriba a los bornes 1/L1, 3/L2 y 5/L3, con el cobre pelado
for x, color in ((110, "#6b3f20"), (180, "#1d1e20"), (250, "#7f8488")):
    a(f'<rect x="{x - 7.5}" y="0" width="17" height="32" fill="#000" opacity="0.35" filter="url(#sombraCorta)"/>')
    a(f'<rect x="{x - 8}" y="0" width="16" height="30" rx="2" fill="{color}"/>')
    a(f'<rect x="{x - 8}" y="0" width="16" height="30" rx="2" fill="url(#as_cable)"/>')
    a(f'<rect x="{x - 6}" y="29" width="12" height="9" fill="url(#as_cobre)"/>')
    for k in range(4):
        a(f'<path d="M{x - 5 + k * 3.3:.1f},29 V38" stroke="#6b3510" stroke-width="0.6" opacity="0.7"/>')

# Bornes de potencia: caja de apriete con mordaza y tornillo grande
for y in (50, 490):
    for x in (110, 180, 250):
        a(f'<rect x="{x - 18}" y="{y - 14}" width="36" height="28" rx="3" fill="url(#as_jaula)" opacity="0.55"/>')
        a(f'<rect x="{x - 18}" y="{y - 14}" width="36" height="5" fill="#2b2f32" opacity="0.6"/>')
        a(f'<rect x="{x - 18}" y="{y + 9}" width="36" height="5" fill="#2b2f32" opacity="0.6"/>')
        a(tornillo(x, y, 10))
    for x in (145, 215):
        a(f'<rect x="{x - 2}" y="{y - 24}" width="4" height="48" rx="1.5" fill="#545b60"/><rect x="{x - 2}" y="{y - 24}" width="1.2" height="48" fill="#fff" opacity="0.3"/>')

# Bornes de mando: tornillo y boca de la jaula, separadores entre ellos
for y, xs in ((131, (70, 130, 230, 290)), (411, (60, 120, 200, 260, 320))):
    for x in xs:
        a(f'<rect x="{x + 9}" y="{y - 9}" width="6" height="18" rx="1" fill="#050607"/>')
        a(f'<rect x="{x + 10}" y="{y - 8}" width="2.4" height="16" fill="url(#as_jaula)" opacity="0.45"/>')
        a(tornillo(x, y, 7.4))
        for dx in (-20, 20):
            if (y == 131 and 44 < x + dx < 316) or (y == 411 and 34 < x + dx < 326):
                a(f'<rect x="{x + dx - 1.2}" y="{y - 15}" width="2.4" height="30" rx="1" fill="#575e63"/>')

# Frente: canto con brillo arriba y sombra abajo
a('<rect x="46" y="161" width="268" height="2" rx="1" fill="#fff" opacity="0.22"/>')
a('<rect x="46" y="370" width="268" height="2.5" rx="1" fill="#000" opacity="0.4"/>')
# Banda de color con su brillo
a('<rect x="62" y="176" width="236" height="56" rx="4" fill="url(#as_brillo)"/>')
a('<rect x="62" y="176" width="236" height="56" rx="4" fill="none" stroke="#005a63" stroke-width="1"/>')
# Pantalla: sombra interior, retroiluminación, reflejo del cristal
a('<rect x="70" y="244" width="220" height="70" rx="4" fill="url(#as_luz)"/>')
a('<rect x="72" y="246" width="216" height="7" fill="#000" opacity="0.4"/>')
a('<path d="M72,246 H288 V266 Q180,258 72,300 Z" fill="url(#as_cristal)"/>')
a('<rect x="66" y="240" width="228" height="78" rx="6" fill="none" stroke="#596267" stroke-width="1.2"/>')
# Teclas con relieve y la rueda central con su aro
for x in (76, 124, 196, 244):
    a(f'<rect x="{x + 3}" y="328" width="34" height="6" rx="3" fill="#fff" opacity="0.14"/>')
    a(f'<rect x="{x}" y="355" width="40" height="1.8" rx="0.9" fill="#000" opacity="0.6"/>')
a('<circle cx="180" cy="341" r="16" fill="none" stroke="#1a1d20" stroke-width="2"/>')
a('<circle cx="180" cy="341" r="9" fill="none" stroke="#7d868b" stroke-width="1"/>')
a('<ellipse cx="175" cy="334" rx="6" ry="3" fill="#fff" opacity="0.3"/>')
# Adhesivo de peligro de tensión
a('<path d="M300,352 L310,369 H290 Z" fill="#f2c200" stroke="#1d1d1d" stroke-width="1.6" stroke-linejoin="round"/>')
a('<path d="M301,356 L297,362 H300 L298,367 L303,360 H300 Z" fill="#1d1d1d"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "arrancador_suave.svg"), "".join(d), P.DEFS + DEFS)
