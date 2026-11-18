"""Selector MAN-OFF-AUT del Taller (220×260) sobre su SVG: caja moldeada con tornillos de la tapa,
aro cromado con las marcas de las tres posiciones, base negra cóncava, maneta de palanca con su
sombra, estrías de agarre e índice blanco, placa de leyenda (el juego escribe MAN OFF AUT encima) y
dos bloques de contacto NA (13-14 y 23-24) con indicador verde y bornes de jaula. Los bornes 33 y 34
del Taller (42,150 y 178,150) quedan libres a los lados de la leyenda."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tsl_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tsl_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tsl_cromo" x1="0.15" y1="0.1" x2="0.85" y2="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#d9dddf"/><stop offset="0.55" stop-color="#7e8488"/><stop offset="0.75" stop-color="#c9cdd0"/><stop offset="1" stop-color="#5d6366"/></linearGradient>
<radialGradient id="tsl_base" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3d4145"/><stop offset="0.7" stop-color="#1a1c1e"/><stop offset="0.92" stop-color="#0b0c0d"/><stop offset="1" stop-color="#2c2f32"/></radialGradient>
<linearGradient id="tsl_maneta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0f1112"/><stop offset="0.25" stop-color="#3c4044"/><stop offset="0.45" stop-color="#2a2d30"/><stop offset="1" stop-color="#0c0d0e"/></linearGradient>
'''


def tornillo_tapa(x, y):
    """Tornillo pequeño de la tapa, ranurado, en su avellanado."""
    return (f'<circle cx="{x}" cy="{y}" r="5" fill="#1b1d20"/><circle cx="{x}" cy="{y}" r="3.8" fill="url(#tsl_acero)"/>'
            f'<path d="M{x - 2.6},{y + 1.2} L{x + 2.6},{y - 1.2}" stroke="#30353a" stroke-width="1.2" stroke-linecap="round"/>')


def borne(x, y):
    """Borne de jaula: alojamiento hundido, jaula cincada, boca del cable abajo y tornillo pozidriv."""
    s = f'<rect x="{x - 17}" y="{y - 16}" width="34" height="34" rx="4" fill="#0c0d0f"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tsl_jaula)" d="M{x - 14.5},{y - 14} h29 v26 h-29 Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<rect x="{x - 9}" y="{y + 13}" width="18" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tsl_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
# Caja moldeada: canto de la tapa, línea de junta y tornillos de las esquinas
a('<rect x="9.5" y="9.5" width="201" height="241" rx="4" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="1.2"/>')
a('<rect x="10.5" y="10.5" width="201" height="241" rx="4" fill="none" stroke="#fff" stroke-opacity="0.1" stroke-width="1"/>')
a('<path d="M6,6.5 H214" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
for x, y in ((16, 16), (204, 16), (16, 246), (204, 246)):
    a(tornillo_tapa(x, y))
# Aro cromado con su sombra de contacto, estrías de torno y las marcas de MAN, OFF y AUT
a('<circle cx="112" cy="81" r="57" fill="none" stroke="#000" stroke-opacity="0.55" stroke-width="5" filter="url(#sombraCorta)"/>')
a('<circle cx="110" cy="78" r="57.5" fill="none" stroke="url(#tsl_cromo)" stroke-width="2.5"/>')
for r in range(49, 57, 2):
    a(f'<circle cx="110" cy="78" r="{r + 0.5}" fill="none" stroke="#fff" stroke-opacity="0.13" stroke-width="0.6"/>')
a('<path d="M66,58 A52,52 0 0 1 128,28" stroke="#fff" stroke-opacity="0.85" stroke-width="3" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<path d="M160,94 A52,52 0 0 1 114,130" stroke="#1d2124" stroke-opacity="0.5" stroke-width="3" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
for ang in (-135, -90, -45):
    t = math.radians(ang)
    p = [(110 + r * math.cos(t + k), 78 + r * math.sin(t + k)) for r, k in ((50.5, 0), (56.5, -0.05), (56.5, 0.05))]
    a('<polygon points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in p) + '" fill="#15181a"/>')
# Base negra cóncava de la maneta
a('<circle cx="110" cy="78" r="48" fill="url(#tsl_base)"/>')
a('<circle cx="110" cy="78" r="47" fill="none" stroke="#000" stroke-width="1.6"/>')
a('<path d="M150,96 A44,44 0 0 1 96,120" stroke="#fff" stroke-opacity="0.16" stroke-width="2" fill="none" stroke-linecap="round"/>')
# Maneta de palanca: sombra sobre la base, cuerpo con brillo, estrías de agarre e índice blanco
a('<rect x="104" y="40" width="20" height="88" rx="9" fill="#000" opacity="0.6" filter="url(#sombraCorta)"/>')
a('<g filter="url(#plastico)"><g filter="url(#biselFuerte)"><rect x="100" y="34" width="20" height="88" rx="9" fill="url(#tsl_maneta)"/></g></g>')
for y in range(70, 116, 5):
    a(f'<rect x="102" y="{y}" width="16" height="1.8" rx="0.9" fill="#060708"/><rect x="102" y="{y + 1.8}" width="16" height="0.8" fill="#fff" opacity="0.12"/>')
a('<path d="M103.5,44 V112" stroke="#fff" stroke-opacity="0.28" stroke-width="1.2" stroke-linecap="round"/>')
a('<rect x="106" y="40" width="8" height="22" rx="3" fill="#eef1f2"/><rect x="106" y="40" width="3" height="22" rx="1.5" fill="#fff"/>')
a('<rect x="106" y="58" width="8" height="4" rx="2" fill="#000" opacity="0.15"/>')
# Placa de leyenda rebajada bajo el aro
a('<g filter="url(#bisel)"><rect x="56" y="139" width="108" height="22" rx="3" fill="#1d2023"/></g>')
a('<rect x="57" y="140" width="106" height="1" fill="#000" opacity="0.6"/>')
# Bloques de contacto NA 13-14 y 23-24 con su indicador verde
for x0 in (20, 116):
    a(f'<rect x="{x0 + 0.5}" y="170.5" width="83" height="63" rx="4" fill="none" stroke="#000" stroke-opacity="0.55"/>')
    a(f'<rect x="{x0 + 1.5}" y="171.2" width="81" height="1" fill="#fff" opacity="0.18"/>')
    cx = x0 + 42
    a(f'<rect x="{cx - 6}" y="173" width="12" height="5" rx="1" fill="#050607"/><rect x="{cx - 4}" y="174.4" width="8" height="2" rx="0.8" fill="#2fa84d"/>')
for x in (42, 82, 138, 178):
    a(borne(x, 212))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "selector.svg"), "".join(d), P.DEFS + DEFS)
