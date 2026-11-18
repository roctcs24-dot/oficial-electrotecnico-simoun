"""Placa de datos del alternador (480×300) sobre su SVG: chapa de aluminio anodizado cepillado con
reflejo, canto redondeado con brillo, marco y líneas de la tabla grabados (surco oscuro y canto claro),
remaches de cabeza redonda, rayas finas y algo de suciedad en las esquinas. El texto de la placa lo
pinta el juego (etiquetas de la ficha): aquí no se repite."""
import os
import random
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="pa_chapa" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e9ebe8"/><stop offset="0.32" stop-color="#cdd1ce"/><stop offset="0.5" stop-color="#eef0ed"/><stop offset="0.66" stop-color="#c3c8c5"/><stop offset="1" stop-color="#aab0ad"/></linearGradient>
<radialGradient id="pa_remache" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#c3c8cb"/><stop offset="1" stop-color="#5d6367"/></radialGradient>
<radialGradient id="pa_sucio" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3a3326" stop-opacity="0.22"/><stop offset="1" stop-color="#3a3326" stop-opacity="0"/></radialGradient>
'''

X, Y, W, H, RX = 10, 10, 460, 280, 12
d = []
a = d.append

# Chapa (cubre la del dibujo; marco, líneas y remaches se vuelven a trazar encima)
a(f'<rect x="{X}" y="{Y}" width="{W}" height="{H}" rx="{RX}" fill="url(#pa_chapa)"/>')
# Vetas del cepillado, agrupadas en pocos trazos (con cientos de elementos Chrome deja trozos sin pintar)
rv = random.Random(23)
grupos = {}
for i in range(140):
    y = Y + 4 + i * (H - 8) / 140
    x0 = X + 6 + rv.uniform(0, 140)
    x1 = X + W - 6 - rv.uniform(0, 140)
    clave = ("#ffffff" if rv.random() < 0.55 else "#5d6367", rv.choice((0.07, 0.12, 0.18)))
    grupos.setdefault(clave, []).append(f"M{x0:.1f},{y:.1f} H{x1:.1f}")
for (c, op), trazos in grupos.items():
    a(f'<path d="{" ".join(trazos)}" stroke="{c}" stroke-width="0.8" opacity="{op}"/>')
a(f'<path d="M{X + 140},{Y} H{X + 270} L{X + 170},{Y + H} H{X + 40} Z" fill="#fff" opacity="0.12"/>')
for cx, cy in ((X + 20, Y + 20), (X + W - 20, Y + 20), (X + 20, Y + H - 20), (X + W - 20, Y + H - 20)):
    a(f'<circle cx="{cx}" cy="{cy}" r="34" fill="url(#pa_sucio)"/>')
# Canto: brillo arriba a la izquierda y borde
a(f'<rect x="{X + 1.5}" y="{Y + 1.5}" width="{W - 3}" height="{H - 3}" rx="{RX - 1}" fill="none" stroke="#fff" stroke-width="1.8" opacity="0.65"/>')
a(f'<rect x="{X + 1}" y="{Y + 1}" width="{W - 2}" height="{H - 2}" rx="{RX - 1}" fill="none" stroke="#6a7073" stroke-width="2"/>')

# Marco y líneas de la tabla, grabados
a('<rect x="24" y="22" width="432" height="256" rx="6" fill="none" stroke="#5b6164" stroke-width="1.5"/>')
a('<rect x="25.4" y="23.4" width="432" height="256" rx="6" fill="none" stroke="#fff" stroke-width="0.8" opacity="0.7"/>')
for y in (60, 98, 134, 170, 206, 242):
    a(f'<path d="M24,{y} H456" stroke="#6d7376" stroke-width="1.2"/><path d="M24,{y + 1.3} H456" stroke="#fff" stroke-width="0.7" opacity="0.75"/>')

# Rayas finas de uso
rnd = random.Random(8)
rayas = []
for _ in range(12):
    x0, y0 = rnd.uniform(40, 440), rnd.uniform(30, 270)
    l, ang = rnd.uniform(10, 36), rnd.uniform(-0.4, 0.4)
    rayas.append(f"M{x0:.1f},{y0:.1f} l{l:.1f},{l * ang:.1f}")
a(f'<path d="{" ".join(rayas)}" stroke="#fff" stroke-width="0.6" opacity="0.4"/>')

# Remaches
for cx, cy in ((30, 30), (450, 30), (30, 270), (450, 270)):
    a(f'<circle cx="{cx}" cy="{cy}" r="9" fill="#7d8387" opacity="0.5"/>')
    a(f'<circle cx="{cx + 0.8}" cy="{cy + 1.2}" r="7.2" fill="#000" opacity="0.4"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="7" fill="url(#pa_remache)"/>')
    a(f'<ellipse cx="{cx - 2.2}" cy="{cy - 2.6}" rx="2.6" ry="1.6" fill="#fff" opacity="0.8"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "placa_alternador.svg"), "".join(d), P.DEFS + DEFS)
