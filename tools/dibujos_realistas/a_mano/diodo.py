"""Diodo rectificador (400×220) sobre su SVG: patillas estañadas con su brillo y el menisco de epoxi
donde entran al cuerpo, cuerpo cilíndrico de epoxi negro mate con sus extremos redondeados y su
reflejo, franja de pintura plateada del cátodo con su relieve y sombra de apoyo. El símbolo de
debajo queda como está."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="di_cil" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.18" stop-color="#fff" stop-opacity="0.32"/>
 <stop offset="0.32" stop-color="#fff" stop-opacity="0"/><stop offset="0.75" stop-color="#000" stop-opacity="0.15"/>
 <stop offset="0.9" stop-color="#9aa3aa" stop-opacity="0.18"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="di_extremo_i" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.6"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="di_extremo_d" x1="1" y1="0" x2="0" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.6"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="di_franja" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#8d959b"/><stop offset="0.2" stop-color="#ffffff"/><stop offset="0.45" stop-color="#d3d8db"/>
 <stop offset="0.85" stop-color="#7f878d"/><stop offset="1" stop-color="#4f565b"/></linearGradient>
<linearGradient id="di_hilo" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.25" stop-color="#ffffff"/><stop offset="0.5" stop-color="#b8bec2"/>
 <stop offset="0.8" stop-color="#6c7378"/><stop offset="1" stop-color="#9aa1a6"/></linearGradient>
'''

d = []
a = d.append
# Sombra de apoyo bajo el cuerpo y bajo las patillas
a('<ellipse cx="200" cy="123" rx="48" ry="2.6" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>')
# Patillas de cobre estañado: cilindro con reflejo y pequeñas marcas de las pinzas de doblado
for x1, x2 in ((32, 151), (249, 368)):
    a(f'<rect x="{x1}" y="97.6" width="{x2 - x1}" height="4.8" rx="2.4" fill="url(#di_hilo)"/>')
for x in (98, 302):
    a(f'<path d="M{x},97.8 V102.2 M{x + 2.5},97.8 V102.2" stroke="#5b6267" stroke-width="0.6" opacity="0.6"/>')
# Menisco de epoxi donde las patillas entran al cuerpo
for x, sgn in ((150, -1), (250, 1)):
    a(f'<path d="M{x},94 Q{x + sgn * 4},99 {x + sgn * 7},98.6 V101.4 Q{x + sgn * 4},101 {x},106 Z" fill="#202326"/>')
# Cuerpo cilíndrico: extremos más oscuros, reflejo de la luz y la franja del cátodo con relieve
a('<rect x="150" y="80" width="18" height="40" rx="8" fill="url(#di_extremo_i)"/>')
a('<rect x="232" y="80" width="18" height="40" rx="8" fill="url(#di_extremo_d)"/>')
a('<rect x="222" y="80.6" width="14" height="38.8" fill="url(#di_franja)"/>')
a('<path d="M222,81 V119" stroke="#2a2e32" stroke-width="0.8" opacity="0.7"/><path d="M236,81 V119" stroke="#2a2e32" stroke-width="0.8" opacity="0.7"/>')
a('<rect x="150" y="80" width="100" height="40" rx="8" fill="url(#di_cil)"/>')
a('<path d="M160,86.5 H240" stroke="#fff" stroke-width="1.2" opacity="0.55" stroke-linecap="round"/>')
a('<path d="M158,116 H242" stroke="#c8d0d6" stroke-width="1" opacity="0.25" stroke-linecap="round"/>')
# Trazos rectos del símbolo, que el relieve automático borra (su caja no tiene alto o ancho)
a('<path d="M140,164 H180 M214,164 H254" stroke="#20242a" stroke-width="3"/>')
a('<path d="M214,148 V180" stroke="#20242a" stroke-width="4"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "diodo.svg"), "".join(d), P.DEFS + DEFS)
