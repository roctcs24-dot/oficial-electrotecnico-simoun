"""Sincronoscopio de cuadro y lámparas (360×440) sobre su SVG: tornillos de fijación del marco,
aro del bisel, escala fina, sombra de la aguja sobre la esfera, tapón central con su tornillo,
cristal con reflejo, tornillo de ajuste del cero, placa de las lámparas con tornillos y lentes
facetadas con aro moleteado."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="sy_cristal" cx="0.3" cy="0.22" r="0.9"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.35" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/></radialGradient>
<linearGradient id="sy_aro" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e9ecee"/><stop offset="0.5" stop-color="#7f8689"/><stop offset="1" stop-color="#3e4447"/></linearGradient>
<radialGradient id="sy_lente" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#fff3c4" stop-opacity="0.35"/><stop offset="0.5" stop-color="#d9b85a" stop-opacity="0.08"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></radialGradient>
'''

d = []
a = d.append
C = (180, 166)


def tornillo_ranura(x, y, r, ang=30):
    t = math.radians(ang)
    dx, dy = r * 0.65 * math.cos(t), r * 0.65 * math.sin(t)
    return (f'<circle cx="{x}" cy="{y}" r="{r + 0.8}" fill="#121416"/><circle cx="{x}" cy="{y}" r="{r}" fill="url(#am_acero)"/>'
            f'<path d="M{x - dx:.1f},{y - dy:.1f} L{x + dx:.1f},{y + dy:.1f}" stroke="#2c3033" stroke-width="{r * 0.32:.1f}" stroke-linecap="round"/>')


# Marco: canto con luz y tornillos de fijación al cuadro
a('<rect x="30.5" y="16.5" width="299" height="299" rx="10" fill="none" stroke="#fff" stroke-opacity="0.18" stroke-width="1"/>')
for (x, y), ang in zip(((50, 36), (310, 36), (50, 296), (310, 296)), (20, 70, 110, 160)):
    a(tornillo_ranura(x, y, 6, ang))
# Bisel metálico con canto interior oscuro
a(f'<circle cx="{C[0]}" cy="{C[1]}" r="122" fill="none" stroke="url(#sy_aro)" stroke-width="4"/>')
a(f'<circle cx="{C[0]}" cy="{C[1]}" r="118.5" fill="none" stroke="#000" stroke-opacity="0.6" stroke-width="2"/>')

# Escala fina fuera de la zona de las flechas FAST y SLOW
for i in range(36):
    g = i * 10
    if g % 30 == 0 or 120 < g < 240:
        continue
    t = math.radians(g - 90)
    a(f'<path d="M{C[0] + 100 * math.cos(t):.1f},{C[1] + 100 * math.sin(t):.1f} L{C[0] + 108 * math.cos(t):.1f},{C[1] + 108 * math.sin(t):.1f}" stroke="#c9ccc8" stroke-width="1.4" stroke-linecap="round"/>')
# Bordes de la ventana de cierre
for g in (-10, 10):
    t = math.radians(g - 90)
    a(f'<path d="M{C[0] + 86 * math.cos(t):.1f},{C[1] + 86 * math.sin(t):.1f} L{C[0] + 108 * math.cos(t):.1f},{C[1] + 108 * math.sin(t):.1f}" stroke="#7fe0a2" stroke-width="1.6"/>')

# Sombra de la aguja sobre la esfera
a('<path d="M186,169 L158,75 M186,169 L192,189" stroke="#000" stroke-opacity="0.45" stroke-width="5" stroke-linecap="round" filter="url(#desenfoque)"/>')
# Contrapeso y tapón central con su tornillo
a('<circle cx="185" cy="183" r="5.5" fill="#d9a63a"/>')
a('<circle cx="180" cy="166" r="9" fill="url(#am_acero)"/>')
a('<circle cx="180" cy="166" r="3.4" fill="#5f6568"/><path d="M177.6,166 H182.4" stroke="#22262a" stroke-width="1.2"/>')
# Cristal: reflejo grande arriba a la izquierda y brillo de canto abajo
a(f'<circle cx="{C[0]}" cy="{C[1]}" r="117" fill="url(#sy_cristal)"/>')
a('<path d="M86,110 A108,108 0 0 1 150,62" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="3" stroke-linecap="round"/>')
a('<path d="M246,250 A108,108 0 0 1 214,268" fill="none" stroke="#fff" stroke-opacity="0.18" stroke-width="2" stroke-linecap="round"/>')
# Tornillo de ajuste del cero bajo la esfera
a(tornillo_ranura(180, 282, 3.6, 0))

# Placa de las lámparas: tornillos y canto con luz
a('<path d="M38,331 H322" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')
for x, y in ((44, 344), (316, 344), (44, 412), (316, 412)):
    a(tornillo_ranura(x, y, 4, 45))
# Portalámparas: aro moleteado, lente facetada y brillo
for cx in (100, 180, 260):
    a(f'<circle cx="{cx}" cy="370" r="22.5" fill="none" stroke="#5f6568" stroke-width="2.6" stroke-dasharray="1.6 1.3"/>')
    a(f'<circle cx="{cx}" cy="370" r="19" fill="url(#sy_lente)"/>')
    for r in (6, 11, 15.5):
        a(f'<circle cx="{cx}" cy="370" r="{r}" fill="none" stroke="#fff3c4" stroke-opacity="0.16" stroke-width="1.2"/>')
    a(f'<circle cx="{cx}" cy="370" r="2.5" fill="#fff3c4" opacity="0.18"/>')
    a(f'<ellipse cx="{cx - 7}" cy="362" rx="6" ry="3.2" fill="#fff" opacity="0.5" transform="rotate(-35 {cx - 7} 362)"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "sincronoscopio.svg"), "".join(d), P.DEFS + DEFS)
