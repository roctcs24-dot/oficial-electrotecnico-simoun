"""Grupo de emergencia (480×340) sobre su SVG: panal del radiador con su tapón y manguitos con
abrazaderas, filtro de aire, fuelle y bridas del escape, filtro de aceite, varilla, motor de
arranque, pernos de tapas, alternador con rejilla de ventilación, cáncamo, caja de bornes con
prensaestopas, placa grabada (380 V 50 Hz del buque), soportes del panel con silentblocks, panel
con bisagras, cerradura, cristal de la pantalla, escala del selector, pilotos con lente, seta de
emergencia brillante, antivibratorios de la bancada y cable de tierra."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<pattern id="ge_panal" width="3" height="10" patternUnits="userSpaceOnUse"><rect width="3" height="10" fill="none"/><path d="M1.5,0 V10" stroke="#2e3439" stroke-width="0.8"/></pattern>
<linearGradient id="ge_goma" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a4f53"/><stop offset="0.4" stop-color="#1c1e20"/><stop offset="1" stop-color="#0a0b0c"/></linearGradient>
<linearGradient id="ge_gomaH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0a0b0c"/><stop offset="0.4" stop-color="#3a3e42"/><stop offset="1" stop-color="#0a0b0c"/></linearGradient>
<linearGradient id="ge_filtro" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#14365c"/><stop offset="0.35" stop-color="#4f86c0"/><stop offset="1" stop-color="#102a47"/></linearGradient>
<linearGradient id="ge_aire" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a5f63"/><stop offset="0.3" stop-color="#2e3236"/><stop offset="1" stop-color="#16181a"/></linearGradient>
<linearGradient id="ge_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.35" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.36" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<radialGradient id="ge_verde" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#9dffbb" stop-opacity="0.8"/><stop offset="1" stop-color="#5dff8f" stop-opacity="0"/></radialGradient>
<radialGradient id="ge_seta" cx="0.38" cy="0.3" r="0.75"><stop offset="0" stop-color="#ff9b8f"/><stop offset="0.45" stop-color="#c8312a"/><stop offset="1" stop-color="#6e1410"/></radialGradient>
'''

d = []
a = d.append


def abrazadera(x, y, ancho, vertical=False):
    if vertical:
        return (f'<rect x="{x - ancho / 2 - 1}" y="{y - 2}" width="{ancho + 2}" height="4" rx="1" fill="url(#am_bridaV)" stroke="#3b4043" stroke-width="0.4"/>'
                f'<rect x="{x + ancho / 2}" y="{y - 2.5}" width="3.5" height="5" rx="0.8" fill="#8a9094"/>')
    return (f'<rect x="{x - 2}" y="{y - ancho / 2 - 1}" width="4" height="{ancho + 2}" rx="1" fill="url(#am_brida)" stroke="#3b4043" stroke-width="0.4"/>'
            f'<rect x="{x - 2.5}" y="{y - ancho / 2 - 4}" width="5" height="3.5" rx="0.8" fill="#8a9094"/>')


# Radiador: panal fino entre las aletas, marco con pernos y tapón de presión
a('<rect x="36" y="122" width="62" height="150" fill="url(#ge_panal)" opacity="0.9"/>')
a('<rect x="36" y="122" width="62" height="150" fill="none" stroke="#000" stroke-opacity="0.6" stroke-width="1.5"/>')
for y in (118, 276):
    for x in (34, 100):
        a(P.perno(x, y, 2.2))
a('<rect x="54" y="96" width="28" height="7" rx="3" fill="url(#am_bridaV)" stroke="#3b4043" stroke-width="0.5"/>')
for x in range(57, 81, 3):
    a(f'<path d="M{x},96.5 V102.5" stroke="#4f5558" stroke-width="0.8"/>')
a('<path d="M60,99 H76" stroke="#fff" stroke-opacity="0.5" stroke-width="0.8"/>')
# Manguitos de agua del radiador al motor, con abrazaderas
H = "M98,130 C112,130 114,128 136,128"
a(f'<path d="{H}" fill="none" stroke="#0e0f10" stroke-width="12" stroke-linecap="round"/>')
a(f'<path d="{H}" fill="none" stroke="#2a2d30" stroke-width="9"/>')
a(f'<path d="{H}" fill="none" stroke="#fff" stroke-opacity="0.22" stroke-width="1.6" transform="translate(0,-3)"/>')
a(abrazadera(104, 130, 11) + abrazadera(129, 128, 11))
a('<rect x="94" y="252" width="16" height="12" rx="2" fill="url(#ge_goma)"/>' + abrazadera(103, 258, 12))

# Filtro de aire con su manguito sobre la tapa de balancines
a('<path d="M170,104 V112" stroke="#1a1c1e" stroke-width="12"/>')
a('<rect x="138" y="80" width="64" height="26" rx="10" fill="url(#ge_aire)" filter="url(#bisel)"/>')
for x in (150, 190):
    a(f'<rect x="{x - 2}" y="80" width="4" height="26" fill="#8a9094"/><rect x="{x - 2}" y="80" width="1.2" height="26" fill="#fff" opacity="0.5"/>')
a('<circle cx="140" cy="93" r="5" fill="#1f2326"/><circle cx="140" cy="93" r="2.5" fill="#d4a62a"/>')

# Escape: fuelle de dilatación, bridas y sombrero
a('<rect x="235" y="78" width="18" height="24" rx="2" fill="#9b968a"/>')
for y in range(80, 101, 3):
    a(f'<rect x="234" y="{y}" width="20" height="1.6" rx="0.8" fill="#5f5a50"/>')
a('<rect x="232" y="74" width="24" height="5" rx="1.5" fill="url(#am_bridaV)"/><rect x="232" y="101" width="24" height="5" rx="1.5" fill="url(#am_bridaV)"/>')
a(P.brida(258, 60, 16))
a('<path d="M244,108 V60 H272 V30" fill="none" stroke="#fff" stroke-opacity="0.18" stroke-width="3" transform="translate(-4,0)" stroke-linejoin="round"/>')

# Motor: pernos de la tapa de balancines, tapa de registro, filtro de aceite, varilla y arranque
for x in (124, 278):
    a(P.perno(x, 135, 2.4))
for x, y in ((145, 217), (189, 217), (145, 247), (189, 247)):
    a(P.perno(x, y, 2.2))
a('<rect x="200" y="206" width="20" height="44" rx="5" fill="url(#ge_filtro)"/>')
a('<rect x="198" y="203" width="24" height="6" rx="2" fill="#5a6064"/>')
for y in range(214, 246, 4):
    a(f'<path d="M201,{y} H219" stroke="#0c2036" stroke-width="0.7" opacity="0.6"/>')
a('<path d="M128,206 V182" stroke="#9aa0a3" stroke-width="2"/><rect x="123" y="176" width="10" height="7" rx="3" fill="#f2c200"/>')
a('<circle cx="246" cy="236" r="16.5" fill="none" stroke="#141b17" stroke-width="2.5" stroke-dasharray="2.4 1.6"/>')
for i in range(4):
    ang = math.radians(45 + 90 * i)
    a(P.perno(246 + 7 * math.cos(ang), 236 + 7 * math.sin(ang), 1.8))
a('<rect x="150" y="258" width="60" height="18" rx="8" fill="#16191b" filter="url(#bisel)"/>')
a('<rect x="204" y="261" width="12" height="12" rx="2" fill="#2a2e31"/>')
a('<path d="M156,262.5 H204" stroke="#fff" stroke-opacity="0.18" stroke-width="1"/>')
a('<path d="M180,258 C180,248 168,246 160,252" fill="none" stroke="#c0392b" stroke-width="3"/>')
for x in range(118, 290, 16):
    a(P.perno(x, 278, 1.8))

# Alternador: rejilla de salida de aire, cáncamo, pernos del adaptador y caja de bornes
a(P.rejilla(406, 186, 16, 78, 8))
a('<path d="M300,182 V270" stroke="#fff" stroke-opacity="0.15" stroke-width="1"/>')
for y in (182, 206, 230, 254, 274):
    a(P.perno(304, y, 2.2))
for x, y in ((334, 150), (392, 150), (334, 168), (392, 168)):
    a(P.perno(x, y, 1.8))
a('<rect x="396" y="146" width="10" height="12" rx="2" fill="#b8963a"/><rect x="396" y="148" width="10" height="2" fill="#fff" opacity="0.35"/>')
a(P.placa(334, 236, 52, 22, ["380 V · 50 Hz"], 4.6, "ALTERNADOR"))
# Cable de tierra verde y amarillo a la bancada
a('<path d="M420,272 C426,280 430,284 432,290" stroke="#35b552" stroke-width="4" fill="none" stroke-linecap="round"/>')
a('<path d="M420,272 C426,280 430,284 432,290" stroke="#f2c200" stroke-width="4" fill="none" stroke-dasharray="4 4"/>')
a(P.perno(420, 272, 2.4))

# Soportes del panel con silentblocks sobre el alternador
for x in (318, 414):
    a(f'<rect x="{x - 4}" y="134" width="8" height="30" fill="#4f5558"/>')
    a(f'<rect x="{x - 4}" y="134" width="2.5" height="30" fill="#fff" opacity="0.25"/>')
    a(f'<rect x="{x - 7}" y="160" width="14" height="10" rx="3" fill="url(#ge_gomaH)"/>')
    a(P.perno(x, 165, 2))
# Panel: bisagras, tornillos, cerradura y prensaestopas del cable
for y in (30, 116):
    a(f'<rect x="303" y="{y - 7}" width="6" height="14" rx="2" fill="url(#am_brida)" stroke="#4f5558" stroke-width="0.4"/>')
for x, y in ((314, 20), (454, 20), (314, 128), (454, 128)):
    a(P.perno(x, y, 2))
a('<rect x="452" y="64" width="7" height="22" rx="3" fill="#2a2e31"/><circle cx="455.5" cy="75" r="2" fill="#8a9094"/>')
a('<rect x="443" y="130" width="10" height="7" rx="1.5" fill="#2a2e31"/>')
a('<path d="M396,152 C440,152 448,140 448,134" fill="none" stroke="#fff" stroke-opacity="0.25" stroke-width="1.4" transform="translate(-0.6,-1.6)"/>')
# Pantalla: cristal con reflejo
a('<rect x="320" y="44" width="64" height="30" rx="2" fill="url(#ge_cristal)"/>')
# Selector AUTO / MAN / OFF: escala de posiciones y aro
for ang in (-90, 145, 35):
    r = math.radians(ang)
    a(f'<path d="M{428 + 17.5 * math.cos(r):.1f},{64 + 17.5 * math.sin(r):.1f} L{428 + 21 * math.cos(r):.1f},{64 + 21 * math.sin(r):.1f}" stroke="#20242a" stroke-width="2" stroke-linecap="round"/>')
a('<circle cx="428" cy="64" r="16" fill="none" stroke="#000" stroke-opacity="0.5" stroke-width="1"/>')
a('<ellipse cx="424" cy="58" rx="4" ry="2.2" fill="#fff" opacity="0.6" transform="rotate(-30 424 58)"/>')
# Pilotos: RUN encendido con halo, ALARM apagado; lentes con brillo
a('<circle cx="330" cy="104" r="14" fill="url(#ge_verde)"/>')
for x in (330, 366):
    a(f'<circle cx="{x}" cy="104" r="7.6" fill="none" stroke="url(#am_acero)" stroke-width="1.8"/>')
    a(f'<ellipse cx="{x - 2}" cy="101.5" rx="2.4" ry="1.5" fill="#fff" opacity="0.75"/>')
# Seta de emergencia con brillo y collar amarillo dentado
a('<circle cx="432" cy="110" r="10" fill="url(#ge_seta)"/>')
a('<ellipse cx="428.5" cy="106" rx="4" ry="2.4" fill="#fff" opacity="0.55" transform="rotate(-25 428.5 106)"/>')
a('<circle cx="432" cy="110" r="12" fill="none" stroke="#8a6a0a" stroke-width="0.8" stroke-dasharray="1.5 1.5"/>')

# Bancada: antivibratorios de goma con su perno y pernos de anclaje al polín
for x in (53, 209, 389):
    a(f'<rect x="{x - 14}" y="278" width="28" height="11" rx="3" fill="url(#ge_goma)"/>')
    a(f'<rect x="{x - 16}" y="276" width="32" height="3.5" rx="1" fill="#4f5558"/>')
    a(P.perno(x - 10, 284, 2.2) + P.perno(x + 10, 284, 2.2))
a('<path d="M22,289.5 H438" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')
for x in (34, 130, 300, 426):
    a(P.perno(x, 298, 3))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "generador_emergencia.svg"), "".join(d), P.DEFS + DEFS)
