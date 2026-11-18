"""Cocina eléctrica de la mesa del Taller (320×240) sobre su SVG: encimera de acero inoxidable
cepillado con barandilla antirrolido, placas de fundición con sus surcos y aro cromado, mandos con
falda graduada e índice, piloto de encendido apagado, y regleta de bornes de carril DIN (A y B en
gris, PE en verde y amarillo)."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tcc_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="tcc_bloqueGris" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.25" stop-color="#b4babd"/><stop offset="0.6" stop-color="#9aa0a4"/><stop offset="1" stop-color="#5b6165"/></linearGradient>
<linearGradient id="tcc_bloquePE" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1f6b2e"/><stop offset="0.25" stop-color="#3fae55"/><stop offset="0.6" stop-color="#2f9645"/><stop offset="1" stop-color="#1a5726"/></linearGradient>
<linearGradient id="tcc_carril" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5f6568"/><stop offset="0.12" stop-color="#eef0f0"/><stop offset="0.3" stop-color="#a3a9ac"/><stop offset="0.85" stop-color="#c9cdce"/><stop offset="1" stop-color="#5c6265"/></linearGradient>
<linearGradient id="tcc_cromo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fbfcfc"/><stop offset="0.3" stop-color="#9ea3a6"/><stop offset="0.55" stop-color="#eef0f0"/><stop offset="1" stop-color="#6c7276"/></linearGradient>
<radialGradient id="tcc_placa" cx="0.42" cy="0.38" r="0.7"><stop offset="0" stop-color="#3b3f43"/><stop offset="0.7" stop-color="#1d2023"/><stop offset="1" stop-color="#0d0f10"/></radialGradient>
<radialGradient id="tcc_mando" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#4a4f53"/><stop offset="1" stop-color="#0d0e0f"/></radialGradient>
<radialGradient id="tcc_piloto" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#b36a1c"/><stop offset="0.6" stop-color="#5a300a"/><stop offset="1" stop-color="#2a1604"/></radialGradient>
<linearGradient id="tcc_barra" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6c7276"/><stop offset="0.35" stop-color="#f4f6f6"/><stop offset="1" stop-color="#5a6064"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.2}" fill="#15181a"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tcc_acero)"/></g>'
    l = r * 0.62
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


def regleta(x0, x1, y, bornes):
    """Carril DIN con bornes de paso; «bornes»: lista de (x, es_tierra)."""
    s = f'<rect x="{x0 + 6}" y="{y - 10}" width="{x1 - x0 - 12}" height="20" fill="url(#tcc_carril)"/>'
    for x in range(int(x0) + 14, int(x1) - 8, 22):
        s += f'<rect x="{x}" y="{y - 3}" width="12" height="6" rx="3" fill="#2a2e31"/>'
    for xt in (x0 + 12, x1 - 12):
        s += f'<g filter="url(#bisel)"><rect x="{xt - 6}" y="{y - 17}" width="12" height="34" rx="2" fill="#3a3f43"/></g>'
        s += tornillo(xt, y, 3.2, 40)
    for x, tierra in bornes:
        s += f'<g filter="url(#bisel)"><rect x="{x - 14}" y="{y - 20}" width="28" height="40" rx="2.5" fill="url(#{"tcc_bloquePE" if tierra else "tcc_bloqueGris"})"/></g>'
        if tierra:
            s += f'<rect x="{x - 12}" y="{y - 20}" width="4" height="40" fill="#e9c21c" opacity="0.9"/><rect x="{x + 8}" y="{y - 20}" width="4" height="40" fill="#e9c21c" opacity="0.9"/>'
        for yy in (y - 17, y + 12):
            s += f'<rect x="{x - 7}" y="{yy}" width="14" height="5" rx="1.5" fill="#050606"/>'
        s += f'<circle cx="{x}" cy="{y}" r="10.5" fill="#1b1e20" opacity="0.8"/>'
        s += tornillo(x, y, 8.4, (x * 13) % 40 - 20)
    return s


# Encimera de inoxidable cepillado (solo el brillo, encima del degradado del dibujo)
a('<g filter="url(#cepillado)"><rect x="22" y="12" width="276" height="136" rx="5" fill="#b9bec1" opacity="0.35"/></g>')
a('<path d="M24,13 H296" stroke="#fff" stroke-opacity="0.8" stroke-width="1.2"/>')
# Placas: aro cromado, fundición con surcos concéntricos y brillo
for cx in (100, 220):
    a(f'<circle cx="{cx}" cy="70" r="42" fill="url(#tcc_placa)"/>')
    for r in (36, 30, 24, 18, 12):
        a(f'<circle cx="{cx}" cy="70" r="{r}" fill="none" stroke="#050606" stroke-width="1.6"/>')
        a(f'<circle cx="{cx}" cy="70.8" r="{r}" fill="none" stroke="#5a6064" stroke-opacity="0.45" stroke-width="0.6"/>')
    a(f'<circle cx="{cx}" cy="70" r="5" fill="#2f3337"/>')
    a(f'<circle cx="{cx}" cy="70" r="43" fill="none" stroke="url(#tcc_cromo)" stroke-width="3.2"/>')
    a(f'<path d="M{cx - 30},48 A36,36 0 0 1 {cx + 6},34" fill="none" stroke="#fff" stroke-opacity="0.25" stroke-width="3" stroke-linecap="round"/>')
# Barandilla antirrolido a lo largo del borde de atrás
for x in (30, 160, 290):
    a(f'<rect x="{x - 3}" y="12" width="6" height="12" rx="1.5" fill="#7d8387"/>')
a('<rect x="24" y="14" width="272" height="5" rx="2.5" fill="url(#tcc_barra)"/>')
# Mandos con falda graduada e índice; piloto apagado entre ellos
for cx in (100, 220):
    for i in range(7):
        ang = math.radians(150 + i * 40)
        a(f'<circle cx="{cx + 13 * math.cos(ang):.1f}" cy="{132 + 13 * math.sin(ang):.1f}" r="{1.2 if i else 1.6}" fill="#2a2e31"/>')
    a(f'<circle cx="{cx}" cy="132" r="10" fill="#0b0c0d"/>')
    a(f'<g filter="url(#bisel)"><circle cx="{cx}" cy="132" r="8.5" fill="url(#tcc_mando)"/></g>')
    a(f'<rect x="{cx - 1.2}" y="122.5" width="2.4" height="9" rx="1.2" fill="#e8ebec"/>')
a('<circle cx="160" cy="132" r="6" fill="url(#tcc_cromo)"/><circle cx="160" cy="132" r="4.4" fill="url(#tcc_piloto)"/>')
a('<ellipse cx="158.6" cy="130.4" rx="1.8" ry="1" fill="#fff" opacity="0.5"/>')
# Cable de salida de la cocina hacia la regleta (entre las marcas B y PE)
a('<path d="M200,152 V172" stroke="#0e1012" stroke-width="9" stroke-linecap="round"/>')
a('<path d="M198,152 V172" stroke="#fff" stroke-opacity="0.25" stroke-width="1.5"/>')
a('<g filter="url(#bisel)"><rect x="191" y="144" width="18" height="10" rx="2" fill="#2f3438"/></g>')

# Regleta de bornes en carril DIN: A, B y PE
a(regleta(40, 280, 192, [(80, False), (160, False), (240, True)]))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "consumidor_cocina.svg"), "".join(d), P.DEFS + DEFS)
