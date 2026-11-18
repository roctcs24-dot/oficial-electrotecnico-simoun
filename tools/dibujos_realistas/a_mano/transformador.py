"""Transformador seco trifásico abierto (420×400) sobre su SVG: chapas magnéticas apiladas en yugos y
columnas con los escalones del núcleo, bastidores de apriete con sus pernos pasantes, espiras finas
del devanado de alta, conductos de refrigeración, calzos de separación, tomas de regulación con su
puente de latón, cables de salida con terminal, bornes con tornillo, bancada con taladros, tacos
antivibratorios y toma de tierra, y remaches de la placa. Rótulos y nombres de bornes, del juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tr_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="tr_marco" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a6a78"/><stop offset="0.3" stop-color="#7c8e9c"/><stop offset="1" stop-color="#34414c"/></linearGradient>
<linearGradient id="tr_laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fbeab0"/><stop offset="0.45" stop-color="#cfaa4c"/><stop offset="1" stop-color="#6e5418"/></linearGradient>
<linearGradient id="tr_calzo" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9c7a45"/><stop offset="0.5" stop-color="#e4c98f"/><stop offset="1" stop-color="#8a6a38"/></linearGradient>
<linearGradient id="tr_bobina" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.18" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.4" stop-color="#fff" stop-opacity="0"/><stop offset="0.8" stop-color="#000" stop-opacity="0.1"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
<linearGradient id="tr_cobreT" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a3f14"/><stop offset="0.45" stop-color="#f3b483"/><stop offset="1" stop-color="#7a3f14"/></linearGradient>
'''


def tornillo(x, y, r):
    return (f'<circle cx="{x}" cy="{y + 0.7}" r="{r + 2}" fill="#0b0d0f" opacity="0.7"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#tr_cabeza)" stroke="#2b3034" stroke-width="0.7"/>'
            f'<path d="M{x - r * 0.7},{y} H{x + r * 0.7} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
            f'<ellipse cx="{x - r * 0.35}" cy="{y - r * 0.45}" rx="{r * 0.35}" ry="{r * 0.18}" fill="#fff" opacity="0.6"/>')


def chapas_h(x, y, w, h, n):
    """Paquete de chapas visto de canto: líneas finas y escalones de tono."""
    s = ""
    for i in range(n):
        yy = y + (i + 0.5) * h / n
        s += f'<path d="M{x},{yy:.1f} H{x + w}" stroke="{"#2f3437" if i % 2 else "#a8aeb2"}" stroke-width="0.45" opacity="0.55"/>'
    for k, op in ((0, 0.18), (1, 0.08), (n - 2, 0.1), (n - 1, 0.22)):
        s += f'<rect x="{x}" y="{y + k * h / n:.1f}" width="{w}" height="{h / n:.1f}" fill="#000" opacity="{op}"/>'
    return s


def chapas_v(x, y, w, h, n):
    s = ""
    for i in range(n):
        xx = x + (i + 0.5) * w / n
        s += f'<path d="M{xx:.1f},{y} V{y + h}" stroke="{"#2f3437" if i % 2 else "#a8aeb2"}" stroke-width="0.45" opacity="0.55"/>'
    return s


d = []
a = d.append

# Núcleo: chapas de los yugos y de las columnas visibles
a(chapas_h(40, 70, 340, 40, 34))
a(chapas_h(40, 320, 340, 40, 34))
for x in (82, 192, 302):
    a(chapas_v(x, 110, 36, 12, 30))
    a(chapas_v(x, 308, 36, 12, 30))
    a(f'<rect x="{x}" y="110" width="5" height="210" fill="#000" opacity="0.25"/><rect x="{x + 31}" y="110" width="5" height="210" fill="#000" opacity="0.25"/>')

# Bastidores de apriete de los yugos (perfil pintado) con pernos pasantes
for y in (64, 104, 314, 354):
    a(f'<rect x="34" y="{y}" width="352" height="12" rx="2" fill="url(#tr_marco)" stroke="#1f272e" stroke-width="0.7"/>')
    a(f'<rect x="36" y="{y + 1}" width="348" height="1.4" fill="#fff" opacity="0.3"/>')
for y in (70, 110, 320, 360):
    for x in (46, 154, 266, 374):
        a(P.perno(x, y, 3.6))
# Tirantes verticales entre los bastidores, a los extremos
for x in (36, 380):
    a(f'<rect x="{x}" y="76" width="4" height="278" fill="#5a6a78"/><rect x="{x}" y="76" width="1.2" height="278" fill="#fff" opacity="0.3"/>')

# Devanados: espiras finas en la parte de cobre visible, conductos y calzos
for x0 in (52, 162, 272):
    for lado in (x0 + 1, x0 + 79):
        y = 125
        while y < 306:
            a(f'<path d="M{lado},{y} H{lado + 17}" stroke="#5a2a0c" stroke-width="0.6" opacity="0.55"/>')
            y += 3.2
    a(f'<rect x="{x0}" y="122" width="96" height="186" rx="10" fill="url(#tr_bobina)"/>')
    # Conductos axiales de refrigeración entre alta y baja
    for xx in (x0 + 18, x0 + 77):
        a(f'<rect x="{xx}" y="124" width="1.8" height="182" fill="#1a0c04" opacity="0.6"/>')
    # Calzos de separación contra los yugos
    for dx in (8, 30, 58, 80):
        a(f'<rect x="{x0 + dx}" y="113" width="8" height="10" rx="1" fill="url(#tr_calzo)" stroke="#5b4320" stroke-width="0.5"/>')
        a(f'<rect x="{x0 + dx}" y="307" width="8" height="10" rx="1" fill="url(#tr_calzo)" stroke="#5b4320" stroke-width="0.5"/>')
    # Brillo del aislamiento del devanado interior
    a(f'<rect x="{x0 + 22}" y="126" width="6" height="178" rx="3" fill="#fff" opacity="0.14"/>')
    # Tomas de regulación con su puente de latón
    tx = x0 + 88
    a(f'<rect x="{tx - 6}" y="188" width="12" height="54" rx="2" fill="#2a2e32" stroke="#111" stroke-width="0.6"/>')
    for i, ty in enumerate((196, 206, 216, 226, 236)):
        a(tornillo(tx, ty, 2.3))
    a(f'<rect x="{tx - 3.5}" y="203" width="7" height="16" rx="2" fill="url(#tr_laton)" opacity="0.9"/>')
    a(tornillo(tx, 206, 2.3) + tornillo(tx, 216, 2.3))

# Cables de salida de los devanados a los bornes, con terminal de ojo
for x in (80, 120, 190, 230, 300, 340):
    a(f'<path d="M{x + 1},62 V120" stroke="#000" stroke-width="5" opacity="0.35"/>')
    a(f'<path d="M{x},60 V120" stroke="#1b1d1f" stroke-width="5"/>')
    a(f'<path d="M{x - 1.2},62 V120" stroke="#fff" stroke-width="1" opacity="0.3"/>')
    a(f'<rect x="{x - 4}" y="56" width="8" height="8" rx="1.5" fill="url(#tr_cobreT)"/>')
    a(f'<rect x="{x - 4}" y="116" width="8" height="9" rx="1.5" fill="url(#tr_cobreT)"/>')
    a(tornillo(x, 46, 7))

# Bancada: taladros, tacos antivibratorios y toma de tierra
a('<rect x="20" y="370" width="380" height="2" fill="#fff" opacity="0.25"/>')
for x in (34, 386):
    a(f'<rect x="{x - 10}" y="392" width="20" height="8" rx="2" fill="#1a1c1e"/>')
    a(f'<rect x="{x - 10}" y="392" width="20" height="2" fill="#555" opacity="0.6"/>')
for x in (60, 110, 310, 360):
    a(f'<rect x="{x - 8}" y="378" width="16" height="7" rx="3.5" fill="#15171a"/>')
    a(f'<rect x="{x - 8}" y="384" width="16" height="1" fill="#fff" opacity="0.25"/>')
a(P.perno(392, 382, 4))
a('<path d="M392,382 C404,384 410,392 414,400" stroke="#2f9e4a" stroke-width="4" fill="none"/>'
  '<path d="M392,382 C404,384 410,392 414,400" stroke="#f2c200" stroke-width="4" fill="none" stroke-dasharray="4 4"/>')

# Placa de características: remaches y brillo
a('<rect x="150" y="334" width="120" height="30" rx="2" fill="url(#am_placa)" opacity="0.6"/>')
for x, y in ((155, 339), (265, 339), (155, 359), (265, 359)):
    a(f'<circle cx="{x}" cy="{y}" r="1.6" fill="#6c7276"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "transformador.svg"), "".join(d), P.DEFS + DEFS)
