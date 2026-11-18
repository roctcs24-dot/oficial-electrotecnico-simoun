"""Placa de datos del motor (560×340) sobre su SVG: chapa de acero inoxidable cepillado con reflejo,
canto biselado, líneas de la tabla grabadas (surco oscuro y canto claro), remaches de cabeza
redonda con su hundimiento, rayas finas de uso y algo de suciedad en las esquinas. El texto de la
placa lo pinta el juego (etiquetas de la ficha): aquí no se repite."""
import os
import random
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="pm_inox" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#eef0f1"/><stop offset="0.3" stop-color="#cfd3d5"/><stop offset="0.48" stop-color="#f4f6f6"/><stop offset="0.62" stop-color="#c4c9cc"/><stop offset="1" stop-color="#b3b9bc"/></linearGradient>
<radialGradient id="pm_remache" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#c3c8cb"/><stop offset="1" stop-color="#5d6367"/></radialGradient>
<radialGradient id="pm_sucio" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3a3326" stop-opacity="0.22"/><stop offset="1" stop-color="#3a3326" stop-opacity="0"/></radialGradient>
'''

X, Y, W, H, RX = 10, 10, 536, 316, 6
d = []
a = d.append

# Chapa cepillada (cubre la del dibujo y se vuelven a trazar las líneas encima)
a(f'<g filter="url(#cepillado)"><rect x="{X}" y="{Y}" width="{W}" height="{H}" rx="{RX}" fill="url(#pm_inox)"/></g>')
a(f'<rect x="{X + 1}" y="{Y + 1}" width="{W - 2}" height="{H - 2}" rx="{RX - 1}" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.7"/>')
a(f'<rect x="{X + 0.75}" y="{Y + 0.75}" width="{W - 1.5}" height="{H - 1.5}" rx="{RX - 0.5}" fill="none" stroke="#5c6265" stroke-width="1.5"/>')
# Vetas del cepillado: trazos horizontales finos, claros y oscuros
# (pocos elementos con muchos subtrazos: con cientos de elementos Chrome deja trozos sin pintar)
rv = random.Random(11)
grupos = {}
for i in range(150):
    y = Y + 3 + i * (H - 6) / 150
    x0 = X + 4 + rv.uniform(0, 160)
    x1 = X + W - 4 - rv.uniform(0, 160)
    clave = ("#ffffff" if rv.random() < 0.55 else "#5d6367", rv.choice((0.07, 0.12, 0.18)))
    grupos.setdefault(clave, []).append(f"M{x0:.1f},{y:.1f} H{x1:.1f}")
for (c, op), trazos in grupos.items():
    a(f'<path d="{" ".join(trazos)}" stroke="{c}" stroke-width="0.8" opacity="{op}"/>')
# Reflejo diagonal suave
a(f'<path d="M{X + 120},{Y} H{X + 260} L{X + 150},{Y + H} H{X + 10} Z" fill="#fff" opacity="0.12"/>')
# Suciedad en las esquinas
for cx, cy in ((X + 18, Y + 18), (X + W - 18, Y + 18), (X + 18, Y + H - 18), (X + W - 18, Y + H - 18)):
    a(f'<circle cx="{cx}" cy="{cy}" r="34" fill="url(#pm_sucio)"/>')

# Líneas de la tabla, grabadas
for y in (74, 122, 170, 218, 266):
    a(f'<path d="M44,{y} H512" stroke="#3f4447" stroke-width="1.5"/><path d="M44,{y + 1.4} H512" stroke="#fff" stroke-width="0.8" opacity="0.8"/>')
a('<path d="M278,74 V266" stroke="#3f4447" stroke-width="1.5"/><path d="M279.4,74 V266" stroke="#fff" stroke-width="0.8" opacity="0.8"/>')

# Rayas finas de uso
rnd = random.Random(4)
for _ in range(14):
    x0, y0 = rnd.uniform(30, 520), rnd.uniform(30, 310)
    l, ang = rnd.uniform(10, 40), rnd.uniform(-0.4, 0.4)
    a(f'<path d="M{x0:.1f},{y0:.1f} l{l:.1f},{l * ang:.1f}" stroke="#fff" stroke-width="0.6" opacity="{rnd.uniform(0.25, 0.5):.2f}"/>')

# Remaches de cabeza redonda con su hundimiento
for cx, cy in ((28, 28), (528, 28), (28, 308), (528, 308)):
    a(f'<circle cx="{cx}" cy="{cy}" r="9" fill="#7d8387" opacity="0.5"/>')
    a(f'<circle cx="{cx + 0.8}" cy="{cy + 1.2}" r="7.2" fill="#000" opacity="0.4"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="7" fill="url(#pm_remache)"/>')
    a(f'<ellipse cx="{cx - 2.2}" cy="{cy - 2.6}" rx="2.6" ry="1.6" fill="#fff" opacity="0.8"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "placa_motor.svg"), "".join(d), P.DEFS + DEFS)
