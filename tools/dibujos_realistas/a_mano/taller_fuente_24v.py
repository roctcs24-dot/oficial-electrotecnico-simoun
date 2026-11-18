"""Fuente de 24 V DC de la mesa del Taller (300×230) sobre su SVG: carcasa de chapa con tornillos,
ranuras de ventilación troqueladas, bornes de jaula con tornillo y entrada del cable, marcas
impresas de los bornes, potenciómetro de ajuste con su escala, placa frontal con los símbolos de
alterna y continua, ventanilla del LED DC OK (lo enciende el juego) y pestaña del carril DIN."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tf_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<radialGradient id="tf_hueco" cx="0.5" cy="0.4" r="0.6"><stop offset="0.45" stop-color="#030304"/><stop offset="0.85" stop-color="#16191b"/><stop offset="1" stop-color="#2f3336"/></radialGradient>
<linearGradient id="tf_laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f3e0a2"/><stop offset="0.45" stop-color="#c2a04d"/><stop offset="1" stop-color="#6b5520"/></linearGradient>
<radialGradient id="tf_lente" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#3d6b48"/><stop offset="0.6" stop-color="#15301c"/><stop offset="1" stop-color="#07100a"/></radialGradient>
<linearGradient id="tf_brillo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.04"/><stop offset="0.46" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.15"/></linearGradient>
<linearGradient id="tf_ranura" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#050607"/><stop offset="0.6" stop-color="#1c2023"/><stop offset="1" stop-color="#3a3f43"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r, ang, cruz=True):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.3}" fill="#111315"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tf_acero)"/></g>'
    l = r * 0.68
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f}" stroke="#25292c" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
    if cruz:
        l2 = r * 0.42
        t += f'<path d="M{x + l2 * s:.1f},{y - l2 * c:.1f} L{x - l2 * s:.1f},{y + l2 * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


def borne(x, y, arriba, ang):
    s = f'<rect x="{x - 15}" y="{y - 14}" width="30" height="28" rx="3" fill="#1e2225"/>'
    s += f'<rect x="{x - 15}" y="{y - 14}" width="30" height="2" fill="#fff" opacity="0.12"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.5" fill="url(#tf_hueco)"/>'
    s += f'<g filter="url(#bisel)"><rect x="{x - 10}" y="{y - 8}" width="20" height="16" rx="2" fill="url(#tf_laton)"/></g>'
    ey = y - 14 if arriba else y + 9
    s += f'<rect x="{x - 7}" y="{ey}" width="14" height="5" rx="1.5" fill="#050606"/>'
    s += f'<rect x="{x - 5}" y="{ey + (3.4 if arriba else 0.4)}" width="10" height="1.1" fill="#c9a956" opacity="0.7"/>'
    s += tornillo(x, y, 7.8, ang)
    return s


# Ranuras de ventilación troqueladas en la chapa (mismo trazado que el dibujo)
for y, x0, x1 in ((74, 30, 270), (82, 30, 270), (152, 30, 110), (160, 30, 110)):
    n = round((x1 - x0) / 20)
    paso = (x1 - x0) / n
    for i in range(n):
        x = x0 + i * paso
        a(f'<rect x="{x + 1:.1f}" y="{y - 2.2}" width="{paso - 3:.1f}" height="4.4" rx="2.2" fill="url(#tf_ranura)"/>')
        a(f'<rect x="{x + 2:.1f}" y="{y + 2.1}" width="{paso - 5:.1f}" height="0.9" fill="#fff" opacity="0.55"/>')
# Marcas impresas de los bornes: recuadro blanco tras L, N, + y −
for x, y in ((70, 72), (130, 72), (170, 160), (230, 160)):
    a(f'<rect x="{x - 8}" y="{y - 8}" width="16" height="16" rx="2" fill="#e2e5e4" stroke="#8a9094" stroke-width="0.6"/>')
# Regletas: bornes de jaula y extremos con su nervio
a(borne(70, 37, True, -8) + borne(130, 37, True, 14))
a(borne(170, 193, False, 6) + borne(230, 193, False, -15))
for x, y in ((100, 37), (200, 193)):
    a(f'<g filter="url(#bisel)"><rect x="{x - 2.5}" y="{y - 15}" width="5" height="30" rx="2" fill="#4c5358"/></g>')
a('<g filter="url(#bisel)"><rect x="160" y="24" width="52" height="26" rx="3" fill="#2a2f32"/></g>')
a('<rect x="170" y="34" width="32" height="6" rx="3" fill="#15181a"/>')

# Potenciómetro de ajuste de la tensión con su escala de puntos
for i in range(9):
    ang = math.radians(135 + i * 33.75)
    a(f'<circle cx="{246 + 15.5 * math.cos(ang):.1f}" cy="{44 + 15.5 * math.sin(ang):.1f}" r="{1.3 if i in (0, 8) else 0.9}" fill="#2a2e31"/>')
a('<circle cx="246" cy="44" r="11.5" fill="#1a1d1f"/>')
a('<g filter="url(#bisel)"><circle cx="246" cy="44" r="10" fill="url(#tf_acero)"/></g>')
a('<path d="M240,48 L252,40" stroke="#25292c" stroke-width="3" stroke-linecap="round"/>')
a('<path d="M240.5,49 L252.5,41" stroke="#fff" stroke-opacity="0.35" stroke-width="0.7"/>')

# Placa frontal: marco, brillo y símbolos de alterna (entrada) y continua (salida)
a('<rect x="34" y="96" width="232" height="44" rx="4" fill="none" stroke="#6c7276" stroke-width="1.2"/>')
a('<rect x="36" y="98" width="228" height="40" rx="3" fill="url(#tf_brillo)"/>')
a('<path d="M40,118 c3,-6 6,-6 9,0 s6,6 9,0" fill="none" stroke="#c9ced1" stroke-width="1.6" stroke-linecap="round"/>')
a('<path d="M244,114 H260 M244,122 H248 M250,122 H254 M256,122 H260" stroke="#c9ced1" stroke-width="1.6" stroke-linecap="round"/>')

# Ventanilla del LED DC OK
a('<circle cx="60" cy="193" r="10" fill="#4c5358"/><circle cx="60" cy="193" r="8" fill="url(#tf_lente)"/>')
a('<ellipse cx="57.5" cy="189.5" rx="3.2" ry="1.7" fill="#fff" opacity="0.4"/>')

# Tornillos de la tapa de chapa y pestaña del carril DIN
for x, y in ((18, 120), (282, 120), (18, 200), (116, 200)):
    a(tornillo(x, y, 4.2, 25, True))
a('<g filter="url(#bisel)"><rect x="40" y="214" width="40" height="9" rx="2" fill="#8a9093"/></g>')
a('<rect x="53" y="216.5" width="14" height="4" rx="2" fill="#2a2e31"/>')
# Canto superior iluminado de la carcasa
a('<path d="M14,8 H286" stroke="#fff" stroke-opacity="0.5" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "fuente_24v.svg"), "".join(d), P.DEFS + DEFS)
