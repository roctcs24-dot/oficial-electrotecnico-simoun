"""Termostato de bulbo y capilar (300×380) sobre su SVG: cantos de la caja, ventana de escala con
sombra interior, subdivisiones, sombra del índice y cristal, perillas de RANGE y DIFF con moleteado,
brillo y flecha, tapa de bornes con sus tornillos y arandelas de los bornes, prensaestopas con caras
de la tuerca, brillo del capilar de cobre y bulbo con sus extremos y brillo."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ts_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.1" stop-color="#fff" stop-opacity="0"/><stop offset="0.9" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.28"/></linearGradient>
<linearGradient id="ts_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.32"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ts_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.4"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.04"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="ts_hex" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1b1d20"/><stop offset="0.3" stop-color="#4a4f53"/><stop offset="0.5" stop-color="#2a2d30"/><stop offset="0.75" stop-color="#3d4246"/><stop offset="1" stop-color="#151719"/></linearGradient>
<radialGradient id="ts_perilla" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></radialGradient>
'''

d = []
a = d.append
# Caja: cantos con luz y sombra
a('<rect x="50" y="20" width="200" height="230" rx="12" fill="url(#ts_lado)"/>')
# Ventana de escala: sombra interior, subdivisiones de 1 °C, sombra del índice y cristal
a('<rect x="65" y="35" width="170" height="10" fill="url(#ts_sombraV)"/>')
for i in range(36):
    x = 80 + i * 4
    if (x - 80) % 20:
        a(f'<path d="M{x},92 V{89 if (x - 80) % 10 else 87}" stroke="#20242a" stroke-width="0.9"/>')
a('<path d="M152.5,52 V106" stroke="#000" stroke-opacity="0.25" stroke-width="3" filter="url(#desenfoque)"/>')
a('<path d="M150,104 L150,50" stroke="#c0392b" stroke-width="3"/>')
a('<rect x="64" y="34" width="172" height="80" rx="6" fill="url(#ts_cristal)"/>')
a('<path d="M64,84 L104,34 H124 L76,114 H64 Z" fill="#fff" opacity="0.08"/>')
a('<path d="M68,36.5 H232" stroke="#fff" stroke-opacity="0.6" stroke-width="1"/>')
# Perillas de RANGE y DIFF: moleteado, brillo y flecha índice en el extremo de la ranura
for cx, ang in ((100, 270), (200, 0)):
    for i in range(32):
        g = math.radians(i * 11.25)
        a(f'<path d="M{cx + 17 * math.cos(g):.1f},{150 + 17 * math.sin(g):.1f} L{cx + 20 * math.cos(g):.1f},{150 + 20 * math.sin(g):.1f}" stroke="#7d8285" stroke-width="1"/>')
    a(f'<circle cx="{cx}" cy="150" r="20" fill="url(#ts_perilla)"/>')
    g = math.radians(ang)
    tx, ty = cx + 23.5 * math.cos(g), 150 + 23.5 * math.sin(g)
    a(f'<path d="M{tx + 4 * math.cos(g):.1f},{ty + 4 * math.sin(g):.1f} L{tx + 3 * math.cos(g + 2.1):.1f},{ty + 3 * math.sin(g + 2.1):.1f} L{tx + 3 * math.cos(g - 2.1):.1f},{ty + 3 * math.sin(g - 2.1):.1f} Z" fill="#20242a" transform="rotate(180 {tx:.1f} {ty:.1f})"/>')
# Tapa de bornes: canto, tornillos de la tapa y arandelas de los bornes
a('<path d="M68,187.5 H232" stroke="#fff" stroke-opacity="0.22" stroke-width="1"/>')
for x, y in ((74, 196), (226, 196), (74, 228), (226, 228)):
    a(f'<circle cx="{x}" cy="{y}" r="3.4" fill="url(#am_acero)"/><path d="M{x - 2},{y} H{x + 2}" stroke="#2a2e31" stroke-width="1"/>')
for x in (100, 150, 200):
    a(f'<circle cx="{x}" cy="212" r="12.6" fill="none" stroke="#9aa1a5" stroke-width="2.4"/>')
    a(f'<path d="M{x - 6},212 H{x + 6} M{x},206 V218" stroke="#2a2e31" stroke-width="2" stroke-linecap="round"/>')
# Prensaestopas: caras de la tuerca y canto
a('<rect x="134" y="250" width="32" height="20" rx="3" fill="url(#ts_hex)"/>')
a('<path d="M142,251 V269 M158,251 V269" stroke="#000" stroke-width="0.8"/>')
a('<rect x="134" y="250" width="32" height="4" fill="#000" opacity="0.35"/>')
# Capilar de cobre: brillo a lo largo y bulbo con extremos y brillo
a('<path d="M150,270 C 150,320 60,300 70,350" fill="none" stroke="#ffd2ad" stroke-opacity="0.55" stroke-width="1.4" transform="translate(-1.2,-0.6)"/>')
a('<g transform="rotate(-6 118 350)">'
  '<rect x="62" y="343" width="112" height="4" rx="2" fill="#ffe1c4" opacity="0.5"/>'
  '<rect x="60" y="341" width="5" height="18" rx="2" fill="#7a4320" opacity="0.6"/>'
  '<rect x="171" y="341" width="5" height="18" rx="2" fill="#7a4320" opacity="0.6"/>'
  '<path d="M66,357 H170" stroke="#5a2e12" stroke-opacity="0.35" stroke-width="1.5"/></g>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "termostato.svg"), "".join(d), P.DEFS + DEFS)
