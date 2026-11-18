"""Transformador de intensidad toroidal (300×320) sobre su SVG: volumen del toroide de resina con brillo
y sombra interior en la ventana, junta de moldeo, pletina de cobre con taladros, pernos y arandelas en
las uniones, reflejo del cobre, placa remachada, caja de bornes secundarios con tapa, tornillos de los
bornes S1 y S2 y los cables del secundario con puntera y marcador. Rótulos y bornes, del juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="ti_toro" cx="150" cy="130" r="96" gradientUnits="userSpaceOnUse">
 <stop offset="0.48" stop-color="#000" stop-opacity="0.55"/><stop offset="0.56" stop-color="#000" stop-opacity="0.1"/>
 <stop offset="0.72" stop-color="#fff" stop-opacity="0.12"/><stop offset="0.86" stop-color="#fff" stop-opacity="0"/>
 <stop offset="1" stop-color="#000" stop-opacity="0.5"/></radialGradient>
<linearGradient id="ti_luz" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></linearGradient>
<radialGradient id="ti_ventana" cx="150" cy="130" r="46" gradientUnits="userSpaceOnUse">
 <stop offset="0.75" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></radialGradient>
<radialGradient id="ti_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
'''


def tornillo(x, y, r):
    return (f'<circle cx="{x}" cy="{y + 0.7}" r="{r + 2.2}" fill="#0b0d0f" opacity="0.6"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#ti_cabeza)" stroke="#2b3034" stroke-width="0.8"/>'
            f'<path d="M{x - r * 0.7},{y} H{x + r * 0.7} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
            f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')


def toro(cx, cy, r1, r2):
    return (f'M{cx - r2},{cy} a{r2},{r2} 0 1 0 {2 * r2},0 a{r2},{r2} 0 1 0 {-2 * r2},0 Z '
            f'M{cx - r1},{cy} a{r1},{r1} 0 1 1 {2 * r1},0 a{r1},{r1} 0 1 1 {-2 * r1},0 Z')


d = []
a = d.append

# Pletina de cobre: reflejo, taladros y uniones atornilladas
for x0, x1 in ((0, 54), (246, 300)):
    a(f'<rect x="{x0}" y="121" width="{x1 - x0}" height="3" fill="#fff" opacity="0.35"/>')
a('<rect x="104" y="121" width="92" height="3" fill="#fff" opacity="0.35"/>')
for x in (36, 264):
    a(f'<circle cx="{x}" cy="130" r="9" fill="url(#am_acero)" stroke="#3b4043" stroke-width="0.6"/>')
    a(P.perno(x, 130, 6))
for x0, w in ((0, 56), (244, 56), (104, 92)):
    a(f'<rect x="{x0}" y="139" width="{w}" height="2.4" fill="#000" opacity="0.3"/>')
# Marcas rojas de polaridad P1 y P2 en los extremos (el filtro automático no dibuja líneas sueltas)
for x in (16, 284):
    a(f'<rect x="{x - 1.6}" y="108" width="3.2" height="44" rx="1" fill="#c0392b"/>')
    a(f'<rect x="{x - 1.6}" y="108" width="1" height="44" fill="#fff" opacity="0.35"/>')

# Toroide: volumen, brillo, junta de moldeo y sombra de la ventana
a(f'<path d="{toro(150, 130, 46, 96)}" fill="url(#ti_toro)" fill-rule="evenodd"/>')
a(f'<path d="{toro(150, 130, 46, 96)}" fill="url(#ti_luz)" fill-rule="evenodd"/>')
a('<path d="M80,64 A96,96 0 0 1 150,34" fill="none" stroke="#fff" stroke-width="2" opacity="0.35" stroke-linecap="round"/>')
a('<circle cx="150" cy="130" r="88" fill="none" stroke="#14171a" stroke-width="1" opacity="0.8"/>')
a('<circle cx="150" cy="130" r="87" fill="none" stroke="#fff" stroke-width="0.6" opacity="0.15"/>')
a('<circle cx="150" cy="130" r="46" fill="url(#ti_ventana)"/>')
a('<path d="M104,118 H196" stroke="#000" stroke-width="3" opacity="0.35"/>')
# Chaveta de sujeción a la pletina: tornillo de apriete arriba de la ventana
a('<rect x="143" y="84" width="14" height="10" rx="2" fill="#20252a"/>')
a(tornillo(150, 89, 3.2))

# Placa de datos remachada con brillo
a('<rect x="96" y="60" width="108" height="22" rx="3" fill="url(#am_placa)" opacity="0.55"/>')
for x in (101, 199):
    a(f'<circle cx="{x}" cy="71" r="1.8" fill="#6c7276"/>')

# Caja de bornes secundarios: tapa abatida, bisagra y tornillos
a('<rect x="98" y="222" width="104" height="3" rx="1.5" fill="#fff" opacity="0.15"/>')
a('<rect x="104" y="246" width="92" height="4" fill="#000" opacity="0.35"/>')
for x in (106, 194):
    a(tornillo(x, 230, 2.4))
a(tornillo(124, 268, 7.2) + tornillo(176, 268, 7.2))
# Cables del secundario con marcador blanco
for x in (124, 176):
    a(f'<path d="M{x + 1},280 V320" stroke="#000" stroke-width="6" opacity="0.35"/>')
    a(f'<path d="M{x},279 V320" stroke="#20242a" stroke-width="5"/>')
    a(f'<path d="M{x - 1.2},281 V320" stroke="#fff" stroke-width="1" opacity="0.3"/>')
    a(f'<rect x="{x - 3}" y="276" width="6" height="6" rx="1" fill="url(#am_acero)"/>')
    a(f'<rect x="{x - 4.5}" y="298" width="9" height="12" rx="1.5" fill="#f2f3f1" stroke="#8a9095" stroke-width="0.5"/>')
    a(f'<path d="M{x - 2.5},302 H{x + 2.5} M{x - 2.5},306 H{x + 1}" stroke="#20242a" stroke-width="0.9"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "transformador_intensidad.svg"), "".join(d), P.DEFS + DEFS)
