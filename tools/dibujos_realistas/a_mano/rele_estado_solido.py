"""Relé de estado sólido (400×220) sobre su SVG: carcasa de plástico gris con su textura y cantos,
cara central de la etiqueta con el esquema impreso (LED y triac), alojamientos de los bornes con su
pared y la barrera entre bornes, placas de apriete niqueladas y tornillos de cabeza combinada,
tapas abatibles de policarbonato ahumado con su bisagra, LED con lente y aro, remache de la carcasa
y sombras de contacto."""
import math
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ss_hueco" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#050607"/><stop offset="0.25" stop-color="#1c1f22"/><stop offset="0.8" stop-color="#2b2f33"/><stop offset="1" stop-color="#3a3f43"/></linearGradient>
<linearGradient id="ss_placa" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#eef1f2"/><stop offset="0.4" stop-color="#b7bdc1"/><stop offset="0.65" stop-color="#d8dcde"/><stop offset="1" stop-color="#7c8388"/></linearGradient>
<radialGradient id="ss_cabeza" cx="0.36" cy="0.3" r="0.85">
 <stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d6dadc"/><stop offset="0.75" stop-color="#8b9195"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="ss_tapa" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.38" stop-color="#fff" stop-opacity="0.05"/>
 <stop offset="0.46" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.52" stop-color="#fff" stop-opacity="0.06"/>
 <stop offset="0.7" stop-color="#fff" stop-opacity="0.14"/><stop offset="0.74" stop-color="#fff" stop-opacity="0.03"/><stop offset="1" stop-color="#fff" stop-opacity="0.02"/></linearGradient>
<linearGradient id="ss_bisagra" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#4a5359"/><stop offset="0.3" stop-color="#2a3237"/><stop offset="1" stop-color="#161b1e"/></linearGradient>
<linearGradient id="ss_cara" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#f1f3f4"/><stop offset="1" stop-color="#c9ced1"/></linearGradient>
<radialGradient id="ss_led" cx="0.4" cy="0.36" r="0.7">
 <stop offset="0" stop-color="#ffb08a"/><stop offset="0.35" stop-color="#e2582a"/><stop offset="1" stop-color="#7a2010"/></radialGradient>
