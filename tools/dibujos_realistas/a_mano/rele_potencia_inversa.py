"""Relé de potencia inversa (300×400) sobre su SVG: caja de carril DIN con rejillas laterales,
pestaña de fijación, tapa transparente precintable con su reflejo y tornillos de precinto, escalas
finas y moleteado de los diales, LED con lente (solo ON encendido) y punteras de los cables en los
bornes. Sin cifras de ajuste: dependen del fabricante."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="rp_tapa" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.31" stop-color="#fff" stop-opacity="0"/><stop offset="0.75" stop-color="#fff" stop-opacity="0"/><stop offset="0.76" stop-color="#fff" stop-opacity="0.07"/><stop offset="1" stop-color="#fff" stop-opacity="0.02"/></linearGradient>
<radialGradient id="rp_verde" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#8dffa6" stop-opacity="0.75"/><stop offset="0.5" stop-color="#3fbf5a" stop-opacity="0.25"/><stop offset="1" stop-color="#3fbf5a" stop-opacity="0"/></radialGradient>
<linearGradient id="rp_clip" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a4f53"/><stop offset="1" stop-color="#1c1f22"/></linearGradient>
'''

d = []
a = d.append

# Cantos de la caja: luz arriba y a la izquierda, línea de unión de las dos mitades
a('<rect x="36.5" y="20.5" width="227" height="359" rx="10" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="1"/>')
a('<path d="M40,200 H58 M242,200 H260" stroke="#7c8184" stroke-width="1"/>')
# Rejillas de ventilación en los costados de la caja
for x in (42, 247):
    for y in range(104, 300, 9):
        a(f'<rect x="{x}" y="{y}" width="11" height="4" rx="2" fill="#4a4f53"/>')
        a(f'<rect x="{x}" y="{y + 4}" width="11" height="0.9" fill="#fff" opacity="0.5"/>')
# Pestaña de fijación al carril DIN
a('<rect x="132" y="372" width="36" height="12" rx="2" fill="url(#rp_clip)"/>')
a('<rect x="144" y="376" width="12" height="4" rx="1.5" fill="#0b0c0d"/>')

# Bornes: puntera del cable asomando por encima o por debajo del tornillo
for x in (78, 126, 174, 222):
    for y, dy in ((48, -1), (352, 1)):
        a(f'<rect x="{x - 3}" y="{y + dy * 9 - (3 if dy < 0 else 0)}" width="6" height="3" rx="0.8" fill="#c9ced1"/>')

# Diales: moleteado, escala fina entre las marcas y brillo
for cx in (106, 194):
    cy = 172
    a(f'<circle cx="{cx}" cy="{cy}" r="27.2" fill="none" stroke="#5f6568" stroke-width="2" stroke-dasharray="1.4 1.2"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="24.5" fill="none" stroke="#000" stroke-opacity="0.25" stroke-width="0.8"/>')
    for i in range(25):
        ang = math.radians(135 + i * 11.25)
        if i % 4 == 0:
            continue
        a(f'<path d="M{cx + 32.5 * math.cos(ang):.1f},{cy + 32.5 * math.sin(ang):.1f} L{cx + 34.5 * math.cos(ang):.1f},{cy + 34.5 * math.sin(ang):.1f}" stroke="#aeb3b0" stroke-width="0.9" stroke-linecap="round"/>')
    a(f'<ellipse cx="{cx - 8}" cy="{cy - 10}" rx="9" ry="4.5" fill="#fff" opacity="0.4" transform="rotate(-35 {cx - 8} {cy - 10})"/>')
# Punto blanco en el extremo del índice de cada dial
a('<circle cx="90.5" cy="160" r="2" fill="#f4f4ee"/><circle cx="206.5" cy="156" r="2" fill="#f4f4ee"/>')

# LED: ON encendido con halo; START y TRIP apagados
a('<circle cx="100" cy="262" r="16" fill="url(#rp_verde)"/>')
for x in (100, 150, 200):
    a(f'<circle cx="{x}" cy="262" r="9.4" fill="none" stroke="#14171a" stroke-width="2.2"/>')
    a(f'<ellipse cx="{x - 2.4}" cy="259" rx="3" ry="1.8" fill="#fff" opacity="0.7"/>')

# Tapa transparente precintable sobre el frente: canto, reflejo, bisagra y tornillos de precinto
a('<rect x="56" y="84" width="188" height="230" rx="7" fill="none" stroke="#c8d0d4" stroke-opacity="0.45" stroke-width="1.6"/>')
a('<rect x="58" y="86" width="184" height="226" rx="6" fill="url(#rp_tapa)"/>')
for x in (66, 234):
    a(f'<circle cx="{x}" cy="300" r="4" fill="url(#am_acero)" stroke="#14171a" stroke-width="0.8"/>')
    a(f'<path d="M{x - 2.4},300 H{x + 2.4}" stroke="#2c3033" stroke-width="1"/>')
    a(f'<circle cx="{x}" cy="300" r="1" fill="#14171a"/>')
# Precinto de alambre con su plomo en el tornillo derecho
a('<path d="M234,300 C238,306 244,306 246,302" fill="none" stroke="#9aa0a3" stroke-width="0.8"/>')
a('<circle cx="247" cy="302" r="2.6" fill="#6c7276"/>')
for x in (64, 236):
    a(f'<rect x="{x - 6}" y="84" width="12" height="4" rx="1.5" fill="#8a9094"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "rele_potencia_inversa.svg"), "".join(d), P.DEFS + DEFS)
