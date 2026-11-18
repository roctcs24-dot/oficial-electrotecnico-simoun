"""Arrancador suave SIRIUS 3RW40 del Taller (360×540) sobre su SVG: disipador de aletas detrás,
rejillas de ventilación, bornes de potencia de caja con mordaza y tornillo, bornes de mando con
tornillo, boca de la jaula y separadores, LED con brillo (DEVICE encendido), pulsador RESET/TEST con
reflejo, potenciómetros con escala y ranura, y tornillos de la carcasa. Sin cables dibujados: en el
Taller los pone el jugador."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="aw_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="aw_aleta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#4d5357"/><stop offset="0.45" stop-color="#c9cdd0"/><stop offset="1" stop-color="#464c50"/></linearGradient>
<linearGradient id="aw_jaula" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a7074"/><stop offset="0.5" stop-color="#e3e6e8"/><stop offset="1" stop-color="#7d8387"/></linearGradient>
<radialGradient id="aw_mando" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.6" stop-color="#d6dadc"/><stop offset="1" stop-color="#9aa0a4"/></radialGradient>
'''


def tornillo(x, y, r, cruz=True):
    s = (f'<circle cx="{x}" cy="{y + 0.8}" r="{r + 2.4}" fill="#07090b" opacity="0.8"/>'
         f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#aw_cabeza)" stroke="#2b3034" stroke-width="0.8"/>'
         f'<path d="M{x - r * 0.72},{y} H{x + r * 0.72}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>')
    if cruz:
        s += f'<path d="M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
    s += (f'<path d="M{x - r * 0.72},{y + r * 0.17} H{x + r * 0.72}" stroke="#fff" stroke-width="0.6" opacity="0.45"/>'
          f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')
    return s


def ranuras(x0, x1, y, alto, paso=9):
    s = ""
    x = x0
    while x + 5 <= x1:
        s += f'<rect x="{x}" y="{y}" width="5" height="{alto}" rx="2.5" fill="#0c0f11"/>'
        s += f'<rect x="{x + 5}" y="{y + 1}" width="1" height="{alto - 2}" fill="#fff" opacity="0.25"/>'
        x += paso
    return s


d = []
a = d.append

# Disipador de aletas asomando por los lados, detrás de la carcasa
for x0 in (14, 334):
    for i in range(3):
        a(f'<rect x="{x0 + 1 + i * 4}" y="16" width="2.6" height="508" rx="1.2" fill="url(#aw_aleta)"/>')

# Tornillos de la carcasa
for x, y in ((40, 16), (320, 16), (40, 524), (320, 524)):
    a(f'<circle cx="{x}" cy="{y}" r="5.6" fill="#1a1f23"/><circle cx="{x}" cy="{y}" r="4.4" fill="url(#aw_cabeza)"/>')
    a(f'<path d="M{x - 2.8},{y} H{x + 2.8} M{x},{y - 2.8} V{y + 2.8}" stroke="#30353a" stroke-width="1.2"/>')

# Rejillas de ventilación
a(ranuras(160, 304, 88, 12))
a(ranuras(66, 300, 438, 12))

# Bornes de potencia: mordaza de la caja y tornillo grande; tabiques entre fases
for y in (50, 490):
    for x in (110, 180, 250):
        a(f'<rect x="{x - 18}" y="{y - 14}" width="36" height="28" rx="3" fill="url(#aw_jaula)" opacity="0.4"/>')
        a(f'<rect x="{x - 18}" y="{y - 14}" width="36" height="5" fill="#15191c" opacity="0.7"/>')
        a(f'<rect x="{x - 18}" y="{y + 9}" width="36" height="5" fill="#15191c" opacity="0.7"/>')
        a(tornillo(x, y, 10))
    for x in (145, 215):
        a(f'<rect x="{x - 2}" y="{y - 24}" width="4" height="48" rx="1.5" fill="#3b444b"/><rect x="{x - 2}" y="{y - 24}" width="1.2" height="48" fill="#fff" opacity="0.2"/>')

# Bornes de mando: tornillo, boca de la jaula y separadores
for y, xs, lim in ((131, (70, 130, 230, 290), (44, 316)), (411, (60, 120, 200, 260, 320), (34, 334))):
    for x in xs:
        a(f'<rect x="{x + 9}" y="{y - 9}" width="6" height="18" rx="1" fill="#050607"/>')
        a(f'<rect x="{x + 10}" y="{y - 8}" width="2.4" height="16" fill="url(#aw_jaula)" opacity="0.4"/>')
        a(tornillo(x, y, 7.4))
        for dx in (-20, 20):
            if lim[0] < x + dx < lim[1]:
                a(f'<rect x="{x + dx - 1.2}" y="{y - 15}" width="2.4" height="30" rx="1" fill="#3b444b"/>')

# LED: el de DEVICE encendido con su halo; los demás, cristal apagado con reflejo
a('<rect x="183" y="183" width="18" height="15" rx="3" fill="#5fd16a" opacity="0.25"/>')
for x, y in ((52, 186), (52, 202), (186, 186), (186, 202), (186, 218)):
    a(f'<rect x="{x + 1.5}" y="{y + 1}" width="5" height="2" rx="1" fill="#fff" opacity="0.5"/>')

# Pulsador RESET/TEST: aro y reflejo
a('<circle cx="76" cy="248" r="14" fill="none" stroke="#14181c" stroke-width="2"/>')
a('<ellipse cx="72" cy="243" rx="5" ry="3" fill="#fff" opacity="0.45"/>')

# Potenciómetros de ajuste: escala alrededor, ranura del destornillador y brillo
for cx, cy in ((76, 284), (76, 320), (200, 248), (200, 284), (200, 320)):
    for i in range(9):
        ang = math.radians(135 + i * 33.75)
        r1, r2 = 15, 17.5 if i % 4 else 19
        a(f'<path d="M{cx + r1 * math.cos(ang):.1f},{cy + r1 * math.sin(ang):.1f} L{cx + r2 * math.cos(ang):.1f},{cy + r2 * math.sin(ang):.1f}" stroke="#c9d0d4" stroke-width="1"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="13" fill="none" stroke="#0e1114" stroke-width="1"/>')
    a(f'<ellipse cx="{cx - 3}" cy="{cy - 4}" rx="3.5" ry="1.8" fill="#fff" opacity="0.6"/>')

# Canto de la tapa frontal
a('<rect x="28" y="6" width="304" height="2" rx="1" fill="#fff" opacity="0.18"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "arrancador_suave_3rw40.svg"), "".join(d), P.DEFS + DEFS)
