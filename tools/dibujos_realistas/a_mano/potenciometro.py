"""Potenciómetro de panel visto por detrás y trimmer (400×220) sobre su SVG. Potenciómetro: tapa de
chapa con brillo circular, pestaña antigiro, cuatro uñas dobladas sobre la base de baquelita, sombra
interior del borde, pista de carbón con sus contactos plateados en los extremos, remaches de los
terminales, y terminales estañados con el doblez y el agujero de soldar. Trimmer: cuerpo de plástico
azul con su valor «103», rotor con ranura en cruz e índice, y patillas con su resalte."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="po_chapa" cx="0.5" cy="0.5" r="0.5">
 <stop offset="0.76" stop-color="#000" stop-opacity="0"/><stop offset="0.8" stop-color="#fff" stop-opacity="0.35"/>
 <stop offset="0.88" stop-color="#000" stop-opacity="0.08"/><stop offset="0.96" stop-color="#fff" stop-opacity="0.3"/>
 <stop offset="1" stop-color="#000" stop-opacity="0.35"/></radialGradient>
<linearGradient id="po_brillo" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.5"/><stop offset="0.35" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.65" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<radialGradient id="po_fondo" cx="0.5" cy="0.5" r="0.5">
 <stop offset="0.8" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/></radialGradient>
<linearGradient id="po_estano" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#000" stop-opacity="0.25"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.55"/>
 <stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="po_hilo" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.3" stop-color="#ffffff"/><stop offset="0.55" stop-color="#b8bec2"/><stop offset="1" stop-color="#6c7378"/></linearGradient>
<radialGradient id="po_rotor" cx="0.4" cy="0.35" r="0.7">
 <stop offset="0" stop-color="#fff" stop-opacity="0.6"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></radialGradient>
<linearGradient id="po_azul" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></linearGradient>
'''

d = []
a = d.append
# Sombra de apoyo bajo los terminales
a('<ellipse cx="200" cy="198" rx="46" ry="2.6" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>')
# Pestaña antigiro arriba de la tapa
a('<path d="M195,26 V19 Q195,17 197,17 H203 Q205,17 205,19 V26 Z" fill="#b9bec2" stroke="#5b6267" stroke-width="1"/>')
a('<path d="M196.5,25 V19.5" stroke="#fff" stroke-width="1" opacity="0.8"/>')
# Tapa de chapa: escalón circular y brillo
a('<circle cx="200" cy="88" r="64" fill="url(#po_chapa)"/>')
a('<circle cx="200" cy="88" r="63" fill="url(#po_brillo)"/>')
a('<path d="M152,56 A58,58 0 0 1 196,30" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.7" stroke-linecap="round"/>')
# Fondo de baquelita: sombra del borde, vetas finas
a('<circle cx="200" cy="88" r="50" fill="url(#po_fondo)"/>')
for r in (18, 30, 41):
    a(f'<circle cx="200" cy="88" r="{r}" fill="none" stroke="#fff" stroke-width="0.4" opacity="0.06"/>')
# Uñas de la tapa dobladas sobre la base
for ang in (15, 165, 225, 315):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    pts = []
    for rr, dt in ((53, -7), (44, -4.5), (44, 4.5), (53, 7)):
        tx, ty = -s, c
        pts.append(f"{200 + rr * c + dt * tx:.1f},{88 + rr * s + dt * ty:.1f}")
    a(f'<polygon points="{" ".join(pts)}" fill="#b4babe" stroke="#4f5558" stroke-width="0.8"/>')
    a(f'<path d="M{200 + 47 * c - 4 * s:.1f},{88 + 47 * s + 4 * c:.1f} L{200 + 47 * c + 4 * s:.1f},{88 + 47 * s - 4 * c:.1f}" stroke="#fff" stroke-width="0.8" opacity="0.7"/>')
# Pista de carbón: brillo de grafito y contactos plateados en los extremos
a('<path d="M164,124 A50,50 0 0 1 236,124" fill="none" stroke="#3a2416" stroke-width="7" opacity="0.35"/>')
a('<path d="M164,124 A50,50 0 0 1 236,124" fill="none" stroke="#f0b48a" stroke-width="1.4" opacity="0.5" transform="translate(0,-1.8)"/>')
for x, ang in ((164.5, -42), (235.5, 42)):
    a(f'<rect x="{x - 4.5}" y="119" width="9" height="9" rx="1" fill="#c9cfd3" stroke="#4f5558" stroke-width="0.6" transform="rotate({ang} {x} 123.5)"/>')
# Placa de los terminales: remaches y doblez de cada terminal
a('<rect x="160" y="140" width="80" height="16" fill="url(#po_brillo)"/>')
for x in (165, 200, 235):
    a(f'<circle cx="{x}" cy="147" r="3.6" fill="#8d9396" stroke="#3b4043" stroke-width="0.6"/>')
    a(f'<circle cx="{x - 1}" cy="146" r="1.4" fill="#fff" opacity="0.7"/>')
    a(f'<rect x="{x - 7}" y="150" width="14" height="46" rx="3" fill="url(#po_estano)"/>')
    a(f'<path d="M{x - 7},160 H{x + 7}" stroke="#5b4a1e" stroke-width="0.8" opacity="0.8"/>')
    a(f'<path d="M{x - 7},161.2 H{x + 7}" stroke="#fff4cc" stroke-width="0.6" opacity="0.7"/>')
    a(f'<circle cx="{x}" cy="184" r="4.6" fill="none" stroke="#fff1c2" stroke-width="0.8" opacity="0.6"/>')

# ----- Trimmer -----
a('<rect x="306" y="66" width="48" height="48" rx="4" fill="url(#po_azul)"/>')
for x, y in ((310, 70), (350, 70), (310, 110), (350, 110)):
    a(f'<circle cx="{x}" cy="{y}" r="1.5" fill="#173f73" opacity="0.7"/>')
a('<text x="330" y="111.2" text-anchor="middle" style="font:700 6px Plex;fill:#f4f4f0;letter-spacing:.04em">103</text>')
a('<circle cx="330" cy="90" r="14.6" fill="none" stroke="#0f2c52" stroke-width="1.2" opacity="0.8"/>')
a('<circle cx="330" cy="90" r="14" fill="url(#po_rotor)"/>')
a('<path d="M321,90 H339 M330,81 V99" stroke="#20242a" stroke-width="3" stroke-linecap="round"/>')
a('<path d="M321.5,91.6 H338.5 M331.6,81.5 V98.5" stroke="#fff" stroke-width="0.6" opacity="0.6"/>')
a('<path d="M330,77.4 l-2.2,3 h4.4 z" fill="#20242a"/>')
for x in (314, 330, 346):
    a(f'<rect x="{x - 1.5}" y="114" width="3" height="22" rx="1" fill="url(#po_hilo)"/>')
    a(f'<rect x="{x - 2.6}" y="114" width="5.2" height="4" rx="1" fill="url(#po_hilo)"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "potenciometro.svg"), "".join(d), P.DEFS + DEFS)
