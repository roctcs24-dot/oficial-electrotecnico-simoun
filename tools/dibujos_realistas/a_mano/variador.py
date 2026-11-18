"""Variador de frecuencia de pared (320×420) sobre su SVG: disipador de aletas asomando por los lados,
rejilla de ventilación superior, tornillos de la carcasa, pantalla con retroiluminación y brillo de
cristal, teclado de membrana con sus símbolos, LED encendido y apagado, adhesivo de peligro, placa de
características, borneras de potencia y de mando con jaula y tornillo, separadores, y los cables del
motor y de mando entrando por sus prensaestopas. Las etiquetas de bornes y pantalla las pinta el juego."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="vf_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="vf_aleta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.5" stop-color="#d9dddf"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<linearGradient id="vf_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.46" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<radialGradient id="vf_luzlcd" cx="0.5" cy="0.5" r="0.7"><stop offset="0" stop-color="#3f8a5c" stop-opacity="0.55"/><stop offset="1" stop-color="#3f8a5c" stop-opacity="0"/></radialGradient>
<linearGradient id="vf_tecla" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6d747a"/><stop offset="0.25" stop-color="#4f565c"/><stop offset="1" stop-color="#363b40"/></linearGradient>
<linearGradient id="vf_borne" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2a2e32"/><stop offset="0.2" stop-color="#4c5359"/><stop offset="0.8" stop-color="#454c52"/><stop offset="1" stop-color="#25292c"/></linearGradient>
<linearGradient id="vf_jaula" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a7074"/><stop offset="0.5" stop-color="#e3e6e8"/><stop offset="1" stop-color="#7d8387"/></linearGradient>
<linearGradient id="vf_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
'''


def tornillo(x, y, r):
    """Tornillo de borne combinado (ranura y cruz) con su pozo oscuro y brillo."""
    return (f'<circle cx="{x}" cy="{y + 0.8}" r="{r + 2.2}" fill="#0b0d0f" opacity="0.8"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#vf_cabeza)" stroke="#2b3034" stroke-width="0.8"/>'
            f'<path d="M{x - r * 0.72},{y} H{x + r * 0.72} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
            f'<path d="M{x - r * 0.72},{y + r * 0.16} H{x + r * 0.72}" stroke="#fff" stroke-width="0.6" opacity="0.45"/>'
            f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')


def borne(x, y0, y1, ys, ancho=30):
    """Cuerpo de borne de jaula, pozo del tornillo en «ys» y boca de la jaula abajo."""
    s = f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0}" rx="2.5" fill="url(#vf_borne)" stroke="#16191c" stroke-width="0.8"/>'
    s += f'<rect x="{x - ancho / 2 + 1}" y="{y0 + 1}" width="{ancho - 2}" height="1.4" fill="#fff" opacity="0.18"/>'
    s += f'<rect x="{x - 8}" y="{y1 - 13}" width="16" height="9" rx="1.5" fill="#050607"/>'
    s += f'<rect x="{x - 7}" y="{y1 - 12}" width="14" height="3.4" fill="url(#vf_jaula)"/>'
    s += f'<rect x="{x - 7}" y="{y1 - 6.6}" width="14" height="1.4" fill="url(#vf_jaula)" opacity="0.7"/>'
    s += tornillo(x, ys, 7.6)
    return s


def cable(dd, color, ancho):
    return (f'<path d="{dd}" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="{ancho + 2}" stroke-linecap="round" transform="translate(1.2,1.6)"/>'
            f'<path d="{dd}" fill="none" stroke="{color}" stroke-width="{ancho}" stroke-linecap="round"/>'
            f'<path d="{dd}" fill="none" stroke="#fff" stroke-opacity="0.32" stroke-width="{max(0.8, ancho * 0.22):.1f}" stroke-linecap="round" transform="translate(-{ancho * 0.22:.1f},0)"/>')


def tierra(dd, ancho):
    return (cable(dd, "#2f9e4a", ancho)
            + f'<path d="{dd}" fill="none" stroke="#f2c200" stroke-width="{ancho}" stroke-dasharray="4 6"/>'
            + f'<path d="{dd}" fill="none" stroke="#fff" stroke-opacity="0.3" stroke-width="{ancho * 0.22:.1f}" transform="translate(-{ancho * 0.22:.1f},0)"/>')


def prensaestopas(x, y, r):
    s = f'<rect x="{x - r - 3}" y="{y - 2}" width="{2 * r + 6}" height="7" rx="1.5" fill="#1b1e21"/>'
    s += f'<polygon points="{x - r - 2},{y + 5} {x + r + 2},{y + 5} {x + r},{y + 13} {x - r},{y + 13}" fill="#2a2e32" stroke="#0e1012" stroke-width="0.8"/>'
    for i in range(1, 5):
        xx = x - r - 2 + i * (2 * r + 4) / 5
        s += f'<path d="M{xx:.1f},{y + 6} V{y + 12}" stroke="#4b5257" stroke-width="1.2"/>'
    s += f'<rect x="{x - r - 2}" y="{y + 5}" width="{2 * r + 4}" height="1.2" fill="#fff" opacity="0.2"/>'
    return s


d = []
a = d.append

# Disipador de aluminio asomando por detrás, con sus aletas a cada lado
for x0 in (21, 289):
    a(f'<rect x="{x0}" y="26" width="10" height="368" rx="2" fill="#3b4044"/>')
    for i in range(3):
        a(f'<rect x="{x0 + 1 + i * 3}" y="28" width="2.2" height="364" rx="1" fill="url(#vf_aleta)"/>')

# Rejilla de ventilación superior: ranuras con fondo oscuro y canto iluminado
a('<rect x="47" y="18" width="226" height="28" rx="4" fill="#9ea4a8"/>')
a('<rect x="47" y="18" width="226" height="28" rx="4" fill="none" stroke="#6d7377" stroke-width="1"/>')
for i in range(27):
    x = 52 + i * 8.1
    a(f'<rect x="{x:.1f}" y="21" width="4.4" height="22" rx="2.2" fill="#121518"/>')
    a(f'<rect x="{x + 4.4:.1f}" y="22" width="1" height="20" fill="#fff" opacity="0.5"/>')

# Tornillos de la carcasa en las esquinas
for x, y in ((40, 22), (280, 22), (40, 398), (280, 398)):
    a(f'<circle cx="{x}" cy="{y}" r="5.2" fill="#555b60"/>')
    a(f'<circle cx="{x}" cy="{y}" r="4.2" fill="url(#vf_cabeza)"/>')
    a(f'<path d="M{x - 2.6},{y} H{x + 2.6} M{x},{y - 2.6} V{y + 2.6}" stroke="#30353a" stroke-width="1.2"/>')

# Junta de la tapa de bornes retirada, entre la parte de mando y la de bornes
a('<path d="M32,229 H288" stroke="#5d6468" stroke-width="1.6"/><path d="M32,231 H288" stroke="#fff" stroke-width="1" opacity="0.6"/>')
a('<path d="M32,304 H288" stroke="#7d8387" stroke-width="1"/><path d="M32,305.5 H288" stroke="#fff" stroke-width="0.8" opacity="0.5"/>')

# Marco del panel de mando y pantalla: sombra interior, retroiluminación y brillo del cristal
a('<rect x="80" y="62" width="160" height="150" rx="8" fill="none" stroke="#5a6167" stroke-width="1.2"/>')
a('<rect x="89" y="71" width="142" height="78" rx="4" fill="#0f1215"/>')
a('<rect x="92" y="74" width="136" height="72" rx="3" fill="#1f3a2a"/>')
a('<rect x="92" y="74" width="136" height="72" rx="3" fill="url(#vf_luzlcd)"/>')
a('<rect x="92" y="74" width="136" height="6" fill="#000" opacity="0.35"/>')
# Iconos discretos de estado en la línea superior y barra de carga abajo (sin cifras)
a('<path d="M99,77.5 l6,3 l-6,3 z" fill="#9be0b0" opacity="0.9"/>')
a('<rect x="210" y="77.5" width="12" height="6" rx="1" fill="none" stroke="#9be0b0" stroke-width="0.9" opacity="0.8"/><rect x="211.5" y="79" width="7" height="3" fill="#9be0b0" opacity="0.8"/>')
for i in range(20):
    a(f'<rect x="{100 + i * 6}" y="136" width="4.4" height="5" fill="#9be0b0" opacity="{0.85 if i < 13 else 0.15}"/>')
a('<path d="M92,74 H228 V100 Q160,92 92,118 Z" fill="url(#vf_cristal)"/>')
a('<rect x="92" y="74" width="136" height="72" rx="3" fill="none" stroke="#000" stroke-width="1.2" opacity="0.6"/>')

# Teclas de membrana con relieve y sus símbolos
iconos = [
    '<path d="M{x},{y} m4,-5 l-8,5 l8,5 z" fill="#d6dbde"/>',            # izquierda
    '<rect x="{x}" y="{y}" width="0" height="0"/><circle cx="{x}" cy="{y}" r="4.6" fill="none" stroke="#d6dbde" stroke-width="1.6"/>',  # aceptar
    '<path d="M{x},{y} m-4,-5 l8,5 l-8,5 z" fill="#d6dbde"/>',            # derecha
    '<path d="M{x},{y} m-4,-6 l10,6 l-10,6 z" fill="#3fcf6e"/>',          # marcha
    '<rect x="{x}" y="{y}" width="10" height="10" transform="translate(-5,-5)" fill="#e0483a"/>',  # paro
    '<path d="M{x},{y} m5,0 a5,5 0 1 1 -2,-4" fill="none" stroke="#d6dbde" stroke-width="1.6"/><path d="M{x},{y} m3,-7 l1,4 l-4,0.5 z" fill="#d6dbde"/>',  # rearme
]
k = 0
for fila in (168, 200):
    for col in (98, 143, 188):
        a(f'<rect x="{col}" y="{fila}" width="34" height="24" rx="5" fill="url(#vf_tecla)" stroke="#15181b" stroke-width="1"/>')
        a(f'<rect x="{col + 3}" y="{fila + 2}" width="28" height="5" rx="2.5" fill="#fff" opacity="0.14"/>')
        a(f'<rect x="{col}" y="{fila + 23}" width="34" height="1.6" rx="0.8" fill="#000" opacity="0.6"/>')
        a(iconos[k].format(x=col + 17, y=fila + 12))
        k += 1

# LED de marcha encendido y de falta apagado
a('<circle cx="232" cy="180" r="13" fill="#2fe06a" opacity="0.22"/><circle cx="232" cy="180" r="9" fill="#2fe06a" opacity="0.25"/>')
a('<circle cx="232" cy="180" r="7" fill="none" stroke="#0e2a17" stroke-width="1"/><circle cx="232" cy="180" r="4" fill="#c8ffd8" opacity="0.8"/>')
a('<circle cx="232" cy="206" r="7" fill="#2a0a08" opacity="0.5"/><circle cx="232" cy="206" r="7" fill="none" stroke="#2a0b08" stroke-width="1"/>')
for cy in (180, 206):
    a(f'<ellipse cx="229.6" cy="{cy - 3}" rx="2.6" ry="1.4" fill="#fff" opacity="0.7"/>')

# Adhesivo de peligro de tensión y placa de características en el lateral izquierdo
a('<path d="M56,66 L73,96 H39 Z" fill="#f2c200" stroke="#1d1d1d" stroke-width="2.4" stroke-linejoin="round"/>')
a('<path d="M58,73 L51,84 H56 L53,92 L61,80 H56 Z" fill="#1d1d1d"/>')
a('<rect x="38" y="108" width="36" height="96" rx="2" fill="url(#am_placa)" stroke="#5c6266" stroke-width="0.8"/>')
for i in range(9):
    a(f'<rect x="42" y="{114 + i * 7}" width="{28 - (i % 3) * 5}" height="2.2" fill="#3a4044" opacity="0.65"/>')
for i in range(14):
    a(f'<rect x="{43 + i * 1.9:.1f}" y="180" width="{0.8 + (i * 7 % 3) * 0.5:.1f}" height="16" fill="#1d2124"/>')

# Borneras de potencia y de mando: bornes de jaula con separadores
for y0, y1, ys in ((252, 289, 264), (340, 385, 352)):
    for x in (72, 110, 148, 186, 224, 256):
        a(borne(x, y0, y1, ys, 30 if x != 256 else 26))
    for x in (91, 129, 167, 205, 240):
        a(f'<rect x="{x - 1.6}" y="{y0 - 3}" width="3.2" height="{y1 - y0 + 5}" rx="1" fill="#5c646a"/>')
        a(f'<rect x="{x - 1.6}" y="{y0 - 3}" width="1" height="{y1 - y0 + 5}" fill="#fff" opacity="0.3"/>')

# Placa pasacables inferior con dos prensaestopas
a('<rect x="52" y="396" width="216" height="13" rx="2" fill="#80878c"/>')

# Cables del motor (U, V, W y PE) y de mando (DI1 y +24 V)
for x, color in ((72, "#6b3f20"), (110, "#1d1e20"), (148, "#7f8488")):
    a(cable(f"M{x},382 V388 Q{x},398 {118 + (x - 110) * 0.18:.1f},404", color, 5))
a(tierra("M186,382 V388 Q186,398 128,404", 5))
a(cable("M224,382 V390 Q224,398 237,404", "#24418f", 3))
a(cable("M256,382 V390 Q256,398 243,404", "#24418f", 3))
a('<rect x="104" y="412" width="28" height="8" fill="#16181a"/><rect x="108" y="412" width="5" height="8" fill="#fff" opacity="0.15"/>')
a('<rect x="234" y="412" width="12" height="8" fill="#26292c"/>')
a(prensaestopas(118, 400, 13))
a(prensaestopas(240, 400, 8))
# Punteras de las cabezas de cable dentro de la jaula
for x in (72, 110, 148, 186, 224, 256):
    a(f'<rect x="{x - 3.2}" y="376" width="6.4" height="7" rx="1" fill="url(#vf_jaula)"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "variador.svg"), "".join(d), P.DEFS + DEFS)
