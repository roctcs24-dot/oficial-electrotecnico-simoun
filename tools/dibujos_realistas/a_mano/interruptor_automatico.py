"""Interruptor automático de 2 polos de carril DIN (260×380) sobre su SVG: carril con sus labios y
ranuras, frente elevado con escalones hacia los bornes, junta y remaches entre los dos módulos,
bornes de jaula con la entrada del cable y el hueco del tornillo, maneta estriada con su brillo,
ventanilla del indicador rojo con cristal y pestaña del clip del carril.
diferencial.py usa la misma base (modular) sin la maneta."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ia_jaula" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.5" stop-color="#e3e6e8"/><stop offset="1" stop-color="#6d7377"/></linearGradient>
<linearGradient id="ia_paso" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.22"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ia_maneta" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.4" stop-color="#fff" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="ia_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.6"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.05"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
'''


def modular(ancho_mando):
    """Detalles comunes de un aparato modular de 2 polos de 260×380; «ancho_mando»: ancho del
    frente gris del mando, que empieza en x = 56."""
    d = []
    a = d.append
    # Carril DIN a los lados del aparato: labios con brillo, fondo y ranuras oblongas
    for x0, x1 in ((0, 30), (230, 260)):
        a(f'<rect x="{x0}" y="170" width="{x1 - x0}" height="5" fill="#d9dcde"/><rect x="{x0}" y="170" width="{x1 - x0}" height="1.2" fill="#fff" opacity="0.7"/>')
        a(f'<rect x="{x0}" y="209" width="{x1 - x0}" height="5" fill="#7d8386"/><rect x="{x0}" y="175" width="{x1 - x0}" height="2" fill="#5f6568" opacity="0.6"/>')
    for x in (4, 236):
        a(f'<rect x="{x}" y="185" width="20" height="14" rx="7" fill="#25292c"/><rect x="{x + 2}" y="196" width="16" height="1.4" fill="#fff" opacity="0.4"/>')
    a('<rect x="26" y="172" width="4" height="40" fill="#000" opacity="0.3"/><rect x="230" y="172" width="4" height="40" fill="#000" opacity="0.3"/>')
    # Escalones: frente elevado entre los hombros de los bornes (canto alto con luz, bajo en sombra)
    a('<rect x="31" y="87" width="198" height="4" fill="#fff" opacity="0.75"/><path d="M31,86.5 H229" stroke="#8d9396" stroke-width="1"/>')
    a('<path d="M31,310 H229" stroke="#7d8386" stroke-width="1.4"/><rect x="31" y="311" width="198" height="7" fill="url(#ia_paso)"/>')
    # Junta entre los dos módulos y remaches que los unen
    for y0, y1 in ((22, 86), (312, 358)):
        a(f'<path d="M130,{y0} V{y1}" stroke="#a5abae" stroke-width="1.2"/><path d="M131.2,{y0} V{y1}" stroke="#fff" stroke-width="0.8"/>')
    for x, y in ((40, 36), (220, 36), (40, 344), (220, 344)):
        a(f'<circle cx="{x}" cy="{y}" r="4.2" fill="#c6cacc"/><circle cx="{x}" cy="{y}" r="2.6" fill="url(#am_acero)"/><circle cx="{x}" cy="{y}" r="0.9" fill="#4f5558"/>')
    # Bornes: entrada del cable con la jaula a la vista y hueco del tornillo
    for x in (80, 180):
        for y, ent in ((52, 23), (328, 349)):
            a(f'<rect x="{x - 13}" y="{ent - 5}" width="26" height="10" rx="2" fill="#0b0c0d"/>')
            a(f'<rect x="{x - 10}" y="{ent - 2.5}" width="20" height="5" rx="1" fill="url(#ia_jaula)" opacity="0.85"/>')
            a(f'<circle cx="{x}" cy="{y}" r="10.4" fill="none" stroke="#050506" stroke-width="2.2"/>')
            a(f'<path d="M{x - 15},{y - 14} H{x + 15}" stroke="#fff" stroke-opacity="0.18" stroke-width="1"/>')
    # Pestaña del clip del carril con la ranura para el destornillador
    a('<path d="M114,358 H146 V370 Q146,374 142,374 H118 Q114,374 114,370 Z" fill="#e4e6e3" stroke="#9aa0a3" stroke-width="1"/>')
    a('<rect x="122" y="364" width="16" height="4" rx="2" fill="#4a4f53"/>')
    # Hendidura del frente alrededor del mando
    a(f'<rect x="55" y="149" width="{ancho_mando + 2}" height="88" rx="6.5" fill="none" stroke="#a9aeb0" stroke-width="1.2"/>')
    return d


d = modular(148)
a = d.append
# Maneta: estrías de agarre, brillo y sombra en su alojamiento
a('<rect x="90" y="182" width="80" height="6" fill="#000" opacity="0.45" filter="url(#desenfoque)"/>')
for x in range(96, 166, 6):
    a(f'<rect x="{x}" y="168" width="2.4" height="12" rx="1" fill="#3a3f43"/>')
a('<rect x="90" y="166" width="80" height="16" rx="3" fill="url(#ia_maneta)"/>')
a('<path d="M92,167 H168" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')
# Ventanilla del indicador de estado con su cristal
a('<rect x="62" y="248" width="26" height="18" rx="2" fill="none" stroke="#7a8084" stroke-width="2"/>')
a('<rect x="64" y="250" width="22" height="14" fill="url(#ia_cristal)"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "interruptor_automatico.svg"), "".join(d), P.DEFS + DEFS)
