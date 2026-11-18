"""Masa del casco del Taller (200×180) sobre su SVG: chapa del casco pintada con picaduras y manchas de
óxido, cordón de soldadura, pernos de las esquinas, espárrago de tierra soldado con su cordón,
arandela dentada y tuerca de latón (borne PE en 100,60), y el símbolo de tierra pintado en relieve."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<filter id="tm_oxido" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.07" numOctaves="4" seed="21" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.4  0 0 0 0 0.21  0 0 0 0 0.09  0 0 0 -24 7.7" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
<filter id="tm_picado" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="4" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.05  0 0 0 0 0.05  0 0 0 0 0.05  0 0 0 -24 7.4" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
<radialGradient id="tm_zinc" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#f5f6f0"/><stop offset="0.5" stop-color="#b9bcb2"/><stop offset="1" stop-color="#5f6359"/></radialGradient>
<radialGradient id="tm_laton" cx="0.36" cy="0.3" r="0.8"><stop offset="0" stop-color="#fff0c0"/><stop offset="0.45" stop-color="#d4a94c"/><stop offset="1" stop-color="#6f4e1a"/></radialGradient>
<radialGradient id="tm_boss" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#7b8186"/><stop offset="1" stop-color="#3c4044"/></radialGradient>
'''

SIMBOLO = "M100,92 V118 M66,118 H134 M78,132 H122 M90,146 H110"


def hexagono(x, y, r, giro=0):
    return " ".join(f"{x + r * math.cos(math.radians(giro + 60 * i)):.1f},{y + r * math.sin(math.radians(giro + 60 * i)):.1f}" for i in range(6))


d = []
a = d.append
# Chapa del casco: picaduras, manchas de óxido y chorreones bajo los pernos
a('<rect x="4" y="4" width="192" height="172" rx="6" fill="#596066" filter="url(#tm_picado)" opacity="0.55"/>')
a('<rect x="4" y="4" width="192" height="172" rx="6" fill="#596066" filter="url(#tm_oxido)" opacity="0.5"/>')
for x, y, h in ((22, 22, 26), (180, 160, 0), (110, 82, 10)):
    if h:
        a(f'<path d="M{x},{y} q1,{h / 2} -0.5,{h}" stroke="#7a4a22" stroke-opacity="0.45" stroke-width="2.4" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<path d="M6,6.5 H194" stroke="#fff" stroke-opacity="0.2" stroke-width="1.2"/>')
# Cordón de soldadura vertical entre dos tracas
for y in range(6, 176, 4):
    a(f'<ellipse cx="172" cy="{y}" rx="4.2" ry="2.6" fill="#5b6268" stroke="#2f3337" stroke-opacity="0.45" stroke-width="0.5"/>')
    a(f'<path d="M169,{y - 0.6} q3,-1.6 6,0" stroke="#c9cdd0" stroke-opacity="0.3" stroke-width="0.7" fill="none"/>')
a('<path d="M167,4 V176" stroke="#000" stroke-opacity="0.35" stroke-width="1"/><path d="M177,4 V176" stroke="#000" stroke-opacity="0.35" stroke-width="1"/>')
# Pernos de las esquinas
for x, y in ((16, 16), (154, 16), (16, 164), (154, 164)):
    a(P.perno(x, y, 4.2))
# Arañazos de la pintura
a('<path d="M30,96 l22,-6 M138,40 l14,10 M42,160 l18,2" stroke="#c4c9cc" stroke-opacity="0.35" stroke-width="0.8" stroke-linecap="round"/>')
# Símbolo de tierra pintado: sombra del relieve, pintura y brillo
a(f'<path d="{SIMBOLO}" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="6" stroke-linecap="round" transform="translate(1,1.5)" filter="url(#desenfoque)"/>')
a(f'<path d="{SIMBOLO}" fill="none" stroke="#d9b65a" stroke-width="6" stroke-linecap="round"/>')
a(f'<path d="{SIMBOLO}" fill="none" stroke="#fff3c8" stroke-opacity="0.55" stroke-width="1.4" stroke-linecap="round" transform="translate(-0.8,-1.4)"/>')
# Espárrago de tierra: base soldada con su cordón, arandela dentada y tuerca de latón
a('<circle cx="102" cy="63" r="25" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
a('<g filter="url(#biselFuerte)"><circle cx="100" cy="60" r="24" fill="url(#tm_boss)"/></g>')
for i in range(28):
    t = math.radians(i * 360 / 28)
    x, y = 100 + 24 * math.cos(t), 60 + 24 * math.sin(t)
    a(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="2.6" fill="#70767b" stroke="#2c3034" stroke-width="0.5"/>')
dientes = []
for i in range(24):
    t = math.radians(i * 15)
    r = 17.5 if i % 2 == 0 else 14.5
    dientes.append(f"{100 + r * math.cos(t):.1f},{60 + r * math.sin(t):.1f}")
a('<g filter="url(#bisel)"><polygon points="' + " ".join(dientes) + '" fill="url(#tm_zinc)"/></g>')
a(f'<polygon points="{hexagono(102, 63, 18)}" fill="#000" opacity="0.45" filter="url(#desenfoque)"/>')
a(f'<g filter="url(#biselFuerte)"><polygon points="{hexagono(100, 60, 17.5)}" fill="url(#tm_laton)" stroke="#4a3210" stroke-width="1.2"/></g>')
a(f'<circle cx="100" cy="60" r="12.5" fill="none" stroke="#fff3c8" stroke-opacity="0.45" stroke-width="1"/>')
a('<circle cx="100" cy="60" r="8" fill="#b9bcb2" stroke="#4f5349" stroke-width="1"/>')
for r in (6.4, 4.6, 2.8):
    a(f'<circle cx="100" cy="60" r="{r}" fill="none" stroke="#5f6359" stroke-width="0.7"/>')
a('<ellipse cx="97" cy="57" rx="3" ry="1.6" fill="#fff" opacity="0.7"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "masa.svg"), "".join(d), P.DEFS + DEFS)
