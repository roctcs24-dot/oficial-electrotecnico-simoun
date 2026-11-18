"""Horómetro de la mesa del Taller (220×200) sobre su SVG: marco cromado del visor con cristal y
reflejo, rodillos del contador con su curvatura (sin cifras: la lectura la da el juego), coma
decimal, indicador de marcha, tornillos de fijación del marco y bornes A1 y A2 con su arandela y
regleta de baquelita."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="th_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="th_cromo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fbfcfc"/><stop offset="0.3" stop-color="#9ea3a6"/><stop offset="0.55" stop-color="#eef0f0"/><stop offset="1" stop-color="#6c7276"/></linearGradient>
<linearGradient id="th_rodillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.65"/><stop offset="0.22" stop-color="#000" stop-opacity="0.08"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.12"/><stop offset="0.78" stop-color="#000" stop-opacity="0.08"/><stop offset="1" stop-color="#000" stop-opacity="0.7"/></linearGradient>
<linearGradient id="th_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.32" stop-color="#fff" stop-opacity="0.06"/><stop offset="0.33" stop-color="#fff" stop-opacity="0"/><stop offset="0.7" stop-color="#fff" stop-opacity="0"/><stop offset="0.71" stop-color="#fff" stop-opacity="0.07"/><stop offset="1" stop-color="#fff" stop-opacity="0.02"/></linearGradient>
<linearGradient id="th_baquelita" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3d40"/><stop offset="1" stop-color="#141516"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.3}" fill="#0c0d0e"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#th_acero)"/></g>'
    l, l2 = r * 0.6, r * 0.6
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l2 * s:.1f},{y - l2 * c:.1f} L{x - l2 * s:.1f},{y + l2 * c:.1f}" stroke="#2a2e31" stroke-width="{r * 0.24:.1f}" stroke-linecap="round"/>'
    return t


# Marco del visor: bisel cromado, rebaje interior y tornillos de fijación
a('<rect x="20" y="24" width="180" height="96" rx="6" fill="none" stroke="url(#th_cromo)" stroke-width="3.4"/>')
a('<rect x="24" y="28" width="172" height="88" rx="4" fill="none" stroke="#000" stroke-opacity="0.6" stroke-width="2"/>')
for x, y in ((12, 12), (208, 12), (12, 188), (208, 188)):
    a(tornillo(x, y, 4.6, 20 + x % 7 * 9))
# Ventana de los rodillos: sombra interior, rodillos curvos y coma decimal
a('<rect x="34" y="54" width="152" height="40" rx="3" fill="none" stroke="#2c3033" stroke-width="1.5"/>')
for x in (38, 59, 80, 101, 122, 143, 164):
    a(f'<rect x="{x}" y="58" width="17" height="32" rx="2" fill="url(#th_rodillo)"/>')
    a(f'<rect x="{x + 1}" y="59" width="15" height="1" fill="#fff" opacity="0.2"/>')
a('<circle cx="161.5" cy="86" r="1.6" fill="#f0f0ee"/>')
a('<rect x="34" y="54" width="152" height="7" fill="#000" opacity="0.35"/>')
# Indicador de marcha: rueda con sectores blancos y negros
a('<circle cx="176" cy="42" r="7" fill="#0b0c0d" stroke="#5c6266" stroke-width="1"/>')
for i in range(4):
    a0, a1 = math.radians(i * 90), math.radians(i * 90 + 45)
    a(f'<path d="M176,42 L{176 + 6 * math.cos(a0):.1f},{42 + 6 * math.sin(a0):.1f} A6,6 0 0 1 {176 + 6 * math.cos(a1):.1f},{42 + 6 * math.sin(a1):.1f} Z" fill="#e9ebea"/>')
# Reloj de arena impreso a la izquierda
a('<path d="M40,36 H50 L45,42 L50,48 H40 L45,42 Z" fill="none" stroke="#b9c0c4" stroke-width="1.2" stroke-linejoin="round"/>')
# Cristal del visor con su reflejo
a('<rect x="22" y="26" width="176" height="92" rx="5" fill="url(#th_cristal)"/>')
a('<path d="M28,30 H120" stroke="#fff" stroke-opacity="0.35" stroke-width="1.4" stroke-linecap="round"/>')

# Bornes traseros A1 y A2: regleta de baquelita, arandela y tornillo
a('<rect x="34" y="146" width="152" height="34" rx="4" fill="url(#th_baquelita)" stroke="#0a0b0c" stroke-width="1"/>')
a('<rect x="34" y="146" width="152" height="1.6" fill="#fff" opacity="0.15"/>')
a('<g filter="url(#bisel)"><rect x="107" y="144" width="6" height="38" rx="2" fill="#2e3134"/></g>')
for x, ang in ((60, 12), (160, -18)):
    a(f'<circle cx="{x}" cy="162" r="15" fill="#c9ced1" stroke="#4f5558" stroke-width="1"/>')
    a(f'<circle cx="{x}" cy="162" r="15" fill="url(#th_acero)" opacity="0.6"/>')
    a(tornillo(x, 162, 11, ang))
# Canto superior iluminado del cuerpo
a('<path d="M10,5 H210" stroke="#fff" stroke-opacity="0.28" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "horometro.svg"), "".join(d), P.DEFS + DEFS)
