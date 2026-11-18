"""Puente rectificador de 25 A (400×220) sobre su SVG: caja de epoxi negra con canto biselado y su
brillo, esquina achaflanada del borne positivo, marcas de los expulsores del molde, ojal metálico del
tornillo del disipador con su fondo, y faston estañados con su agujero, el doblez y el reflejo."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<clipPath id="pr_fuera"><path d="M0,0 H400 V220 H0 Z M130,38 H270 Q272,38 272,40 V180 Q272,182 270,182 H130 Q128,182 128,180 V40 Q128,38 130,38 Z" clip-rule="evenodd"/></clipPath>
<linearGradient id="pr_canto" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.05"/>
 <stop offset="0.75" stop-color="#000" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
<linearGradient id="pr_cara" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.1"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.15"/></linearGradient>
<linearGradient id="pr_chaflan" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#a3aaaf"/><stop offset="0.6" stop-color="#5d646a"/><stop offset="1" stop-color="#3a3f44"/></linearGradient>
<radialGradient id="pr_ojal" cx="0.5" cy="0.5" r="0.5">
 <stop offset="0.5" stop-color="#000" stop-opacity="0"/><stop offset="0.56" stop-color="#000" stop-opacity="0.45"/>
 <stop offset="0.66" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.9" stop-color="#000" stop-opacity="0.05"/>
 <stop offset="1" stop-color="#000" stop-opacity="0.4"/></radialGradient>
<radialGradient id="pr_fondo" cx="0.5" cy="0.62" r="0.6">
 <stop offset="0" stop-color="#4a5056"/><stop offset="0.6" stop-color="#16181a"/><stop offset="1" stop-color="#050606"/></radialGradient>
<linearGradient id="pr_faston" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#8b9196"/><stop offset="0.3" stop-color="#ffffff"/><stop offset="0.55" stop-color="#c9ced1"/><stop offset="1" stop-color="#6c7378"/></linearGradient>
'''

d = []
a = d.append
# Canto biselado de la caja y cara superior algo hundida con el relleno de epoxi
a('<rect x="128" y="38" width="144" height="144" rx="8" fill="url(#pr_canto)"/>')
a('<rect x="134" y="44" width="132" height="132" rx="5" fill="url(#pr_cara)" stroke="#000" stroke-opacity="0.5" stroke-width="1"/>')
a('<rect x="135" y="45" width="130" height="130" rx="4.5" fill="none" stroke="#fff" stroke-opacity="0.1" stroke-width="0.8"/>')
# Esquina achaflanada del positivo
a('<path d="M129,40 Q129,38 131,38 L149,38 L128.6,58.4 Z" fill="url(#pr_chaflan)"/>')
a('<path d="M150,38.4 L128.4,60" stroke="#c9ced2" stroke-width="1.2"/>')
# Marcas de los expulsores del molde
for x, y in ((150, 110), (250, 110)):
    a(f'<circle cx="{x}" cy="{y}" r="5" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="1"/>')
    a(f'<circle cx="{x + 0.5}" cy="{y + 0.6}" r="5" fill="none" stroke="#fff" stroke-opacity="0.1" stroke-width="0.8"/>')
# Ojal metálico del tornillo del disipador
a('<circle cx="200" cy="110" r="17" fill="url(#pr_ojal)"/>')
a('<path d="M188,100 A15,15 0 0 1 208,96" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.75" stroke-linecap="round"/>')
a('<circle cx="200" cy="110" r="9" fill="url(#pr_fondo)"/>')
a('<path d="M193.5,114 A8,8 0 0 0 206.5,114" fill="none" stroke="#9aa1a6" stroke-width="0.9" opacity="0.6"/>')
# Faston estañados: agujero, doblez de salida y reflejo (en coordenadas de cada faston)
for cx, cy, ang, abajo in ((121, 35, -45, False), (279, 35, 45, False), (279, 185, -45, True), (121, 185, 45, True)):
    g = f'<g clip-path="url(#pr_fuera)"><g transform="rotate({ang} {cx} {cy})">'
    punta = cy + 6 if abajo else cy - 6
    g += f'<rect x="{cx - 9}" y="{cy - 13}" width="18" height="26" rx="2" fill="url(#pr_faston)" opacity="0.8"/>'
    g += f'<circle cx="{cx}" cy="{punta}" r="2.8" fill="#1a1c1e"/>'
    g += f'<circle cx="{cx}" cy="{punta}" r="3.6" fill="none" stroke="#fff" stroke-width="0.6" opacity="0.6"/>'
    g += f'<path d="M{cx - 5},{cy - 11.5} V{cy + 11.5}" stroke="#fff" stroke-width="1.2" opacity="0.7"/>'
    a(g + '</g></g>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "puente_rectificador.svg"), "".join(d), P.DEFS + DEFS)
