"""Transformador de mando de la mesa del Taller (300×260) sobre su SVG: chapas apiladas del núcleo,
espiras de cobre esmaltado con el papel aislante en los bordes, bridas de apriete con sus pernos,
regletas de baquelita de H1-H2 y X1-X2 con arandela y tornillo, salidas de los devanados con su
funda, placa con el símbolo del transformador y colisos de fijación. Sin tensiones escritas: el
mismo dibujo sirve para 380/110 V y 380/230 V."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tt_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="tt_baquelita" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a3424"/><stop offset="1" stop-color="#1f150e"/></linearGradient>
<linearGradient id="tt_brida" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a9094"/><stop offset="0.3" stop-color="#5b6165"/><stop offset="1" stop-color="#2c3033"/></linearGradient>
<linearGradient id="tt_bobina" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.25" stop-color="#000" stop-opacity="0"/><stop offset="0.42" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
<pattern id="tt_espiras" width="2.6" height="10" patternUnits="userSpaceOnUse"><rect width="1.2" height="10" fill="#5a2a0c" opacity="0.5"/><rect x="1.3" width="0.6" height="10" fill="#ffd2a8" opacity="0.35"/></pattern>
<pattern id="tt_chapas" width="10" height="2.4" patternUnits="userSpaceOnUse"><rect width="10" height="1" fill="#000" opacity="0.55"/><rect y="1.2" width="10" height="0.5" fill="#9aa4ab" opacity="0.25"/></pattern>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.3}" fill="#0c0d0e"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tt_acero)"/></g>'
    l = r * 0.6
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#2a2e31" stroke-width="{r * 0.24:.1f}" stroke-linecap="round"/>'
    return t


def perno(x, y, r):
    pts = " ".join(f"{x + r * math.cos(math.radians(60 * i)):.1f},{y + r * math.sin(math.radians(60 * i)):.1f}" for i in range(6))
    return f'<g filter="url(#bisel)"><polygon points="{pts}" fill="#9aa0a3"/></g><circle cx="{x}" cy="{y}" r="{r * 0.45:.1f}" fill="#5f6568"/>'


# Núcleo: chapas apiladas en el marco que rodea la bobina
a('<path d="M66,84 H234 V176 H66 Z M74,92 V168 H226 V92 Z" fill-rule="evenodd" fill="url(#tt_chapas)"/>')
a('<rect x="66" y="84" width="168" height="92" rx="3" fill="none" stroke="#5a6064" stroke-width="1"/>')
# Bobina: espiras de cobre esmaltado, curvatura y papel aislante arriba y abajo
a('<rect x="74" y="92" width="152" height="76" fill="url(#tt_espiras)"/>')
a('<rect x="74" y="92" width="152" height="76" fill="url(#tt_bobina)"/>')
for y in (92, 163):
    a(f'<rect x="74" y="{y}" width="152" height="5" fill="#d9c58f"/>')
    a(f'<rect x="74" y="{y}" width="152" height="5" fill="url(#tt_bobina)"/>')
# Bridas de apriete del núcleo con sus pernos
for y in (70, 176):
    a(f'<g filter="url(#bisel)"><rect x="56" y="{y}" width="188" height="14" rx="2" fill="url(#tt_brida)"/></g>')
    a(perno(64, y + 7, 4.4) + perno(236, y + 7, 4.4))
    a(f'<rect x="76" y="{y + 5}" width="148" height="4" rx="2" fill="#000" opacity="0.25"/>')

# Regletas de baquelita: H1-H2 arriba, X1-X2 abajo, con separador central
for y in (44, 216):
    for x in (70, 230):
        a(f'<rect x="{x - 22}" y="{y - 20}" width="44" height="40" rx="4" fill="url(#tt_baquelita)" stroke="#120c08" stroke-width="1"/>')
        a(f'<rect x="{x - 22}" y="{y - 20}" width="44" height="1.6" fill="#fff" opacity="0.15"/>')
        a(f'<g filter="url(#bisel)"><rect x="{x - 15}" y="{y - 14}" width="30" height="28" rx="2" fill="#b9bfc2"/></g>')
        a(tornillo(x, y, 11, (x * 7 + y) % 40 - 20))
# Salidas de los devanados con su funda hacia las regletas
for x0, y0, x1, y1 in ((96, 92, 76, 64), (204, 92, 224, 64), (96, 168, 76, 196), (204, 168, 224, 196)):
    dd = f"M{x0},{y0} C{x0},{(y0 + y1) / 2} {x1},{(y0 + y1) / 2} {x1},{y1}"
    a(f'<path d="{dd}" stroke="#111" stroke-width="5.5" fill="none" stroke-linecap="round"/>')
    a(f'<path d="{dd}" stroke="#e9e3cf" stroke-width="4" fill="none" stroke-linecap="round"/>')
    a(f'<path d="{dd}" stroke="#fff" stroke-opacity="0.6" stroke-width="1" fill="none" transform="translate(-0.8,0)"/>')

# Placa con el símbolo del transformador entre los bornes de abajo
a(P.placa(116, 200, 68, 34, []))
a('<circle cx="144" cy="217" r="8" fill="none" stroke="#2a3034" stroke-width="1.4"/><circle cx="156" cy="217" r="8" fill="none" stroke="#2a3034" stroke-width="1.4"/>')
# Colisos de fijación en los costados
for x in (22, 278):
    a(f'<rect x="{x - 5}" y="106" width="10" height="48" rx="5" fill="#0b0c0d"/>')
    a(f'<rect x="{x - 4}" y="150" width="8" height="2" rx="1" fill="#fff" opacity="0.2"/>')
a('<path d="M10,5 H290" stroke="#fff" stroke-opacity="0.28" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "transformador.svg"), "".join(d), P.DEFS + DEFS)
