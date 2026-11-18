"""Relé térmico de montaje directo (360×440) sobre su SVG: pernos de cobre con brillo, ranura y
sombra de entrada, cantos del cuerpo, escala del dial de ajuste (12 a 18 A, cada 0,5 A) sobre el
aro negro con índice y moleteado, corredera A/H con su ranura, ventanilla del testigo de disparo,
relieve y brillo de los pulsadores RESET y STOP, jaulas de los bornes con la entrada del cable y
cantos de las barreras."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="rt_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.16"/><stop offset="0.12" stop-color="#fff" stop-opacity="0"/><stop offset="0.88" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="rt_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="rt_boton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.04"/><stop offset="0.8" stop-color="#000" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="rt_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.04"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="rt_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#eef0f1"/><stop offset="0.5" stop-color="#a7aeb2"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<radialGradient id="rt_perilla" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.6"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></radialGradient>
'''

CX, CY = 132, 176
d = []
a = d.append
# Pernos de cobre: ranura central, brillo y sombra donde entran en el cuerpo
for x in (100, 172, 244):
    a(f'<rect x="{x + 3}" y="0" width="2" height="56" fill="#fff" opacity="0.35"/>')
    a(f'<rect x="{x + 7}" y="0" width="2" height="56" fill="#5a2e12" opacity="0.45"/>')
    a(f'<rect x="{x}" y="44" width="16" height="12" fill="url(#rt_sombraV)" transform="rotate(180 {x + 8} 50)"/>')
    a(f'<rect x="{x - 3}" y="54" width="22" height="5" rx="2" fill="#191b1d"/>')
# Cantos del cuerpo con luz y sombra
a('<rect x="60" y="56" width="240" height="288" fill="url(#rt_lado)"/>')
a('<path d="M62,57.5 H298" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
a('<rect x="64" y="345" width="232" height="8" fill="url(#rt_sombraV)"/>')
# Escala del dial sobre el aro negro: de 12 A (abajo a la izquierda) a 18 A (abajo a la derecha)
for i in range(13):
    g = math.radians(151 + i * 238 / 12)
    largo = 6 if i % 2 == 0 else 3.6
    r1 = 33
    a(f'<path d="M{CX + r1 * math.cos(g):.1f},{CY + r1 * math.sin(g):.1f} L{CX + (r1 + largo) * math.cos(g):.1f},{CY + (r1 + largo) * math.sin(g):.1f}" stroke="#eceee8" stroke-width="{1.5 if i % 2 == 0 else 1}"/>')
# Perilla: moleteado, brillo y flecha índice en la ranura
for i in range(40):
    g = math.radians(i * 9)
    a(f'<path d="M{CX + 27.5 * math.cos(g):.1f},{CY + 27.5 * math.sin(g):.1f} L{CX + 30.5 * math.cos(g):.1f},{CY + 30.5 * math.sin(g):.1f}" stroke="#7d8285" stroke-width="1.1"/>')
a(f'<circle cx="{CX}" cy="{CY}" r="31" fill="url(#rt_perilla)"/>')
g = math.radians(270 + 32)
a(f'<path d="M{CX + 21 * math.cos(g):.1f},{CY + 21 * math.sin(g):.1f} L{CX + 28 * math.cos(g):.1f},{CY + 28 * math.sin(g):.1f}" stroke="#f4f4f0" stroke-width="2.2" stroke-linecap="round"/>')
a(f'<circle cx="{CX}" cy="{CY}" r="2.4" fill="#8d9396"/>')
# Corredera A/H: ranura para el destornillador y guía
a('<rect x="202" y="147" width="4" height="22" rx="2" fill="#0b0c0d"/>')
a('<rect x="198" y="133" width="12" height="3" rx="1.5" fill="#2a2d30"/><rect x="196" y="126" width="16" height="3" fill="#fff" opacity="0.35"/>')
# Ventanilla del testigo de disparo con su cristal
a('<rect x="196" y="194" width="28" height="38" rx="1" fill="url(#rt_cristal)"/>')
a('<path d="M197,230 L223,198" stroke="#fff" stroke-opacity="0.15" stroke-width="4"/>')
# Pulsadores RESET y STOP: relieve y brillo
for y in (128, 200):
    a(f'<rect x="244" y="{y}" width="32" height="32" rx="3" fill="url(#rt_boton)"/>')
    a(f'<path d="M246,{y + 1.5} H274" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')
    a(f'<rect x="240" y="{y + 36}" width="40" height="5" fill="url(#rt_sombraV)"/>')
# Bornes del contacto auxiliar: jaula alrededor del tornillo
for x in (96, 152, 208, 264):
    a(f'<circle cx="{x}" cy="282" r="12.4" fill="none" stroke="url(#rt_jaula)" stroke-width="2.4"/>')
    a(f'<rect x="{x - 7}" y="292" width="14" height="4" rx="1" fill="#050506"/>')
# Bornes de potencia: borde de la jaula y entrada del cable abajo
for x in (110, 180, 250):
    a(f'<rect x="{x - 14}" y="366" width="28" height="28" rx="3" fill="none" stroke="#2b2e31" stroke-width="1"/>')
    a(f'<path d="M{x - 13},367 H{x + 13}" stroke="#fff" stroke-opacity="0.45" stroke-width="1"/>')
    a(f'<rect x="{x - 12}" y="396" width="24" height="5" rx="1.5" fill="#000"/>')
# Canto con luz de las barreras
for x in (142, 212):
    a(f'<rect x="{x}" y="348" width="1.6" height="76" rx="0.8" fill="#fff" opacity="0.22"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "rele_termico.svg"), "".join(d), P.DEFS + DEFS)
