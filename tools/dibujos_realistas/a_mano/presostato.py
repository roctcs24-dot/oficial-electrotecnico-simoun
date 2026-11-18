"""Presostato industrial (300×380) sobre su SVG: caja con la junta de la tapa, cantos y tornillos,
husillos de ajuste con ranura y rosca, ventanas de escala con sombra interior, subdivisiones,
sombra de los índices y cristal, pulsador de rearme con aro y brillo, prensaestopas con caras de la
tuerca y cable, racor hexagonal de la conexión de presión con tuerca y tubo de acero con brillo
(en amoníaco no se usa cobre)."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ps_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.1" stop-color="#fff" stop-opacity="0"/><stop offset="0.9" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="ps_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.32"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ps_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.4"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.04"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="ps_hex" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.3" stop-color="#e3e6e8"/><stop offset="0.5" stop-color="#a7aeb2"/><stop offset="0.75" stop-color="#d0d4d6"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<linearGradient id="ps_tubo" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5d6367"/><stop offset="0.35" stop-color="#e3e6e8"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<linearGradient id="ps_cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a4f54"/><stop offset="0.4" stop-color="#2a2e31"/><stop offset="1" stop-color="#08090a"/></linearGradient>
<radialGradient id="ps_boton" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></radialGradient>
'''

d = []
a = d.append
# Caja: cantos, junta de la tapa (sin tramo alto, que pasaría bajo «CORTE») y tornillos
a('<rect x="50" y="30" width="200" height="260" rx="10" fill="url(#ps_lado)"/>')
a('<path d="M56,58 V277 Q56,284 63,284 H237 Q244,284 244,277 V58" fill="none" stroke="#5f6568" stroke-width="1.4"/>')
a('<path d="M57.6,58 V277 Q57.6,282.4 63,282.4 H237 Q242.4,282.4 242.4,277 V58" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="0.8"/>')
for x, y in ((66, 274), (234, 274), (66, 68), (234, 68)):
    a(f'<circle cx="{x}" cy="{y}" r="5" fill="#3a3e42"/><circle cx="{x}" cy="{y}" r="4" fill="url(#am_acero)"/>'
      f'<path d="M{x - 2.4},{y} H{x + 2.4} M{x},{y - 2.4} V{y + 2.4}" stroke="#2a2e31" stroke-width="1.1" stroke-linecap="round"/>')
# Husillos de ajuste: rosca, ranura y brillo
for x in (104, 196):
    a(f'<circle cx="{x}" cy="44" r="10" fill="none" stroke="#4f5558" stroke-width="1.2"/>')
    a(f'<circle cx="{x}" cy="44" r="6.6" fill="none" stroke="#6d7377" stroke-width="1" stroke-dasharray="1.6 1.6"/>')
    a(f'<path d="M{x - 6},44 H{x + 6}" stroke="#2a2e31" stroke-width="2.4" stroke-linecap="round"/>')
# Ventanas de escala: sombra interior, subdivisiones, sombra del índice y cristal
for y0, base in ((64, 96), (138, 170)):
    a(f'<rect x="77" y="{y0 + 1}" width="146" height="9" fill="url(#ps_sombraV)"/>')
    for x in (111, 141, 171, 200):
        a(f'<path d="M{x},{base} V{base - 5}" stroke="#20242a" stroke-width="1.2"/>')
    if base == 170:
        for x, h in ((96, 10), (126, 8), (156, 10), (186, 8), (214, 10)):
            a(f'<path d="M{x},{base} V{base - h}" stroke="#20242a" stroke-width="2"/>')
    xi = 150 if base == 96 else 120
    a(f'<path d="M{xi + 2.5},{y0 + 9} V{y0 + 42}" stroke="#000" stroke-opacity="0.25" stroke-width="3" filter="url(#desenfoque)"/>')
    a(f'<path d="M{xi},{y0 + 8} V{y0 + 40}" stroke="#c8312a" stroke-width="3"/>')
    a(f'<rect x="76" y="{y0}" width="148" height="44" rx="4" fill="url(#ps_cristal)"/>')
    a(f'<path d="M80,{y0 + 2.5} H220" stroke="#fff" stroke-opacity="0.6" stroke-width="1"/>')
# Pulsador de rearme: aro, brillo y canto
a('<circle cx="150" cy="232" r="24" fill="none" stroke="#6d7377" stroke-width="1.5"/>')
a('<circle cx="150" cy="232" r="16" fill="url(#ps_boton)"/>')
a('<path d="M138,224 A14,14 0 0 1 152,218" stroke="#fff" stroke-opacity="0.6" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
# Prensaestopas del cable: caras de la tuerca y cable con brillo
a('<path d="M250,244 H280 M250,252 H280" stroke="#0d0f11" stroke-width="1"/>')
a('<rect x="250" y="236" width="4" height="24" fill="#000" opacity="0.3"/>')
a('<rect x="280" y="243" width="20" height="10" fill="url(#ps_cable)"/>')
# Conexión de presión: racor hexagonal, tuerca y tubo de acero
a('<rect x="136" y="290" width="28" height="30" fill="url(#ps_hex)"/>')
a('<path d="M143,290 V320 M157,290 V320" stroke="#4f5558" stroke-width="0.8"/>')
a('<rect x="136" y="290" width="28" height="4" fill="#000" opacity="0.3"/>')
a('<rect x="140" y="328" width="20" height="16" rx="1.5" fill="url(#ps_hex)" stroke="#4f5558" stroke-width="0.6"/>')
a('<path d="M146,328 V344 M154,328 V344" stroke="#4f5558" stroke-width="0.7"/>')
a('<rect x="146" y="320" width="8" height="8" fill="url(#ps_tubo)"/><rect x="146" y="344" width="8" height="18" fill="url(#ps_tubo)"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "presostato.svg"), "".join(d), P.DEFS + DEFS)
