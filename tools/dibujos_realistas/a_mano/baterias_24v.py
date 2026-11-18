"""Banco de baterías de 24 V y cargador (520×320) sobre su SVG: tapones de las celdas, nervios de la
caja, asas, etiqueta impresa con pictogramas de seguridad, terminales de cable con tuerca, bandeja
antiácido con su barra de sujeción, brillo de los cables y, en el cargador (datos de la ficha),
pantalla con cristal, LED con bisel, rejilla de ventilación, prensaestopas y tornillos."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="bt_tapon" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a5f63"/><stop offset="1" stop-color="#1a1c1e"/></linearGradient>
<linearGradient id="bt_bandeja" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4b5148"/><stop offset="0.3" stop-color="#3a3f37"/><stop offset="1" stop-color="#1f221d"/></linearGradient>
<linearGradient id="bt_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.4" stop-color="#fff" stop-opacity="0.08"/><stop offset="0.41" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="bt_cobre" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f0b27a"/><stop offset="0.5" stop-color="#b8692e"/><stop offset="1" stop-color="#6b3510"/></linearGradient>
<radialGradient id="bt_verde" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#7dff9a" stop-opacity="0.7"/><stop offset="1" stop-color="#2fbf5a" stop-opacity="0"/></radialGradient>
'''

d = []
a = d.append

for bx in (20, 200):
    # Nervios verticales moldeados en los costados de la caja y canto inferior
    for x in (bx + 7, bx + 12, bx + 148, bx + 153):
        a(f'<rect x="{x - 1.5}" y="124" width="3" height="124" rx="1.5" fill="#15171a"/>')
        a(f'<rect x="{x - 1.5}" y="124" width="1" height="124" fill="#fff" opacity="0.12"/>')
    a(f'<path d="M{bx + 4},122 H{bx + 156}" stroke="#000" stroke-opacity="0.45" stroke-width="1.2"/>')
    a(f'<path d="M{bx + 4},123.5 H{bx + 156}" stroke="#fff" stroke-opacity="0.12" stroke-width="0.8"/>')
    # Asas abatibles en la tapa
    a(f'<path d="M{bx + 4},101 H{bx + 14}" stroke="#121416" stroke-width="3" stroke-linecap="round"/>')
    a(f'<path d="M{bx + 146},101 H{bx + 156}" stroke="#121416" stroke-width="3" stroke-linecap="round"/>')
    # Seis tapones de las celdas entre los terminales
    for i in range(6):
        cx = bx + 55 + i * 10
        a(f'<circle cx="{cx}" cy="107" r="4.4" fill="#0d0e10"/><circle cx="{cx}" cy="106.4" r="3.8" fill="url(#bt_tapon)"/>')
        a(f'<path d="M{cx - 2.2},106.4 H{cx + 2.2}" stroke="#0a0b0c" stroke-width="1"/>')
    a(f'<path d="M{bx + 50},112.5 H{bx + 110}" stroke="#000" stroke-opacity="0.35" stroke-width="0.8"/>')
    # Etiqueta impresa: franja de marca, rayas de datos y pictogramas de seguridad
    lx = bx + 30
    a(f'<rect x="{lx}" y="150" width="100" height="8" rx="3" fill="#1f4f8a"/>')
    a(f'<rect x="{lx}" y="155" width="100" height="3" fill="#1f4f8a"/>')
    a(f'<text x="{lx + 50}" y="156.2" text-anchor="middle" style="font:800 5.6px Plex;fill:#fff;letter-spacing:.18em">MOTOREX</text>')
    for i, c in enumerate(("#f2c200", "#c0392b", "#1f4f8a", "#f2c200", "#2f9e57", "#c0392b")):
        x = lx + 22 + i * 10
        a(f'<rect x="{x}" y="181" width="7" height="7" rx="1" fill="{c}"/>')
        a(f'<rect x="{x + 1.6}" y="182.6" width="3.8" height="3.8" rx="1.9" fill="#fff" opacity="0.8"/>')
    a(f'<rect x="{lx + 2}" y="159" width="96" height="29" rx="4" fill="none" stroke="#fff" stroke-opacity="0.3" stroke-width="0.6"/>')
    # Ojo indicador de carga en la cara frontal
    a(f'<circle cx="{bx + 136}" cy="208" r="6" fill="#0d0e10"/><circle cx="{bx + 136}" cy="208" r="4" fill="#2fbf5a"/>')
    a(f'<ellipse cx="{bx + 134.6}" cy="206.6" rx="1.8" ry="1.1" fill="#fff" opacity="0.8"/>')

# Terminales de cable de cobre con tuerca sobre cada borne
for x in (54, 148, 222, 326):
    a(f'<rect x="{x - 8}" y="78" width="16" height="10" rx="3" fill="url(#bt_cobre)" stroke="#5a2c0c" stroke-width="0.5"/>')
    a(P.perno(x, 83, 3.4))
# Tapas de los bornes: canto con luz
for x, c in ((42, "#ff8a7a"), (134, "#7b8084"), (222, "#ff8a7a"), (314, "#7b8084")):
    a(f'<path d="M{x + 2},80.8 H{x + 22}" stroke="{c}" stroke-opacity="0.6" stroke-width="1"/>')

# Brillo de los cables
for ruta, w in (("M148,82 C160,40 200,40 222,82", 9), ("M54,82 C54,30 420,20 430,140", 7), ("M326,82 C326,40 450,40 456,140", 7)):
    a(f'<path d="{ruta}" fill="none" stroke="#fff" stroke-opacity="0.32" stroke-width="{w * 0.22:.1f}" transform="translate(-0.8,-{w * 0.25:.1f})" stroke-linecap="round"/>')

# Bandeja antiácido con su canto y la barra de sujeción por delante
a('<rect x="12" y="246" width="356" height="20" rx="3" fill="url(#bt_bandeja)" filter="url(#bisel)"/>')
a('<path d="M14,247.5 H366" stroke="#fff" stroke-opacity="0.25" stroke-width="1"/>')
for x in (30, 190, 350):
    a(P.perno(x, 256, 3.2))

# Cargador: tornillos, prensaestopas de los cables y placa de datos
for x, y in ((408, 148), (502, 148), (408, 292), (502, 292)):
    a(P.perno(x, y, 2.8))
for x in (430, 456):
    a(f'<rect x="{x - 8}" y="134" width="16" height="8" rx="1.5" fill="#2a2d30"/>')
    a(f'<polygon points="{x - 7},134 {x + 7},134 {x + 5},128 {x - 5},128" fill="#3a3e42"/>')
    a(f'<path d="M{x - 6},137.5 H{x + 6}" stroke="#55595c" stroke-width="0.8"/>')
a('<text x="455" y="154.5" text-anchor="middle" style="font:800 6px Plex;fill:#2a3034;letter-spacing:.12em">EXXEL · 24 V · 70 A</text>')
# Pantalla: bisel negro, cristal con reflejo
a('<rect x="413" y="157" width="84" height="42" rx="4" fill="none" stroke="#2a2e31" stroke-width="3"/>')
a('<rect x="416" y="160" width="78" height="36" rx="3" fill="#000" opacity="0.12"/>')
a('<rect x="416" y="160" width="78" height="36" rx="3" fill="url(#bt_cristal)"/>')
# LED de carga encendido y de alarma apagado, con su bisel
a('<circle cx="430" cy="220" r="12" fill="url(#bt_verde)"/>')
for x in (430, 450):
    a(f'<circle cx="{x}" cy="220" r="7.6" fill="none" stroke="url(#am_acero)" stroke-width="2"/>')
    a(f'<ellipse cx="{x - 1.8}" cy="218" rx="2" ry="1.3" fill="#fff" opacity="0.75"/>')
# Teclas de manejo
for x in (472, 486):
    a(f'<rect x="{x - 5}" y="214" width="10" height="12" rx="2" fill="#3a3e42" filter="url(#bisel)"/>')
# Rejilla de ventilación
for y in range(236, 258, 5):
    a(f'<rect x="418" y="{y}" width="74" height="2.6" rx="1.3" fill="#3e4447"/>')
    a(f'<rect x="418" y="{y + 2.6}" width="74" height="0.8" fill="#fff" opacity="0.6"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "baterias_24v.svg"), "".join(d), P.DEFS + DEFS)
