"""Máquina principal con su caja de bornes de 24 V DC (1000×400) sobre su SVG: tapas de culata con
tuercas, grifo indicador y tubo de inyección, ramales y colector de escape con forro aislante
acolchado y abrazaderas, turbos con voluta, rejilla del filtro y tuerca central, bloque con
puertas del cárter y válvulas de alivio, virador con aletas, bancada con pernos de anclaje,
conducto flexible y caja de bornes con tornillos de tapa, carril DIN, bornes grises con tornillo y
entradas de cable, separadores y prensaestopas. Respeta los textos del SVG («virador», «CMR» y
«MÁQUINA PRINCIPAL») y deja libre la fila de marcas de los bornes."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tmp_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="tmp_borne" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6d7377"/><stop offset="0.25" stop-color="#b4babd"/><stop offset="0.6" stop-color="#9aa0a4"/><stop offset="1" stop-color="#5b6165"/></linearGradient>
<linearGradient id="tmp_carril" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5f6568"/><stop offset="0.12" stop-color="#eef0f0"/><stop offset="0.3" stop-color="#a3a9ac"/><stop offset="0.85" stop-color="#c9cdce"/><stop offset="1" stop-color="#5c6265"/></linearGradient>
<linearGradient id="tmp_tapa" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.15" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.8" stop-color="#000" stop-opacity="0.05"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<linearGradient id="tmp_forro" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.4"/><stop offset="0.35" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#5a4e30" stop-opacity="0.4"/></linearGradient>
<linearGradient id="tmp_flexible" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2a2e31"/><stop offset="0.35" stop-color="#9aa0a3"/><stop offset="1" stop-color="#1d2023"/></linearGradient>
<radialGradient id="tmp_voluta" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#b9bfa8"/><stop offset="0.7" stop-color="#7f8670"/><stop offset="1" stop-color="#4f5546"/></radialGradient>
<pattern id="tmp_puntada" width="8" height="24" patternUnits="userSpaceOnUse"><rect width="4" height="1" y="12" fill="#7d7258" opacity="0.6"/></pattern>
'''

d = []
a = d.append


def tornillo(x, y, r, ang, cruz=True):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.2}" fill="#15181a"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tmp_acero)"/></g>'
    l = r * 0.62
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f}" stroke="#25292c" stroke-width="{r * 0.28:.1f}" stroke-linecap="round"/>'
    if cruz:
        t += f'<path d="M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#25292c" stroke-width="{r * 0.26:.1f}" stroke-linecap="round"/>'
    return t


CILINDROS = [80 + 96 * i for i in range(8)]

# Colector de escape: forro aislante acolchado con puntadas y abrazaderas
a('<rect x="76" y="46" width="776" height="24" rx="10" fill="url(#tmp_puntada)"/>')
for x in range(116, 852, 48):
    a(f'<path d="M{x},47 V69" stroke="#9f9478" stroke-width="1.2"/><path d="M{x + 1.2},47 V69" stroke="#fff" stroke-opacity="0.35" stroke-width="0.8"/>')
a('<rect x="76" y="46" width="776" height="24" rx="10" fill="url(#tmp_forro)"/>')
for x in (164, 356, 548, 740):
    a(f'<rect x="{x - 3}" y="44" width="6" height="28" rx="1.5" fill="url(#tmp_acero)"/>')
    a(P.perno(x, 44, 2.2))
# Escape al turbo
a('<path d="M852,58 H880 V86" fill="none" stroke="#d9cfb4" stroke-width="18" stroke-linejoin="round"/>')
a('<path d="M852,58 H880 V86" fill="none" stroke="url(#tmp_forro)" stroke-width="18" stroke-linejoin="round"/>')
a('<path d="M852,50 H880" stroke="#fff" stroke-opacity="0.4" stroke-width="1.5"/>')

# Tapas de culata: brillo, cuatro tuercas, grifo indicador y tubo de inyección
for x in CILINDROS:
    a(f'<rect x="{x}" y="72" width="80" height="52" rx="6" fill="url(#tmp_tapa)"/>')
    for px, py in ((x + 9, 80), (x + 71, 80), (x + 9, 116), (x + 71, 116)):
        a(P.perno(px, py, 3.6))
    a(f'<rect x="{x + 52}" y="64" width="6" height="10" fill="#5d6452"/>')
    a(f'<rect x="{x + 47}" y="62" width="16" height="4" rx="2" fill="#2a2e31"/>')
    a(f'<path d="M{x + 24},124 C{x + 24},108 {x + 30},104 {x + 34},98" fill="none" stroke="#9aa0a3" stroke-width="2.2"/>')
    a(f'<path d="M{x + 23.4},124 C{x + 23.4},108 {x + 29.4},104 {x + 33.4},98" fill="none" stroke="#fff" stroke-opacity="0.45" stroke-width="0.7"/>')
    a(f'<circle cx="{x + 40}" cy="98" r="9" fill="none" stroke="#5d6452" stroke-width="1"/>')

# Bloque: canto iluminado, línea de la bancada del cárter, puertas con válvula de alivio
a('<path d="M64,122 H856" stroke="#fff" stroke-opacity="0.45" stroke-width="1.5"/>')
a('<path d="M62,186 H858" stroke="#5d6452" stroke-width="1.4"/><path d="M62,187.4 H858" stroke="#fff" stroke-opacity="0.3" stroke-width="0.8"/>')
for i, x in enumerate(CILINDROS):
    if i in (3, 4):
        continue
    cx = x + 40
    a(f'<g filter="url(#bisel)"><rect x="{cx - 26}" y="194" width="52" height="38" rx="10" fill="#9da58a"/></g>')
    for px, py in ((cx - 20, 199), (cx + 20, 199), (cx - 20, 227), (cx + 20, 227)):
        a(P.perno(px, py, 2.2))
    a(f'<circle cx="{cx}" cy="213" r="8" fill="#7b8270" stroke="#4f5546" stroke-width="1"/>')
    a(f'<circle cx="{cx}" cy="213" r="4" fill="#5d6452"/>')
# Turbos: voluta, rejilla del filtro silenciador y tuerca central
for cx in (880, 940):
    a(f'<circle cx="{cx}" cy="120" r="34" fill="url(#tmp_voluta)" opacity="0.85"/>')
    a(f'<path d="M{cx + 30},120 A30,30 0 1 1 {cx},90 A26,26 0 0 1 {cx + 26},116" fill="none" stroke="#4f5546" stroke-width="1.4"/>')
    for r in (22, 18):
        a(f'<circle cx="{cx}" cy="120" r="{r}" fill="none" stroke="#3f4538" stroke-width="1.2" stroke-dasharray="2 1.4"/>')
    a(f'<circle cx="{cx}" cy="120" r="14" fill="#2f3529"/>')
    for k in range(10):
        ang = math.radians(k * 36)
        a(f'<path d="M{cx + 6 * math.cos(ang):.1f},{120 + 6 * math.sin(ang):.1f} L{cx + 13 * math.cos(ang + 0.5):.1f},{120 + 13 * math.sin(ang + 0.5):.1f}" stroke="#8a9178" stroke-width="1.2"/>')
    a(f'<g filter="url(#bisel)"><circle cx="{cx}" cy="120" r="4.4" fill="url(#tmp_acero)"/></g>')
    a(f'<ellipse cx="{cx - 12}" cy="99" rx="10" ry="4" fill="#fff" opacity="0.25" transform="rotate(-30 {cx - 12} 99)"/>')
# Virador: aletas del motor y caja reductora
a('<circle cx="40" cy="180" r="34" fill="none" stroke="#4f5546" stroke-width="1"/>')
for k in range(8):
    ang = math.radians(k * 45 + 10)
    a(f'<path d="M{40 + 14 * math.cos(ang):.1f},{180 + 14 * math.sin(ang):.1f} L{40 + 30 * math.cos(ang):.1f},{180 + 30 * math.sin(ang):.1f}" stroke="#4f5546" stroke-width="3" stroke-linecap="round"/>')
    a(f'<path d="M{40 + 14 * math.cos(ang) + 1:.1f},{180 + 14 * math.sin(ang) - 1:.1f} L{40 + 30 * math.cos(ang) + 1:.1f},{180 + 30 * math.sin(ang) - 1:.1f}" stroke="#fff" stroke-opacity="0.25" stroke-width="1"/>')
a('<circle cx="40" cy="180" r="12" fill="#5d6452"/>')
a('<g filter="url(#bisel)"><circle cx="40" cy="180" r="6" fill="url(#tmp_acero)"/></g>')
# Bancada: canto iluminado y pernos de anclaje con su tuerca
a('<path d="M22,238 H978" stroke="#fff" stroke-opacity="0.35" stroke-width="1.4"/>')
for x in range(50, 980, 60):
    a(P.perno(x, 262, 4.4))
    a(f'<rect x="{x - 9}" y="268" width="18" height="5" rx="1" fill="#4f5546"/>')

# Conducto flexible de los cables de la máquina a la caja de bornes
a('<path d="M900,154 C900,220 960,230 960,296" fill="none" stroke="url(#tmp_flexible)" stroke-width="12"/>')
a('<path d="M900,154 C900,220 960,230 960,296" fill="none" stroke="#111" stroke-width="12" stroke-dasharray="1.2 3" opacity="0.7"/>')
a('<g filter="url(#bisel)"><rect x="950" y="290" width="20" height="10" rx="2" fill="#b9bfc2"/></g>')

# Caja de bornes: tornillos de la tapa, carril DIN, bornes grises y prensaestopas
for x in (40, 500, 960):
    for y in (306, 382):
        a(tornillo(x, y, 4.4, 30))
a('<path d="M34,298 H966" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2"/>')
a('<rect x="34" y="344" width="932" height="16" fill="url(#tmp_carril)"/>')
XS = [52.0 + 38.9 * i for i in range(24)]
for i, x in enumerate(XS):
    a(f'<g filter="url(#bisel)"><rect x="{x - 15}" y="334" width="30" height="36" rx="2.5" fill="url(#tmp_borne)"/></g>')
    a(f'<rect x="{x - 6}" y="335.5" width="12" height="4" rx="1.2" fill="#050606"/>')
    a(f'<rect x="{x - 6}" y="364.5" width="12" height="4" rx="1.2" fill="#050606"/>')
    a(f'<circle cx="{x}" cy="352" r="10" fill="#1b1e20" opacity="0.8"/>')
    a(tornillo(x, 352, 8, (i * 29) % 40 - 20))
for i in range(1, 12):
    x = (XS[2 * i - 1] + XS[2 * i]) / 2
    a(f'<rect x="{x - 1.6}" y="330" width="3.2" height="44" rx="1" fill="#e7c21c" opacity="0.9"/>')
for x in (150, 380, 620, 850):
    a(f'<g filter="url(#bisel)"><rect x="{x - 14}" y="380" width="28" height="12" rx="2" fill="#b9bfc2"/></g>')
    a(f'<rect x="{x - 8}" y="383" width="16" height="6" rx="3" fill="#2a2e31"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "maquina_principal.svg"), "".join(d), P.DEFS + DEFS)
