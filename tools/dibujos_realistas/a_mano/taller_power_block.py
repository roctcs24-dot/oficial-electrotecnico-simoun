"""Power block con su válvula direccional de la mesa del Taller (480×360) sobre su SVG: placas
laterales verdes con su fila de pernos y orejetas de izado, garganta forrada de caucho con
curvatura y desgaste, cubo con corona de pernos y engrasador, motor hidráulico con aletas,
pernos y racores, mangueras con brillo y casquillos prensados, bloque de válvulas con tornillos
Allen, bobinas con aletas y conector, palanca de mando manual, y regleta con bornes de jaula."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tpb_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<radialGradient id="tpb_hueco" cx="0.5" cy="0.4" r="0.6"><stop offset="0.45" stop-color="#030304"/><stop offset="0.85" stop-color="#16191b"/><stop offset="1" stop-color="#2f3336"/></radialGradient>
<linearGradient id="tpb_laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f3e0a2"/><stop offset="0.45" stop-color="#c2a04d"/><stop offset="1" stop-color="#6b5520"/></linearGradient>
<linearGradient id="tpb_garganta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.55"/><stop offset="0.2" stop-color="#000" stop-opacity="0.1"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.1"/><stop offset="0.7" stop-color="#000" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/></linearGradient>
<linearGradient id="tpb_motor" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.25"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.2"/><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="tpb_bobina" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.14"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<filter id="tpb_desgaste" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.35 0.06" numOctaves="2" seed="4" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.46  0 0 0 0 0.46  0 0 0 12 -7.4" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.3}" fill="#111315"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tpb_acero)"/></g>'
    l, l2 = r * 0.68, r * 0.42
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f}" stroke="#25292c" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>'
    t += f'<path d="M{x + l2 * s:.1f},{y - l2 * c:.1f} L{x - l2 * s:.1f},{y + l2 * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


def borne(x, y, i):
    s = f'<rect x="{x - 15}" y="{y - 14}" width="30" height="28" rx="3" fill="#1e2225"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.5" fill="url(#tpb_hueco)"/>'
    s += f'<g filter="url(#bisel)"><rect x="{x - 10}" y="{y - 8}" width="20" height="16" rx="2" fill="url(#tpb_laton)"/></g>'
    s += f'<rect x="{x - 7}" y="{y - 14}" width="14" height="5" rx="1.5" fill="#050606"/>'
    s += f'<rect x="{x - 5}" y="{y - 10.6}" width="10" height="1.1" fill="#c9a956" opacity="0.7"/>'
    s += tornillo(x, y, 7.8, -14 + (i * 23) % 30)
    return s


def allen(x, y, r=4):
    hexa = " ".join(f"{x + r * 0.5 * math.cos(math.radians(60 * i)):.1f},{y + r * 0.5 * math.sin(math.radians(60 * i)):.1f}" for i in range(6))
    return f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="#4a4f53"/></g><polygon points="{hexa}" fill="#0b0c0d"/>'


# Placas laterales: canto iluminado, fila de pernos y orejetas de izado
a('<path d="M62,42 L298,42" stroke="#8fc39d" stroke-opacity="0.6" stroke-width="1.5"/>')
for t in [i / 7 for i in range(8)]:
    a(P.perno(78 + (110 - 78) * t, 46 + (200 - 46) * t, 2.8))
    a(P.perno(282 + (250 - 282) * t, 46 + (200 - 46) * t, 2.8))
for t in (0.25, 0.5, 0.75):
    a(P.perno(110 + 140 * t, 196, 2.8))
for x in (70, 290):
    a(f'<circle cx="{x}" cy="40" r="9" fill="none" stroke="#244a30" stroke-width="5"/>')
    a(f'<circle cx="{x}" cy="40" r="9" fill="none" stroke="#5f9a6d" stroke-width="1.2" opacity="0.6"/>')
# Garganta de caucho: curvatura, nervios con brillo y desgaste de la cuerda
a('<path d="M96,52 L264,52 L228,176 L132,176 Z" fill="url(#tpb_garganta)"/>')
for x in range(104, 260, 20):
    a(f'<path d="M{x + 1.6},58 L{x + 13.6},170" stroke="#6c7276" stroke-opacity="0.5" stroke-width="1"/>')
a('<path d="M96,52 L264,52 L228,176 L132,176 Z" fill="#7a7d80" opacity="0.16" filter="url(#tpb_desgaste)"/>')
a('<path d="M98,53 H262" stroke="#000" stroke-width="2.4" opacity="0.6"/>')
# Cubo: corona de pernos, tuerca del eje y engrasador
a('<circle cx="180" cy="126" r="22" fill="none" stroke="#2b2f32" stroke-width="1"/>')
a(P.tuerca_pernos(180, 126, 16, 6, 2.6))
a('<circle cx="180" cy="126" r="9" fill="url(#tpb_acero)"/>')
a(f'<g filter="url(#bisel)"><polygon points="{" ".join(f"{180 + 6.5 * math.cos(math.radians(60 * i)):.1f},{126 + 6.5 * math.sin(math.radians(60 * i)):.1f}" for i in range(6))}" fill="#8a9094"/></g>')
a('<circle cx="180" cy="126" r="2.2" fill="#c9a956"/>')

# Motor hidráulico: curvatura de la carcasa, aletas con brillo, pernos y racores
a('<rect x="300" y="96" width="90" height="64" rx="8" fill="url(#tpb_motor)"/>')
for x in (320, 340, 360):
    a(f'<path d="M{x + 1.4},98 V158" stroke="#fff" stroke-opacity="0.5" stroke-width="0.8"/>')
for x, y in ((308, 104), (382, 104), (308, 152), (382, 152)):
    a(allen(x, y, 3.6))
a('<rect x="290" y="112" width="12" height="32" rx="2" fill="#5f6568"/>')
a('<path d="M290,114 H300" stroke="#fff" stroke-opacity="0.4" stroke-width="1"/>')
for x in (345, 372):
    a(f'<g filter="url(#bisel)"><rect x="{x - 8}" y="158" width="16" height="12" rx="2" fill="#c9a956"/></g>')
    a(f'<g filter="url(#bisel)"><rect x="{x - 7}" y="218" width="14" height="12" rx="2" fill="#c9a956"/></g>')
    a(f'<rect x="{x - 6.5}" y="170" width="13" height="10" rx="1.5" fill="url(#tpb_acero)"/>')
    a(f'<rect x="{x - 6.5}" y="208" width="13" height="10" rx="1.5" fill="url(#tpb_acero)"/>')
    for k in range(3):
        a(f'<rect x="{x - 6.5}" y="{171 + k * 3}" width="13" height="0.9" fill="#4f5558"/><rect x="{x - 6.5}" y="{209 + k * 3}" width="13" height="0.9" fill="#4f5558"/>')
    a(f'<path d="M{x - 2.5},181 V207" stroke="#fff" stroke-opacity="0.35" stroke-width="1.6" stroke-linecap="round"/>')

# Bloque de válvulas: tornillos Allen, bobinas con aletas, conector y palanca manual
for x, y in ((256, 232), (444, 232), (256, 290), (444, 290)):
    a(allen(x, y, 3.4))
a('<path d="M252,228 H448" stroke="#fff" stroke-opacity="0.55" stroke-width="1"/>')
for x0 in (262, 398):
    a(f'<rect x="{x0}" y="232" width="40" height="58" rx="4" fill="url(#tpb_bobina)"/>')
    for k in range(4):
        a(f'<rect x="{x0 + 4}" y="{256 + k * 7}" width="32" height="2" rx="1" fill="#0b0c0d"/>')
        a(f'<rect x="{x0 + 4}" y="{258 + k * 7}" width="32" height="0.7" fill="#fff" opacity="0.2"/>')
    a(f'<g filter="url(#bisel)"><rect x="{x0 + 6}" y="240" width="28" height="10" rx="2" fill="#5a3a12"/></g>')
    a(tornillo(x0 + 20, 245, 3, 30))
a('<rect x="314" y="246" width="72" height="30" rx="3" fill="none" stroke="#7a5a0c" stroke-width="1"/>')
for k in range(6):
    a(f'<path d="M{318 + k * 12},274 L{328 + k * 12},248" stroke="#1d1d1b" stroke-width="3.2" opacity="0.85"/>')
a('<rect x="336" y="255" width="28" height="12" rx="6" fill="#151719"/>')
a('<g filter="url(#bisel)"><circle cx="350" cy="261" r="5" fill="#c0392b"/></g>')
# Cables de las bobinas con brillo y su manguito
for x in (282, 418):
    a(f'<path d="M{x - 1.5},292 V318" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2"/>')
    a(f'<rect x="{x - 5}" y="290" width="10" height="6" rx="1.5" fill="#2f3438"/>')

# Regleta: bornes de jaula, separadores y tornillos de los extremos
for i, x in enumerate((110, 190, 310, 390)):
    a(borne(x, 322, i))
for x in (150, 250, 350):
    a(f'<g filter="url(#bisel)"><rect x="{x - 2.5}" y="{304}" width="5" height="36" rx="2" fill="#4c5358"/></g>')
for x in (54, 446):
    a(tornillo(x, 322, 4.2, 20))
a('<path d="M44,301 H456" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "power_block.svg"), "".join(d), P.DEFS + DEFS)
