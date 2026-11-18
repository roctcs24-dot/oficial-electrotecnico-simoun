"""PLC compacto de 24 V DC de la mesa del Taller (660×310) sobre su SVG: bornes de jaula con su
tornillo y la entrada del cable, tapas abatibles de humo sobre las regletas, ventanillas de los LED
(el juego enciende RUN, STOP, entradas y salidas encima), pantalla con cristal y matriz de puntos,
teclas de membrana con flechas, tapa del módulo de programa, rejilla de ventilación, separadores de
grupos en las regletas y pestaña del carril DIN."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tp_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<radialGradient id="tp_hueco" cx="0.5" cy="0.4" r="0.6"><stop offset="0.45" stop-color="#030304"/><stop offset="0.85" stop-color="#16191b"/><stop offset="1" stop-color="#2f3336"/></radialGradient>
<linearGradient id="tp_laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f3e0a2"/><stop offset="0.45" stop-color="#c2a04d"/><stop offset="1" stop-color="#6b5520"/></linearGradient>
<linearGradient id="tp_humo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fb0ba" stop-opacity="0.55"/><stop offset="0.5" stop-color="#5d6b73" stop-opacity="0.35"/><stop offset="1" stop-color="#2a3236" stop-opacity="0.6"/></linearGradient>
<linearGradient id="tp_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.42"/><stop offset="0.38" stop-color="#fff" stop-opacity="0.08"/><stop offset="0.39" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.12"/></linearGradient>
<linearGradient id="tp_tecla" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7a8085"/><stop offset="0.12" stop-color="#5f656a"/><stop offset="1" stop-color="#43484c"/></linearGradient>
<radialGradient id="tp_lente" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#5a6064"/><stop offset="0.6" stop-color="#22272a"/><stop offset="1" stop-color="#0b0d0e"/></radialGradient>
<pattern id="tp_puntos" width="3" height="3" patternUnits="userSpaceOnUse"><rect width="2.2" height="2.2" fill="#6f8a66" opacity="0.18"/></pattern>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    """Cabeza de tornillo combinado (ranura y Pozidriv) con su brillo."""
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.4}" fill="#111315"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tp_acero)"/></g>'
    l = r * 0.7
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f}" stroke="#25292c" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
    l2 = r * 0.42
    t += f'<path d="M{x + l2 * s:.1f},{y - l2 * c:.1f} L{x - l2 * s:.1f},{y + l2 * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    t += f'<path d="M{x - l * c:.1f},{y - l * s + 1:.1f} L{x + l * c:.1f},{y + l * s + 1:.1f}" stroke="#fff" stroke-opacity="0.35" stroke-width="0.7"/>'
    return t


def borne(x, y, arriba, i):
    """Borne de jaula: alojamiento, jaula de latón asomando, entrada del cable hacia fuera y tornillo."""
    s = f'<rect x="{x - 15}" y="{y - 14}" width="30" height="28" rx="3" fill="#1e2225"/>'
    s += f'<rect x="{x - 15}" y="{y - 14}" width="30" height="2" fill="#fff" opacity="0.12"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.5" fill="url(#tp_hueco)"/>'
    s += f'<g filter="url(#bisel)"><rect x="{x - 10}" y="{y - 8}" width="20" height="16" rx="2" fill="url(#tp_laton)"/></g>'
    ey = y - 14 if arriba else y + 9
    s += f'<rect x="{x - 7}" y="{ey}" width="14" height="5" rx="1.5" fill="#050606"/>'
    s += f'<rect x="{x - 5}" y="{ey + (3.4 if arriba else 0.4)}" width="10" height="1.1" fill="#c9a956" opacity="0.7"/>'
    s += tornillo(x, y, 7.8, -12 + (i * 37) % 30)
    return s


# Regletas superior e inferior: alojamientos más reales y separadores de grupos
for i, x in enumerate((36, 86, 136, 190, 244, 298, 352, 406, 460, 514, 568)):
    a(borne(x, 38, True, i))
for i, x in enumerate((56, 120, 184, 248, 312, 376, 440, 540, 600)):
    a(borne(x, 272, False, i + 3))
for x, y in ((111, 38), (163, 38), (88, 272), (490, 272)):
    a(f'<g filter="url(#bisel)"><rect x="{x - 2.5}" y="{y - 18}" width="5" height="36" rx="2" fill="#4c5358"/></g>')
# Posición libre de la regleta superior, tapada con un tapón ciego
a('<g filter="url(#bisel)"><rect x="596" y="24" width="40" height="28" rx="3" fill="#2a2f32"/></g>')
a('<rect x="604" y="35" width="24" height="6" rx="3" fill="#15181a"/>')
# Tapas abatibles de humo sobre las regletas, con su bisagra
for y0, y1 in ((56, 62), (248, 254)):
    a(f'<rect x="16" y="{y0}" width="628" height="{y1 - y0}" rx="2" fill="url(#tp_humo)"/>')
    a(f'<rect x="16" y="{y0}" width="628" height="1" fill="#fff" opacity="0.35"/>')
    for x in (60, 330, 600):
        a(f'<rect x="{x - 9}" y="{y0 - 1}" width="18" height="{y1 - y0 + 2}" rx="2" fill="#2b3135"/>')

# Ventanillas de los LED de entradas y salidas (el juego pinta el LED en el centro)
for i in range(8):
    x = 190 + 54 * i
    a(f'<circle cx="{x}" cy="96" r="8.5" fill="#7d8387"/><circle cx="{x}" cy="96" r="7" fill="url(#tp_lente)"/>')
    a(f'<ellipse cx="{x - 2}" cy="93.5" rx="3" ry="1.6" fill="#fff" opacity="0.35"/>')
for i in range(6):
    x = 120 + 64 * i
    a(f'<circle cx="{x}" cy="214" r="8.5" fill="#7d8387"/><circle cx="{x}" cy="214" r="7" fill="url(#tp_lente)"/>')
    a(f'<ellipse cx="{x - 2}" cy="211.5" rx="3" ry="1.6" fill="#fff" opacity="0.35"/>')

# Ventana de estado RUN / STOP con sus lentes
a('<rect x="30" y="118" width="96" height="70" rx="6" fill="none" stroke="#7d8387" stroke-width="1.5"/>')
a('<rect x="34" y="122" width="88" height="4" rx="2" fill="#000" opacity="0.4"/>')
for y, t in ((140, "RUN"), (166, "STOP")):
    a(f'<circle cx="78" cy="{y}" r="9" fill="#5c6266"/><circle cx="78" cy="{y}" r="7.4" fill="url(#tp_lente)"/>')
    a(f'<ellipse cx="76" cy="{y - 3}" rx="3" ry="1.6" fill="#fff" opacity="0.35"/>')
    a(f'<text x="94" y="{y + 3}" style="font:600 8px Plex;fill:#b9c0c4;letter-spacing:.04em">{t}</text>')

# Pantalla: marco hundido, matriz de puntos y cristal con reflejo
a('<rect x="158" y="116" width="194" height="80" rx="4" fill="#15181a"/>')
a('<rect x="162" y="120" width="186" height="72" rx="3" fill="url(#lcd)"/>')
a('<rect x="166" y="124" width="178" height="64" fill="url(#tp_puntos)"/>')
a('<rect x="162" y="120" width="186" height="5" fill="#000" opacity="0.18"/>')
a('<rect x="162" y="120" width="5" height="72" fill="#000" opacity="0.12"/>')
a('<rect x="162" y="120" width="186" height="72" rx="3" fill="url(#tp_cristal)"/>')
a('<path d="M150,108 H360" stroke="#fff" stroke-opacity="0.18" stroke-width="1.5"/>')

# Teclas de membrana con flechas grabadas
FLECHAS = {(410, 133): "M-6,3 L0,-4 L6,3", (460, 133): "M-3,-6 L4,0 L-3,6",
           (410, 175): "M-4,-6 L3,0 L-4,6", (460, 175): "M-6,-3 L0,4 L6,-3"}
FLECHAS[(410, 175)] = "M3,-6 L-4,0 L3,6"
for (x, y), f in FLECHAS.items():
    a(f'<g filter="url(#bisel)"><rect x="{x - 18}" y="{y - 13}" width="36" height="26" rx="4.5" fill="url(#tp_tecla)"/></g>')
    a(f'<path d="{f}" transform="translate({x},{y})" fill="none" stroke="#e6e9ea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>')
# Teclas de salir y de aceptar sobre la tecla alta (símbolos grabados)
a('<g filter="url(#bisel)"><rect x="503" y="121" width="48" height="31" rx="5" fill="url(#tp_tecla)"/><rect x="503" y="156" width="48" height="31" rx="5" fill="url(#tp_tecla)"/></g>')
a('<path d="M535,130 V137 H519 M524,132 L519,137 L524,142" fill="none" stroke="#e6e9ea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>')
a('<path d="M518,172 L524,178 L536,165" fill="none" stroke="#e6e9ea" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>')

# Rejilla de ventilación a la derecha del frente
for i in range(7):
    x = 586 + i * 8
    a(f'<rect x="{x}" y="116" width="4" height="78" rx="2" fill="#2a2e31"/>')
    a(f'<rect x="{x + 4}" y="117" width="1" height="76" fill="#fff" opacity="0.45"/>')

# Juntas del frente y pestaña del carril DIN
a('<path d="M10,66 H650 M10,244 H650" stroke="#81878a" stroke-width="1"/>')
a('<path d="M10,67 H650 M10,245 H650" stroke="#fff" stroke-opacity="0.45" stroke-width="0.8"/>')
a('<g filter="url(#bisel)"><rect x="306" y="293" width="48" height="10" rx="2" fill="#8a9093"/></g>')
a('<rect x="322" y="296" width="16" height="4" rx="2" fill="#2a2e31"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "plc.svg"), "".join(d), P.DEFS + DEFS)
