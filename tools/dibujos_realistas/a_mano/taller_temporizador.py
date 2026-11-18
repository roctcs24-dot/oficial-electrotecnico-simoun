"""Temporizador a la conexión del Taller (260×300) sobre su SVG: caja modular con zonas de bornes
rebajadas y bornes de jaula, rejilla de ventilación, frontal con dos LED apagados, potenciómetro de
ajuste ranurado, dial con escala y mando oscuro con su índice (el juego escribe el retardo encima, en
130,150), tapa transparente precintable y lengüeta del carril DIN."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tt_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tt_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tt_frente" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4b5056"/><stop offset="0.06" stop-color="#3a3f44"/><stop offset="1" stop-color="#2b2f33"/></linearGradient>
<radialGradient id="tt_mando" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#4a4f54"/><stop offset="0.6" stop-color="#202326"/><stop offset="1" stop-color="#0b0c0d"/></radialGradient>
<radialGradient id="tt_dial" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#f4f5f5"/><stop offset="1" stop-color="#b9bec0"/></radialGradient>
<linearGradient id="tt_reflejo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.55" stop-color="#fff" stop-opacity="0.03"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
'''


def borne(x, y):
    """Borne de jaula: alojamiento hundido, jaula cincada, boca del cable y tornillo pozidriv."""
    s = f'<rect x="{x - 18}" y="{y - 17}" width="36" height="36" rx="4" fill="#0c0d0f"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tt_jaula)" d="M{x - 15},{y - 14} h30 v26 h-30 Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<rect x="{x - 9}" y="{y + 13}" width="18" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tt_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


def punto(cx, cy, r, ang):
    t = math.radians(ang)
    return cx + r * math.cos(t), cy + r * math.sin(t)


d = []
a = d.append
a('<path d="M6,6.5 H254" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
# Zonas de bornes rebajadas arriba y abajo, con su escalón
for y0, h in ((30, 50), (222, 50)):
    a(f'<rect x="16" y="{y0}" width="228" height="{h}" rx="5" fill="#000" opacity="0.28"/>')
    a(f'<rect x="16" y="{y0}" width="228" height="1.4" fill="#000" opacity="0.5"/><rect x="16" y="{y0 + h - 1}" width="228" height="1" fill="#fff" opacity="0.12"/>')
# Rejilla de ventilación entre A1 y A2
for x in range(92, 170, 8):
    a(f'<rect x="{x}" y="40" width="4" height="28" rx="2" fill="#08090a"/><rect x="{x + 4}" y="41" width="1" height="26" fill="#fff" opacity="0.14"/>')
# Frontal elevado (el juego rotula TEMPORIZADOR en 130,100)
a('<rect x="22" y="88" width="216" height="122" rx="7" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
a('<g filter="url(#plastico)"><g filter="url(#bisel)"><rect x="20" y="84" width="220" height="122" rx="7" fill="url(#tt_frente)"/></g></g>')
# LED de tensión y de relé, apagados
for y, c in ((136, "#1c4a2a"), (164, "#4a3a0e")):
    a(f'<circle cx="62" cy="{y}" r="7" fill="#121416"/><circle cx="62" cy="{y}" r="5" fill="{c}"/>')
    a(f'<circle cx="60.5" cy="{y - 1.6}" r="1.6" fill="#fff" opacity="0.45"/>')
# Potenciómetro de ajuste de escala con ranura y marcas
for i in range(7):
    x1, y1 = punto(196, 150, 11.5, 135 + i * 45)
    x2, y2 = punto(196, 150, 14.5, 135 + i * 45)
    a(f'<path d="M{x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f}" stroke="#d8dcdd" stroke-width="1.1"/>')
a('<circle cx="196" cy="150" r="9.5" fill="#0b0c0d"/>')
a('<g filter="url(#biselFuerte)"><circle cx="196" cy="150" r="8.2" fill="#e9ebec"/></g>')
a('<path d="M191,154.5 L201,145.5" stroke="#3b4043" stroke-width="2.4" stroke-linecap="round"/>')
# Dial: sombra, disco claro con escala de 270° y mando oscuro con su índice
a('<circle cx="132" cy="153" r="31" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
a('<circle cx="130" cy="150" r="30" fill="url(#tt_dial)"/>')
for i in range(28):
    ang = 135 + i * 10
    x1, y1 = punto(130, 150, 24.5 if i % 3 else 22.8, ang)
    x2, y2 = punto(130, 150, 28.5, ang)
    a(f'<path d="M{x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f}" stroke="#20242a" stroke-width="{1.4 if i % 3 == 0 else 0.8}"/>')
a('<circle cx="130" cy="150" r="22" fill="#000" opacity="0.45" filter="url(#desenfoque)"/>')
a('<g filter="url(#biselFuerte)"><circle cx="130" cy="150" r="21.5" fill="url(#tt_mando)"/></g>')
for i in range(36):
    x1, y1 = punto(130, 150, 19.6, i * 10)
    x2, y2 = punto(130, 150, 21.4, i * 10)
    a(f'<path d="M{x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f}" stroke="#000" stroke-width="1.2"/>')
x1, y1 = punto(130, 150, 14.5, 215)
x2, y2 = punto(130, 150, 21, 215)
a(f'<path d="M{x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f}" stroke="#f4f5f5" stroke-width="2.4" stroke-linecap="round"/>')
# Tapa transparente precintable sobre el frontal, con su bisagra y ojal de precinto
a('<rect x="84" y="114" width="92" height="74" rx="5" fill="#dfe8ee" fill-opacity="0.06" stroke="#fff" stroke-opacity="0.35" stroke-width="1"/>')
a('<path d="M88,188 L128,114 H150 L110,188 Z" fill="url(#tt_reflejo)"/>')
a('<rect x="84" y="111" width="92" height="4" rx="2" fill="#6c7276" opacity="0.8"/>')
a('<circle cx="172" cy="184" r="2.2" fill="none" stroke="#c8ccce" stroke-width="1"/>')
# Lengüeta del carril DIN abajo
a('<rect x="112" y="280" width="36" height="10" rx="2" fill="#1b1d20"/><rect x="122" y="283" width="16" height="4" rx="2" fill="#050506"/>')
for x, y in ((60, 54), (200, 54), (50, 246), (130, 246), (210, 246)):
    a(borne(x, y))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "temporizador.svg"), "".join(d), P.DEFS + DEFS)
