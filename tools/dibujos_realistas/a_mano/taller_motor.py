"""Caja de bornes del motor de la mesa del Taller (480×320) sobre su SVG: espárragos de latón con
rosca, arandela y tuerca, tornillos que sujetan la regleta, nervios moldeados, junta de goma, borne
de tierra con su símbolo, taladros roscados de la tapa, prensaestopas con tuerca y sello, y
desgaste de la pintura en los cantos. Sin puentes: los pone el jugador."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tm_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<radialGradient id="tm_laton" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#fff3c8"/><stop offset="0.4" stop-color="#d6b25c"/><stop offset="0.8" stop-color="#8a6a26"/><stop offset="1" stop-color="#4f3a12"/></radialGradient>
<linearGradient id="tm_goma" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a2c2e"/><stop offset="1" stop-color="#0d0e0f"/></linearGradient>
<filter id="tm_desgaste" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.22" numOctaves="3" seed="21" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.55  0 0 0 0 0.6  0 0 0 0 0.62  0 0 0 22 -14.6" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
'''

d = []
a = d.append


def hexagono(x, y, r, giro=0):
    return " ".join(f"{x + r * math.cos(math.radians(30 + giro + 60 * i)):.1f},{y + r * math.sin(math.radians(30 + giro + 60 * i)):.1f}" for i in range(6))


def esparrago(x, y, giro):
    """Tuerca de latón del dibujo con su chaflán y caras iluminadas, y la punta roscada del espárrago."""
    s = ""
    pts = [(x + 20 * math.cos(math.radians(-90 + 60 * i)), y + 20 * math.sin(math.radians(-90 + 60 * i))) for i in range(6)]
    for i in range(6):
        (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % 6]
        luz = (0.28, 0.1, -0.12, -0.3, -0.12, 0.12)[i]
        color = "#fff" if luz > 0 else "#000"
        s += f'<path d="M{x},{y} L{x0:.1f},{y0:.1f} L{x1:.1f},{y1:.1f} Z" fill="{color}" opacity="{abs(luz):.2f}"/>'
    s += f'<circle cx="{x}" cy="{y}" r="16.6" fill="url(#tm_laton)" opacity="0.85"/>'
    s += f'<circle cx="{x}" cy="{y}" r="16.6" fill="none" stroke="#fff3c8" stroke-opacity="0.6" stroke-width="0.8"/>'
    s += f'<circle cx="{x}" cy="{y}" r="8.6" fill="#5f4615" opacity="0.7"/>'
    s += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="7.4" fill="url(#tm_acero)"/></g>'
    for r in (6.0, 4.6, 3.2):
        s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#4f5558" stroke-width="0.6"/>'
    s += f'<circle cx="{x}" cy="{y}" r="1.6" fill="#6c7276"/>'
    s += f'<ellipse cx="{x - 6}" cy="{y - 9}" rx="5" ry="2" fill="#fff" opacity="0.4" transform="rotate(-30 {x - 6} {y - 9})"/>'
    return s


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.2}" fill="#120d0a"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tm_acero)"/></g>'
    l = r * 0.62
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#2a2e31" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


# Desgaste de la pintura en los cantos de la caja y las aletas
a('<path d="M16,56 Q16,48 24,48 H456 Q464,48 464,56 V304 Q464,312 456,312 H24 Q16,312 16,304 Z M36,62 V300 H444 V62 Z" fill-rule="evenodd" fill="#46667f" filter="url(#tm_desgaste)" opacity="0.4"/>')
a('<path d="M17,50 H463" stroke="#a9c3d6" stroke-opacity="0.45" stroke-width="1.4"/>')
# Junta de goma de la tapa
a('<rect x="34" y="60" width="412" height="242" rx="6" fill="none" stroke="url(#tm_goma)" stroke-width="5"/>')
a('<rect x="32" y="58" width="416" height="246" rx="7" fill="none" stroke="#fff" stroke-opacity="0.08" stroke-width="1"/>')
# Taladros roscados de la tapa: rosca y brillo
for x, y in ((26, 58), (454, 58), (26, 302), (454, 302)):
    a(f'<circle cx="{x}" cy="{y}" r="5.2" fill="none" stroke="#0c1419" stroke-width="0.6"/>')
    a(f'<circle cx="{x}" cy="{y}" r="3.2" fill="#0b1116"/><circle cx="{x}" cy="{y}" r="2.2" fill="none" stroke="#6b7e8b" stroke-width="0.6"/>')

# Regleta: tornillos de fijación, nervios moldeados y canto brillante
for x, y in ((86, 94), (394, 94), (86, 256), (394, 256)):
    a(tornillo(x, y, 5, 30 + x % 11 * 5))
a('<path d="M80,81 H400" stroke="#9c7e62" stroke-opacity="0.55" stroke-width="1.2"/>')
for x in (185, 295):
    a(f'<rect x="{x - 1}" y="86" width="2" height="178" fill="#c09a78" opacity="0.25"/>')
# Espárragos con su tuerca (las bornes de U, V y W)
for i, (x, y) in enumerate(((130, 110), (240, 110), (350, 110), (130, 240), (240, 240), (350, 240))):
    a(esparrago(x, y, i * 7 % 20))

# Borne de tierra en la pared derecha con su símbolo
a('<rect x="414" y="150" width="22" height="48" rx="3" fill="#1d2226"/>')
a(f'<g filter="url(#bisel)"><polygon points="{hexagono(425, 166, 7)}" fill="#b9bfc2"/></g>')
a('<circle cx="425" cy="166" r="3" fill="url(#tm_acero)"/>')
a('<path d="M425,178 V184 M418,184 H432 M420,188 H430 M422.5,192 H427.5" stroke="#cdd3d6" stroke-width="1.5" stroke-linecap="round"/>')

# Prensaestopas: cuerpo roscado, tuerca de apriete y sello de goma
a('<rect x="214" y="298" width="52" height="12" rx="2" fill="none" stroke="#2b2f32" stroke-width="1"/>')
a('<path d="M210,300 H270" stroke="#fff" stroke-opacity="0.55" stroke-width="1"/>')
a('<rect x="224" y="306" width="32" height="6" rx="2" fill="#111"/>')
a('<rect x="228" y="307" width="24" height="2" rx="1" fill="#3a3e42"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "motor.svg"), "".join(d), P.DEFS + DEFS)
