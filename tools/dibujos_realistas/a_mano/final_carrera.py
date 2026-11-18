"""Final de carrera de palanca con rodillo (320×390) sobre su SVG: caja de fundición con la junta
de la tapa y sus cantos, tornillos de la tapa con ranura, cabeza giratoria con aro, palanca con
ranura de ajuste y brillo, perno de apriete, rodillo con banda de rodadura y eje con tuerca,
prensaestopas con caras de la tuerca y manguera gris con brillo."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="fc_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.1" stop-color="#fff" stop-opacity="0"/><stop offset="0.88" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="fc_tuerca" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3a3e42"/><stop offset="0.25" stop-color="#5d6367"/><stop offset="0.5" stop-color="#2b2f32"/><stop offset="0.75" stop-color="#4a4f53"/><stop offset="1" stop-color="#1b1d20"/></linearGradient>
<linearGradient id="fc_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3b4044"/><stop offset="0.35" stop-color="#9aa1a6"/><stop offset="1" stop-color="#2f3337"/></linearGradient>
<radialGradient id="fc_rodillo" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.45" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></radialGradient>
'''

d = []
a = d.append
# Caja: cantos y junta de la tapa
a('<rect x="90" y="120" width="140" height="200" rx="10" fill="url(#fc_lado)"/>')
a('<rect x="96" y="126" width="128" height="188" rx="7" fill="none" stroke="#3f4447" stroke-width="1.6"/>')
a('<rect x="97.5" y="127.5" width="125" height="185" rx="6" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="0.8"/>')
# Ventanas de las etiquetas: canto hundido
for y, h in ((150, 70), (240, 50)):
    a(f'<rect x="110" y="{y}" width="100" height="5" fill="#000" opacity="0.12"/>')
# Tornillos de la tapa: ranura en cruz y sombra
for x, y in ((104, 134), (216, 134), (104, 306), (216, 306)):
    a(f'<circle cx="{x}" cy="{y}" r="7" fill="none" stroke="#2a2e31" stroke-width="1.2"/>')
    a(f'<path d="M{x - 3.4},{y} H{x + 3.4} M{x},{y - 3.4} V{y + 3.4}" stroke="#2a2e31" stroke-width="1.5" stroke-linecap="round"/>')
# Cabeza giratoria: aro y brillo
a('<circle cx="160" cy="100" r="22" fill="none" stroke="#6d7377" stroke-width="2"/>')
a('<path d="M142,90 A20,20 0 0 1 166,80" stroke="#fff" stroke-opacity="0.35" stroke-width="2" fill="none" stroke-linecap="round"/>')
# Palanca: brillo del canto, ranura de ajuste de largo y perno de apriete
a('<path d="M160,100 L250,40" stroke="#fff" stroke-opacity="0.25" stroke-width="2.5" transform="translate(-1.6,-2.4)" stroke-linecap="round"/>')
a('<path d="M186,83 L226,56" stroke="#15181a" stroke-width="4" stroke-linecap="round"/>')
a(P.perno(160, 100, 8))
a('<circle cx="160" cy="100" r="2.4" fill="#2a2e31"/>')
# Rodillo: banda de rodadura, brillo y eje con tuerca
a('<circle cx="250" cy="40" r="17" fill="none" stroke="#0f1113" stroke-width="1.2"/>')
a('<circle cx="250" cy="40" r="20" fill="url(#fc_rodillo)"/>')
a('<path d="M236,30 A17,17 0 0 1 252,23" stroke="#fff" stroke-opacity="0.35" stroke-width="2" fill="none" stroke-linecap="round"/>')
a(P.perno(250, 40, 6))
# Prensaestopas: caras de la tuerca, cúpula y cable con brillo
a('<rect x="140" y="320" width="40" height="26" rx="3" fill="url(#fc_tuerca)"/>')
a('<path d="M150,321 V345 M170,321 V345" stroke="#0d0f11" stroke-width="1"/>')
a('<rect x="140" y="320" width="40" height="5" fill="#000" opacity="0.35"/>')
a('<path d="M146,346 Q160,354 174,346" fill="#2b2f32"/>')
a('<rect x="154" y="350" width="12" height="40" fill="url(#fc_cable)"/>')
a('<path d="M157.5,352 V390" stroke="#fff" stroke-opacity="0.18" stroke-width="1.4"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "final_carrera.svg"), "".join(d), P.DEFS + DEFS)
