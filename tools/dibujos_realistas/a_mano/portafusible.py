"""Portafusible seccionable de carril DIN (200×380) sobre su SVG: carril con labios y ranuras,
cantos del cuerpo, bornes con jaula y entrada del cable, portacartucho con su bisagra y estrías del
asa, ventana con cristal, casquillos del cartucho 10×38 con sus aristas y brillo, lente del
indicador de fusión y pestaña del clip del carril."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="pf_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.16"/><stop offset="0.12" stop-color="#fff" stop-opacity="0"/><stop offset="0.88" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.32"/></linearGradient>
<linearGradient id="pf_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#eef0f1"/><stop offset="0.5" stop-color="#a7aeb2"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<linearGradient id="pf_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.4" stop-color="#fff" stop-opacity="0.03"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="pf_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.5"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<radialGradient id="pf_lente" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.85"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></radialGradient>
'''

d = []
a = d.append
# Carril DIN a los lados: labios, fondo y ranuras
for x0, x1 in ((0, 44), (156, 200)):
    w = x1 - x0
    a(f'<rect x="{x0}" y="160" width="{w}" height="8" fill="#e7eaeb"/><rect x="{x0}" y="160" width="{w}" height="1.3" fill="#fff"/>')
    a(f'<rect x="{x0}" y="168" width="{w}" height="3" fill="#000" opacity="0.22"/>')
    a(f'<rect x="{x0}" y="212" width="{w}" height="8" fill="#868c90"/>')
a('<rect x="8" y="182" width="26" height="16" rx="8" fill="#202427"/><rect x="166" y="182" width="26" height="16" rx="8" fill="#202427"/>')
a('<rect x="44" y="162" width="4" height="56" fill="#000" opacity="0.3"/><rect x="152" y="162" width="4" height="56" fill="#000" opacity="0.3"/>')
# Cantos del cuerpo
a('<rect x="45" y="13" width="110" height="354" rx="7" fill="url(#pf_lado)"/>')
# Bornes: jaula de acero alrededor del tornillo y entrada del cable
for y, ent in ((46, 22), (334, 357)):
    a(f'<path fill-rule="evenodd" fill="url(#pf_jaula)" stroke="#202326" stroke-width="0.8" '
      f'd="M82,{y - 17} H118 V{y + 17} H82 Z M115,{y} A15,15 0 1 0 85,{y} A15,15 0 1 0 115,{y} Z"/>')
    a(f'<rect x="84" y="{ent - 3}" width="32" height="6" rx="2" fill="#050506"/>')
# Portacartucho: bisagra abajo, estrías del asa y sombra sobre el cuerpo
a('<rect x="52" y="296" width="96" height="8" fill="url(#pf_sombraV)"/>')
for x in (47, 147):
    a(f'<circle cx="{x + 3}" cy="282" r="5" fill="#2a2d30"/><circle cx="{x + 3}" cy="282" r="3" fill="url(#am_acero)"/>')
for x in range(66, 136, 6):
    a(f'<rect x="{x}" y="99" width="2.4" height="10" rx="1" fill="#14171a"/>')
a('<path d="M52,86 H148" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2"/>')
# Cartucho: aristas de los casquillos, brillo y sombra de la cerámica
for y in (128, 246):
    a(f'<path d="M81,{y + 2.5} H119 M81,{y + 19.5} H119" stroke="#5d6367" stroke-width="1"/>')
    a(f'<rect x="86" y="{y + 1}" width="5" height="20" fill="#fff" opacity="0.45"/>')
a('<rect x="114" y="150" width="7" height="98" fill="#000" opacity="0.08"/>')
# Ventana: cristal con reflejo
a('<rect x="66" y="122" width="68" height="150" rx="6" fill="url(#pf_cristal)"/>')
a('<path d="M68,182 L132,128 V146 L68,200 Z" fill="#fff" opacity="0.06"/>')
a('<rect x="66" y="122" width="68" height="150" rx="6" fill="none" stroke="#0b0c0d" stroke-width="1.5"/>')
# Lente del indicador de fusión
a('<circle cx="100" cy="286" r="7.5" fill="none" stroke="#1b1d20" stroke-width="2"/>')
a('<circle cx="100" cy="286" r="5" fill="url(#pf_lente)"/>')
# Pestaña del clip del carril
a('<path d="M84,366 H116 V374 Q116,378 112,378 H88 Q84,378 84,374 Z" fill="#3a3e42" stroke="#191b1d" stroke-width="1"/>')
a('<rect x="92" y="370" width="16" height="3.5" rx="1.7" fill="#0b0c0d"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "portafusible.svg"), "".join(d), P.DEFS + DEFS)
