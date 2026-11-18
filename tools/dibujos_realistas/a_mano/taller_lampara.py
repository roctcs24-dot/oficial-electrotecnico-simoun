"""Luz piloto del Taller (200×220) sobre su SVG: caja moldeada con tornillos de la tapa, aro cromado
torneado con sombra de contacto, lente verde facetada con los LED apagados al fondo y su reflejo,
portalámparas con el símbolo grabado y bornes de jaula X1 y X2. Encendida, el juego pinta la lente
(círculo de radio 40 en 100,66) encima: todo el detalle de la lente queda dentro de ese círculo."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tl_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tl_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tl_cromo" x1="0.15" y1="0.1" x2="0.85" y2="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#d9dddf"/><stop offset="0.55" stop-color="#7e8488"/><stop offset="0.75" stop-color="#c9cdd0"/><stop offset="1" stop-color="#5d6366"/></linearGradient>
<radialGradient id="tl_lente" cx="0.5" cy="0.55" r="0.5"><stop offset="0" stop-color="#3f8a52" stop-opacity="0.55"/><stop offset="0.55" stop-color="#1d4a2b" stop-opacity="0.25"/><stop offset="0.9" stop-color="#000" stop-opacity="0.35"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/></radialGradient>
<linearGradient id="tl_bloque" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3e42"/><stop offset="0.08" stop-color="#2c2f33"/><stop offset="1" stop-color="#1f2225"/></linearGradient>
'''


def tornillo_tapa(x, y):
    """Tornillo pequeño de la tapa, ranurado, en su avellanado."""
    return (f'<circle cx="{x}" cy="{y}" r="5" fill="#1b1d20"/><circle cx="{x}" cy="{y}" r="3.8" fill="url(#tl_acero)"/>'
            f'<path d="M{x - 2.6},{y + 1.2} L{x + 2.6},{y - 1.2}" stroke="#30353a" stroke-width="1.2" stroke-linecap="round"/>')


def borne(x, y):
    """Borne de jaula: alojamiento hundido, jaula cincada, boca del cable abajo y tornillo pozidriv."""
    s = f'<rect x="{x - 18}" y="{y - 17}" width="36" height="36" rx="4" fill="#0c0d0f"/>'
    s += f'<rect x="{x - 18}" y="{y + 15}" width="36" height="1.4" fill="#fff" opacity="0.12"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tl_jaula)" d="M{x - 15},{y - 14} h30 v26 h-30 Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<rect x="{x - 9}" y="{y + 13}" width="18" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tl_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
# Caja moldeada: canto de la tapa, línea de junta y tornillos de las esquinas
a('<rect x="9.5" y="9.5" width="181" height="201" rx="4" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="1.2"/>')
a('<rect x="10.5" y="10.5" width="181" height="201" rx="4" fill="none" stroke="#fff" stroke-opacity="0.1" stroke-width="1"/>')
a('<path d="M6,6.5 H194" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
for x, y in ((16, 16), (184, 16), (16, 204), (184, 204)):
    a(tornillo_tapa(x, y))
# Sombra de contacto y aro cromado torneado con su luz
a('<circle cx="102" cy="69" r="53" fill="none" stroke="#000" stroke-opacity="0.55" stroke-width="5" filter="url(#sombraCorta)"/>')
a('<circle cx="100" cy="66" r="51.5" fill="none" stroke="url(#tl_cromo)" stroke-width="2.5"/>')
for r in range(42, 51, 2):
    a(f'<circle cx="100" cy="66" r="{r + 0.5}" fill="none" stroke="#fff" stroke-opacity="0.13" stroke-width="0.6"/>')
a('<path d="M60,48 A46,46 0 0 1 116,21" stroke="#fff" stroke-opacity="0.85" stroke-width="3" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<path d="M144,80 A46,46 0 0 1 104,112" stroke="#1d2124" stroke-opacity="0.5" stroke-width="3" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<circle cx="100" cy="66" r="41" fill="none" stroke="#111315" stroke-width="2.4"/>')
a('<circle cx="100" cy="66" r="42.7" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="0.8"/>')
# Lente apagada: LED al fondo, anillos de Fresnel, profundidad y reflejo de la luz del techo
for i in range(19):
    if i == 0:
        x, y = 100, 66
    elif i < 7:
        ang = math.radians(60 * i)
        x, y = 100 + 11 * math.cos(ang), 66 + 11 * math.sin(ang)
    else:
        ang = math.radians(30 * (i - 7) + 15)
        x, y = 100 + 22 * math.cos(ang), 66 + 22 * math.sin(ang)
    a(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.4" fill="#0e2416"/><circle cx="{x:.1f}" cy="{y:.1f}" r="2.2" fill="#35603f"/>'
      f'<circle cx="{x - 0.8:.1f}" cy="{y - 0.9:.1f}" r="0.8" fill="#c9f2d1" opacity="0.6"/>')
for r in (8, 15, 22, 29, 35):
    a(f'<circle cx="100" cy="66" r="{r}" fill="none" stroke="#9be0ab" stroke-opacity="0.12" stroke-width="1"/>')
    a(f'<circle cx="100" cy="66.8" r="{r}" fill="none" stroke="#000" stroke-opacity="0.18" stroke-width="0.8"/>')
a('<circle cx="100" cy="66" r="40" fill="url(#tl_lente)"/>')
a('<path d="M68,52 A33,33 0 0 1 108,34" stroke="#d8ffe0" stroke-opacity="0.5" stroke-width="5" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<ellipse cx="80" cy="44" rx="10" ry="4" fill="#fff" opacity="0.55" transform="rotate(-35 80 44)" filter="url(#desenfoque)"/>')
a('<circle cx="124" cy="88" r="2.5" fill="#fff" opacity="0.35" filter="url(#desenfoque)"/>')
# Portalámparas con el símbolo de la lámpara grabado entre los bornes
a('<g filter="url(#plastico)"><g filter="url(#bisel)"><rect x="24" y="130" width="152" height="68" rx="5" fill="url(#tl_bloque)"/></g></g>')
a('<g stroke="#8d9397" stroke-width="1.3" fill="none"><circle cx="100" cy="178" r="7"/><path d="M95,173 L105,183 M105,173 L95,183 M86,178 H93 M107,178 H114"/></g>')
for x in (60, 140):
    a(borne(x, 176))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "lampara.svg"), "".join(d), P.DEFS + DEFS)
