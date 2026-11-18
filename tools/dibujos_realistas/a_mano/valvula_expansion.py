"""Válvula de expansión termostática (320×320) sobre su SVG: tuberías rectas que el relieve
automático pierde (líquido de entrada y salida al evaporador, con escarcha a la salida), tuercas
de racor hexagonales, cuerpo de latón con aristas, cabeza con el reborde engatillado del diafragma
y la soldadura del capilar, brillo del capilar y del igualador, tuerca de abocardado del igualador,
caperuza de ajuste con su tornillo, y bulbo sujeto con abrazaderas a un tramo escarchado de la
aspiración."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ve_laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6dc8e"/><stop offset="0.45" stop-color="#c49a3a"/><stop offset="1" stop-color="#7a5a1c"/></linearGradient>
<linearGradient id="ve_latonH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a5a1c"/><stop offset="0.4" stop-color="#f6dc8e"/><stop offset="1" stop-color="#7a5a1c"/></linearGradient>
<linearGradient id="ve_brillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.15"/></linearGradient>
'''

d = []
a = d.append


def tubo_recto(ruta, w, color):
    horizontal = "H" in ruta
    sombra = "translate(0,%.1f)" % (w * 0.28) if horizontal else "translate(%.1f,0)" % (w * 0.28)
    luz = "translate(0,-%.1f)" % (w * 0.24) if horizontal else "translate(-%.1f,0)" % (w * 0.24)
    return (f'<path d="{ruta}" stroke="{color}" stroke-width="{w}"/>'
            f'<path d="{ruta}" stroke="#000" stroke-opacity="0.28" stroke-width="{w * 0.42:.1f}" transform="{sombra}"/>'
            f'<path d="{ruta}" stroke="#fff" stroke-opacity="0.38" stroke-width="{max(1.2, w * 0.16):.1f}" transform="{luz}"/>')


def escarcha_recta(ruta, ancho, x, y, w, h):
    return (f'<path d="{ruta}" stroke="#dff3ff" stroke-width="{ancho}" opacity="0.35"/>'
            f'<g filter="url(#am_escarcha)" opacity="0.9"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none"/>'
            f'<path d="{ruta}" stroke="#fff" stroke-width="{ancho}"/></g>')


def tuerca(x, y, w, h, vertical=False):
    """Tuerca de racor vista de lado: tres caras con luz en la central."""
    if vertical:
        s = f'<rect x="{x - w / 2}" y="{y - h / 2}" width="{w}" height="{h}" rx="1.5" fill="url(#ve_latonH)" stroke="#5a4210" stroke-width="0.7"/>'
        s += f'<path d="M{x - w / 6:.1f},{y - h / 2} V{y + h / 2} M{x + w / 6:.1f},{y - h / 2} V{y + h / 2}" stroke="#6e5214" stroke-width="0.8"/>'
    else:
        s = f'<rect x="{x - w / 2}" y="{y - h / 2}" width="{w}" height="{h}" rx="1.5" fill="url(#ve_laton)" stroke="#5a4210" stroke-width="0.7"/>'
        s += f'<path d="M{x - w / 2},{y - h / 6:.1f} H{x + w / 2} M{x - w / 2},{y + h / 6:.1f} H{x + w / 2}" stroke="#6e5214" stroke-width="0.8"/>'
    return s


# Tuberías rectas: líquido templado a la entrada, mezcla fría y escarchada a la salida
a(tubo_recto("M10,190 H96", 16, "#e0a030"))
a(tubo_recto("M160,240 V312", 16, "#5aa0e0"))
a(escarcha_recta("M160,250 V312", 16, 152, 250, 16, 62))
# Tuerca del racor de entrada y de salida
a(tuerca(90, 191, 14, 34))
a(tuerca(160, 240, 34, 14, True))
# Cuerpo: aristas de fundición y brillo
a('<rect x="104" y="160" width="112" height="72" rx="10" fill="url(#ve_brillo)"/>')
a('<path d="M118,170 H202" stroke="#fff3c4" stroke-opacity="0.6" stroke-width="1.2"/>')
a('<path d="M106,214 H214" stroke="#5a4210" stroke-opacity="0.45" stroke-width="1"/>')
for x, y in ((114, 170), (206, 170), (114, 222), (206, 222)):
    a(P.perno(x, y, 2.6))

# Cabeza termostática: reborde engatillado del diafragma y cuello roscado
a('<ellipse cx="160" cy="110" rx="56" ry="16" fill="none" stroke="#6c7276" stroke-width="1.5" stroke-dasharray="1.4 1.1"/>')
a('<ellipse cx="160" cy="106" rx="40" ry="8" fill="#fff" opacity="0.25"/>')
a('<path d="M104,112 Q160,134 216,112" fill="none" stroke="#4a5054" stroke-width="1.2"/>')
for y in range(132, 160, 4):
    a(f'<path d="M128,{y} H192" stroke="#5f6568" stroke-width="0.8" opacity="0.7"/>')
a('<rect x="130" y="121" width="5" height="40" fill="#fff" opacity="0.3"/>')
# Soldadura del capilar en la cabeza
a('<circle cx="206" cy="104" r="4" fill="#c49a3a" stroke="#6e5214" stroke-width="0.8"/>')
a('<path d="M206,104 C262,92 280,120 270,170 C262,210 250,236 280,250" fill="none" stroke="#fff3c4" stroke-opacity="0.6" stroke-width="1" transform="translate(-0.8,-0.8)"/>')

# Igualador externo: brillo y tuercas de abocardado en los dos extremos
a('<path d="M120,150 C80,140 60,150 60,230 V290" fill="none" stroke="#fff" stroke-opacity="0.4" stroke-width="1.4" transform="translate(-1.2,-1)"/>')
a(tuerca(124, 151, 10, 14))
a(tuerca(60, 288, 16, 10, True))

# Caperuza del tornillo de ajuste: caras del hexágono, junta y tornillo con ranura
a('<path d="M216,192 H242 M216,200 H242" stroke="#3b4043" stroke-width="1"/>')
a('<rect x="216" y="184" width="26" height="4" fill="#fff" opacity="0.25"/>')
a('<rect x="212" y="186" width="5" height="20" rx="1" fill="#2a2e31"/>')
a('<rect x="242" y="190" width="7" height="12" rx="1.5" fill="url(#am_brida)"/>')
a('<path d="M245.5,191.5 V200.5" stroke="#2a2e31" stroke-width="1.6"/>')

# Aspiración escarchada bajo el bulbo y abrazaderas del bulbo
a(tubo_recto("M244,268 H320", 10, "#5aa0e0"))
a(escarcha_recta("M244,268 H320", 10, 244, 263, 76, 10))
a('<rect x="270" y="244" width="40" height="18" rx="9" fill="url(#ve_brillo)"/>')
for x in (278, 302):
    a(f'<rect x="{x - 2.5}" y="241" width="5" height="36" rx="1.5" fill="url(#am_brida)" stroke="#3b4043" stroke-width="0.5"/>')
    a(P.perno(x, 243, 2))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "valvula_expansion.svg"), "".join(d), P.DEFS + DEFS)
