"""Tanque hidróforo con presostato de la mesa del Taller (260×320) sobre su SVG: virola con la luz
de un cilindro, costuras de soldadura de los fondos, manómetro, patas soldadas, toma de agua con
brida y válvula, presostato con tapa atornillada y tornillo de ajuste, cable con prensaestopas
hasta la regleta de baquelita de los bornes 13 y 14."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="thf_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="thf_virola" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.18" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.42" stop-color="#fff" stop-opacity="0.04"/><stop offset="0.8" stop-color="#000" stop-opacity="0.18"/><stop offset="1" stop-color="#000" stop-opacity="0.55"/></linearGradient>
<linearGradient id="thf_baquelita" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3d40"/><stop offset="1" stop-color="#141516"/></linearGradient>
<linearGradient id="thf_presostato" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6a6f73"/><stop offset="1" stop-color="#2c3033"/></linearGradient>
<linearGradient id="thf_tuboH" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a5054"/><stop offset="0.35" stop-color="#c9ced1"/><stop offset="1" stop-color="#3a3f43"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.3}" fill="#0c0d0e"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#thf_acero)"/></g>'
    l = r * 0.6
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#2a2e31" stroke-width="{r * 0.24:.1f}" stroke-linecap="round"/>'
    return t


# Patas soldadas del tanque, detrás de la virola visible
for x in (58, 202):
    a(f'<path d="M{x - 4},228 L{x - 8},282 H{x + 8} L{x + 4},228 Z" fill="#22394b" stroke="#12202b" stroke-width="1"/>')
    a(f'<rect x="{x - 12}" y="280" width="24" height="5" rx="1.5" fill="#2c3238"/>')
    a(P.perno(x, 282.5, 2.4))
# Virola: luz de cilindro, costuras de los fondos y reflejo
a('<rect x="50" y="40" width="160" height="220" rx="70" fill="url(#thf_virola)"/>')
for y in (104, 196):
    a(f'<path d="M51,{y} H209" stroke="#12202b" stroke-width="2.4"/>')
    a(f'<path d="M51,{y + 1.6} H209" stroke="#7fa2bd" stroke-opacity="0.45" stroke-width="1"/>')
a('<path d="M92,58 Q86,150 92,242" fill="none" stroke="#fff" stroke-opacity="0.25" stroke-width="5" stroke-linecap="round"/>')
# Manómetro de la línea de agua a un lado del tanque
a('<path d="M41,104 H52" stroke="#9aa0a3" stroke-width="3"/>')
a(P.manometro(30, 104, 11, 0.42))
# Toma de agua por el costado: tubo, brida y válvula de bola con su palanca
a('<rect x="6" y="213" width="50" height="14" fill="url(#thf_tuboH)"/>')
a(P.brida(40, 220, 14))
a('<g filter="url(#bisel)"><rect x="14" y="211" width="16" height="18" rx="3" fill="#b88a2e"/></g>')
a('<rect x="20" y="203" width="4" height="9" fill="#5a6064"/><rect x="20" y="201" width="26" height="4" rx="2" fill="#c0392b"/>')

# Presostato: tapa con tornillos, rejilla, tornillo de ajuste y prensaestopas
a('<rect x="96" y="14" width="68" height="34" rx="4" fill="url(#thf_presostato)"/>')
for x, y in ((101, 19), (159, 19), (101, 43), (159, 43)):
    a(tornillo(x, y, 2.6, 30))
a('<circle cx="130" cy="31" r="14" fill="#1a1c1e"/>')
a('<g filter="url(#bisel)"><circle cx="130" cy="31" r="12" fill="url(#cromo)"/></g>')
for i in range(12):
    ang = math.radians(i * 30)
    a(f'<path d="M{130 + 9 * math.cos(ang):.1f},{31 + 9 * math.sin(ang):.1f} L{130 + 11.6 * math.cos(ang):.1f},{31 + 11.6 * math.sin(ang):.1f}" stroke="#5f6568" stroke-width="1"/>')
a('<path d="M124,31 H136" stroke="#2a2e31" stroke-width="2.6" stroke-linecap="round"/>')
a('<path d="M130,48 V56" stroke="#9aa0a3" stroke-width="5"/>')
a('<g filter="url(#bisel)"><rect x="164" y="25" width="10" height="12" rx="2" fill="#5a6064"/></g>')
# Cable del presostato hasta la regleta
CABLE = "M174,31 H232 Q242,31 242,41 V280 Q242,290 232,290 H198"
a(f'<path d="{CABLE}" fill="none" stroke="#0e1012" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>')
a(f'<path d="{CABLE}" fill="none" stroke="#fff" stroke-opacity="0.22" stroke-width="1.4" transform="translate(-1,-1)"/>')
for y in (70, 150, 230):
    a(f'<rect x="237" y="{y}" width="10" height="4" rx="1" fill="#c9ced1"/>')

# Regleta de baquelita de los contactos 13 y 14 con arandelas
a('<rect x="66" y="274" width="132" height="32" rx="4" fill="url(#thf_baquelita)" stroke="#0a0b0c" stroke-width="1"/>')
a('<rect x="66" y="274" width="132" height="1.6" fill="#fff" opacity="0.15"/>')
a('<g filter="url(#bisel)"><rect x="127" y="272" width="6" height="36" rx="2" fill="#2e3134"/></g>')
for x, ang in ((90, 12), (170, -20)):
    a(f'<circle cx="{x}" cy="290" r="15" fill="#c9ced1" stroke="#4f5558" stroke-width="1"/>')
    a(tornillo(x, 290, 11, ang))
a('<path d="M10,5 H250" stroke="#fff" stroke-opacity="0.28" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "hidroforo.svg"), "".join(d), P.DEFS + DEFS)
