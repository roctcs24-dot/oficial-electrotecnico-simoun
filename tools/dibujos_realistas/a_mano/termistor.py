"""Termistores (400×220) sobre su SVG. NTC de gota: epoxi negro brillante con su reflejo, chorreado
del barniz sobre las patillas y patillas estañadas con brillo. PTC del bobinado: funda de fibra de
vidrio trenzada que une las tres sondas, sondas de epoxi con su reflejo, cables con aislamiento y
punteras, y regleta de bornes con tabique, entradas de cable y placa de apriete bajo cada tornillo."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<pattern id="te_trenza" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
 <rect width="5" height="5" fill="#e3ddcb"/><rect width="2.5" height="5" fill="#c9c2ac"/>
 <rect y="0" width="5" height="0.6" fill="#fff" opacity="0.5"/></pattern>
<linearGradient id="te_tubo" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.7" stop-color="#000" stop-opacity="0.1"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
<radialGradient id="te_gota" cx="0.35" cy="0.3" r="0.75">
 <stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.85" stop-color="#000" stop-opacity="0.1"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></radialGradient>
<radialGradient id="te_ptc" cx="0.35" cy="0.3" r="0.8">
 <stop offset="0" stop-color="#c7704a"/><stop offset="0.55" stop-color="#7a3b1e"/><stop offset="1" stop-color="#3d1a0b"/></radialGradient>
<linearGradient id="te_regleta" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.12" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.85" stop-color="#000" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="te_laton" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#f6e2a8"/><stop offset="0.5" stop-color="#c9a24a"/><stop offset="1" stop-color="#7a5c1c"/></linearGradient>
<linearGradient id="te_puntera" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.35" stop-color="#ffffff"/><stop offset="1" stop-color="#6c7378"/></linearGradient>
'''

d = []
a = d.append

# ----- NTC de gota -----
a('<ellipse cx="90" cy="152" rx="22" ry="2" fill="#000" opacity="0.35" filter="url(#sombraCorta)"/>')
a('<path d="M77,97 Q75,124 74,149 M101,97 Q103,124 104,149" fill="none" stroke="#fff" stroke-width="1" opacity="0.85" stroke-linecap="round"/>')
a('<path d="M79.5,97 Q77.5,124 76.5,149 M103.5,97 Q105.5,124 106.5,149" fill="none" stroke="#4f5558" stroke-width="0.8" opacity="0.6"/>')
# Chorreado del barniz sobre las patillas
a('<path d="M73,96 Q77,99 77.2,106 Q77.4,109.5 78.6,109.5 Q80,109.5 80,106 Q80.4,100 85,98.5 Z" fill="#2a2e32"/>')
a('<path d="M107,96 Q103,99 102.8,106 Q102.6,109.5 101.4,109.5 Q100,109.5 100,106 Q99.6,100 95,98.5 Z" fill="#2a2e32"/>')
a('<path d="M77.4,100.5 Q77.8,104 78,107" stroke="#fff" stroke-width="0.6" opacity="0.4" fill="none"/>')
a('<ellipse cx="90" cy="80" rx="26" ry="22" fill="url(#te_gota)"/>')
a('<path d="M71,72 Q80,62 96,62" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.8" stroke-linecap="round"/>')
a('<path d="M104,95 Q112,88 114,78" fill="none" stroke="#9aa3aa" stroke-width="1.2" opacity="0.35" stroke-linecap="round"/>')

# ----- PTC del bobinado -----
# Funda de fibra de vidrio trenzada (el trazo del SVG no se ve con el relieve automático)
a('<rect x="207" y="75" width="126" height="14" rx="7" fill="url(#te_trenza)"/>')
a('<rect x="207" y="75" width="126" height="14" rx="7" fill="url(#te_tubo)" stroke="#8f8873" stroke-width="0.6"/>')
# Las tres sondas de epoxi encima de la funda
for x in (232, 270, 308):
    a(f'<ellipse cx="{x}" cy="83.5" rx="12" ry="9" fill="#000" opacity="0.3" filter="url(#sombraCorta)"/>')
    a(f'<ellipse cx="{x}" cy="82" rx="12" ry="9" fill="url(#te_ptc)" stroke="#3a1608" stroke-width="0.6"/>')
    a(f'<path d="M{x - 8},79 Q{x - 4},74.5 {x + 3},75" fill="none" stroke="#fff" stroke-width="1.3" opacity="0.7" stroke-linecap="round"/>')
# Brillo del aislamiento de los cables y punteras al entrar en la regleta
a('<path d="M213,84 Q205,110 249,150 M325,84 Q335,110 289,150" fill="none" stroke="#fff" stroke-width="1" opacity="0.9" transform="translate(-1,-1)"/>')
for x in (250, 290):
    a(f'<rect x="{x - 3}" y="142" width="6" height="10" rx="1" fill="url(#te_puntera)" stroke="#4f5558" stroke-width="0.5"/>')
    a(f'<path d="M{x - 3},145 H{x + 3} M{x - 3},148 H{x + 3}" stroke="#4f5558" stroke-width="0.5"/>')
# Regleta: entradas de cable, tabique entre bornes, placas de apriete y brillo del plástico
a('<rect x="226" y="150" width="88" height="34" rx="4" fill="url(#te_regleta)"/>')
for x in (250, 290):
    a(f'<rect x="{x - 4.5}" y="150.6" width="9" height="4" rx="1" fill="#1d2023"/>')
    a(f'<path d="M{x - 11},157 H{x + 11} V178 H{x - 11} Z M{x + 9.6},167 A9.6,9.6 0 1 0 {x - 9.6},167 A9.6,9.6 0 1 0 {x + 9.6},167 Z" fill="url(#te_laton)" fill-rule="evenodd" stroke="#5b4a1e" stroke-width="0.6"/>')
a('<rect x="268" y="152" width="4" height="30" rx="1" fill="#c3c8cb" stroke="#5b6267" stroke-width="0.6"/>')
a('<path d="M268.8,153 V181" stroke="#fff" stroke-width="0.8" opacity="0.8"/>')
for x in (231, 309):
    a(f'<circle cx="{x}" cy="167" r="2.2" fill="#5b6267"/><circle cx="{x - 0.5}" cy="166.5" r="0.9" fill="#fff" opacity="0.6"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "termistor.svg"), "".join(d), P.DEFS + DEFS)
