"""Monitor de aislamiento de cuadro (300×360) sobre su SVG: tornillos del marco con su ranura,
esfera hundida con sombra interior, subdivisiones de la escala, aguja con sombra y tapa del eje,
cristal con reflejo, pilotos con aro cromado, lente y halo
(ON encendido, ALARM apagado) y teclas con relieve y brillo."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ma_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.38"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ma_sombraH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.28"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ma_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.34"/><stop offset="0.4" stop-color="#fff" stop-opacity="0.05"/><stop offset="1" stop-color="#9fb4c4" stop-opacity="0.08"/></linearGradient>
<linearGradient id="ma_tecla" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.04"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<radialGradient id="ma_tapa" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#9aa0a5"/><stop offset="0.5" stop-color="#2c3034"/><stop offset="1" stop-color="#0c0d0f"/></radialGradient>
<radialGradient id="ma_lente" cx="0.36" cy="0.3" r="0.75"><stop offset="0" stop-color="#fff" stop-opacity="0.85"/><stop offset="0.35" stop-color="#fff" stop-opacity="0.1"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/></radialGradient>
<radialGradient id="ma_halo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#6cf08a" stop-opacity="0.6"/><stop offset="1" stop-color="#6cf08a" stop-opacity="0"/></radialGradient>
'''

AX, AY = 150, 202.6   # centro del arco de la escala
d = []
a = d.append
# Tornillos del marco: ranura en cruz y sombra de contacto
for x, y in ((44, 34), (256, 34), (44, 326), (256, 326)):
    a(f'<circle cx="{x}" cy="{y}" r="7" fill="none" stroke="#0b0c0d" stroke-width="1.4"/>')
    a(f'<path d="M{x - 3.6},{y} H{x + 3.6} M{x},{y - 3.6} V{y + 3.6}" stroke="#2a2e31" stroke-width="1.6" stroke-linecap="round"/>')
a('<path d="M34,17.5 H266" stroke="#fff" stroke-opacity="0.2" stroke-width="1.5"/>')
# Esfera hundida: escalón del marco y sombra interior
a('<rect x="45" y="41" width="210" height="156" rx="5" fill="none" stroke="#0c0e10" stroke-width="2"/>')
a('<rect x="46" y="42" width="208" height="12" fill="url(#ma_sombraV)"/>')
a('<rect x="46" y="42" width="9" height="154" fill="url(#ma_sombraH)"/>')
# Subdivisiones entre las marcas principales de la escala
for i in range(6):
    for k in (1, 2):
        g = math.radians(211.3 + i * 19.6 + k * 6.53)
        a(f'<path d="M{AX + 84 * math.cos(g):.1f},{AY + 84 * math.sin(g):.1f} L{AX + 90 * math.cos(g):.1f},{AY + 90 * math.sin(g):.1f}" stroke="#20242a" stroke-width="1.2"/>')
# Aguja: sombra y tapa del eje
px, py, cx, cy = 108, 128, 150, 190
l = math.hypot(px - cx, py - cy)
ux, uy = (px - cx) / l, (py - cy) / l
cola = (cx - ux * 5, cy - uy * 5)
a(f'<path d="M{cola[0] + 3:.1f},{cola[1] + 4:.1f} L{px + 3},{py + 4}" stroke="#000" stroke-opacity="0.28" stroke-width="3.5" stroke-linecap="round" filter="url(#desenfoque)"/>')
a(f'<path d="M{cx},{cy} L{px},{py}" stroke="#20242a" stroke-width="3" stroke-linecap="round"/>')
a(f'<circle cx="{cx}" cy="{cy}" r="7.5" fill="url(#ma_tapa)"/><circle cx="{cx}" cy="{cy}" r="2.4" fill="#0b0c0d"/>')
# Cristal de la esfera
a('<rect x="46" y="42" width="208" height="154" rx="4" fill="url(#ma_cristal)"/>')
a('<path d="M46,104 L120,42 H150 L46,130 Z" fill="#fff" opacity="0.09"/>')
a('<path d="M50,44.5 H250" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')
# Pilotos: aro cromado y lente; el verde encendido con su halo
a('<circle cx="104" cy="222" r="17" fill="url(#ma_halo)"/>')
for x in (104, 196):
    a(f'<circle cx="{x}" cy="222" r="10.5" fill="none" stroke="url(#am_acero)" stroke-width="3"/>')
    a(f'<circle cx="{x}" cy="222" r="8" fill="url(#ma_lente)" opacity="{1 if x == 104 else 0.55}"/>')
# Teclas TEST y RESET: canto, relieve y brillo
for x in (62, 158):
    a(f'<rect x="{x - 2}" y="268" width="84" height="42" rx="8" fill="none" stroke="#0c0e10" stroke-width="2"/>')
    a(f'<rect x="{x}" y="270" width="80" height="38" rx="6" fill="url(#ma_tecla)"/>')
    a(f'<path d="M{x + 4},271.5 H{x + 76}" stroke="#fff" stroke-opacity="0.4" stroke-width="1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "monitor_aislamiento.svg"), "".join(d), P.DEFS + DEFS)
