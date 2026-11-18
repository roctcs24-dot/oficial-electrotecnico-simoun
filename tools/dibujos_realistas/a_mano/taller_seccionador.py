"""Interruptor general con candado del Taller (320×440) sobre su SVG: caja con tornillos de la tapa,
zonas de bornes de potencia rebajadas con tabiques entre fases y bornes de caja, placa amarilla
atornillada con las marcas de posición, disco rojo abombado, maneta con su sombra, agarre estriado y
tapa central, pestaña de candado en la posición de abierto y bloque de contacto auxiliar 13-14 a la
derecha. El juego escribe los números de los bornes y «0 OFF   I ON» bajo la placa."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tsc_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tsc_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<radialGradient id="tsc_disco" cx="0.42" cy="0.36" r="0.66"><stop offset="0" stop-color="#ff7a6a" stop-opacity="0.4"/><stop offset="0.4" stop-color="#e2473a" stop-opacity="0"/><stop offset="0.85" stop-color="#5e100a" stop-opacity="0.25"/><stop offset="1" stop-color="#3a0804" stop-opacity="0.6"/></radialGradient>
<linearGradient id="tsc_maneta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6e1009"/><stop offset="0.22" stop-color="#e2493b"/><stop offset="0.45" stop-color="#c22a1e"/><stop offset="1" stop-color="#5e0c06"/></linearGradient>
<linearGradient id="tsc_amarillo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff6c8" stop-opacity="0.35"/><stop offset="0.4" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#7a5c06" stop-opacity="0.25"/></linearGradient>
<linearGradient id="tsc_pestana" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5a6064"/><stop offset="0.35" stop-color="#d5d9db"/><stop offset="1" stop-color="#4c5154"/></linearGradient>
'''


def tornillo_tapa(x, y, r=5):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="#1b1d20"/><circle cx="{x}" cy="{y}" r="{r * 0.76:.1f}" fill="url(#tsc_acero)"/>'
            f'<path d="M{x - r * 0.52:.1f},{y + r * 0.24:.1f} L{x + r * 0.52:.1f},{y - r * 0.24:.1f}" stroke="#30353a" stroke-width="1.2" stroke-linecap="round"/>')


def borne(x, y, ancho=36):
    """Borne de caja: alojamiento hundido, jaula cincada, boca del cable y tornillo pozidriv."""
    m = ancho / 2
    s = f'<rect x="{x - m}" y="{y - 17}" width="{ancho}" height="36" rx="4" fill="#0c0d0f"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tsc_jaula)" d="M{x - m + 3},{y - 14} h{ancho - 6} v26 h-{ancho - 6} Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<rect x="{x - m + 7}" y="{y + 13}" width="{ancho - 14}" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#tsc_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
a('<path d="M8,6.5 H312" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
a('<rect x="9.5" y="9.5" width="301" height="421" rx="5" fill="none" stroke="#000" stroke-opacity="0.4" stroke-width="1.2"/>')
for x, y in ((18, 18), (302, 18), (18, 422), (302, 422)):
    a(tornillo_tapa(x, y))
# Zonas de bornes de potencia rebajadas, con tabiques entre fases
for y0 in (24, 364):
    a(f'<rect x="38" y="{y0}" width="244" height="54" rx="5" fill="#000" opacity="0.3"/>')
    a(f'<rect x="38" y="{y0}" width="244" height="1.4" fill="#000" opacity="0.55"/><rect x="38" y="{y0 + 53}" width="244" height="1" fill="#fff" opacity="0.12"/>')
    for x in (120, 200):
        a(f'<g filter="url(#biselFuerte)"><rect x="{x - 4}" y="{y0 - 2}" width="8" height="58" rx="3" fill="#43484d"/></g>')
# Placa amarilla: brillo, canto, tornillos y marcas de posición
a('<rect x="40" y="100" width="200" height="200" rx="10" fill="url(#tsc_amarillo)"/>')
a('<rect x="42" y="102" width="196" height="196" rx="9" fill="none" stroke="#fff6c8" stroke-opacity="0.55" stroke-width="1"/>')
for x, y in ((54, 114), (226, 114), (54, 286), (226, 286)):
    a(tornillo_tapa(x, y, 4.6))
a('<path d="M140,104 V122 M218,200 H236" stroke="#1d1a10" stroke-width="3" stroke-linecap="round"/>')
# Sombra del disco en la placa y disco rojo abombado
a('<circle cx="143" cy="204" r="70" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>')
a('<circle cx="140" cy="200" r="70" fill="#7a0f08"/><circle cx="140" cy="198" r="66" fill="#d03a2d"/>')
a('<circle cx="140" cy="198" r="66" fill="url(#tsc_disco)"/>')
a('<circle cx="140" cy="198" r="65" fill="none" stroke="#ff8f80" stroke-opacity="0.35" stroke-width="1"/>')
a('<path d="M84,170 A62,62 0 0 1 124,138" stroke="#fff" stroke-opacity="0.45" stroke-width="5" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
# Maneta: sombra, cuerpo con luz lateral, agarre estriado y tapa central
a('<rect x="131" y="132" width="28" height="144" rx="12" fill="#000" opacity="0.55" filter="url(#sombraCorta)"/>')
a('<g filter="url(#biselFuerte)"><rect x="126" y="126" width="28" height="144" rx="12" fill="url(#tsc_maneta)" stroke="#5e100a" stroke-width="2"/></g>')
for y0 in (136, 226):
    for y in range(y0, y0 + 34, 5):
        a(f'<rect x="130" y="{y}" width="20" height="2" rx="1" fill="#5e0c06"/><rect x="130" y="{y + 2}" width="20" height="0.8" fill="#ff9a8c" opacity="0.4"/>')
a('<path d="M131,134 V262" stroke="#ffb0a4" stroke-opacity="0.5" stroke-width="1.6" stroke-linecap="round"/>')
a('<circle cx="140" cy="198" r="13" fill="#3a0804" opacity="0.6" filter="url(#desenfoque)"/>')
a('<g filter="url(#biselFuerte)"><circle cx="140" cy="198" r="11" fill="#8a1810"/></g>')
a('<circle cx="140" cy="198" r="4" fill="#2a0603"/><ellipse cx="136.5" cy="194" rx="3.2" ry="1.6" fill="#fff" opacity="0.4"/>')
# Pestaña de candado bajo la maneta (bloqueo en abierto)
a('<rect x="126" y="276" width="28" height="20" rx="3" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>')
a('<g filter="url(#bisel)"><rect x="124" y="273" width="32" height="20" rx="3" fill="url(#tsc_pestana)"/></g>')
a('<rect x="133" y="279" width="14" height="8" rx="4" fill="#0b0c0d"/><rect x="133" y="285.5" width="14" height="1.2" fill="#fff" opacity="0.3"/>')
# Bloque de contacto auxiliar 13-14 a la derecha
a('<g filter="url(#plastico)"><g filter="url(#bisel)"><rect x="258" y="146" width="44" height="118" rx="5" fill="#2c3034"/></g></g>')
a('<rect x="273" y="200" width="10" height="10" rx="1.5" fill="#050607"/><rect x="275" y="203" width="6" height="4" rx="1" fill="#2fa84d"/>')
for x in (80, 160, 240):
    a(borne(x, 52, 40))
    a(borne(x, 392, 40))
for y in (170, 240):
    a(borne(278, y, 34))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "seccionador.svg"), "".join(d), P.DEFS + DEFS)
