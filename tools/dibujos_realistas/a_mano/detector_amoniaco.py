"""Detector de amoníaco de pared (300×360) sobre su SVG: orejetas de fijación, junta y tornillos de
la tapa, pantalla con bisel, matriz y reflejo, luces de alarma con lente (apagadas), teclas de
membrana, placa con la alimentación y la salida (datos de la ficha), prensaestopas con sus cables,
rosca y tuerca del cuello del sensor y filtro sinterizado del cabezal."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<pattern id="da_sinter" width="3" height="3" patternUnits="userSpaceOnUse"><rect width="3" height="3" fill="none"/><circle cx="1.5" cy="1.5" r="0.75" fill="#0e1012"/></pattern>
<pattern id="da_matriz" width="2.4" height="2.4" patternUnits="userSpaceOnUse"><rect width="2.4" height="2.4" fill="none"/><path d="M0,2.3 H2.4 M2.3,0 V2.4" stroke="#000" stroke-width="0.4"/></pattern>
<linearGradient id="da_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.31" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="da_cable" gradientUnits="userSpaceOnUse" x1="0" y1="276" x2="0" y2="358"><stop offset="0" stop-color="#1b1d1f"/><stop offset="0.75" stop-color="#1b1d1f"/><stop offset="1" stop-color="#1b1d1f" stop-opacity="0"/></linearGradient>
<linearGradient id="da_luzCable" gradientUnits="userSpaceOnUse" x1="0" y1="276" x2="0" y2="358"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.75" stop-color="#fff" stop-opacity="0.3"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="da_canto" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/><stop offset="0.8" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r):
    return (f'<circle cx="{x}" cy="{y}" r="{r + 0.8}" fill="#6e5518"/><circle cx="{x}" cy="{y}" r="{r}" fill="url(#am_acero)"/>'
            f'<path d="M{x - r * 0.55:.1f},{y} H{x + r * 0.55:.1f} M{x},{y - r * 0.55:.1f} V{y + r * 0.55:.1f}" stroke="#2c3033" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>')


# Orejetas de fijación a la pared
for x in (28, 260):
    for y in (44, 246):
        a(f'<rect x="{x}" y="{y - 9}" width="12" height="18" rx="3" fill="#a07c22"/>')
        a(f'<circle cx="{x + 6}" cy="{y}" r="3.4" fill="#2a2400"/>' + P.perno(x + 6, y, 2.6))
# Junta de la tapa y canto superior con luz
a('<rect x="40.5" y="20.5" width="219" height="249" rx="12" fill="none" stroke="#fff3c4" stroke-opacity="0.55" stroke-width="1"/>')
a('<rect x="46" y="26" width="208" height="238" rx="9" fill="none" stroke="#7a5d14" stroke-opacity="0.6" stroke-width="1.2"/>')
# Tornillos de la tapa
for x, y in ((58, 38), (242, 38), (58, 252), (242, 252)):
    a(tornillo(x, y, 4.6))

# Pantalla: bisel, matriz, sombra interior y reflejo del cristal
a('<rect x="70" y="60" width="160" height="70" rx="4" fill="url(#da_matriz)" opacity="0.25"/>')
a('<rect x="72" y="62" width="156" height="66" rx="3" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="2.4"/>')
a('<path d="M70,60 H230 L222,78 Q150,70 70,92 Z" fill="url(#da_cristal)"/>')

# Luces A1, A2 y avería: lentes con brillo, apagadas
for x in (100, 150, 200):
    a(f'<circle cx="{x}" cy="168" r="12.6" fill="none" stroke="#3a2e10" stroke-width="2.4"/>')
    a(f'<circle cx="{x}" cy="168" r="11" fill="none" stroke="#000" stroke-opacity="0.35" stroke-width="1"/>')
    a(f'<ellipse cx="{x - 3.4}" cy="163.6" rx="4" ry="2.4" fill="#fff" opacity="0.45" transform="rotate(-30 {x - 3.4} 163.6)"/>')
    a(f'<circle cx="{x + 3}" cy="172" r="1.4" fill="#fff" opacity="0.15"/>')

# Teclas de membrana: canto con luz y sombra
for x in (84, 162):
    a(f'<rect x="{x}" y="210" width="54" height="30" rx="4" fill="url(#da_canto)"/>')
    a(f'<rect x="{x - 2}" y="208" width="58" height="34" rx="5" fill="none" stroke="#7a5d14" stroke-opacity="0.7" stroke-width="1"/>')

# Placa con la alimentación y la salida
a(P.placa(104, 247, 92, 16, ["24 V DC · 4–20 mA"], 5.4))

# Prensaestopas de la caja con sus cables, que bajan por la pared
for x in (70, 94):
    # Rectángulos y no trazos: un trazo recto con degradado no tiene caja y no se pinta
    a(f'<rect x="{x - 3.5}" y="276" width="7" height="82" fill="url(#da_cable)"/>')
    a(f'<rect x="{x - 2.2}" y="276" width="1.2" height="82" fill="url(#da_luzCable)"/>')
    a(f'<rect x="{x - 9}" y="268" width="18" height="6" rx="1" fill="#2a2e31"/>')
    a(f'<polygon points="{x - 8},274 {x + 8},274 {x + 6},284 {x - 6},284" fill="#3a3e42"/>')
    a(f'<path d="M{x - 6},278 H{x + 6} M{x - 6},281 H{x + 6}" stroke="#1a1c1e" stroke-width="0.8"/>')

# Cuello del sensor: rosca y tuerca
for y in range(274, 294, 3):
    a(f'<path d="M122,{y} H178" stroke="#3b4043" stroke-width="1"/>')
    a(f'<path d="M122,{y + 1.2} H178" stroke="#fff" stroke-opacity="0.25" stroke-width="0.6"/>')
a('<polygon points="114,268 186,268 190,276 110,276" fill="url(#am_bridaV)" stroke="#3b4043" stroke-width="0.6"/>')
a('<path d="M136,268 V276 M164,268 V276" stroke="#3b4043" stroke-width="0.8"/>')
# Cabezal: filtro sinterizado, canto y tapa de calibración
a('<rect x="118" y="304" width="64" height="36" rx="6" fill="#4a4f53"/>')
a('<rect x="118" y="304" width="64" height="36" rx="6" fill="url(#da_sinter)"/>')
a('<path d="M118,312 H182 M118,322 H182 M118,332 H182" stroke="#20242a" stroke-width="3"/>')
a('<rect x="110.5" y="296.5" width="79" height="49" rx="10" fill="none" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')
a('<rect x="112" y="298" width="76" height="5" rx="2.5" fill="#fff" opacity="0.1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "detector_amoniaco.svg"), "".join(d), P.DEFS + DEFS)
