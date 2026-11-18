"""Botella de baja (480×320) sobre su SVG: tramos rectos que el relieve automático pierde (venteo,
salida de líquido y aspiración de la bomba), escarcha en las líneas frías de NH3, bridas, válvula de
seguridad con su sombrerete y precinto, costuras soldadas y brillo de la virola, burbujas del
líquido, tacos aislantes de las cunas y placas de anclaje, interruptores de nivel con tuerca y
conector, solenoide con tuerca de bobina y conector, y bomba con pernos de la voluta, caja de bornes
y bancada."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="bb_brillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.12" stop-color="#fff" stop-opacity="0.3"/><stop offset="0.26" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="bb_madera" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6b4a2a"/><stop offset="0.5" stop-color="#9a6d40"/><stop offset="1" stop-color="#5c3e22"/></linearGradient>
<linearGradient id="bb_rojo" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a1c16"/><stop offset="0.4" stop-color="#e0574a"/><stop offset="1" stop-color="#7a1c16"/></linearGradient>
'''

d = []
a = d.append


def escarcha_recta(ruta, ancho, x, y, w, h):
    """Escarcha sobre un tramo recto: el filtro necesita una caja con alto y ancho, que da el
    rectángulo invisible (x, y, w, h) del grupo."""
    return (f'<path d="{ruta}" stroke="#dff3ff" stroke-width="{ancho}" opacity="0.35"/>'
            f'<g filter="url(#am_escarcha)" opacity="0.9"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none"/>'
            f'<path d="{ruta}" stroke="#fff" stroke-width="{ancho}"/></g>')


# Tramos rectos de un solo segmento: el relieve automático los pierde, se dibujan aquí
for ruta, w, c in (("M270,68 V30", 6, "#8e9496"), ("M240,190 V244", 10, "#e0a030"), ("M222,262 H60", 10, "#e0a030")):
    # Sin filtro ni degradado: una línea recta no tiene caja y los dos fallarían
    a(f'<path d="{ruta}" stroke="{c}" stroke-width="{w}"/>')
    sombra = "translate(0,%.1f)" % (w * 0.3) if "H" in ruta else "translate(%.1f,0)" % (w * 0.3)
    a(f'<path d="{ruta}" stroke="#000" stroke-opacity="0.25" stroke-width="{w * 0.4:.1f}" transform="{sombra}"/>')
    a(P.brillo_tubo(ruta, w) if "H" in ruta else f'<path d="{ruta}" stroke="#fff" stroke-opacity="0.35" stroke-width="{w * 0.2:.1f}" transform="translate(-{w * 0.22:.1f},0)"/>')
# Escarcha en las líneas frías: aspiración, retorno, líquido a la bomba y tras la solenoide
a(P.escarcha("M200,88 V40 H110", 14))
a(P.escarcha("M470,60 H330 V88", 12))
a(escarcha_recta("M240,192 V244", 10, 235, 192, 10, 52))
a(escarcha_recta("M222,262 H60", 10, 60, 257, 162, 10))
a(P.escarcha("M406,236 H384 V172 H362", 10))
# Bridas de las tuberías
a(P.brida(160, 40, 14) + P.brida(200, 72, 14, True))
a(P.brida(420, 60, 12) + P.brida(330, 76, 12, True))
a(P.brida(240, 214, 10, True) + P.brida(130, 262, 10))
a(P.brida(462, 236, 10))

# Virola: brillo longitudinal, costuras de los fondos y placa de identificación
a('<rect x="120" y="90" width="240" height="100" rx="50" fill="url(#bb_brillo)"/>')
for x in (170, 310):
    a(f'<path d="M{x},91 V147" stroke="#3d1a17" stroke-width="2.6" opacity="0.7"/>')
    a(f'<path d="M{x},91 V147" stroke="#c97a70" stroke-width="1" stroke-dasharray="1.6 1.2" opacity="0.8"/>')
a('<path d="M120.6,148 H359.4" stroke="#fff3c4" stroke-width="1" opacity="0.55" transform="translate(0,1.5)"/>')
# Burbujas de vapor que suben del líquido
for x, y, r in ((150, 158, 1.6), (172, 172, 1.2), (205, 160, 1.4), (278, 176, 1.3), (300, 158, 1.7), (322, 168, 1.2), (338, 156, 1.0), (190, 182, 1.0)):
    a(f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#fff3c4" stroke-width="0.7" opacity="0.8"/>')
# Tubuladuras soldadas de la aspiración, el retorno y la seguridad
for x, w in ((200, 22), (330, 20), (270, 22)):
    a(f'<rect x="{x - w / 2}" y="86" width="{w}" height="6" rx="1.5" fill="url(#am_bridaV)"/>')

# Válvula de seguridad: cuerpo con brillo, sombrerete del muelle, palanca y precinto
a('<rect x="262" y="68" width="16" height="22" fill="url(#bb_rojo)" opacity="0.85"/>')
a('<rect x="264" y="52" width="12" height="16" rx="2" fill="#a52a22" stroke="#5a1410" stroke-width="0.6"/>')
a('<rect x="266" y="46" width="8" height="7" rx="1.5" fill="url(#am_brida)"/>')
a('<path d="M276,58 L288,52" stroke="#5a6064" stroke-width="2.2" stroke-linecap="round"/>')
a('<circle cx="289" cy="51.5" r="2" fill="#5a6064"/>')
a('<path d="M264,60 C258,62 258,66 262,68" fill="none" stroke="#9aa0a3" stroke-width="0.7"/><circle cx="258.5" cy="64" r="1.8" fill="#7b8286"/>')
a(P.perno(265, 87, 1.5) + P.perno(275, 87, 1.5))

# Cunas: tacos aislantes de madera bajo la virola, placas de anclaje y pernos
for x0, x1 in ((160, 184), (296, 320)):
    a(f'<rect x="{x0 - 3}" y="182" width="{x1 - x0 + 6}" height="7" rx="1" fill="url(#bb_madera)"/>')
    a(f'<path d="M{x0 - 1},184.5 H{x1 + 1} M{x0 - 1},186.8 H{x1 + 1}" stroke="#4a3018" stroke-width="0.5" opacity="0.6"/>')
for x in (172, 308):
    a(f'<path d="M{x - 6},196 V228" stroke="#1a1d20" stroke-width="2"/><path d="M{x + 6},196 V228" stroke="#1a1d20" stroke-width="2"/>')
    a(f'<rect x="{x - 28}" y="231" width="56" height="6" rx="1.5" fill="#3a3f44"/>')
    a(P.perno(x - 20, 234, 2.4) + P.perno(x + 20, 234, 2.4))

# Columna de nivel: bridas de las conexiones y tapones de purga
a(P.brida(118, 100, 8) + P.brida(118, 180, 8))
a('<rect x="84" y="78" width="10" height="7" rx="2" fill="#5a6064"/><rect x="84" y="203" width="10" height="7" rx="2" fill="#5a6064"/>')
a('<path d="M86,92 V196" stroke="#fff" stroke-opacity="0.4" stroke-width="1"/>')
# Interruptores de nivel: tuerca en la columna, aristas y tornillo del conector
for y in (110, 140, 155):
    a(f'<polygon points="78,{y - 6} 82,{y - 7} 82,{y + 7} 78,{y + 6}" fill="#7b8286"/>')
    a(f'<path d="M54,{y - 4.5} H80" stroke="#fff" stroke-opacity="0.25" stroke-width="0.8"/>')
    a(f'<path d="M64,{y - 6} V{y + 6} M70,{y - 6} V{y + 6}" stroke="#23272b" stroke-width="0.8"/>')
    a(f'<circle cx="48" cy="{y}" r="1.4" fill="#9aa0a3"/>')

# Solenoide: tuerca de la bobina, conector con su cable y flecha de sentido en el cuerpo
a('<rect x="422" y="191" width="12" height="7" rx="1.5" fill="url(#am_brida)"/>')
a(P.perno(428, 191, 3))
a('<rect x="440" y="202" width="12" height="18" rx="2" fill="#1b1d1f"/>')
a('<circle cx="446" cy="211" r="1.8" fill="#8a9094"/>')
a('<path d="M452,206 C462,206 467,198 467,168" fill="none" stroke="#202326" stroke-width="3.5" stroke-linecap="round"/>')
a('<rect x="457" y="150" width="20" height="18" rx="2" fill="#5a6064" filter="url(#bisel)"/>' + P.perno(460, 153, 1.2) + P.perno(474, 165, 1.2))
a('<rect x="464" y="167" width="6" height="4" rx="1" fill="#b8963a"/>')
a('<path d="M444,236 H412 M416,233 L412,236 L416,239" stroke="#2a2e31" stroke-width="1.4" fill="none"/>')
a(P.perno(411, 230, 1.6) + P.perno(445, 230, 1.6) + P.perno(411, 242, 1.6) + P.perno(445, 242, 1.6))

# Bomba de amoníaco: pernos de la voluta, caja de bornes del motor, bancada y tapón de purga
for i in range(8):
    ang = 2 * math.pi * i / 8 + 0.2
    a(P.perno(240 + 14.5 * math.cos(ang), 262 + 14.5 * math.sin(ang), 1.7))
a('<circle cx="240" cy="262" r="6" fill="url(#am_acero)"/>' + P.perno(240, 262, 3))
a('<rect x="280" y="239" width="20" height="10" rx="2" fill="#3e5366" stroke="#26343f" stroke-width="0.8"/>')
a(P.perno(283, 242, 1.2) + P.perno(297, 242, 1.2))
a('<rect x="300" y="241" width="5" height="5" rx="1" fill="#b8963a"/>')
a('<path d="M305,243.5 C318,243.5 322,252 322,279" fill="none" stroke="#1b1e21" stroke-width="3"/>')
a('<rect x="222" y="279" width="102" height="6" rx="1.5" fill="#2a2e31"/>')
for x in (230, 316):
    a(P.perno(x, 282, 2))
a('<path d="M260,251 H316" stroke="#fff" stroke-opacity="0.25" stroke-width="1"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "botella_baja.svg"), "".join(d), P.DEFS + DEFS)
