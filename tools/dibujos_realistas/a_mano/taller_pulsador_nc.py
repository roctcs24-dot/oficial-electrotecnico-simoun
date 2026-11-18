"""Pulsador NC de parada del Taller (200×240) sobre su SVG: caja moldeada con tornillos de la tapa,
aro cromado torneado con sombra de contacto, botón rojo rasante con su brillo, franja de color,
bloque de contacto NC con su símbolo y su indicador rojo, y bornes de jaula con tornillo pozidriv.
El juego escribe «O» en el centro del botón y 21/22 sobre los bornes."""
import math, os
import realzar as R
from a_mano import _piezas as P

COLOR, OSCURO, CLARO = "#c9352b", "#5e0c06", "#ff8a7a"

DEFS = '''
<radialGradient id="tpc_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tpc_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tpc_cromo" x1="0.15" y1="0.1" x2="0.85" y2="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#d9dddf"/><stop offset="0.55" stop-color="#7e8488"/><stop offset="0.75" stop-color="#c9cdd0"/><stop offset="1" stop-color="#5d6366"/></linearGradient>
<radialGradient id="tpc_boton" cx="0.5" cy="0.5" r="0.5"><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="0.93" stop-color="#000" stop-opacity="0.28"/><stop offset="1" stop-color="#000" stop-opacity="0.55"/></radialGradient>
<linearGradient id="tpc_bloque" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3e42"/><stop offset="0.08" stop-color="#2c2f33"/><stop offset="1" stop-color="#1f2225"/></linearGradient>
'''


def tornillo_tapa(x, y):
    """Tornillo pequeño de la tapa, ranurado, en su avellanado."""
    return (f'<circle cx="{x}" cy="{y}" r="5" fill="#1b1d20"/><circle cx="{x}" cy="{y}" r="3.8" fill="url(#tpc_acero)"/>'
            f'<path d="M{x - 2.6},{y + 1.2} L{x + 2.6},{y - 1.2}" stroke="#30353a" stroke-width="1.2" stroke-linecap="round"/>')


def borne(x, y):
    """Borne de jaula: alojamiento hundido, jaula cincada, boca del cable abajo y tornillo pozidriv."""
    s = f'<rect x="{x - 18}" y="{y - 17}" width="36" height="36" rx="4" fill="#0c0d0f"/>'
    s += f'<rect x="{x - 18}" y="{y + 15}" width="36" height="1.4" fill="#fff" opacity="0.12"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tpc_jaula)" d="M{x - 15},{y - 14} h30 v26 h-30 Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<rect x="{x - 9}" y="{y + 13}" width="18" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tpc_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
# Caja moldeada: canto biselado de la tapa, línea de junta y tornillos de las esquinas
a('<rect x="9.5" y="9.5" width="181" height="221" rx="4" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="1.2"/>')
a('<rect x="10.5" y="10.5" width="181" height="221" rx="4" fill="none" stroke="#fff" stroke-opacity="0.1" stroke-width="1"/>')
a('<path d="M6,6.5 H194" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
for x, y in ((16, 16), (184, 16), (16, 226), (184, 226)):
    a(tornillo_tapa(x, y))
# Sombra de contacto del aro sobre la tapa
a('<circle cx="102" cy="73" r="55" fill="none" stroke="#000" stroke-opacity="0.55" stroke-width="5" filter="url(#sombraCorta)"/>')
# Aro cromado torneado: estrías finas, luz arriba a la izquierda y sombra en el escalón interior
a('<circle cx="100" cy="70" r="53.5" fill="none" stroke="url(#tpc_cromo)" stroke-width="2.5"/>')
for r in range(45, 53, 2):
    a(f'<circle cx="100" cy="70" r="{r + 0.5}" fill="none" stroke="#fff" stroke-opacity="0.13" stroke-width="0.6"/>')
a('<path d="M60,52 A48,48 0 0 1 118,24" stroke="#fff" stroke-opacity="0.85" stroke-width="3" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<path d="M146,86 A48,48 0 0 1 104,118" stroke="#1d2124" stroke-opacity="0.5" stroke-width="3" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<circle cx="100" cy="70" r="44" fill="none" stroke="#1a1d1f" stroke-width="2.2"/>')
a('<circle cx="100" cy="70" r="45.6" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="0.8"/>')
# Botón rasante: canto oscurecido, reflejo de la luz del techo y leve brillo de arriba
a('<circle cx="100" cy="70" r="43" fill="url(#tpc_boton)"/>')
a(f'<path d="M66,58 A36,36 0 0 1 112,36" stroke="{CLARO}" stroke-opacity="0.55" stroke-width="5" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
a('<ellipse cx="78" cy="46" rx="11" ry="4.5" fill="#fff" opacity="0.4" transform="rotate(-35 78 46)" filter="url(#desenfoque)"/>')
a(f'<path d="M136,84 A38,38 0 0 1 112,106" stroke="{OSCURO}" stroke-opacity="0.6" stroke-width="4" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
# Franja de color con su canto
a('<rect x="24" y="136" width="152" height="1.3" fill="#fff" opacity="0.35"/><rect x="24" y="141.2" width="152" height="1" fill="#000" opacity="0.45"/>')
# Bloque de contacto NC: cuerpo, ventana del indicador rojo, símbolo grabado y bornes
a('<g filter="url(#plastico)"><g filter="url(#bisel)"><rect x="24" y="152" width="152" height="74" rx="5" fill="url(#tpc_bloque)"/></g></g>')
a('<path d="M100,152 V226" stroke="#000" stroke-opacity="0.5" stroke-width="1.2"/><path d="M101.2,153 V225" stroke="#fff" stroke-opacity="0.08" stroke-width="1"/>')
a(f'<rect x="94" y="156" width="12" height="6" rx="1.5" fill="#050607"/><rect x="96" y="157.5" width="8" height="3" rx="1" fill="{COLOR}"/>')
a('<g stroke="#8d9397" stroke-width="1.3" fill="none" stroke-linecap="round">'
  '<path d="M86,198 H93 M107,198 H114 M107,198 V193"/><path d="M93,198 L109,194"/></g>')
a('<circle cx="93" cy="198" r="1.2" fill="#8d9397"/>')
for x in (60, 140):
    a(borne(x, 196))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "pulsador_nc.svg"), "".join(d), P.DEFS + DEFS)
