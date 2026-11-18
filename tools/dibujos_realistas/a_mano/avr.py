"""Regulador automático de tensión (360×320) sobre su SVG: soportes antivibratorios en las esquinas,
tornillos de la tapa, escalas de los potenciómetros, LED con su lente, adhesivos de tensión y de
riesgo eléctrico, puerto de configuración con tapa de goma, portafusible, borne de tierra, regleta
con riel DIN, entradas de cable y punteras, y el mazo de cables con marcadores y bridas que entra
por un pasacables."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="avr_goma" cx="0.4" cy="0.35" r="0.8"><stop offset="0" stop-color="#3a3d40"/><stop offset="1" stop-color="#0b0c0d"/></radialGradient>
<radialGradient id="avr_led" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#7dff9a" stop-opacity="0.75"/><stop offset="0.45" stop-color="#3fbf5a" stop-opacity="0.3"/><stop offset="1" stop-color="#3fbf5a" stop-opacity="0"/></radialGradient>
<linearGradient id="avr_laton" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f3dc8a"/><stop offset="0.5" stop-color="#b8963a"/><stop offset="1" stop-color="#6e5518"/></linearGradient>
<linearGradient id="avr_riel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e6e9ea"/><stop offset="0.5" stop-color="#9aa1a5"/><stop offset="1" stop-color="#5d6467"/></linearGradient>
<linearGradient id="avr_cableV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.4" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="avr_cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.4"/><stop offset="0.4" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
'''

d = []
a = d.append


def tornillo_cruz(x, y, r):
    return (f'<circle cx="{x}" cy="{y}" r="{r + 0.8}" fill="#16181a"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#am_acero)"/>'
            f'<path d="M{x - r * 0.55:.1f},{y} H{x + r * 0.55:.1f} M{x},{y - r * 0.55:.1f} V{y + r * 0.55:.1f}" stroke="#2c3033" stroke-width="{r * 0.28:.1f}" stroke-linecap="round"/>')


# Soportes antivibratorios de goma en los cuatro agujeros de fijación
for x, y in ((34, 34), (326, 34), (34, 286), (326, 286)):
    a(f'<circle cx="{x}" cy="{y}" r="10.5" fill="url(#avr_goma)"/>')
    a(f'<circle cx="{x}" cy="{y}" r="10.5" fill="none" stroke="#000" stroke-opacity="0.5" stroke-width="0.8"/>')
    a(f'<circle cx="{x}" cy="{y}" r="7" fill="url(#am_acero)" stroke="#3b4043" stroke-width="0.6"/>')
    a(P.perno(x, y, 4.6))
    a(f'<circle cx="{x}" cy="{y}" r="1.6" fill="#7b8286"/>')

# Tapa: arista superior con luz y tornillos de cruz en las esquinas
a('<path d="M56,39.2 H304" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
a('<rect x="54" y="42" width="252" height="160" rx="4" fill="none" stroke="#000" stroke-opacity="0.35" stroke-width="1"/>')
for x, y in ((62, 50), (298, 50), (62, 194), (298, 194)):
    a(tornillo_cruz(x, y, 3.6))

# Escalas de los potenciómetros: marcas de recorrido y aro brillante
for cx in (82, 131, 180, 229, 278):
    cy = 112
    for i in range(11):
        ang = math.radians(135 + i * 27)
        r1, r2 = (19.5, 24) if i in (0, 5, 10) else (20, 22.5)
        a(f'<path d="M{cx + r1 * math.cos(ang):.1f},{cy + r1 * math.sin(ang):.1f} L{cx + r2 * math.cos(ang):.1f},{cy + r2 * math.sin(ang):.1f}" '
          f'stroke="#cfd4d6" stroke-width="{1.3 if i in (0, 5, 10) else 0.8}" stroke-linecap="round"/>')
    # Cuña de «más» por fuera de la escala
    a(f'<path d="M{cx - 15},{cy - 25.5} L{cx + 15},{cy - 28.5} L{cx + 15},{cy - 25.5} Z" fill="#cfd4d6" opacity="0.7"/>')
    a(f'<circle cx="{cx}" cy="{cy}" r="16.2" fill="none" stroke="#fff" stroke-opacity="0.18" stroke-width="0.8"/>')
    a(f'<ellipse cx="{cx - 5}" cy="{cy - 7}" rx="6" ry="3" fill="#fff" opacity="0.35" transform="rotate(-30 {cx - 5} {cy - 7})"/>')

# LED de encendido con bisel cromado, lente y halo
a('<circle cx="288" cy="62" r="13" fill="url(#avr_led)"/>')
a('<circle cx="288" cy="62" r="8" fill="none" stroke="url(#am_acero)" stroke-width="2.2"/>')
a('<circle cx="288" cy="62" r="5" fill="#5fe07a" opacity="0.55"/>')
a('<ellipse cx="286.3" cy="60" rx="2.2" ry="1.4" fill="#fff" opacity="0.85"/>')

# Adhesivo de tensión del alternador y triángulo de riesgo eléctrico
a('<rect x="66" y="52" width="66" height="22" rx="2" fill="#e9e6da" stroke="#9a9580" stroke-width="0.6"/>')
a('<rect x="66" y="52" width="66" height="6" rx="2" fill="#1f4f8a"/>')
a('<text x="99" y="68.5" text-anchor="middle" style="font:700 7.2px Plex;fill:#1d2226">380 V · 50 Hz</text>')
a('<path d="M232,52 L245,74 H219 Z" fill="#f2c200" stroke="#1a1a1a" stroke-width="1.4" stroke-linejoin="round"/>')
a('<path d="M233.5,58 L228.5,65.5 H232.5 L230,71 L236.5,63 H232.5 L235,58 Z" fill="#1a1a1a"/>')

# Puerto de configuración con tapa de goma
a('<rect x="252" y="172" width="40" height="18" rx="4" fill="#121416" stroke="#000" stroke-width="0.8"/>')
a('<rect x="256" y="175" width="32" height="12" rx="3" fill="#24272a"/>')
for x in range(260, 286, 4):
    a(f'<rect x="{x}" y="177" width="1.6" height="8" rx="0.8" fill="#3c4044"/>')
a('<path d="M253,173.2 H291" stroke="#fff" stroke-opacity="0.18" stroke-width="0.8"/>')

# Portafusible de bayoneta en el lateral derecho de la placa
a('<rect x="318" y="96" width="18" height="62" rx="3" fill="#1b1d1f" filter="url(#bisel)"/>')
a('<rect x="320" y="132" width="14" height="22" rx="1.5" fill="#2a2d30"/>')
a(P.perno(327, 138, 2) + P.perno(327, 149, 2))
a('<circle cx="327" cy="112" r="8" fill="#26292c" filter="url(#bisel)"/>')
a('<circle cx="327" cy="112" r="6" fill="none" stroke="#3d4145" stroke-width="1.4" stroke-dasharray="1.6 1.4"/>')
a('<path d="M322.5,112 H331.5" stroke="#0a0b0c" stroke-width="2" stroke-linecap="round"/>')

# Borne de tierra en el lateral izquierdo: espárrago de latón, terminal de ojal y símbolo grabado
a('<path d="M26,92 V102 M21,102 H31 M23,105 H29 M25,108 H27" stroke="#2a2e31" stroke-width="1.3" stroke-linecap="round"/>')
T = "M33,126 V190"
a(f'<path d="{T}" stroke="#000" stroke-opacity="0.35" stroke-width="6.5" transform="translate(1,1.5)"/>')
a(f'<path d="{T}" stroke="#2f9e4a" stroke-width="6"/>')
a(f'<path d="{T}" stroke="#f2c200" stroke-width="6" stroke-dasharray="9 6"/>')
a('<rect x="30" y="126" width="6" height="64" fill="url(#avr_cableV)"/>')
a(f'<path d="M31,128 V190" stroke="#fff" stroke-opacity="0.35" stroke-width="1"/>')
a('<circle cx="33" cy="126" r="8.5" fill="url(#am_acero)" stroke="#4f5558" stroke-width="0.6"/>')
a('<rect x="29.5" y="132" width="7" height="9" rx="1.2" fill="url(#am_brida)"/>')
a('<circle cx="33" cy="126" r="5.6" fill="url(#avr_laton)"/>' + P.perno(33, 126, 3.6))
a('<circle cx="33" cy="196" r="8" fill="url(#avr_goma)"/><circle cx="33" cy="196" r="4.2" fill="#030303"/>')
a('<path d="M33,188 V196" stroke="#2f9e4a" stroke-width="6"/>')

# Riel DIN asomando a los lados de la regleta, con sus topes
for x in (26, 322):
    a(f'<rect x="{x}" y="236" width="12" height="24" rx="1" fill="url(#avr_riel)" stroke="#4f5558" stroke-width="0.6"/>')
a('<rect x="29" y="244" width="6" height="8" rx="3" fill="#3b4043"/><rect x="325" y="244" width="6" height="8" rx="3" fill="#3b4043"/>')

# Regleta: aristas de cada borne, tapa final, entradas de cable con punteras
for x in (69, 100, 131, 162, 193, 224, 255, 286):
    a(f'<path d="M{x + 1.4},221 V276" stroke="#fff" stroke-opacity="0.45" stroke-width="0.9"/>')
a('<rect x="38" y="218" width="5" height="60" rx="1.5" fill="#8a836d" opacity="0.7"/>')
a('<rect x="317" y="218" width="5" height="60" rx="1.5" fill="#8a836d" opacity="0.7"/>')
a('<path d="M40,219.5 H320" stroke="#fff" stroke-opacity="0.5" stroke-width="1"/>')

# Mazo: colores de cada borne (U V W, F+ F−, S1 S2, R1 R2)
X = (54, 85, 116, 147, 178, 209, 240, 271, 302)
COLOR = ("#6b3f1f", "#1b1c1d", "#7d858a", "#b8322a", "#1f4fa0", "#e9e7df", "#e9e7df", "#d38a1f", "#d38a1f")
Y = (299, 295.5, 292, 288.5, None, 288.5, 292, 295.5, 299)
GX, GY = 180, 293
# Pasacables de goma en la placa
a(f'<circle cx="{GX}" cy="{GY}" r="10" fill="url(#avr_goma)"/><circle cx="{GX}" cy="{GY}" r="6.5" fill="#030303"/>')
for i in sorted(range(9), key=lambda k: -abs(k - 4)):
    x, c, y = X[i], COLOR[i], Y[i]
    if y is None:
        ruta = f"M{x},280 V{GY}"
    elif x < GX:
        ruta = f"M{x},280 V{y - 5} Q{x},{y} {x + 5},{y} H{GX - 4}"
    else:
        ruta = f"M{x},280 V{y - 5} Q{x},{y} {x - 5},{y} H{GX + 4}"
    a(f'<path d="{ruta}" fill="none" stroke="#000" stroke-opacity="0.35" stroke-width="4.6" stroke-linecap="round" stroke-linejoin="round" transform="translate(0.8,1.4)"/>')
    a(f'<path d="{ruta}" fill="none" stroke="{c}" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"/>')
    a(f'<path d="{ruta}" fill="none" stroke="#fff" stroke-opacity="0.3" stroke-width="0.9" stroke-linecap="round" transform="translate(-0.7,-0.7)"/>')
for x in X:
    # Entrada del borne con su borna y la puntera prensada que asoma
    a(f'<rect x="{x - 7}" y="266" width="14" height="9" rx="1.5" fill="#1d1b16"/>')
    a(f'<rect x="{x - 5}" y="267.5" width="10" height="3" fill="#8f979b"/>')
    a(f'<rect x="{x - 2.4}" y="271" width="4.8" height="8" rx="0.8" fill="url(#am_brida)"/>')
    a(f'<rect x="{x - 2.4}" y="279" width="4.8" height="2.6" rx="0.8" fill="#9aa0a3"/>')
    # Marcador de cable
    a(f'<rect x="{x - 3}" y="282" width="6" height="4.2" rx="1" fill="#f4f3ec" stroke="#8b8a80" stroke-width="0.4"/>')
    a(f'<path d="M{x - 1.6},284.1 H{x + 1.6}" stroke="#2a2e31" stroke-width="0.8"/>')
# Bridas de nailon en el mazo
for x, y0 in ((101, 292.5), (163, 285.5), (197, 285.5), (259, 292.5)):
    a(f'<rect x="{x - 1.8}" y="{y0}" width="3.6" height="{302 - y0}" rx="1.2" fill="#e8e6dc" stroke="#8b8a80" stroke-width="0.4"/>')
    a(f'<rect x="{x - 1}" y="{y0 + 0.5}" width="1" height="{301 - y0}" fill="#fff" opacity="0.7"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "avr.svg"), "".join(d), P.DEFS + DEFS)
