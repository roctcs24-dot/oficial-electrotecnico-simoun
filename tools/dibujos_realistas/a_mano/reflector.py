"""Reflector de cubierta (360×360) sobre su SVG: espejo de aluminio facetado detrás del cristal,
lámpara tubular y portalámparas redibujados en su sitio por encima del espejo, varillas de
protección con brillo, junta y reflejos del cristal templado, tornillos de la tapa, placa de datos
(datos de la ficha), lira con brillo, pomos de bloqueo con escala de inclinación, pernos de la
base y cable con lazo de goteo bajo el prensaestopas."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<clipPath id="rf_cristal"><rect x="80" y="80" width="200" height="150" rx="14"/></clipPath>
<linearGradient id="rf_espejo" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#9eaab2"/><stop offset="0.12" stop-color="#e9eef1"/><stop offset="0.22" stop-color="#b9c4cb"/>
 <stop offset="0.34" stop-color="#f4f7f9"/><stop offset="0.44" stop-color="#c3cdd3"/><stop offset="0.5" stop-color="#fbfcfd"/>
 <stop offset="0.56" stop-color="#c3cdd3"/><stop offset="0.66" stop-color="#eef2f4"/><stop offset="0.78" stop-color="#b3bec6"/>
 <stop offset="0.88" stop-color="#e2e8ec"/><stop offset="1" stop-color="#8f9ca5"/></linearGradient>
<linearGradient id="rf_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8f9ca5"/><stop offset="1" stop-color="#d5dde2"/></linearGradient>
<linearGradient id="rf_ladoD" x1="1" y1="0" x2="0" y2="0"><stop offset="0" stop-color="#7f8c95"/><stop offset="1" stop-color="#cfd8dd"/></linearGradient>
<linearGradient id="rf_lampara" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#fff6d8"/><stop offset="1" stop-color="#d9c58c"/></linearGradient>
<linearGradient id="rf_reflejo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.5"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.12"/><stop offset="0.26" stop-color="#fff" stop-opacity="0"/><stop offset="0.62" stop-color="#fff" stop-opacity="0"/><stop offset="0.63" stop-color="#fff" stop-opacity="0.14"/><stop offset="0.7" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="rf_cable" gradientUnits="userSpaceOnUse" x1="0" y1="212" x2="0" y2="358"><stop offset="0" stop-color="#15171a"/><stop offset="0.8" stop-color="#15171a"/><stop offset="1" stop-color="#15171a" stop-opacity="0"/></linearGradient>
'''

d = []
a = d.append

# Espejo facetado: bandas del canal parabólico y testeros inclinados a los lados
a('<g clip-path="url(#rf_cristal)">')
a('<rect x="80" y="80" width="200" height="150" fill="url(#rf_espejo)"/>')
a('<polygon points="80,80 116,112 116,208 80,230" fill="url(#rf_lado)"/>')
a('<polygon points="280,80 244,112 244,208 280,230" fill="url(#rf_ladoD)"/>')
a('<path d="M116,112 H244 M116,208 H244 M116,112 V208 M244,112 V208" stroke="#8f9ca5" stroke-width="0.8" fill="none" opacity="0.7"/>')
for y in (92, 104, 124, 140, 180, 196, 216):
    a(f'<path d="M80,{y} H280" stroke="#fff" stroke-opacity="0.35" stroke-width="0.6"/>')
a('</g>')
# Lámpara y portalámparas redibujados encima del espejo, en su sitio
a('<rect x="96" y="148" width="20" height="24" rx="3" fill="#7d8488"/>')
a('<rect x="244" y="148" width="20" height="24" rx="3" fill="#7d8488"/>')
for x in (96, 244):
    a(f'<rect x="{x + 2}" y="150" width="16" height="4" rx="1.5" fill="#fff" opacity="0.3"/>')
    a(P.perno(x + 10, 166, 2.2))
a('<rect x="116" y="153" width="128" height="14" rx="7" fill="url(#rf_lampara)" stroke="#c9b98a" stroke-width="1.5"/>')
a('<path d="M124,160 H236" stroke="#d8b860" stroke-width="2" opacity="0.8"/>')
a('<path d="M122,156 H238" stroke="#fff" stroke-width="1.6" opacity="0.8"/>')
a('<rect x="170" y="155" width="20" height="10" rx="5" fill="#fff" opacity="0.5"/>')
# Varillas de protección: barras redondas con brillo y su sombra
a('<path d="M80,121.5 H280 M80,161.5 H280 M80,201.5 H280" stroke="#000" stroke-opacity="0.25" stroke-width="2.4"/>')
a('<path d="M80,120 H280 M80,160 H280 M80,200 H280" stroke="#9aa6ad" stroke-width="2.6"/>')
a('<path d="M80,119.3 H280 M80,159.3 H280 M80,199.3 H280" stroke="#fff" stroke-opacity="0.8" stroke-width="0.8"/>')
# Cristal templado: reflejos en diagonal y junta de goma
a('<rect x="80" y="80" width="200" height="150" rx="14" fill="url(#rf_reflejo)"/>')
a('<rect x="80" y="80" width="200" height="150" rx="14" fill="none" stroke="#111315" stroke-width="3.5"/>')
a('<rect x="77" y="77" width="206" height="156" rx="16" fill="none" stroke="#8a9094" stroke-width="1.2"/>')

# Tornillos de la tapa a lo largo del marco y canto superior con luz
a('<path d="M80,61.2 H280" stroke="#fff" stroke-opacity="0.25" stroke-width="1.2"/>')
for x in (130, 180):
    a(P.perno(x, 70, 2.8) + P.perno(x, 240, 2.8))
a(P.perno(230, 240, 2.8))
for y in (115, 160, 205):
    a(P.perno(70, y, 2.8))
for y in (115, 205):
    a(P.perno(290, y, 2.8))
# Placa de datos en el canto superior
a(P.placa(210, 62, 64, 14, ["IP56 · 1000 W"], 5))

# Lira: brillo del fleje y pernos de la base
a('<path d="M90,250 L60,330 H300 L270,250" fill="none" stroke="#fff" stroke-opacity="0.28" stroke-width="2" stroke-linejoin="round" transform="translate(-2,-2.5)"/>')
a('<rect x="150.5" y="320.5" width="59" height="5" rx="2" fill="#fff" opacity="0.15"/>')
for x in (162, 198):
    a(P.perno(x, 336, 3.2))
a(P.perno(180, 336, 4.4))
# Pomos de bloqueo de la inclinación con su escala
for cx, sgn in ((60, -1), (300, 1)):
    for i in range(7):
        ang = math.radians(200 + i * 20) if sgn < 0 else math.radians(-20 - i * 20)
        r1, r2 = 13, (17 if i % 3 == 0 else 15.5)
        a(f'<path d="M{cx + r1 * math.cos(ang):.1f},{250 + r1 * math.sin(ang):.1f} L{cx + r2 * math.cos(ang):.1f},{250 + r2 * math.sin(ang):.1f}" stroke="#c9ced1" stroke-width="1" stroke-linecap="round"/>')
    a(f'<circle cx="{cx}" cy="250" r="10" fill="none" stroke="#3b4043" stroke-width="2.2" stroke-dasharray="1.6 1.4"/>')
    a(f'<path d="M{cx - 5},250 H{cx + 5}" stroke="#3b4043" stroke-width="3" stroke-linecap="round"/>')
    a(f'<ellipse cx="{cx - 3}" cy="246" rx="3.5" ry="2" fill="#fff" opacity="0.6"/>')

# Cable con lazo de goteo bajo el prensaestopas
a('<path d="M344,212 C344,250 346,282 330,300 C318,314 300,326 292,358" fill="none" stroke="url(#rf_cable)" stroke-width="9" stroke-linecap="round"/>')
a('<path d="M341.5,212 C341.5,250 343.5,280 328,298" fill="none" stroke="#5a6064" stroke-width="2" stroke-linecap="round"/>')
a('<rect x="301" y="153" width="3" height="24" fill="#fff" opacity="0.35"/><rect x="313" y="157" width="3" height="16" fill="#fff" opacity="0.35"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "reflector.svg"), "".join(d), P.DEFS + DEFS)
