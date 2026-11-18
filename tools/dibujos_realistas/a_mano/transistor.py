"""Transistor en cápsula TO-92 vista por el lado plano (400×220) sobre su SVG: epoxi negro mate con
granulado de molde, borde de la cara plana donde empieza el lomo redondo, marca de la colada en la
cúpula, escalón de asiento con su línea de partición, patas estañadas con su hombro y sombras de
contacto. Las patas se dibujan con las piezas de mosfet.py."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T

DEFS = '''
<linearGradient id="tr_cara" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#1c1e20"/><stop offset="0.08" stop-color="#34383b"/><stop offset="0.3" stop-color="#2c2f32"/>
 <stop offset="0.75" stop-color="#25282a"/><stop offset="0.93" stop-color="#2e3134"/><stop offset="1" stop-color="#141517"/></linearGradient>
<linearGradient id="tr_asiento" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#3a3e41"/><stop offset="0.2" stop-color="#25282a"/><stop offset="1" stop-color="#131416"/></linearGradient>
'''

CARA = "M166,50 A34,34 0 0 1 234,50 V106 H166 Z"
d = []
a = d.append
# Cuerpo: epoxi mate con granulado
a(f'<g filter="url(#to_epoxi)"><path d="{CARA}" fill="url(#tr_cara)"/></g>')
# Brillo difuso de la cúpula y del canto izquierdo
a('<path d="M170,52 A30,30 0 0 1 222,30" fill="none" stroke="#fff" stroke-width="2.4" opacity="0.13" stroke-linecap="round"/>')
a('<path d="M168.5,54 V88" stroke="#fff" stroke-width="1.6" opacity="0.1" stroke-linecap="round"/>')
# Borde de la cara plana: el lomo redondo asoma un poco por los lados y por arriba
a('<path d="M169,88 V50 A31,31 0 0 1 231,50 V88" fill="none" stroke="#000" stroke-width="0.8" opacity="0.55"/>')
a('<path d="M170.2,88 V50.5 A29.8,29.8 0 0 1 229.8,50.5 V88" fill="none" stroke="#5d6267" stroke-width="0.5" opacity="0.5"/>')
# Marca de la colada en lo alto de la cúpula
a('<rect x="195" y="16.6" width="10" height="2.6" rx="0.8" fill="#4a4f53" opacity="0.6" filter="url(#to_epoxi)"/>')
# Escalón de asiento con la línea de partición del molde
a('<g filter="url(#to_epoxi)"><rect x="166" y="90" width="68" height="16" fill="url(#tr_asiento)"/></g>')
a('<path d="M166,90.4 H234" stroke="#000" stroke-width="1" opacity="0.7"/>')
a('<path d="M166,91.6 H234" stroke="#fff" stroke-width="0.6" opacity="0.18"/>')
a('<path d="M166,105.4 H234" stroke="#000" stroke-width="1.2" opacity="0.6"/>')
a(f'<path d="{CARA}" fill="none" stroke="#0a0b0c" stroke-width="1.3"/>')
# Patas estañadas
a(T.patas(xs=(176, 200, 224), y0=106, y1=170, ancho=4, hombro=5.8, semilla=5))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "transistor.svg"), "".join(d), P.DEFS + T.DEFS_TO220 + DEFS)
