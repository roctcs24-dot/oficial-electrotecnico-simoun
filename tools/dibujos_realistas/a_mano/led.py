"""LED de 5 mm y piloto de panel de 22 mm (400×220) sobre su SVG. LED: patillas estañadas con su
brillo, reflector en copa sobre el yunque del cátodo con la pastilla y el hilo de oro hasta el poste
del ánodo, cúpula de epoxi con la lente arriba, reflejos y luz de borde, y la pestaña con su lado
plano. Piloto: bisel cromado con reflejo, lente difusora con la matriz de LED al trasluz y anillos de
Fresnel, cuello roscado, cuerpo nervado y borne de tornillo con su placa."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="le_copa" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#6c7378"/><stop offset="0.35" stop-color="#ffffff"/><stop offset="0.6" stop-color="#b9c0c4"/><stop offset="1" stop-color="#596064"/></linearGradient>
<linearGradient id="le_hilo" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.3" stop-color="#ffffff"/><stop offset="0.55" stop-color="#b8bec2"/><stop offset="1" stop-color="#6c7378"/></linearGradient>
<radialGradient id="le_lente" cx="0.35" cy="0.3" r="0.8">
 <stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.45" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.85" stop-color="#000" stop-opacity="0.15"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></radialGradient>
<linearGradient id="le_bisel" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#c9ced2"/><stop offset="0.55" stop-color="#7a8287"/>
 <stop offset="0.75" stop-color="#d9dde0"/><stop offset="1" stop-color="#4c5357"/></linearGradient>
<linearGradient id="le_cuerpo" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.18"/>
 <stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="le_rosca" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#3a3f43"/><stop offset="0.35" stop-color="#9aa1a6"/><stop offset="1" stop-color="#2a2e32"/></linearGradient>
<linearGradient id="le_laton" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#8a6a22"/><stop offset="0.35" stop-color="#f6e2a8"/><stop offset="1" stop-color="#7a5c1c"/></linearGradient>
'''

d = []
a = d.append

# ----- LED de 5 mm -----
# Patillas estañadas (la del ánodo más larga)
a('<rect x="183" y="126" width="4" height="78" rx="2" fill="url(#le_hilo)"/>')
a('<rect x="213" y="126" width="4" height="60" rx="2" fill="url(#le_hilo)"/>')
a('<ellipse cx="200" cy="128" rx="34" ry="2.2" fill="#000" opacity="0.35" filter="url(#sombraCorta)"/>')
# Reflector en copa sobre el yunque del cátodo, pastilla y hilo de oro hasta el poste del ánodo
a('<path d="M206,74.5 L223,78.5 L219.5,86 L210,83.6 Z" fill="url(#le_copa)" stroke="#4f5558" stroke-width="0.6"/>')
a('<path d="M206.6,75 L222.4,78.7 L219.8,80.6 L208.6,78 Z" fill="#41484c" opacity="0.8"/>')
a('<path d="M210,82 L219,84.2" stroke="#fff" stroke-width="0.8" opacity="0.8"/>')
a('<rect x="212.6" y="77" width="3.2" height="3" fill="#3a1410" stroke="#ffb3a6" stroke-width="0.4" transform="rotate(13 214 78.5)"/>')
a('<path d="M213.5,77.2 C206,60 192,64 188.6,84.5" fill="none" stroke="#f3d27a" stroke-width="0.7"/>')
a('<rect x="186" y="84" width="1.6" height="30" fill="#fff" opacity="0.55"/><rect x="208" y="84" width="1.4" height="30" fill="#fff" opacity="0.45"/>')
# Cúpula de epoxi: lente arriba, reflejo fino, luz de borde a la derecha y meniscos en la base
a('<ellipse cx="200" cy="44" rx="15" ry="6" fill="#fff" opacity="0.14"/>')
a('<path d="M176,62 Q178,46 190,40" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.9" stroke-linecap="round"/>')
a('<path d="M226,58 Q227,86 226,112" fill="none" stroke="#ffb0a4" stroke-width="2" opacity="0.4" stroke-linecap="round"/>')
a('<path d="M174,70 V110" stroke="#fff" stroke-width="1.2" opacity="0.25" stroke-linecap="round"/>')
a('<path d="M171,113 H229" stroke="#5a0e09" stroke-width="1.4" opacity="0.6"/>')
# Pestaña: canto superior iluminado y el lado plano del cátodo marcado
a('<path d="M163,114.6 H231.5" stroke="#ff9d8f" stroke-width="1" opacity="0.8"/>')
a('<path d="M163,125.3 H237" stroke="#4a0b07" stroke-width="1" opacity="0.6"/>')
a('<path d="M232,114 V126" stroke="#6d1610" stroke-width="1"/>')
a('<rect x="232.5" y="114.5" width="5" height="11" fill="#ffd8d2" opacity="0.35"/>')

# ----- Piloto de panel de 22 mm -----
# Cuello roscado y cuerpo nervado
a('<rect x="316" y="117" width="28" height="7" fill="url(#le_rosca)"/>')
for x in range(318, 344, 3):
    a(f'<path d="M{x},117 l1.6,7" stroke="#1d2023" stroke-width="0.7"/>')
a('<rect x="312" y="124" width="36" height="30" fill="url(#le_cuerpo)"/>')
for x in range(316, 346, 5):
    a(f'<rect x="{x}" y="127" width="2" height="24" rx="1" fill="#000" opacity="0.35"/>')
    a(f'<rect x="{x + 2}" y="127" width="0.8" height="24" fill="#fff" opacity="0.12"/>')
# Borne de tornillo con su placa de latón alrededor del tornillo
a('<path d="M318,158 H342 V182 H318 Z M339.5,170 A9.5,9.5 0 1 0 320.5,170 A9.5,9.5 0 1 0 339.5,170 Z" fill="url(#le_laton)" fill-rule="evenodd" stroke="#5b4a1e" stroke-width="0.7"/>')
a('<path d="M312,154 L318,158 M348,154 L342,158" stroke="#2a2e32" stroke-width="1.4"/>')
# Bisel cromado
a('<circle cx="330" cy="88" r="27" fill="none" stroke="url(#le_bisel)" stroke-width="9"/>')
a('<path d="M308,76 A25,25 0 0 1 344,64" fill="none" stroke="#fff" stroke-width="2" opacity="0.75" stroke-linecap="round"/>')
a('<circle cx="330" cy="88" r="31.5" fill="none" stroke="#3b4246" stroke-width="1"/>')
a('<circle cx="330" cy="88" r="22.6" fill="none" stroke="#1d2226" stroke-width="1.4"/>')
# Lente difusora: matriz de LED al trasluz, anillos de Fresnel y abombado
for i in range(7):
    if i == 0:
        x, y = 330, 88
    else:
        ang = math.radians(60 * i + 30)
        x, y = 330 + 10 * math.cos(ang), 88 + 10 * math.sin(ang)
    a(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="2.6" fill="#0f5a26" opacity="0.35"/>')
    a(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="1.1" fill="#d8ffe0" opacity="0.35"/>')
for r in (6, 11, 16, 20):
    a(f'<circle cx="330" cy="88" r="{r}" fill="none" stroke="#c8ffd6" stroke-width="0.5" opacity="0.3"/>')
a('<circle cx="330" cy="88" r="22" fill="url(#le_lente)"/>')
a('<path d="M314,84 A16,16 0 0 1 326,72" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.7" stroke-linecap="round"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "led.svg"), "".join(d), P.DEFS + DEFS)
