"""Transmisor de presión (260×380) sobre su SVG: cable que el relieve automático pierde por ser un
tramo recto, con su manguito de alivio, conector con nervios y tornillo, tuerca moleteada con
brillo, cuerpo de acero inoxidable con reflejo y costuras, borde y separadores de la etiqueta,
hexágono con sus caras, arandela de estanqueidad y rosca helicoidal. Los bornes + y − del Taller
(100, 350) y (160, 350) quedan despejados."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="tp_inox" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.28" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.36" stop-color="#fff" stop-opacity="0"/><stop offset="0.85" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/></linearGradient>
<linearGradient id="tp_cara" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.1"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/></linearGradient>
'''

d = []
a = d.append

# Cable: tramo recto dibujado aquí (el relieve automático lo pierde), manguito de alivio
a('<path d="M130,2 V22" stroke="#15171a" stroke-width="12"/>')
a('<path d="M127,2 V22" stroke="#5a6064" stroke-width="2"/>')
a('<path d="M133.5,2 V22" stroke="#000" stroke-opacity="0.5" stroke-width="2"/>')
a('<path d="M121,8 H139 L141,18 H119 Z" fill="#202326"/>')
for y in (10, 13, 16):
    a(f'<path d="M121,{y} H139" stroke="#3a3e42" stroke-width="0.8"/>')
# Conector: nervios de agarre, tornillo de cierre y canto con luz
for x in range(134, 154, 4):
    a(f'<path d="M{x},24 V46" stroke="#2a2e31" stroke-width="1.6"/>')
    a(f'<path d="M{x + 1.2},24 V46" stroke="#fff" stroke-opacity="0.1" stroke-width="0.7"/>')
a('<circle cx="117" cy="35" r="4.4" fill="url(#am_acero)" stroke="#1c1e20" stroke-width="0.8"/>')
a('<path d="M114.4,35 H119.6" stroke="#2c3033" stroke-width="1.2"/>')
# Tuerca moleteada: brillo y sombra de los cantos
a('<rect x="99" y="51" width="62" height="5" rx="2" fill="#fff" opacity="0.35"/>')
a('<rect x="99" y="64" width="62" height="5" rx="2" fill="#000" opacity="0.18"/>')

# Cuerpo de acero inoxidable: reflejo vertical, anillo superior y costura de la base
a('<rect x="80" y="70" width="100" height="200" rx="14" fill="url(#tp_inox)"/>')
a('<path d="M84,78 H176" stroke="#5f6568" stroke-width="1.2"/>')
a('<path d="M84,80 H176" stroke="#fff" stroke-opacity="0.5" stroke-width="0.8"/>')
a('<path d="M84,258 H176" stroke="#5f6568" stroke-width="1.6"/>')
a('<path d="M84,258 H176" stroke="#e1e4e5" stroke-width="0.8" stroke-dasharray="1.4 1"/>')
# Etiqueta: borde, separadores entre líneas y franja inferior
a('<rect x="96" y="112" width="68" height="106" rx="3" fill="none" stroke="#5f6568" stroke-width="0.8"/>')
for y in (141, 166, 190):
    a(f'<path d="M104,{y} H156" stroke="#9aa1a5" stroke-width="0.6"/>')
a('<rect x="96" y="210" width="68" height="8" fill="#2f6fb0" opacity="0.85"/>')
a('<path d="M96,112 L164,112" stroke="#fff" stroke-width="0.8" opacity="0.8"/>')

# Hexágono: caras y brillo de la central
a('<path d="M104,270 V310 M156,270 V310" stroke="#5f6568" stroke-width="1"/>')
a('<rect x="104" y="270" width="52" height="40" fill="url(#tp_cara)"/>')
a('<path d="M90,271 H170" stroke="#fff" stroke-opacity="0.45" stroke-width="1"/>')
# Arandela de estanqueidad y rosca helicoidal de proceso
a('<rect x="104" y="309" width="52" height="5" rx="1.5" fill="#2e3236"/>')
for y in range(316, 350, 4):
    a(f'<path d="M108,{y + 2} L152,{y}" stroke="#6b7378" stroke-width="1.4"/>')
    a(f'<path d="M108,{y + 3.2} L152,{y + 1.2}" stroke="#fff" stroke-opacity="0.35" stroke-width="0.7"/>')
a('<rect x="108" y="314" width="9" height="36" fill="#fff" opacity="0.15"/>')
a('<path d="M108,349.5 H152" stroke="#5f6568" stroke-width="1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "transmisor_presion.svg"), "".join(d), P.DEFS + DEFS)
