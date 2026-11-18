"""Condensador trifásico de compensación en lata (300×380) sobre su SVG: lata de aluminio con vetas de
cepillado, reborde de la tapa y ranura de expansión (sistema de sobrepresión), aisladores de los bornes
con faldas, tornillos con arandela, resistencias de descarga con bandas de color, brillo del hilo de
cobre, adhesivo de peligro, brillo de la etiqueta y espárrago de fijación con tuerca bajo el fondo.
Los datos de la etiqueta y los nombres de bornes los pinta el juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="cd_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="cd_aislador" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2b2e31"/><stop offset="0.3" stop-color="#6c7276"/><stop offset="0.55" stop-color="#3a3e42"/><stop offset="1" stop-color="#1a1c1e"/></linearGradient>
<linearGradient id="cd_resist" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f3dcb4"/><stop offset="0.5" stop-color="#d4a86a"/><stop offset="1" stop-color="#8f6a36"/></linearGradient>
<linearGradient id="cd_lata" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.3"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.4" stop-color="#fff" stop-opacity="0"/><stop offset="0.85" stop-color="#000" stop-opacity="0.1"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="cd_esparrago" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5d6367"/><stop offset="0.4" stop-color="#e3e6e8"/><stop offset="1" stop-color="#4c5256"/></linearGradient>
'''


def tornillo(x, y, r):
    return (f'<circle cx="{x}" cy="{y + 0.7}" r="{r + 3}" fill="#c3c8cb" stroke="#555b5f" stroke-width="0.8"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#cd_cabeza)" stroke="#2b3034" stroke-width="0.8"/>'
            f'<path d="M{x - r * 0.7},{y} H{x + r * 0.7} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
            f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')


d = []
a = d.append

# Espárrago de fijación M12 bajo el fondo, con arandela y tuerca
a('<rect x="144" y="350" width="12" height="28" fill="url(#cd_esparrago)"/>')
for y in range(354, 378, 3):
    a(f'<path d="M144,{y} L156,{y + 1.5}" stroke="#3a3f43" stroke-width="0.7"/>')
a('<rect x="132" y="358" width="36" height="4" rx="1" fill="url(#cd_esparrago)"/>')
a('<path d="M136,362 H164 L162,372 H138 Z" fill="url(#cd_esparrago)" stroke="#3a3f43" stroke-width="0.6"/>')

# Lata: volumen, vetas de cepillado fuera de la etiqueta
a('<rect x="60" y="80" width="180" height="270" rx="14" fill="url(#cd_lata)"/>')
for i in range(46):
    x = 63 + i * 3.8
    op = 0.06 + ((i * 37) % 11) / 100
    for y0, y1 in ((100, 158), (262, 338)):
        a(f'<path d="M{x:.1f},{y0} V{y1}" stroke="{"#fff" if i % 3 else "#000"}" stroke-width="0.8" opacity="{op:.2f}"/>')
# Ranura de expansión bajo la tapa (sistema de desconexión por sobrepresión) y reborde
a('<path d="M60,104 Q150,128 240,104" fill="none" stroke="#5b6267" stroke-width="3"/>')
a('<path d="M60,107 Q150,131 240,107" fill="none" stroke="#fff" stroke-width="1.4" opacity="0.6"/>')
a('<path d="M60,112 Q150,136 240,112" fill="none" stroke="#5b6267" stroke-width="1.6" opacity="0.7"/>')
a('<ellipse cx="150" cy="80" rx="86" ry="15.5" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.6"/>')
a('<ellipse cx="150" cy="82" rx="76" ry="12" fill="none" stroke="#7d8387" stroke-width="1.2" opacity="0.7"/>')

# Aisladores de los bornes con sus faldas y tornillos con arandela
for x, y0 in ((106, 36), (150, 30), (194, 36)):
    a(f'<rect x="{x - 10}" y="{y0}" width="20" height="{76 - y0}" rx="3" fill="url(#cd_aislador)"/>')
    for yy in range(y0 + 16, 74, 8):
        a(f'<rect x="{x - 12}" y="{yy}" width="24" height="4" rx="2" fill="url(#cd_aislador)" stroke="#111" stroke-width="0.5"/>')
    a(f'<ellipse cx="{x}" cy="76" rx="14" ry="3.5" fill="#000" opacity="0.35"/>')
    a(tornillo(x, y0, 6.6))

# Resistencias de descarga: brillo del hilo y cuerpos con bandas de color
a('<path d="M106,51 Q128,65 150,51 M150,51 Q172,65 194,51" fill="none" stroke="#f6c49a" stroke-width="0.9" opacity="0.8"/>')
for x in (120, 166):
    a(f'<rect x="{x}" y="53" width="14" height="10" rx="4" fill="url(#cd_resist)" stroke="#6e5226" stroke-width="0.6"/>')
    for k, c in enumerate(("#6b3f20", "#1d1d1d", "#d4a017", "#c9a227")):
        a(f'<rect x="{x + 2.5 + k * 2.6:.1f}" y="53.5" width="1.5" height="9" fill="{c}"/>')
    a(f'<rect x="{x + 1}" y="54.5" width="12" height="1.6" rx="0.8" fill="#fff" opacity="0.5"/>')

# Etiqueta: brillo y borde impreso
a('<rect x="80" y="160" width="140" height="100" rx="4" fill="url(#am_placa)" opacity="0.25"/>')
a('<rect x="85" y="165" width="130" height="90" rx="2" fill="none" stroke="#2f5d8a" stroke-width="1.2" opacity="0.7"/>')
# Adhesivo de peligro: condensador con tensión residual
a('<path d="M150,276 L163,298 H137 Z" fill="#f2c200" stroke="#1d1d1d" stroke-width="2" stroke-linejoin="round"/>')
a('<path d="M151,281 L146,289 H150 L148,295 L154,287 H150 Z" fill="#1d1d1d"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "condensadores.svg"), "".join(d), P.DEFS + DEFS)
