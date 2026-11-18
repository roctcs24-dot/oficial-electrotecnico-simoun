"""Resistencias (400×220) sobre su SVG. De película: patillas estañadas, cuerpo en hueso de perro con
los casquillos más gruesos, laca brillante sobre las bandas de color, banda dorada metálica y
menisco de laca en la salida de las patillas. SMD: capa negra brillante sobre el sustrato blanco de
alúmina, terminaciones estañadas y soldadura en las pistas. De potencia: cerámica porosa con sus
cantos, cemento en la salida de las patillas y sombra de apoyo."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<clipPath id="rs_cuerpo"><rect x="130" y="84" width="140" height="52" rx="24"/></clipPath>
<linearGradient id="rs_cil" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#000" stop-opacity="0.12"/><stop offset="0.12" stop-color="#fff" stop-opacity="0.45"/>
 <stop offset="0.3" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.7" stop-color="#000" stop-opacity="0.08"/>
 <stop offset="0.9" stop-color="#fff" stop-opacity="0.12"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
<linearGradient id="rs_oro" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#6e5216"/><stop offset="0.16" stop-color="#fff4c8"/><stop offset="0.38" stop-color="#d9b04a"/>
 <stop offset="0.7" stop-color="#9c7624"/><stop offset="0.88" stop-color="#e2c46e"/><stop offset="1" stop-color="#5e4512"/></linearGradient>
<linearGradient id="rs_hilo" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.25" stop-color="#ffffff"/><stop offset="0.5" stop-color="#b8bec2"/>
 <stop offset="0.8" stop-color="#6c7378"/><stop offset="1" stop-color="#9aa1a6"/></linearGradient>
<linearGradient id="rs_smd" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.28"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="rs_estano" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#8c9398"/><stop offset="0.4" stop-color="#ffffff"/><stop offset="0.7" stop-color="#c3c8cb"/><stop offset="1" stop-color="#6f767b"/></linearGradient>
<linearGradient id="rs_ceramica" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.6"/><stop offset="0.12" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.75" stop-color="#000" stop-opacity="0.04"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></linearGradient>
<filter id="rs_poros" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="21" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.35  0 0 0 0 0.33  0 0 0 0 0.3  0 0 0 -9 5.2" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
'''

d = []
a = d.append


def sombra(cx, cy, rx, ry, op=0.4):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#000" opacity="{op}" filter="url(#sombraCorta)"/>'


# ----- Resistencia de película de 1/4 W -----
a(sombra(200, 139, 66, 2.6))
for x1, x2 in ((32, 132), (268, 368)):
    a(f'<rect x="{x1}" y="107.5" width="{x2 - x1}" height="5" rx="2.5" fill="url(#rs_hilo)"/>')
# Menisco de laca en la salida de las patillas
for x, s in ((131, -1), (269, 1)):
    a(f'<path d="M{x},101 Q{x + s * 5},108 {x + s * 8},107.6 V112.4 Q{x + s * 5},112 {x},119 Z" fill="#b89c6c"/>')
# Hueso de perro: el centro más delgado que los casquillos de los extremos
a('<g clip-path="url(#rs_cuerpo)">')
a('<path d="M164,84 Q200,92 236,84 Z" fill="#6d5636" opacity="0.4"/>')
a('<path d="M164,136 Q200,128 236,136 Z" fill="#6d5636" opacity="0.4"/>')
a('<path d="M164,84 Q200,92 236,84" fill="none" stroke="#fff3d6" stroke-width="0.8" opacity="0.6"/>')
# Banda dorada metálica y filos de las bandas pintadas
a('<rect x="238" y="84" width="12" height="52" fill="url(#rs_oro)"/>')
for x in (152, 164, 176, 188, 200, 212, 238, 250):
    a(f'<path d="M{x},84 V136" stroke="#2a2016" stroke-width="0.7" opacity="0.35"/>')
# Laca brillante: cilindro, reflejo fino arriba y luz rebotada abajo
a('<rect x="130" y="84" width="140" height="52" fill="url(#rs_cil)"/>')
a('<path d="M146,92 Q200,85.6 256,92" fill="none" stroke="#fff" stroke-width="1.3" opacity="0.85" stroke-linecap="round"/>')
a('<path d="M150,129.5 Q200,133 250,129.5" fill="none" stroke="#fff" stroke-width="1" opacity="0.25" stroke-linecap="round"/>')
a('</g>')

# ----- Resistencia SMD -----
a(sombra(80, 194, 26, 1.8, 0.45))
for x1, x2 in ((38, 56), (104, 122)):
    a(f'<rect x="{x1}" y="180" width="{x2 - x1}" height="4" rx="1" fill="url(#rs_hilo)"/>')
a('<rect x="58" y="172" width="40" height="20" fill="url(#rs_smd)"/>')
a('<rect x="60" y="188.6" width="38" height="3.4" fill="#ecebe4"/>')
a('<path d="M60,188.6 H98" stroke="#000" stroke-width="0.6" opacity="0.6"/>')
for x in (54, 98):
    a(f'<rect x="{x}" y="172" width="8" height="20" rx="1.2" fill="url(#rs_estano)"/>')
# Soldadura: menisco entre la terminación y la pista
a('<path d="M54,175 Q50,181 45,180 V184 Q50,183 54,189 Z" fill="url(#rs_estano)" opacity="0.95"/>')
a('<path d="M106,175 Q110,181 115,180 V184 Q110,183 106,189 Z" fill="url(#rs_estano)" opacity="0.95"/>')

# ----- Resistencia de potencia cementada -----
a(sombra(329, 196, 42, 2.4, 0.45))
for x1, x2 in ((258, 288), (370, 394)):
    a(f'<rect x="{x1}" y="175" width="{x2 - x1}" height="4" rx="2" fill="url(#rs_hilo)"/>')
a('<rect x="286" y="160" width="86" height="34" rx="3" fill="#fff" filter="url(#rs_poros)"/>')
a('<rect x="286" y="160" width="86" height="34" rx="3" fill="url(#rs_ceramica)"/>')
a('<path d="M288.5,161.5 H369.5" stroke="#fff" stroke-width="1" opacity="0.8"/>')
# Cemento gris donde salen las patillas
for x in (288.5, 369.5):
    a(f'<ellipse cx="{x}" cy="177" rx="3" ry="6.5" fill="#a9a497" stroke="#7e786b" stroke-width="0.5"/>')
    a(f'<ellipse cx="{x - 0.6}" cy="175" rx="1.2" ry="2.6" fill="#fff" opacity="0.4"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "resistor.svg"), "".join(d), P.DEFS + DEFS)
