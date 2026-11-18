"""Fuente conmutada de carril DIN (400×220) sobre su SVG: caja de chapa de aluminio cepillado con el
canto doblado y tornillos avellanados, rejilla de ventilación troquelada con el fondo oscuro, regletas
de bornes con tabiques entre bornes, entradas de cable y alojamiento de cada tornillo, LED DC OK
encendido con su halo, y potenciómetro V ADJ hundido con su ranura."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="fc_canto" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.1" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.9" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="fc_ranura" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#050607"/><stop offset="0.6" stop-color="#1f2326"/><stop offset="1" stop-color="#3b4145"/></linearGradient>
<linearGradient id="fc_regleta" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.16"/><stop offset="0.2" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.8" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="fc_tabique" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#5a6066"/><stop offset="0.4" stop-color="#3a3f44"/><stop offset="1" stop-color="#15181a"/></linearGradient>
<radialGradient id="fc_halo" cx="0.5" cy="0.5" r="0.5">
 <stop offset="0" stop-color="#7dff9e" stop-opacity="0.75"/><stop offset="0.45" stop-color="#3ee06a" stop-opacity="0.3"/><stop offset="1" stop-color="#3ee06a" stop-opacity="0"/></radialGradient>
<radialGradient id="fc_led" cx="0.4" cy="0.35" r="0.65">
 <stop offset="0" stop-color="#eaffef"/><stop offset="0.35" stop-color="#6cf08f"/><stop offset="1" stop-color="#1c9a45"/></radialGradient>
<radialGradient id="fc_hueco" cx="0.5" cy="0.5" r="0.5">
 <stop offset="0.75" stop-color="#000" stop-opacity="0.55"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
'''

d = []
a = d.append
# Chapa cepillada, canto doblado y tornillos avellanados de la tapa
a('<rect x="81" y="21" width="238" height="178" rx="5.5" fill="#c3c9cd" opacity="0.4" filter="url(#cepillado)"/>')
a('<rect x="80" y="20" width="240" height="180" rx="6" fill="url(#fc_canto)"/>')
a('<rect x="83" y="23" width="234" height="174" rx="4" fill="none" stroke="#fff" stroke-width="0.8" opacity="0.5"/>')
for x in (88, 312):
    a(f'<circle cx="{x}" cy="110" r="3.6" fill="url(#am_acero)" stroke="#4f5558" stroke-width="0.6"/>')
    a(f'<path d="M{x - 2},110 H{x + 2} M{x},108 V112" stroke="#30363a" stroke-width="0.9"/>')
# Rejilla troquelada: ranuras con el fondo oscuro, filo de luz abajo
for y in (70, 80, 90, 100):
    a(f'<rect x="100" y="{y - 2.6}" width="200" height="5.2" rx="2.6" fill="url(#fc_ranura)"/>')
    a(f'<path d="M102,{y + 3.3} H298" stroke="#fff" stroke-width="0.8" opacity="0.7"/>')
    a(f'<path d="M102,{y - 3.2} H298" stroke="#5b6267" stroke-width="0.6" opacity="0.6"/>')
# Regletas: brillo, tabiques entre bornes, entradas de cable y alojamiento de los tornillos
for y0, xs, tabiques, entrada in ((26, (130, 170, 230, 270), (110, 150, 190, 210, 250, 290), 27.5),
                                  (158, (130, 170, 210), (110, 150, 190, 230), 187.5)):
    a(f'<rect x="96" y="{y0}" width="208" height="36" rx="3" fill="url(#fc_regleta)"/>')
    for x in tabiques:
        a(f'<rect x="{x - 2}" y="{y0 + 1}" width="4" height="34" rx="1" fill="url(#fc_tabique)"/>')
        a(f'<path d="M{x - 1.4},{y0 + 2} V{y0 + 34}" stroke="#fff" stroke-width="0.6" opacity="0.25"/>')
    for x in xs:
        a(f'<rect x="{x - 6}" y="{entrada}" width="12" height="5" rx="1" fill="#050607"/>')
        a(f'<rect x="{x - 4.5}" y="{entrada + 1}" width="9" height="1.4" fill="#9aa1a6" opacity="0.5"/>')
        yc = y0 + 18
        a(f'<circle cx="{x}" cy="{yc}" r="11.5" fill="url(#fc_hueco)"/>')
# LED DC OK encendido
a('<circle cx="200" cy="130" r="20" fill="url(#fc_halo)"/>')
a('<circle cx="200" cy="130" r="10.5" fill="none" stroke="#3b4246" stroke-width="1.4"/>')
a('<circle cx="200" cy="130" r="8.4" fill="url(#fc_led)"/>')
a('<ellipse cx="197" cy="126.5" rx="3.4" ry="2" fill="#fff" opacity="0.8"/>')
# Potenciómetro V ADJ hundido con su ranura
a('<circle cx="270" cy="130" r="11.5" fill="none" stroke="#3b4246" stroke-width="2"/>')
a('<circle cx="270" cy="130" r="12.6" fill="none" stroke="#fff" stroke-width="0.8" opacity="0.6"/>')
a('<path d="M264,130 H276" stroke="#20242a" stroke-width="2.4" stroke-linecap="round"/>')
a('<path d="M264.5,131.6 H275.5" stroke="#fff" stroke-width="0.6" opacity="0.7"/>')
a('<path d="M263,125 A8,8 0 0 1 271,122.2" fill="none" stroke="#fff" stroke-width="1" opacity="0.8" stroke-linecap="round"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "fuente_conmutada.svg"), "".join(d), P.DEFS + DEFS)
