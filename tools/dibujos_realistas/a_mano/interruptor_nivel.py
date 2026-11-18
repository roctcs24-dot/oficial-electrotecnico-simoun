"""Interruptor de nivel de flotador (320×380) sobre su SVG: caja de conexiones con tornillos de la tapa
y placa remachada, prensaestopas con cúpula estriada y cable con brillo, brida con sus pernos y junta,
tubo de acero, cámara en corte con paredes rayadas, tubuladuras de conexión a la botella con escarcha
(NH3 frío), varilla del flotador con el imán del contacto, flotador de acero con brillo, y la
superficie del líquido con menisco y burbujas. Los rótulos los pinta el juego."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ni_acero" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6f7477"/><stop offset="0.45" stop-color="#f1f3f4"/><stop offset="1" stop-color="#6a6f72"/></linearGradient>
<linearGradient id="ni_aceroV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6f7477"/><stop offset="0.4" stop-color="#f1f3f4"/><stop offset="1" stop-color="#6a6f72"/></linearGradient>
<radialGradient id="ni_flotador" cx="0.35" cy="0.25" r="0.85"><stop offset="0" stop-color="#ffffff" stop-opacity="0.9"/><stop offset="0.35" stop-color="#ffffff" stop-opacity="0.15"/><stop offset="1" stop-color="#3a4044" stop-opacity="0.45"/></radialGradient>
<linearGradient id="ni_cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<pattern id="ni_rayado" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="6" height="6" fill="#9aa1a5"/><rect width="1.6" height="6" fill="#4a5054"/></pattern>
'''

d = []
a = d.append

# Tubuladuras de conexión con la botella, con escarcha del NH3 frío
# (rectángulos: un trazo horizontal suelto no admite degradados ni filtros de caja)
for x0, x1, y in ((18, 70, 214), (250, 302, 334)):
    a(f'<rect x="{x0}" y="{y - 8}" width="{x1 - x0}" height="16" fill="#8a9094"/>')
    a(f'<rect x="{x0}" y="{y - 8}" width="{x1 - x0}" height="16" fill="url(#am_tubo)"/>')
    a(f'<rect x="{x0}" y="{y - 9}" width="{x1 - x0}" height="18" rx="3" fill="#dff3ff" opacity="0.35"/>')
    a(f'<rect x="{x0}" y="{y - 9}" width="{x1 - x0}" height="18" rx="3" fill="#fff" filter="url(#am_escarcha)" opacity="0.9"/>')
a(P.brida(34, 214, 16) + P.brida(286, 334, 16))

# Cámara en corte: paredes de acero rayadas y fondo
a('<path d="M70,202 Q70,192 80,192 H240 Q250,192 250,202 V352 Q250,362 240,362 H80 Q70,362 70,352 Z M78,198 V354 H242 V198 Z" fill="url(#ni_rayado)" fill-rule="evenodd" stroke="#3b4043" stroke-width="1"/>')
a('<path d="M78,198 V354 H242 V198" fill="none" stroke="#2a2e31" stroke-width="1"/>')
# Superficie del líquido: menisco, reflejo y burbujas
a('<rect x="78" y="262" width="164" height="3" fill="#e6f3fb" opacity="0.8"/>')
a('<path d="M78,262 Q84,258 90,262 M242,262 Q236,258 230,262" fill="none" stroke="#e6f3fb" stroke-width="1.5"/>')
a('<rect x="78" y="265" width="164" height="22" fill="#fff" opacity="0.12"/>')
for x, y, r in ((96, 300, 2.2), (104, 318, 1.5), (92, 340, 1.8), (222, 296, 1.6), (214, 312, 2.4), (228, 344, 1.4), (118, 284, 1.2)):
    a(f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#eef7fc" stroke-width="0.7" opacity="0.8"/><circle cx="{x - r * 0.3:.1f}" cy="{y - r * 0.3:.1f}" r="{r * 0.3:.1f}" fill="#fff" opacity="0.8"/>')

# Varilla del flotador (el original no se ve) e imán del contacto arriba
a('<rect x="157.5" y="198" width="5" height="50" fill="url(#ni_acero)"/>')
a('<rect x="152" y="198" width="16" height="18" rx="2" fill="#3b4246" stroke="#1d2124" stroke-width="0.8"/>')
a('<rect x="154" y="200" width="4" height="14" fill="#fff" opacity="0.2"/>')
a('<rect x="148" y="186" width="24" height="12" fill="url(#ni_acero)" stroke="#5b6267" stroke-width="0.8"/>')
# Flotador de acero: volumen y brillo (el texto lo pinta el juego en el centro)
a('<ellipse cx="160" cy="262" rx="40" ry="18" fill="url(#ni_flotador)"/>')
a('<ellipse cx="146" cy="251" rx="14" ry="3.5" fill="#fff" opacity="0.7"/>')
a('<path d="M158,244 Q160,242 162,244" stroke="#5b6267" stroke-width="2" fill="none"/>')

# Tubo: brillo y rosca a la brida
a('<rect x="152" y="122" width="4" height="64" fill="#fff" opacity="0.4"/>')
for y in range(126, 140, 3):
    a(f'<path d="M148,{y} H172" stroke="#3b4043" stroke-width="0.7" opacity="0.6"/>')

# Brida: pernos y junta
a('<rect x="88" y="120" width="144" height="3" fill="#1a1c1e"/>')
for x in (98, 122, 198, 222):
    a(P.perno(x, 112, 4.2))
a('<rect x="88" y="102" width="144" height="2" fill="#fff" opacity="0.5"/>')

# Caja de conexiones: tornillos de la tapa, placa remachada y tornillo de tierra
for x, y in ((112, 24), (208, 24), (112, 94), (208, 94)):
    a(f'<circle cx="{x}" cy="{y}" r="4.4" fill="#232a31"/><circle cx="{x}" cy="{y}" r="3.4" fill="url(#am_acero)"/>')
    a(f'<path d="M{x - 2},{y} H{x + 2} M{x},{y - 2} V{y + 2}" stroke="#30353a" stroke-width="0.9"/>')
a('<rect x="118" y="30" width="84" height="40" rx="4" fill="url(#am_placa)" opacity="0.5"/>')
for x, y in ((122, 34), (198, 34), (122, 66), (198, 66)):
    a(f'<circle cx="{x}" cy="{y}" r="1.4" fill="#6c7276"/>')
a('<rect x="106" y="18" width="108" height="2" rx="1" fill="#fff" opacity="0.25"/>')
a(P.perno(160, 86, 3.4))
a('<path d="M154,92.5 H166 M156,95 H164 M158,97.5 H162" stroke="#c9ced1" stroke-width="0.9"/>')

# Prensaestopas: cuerpo hexagonal y cúpula estriada; cable con brillo
a('<path d="M246,55 C 280,55 290,80 300,110" fill="none" stroke="url(#ni_cable)" stroke-width="7"/>')
a('<path d="M246,52.5 C 278,52.5 289,77 297.5,105" fill="none" stroke="#fff" stroke-width="1" opacity="0.3"/>')
a('<rect x="206" y="44" width="14" height="22" rx="1.5" fill="url(#ni_aceroV)" stroke="#33383c" stroke-width="0.7"/>')
a('<path d="M220,46 H236 Q246,48 246,55 Q246,62 236,64 H220 Z" fill="#2a2d30" stroke="#111" stroke-width="0.7"/>')
for x in (224, 228, 232, 236):
    a(f'<path d="M{x},47 V63" stroke="#4b5257" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "interruptor_nivel.svg"), "".join(d), P.DEFS + DEFS)
