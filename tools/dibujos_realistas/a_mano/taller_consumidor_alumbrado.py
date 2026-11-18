"""Circuito de alumbrado de la mesa del Taller (360×200) sobre su SVG: luminaria estanca de dos tubos
con difusor de policarbonato, junta, cierres de acero inoxidable, tubos con su brillo y portalámparas
de dos espigas, prensaestopas con el cable de salida, y regleta de bornes de carril DIN (A y B en
gris, PE en verde y amarillo) con sus tornillos y topes."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tca_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="tca_bloqueGris" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.25" stop-color="#b4babd"/><stop offset="0.6" stop-color="#9aa0a4"/><stop offset="1" stop-color="#5b6165"/></linearGradient>
<linearGradient id="tca_bloquePE" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1f6b2e"/><stop offset="0.25" stop-color="#3fae55"/><stop offset="0.6" stop-color="#2f9645"/><stop offset="1" stop-color="#1a5726"/></linearGradient>
<linearGradient id="tca_carril" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5f6568"/><stop offset="0.12" stop-color="#eef0f0"/><stop offset="0.3" stop-color="#a3a9ac"/><stop offset="0.85" stop-color="#c9cdce"/><stop offset="1" stop-color="#5c6265"/></linearGradient>
<linearGradient id="tca_tubo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity="0.95"/><stop offset="0.3" stop-color="#f4f7f6" stop-opacity="0.5"/><stop offset="0.7" stop-color="#c9d1d3" stop-opacity="0.3"/><stop offset="1" stop-color="#7d878b" stop-opacity="0.55"/></linearGradient>
<linearGradient id="tca_difusor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.38"/><stop offset="0.18" stop-color="#fff" stop-opacity="0.08"/><stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.12"/></linearGradient>
<pattern id="tca_prisma" width="4" height="90" patternUnits="userSpaceOnUse"><rect width="1.4" height="90" fill="#fff" opacity="0.12"/><rect x="2" width="0.8" height="90" fill="#000" opacity="0.06"/></pattern>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.2}" fill="#15181a"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tca_acero)"/></g>'
    l = r * 0.62
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


def regleta(x0, x1, y, bornes):
    """Carril DIN con bornes de paso; «bornes»: lista de (x, es_tierra)."""
    s = f'<rect x="{x0 + 6}" y="{y - 10}" width="{x1 - x0 - 12}" height="20" fill="url(#tca_carril)"/>'
    for x in range(int(x0) + 14, int(x1) - 8, 22):
        s += f'<rect x="{x}" y="{y - 3}" width="12" height="6" rx="3" fill="#2a2e31"/>'
    for xt in (x0 + 12, x1 - 12):
        s += f'<g filter="url(#bisel)"><rect x="{xt - 6}" y="{y - 17}" width="12" height="34" rx="2" fill="#3a3f43"/></g>'
        s += tornillo(xt, y, 3.2, 40)
    for x, tierra in bornes:
        s += f'<g filter="url(#bisel)"><rect x="{x - 14}" y="{y - 20}" width="28" height="40" rx="2.5" fill="url(#{"tca_bloquePE" if tierra else "tca_bloqueGris"})"/></g>'
        if tierra:
            s += f'<rect x="{x - 12}" y="{y - 20}" width="4" height="40" fill="#e9c21c" opacity="0.9"/><rect x="{x + 8}" y="{y - 20}" width="4" height="40" fill="#e9c21c" opacity="0.9"/>'
        for yy in (y - 17, y + 12):
            s += f'<rect x="{x - 7}" y="{yy}" width="14" height="5" rx="1.5" fill="#050606"/>'
        s += f'<circle cx="{x}" cy="{y}" r="10.5" fill="#1b1e20" opacity="0.8"/>'
        s += tornillo(x, y, 8.4, (x * 13) % 40 - 20)
    return s


# Luminaria: junta de goma, difusor prismático con reflejo y cierres de inoxidable
a('<rect x="16" y="26" width="328" height="78" rx="34" fill="none" stroke="#2b3033" stroke-width="2.4"/>')
# Reflector blanco esmaltado detrás de los tubos
a('<rect x="28" y="32" width="304" height="66" rx="16" fill="#dfe4e4"/>')
a('<rect x="28" y="32" width="304" height="66" rx="16" fill="url(#tca_difusor)"/>')
a('<path d="M40,64 H320" stroke="#c4cbcd" stroke-width="1.2"/>')
for y, h in ((38, 20), (70, 20)):
    a(f'<rect x="44" y="{y + 1}" width="272" height="{h - 2}" rx="9" fill="#f7f9f8"/>')
    a(f'<rect x="44" y="{y + h - 1}" width="272" height="5" rx="2.5" fill="#000" opacity="0.22"/>')
    a(f'<rect x="44" y="{y + 1}" width="272" height="{h - 2}" rx="9" fill="none" stroke="#8f9a9e" stroke-width="1"/>')
    # Tubo: vidrio con brillo, extremos metálicos y portalámparas con sus dos espigas
    a(f'<rect x="44" y="{y + 2}" width="272" height="{h - 4}" rx="8" fill="url(#tca_tubo)"/>')
    a(f'<rect x="56" y="{y + 4.5}" width="248" height="2.2" rx="1.1" fill="#fff" opacity="0.8"/>')
    for x, sgn in ((34, 1), (326, -1)):
        xc = x if sgn > 0 else x - 16
        a(f'<g filter="url(#bisel)"><rect x="{xc}" y="{y - 3}" width="16" height="{h + 6}" rx="3" fill="#b7bdbf"/></g>')
        xm = x + 15 if sgn > 0 else x - 21
        a(f'<rect x="{xm}" y="{y + 2}" width="6" height="{h - 4}" rx="1" fill="url(#tca_acero)"/>')
a('<rect x="12" y="22" width="336" height="86" rx="38" fill="url(#tca_prisma)" opacity="0.8"/>')
a('<rect x="12" y="22" width="336" height="86" rx="38" fill="url(#tca_difusor)"/>')
a('<path d="M52,25 H300" stroke="#fff" stroke-opacity="0.7" stroke-width="1.6" stroke-linecap="round"/>')
for x in (90, 180, 270):
    for y in (17, 106):
        a(f'<g filter="url(#bisel)"><rect x="{x - 9}" y="{y}" width="18" height="7" rx="2" fill="url(#tca_acero)"/></g>')
        a(f'<rect x="{x - 6}" y="{y + 2.5}" width="12" height="1.4" fill="#4f5558"/>')
# Prensaestopas y cable de salida hacia la regleta (entre las marcas B y PE)
a('<path d="M220,114 V132" stroke="#0e1012" stroke-width="9" stroke-linecap="round"/>')
a('<path d="M218,114 V132" stroke="#fff" stroke-opacity="0.25" stroke-width="1.5"/>')
a('<g filter="url(#bisel)"><rect x="211" y="106" width="18" height="10" rx="2" fill="#2f3438"/></g>')

# Regleta de bornes en carril DIN: A, B y PE
a(regleta(60, 300, 152, [(100, False), (180, False), (260, True)]))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "consumidor_alumbrado.svg"), "".join(d), P.DEFS + DEFS)
