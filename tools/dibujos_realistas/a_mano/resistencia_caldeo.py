"""Resistencia de caldeo de varilla (400×220) sobre su SVG: caja de bornes con tornillos de la tapa,
regleta cerámica con sus tornillos, conductores de salida con funda de fibra de vidrio, prensaestopas
lateral con el cable de alimentación (marrón y azul) y tornillo de tierra, racor hexagonal roscado
en el cuello, y vaina de acero inoxidable con brillo, engastes y la coloración del calor en la punta.
Los números de bornes y los rótulos, del juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="rc_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="rc_ceramica" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fbf8ef"/><stop offset="0.6" stop-color="#e6dfcd"/><stop offset="1" stop-color="#b9b19c"/></linearGradient>
<linearGradient id="rc_vaina" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.25"/><stop offset="0.22" stop-color="#fff" stop-opacity="0.7"/><stop offset="0.38" stop-color="#fff" stop-opacity="0"/><stop offset="0.8" stop-color="#000" stop-opacity="0.15"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
<linearGradient id="rc_calor" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#c79a4a" stop-opacity="0"/><stop offset="0.55" stop-color="#c79a4a" stop-opacity="0.12"/><stop offset="0.8" stop-color="#7a5aa0" stop-opacity="0.2"/><stop offset="1" stop-color="#3f5a96" stop-opacity="0.28"/></linearGradient>
<linearGradient id="rc_hex" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5d6367"/><stop offset="0.3" stop-color="#e3e6e8"/><stop offset="0.55" stop-color="#9ba1a5"/><stop offset="1" stop-color="#4c5256"/></linearGradient>
<linearGradient id="rc_cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
'''


def tornillo(x, y, r):
    return (f'<circle cx="{x}" cy="{y + 0.7}" r="{r + 2}" fill="#0b0d0f" opacity="0.6"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#rc_cabeza)" stroke="#2b3034" stroke-width="0.7"/>'
            f'<path d="M{x - r * 0.7},{y} H{x + r * 0.7} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
            f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')


def hilo(dd, color, ancho=3.2):
    return (f'<path d="{dd}" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="{ancho + 1.4}" stroke-linecap="round" transform="translate(0.8,1.2)"/>'
            f'<path d="{dd}" fill="none" stroke="{color}" stroke-width="{ancho}" stroke-linecap="round"/>'
            f'<path d="{dd}" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="0.9" stroke-linecap="round" transform="translate(-0.5,-0.8)"/>')


d = []
a = d.append

# Tapa: tornillos en las esquinas y canto
for x, y in ((27, 77), (123, 77), (27, 153), (123, 153)):
    a(f'<circle cx="{x}" cy="{y}" r="3.6" fill="#6d7377"/><circle cx="{x}" cy="{y}" r="2.8" fill="url(#rc_cabeza)"/>')
    a(f'<path d="M{x - 1.8},{y} H{x + 1.8}" stroke="#30353a" stroke-width="0.9"/>')
a('<rect x="34" y="84" width="82" height="4" fill="#000" opacity="0.4"/>')

# Prensaestopas en el lateral izquierdo y cable de alimentación
a('<rect x="0" y="108" width="14" height="14" fill="#2a2d30"/><rect x="0" y="108" width="14" height="14" fill="url(#rc_cable)"/>')
a('<rect x="10" y="103" width="12" height="24" rx="2" fill="url(#rc_hex)" stroke="#33383c" stroke-width="0.6"/>')

# Regleta cerámica de dos bornes
a('<rect x="40" y="102" width="70" height="27" rx="3" fill="url(#rc_ceramica)" stroke="#8c8572" stroke-width="0.7"/>')
a('<rect x="73" y="102" width="4" height="27" fill="#cfc7b2"/><rect x="73" y="102" width="1.2" height="27" fill="#fff" opacity="0.6"/>')
for x in (56, 94):
    a(f'<rect x="{x - 9}" y="{106}" width="18" height="18" rx="2" fill="#b8bec2" stroke="#6c7276" stroke-width="0.6"/>')
    a(tornillo(x, 115, 7))

# Conductores: alimentación (marrón y azul) desde el prensaestopas y salidas de la varilla con funda
# de fibra de vidrio desde el cuello
a(hilo("M20,111 H46", "#7a4a22"))
a(hilo("M20,119 Q28,136 50,136 H86 Q92,136 92,126", "#2a62b8"))
a(hilo("M130,110 Q118,110 104,114", "#e8e1cf", 3.4))
a(hilo("M130,121 Q127,143 104,143 H70 Q60,143 59,126", "#e8e1cf", 3.4))
# Tornillo de tierra con su símbolo
a(tornillo(111, 92, 3.2))
a('<path d="M105,99 H117 M107,101.5 H115 M109,104 H113" stroke="#c9ced1" stroke-width="1"/>')

# Racor del cuello: rosca y hexágono
for x in range(132, 148, 3):
    a(f'<rect x="{x}" y="102" width="1.4" height="26" fill="#000" opacity="0.45"/>')
a('<path d="M148,98 H166 L169,104 V126 L166,132 H148 L145,126 V104 Z" fill="url(#rc_hex)" stroke="#33383c" stroke-width="0.8"/>')
a('<path d="M145,110 H169 M145,120 H169" stroke="#000" stroke-width="0.6" opacity="0.35"/>')

# Vaina de acero inoxidable: brillo, calor hacia la punta y engastes
a('<path d="M170,104 H350 Q380,104 380,115 Q380,126 350,126 H170 Z" fill="url(#rc_calor)"/>')
a('<path d="M170,104 H350 Q380,104 380,115 Q380,126 350,126 H170 Z" fill="url(#rc_vaina)"/>')
for x in (190, 215, 240, 265, 290, 315, 340):
    a(f'<rect x="{x - 1}" y="104" width="2" height="22" fill="#fff" opacity="0.35"/>')
a('<path d="M174,108 H352" stroke="#fff" stroke-width="1.2" opacity="0.6" stroke-linecap="round"/>')
a('<ellipse cx="200" cy="129" rx="40" ry="2" fill="#000" opacity="0.25"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "resistencia_caldeo.svg"), "".join(d), P.DEFS + DEFS)
