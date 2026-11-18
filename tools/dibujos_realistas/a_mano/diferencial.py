"""Interruptor diferencial de 2 polos de carril DIN (260×380) sobre su SVG: la base modular del
interruptor automático (carril, escalones, junta y remaches, bornes de jaula, clip) más la maneta
estriada en su alojamiento, el botón de prueba T con su aro y brillo y el símbolo del tipo A
(alterna y continua pulsante) en la banda inferior."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import interruptor_automatico as IA

DEFS = '''
<radialGradient id="df_boton" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#fff3c4" stop-opacity="0.75"/><stop offset="0.45" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#5a4405" stop-opacity="0.35"/></radialGradient>
'''

d = IA.modular(96)
a = d.append
# Maneta en su alojamiento: palanca en ON (arriba), estrías y sombra
a('<rect x="82" y="166" width="44" height="20" rx="4" fill="#5a6064"/>')
a('<rect x="82" y="184" width="44" height="6" fill="#000" opacity="0.45" filter="url(#desenfoque)"/>')
for x in range(87, 124, 5):
    a(f'<rect x="{x}" y="169" width="2.2" height="13" rx="1" fill="#3a3f43"/>')
a('<rect x="82" y="166" width="44" height="20" rx="4" fill="url(#ia_maneta)"/>')
a('<path d="M84,167 H124" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')
# Botón de prueba T: alojamiento hundido, aro y brillo del plástico amarillo
a('<circle cx="186" cy="192" r="22" fill="none" stroke="#9aa0a3" stroke-width="2"/>')
a('<circle cx="186" cy="192" r="20" fill="none" stroke="#3a3e42" stroke-width="2.4" opacity="0.6"/>')
a('<circle cx="186" cy="192" r="17" fill="url(#df_boton)"/>')
a('<path d="M174,183 A14,14 0 0 1 190,178" stroke="#fff" stroke-opacity="0.7" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
# Símbolo del tipo A en la banda inferior: alterna y semionda pulsante en un recuadro
a('<rect x="56" y="280" width="26" height="16" rx="1.5" fill="none" stroke="#2a2f34" stroke-width="1"/>')
a('<path d="M60,285 q2.75,-4 5.5,0 t5.5,0" fill="none" stroke="#2a2f34" stroke-width="1.1"/>'
  '<path d="M60,293 q1.8,-4 3.6,0 M67,293 q1.8,-4 3.6,0 M74,293 q1.8,-4 3.6,0 M58.5,293 H79" fill="none" stroke="#2a2f34" stroke-width="1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "diferencial.svg"), "".join(d), P.DEFS + IA.DEFS + DEFS)
