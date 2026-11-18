"""Controlador del generador (420×340) sobre su SVG: junta de goma del frente, membrana impresa con
sus grupos de teclas, pantalla con retroiluminación, matriz de puntos y reflejo del cristal, LED de
estado con lente (solo READY encendido, como en «Loaded»), LED de las teclas del interruptor, canto
con luz en cada tecla y puerto USB con tapa. Sin texto propio: las medidas las pone el juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<pattern id="cg_matriz" width="2.2" height="2.2" patternUnits="userSpaceOnUse"><rect width="2.2" height="2.2" fill="none"/><path d="M0,2.1 H2.2 M2.1,0 V2.2" stroke="#0d1a0b" stroke-width="0.35"/></pattern>
<radialGradient id="cg_luz" cx="0.5" cy="0.45" r="0.7"><stop offset="0" stop-color="#e9ffd9" stop-opacity="0.35"/><stop offset="0.7" stop-color="#e9ffd9" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.18"/></radialGradient>
<linearGradient id="cg_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.28" stop-color="#fff" stop-opacity="0.06"/><stop offset="0.29" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<radialGradient id="cg_verde" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#8dffa6" stop-opacity="0.75"/><stop offset="0.5" stop-color="#3fbf5a" stop-opacity="0.25"/><stop offset="1" stop-color="#3fbf5a" stop-opacity="0"/></radialGradient>
<linearGradient id="cg_canto" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.28"/><stop offset="0.25" stop-color="#fff" stop-opacity="0"/><stop offset="0.8" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
'''

d = []
a = d.append

# Junta de goma del frente y canto superior con luz
a('<rect x="16.5" y="16.5" width="387" height="307" rx="10" fill="none" stroke="#0b0c0d" stroke-width="2.4"/>')
a('<path d="M28,22.5 H392" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')
# Membrana impresa: recuadros de los grupos de teclas
a('<rect x="280" y="38" width="116" height="132" rx="6" fill="none" stroke="#9aa3a8" stroke-opacity="0.35" stroke-width="1"/>')
a('<rect x="34" y="204" width="362" height="100" rx="8" fill="none" stroke="#9aa3a8" stroke-opacity="0.35" stroke-width="1"/>')
a('<path d="M164,212 V296 M310,212 V296" stroke="#9aa3a8" stroke-opacity="0.25" stroke-width="1"/>')

# Pantalla: luz de fondo, matriz de puntos, sombra interior del bisel y reflejo
a('<rect x="44" y="46" width="220" height="116" rx="3" fill="url(#cg_luz)"/>')
a('<rect x="44" y="46" width="220" height="116" rx="3" fill="url(#cg_matriz)" opacity="0.18"/>')
a('<rect x="44.5" y="46.5" width="219" height="115" rx="3" fill="none" stroke="#000" stroke-opacity="0.35" stroke-width="2.5"/>')
a('<path d="M44,46 H264 L250,74 Q160,58 44,82 Z" fill="url(#cg_cristal)"/>')
a('<path d="M38,39.5 H270" stroke="#fff" stroke-opacity="0.18" stroke-width="1"/>')

# LED de estado: ALARM y WARN apagados, READY encendido
for y in (56, 82):
    a(f'<circle cx="296" cy="{y}" r="7" fill="#000" opacity="0.45"/>')
a('<circle cx="296" cy="108" r="15" fill="url(#cg_verde)"/>')
a('<circle cx="296" cy="108" r="4" fill="#b8ffc6" opacity="0.6"/>')
for y in (56, 82, 108):
    a(f'<circle cx="296" cy="{y}" r="8.2" fill="none" stroke="#15171a" stroke-width="2"/>')
    a(f'<ellipse cx="294.2" cy="{y - 2.4}" rx="2.6" ry="1.6" fill="#fff" opacity="0.7"/>')

# Canto con luz y sombra de cada tecla de membrana
for x, y, w, h, rx in ((353, 47, 34, 30, 5), (353, 85, 34, 30, 5), (353, 124, 34, 30, 5), (287, 132, 44, 30, 5),
                       (180, 224, 52, 44, 6), (246, 224, 52, 44, 6), (320, 224, 64, 44, 6)):
    a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="url(#cg_canto)"/>')
    a(f'<rect x="{x + 0.5}" y="{y + 0.5}" width="{w - 1}" height="{h - 1}" rx="{rx}" fill="none" stroke="#000" stroke-opacity="0.4" stroke-width="1"/>')
# Raya de la tecla GB OFF: el relieve automático la pierde (es una línea sin alto)
a('<path d="M262,246 H282" stroke="#d8dcd8" stroke-width="3" stroke-linecap="round"/>')
# Pulsadores START y STOP: aro y brillo de la cúpula
for cx in (64, 134):
    a(f'<circle cx="{cx}" cy="246" r="23.5" fill="none" stroke="#2c3035" stroke-width="2.5"/>')
    a(f'<circle cx="{cx}" cy="246" r="21" fill="none" stroke="#000" stroke-opacity="0.3" stroke-width="1.2"/>')
    a(f'<path d="M{cx - 14},236 A17,17 0 0 1 {cx + 10},231" fill="none" stroke="#fff" stroke-opacity="0.45" stroke-width="3" stroke-linecap="round"/>')
# LED de las teclas del interruptor: GB cerrado (verde encendido), apertura apagado
a('<circle cx="225" cy="231" r="7" fill="url(#cg_verde)"/>')
a('<circle cx="225" cy="231" r="2.4" fill="#5fe07a"/><circle cx="291" cy="231" r="2.4" fill="#3a1b17"/>')
for x in (225, 291):
    a(f'<circle cx="{x}" cy="231" r="2.9" fill="none" stroke="#15171a" stroke-width="0.8"/>')

# Puerto USB de servicio con su tapa de goma
a('<rect x="366" y="307" width="24" height="10" rx="3" fill="#15171a"/>')
a('<rect x="369" y="309" width="18" height="6" rx="2" fill="#22262a"/>')
a('<path d="M371,311 H385" stroke="#3e4348" stroke-width="1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "controlador_generador.svg"), "".join(d), P.DEFS + DEFS)
