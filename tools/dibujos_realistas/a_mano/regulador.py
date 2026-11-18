"""Regulador de tensión en cápsula TO-220 atornillado a su disipador (400×220) sobre su SVG:
disipador de aluminio extruido con las estrías de la hilera, placa central de apoyo, aletas con
cantos brillantes, base con sus pasadores de soldadura, pasta térmica asomando por los bordes de
la lengüeta, tornillo de cabeza alomada con arandela, epoxi negro mate, serigrafía láser tenue
(datos de la ficha) y patas estañadas. La cápsula se dibuja con las piezas de mosfet.py."""
import os
import random
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T

DEFS = '''
<linearGradient id="rg_aleta" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#6e767c"/><stop offset="0.2" stop-color="#d8dde0"/><stop offset="0.45" stop-color="#aab1b6"/>
 <stop offset="0.8" stop-color="#868e94"/><stop offset="1" stop-color="#555c61"/></linearGradient>
<linearGradient id="rg_base" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#e3e7e9"/><stop offset="0.12" stop-color="#b9c0c4"/><stop offset="0.6" stop-color="#9aa2a7"/>
 <stop offset="0.9" stop-color="#7d858a"/><stop offset="1" stop-color="#5a6166"/></linearGradient>
<linearGradient id="rg_placa" x1="0" y1="0" x2="1" y2="0.25">
 <stop offset="0" stop-color="#8d959a"/><stop offset="0.3" stop-color="#b4bbc0"/><stop offset="0.55" stop-color="#c8cdd0"/>
 <stop offset="1" stop-color="#8a9297"/></linearGradient>
<radialGradient id="rg_cabeza" cx="0.38" cy="0.32" r="0.8">
 <stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d9dc"/><stop offset="0.8" stop-color="#7f878c"/><stop offset="1" stop-color="#4b5256"/></radialGradient>
<filter id="rg_extrusion" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="1.1 0.012" numOctaves="2" seed="13" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0.8 0" result="g"/>
 <feComposite in="g" in2="SourceAlpha" operator="in" result="g2"/>
 <feBlend in="SourceGraphic" in2="g2" mode="overlay"/>
</filter>
<filter id="rg_pasta" x="-20%" y="-20%" width="140%" height="140%">
 <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="5" result="n"/>
 <feDisplacementMap in="SourceGraphic" in2="n" scale="2.2" xChannelSelector="R" yChannelSelector="G" result="d"/>
 <feGaussianBlur in="d" stdDeviation="0.25" result="b"/>
 <feSpecularLighting in="b" surfaceScale="2" specularConstant="0.8" specularExponent="16" lighting-color="#fff" result="s"><feDistantLight azimuth="235" elevation="45"/></feSpecularLighting>
 <feComposite in="s" in2="b" operator="in" result="s2"/>
 <feComposite in="b" in2="s2" operator="arithmetic" k1="0" k2="1" k3="0.6" k4="0"/>
</filter>
'''

d = []
a = d.append

# Placa central del disipador, donde apoya la lengüeta
a('<rect x="118" y="20" width="164" height="102" fill="#000" opacity="0.35" filter="url(#sombraCorta)"/>')
a('<g filter="url(#bisel)"><rect x="118" y="20" width="164" height="102" rx="1.5" fill="url(#rg_placa)" filter="url(#rg_extrusion)"/></g>')
a('<path d="M118.8,21 V121 M119,20.7 H281" stroke="#fff" stroke-width="1" opacity="0.55"/>')
a('<path d="M281.2,21 V121" stroke="#3d4448" stroke-width="1.2" opacity="0.8"/>')
# Aletas: estrías de extrusión, canto superior y sombra entre aletas
for x in (70, 90, 110, 290, 310, 330):
    a(f'<rect x="{x - 9}" y="22" width="18" height="98" fill="#000" opacity="0.28" filter="url(#sombraCorta)"/>')
for x in (70, 90, 110, 290, 310, 330):
    a(f'<rect x="{x - 5}" y="20" width="10" height="100" fill="url(#rg_aleta)" filter="url(#rg_extrusion)"/>')
    a(f'<rect x="{x - 5}" y="20" width="10" height="2.2" rx="1" fill="#f4f6f7" opacity="0.85"/>')
    a(f'<path d="M{x - 2.8},23 V119" stroke="#fff" stroke-width="0.8" opacity="0.45"/>')
# Base: estrías horizontales, canto superior y canto inferior en sombra
a('<g filter="url(#bisel)"><rect x="60" y="120" width="280" height="24" fill="url(#rg_base)" filter="url(#cepillado)"/></g>')
a('<path d="M60,120.7 H340" stroke="#fff" stroke-width="1.2" opacity="0.7"/>')
a('<path d="M60,143.4 H340" stroke="#2f3539" stroke-width="1.2" opacity="0.8"/>')
for x in (70, 90, 110, 290, 310, 330):
    a(f'<path d="M{x - 6},120.6 Q{x},118 {x + 6},120.6" fill="none" stroke="#5c6368" stroke-width="0.9" opacity="0.6"/>')
# Pasadores de soldadura bajo la base, en los extremos
for x in (76, 324):
    a(f'<rect x="{x - 2.2}" y="144" width="4.4" height="12" rx="1.2" fill="url(#to_estano)"/>')
    a(f'<rect x="{x - 3}" y="144" width="6" height="3" fill="#000" opacity="0.35"/>')

# Pasta térmica que asoma por los cantos de la lengüeta
rnd = random.Random(7)
pasta = ""
for lado in (-1, 1):
    xx = 200 + lado * 46
    pts = []
    for i in range(9):
        yy = 24 + i * 7
        pts.append(f"{xx + lado * rnd.uniform(2.0, 4.6):.1f},{yy:.1f}")
    pasta += f'<path d="M{xx},22 L{" L".join(pts)} L{xx},82 Z" fill="#d9dbd6"/>'
a(f'<g opacity="0.55" transform="translate(0.8,1.2)" filter="url(#desenfoque)">{pasta.replace("#d9dbd6", "#2a2f33")}</g>')
a(f'<g filter="url(#rg_pasta)">{pasta}</g>')

# Cápsula TO-220 con su tornillo en lugar del agujero
a(T.hoja(con_hueco=False))
a('<circle cx="200" cy="46" r="13.5" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>')
a('<circle cx="200" cy="46" r="12.6" fill="url(#am_acero)" stroke="#4a5155" stroke-width="0.8"/>')
a('<circle cx="200" cy="46" r="12.6" fill="none" stroke="#fff" stroke-width="0.6" opacity="0.5" stroke-dasharray="14 66" stroke-dashoffset="30"/>')
a('<g filter="url(#biselFuerte)"><circle cx="200" cy="46" r="9.2" fill="url(#rg_cabeza)"/></g>')
a('<circle cx="200" cy="46" r="9.2" fill="none" stroke="#40474b" stroke-width="0.7"/>')
a('<path d="M195.2,46 H204.8 M200,41.2 V50.8" stroke="#262b2e" stroke-width="2.4" stroke-linecap="round"/>')
a('<path d="M196.6,47.2 H203.4 M201.2,41.6 V50.2" stroke="#8a9196" stroke-width="0.6" opacity="0.6"/>')
a('<ellipse cx="196" cy="42" rx="3.4" ry="1.8" fill="#fff" opacity="0.55" transform="rotate(-35 196 42)"/>')
a(T.cuerpo(texto="12 V · 1,5 A"))
a(T.patas())

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "regulador.svg"), "".join(d), P.DEFS + T.DEFS_TO220 + DEFS)
