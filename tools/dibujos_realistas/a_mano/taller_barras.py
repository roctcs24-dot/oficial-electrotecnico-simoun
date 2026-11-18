"""Barras de 380 V del Taller (360×140) sobre su SVG: pletina de cobre con brillo, partida en tres
tramos por los soportes aislantes de poliéster, bajantes de cobre con su funda del color de cada fase
(L1 marrón, L2 negro, L3 gris; el juego escribe L1, L2 y L3 sobre la funda), bornes de caja estañados
con su tornillo, pernos en la barra, tornillos de la tapa y triángulo de riesgo eléctrico."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tb_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tb_cobre" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd2ac"/><stop offset="0.25" stop-color="#e8975c"/><stop offset="0.6" stop-color="#b8632c"/><stop offset="1" stop-color="#6e3412"/></linearGradient>
<linearGradient id="tb_cobreV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a3a16"/><stop offset="0.3" stop-color="#f0a46c"/><stop offset="0.55" stop-color="#c06a32"/><stop offset="1" stop-color="#6e3412"/></linearGradient>
<linearGradient id="tb_estano" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f4f5f2"/><stop offset="0.45" stop-color="#b9bdb8"/><stop offset="1" stop-color="#6c706b"/></linearGradient>
<linearGradient id="tb_soporte" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#4a1712"/><stop offset="0.35" stop-color="#9c3a2a"/><stop offset="1" stop-color="#3e130e"/></linearGradient>
<linearGradient id="tb_funda" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
'''

FASES = ((60, "#6b3a1c"), (180, "#1a1b1c"), (300, "#5d6266"))


def tornillo_tapa(x, y):
    return (f'<circle cx="{x}" cy="{y}" r="5" fill="#1b1d20"/><circle cx="{x}" cy="{y}" r="3.8" fill="url(#tb_acero)"/>'
            f'<path d="M{x - 2.6},{y + 1.2} L{x + 2.6},{y - 1.2}" stroke="#30353a" stroke-width="1.2" stroke-linecap="round"/>')


def borne_caja(x, y):
    """Borne de caja estañado para cable de potencia, con su tornillo pozidriv."""
    s = f'<rect x="{x - 21}" y="{y - 17}" width="42" height="36" rx="4" fill="#0c0d0f"/>'
    s += (f'<g filter="url(#biselFuerte)"><path fill-rule="evenodd" fill="url(#tb_estano)" d="M{x - 18},{y - 15} h36 v28 h-36 Z '
          f'M{x + 11.6},{y} a11.6,11.6 0 1 0 -23.2,0 a11.6,11.6 0 1 0 23.2,0 Z"/></g>')
    s += f'<rect x="{x - 11}" y="{y + 13}" width="22" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tb_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
a('<path d="M6,6.5 H354" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
a('<rect x="9.5" y="9.5" width="341" height="121" rx="4" fill="none" stroke="#000" stroke-opacity="0.4" stroke-width="1.2"/>')
for x, y in ((16, 16), (16, 124), (344, 124)):
    a(tornillo_tapa(x, y))
# Triángulo de riesgo eléctrico arriba a la derecha
a('<path d="M338,12 L350,33 H326 Z" fill="#f2c200" stroke="#1d1f22" stroke-width="1.6" stroke-linejoin="round"/>')
a('<path d="M339.5,18 L334.5,26 H339 L336.5,31 L342.5,23 H338 Z" fill="#1d1f22"/>')
# Pletina de cobre: sombra, cuerpo con brillo y cantos
a('<rect x="20" y="49" width="320" height="7" fill="#000" opacity="0.55" filter="url(#sombraCorta)"/>')
a('<rect x="20" y="45" width="320" height="8" rx="1" fill="url(#tb_cobre)"/>')
a('<rect x="20" y="45.6" width="320" height="1" fill="#fff" opacity="0.55"/>')
for x in (40, 150, 230, 290):
    a(f'<rect x="{x}" y="47" width="{18 if x % 20 else 26}" height="1.2" fill="#5a2a0c" opacity="0.35"/>')
# Bajantes de cobre a cada borne, con su funda de color de fase y el perno en la barra
for x, color in FASES:
    a(f'<rect x="{x - 9}" y="51" width="18" height="34" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
    a(f'<rect x="{x - 8}" y="47" width="16" height="36" rx="1.5" fill="url(#tb_cobreV)"/>')
    a(P.perno(x, 49.5, 4.2))
    a(f'<rect x="{x - 10}" y="53" width="20" height="20" rx="3" fill="{color}"/>')
    a(f'<rect x="{x - 10}" y="53" width="20" height="20" rx="3" fill="url(#tb_funda)"/>')
    a(f'<path d="M{x - 10},53.6 H{x + 10} M{x - 10},72.4 H{x + 10}" stroke="#000" stroke-opacity="0.4" stroke-width="1"/>')
# Soportes aislantes de poliéster que separan los tramos de cada fase
for x in (28, 120, 240, 332):
    a(f'<rect x="{x - 8}" y="40" width="16" height="20" rx="2" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
    a(f'<g filter="url(#bisel)"><rect x="{x - 8}" y="38" width="16" height="20" rx="2" fill="url(#tb_soporte)"/></g>')
    a(P.perno(x, 48, 3.2))
for x, _ in FASES:
    a(borne_caja(x, 96))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "barras.svg"), "".join(d), P.DEFS + DEFS)
