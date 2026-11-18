"""Condensador multitubular (480×280) sobre su SVG: tuberías rectas que el relieve automático pierde
(agua de mar, entrada de vapor y salida de líquido) con su volumen y bridas, costuras soldadas,
coronas de pernos de las cajas de agua, ánodos de cinc, purgadores de aire y de vaciado, cáncamos,
manómetro, válvula de seguridad con sombrerete y palanca, purga con tapón, placa remachada y
placas de anclaje de las cunas."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="cd_brillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.42" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="cd_rojo" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a1c16"/><stop offset="0.4" stop-color="#e0574a"/><stop offset="1" stop-color="#7a1c16"/></linearGradient>
<radialGradient id="cd_cinc" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#f6e7b0"/><stop offset="0.6" stop-color="#c8a248"/><stop offset="1" stop-color="#6e5518"/></radialGradient>
'''

d = []
a = d.append


def tubo_recto(ruta, w, color):
    """Tramo recto con volumen sin filtros ni degradados (una línea no tiene caja)."""
    horizontal = "H" in ruta
    sombra = "translate(0,%.1f)" % (w * 0.28) if horizontal else "translate(%.1f,0)" % (w * 0.28)
    luz = "translate(0,-%.1f)" % (w * 0.24) if horizontal else "translate(-%.1f,0)" % (w * 0.24)
    return (f'<path d="{ruta}" stroke="{color}" stroke-width="{w}"/>'
            f'<path d="{ruta}" stroke="#000" stroke-opacity="0.28" stroke-width="{w * 0.42:.1f}" transform="{sombra}"/>'
            f'<path d="{ruta}" stroke="#fff" stroke-opacity="0.38" stroke-width="{max(1.2, w * 0.16):.1f}" transform="{luz}"/>')


# Tuberías: agua de mar (entra abajo, sale arriba), vapor caliente arriba y líquido abajo
a(tubo_recto("M8,190 H30", 14, "#3fb5a3") + tubo_recto("M30,120 H8", 14, "#3fb5a3"))
a(tubo_recto("M190,100 V44", 16, "#d9534f"))
a(tubo_recto("M290,210 V262", 12, "#e0a030"))
a(P.brida(24, 190, 14) + P.brida(24, 120, 14))
a(P.brida(190, 64, 16, True))
a(P.brida(290, 238, 12, True))
for x, w in ((190, 26), (290, 22)):
    y = 96 if x == 190 else 208
    a(f'<rect x="{x - w / 2}" y="{y}" width="{w}" height="6" rx="1.5" fill="url(#am_bridaV)"/>')

# Virola: brillo longitudinal y costuras soldadas junto a las cajas
a('<rect x="76" y="100" width="328" height="110" fill="url(#cd_brillo)"/>')
for x in (84, 396):
    a(f'<path d="M{x},101 V209" stroke="#5f6568" stroke-width="3"/>')
    a(f'<path d="M{x},101 V209" stroke="#e1e4e5" stroke-width="1.2" stroke-dasharray="1.8 1.3"/>')
a('<path d="M240,101 V138 M240,182 V209" stroke="#7a8084" stroke-width="1.2" opacity="0.6"/>')
# Cáncamos de izado
for x in (110, 370):
    a(f'<path d="M{x - 6},100 A6,6 0 0 1 {x + 6},100" fill="none" stroke="#5a6064" stroke-width="3.2"/>')
    a(f'<rect x="{x - 8}" y="98" width="16" height="3" fill="#5a6064"/>')

# Cajas de agua: bridas atornilladas a la placa tubular, ánodos de cinc y purgadores
for x in (79, 401):
    a(f'<rect x="{x - 4}" y="94" width="8" height="122" rx="2" fill="url(#am_brida)" stroke="#2e3d47" stroke-width="0.6"/>')
    for y in range(102, 212, 13):
        a(P.perno(x, y, 2.1))
for x in (36, 444):
    a(f'<path d="M{x},96 V214" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')
for cx, cy in ((40, 104), (40, 206), (440, 104), (440, 206)):
    a(f'<circle cx="{cx}" cy="{cy}" r="5.4" fill="url(#cd_cinc)"/>' + P.perno(cx, cy, 2.8))
for cx in (53, 427):
    a(f'<rect x="{cx - 4}" y="88" width="8" height="6" rx="1" fill="#8a9094"/>' + P.perno(cx, 88, 2.4))
    a(f'<rect x="{cx - 4}" y="216" width="8" height="6" rx="1" fill="#8a9094"/>' + P.perno(cx, 222, 2.4))

# Manómetro de la carcasa sobre su toma
a('<path d="M136,100 V92" stroke="#8a9094" stroke-width="3"/>' + P.manometro(136, 82, 9, 0.45))

# Válvula de seguridad: brillo del cuerpo, sombrerete, palanca, brida de la base y precinto
a('<rect x="320" y="70" width="18" height="30" fill="url(#cd_rojo)" opacity="0.85"/>')
a('<rect x="318" y="96" width="22" height="5" rx="1.5" fill="url(#am_bridaV)"/>')
a(P.perno(322, 98.5, 1.4) + P.perno(336, 98.5, 1.4))
a('<rect x="322" y="62" width="14" height="9" rx="2" fill="#a52a22" stroke="#5a1410" stroke-width="0.6"/>')
a('<path d="M338,80 L348,74" stroke="#5a6064" stroke-width="2.2" stroke-linecap="round"/><circle cx="349" cy="73.5" r="2" fill="#5a6064"/>')
a('<path d="M320,78 C314,80 314,84 318,86" fill="none" stroke="#9aa0a3" stroke-width="0.7"/><circle cx="314.5" cy="82" r="1.8" fill="#7b8286"/>')
a('<path d="M329,70 V40 H352" fill="none" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2" transform="translate(-1.2,-1.2)"/>')

# Purga de incondensables: tapón hexagonal y brillo del cuerpo
a('<rect x="247" y="83" width="3" height="16" fill="#fff" opacity="0.3"/>')
a('<rect x="244" y="78" width="14" height="5" rx="1" fill="#4f5558"/>' + P.perno(251, 80, 3))

# Placa: marco, remaches y raya grabada entre las dos líneas de texto
a('<rect x="122" y="142" width="106" height="36" rx="2" fill="none" stroke="#7a8084" stroke-width="0.8"/>')
for px, py in ((125, 145), (225, 145), (125, 175), (225, 175)):
    a(f'<circle cx="{px}" cy="{py}" r="1.5" fill="#7b8286"/>')

# Cunas: zunchos, placas de anclaje y pernos
for x0, x1 in ((110, 136), (340, 366)):
    a(f'<path d="M{x0 - 4},204 H{x1 + 4}" stroke="#1a1d20" stroke-width="4"/>')
    a(f'<rect x="{x0 - 22}" y="248" width="{x1 - x0 + 44}" height="6" rx="1.5" fill="#3a3f44"/>')
    a(P.perno(x0 - 14, 251, 2.4) + P.perno(x1 + 14, 251, 2.4))
    a(f'<path d="M{(x0 + x1) / 2},208 V246" stroke="#1a1d20" stroke-width="2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "condensador.svg"), "".join(d), P.DEFS + DEFS)