'''

d = []
a = d.append

# Carcasa: canto superior iluminado, canto inferior en sombra
a('<path d="M118,20.9 H282" stroke="#fff" stroke-width="1.4" opacity="0.8"/>')
a('<path d="M110.9,28 V192" stroke="#fff" stroke-width="1.2" opacity="0.55"/>')
a('<path d="M289.1,28 V192 M118,199.1 H282" stroke="#4a5055" stroke-width="1.4" opacity="0.7"/>')
# Cara de la etiqueta, algo rehundida, con su marco impreso
a('<rect x="118" y="80" width="164" height="60" rx="2.5" fill="url(#ss_cara)" filter="url(#plastico)"/>')
a('<rect x="118" y="80" width="164" height="60" rx="2.5" fill="none" stroke="#7d8488" stroke-width="0.8"/>')
a('<path d="M118.6,81 H281.4" stroke="#000" stroke-width="0.8" opacity="0.25"/>')
a('<rect x="121" y="83" width="158" height="54" rx="1.5" fill="none" stroke="#2a2e32" stroke-width="0.5" opacity="0.45"/>')
# Esquema impreso: LED de mando y triac de salida, en tinta gris
e = '#3a3f44'
a(f'<g stroke="{e}" stroke-width="0.8" fill="none" opacity="0.75" stroke-linejoin="round">'
  '<path d="M170,116 V132 M166,121 H174 L170,127 Z M166,127 H174"/>'
  '<path d="M184,121 H208 M205,119 L208,121 L205,123 M184,127 H208 M205,125 L208,127 L205,129"/>'
  '<path d="M213,116 V134" stroke-dasharray="1.6 1.4"/>'
  '<path d="M224,114 V119.5 M224,128.5 V134 M218,119.5 H230 M218,128.5 H230"/>'
  '<path d="M219,120 H225 L222,128 Z M223,128 H229 L226,120 Z M229,128.5 L233,132.5"/>'
  '</g>')

# Alojamientos de los bornes: pared, barrera central y placas de apriete
for y0 in (32, 142):
    a(f'<rect x="122" y="{y0}" width="156" height="46" rx="4" fill="url(#ss_hueco)"/>')
    a(f'<rect x="122" y="{y0}" width="156" height="46" rx="4" fill="none" stroke="#000" stroke-width="1.4" opacity="0.8"/>')
    a(f'<path d="M124,{y0 + 45.2} H276" stroke="#9aa1a6" stroke-width="0.9" opacity="0.6"/>')
    a(f'<g filter="url(#bisel)"><rect x="196" y="{y0 + 1}" width="8" height="44" rx="2" fill="#3b4146"/></g>')
    a(f'<path d="M197,{y0 + 2} V{y0 + 44}" stroke="#7d858a" stroke-width="0.8" opacity="0.7"/>')

def borne(x, y):
    s = f'<rect x="{x - 15}" y="{y - 14}" width="30" height="30" rx="2" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>'
    s += f'<g filter="url(#bisel)"><rect x="{x - 14}" y="{y - 14}" width="28" height="28" rx="1.8" fill="url(#ss_placa)" filter="url(#cepillado)"/></g>'
    s += f'<path d="M{x - 14},{y + 9} H{x + 14}" stroke="#3a4044" stroke-width="0.8" opacity="0.6"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#000" opacity="0.45" filter="url(#desenfoque)"/>'
    s += f'<circle cx="{x}" cy="{y}" r="10.4" fill="url(#am_acero)" stroke="#3b4043" stroke-width="0.6"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="8.6" fill="url(#ss_cabeza)"/></g>'
    s += f'<circle cx="{x}" cy="{y}" r="8.6" fill="none" stroke="#3b4043" stroke-width="0.7"/>'
    # Cabeza combinada: ranura recta y cruz
    s += f'<path d="M{x - 6.6},{y} H{x + 6.6}" stroke="#1c2023" stroke-width="2.2" stroke-linecap="round"/>'
    s += f'<path d="M{x},{y - 4.4} V{y + 4.4}" stroke="#1c2023" stroke-width="2" stroke-linecap="round"/>'
    s += f'<path d="M{x - 6},{y + 1.3} H{x + 6}" stroke="#fff" stroke-width="0.6" opacity="0.5"/>'
    s += f'<ellipse cx="{x - 3.4}" cy="{y - 4}" rx="2.8" ry="1.4" fill="#fff" opacity="0.55" transform="rotate(-30 {x - 3.4} {y - 4})"/>'
    return s

for x, y in ((150, 55), (250, 55), (150, 165), (250, 165)):
    a(borne(x, y))

# Tapas abatibles de policarbonato ahumado, con la bisagra en el canto exterior
for y0, h, arriba in ((20, 59, True), (141, 59, False)):
    a(f'<rect x="118" y="{y0}" width="164" height="{h}" rx="3" fill="#1b2a33" opacity="0.16"/>')
    a(f'<rect x="118" y="{y0}" width="164" height="{h}" rx="3" fill="url(#ss_tapa)"/>')
    a(f'<rect x="118.6" y="{y0 + 0.6}" width="162.8" height="{h - 1.2}" rx="2.6" fill="none" stroke="#e8f2f6" stroke-width="0.7" opacity="0.45"/>')
    a(f'<rect x="118" y="{y0}" width="164" height="{h}" rx="3" fill="none" stroke="#0e1519" stroke-width="0.8" opacity="0.55"/>')
    yb = y0 if arriba else y0 + h - 11
    a(f'<g filter="url(#plastico)"><rect x="118" y="{yb}" width="164" height="11" rx="2" fill="url(#ss_bisagra)" opacity="0.92"/></g>')
    a(f'<path d="M120,{yb + 0.8} H280" stroke="#9fb0ba" stroke-width="0.7" opacity="0.5"/>')
    for xx in (126, 132, 268, 274):
        a(f'<path d="M{xx},{yb + 2.5} V{yb + 8.5}" stroke="#0a0d0f" stroke-width="1.2" opacity="0.7"/>')
    # Lengüeta para abrir la tapa
    yl = y0 + h - 4 if arriba else y0
    a(f'<rect x="190" y="{yl}" width="20" height="4" rx="1.5" fill="#2a3237" opacity="0.75"/>')

# LED de mando: lente con su aro
a('<circle cx="270" cy="110" r="9.2" fill="#000" opacity="0.4" filter="url(#desenfoque)"/>')
a('<circle cx="270" cy="110" r="8.6" fill="#2a2e32"/>')
a('<circle cx="270" cy="110" r="7" fill="url(#ss_led)"/>')
a('<circle cx="270" cy="110" r="4" fill="none" stroke="#5a1a0c" stroke-width="0.6" opacity="0.6"/>')
a('<ellipse cx="267.6" cy="107.2" rx="2.6" ry="1.6" fill="#fff" opacity="0.75" transform="rotate(-30 267.6 107.2)"/>')
a('<path d="M274.5,113 A5.5,5.5 0 0 1 268,115.8" fill="none" stroke="#ffd0b8" stroke-width="0.8" opacity="0.6"/>')
# Remache de la carcasa
a('<circle cx="125" cy="110" r="5.6" fill="#5c6267"/>')
a('<circle cx="125" cy="110" r="4.6" fill="url(#am_acero)"/>')
a('<circle cx="125" cy="110" r="1.6" fill="#3b4043" opacity="0.7"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "rele_estado_solido.svg"), "".join(d), P.DEFS + DEFS)
