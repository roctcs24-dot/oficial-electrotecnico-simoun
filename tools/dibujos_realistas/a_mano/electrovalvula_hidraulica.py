"""Válvula direccional 4/3 (500×280) sobre su SVG: cables de los conectores, que el relieve
automático pierde por ser tramos rectos, conectores DIN con junta, tornillo y prensaestopas sobre
cada bobina, nervios y brillo de las bobinas, ventana del LED, tuercas moleteadas de los tubos,
pulsadores de mando manual con fuelle de goma, tornillos Allen del cuerpo, juntas tóricas de las
bocas P A B T, marcas de mecanizado y borde remachado de la etiqueta."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ev_cuerpo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.2" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.15"/></linearGradient>
<linearGradient id="ev_conector" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#4a4f53"/><stop offset="1" stop-color="#17191b"/></linearGradient>
<linearGradient id="ev_tubo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.5"/><stop offset="0.3" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.15"/></linearGradient>
'''

d = []
a = d.append


def allen(x, y, r):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#am_acero)" stroke="#3b4043" stroke-width="1"/>'
            f'<polygon points="{P._hex(x, y, r * 0.48)}" fill="#1b1d1f"/>')


for cx, lado in ((95, -1), (405, 1)):
    # Cable del conector: tramo recto dibujado aquí
    a(f'<path d="M{cx},62 V76" stroke="#1b1d1f" stroke-width="10" stroke-linecap="round"/>')
    a(f'<path d="M{cx - 2.5},62 V76" stroke="#5a6064" stroke-width="2"/>')
    # Conector DIN: cuerpo, junta, nervios, tornillo de cierre y prensaestopas
    a(f'<rect x="{cx - 22}" y="72" width="44" height="24" rx="4" fill="url(#ev_conector)" stroke="#0e0f10" stroke-width="1"/>')
    a(f'<rect x="{cx - 22}" y="94" width="44" height="3" fill="#0a0b0c"/>')
    for x in range(cx - 18, cx - 4, 4):
        a(f'<path d="M{x},76 V92" stroke="#2a2e31" stroke-width="1.4"/>')
        a(f'<path d="M{x + 1},76 V92" stroke="#fff" stroke-opacity="0.12" stroke-width="0.6"/>')
    a(f'<circle cx="{cx + 10}" cy="84" r="4.4" fill="url(#am_acero)" stroke="#1c1e20" stroke-width="0.8"/>')
    a(f'<path d="M{cx + 7.6},84 H{cx + 12.4}" stroke="#2c3033" stroke-width="1.2"/>')
    a(f'<polygon points="{cx - 8},72 {cx + 8},72 {cx + 6},64 {cx - 6},64" fill="#2e3236"/>')
    a(f'<path d="M{cx - 7},68 H{cx + 7}" stroke="#15171a" stroke-width="0.8"/>')
    a(f'<rect x="{cx - 21}" y="73" width="20" height="4" rx="2" fill="#fff" opacity="0.15"/>')
    # Bobina: nervios, brillo y ventana del LED (apagado)
    for y in (132, 160, 168):
        a(f'<path d="M{cx - 30},{y} H{cx + 30}" stroke="#121416" stroke-width="1.8"/>')
        a(f'<path d="M{cx - 30},{y + 1.2} H{cx + 30}" stroke="#fff" stroke-opacity="0.1" stroke-width="0.7"/>')
    a(f'<rect x="{cx - 33}" y="98" width="6" height="74" rx="3" fill="#fff" opacity="0.1"/>')
    a(f'<rect x="{cx - 24}" y="106" width="48" height="16" rx="3" fill="none" stroke="#1b1d1f" stroke-width="1.4"/>')
    a(f'<rect x="{cx - 21}" y="108" width="20" height="5" rx="2" fill="#fff" opacity="0.25"/>')
    # Tubo: brillo y tuerca moleteada en el extremo
    x0 = 40 if lado < 0 else 350
    a(f'<rect x="{x0}" y="176" width="110" height="58" rx="4" fill="url(#ev_tubo)"/>')
    xn = 40 if lado < 0 else 448
    a(f'<rect x="{xn}" y="186" width="12" height="38" rx="2" fill="url(#am_brida)" stroke="#3b4043" stroke-width="0.6"/>')
    for y in range(189, 222, 3):
        a(f'<path d="M{xn + 1},{y} H{xn + 11}" stroke="#4f5559" stroke-width="0.8"/>')
    # Pulsador de mando manual con fuelle de goma
    xb = 22 if lado < 0 else 460
    for x in (xb + 5, xb + 9, xb + 13):
        a(f'<path d="M{x},196 V214" stroke="#7a1c16" stroke-width="1" opacity="0.7"/>')
    a(f'<rect x="{xb + 2}" y="196" width="14" height="5" rx="2" fill="#fff" opacity="0.3"/>')

# Cuerpo: brillo, marcas de mecanizado, tornillos Allen y juntas tóricas de las bocas
a('<rect x="150" y="150" width="200" height="110" rx="6" fill="url(#ev_cuerpo)"/>')
for y in range(156, 198, 6):
    a(f'<path d="M156,{y} H344" stroke="#fff" stroke-opacity="0.12" stroke-width="0.7"/>')
for x, y in ((166, 166), (334, 166), (166, 244), (334, 244)):
    a(allen(x, y, 6))
for x in (205, 235, 265, 295):
    a(f'<circle cx="{x}" cy="235" r="11" fill="none" stroke="#1b1d1f" stroke-width="2.6"/>')
    a(f'<circle cx="{x}" cy="235" r="9.5" fill="none" stroke="#5a6064" stroke-width="0.8"/>')
    a(f'<path d="M{x - 6},230 A7,7 0 0 1 {x + 4},229" fill="none" stroke="#fff" stroke-opacity="0.18" stroke-width="1"/>')
# Etiqueta: borde y remaches
a('<rect x="192" y="202" width="116" height="20" rx="2" fill="none" stroke="#6e5a1a" stroke-width="0.8"/>')
for x in (196, 304):
    a(f'<circle cx="{x}" cy="212" r="1.5" fill="#6e5a1a"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "electrovalvula_hidraulica.svg"), "".join(d), P.DEFS + DEFS)
