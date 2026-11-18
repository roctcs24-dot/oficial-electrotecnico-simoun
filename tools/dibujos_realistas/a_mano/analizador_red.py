"""Analizador de red de cuadro (320×360) sobre su SVG: marco con pestañas de fijación, pantalla LCD
hundida con retroiluminación, trama de píxeles y cristal, flechas y barras de nivel de las filas, teclas de goma con
sus símbolos, LED de impulsos de energía y regleta trasera con tabiques, arandelas y conector
enchufable verde de la alimentación auxiliar."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<pattern id="an_pixel" width="2" height="2" patternUnits="userSpaceOnUse"><rect width="2" height="2" fill="#000" opacity="0"/><rect width="2" height="0.5" fill="#2f4a2a" opacity="0.10"/><rect width="0.5" height="2" fill="#2f4a2a" opacity="0.10"/></pattern>
<radialGradient id="an_luz" cx="0.5" cy="0.45" r="0.7"><stop offset="0" stop-color="#f4ffe9" stop-opacity="0.45"/><stop offset="1" stop-color="#5f7a55" stop-opacity="0.18"/></radialGradient>
<linearGradient id="an_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.42"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="an_sombraH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.3"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="an_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.30"/><stop offset="0.4" stop-color="#fff" stop-opacity="0.04"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="an_tecla" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.04"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></linearGradient>
<linearGradient id="an_verde" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3fa45a"/><stop offset="0.5" stop-color="#1f7a3a"/><stop offset="1" stop-color="#14552a"/></linearGradient>
<radialGradient id="an_led" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#ffb3a8"/><stop offset="0.5" stop-color="#e0392b"/><stop offset="1" stop-color="#6a120b"/></radialGradient>
'''

d = []
a = d.append
# Pestañas de fijación al panel en los lados del marco
for y in (40, 210):
    for x in (14, 300):
        a(f'<rect x="{x}" y="{y}" width="6" height="22" rx="1.5" fill="#1a1d20"/><rect x="{x + 1}" y="{y + 2}" width="1.4" height="18" fill="#fff" opacity="0.18"/>')
a('<path d="M28,11.5 H292" stroke="#fff" stroke-opacity="0.2" stroke-width="1.5"/>')
# Pantalla: escalón del marco, retroiluminación, trama de píxeles y sombra interior
a('<rect x="37" y="27" width="246" height="156" rx="5.5" fill="none" stroke="#0c0e10" stroke-width="3"/>')
a('<rect x="40" y="30" width="240" height="150" rx="4" fill="url(#an_luz)"/>')
a('<rect x="40" y="30" width="240" height="150" rx="4" fill="url(#an_pixel)"/>')
a('<rect x="40" y="30" width="240" height="14" fill="url(#an_sombraV)"/>')
a('<rect x="40" y="30" width="10" height="150" fill="url(#an_sombraH)"/>')
# Flechas de fila y barras de nivel a la derecha de cada lectura
for y, n in ((56, 5), (104, 3), (152, 0)):
    a(f'<path d="M52,{y - 5} L58,{y} L52,{y + 5} Z" fill="#20242a" opacity="0.85"/>')
    for k in range(5 if n else 0):
        h = 4 + k * 2.2
        a(f'<rect x="{250 + k * 5}" y="{y + 6 - h:.1f}" width="3.4" height="{h:.1f}" fill="#20242a" opacity="{0.85 if k < n else 0.18}"/>')
# Cristal de la pantalla
a('<rect x="40" y="30" width="240" height="150" rx="4" fill="url(#an_cristal)"/>')
a('<path d="M40,96 L120,30 H158 L40,128 Z" fill="#fff" opacity="0.08"/>')
a('<path d="M44,32.5 H276" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')
# Teclas de goma: brillo, aro y símbolo (izquierda, arriba, abajo, aceptar)
for i, x in enumerate((44, 104, 164, 224)):
    a(f'<rect x="{x - 1.5}" y="194.5" width="53" height="39" rx="7" fill="none" stroke="#111315" stroke-width="2"/>')
    a(f'<rect x="{x}" y="196" width="50" height="36" rx="6" fill="url(#an_tecla)"/>')
    cx, cy = x + 25, 214
    if i == 0:
        a(f'<path d="M{cx + 5},{cy - 6} L{cx - 5},{cy} L{cx + 5},{cy + 6} Z" fill="#d6dadc"/>')
    elif i == 1:
        a(f'<path d="M{cx - 6},{cy + 4} L{cx},{cy - 6} L{cx + 6},{cy + 4} Z" fill="#d6dadc"/>')
    elif i == 2:
        a(f'<path d="M{cx - 6},{cy - 4} L{cx},{cy + 6} L{cx + 6},{cy - 4} Z" fill="#d6dadc"/>')
    else:
        a(f'<path d="M{cx + 7},{cy - 7} V{cy + 2} H{cx - 5} M{cx - 1},{cy - 2} L{cx - 6},{cy + 2} L{cx - 1},{cy + 6}" fill="none" stroke="#d6dadc" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>')
# LED de impulsos de energía en el marco
a('<circle cx="287" cy="214" r="5" fill="#0b0c0d"/><circle cx="287" cy="214" r="3.4" fill="url(#an_led)"/>'
  '<circle cx="287" cy="214" r="7" fill="#e0392b" opacity="0.18"/>')
# Regleta trasera: brillo del canto, tabiques entre bornes y arandelas
a('<path d="M22,261.5 H298" stroke="#fff" stroke-opacity="0.18" stroke-width="1.2"/>')
for x in (75, 125, 175):
    a(f'<rect x="{x - 3}" y="264" width="6" height="82" rx="2" fill="#24282b"/><rect x="{x - 3}" y="264" width="1.6" height="82" fill="#fff" opacity="0.12"/>')
a('<path d="M28,305 H170" stroke="#1a1d20" stroke-width="2"/>')
for x in (50, 100, 150):
    for y in (284, 326):
        a(f'<circle cx="{x}" cy="{y}" r="11" fill="none" stroke="#9aa1a5" stroke-width="2.2"/>')
        a(f'<circle cx="{x}" cy="{y}" r="12.4" fill="none" stroke="#111315" stroke-width="0.8"/>')
# Conector enchufable verde de la alimentación auxiliar, con sus bridas
a('<path fill-rule="evenodd" fill="url(#an_verde)" stroke="#0d3a1b" stroke-width="1" '
  'd="M188,284 H282 Q284,284 284,286 V316 Q284,318 282,318 H188 Q186,318 186,316 V286 Q186,284 188,284 Z '
  'M221,300 A11,11 0 1 0 199,300 A11,11 0 1 0 221,300 Z M271,300 A11,11 0 1 0 249,300 A11,11 0 1 0 271,300 Z"/>')
a('<rect x="231" y="288" width="8" height="26" rx="1.5" fill="#15602e"/><rect x="186" y="285" width="98" height="2" fill="#fff" opacity="0.25"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "analizador_red.svg"), "".join(d), P.DEFS + DEFS)
