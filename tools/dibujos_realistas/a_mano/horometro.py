"""Horómetro de cuadro (280×260) sobre su SVG: marco con tornillos, ventana del contador con
bisel cromado, rodillos con curvatura y separadores, cristal con reflejo, indicador de marcha en
relieve, tabique entre bornes, arandelas y cables de mando con terminal de ojo y manguito."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ho_rodillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.85"/><stop offset="0.28" stop-color="#000" stop-opacity="0.05"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.10"/><stop offset="0.72" stop-color="#000" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.85"/></linearGradient>
<linearGradient id="ho_cromo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f4f6f7"/><stop offset="0.45" stop-color="#8d9498"/><stop offset="0.55" stop-color="#5d6367"/><stop offset="1" stop-color="#c9ced1"/></linearGradient>
<linearGradient id="ho_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.03"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="ho_estano" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.5" stop-color="#eef0f1"/><stop offset="1" stop-color="#6d7377"/></linearGradient>
<linearGradient id="ho_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#050607"/><stop offset="0.4" stop-color="#3d4247"/><stop offset="1" stop-color="#08090a"/></linearGradient>
'''

d = []
a = d.append
# Tornillos del marco frontal
for x, y in ((50, 20), (230, 20), (50, 160), (230, 160)):
    a(f'<circle cx="{x}" cy="{y}" r="4.4" fill="#0b0c0d"/><circle cx="{x}" cy="{y}" r="3.6" fill="url(#am_acero)"/>'
      f'<path d="M{x - 2.2},{y} H{x + 2.2} M{x},{y - 2.2} V{y + 2.2}" stroke="#2a2e31" stroke-width="1.2" stroke-linecap="round"/>')
a('<path d="M48,11.5 H232" stroke="#fff" stroke-opacity="0.2" stroke-width="1.5"/>')
# Bisel cromado de la ventana del contador
a('<rect x="54" y="62" width="172" height="52" rx="5" fill="none" stroke="url(#ho_cromo)" stroke-width="4"/>')
a('<rect x="57" y="65" width="166" height="46" rx="3" fill="none" stroke="#050607" stroke-width="1.5"/>')
# Rodillos: separadores con su eje y curvatura de cada rodillo
# Cinco rodillos de horas y uno rojo de décimas, como las 12408,6 h de la simulación.
for x in (85, 112, 140, 167, 195):
    a(f'<rect x="{x - 2.5}" y="66" width="5" height="44" fill="#1b1e21"/><rect x="{x - 2.5}" y="66" width="1.2" height="44" fill="#fff" opacity="0.15"/>')
a('<rect x="58" y="66" width="164" height="44" rx="3" fill="url(#ho_rodillo)"/>')
# Cristal de la ventana
a('<rect x="58" y="66" width="164" height="44" rx="3" fill="url(#ho_cristal)"/>')
a('<path d="M58,92 L88,66 H104 L66,110 H58 Z" fill="#fff" opacity="0.10"/>')
# Indicador de marcha (reloj de arena) en relieve, con su ventanilla
a('<circle cx="140" cy="137" r="14" fill="#15181b"/><circle cx="140" cy="137" r="14" fill="none" stroke="#5a6064" stroke-width="1.2"/>')
a('<path d="M132,128 H148 L136,146 H148 L132,128 Z" fill="#d9dcde" opacity="0.18"/>')
a('<path d="M132,128 H148 L136,146 H148 L132,128 Z" fill="none" stroke="#e8ebec" stroke-width="2.2" stroke-linejoin="round"/>')
a('<path d="M130,129 A12,12 0 0 1 150,128" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2" fill="none"/>')
# Regleta: tabique entre bornes, nervios y arandelas
a('<path d="M72,181.5 H208" stroke="#fff" stroke-opacity="0.18" stroke-width="1.2"/>')
a('<rect x="136" y="184" width="8" height="56" rx="2" fill="#24282b"/><rect x="136" y="184" width="2" height="56" fill="#fff" opacity="0.12"/>')
for x in (110, 170):
    a(f'<circle cx="{x}" cy="212" r="11.6" fill="none" stroke="#9aa1a5" stroke-width="2.4"/>')
    # Terminal de ojo estañado hacia abajo, manguito rojo y cable de mando
    a(f'<path d="M{x - 4.5},223 H{x + 4.5} V236 H{x - 4.5} Z" fill="url(#ho_estano)" stroke="#4a5054" stroke-width="0.6"/>')
    a(f'<rect x="{x - 5.5}" y="234" width="11" height="10" rx="2" fill="#c03228" stroke="#6a1a12" stroke-width="0.5"/>')
    a(f'<rect x="{x - 3.25}" y="244" width="6.5" height="16" fill="url(#ho_cable)"/>')
    a(f'<path d="M{x - 1.4},244 V260" stroke="#fff" stroke-opacity="0.2" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "horometro.svg"), "".join(d), P.DEFS + DEFS)
