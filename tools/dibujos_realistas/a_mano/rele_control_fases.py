"""Relé de control de fases de carril DIN (220×380) sobre su SVG: carril con labios y ranuras,
cantos de la caja, tabiques entre bornes, jaulas y entradas de cable, LED con lente y halo,
escalas de los tres potenciómetros con su brillo, canto del frente y pestaña del clip del carril.
Sin cables: este dibujo también va en la mesa del Taller."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="rf_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.1" stop-color="#fff" stop-opacity="0"/><stop offset="0.9" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.22"/></linearGradient>
<linearGradient id="rf_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#eef0f1"/><stop offset="0.5" stop-color="#a7aeb2"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<linearGradient id="rf_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.4"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<radialGradient id="rf_lente" cx="0.36" cy="0.3" r="0.75"><stop offset="0" stop-color="#fff" stop-opacity="0.9"/><stop offset="0.35" stop-color="#fff" stop-opacity="0.1"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
<radialGradient id="rf_haloV" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#7cf09a" stop-opacity="0.55"/><stop offset="1" stop-color="#7cf09a" stop-opacity="0"/></radialGradient>
<radialGradient id="rf_haloA" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffd36a" stop-opacity="0.55"/><stop offset="1" stop-color="#ffd36a" stop-opacity="0"/></radialGradient>
<radialGradient id="rf_perilla" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></radialGradient>
'''

d = []
a = d.append
# Carril DIN a los lados: labios, fondo y ranuras
for x0, x1 in ((0, 30), (190, 220)):
    w = x1 - x0
    a(f'<rect x="{x0}" y="160" width="{w}" height="8" fill="#e7eaeb"/><rect x="{x0}" y="160" width="{w}" height="1.3" fill="#fff"/>')
    a(f'<rect x="{x0}" y="168" width="{w}" height="3" fill="#000" opacity="0.22"/>')
    a(f'<rect x="{x0}" y="212" width="{w}" height="8" fill="#868c90"/>')
a('<rect x="4" y="182" width="20" height="16" rx="8" fill="#202427"/><rect x="196" y="182" width="20" height="16" rx="8" fill="#202427"/>')
a('<rect x="26" y="162" width="4" height="56" fill="#000" opacity="0.3"/><rect x="190" y="162" width="4" height="56" fill="#000" opacity="0.3"/>')
# Cantos de la caja
a('<rect x="31" y="11" width="158" height="358" rx="9" fill="url(#rf_lado)"/>')
# Zonas de bornes: tabiques, jaulas y entradas de cable
for y, ent in ((46, 22), (334, 357)):
    for x in (86, 134):
        a(f'<rect x="{x - 2}" y="{y - 26}" width="4" height="52" rx="2" fill="#a9aeb2"/><rect x="{x - 2}" y="{y - 26}" width="1.2" height="52" fill="#fff" opacity="0.7"/>')
    for x in (62, 110, 158):
        a(f'<circle cx="{x}" cy="{y}" r="12.2" fill="none" stroke="url(#rf_jaula)" stroke-width="2.6"/>')
        a(f'<rect x="{x - 10}" y="{ent - 2.5}" width="20" height="5" rx="1.5" fill="#1b1d20"/>')
# Frente: canto con luz y sombra en la caja bajo el frente
a('<path d="M48,85.5 H172" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2"/>')
a('<rect x="46" y="296" width="128" height="6" fill="url(#rf_sombraV)"/>')
# LED encendidos: aro, halo y lente
for x, halo in ((78, "rf_haloV"), (142, "rf_haloA")):
    a(f'<circle cx="{x}" cy="136" r="16" fill="url(#{halo})"/>')
    a(f'<circle cx="{x}" cy="136" r="10" fill="none" stroke="#1a1f24" stroke-width="2"/>')
    a(f'<circle cx="{x}" cy="136" r="8" fill="url(#rf_lente)"/>')
# Potenciómetros: escala de marcas, brillo de la perilla y ranura
for cx, cy in ((78, 196), (142, 196), (110, 256)):
    for i in range(11):
        g = math.radians(135 + i * 27)
        r1, r2 = 22.5, 22.5 + (4.5 if i % 5 == 0 else 2.8)
        a(f'<path d="M{cx + r1 * math.cos(g):.1f},{cy + r1 * math.sin(g):.1f} L{cx + r2 * math.cos(g):.1f},{cy + r2 * math.sin(g):.1f}" stroke="#d6dadc" stroke-width="{1.3 if i % 5 == 0 else 0.9}"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="17" fill="url(#rf_perilla)"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="20" fill="none" stroke="#000" stroke-opacity="0.5" stroke-width="1"/>')
    a(f'<rect x="{cx - 1}" y="{cy - 13}" width="2" height="12" rx="1" fill="#f4f4f0" opacity="0.8"/>')
# Pestaña del clip del carril
a('<path d="M94,368 H126 V374 Q126,378 122,378 H98 Q94,378 94,374 Z" fill="#d9dcde" stroke="#8a9095" stroke-width="1"/>')
a('<rect x="102" y="371" width="16" height="3.5" rx="1.7" fill="#4a4f53"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "rele_control_fases.svg"), "".join(d), P.DEFS + DEFS)
