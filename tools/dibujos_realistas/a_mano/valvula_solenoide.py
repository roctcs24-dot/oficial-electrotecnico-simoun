"""Válvula solenoide (320×320) sobre su SVG: tubería de líquido y cable del conector, que el relieve
automático pierde por ser tramos rectos, bridas con pernos y junta, cuerpo con aristas de
fundición, tubo del núcleo pulido, bobina encapsulada con nervios y borde de la etiqueta, conector
con junta, nervios de agarre y prensaestopas, y mando manual con su tuerca."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="vs_pulido" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6c7276"/><stop offset="0.3" stop-color="#ffffff"/><stop offset="0.55" stop-color="#b9bfc2"/><stop offset="1" stop-color="#4f5558"/></linearGradient>
<linearGradient id="vs_brillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.25" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/></linearGradient>
<linearGradient id="vs_rojo" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a1c16"/><stop offset="0.4" stop-color="#e0574a"/><stop offset="1" stop-color="#7a1c16"/></linearGradient>
'''

d = []
a = d.append


def tubo_recto(ruta, w, color, opac_luz=0.38):
    horizontal = "H" in ruta
    sombra = "translate(0,%.1f)" % (w * 0.28) if horizontal else "translate(%.1f,0)" % (w * 0.28)
    luz = "translate(0,-%.1f)" % (w * 0.24) if horizontal else "translate(-%.1f,0)" % (w * 0.24)
    return (f'<path d="{ruta}" stroke="{color}" stroke-width="{w}"/>'
            f'<path d="{ruta}" stroke="#000" stroke-opacity="0.28" stroke-width="{w * 0.42:.1f}" transform="{sombra}"/>'
            f'<path d="{ruta}" stroke="#fff" stroke-opacity="{opac_luz}" stroke-width="{max(1.2, w * 0.16):.1f}" transform="{luz}"/>')


# Tubería de líquido a ambos lados de las bridas y cable del conector
a(tubo_recto("M8,250 H64", 16, "#e0a030") + tubo_recto("M256,250 H312", 16, "#e0a030"))
a(tubo_recto("M260,130 H306", 10, "#15171a", 0.22))

# Bridas: junta, pernos pasantes con tuercas y canto con luz
for x in (64, 236):
    a(f'<rect x="{x}" y="226" width="20" height="48" fill="url(#am_brida)" opacity="0.75"/>')
    a(f'<rect x="{x + 9}" y="224" width="2.4" height="52" fill="#2a2e31"/>')
    for y in (233, 267):
        a(f'<rect x="{x - 3}" y="{y - 2}" width="26" height="4" fill="#8a9094"/>')
        a(P.perno(x - 2, y, 3.2) + P.perno(x + 22, y, 3.2))

# Cuerpo: brillo, aristas y tapones de fundición
a('<rect x="84" y="220" width="152" height="60" rx="6" fill="url(#vs_brillo)"/>')
a('<path d="M90,224 H230" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')
for x, y in ((96, 230), (224, 230), (96, 272), (224, 272)):
    a(P.perno(x, y, 2.6))

# Tubo del núcleo pulido y tuerca de la base del tubo
a('<rect x="146" y="176" width="28" height="46" fill="url(#vs_pulido)" opacity="0.85"/>')
a('<rect x="140" y="208" width="40" height="13" rx="2" fill="url(#am_brida)" stroke="#3b4043" stroke-width="0.6"/>')
a('<path d="M153,208 V221 M167,208 V221" stroke="#3b4043" stroke-width="0.8"/>')

# Bobina: nervios moldeados, borde de la etiqueta y brillo
for y in (140, 150, 160, 170):
    a(f'<path d="M116,{y} H204" stroke="#0e0f10" stroke-width="2"/>')
    a(f'<path d="M116,{y + 1.4} H204" stroke="#fff" stroke-opacity="0.1" stroke-width="0.8"/>')
a('<rect x="112.5" y="80.5" width="95" height="99" rx="8" fill="none" stroke="#fff" stroke-opacity="0.15" stroke-width="1"/>')
a('<rect x="132" y="102" width="56" height="26" rx="2" fill="none" stroke="#20242a" stroke-width="0.7"/>')
a('<rect x="132" y="102" width="56" height="5" fill="#20242a" opacity="0.85"/>')
a('<path d="M116,86 Q160,82 204,86" fill="none" stroke="#fff" stroke-opacity="0.22" stroke-width="2"/>')

# Conector: junta contra la bobina, nervios de agarre, tornillo y prensaestopas
a('<rect x="206" y="106" width="4" height="48" fill="#0c0d0e"/>')
for y in range(110, 156, 5):
    if 120 < y < 140:
        continue
    a(f'<path d="M214,{y} H246" stroke="#2a2e31" stroke-width="1.6"/>')
    a(f'<path d="M214,{y + 1.2} H246" stroke="#fff" stroke-opacity="0.12" stroke-width="0.7"/>')
a('<circle cx="230" cy="130" r="6.5" fill="none" stroke="#2a2e31" stroke-width="1.4"/>')
a('<rect x="252" y="120" width="8" height="20" rx="2" fill="url(#am_brida)"/>')
for y in (123, 127, 131, 135):
    a(f'<path d="M253,{y} H259" stroke="#3b4043" stroke-width="0.8"/>')

# Mando manual: brillo, tuerca de latón y ranura del vástago
a('<rect x="150" y="282" width="20" height="18" fill="url(#vs_rojo)" opacity="0.85"/>')
a('<rect x="146" y="279" width="28" height="5" rx="1" fill="#b8963a"/>')
a('<path d="M160,290 V298" stroke="#3a0d09" stroke-width="2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "valvula_solenoide.svg"), "".join(d), P.DEFS + DEFS)
