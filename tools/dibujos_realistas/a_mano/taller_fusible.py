"""Fusible de mando del Taller (140×240) sobre su SVG: base aislante con bornes de jaula arriba y
abajo, pletinas de latón hasta las pinzas elásticas, cartucho cerámico cilíndrico con capuchones
niquelados, indicador de fusión y nervios laterales. El juego escribe el calibre en el centro del
cartucho (70,120) y los números 1 y 2 a la derecha de los bornes."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tf_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tf_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tf_ceramica" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#a9aca5"/><stop offset="0.18" stop-color="#e3e4df"/><stop offset="0.38" stop-color="#fbfbf8"/><stop offset="0.7" stop-color="#e2e3dd"/><stop offset="1" stop-color="#9c9f98"/></linearGradient>
<linearGradient id="tf_niquel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6c7276"/><stop offset="0.25" stop-color="#e4e7e8"/><stop offset="0.4" stop-color="#ffffff"/><stop offset="0.7" stop-color="#a7adb0"/><stop offset="1" stop-color="#565c60"/></linearGradient>
<linearGradient id="tf_laton" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a6324"/><stop offset="0.35" stop-color="#f0d98f"/><stop offset="0.6" stop-color="#c4a24f"/><stop offset="1" stop-color="#6b5520"/></linearGradient>
'''


def borne(x, y):
    """Borne de jaula: alojamiento hundido, jaula cincada, boca del cable y tornillo pozidriv."""
    s = f'<rect x="{x - 18}" y="{y - 17}" width="36" height="36" rx="4" fill="#0c0d0f"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tf_jaula)" d="M{x - 15},{y - 14} h30 v26 h-30 Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tf_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
a('<path d="M6,6.5 H134" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
a('<rect x="9.5" y="9.5" width="121" height="221" rx="4" fill="none" stroke="#000" stroke-opacity="0.4" stroke-width="1.2"/>')
# Nervios laterales de la base aislante
for x in (16, 112):
    for y in range(92, 152, 9):
        a(f'<rect x="{x}" y="{y}" width="12" height="4" rx="2" fill="#1e2124"/><rect x="{x}" y="{y + 4}" width="12" height="1" fill="#fff" opacity="0.13"/>')
# Alojamiento del cartucho, rebajado
a('<rect x="32" y="60" width="76" height="120" rx="8" fill="#141618"/>')
a('<rect x="32" y="178" width="76" height="2" fill="#fff" opacity="0.1"/>')
# Pletinas de latón de los bornes a las pinzas
for y0, y1 in ((48, 74), (166, 192)):
    a(f'<g filter="url(#bisel)"><rect x="62" y="{y0}" width="16" height="{y1 - y0}" rx="1.5" fill="url(#tf_laton)"/></g>')
    a(f'<circle cx="70" cy="{(y0 + y1) / 2}" r="2.6" fill="url(#tf_acero)" stroke="#4a3a10" stroke-width="0.6"/>')
# Cartucho cerámico con su sombra
a('<rect x="44" y="72" width="60" height="100" rx="6" fill="#000" opacity="0.55" filter="url(#sombraCorta)"/>')
a('<rect x="40" y="70" width="60" height="100" rx="6" fill="url(#tf_ceramica)"/>')
a('<rect x="47" y="86" width="3" height="68" rx="1.5" fill="#fff" opacity="0.8"/>')
# Capuchones niquelados con su borde y pinzas elásticas a los lados
for y in (70, 154):
    a(f'<g filter="url(#bisel)"><rect x="38" y="{y}" width="64" height="16" rx="4" fill="url(#tf_niquel)"/></g>')
    a(f'<rect x="38" y="{y + (14 if y == 70 else 0)}" width="64" height="2" fill="#3b4043" opacity="0.7"/>')
    for x in (33, 101):
        a(f'<g filter="url(#bisel)"><rect x="{x}" y="{y + 1}" width="6" height="14" rx="2" fill="url(#tf_laton)"/></g>')
# Indicador de fusión en el capuchón inferior (intacto)
a('<circle cx="70" cy="162" r="3.6" fill="#2a2d30"/><circle cx="70" cy="162" r="2.4" fill="#d9a23a"/><circle cx="69.2" cy="161.2" r="0.8" fill="#fff" opacity="0.7"/>')
for x, y in ((70, 34), (70, 206)):
    a(borne(x, y))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "fusible.svg"), "".join(d), P.DEFS + DEFS)
