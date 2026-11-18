"""Sensor inductivo de 3 hilos del Taller (340×200) sobre su SVG: cara activa azul con su labio,
cuerpo roscado de latón con volumen y crestas de rosca, tuercas hexagonales con sus caras y arandelas
dentadas, cuerpo trasero de plástico, ventana del LED ámbar (el juego lo enciende en 200,65.5),
prensaestopas con alivio de tracción estriado, cable con brillo, punteras con su collar y bornes de
jaula. El juego escribe PNP o NPN en el cuerpo (105,92), en oscuro."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tse_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tse_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tse_cilindro" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.12" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.28" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.45" stop-color="#fff" stop-opacity="0"/><stop offset="0.8" stop-color="#000" stop-opacity="0.18"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
<linearGradient id="tse_tuerca" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#555b5f"/><stop offset="0.2" stop-color="#9aa1a4"/><stop offset="0.22" stop-color="#e9ecee"/><stop offset="0.5" stop-color="#c4c9cc"/><stop offset="0.78" stop-color="#8d9497"/><stop offset="0.8" stop-color="#6a7074"/><stop offset="1" stop-color="#3c4246"/></linearGradient>
<linearGradient id="tse_estria" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3e42"/><stop offset="0.3" stop-color="#7a8085"/><stop offset="1" stop-color="#1c1e20"/></linearGradient>
<linearGradient id="tse_ferrula" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6c7276"/><stop offset="0.35" stop-color="#f1f3f3"/><stop offset="1" stop-color="#5c6266"/></linearGradient>
'''


def borne(x, y):
    """Borne de jaula pequeño: jaula cincada, boca del cable a la izquierda y tornillo pozidriv."""
    s = (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tse_jaula)" d="M{x - 13},{y - 12} h26 v24 h-26 Z '
         f'M{x + 9.5},{y} a9.5,9.5 0 1 0 -19,0 a9.5,9.5 0 1 0 19,0 Z"/></g>')
    s += f'<circle cx="{x}" cy="{y}" r="9.4" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="8.6" fill="url(#tse_acero)"/></g>'
    s += f'<path d="M{x - 5},{y} H{x + 5} M{x},{y - 5} V{y + 5}" stroke="#24282b" stroke-width="2.2" stroke-linecap="round"/>'
    s += f'<path d="M{x - 6},{y - 3.4} A7,7 0 0 1 {x - 1.6},{y - 6.8}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.4" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
# Cara activa azul: volumen, labio y canto frontal
a('<rect x="14" y="58" width="20" height="64" rx="4" fill="url(#tse_cilindro)"/>')
a('<rect x="14" y="58" width="4" height="64" rx="2" fill="#000" opacity="0.25"/>')
a('<rect x="29" y="56" width="5" height="68" rx="1.5" fill="#2b5577"/><rect x="29" y="56" width="5" height="68" rx="1.5" fill="url(#tse_cilindro)"/>')
# Cuerpo roscado: crestas de la rosca con luz, volumen del cilindro
for x in range(37, 178, 3):
    if 62 <= x <= 84 or 130 <= x <= 152:
        continue
    a(f'<path d="M{x + 3},55 L{x - 3},125" stroke="#fff3c4" stroke-opacity="0.35" stroke-width="0.9"/>')
a('<rect x="30" y="54" width="150" height="72" rx="4" fill="url(#tse_cilindro)"/>')
a('<rect x="176" y="54" width="4" height="72" fill="#000" opacity="0.3"/>')
# Tuercas hexagonales vistas de lado: caras, chaflanes y arandela dentada
for x0 in (62, 130):
    a(f'<rect x="{x0}" y="48" width="22" height="84" rx="3" fill="url(#tse_tuerca)"/>')
    a(f'<path d="M{x0},48 q11,-3 22,0 M{x0},132 q11,3 22,0" stroke="#3c4246" stroke-width="1" fill="none"/>')
    a(f'<rect x="{x0 + 2}" y="60" width="1.4" height="60" fill="#fff" opacity="0.5"/>')
    xa = x0 + 22 if x0 == 62 else x0 - 3
    a(f'<rect x="{xa}" y="51" width="3" height="78" rx="1" fill="#8e9497"/>')
    for y in range(53, 128, 6):
        a(f'<rect x="{xa}" y="{y}" width="3" height="2" fill="#3c4246"/>')
# Cuerpo trasero de plástico con su escalón
a('<rect x="180" y="66" width="40" height="48" rx="6" fill="url(#tse_cilindro)"/>')
a('<rect x="183" y="74" width="34" height="1" fill="#000" opacity="0.4"/><rect x="183" y="106" width="34" height="1" fill="#000" opacity="0.4"/>')
# Ventana del LED ámbar, translúcida (apagada)
a('<rect x="188" y="61" width="24" height="9" rx="4" fill="#5c3d0c"/>')
a('<rect x="188" y="61" width="24" height="9" rx="4" fill="#ffb020" opacity="0.28"/>')
a('<rect x="190" y="62" width="20" height="2.4" rx="1.2" fill="#fff4cf" opacity="0.55"/>')
# Prensaestopas con alivio de tracción estriado y cable
for x in range(222, 250, 4):
    a(f'<rect x="{x}" y="79" width="3" height="22" rx="1.2" fill="url(#tse_estria)"/>')
a('<rect x="220" y="80" width="30" height="20" rx="8" fill="url(#tse_cilindro)"/>')
# Brillo de los hilos y punteras con su collar
for camino in ("M250,84 C272,84 278,60 300,60", "M250,90 C272,90 278,100 300,100", "M250,96 C272,96 278,140 300,140"):
    a(f'<path d="{camino}" stroke="#fff" stroke-opacity="0.3" stroke-width="1.6" fill="none" transform="translate(0,-1.6)"/>')
for y in (60, 100, 140):
    a(f'<rect x="282" y="{y - 4.5}" width="6" height="9" rx="1.5" fill="#e9ebe8"/><rect x="282" y="{y - 4.5}" width="6" height="2.4" rx="1" fill="#fff" opacity="0.7"/>')
    a(f'<rect x="288" y="{y - 3}" width="10" height="6" rx="1" fill="url(#tse_ferrula)"/>')
for y in (60, 100, 140):
    a(borne(310, y))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "sensor.svg"), "".join(d), P.DEFS + DEFS)
