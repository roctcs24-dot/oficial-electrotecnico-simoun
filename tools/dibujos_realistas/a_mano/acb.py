"""Interruptor de bastidor abierto (360×460) sobre su SVG: rejillas de la cámara de corte, asas del
chasis, tornillos de la tapa, escalas de los diales de la unidad de disparo, botones de la unidad,
aros de los pulsadores I y O, candado de bloqueo en abierto, palanca de carga con su agarre y
manivela de extracción."""
import math, os
import realzar as R
from a_mano import _piezas as P

d = []
a = d.append
# Rejillas de la cámara de corte, arriba del chasis
for i in range(14):
    x = 44 + i * 20
    a(f'<rect x="{x}" y="20" width="12" height="11" rx="2" fill="#0a0b0c"/>')
    a(f'<rect x="{x}" y="29" width="12" height="1.6" fill="#fff" opacity="0.2"/>')
# Asas del chasis a los lados, para sacarlo del cubículo
for x in (8, 342):
    a(f'<rect x="{x}" y="180" width="10" height="100" rx="5" fill="#2a2d30"/>')
    a(f'<rect x="{x + 2}" y="184" width="3" height="92" rx="1.5" fill="#8a9094" opacity="0.6"/>')
# Tornillos de la tapa frontal
for x, y in ((46, 46), (314, 46), (46, 414), (314, 414), (46, 230), (314, 230)):
    a(P.perno(x, y, 3.2))
# Escalas de los diales Ir, Isd e Ii
for cx in (88, 131, 174):
    for i in range(9):
        ang = math.radians(150 + i * 30)
        r1, r2 = 15.5, 19
        a(f'<path d="M{cx + r1 * math.cos(ang):.1f},{138 + r1 * math.sin(ang):.1f} L{cx + r2 * math.cos(ang):.1f},{138 + r2 * math.sin(ang):.1f}" stroke="#1d2226" stroke-width="1"/>')
# Botones y conector de prueba de la unidad de disparo
for i, y in enumerate((70, 86)):
    a(f'<rect x="198" y="{y}" width="6" height="12" rx="2" fill="#3a3e42"/>')
a('<rect x="186" y="170" width="16" height="8" rx="2" fill="#0d0f11"/>')
a('<circle cx="64" cy="174" r="2.4" fill="#2ecc71"/><circle cx="64" cy="174" r="5" fill="#2ecc71" opacity="0.25"/>')
# Aros cromados de los pulsadores I y O con su protector
for cx in (96, 264):
    a(f'<circle cx="{cx}" cy="232" r="29" fill="none" stroke="url(#am_acero)" stroke-width="3"/>')
    a(f'<ellipse cx="{cx - 8}" cy="219" rx="9" ry="4.5" fill="#fff" opacity="0.35" transform="rotate(-25 {cx - 8} 219)"/>')
# Candado de bloqueo en abierto junto al pulsador O
a('<rect x="296" y="252" width="22" height="12" rx="2" fill="url(#am_brida)" stroke="#3b4043" stroke-width="0.6"/>')
a('<circle cx="307" cy="258" r="3" fill="#0d0f11"/>')
# Agarre estriado de la palanca de carga y flecha de sentido
for y in range(312, 380, 6):
    a(f'<rect x="86" y="{y}" width="18" height="2.4" rx="1.2" fill="#14171a"/>')
a('<path d="M74,300 V386 M70,382 L74,390 L78,382" stroke="#e3c84f" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
# Manivela de extracción con su escudo
a('<circle cx="268" cy="370" r="22" fill="none" stroke="#5a6064" stroke-width="3"/>')
a('<path d="M246,348 L252,354 M290,348 L284,354 M246,392 L252,386 M290,392 L284,386" stroke="#8a9094" stroke-width="2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "acb.svg"), "".join(d), P.DEFS)
