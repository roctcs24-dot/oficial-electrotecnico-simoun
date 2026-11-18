"""Circuito de tomas de corriente de la mesa del Taller (300×220) sobre su SVG: placa doble con
bisel y tornillo central, tomas hundidas con alvéolos y contactos de latón al fondo, orificio de
tierra, cable de salida y regleta de bornes de carril DIN (A y B en gris, PE en verde y amarillo)."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tct_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="tct_bloqueGris" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.25" stop-color="#b4babd"/><stop offset="0.6" stop-color="#9aa0a4"/><stop offset="1" stop-color="#5b6165"/></linearGradient>
<linearGradient id="tct_bloquePE" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1f6b2e"/><stop offset="0.25" stop-color="#3fae55"/><stop offset="0.6" stop-color="#2f9645"/><stop offset="1" stop-color="#1a5726"/></linearGradient>
<linearGradient id="tct_carril" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5f6568"/><stop offset="0.12" stop-color="#eef0f0"/><stop offset="0.3" stop-color="#a3a9ac"/><stop offset="0.85" stop-color="#c9cdce"/><stop offset="1" stop-color="#5c6265"/></linearGradient>
<radialGradient id="tct_hundido" cx="0.5" cy="0.45" r="0.55"><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="0.93" stop-color="#000" stop-opacity="0.2"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></radialGradient>
<linearGradient id="tct_bisel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.8"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.18"/></linearGradient>
<linearGradient id="tct_laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2c10"/><stop offset="0.5" stop-color="#b8953e"/><stop offset="1" stop-color="#3a2c10"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.2}" fill="#15181a"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tct_acero)"/></g>'
    l = r * 0.62
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


def regleta(x0, x1, y, bornes):
    """Carril DIN con bornes de paso; «bornes»: lista de (x, es_tierra)."""
    s = f'<rect x="{x0 + 6}" y="{y - 10}" width="{x1 - x0 - 12}" height="20" fill="url(#tct_carril)"/>'
    for x in range(int(x0) + 14, int(x1) - 8, 22):
        s += f'<rect x="{x}" y="{y - 3}" width="12" height="6" rx="3" fill="#2a2e31"/>'
    for xt in (x0 + 12, x1 - 12):
        s += f'<g filter="url(#bisel)"><rect x="{xt - 6}" y="{y - 17}" width="12" height="34" rx="2" fill="#3a3f43"/></g>'
        s += tornillo(xt, y, 3.2, 40)
    for x, tierra in bornes:
        s += f'<g filter="url(#bisel)"><rect x="{x - 14}" y="{y - 20}" width="28" height="40" rx="2.5" fill="url(#{"tct_bloquePE" if tierra else "tct_bloqueGris"})"/></g>'
        if tierra:
            s += f'<rect x="{x - 12}" y="{y - 20}" width="4" height="40" fill="#e9c21c" opacity="0.9"/><rect x="{x + 8}" y="{y - 20}" width="4" height="40" fill="#e9c21c" opacity="0.9"/>'
        for yy in (y - 17, y + 12):
            s += f'<rect x="{x - 7}" y="{yy}" width="14" height="5" rx="1.5" fill="#050606"/>'
        s += f'<circle cx="{x}" cy="{y}" r="10.5" fill="#1b1e20" opacity="0.8"/>'
        s += tornillo(x, y, 8.4, (x * 13) % 40 - 20)
    return s


# Placa: canto biselado con brillo y tornillo central
a('<rect x="22" y="12" width="256" height="116" rx="9" fill="none" stroke="url(#tct_bisel)" stroke-width="3"/>')
a('<rect x="30" y="20" width="240" height="100" rx="6" fill="none" stroke="#c5cacb" stroke-width="1"/>')
a(tornillo(150, 70, 5.2, 15))
# Tomas: cara hundida, alvéolos con el contacto de latón y orificio de tierra
for cx in (95, 205):
    a(f'<circle cx="{cx}" cy="70" r="38" fill="url(#tct_hundido)"/>')
    a(f'<circle cx="{cx}" cy="70" r="33" fill="none" stroke="#fff" stroke-opacity="0.7" stroke-width="1"/>')
    a(f'<path d="M{cx - 31},58 A33,33 0 0 1 {cx + 20},44" fill="none" stroke="#9aa0a3" stroke-opacity="0.5" stroke-width="1.2"/>')
    for x in (cx - 11, cx + 5):
        a(f'<rect x="{x}" y="56" width="6" height="26" rx="2" fill="#0c0d0e"/>')
        a(f'<rect x="{x + 1.5}" y="62" width="3" height="16" rx="1" fill="url(#tct_laton)"/>')
        a(f'<rect x="{x}" y="81" width="6" height="1.2" fill="#fff" opacity="0.8"/>')
    a(f'<path d="M{cx - 5},99 V94 A5,5 0 0 1 {cx + 5},94 V99 Z" fill="#0c0d0e"/>')
    a(f'<rect x="{cx - 2.5}" y="95" width="5" height="3" fill="url(#tct_laton)"/>')
# Cable de salida de la caja hacia la regleta (entre las marcas B y PE)
a('<path d="M190,134 V152" stroke="#0e1012" stroke-width="9" stroke-linecap="round"/>')
a('<path d="M188,134 V152" stroke="#fff" stroke-opacity="0.25" stroke-width="1.5"/>')
a('<g filter="url(#bisel)"><rect x="181" y="126" width="18" height="10" rx="2" fill="#c9cdcf"/></g>')

# Regleta de bornes en carril DIN: A, B y PE
a(regleta(30, 270, 172, [(70, False), (150, False), (230, True)]))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "consumidor_tomas.svg"), "".join(d), P.DEFS + DEFS)
