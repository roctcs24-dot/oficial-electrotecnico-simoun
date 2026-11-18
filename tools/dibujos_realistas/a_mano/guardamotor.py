"""Guardamotor de pulsadores (320×500) sobre su SVG: carril DIN con labios y ranuras, rejillas de
la cámara de corte, bornes con jaula de acero estañado, canto de las barreras, escala del dial de
ajuste con su índice y moleteado, sombra interior de la ventana, brillo y relieve de los pulsadores
de parada y de marcha, remaches de la placa y pestaña del clip del carril."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="gm_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#eef0f1"/><stop offset="0.5" stop-color="#a7aeb2"/><stop offset="1" stop-color="#5d6367"/></linearGradient>
<linearGradient id="gm_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="gm_boton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.28"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.04"/><stop offset="0.8" stop-color="#000" stop-opacity="0.08"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="gm_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.15" stop-color="#fff" stop-opacity="0"/><stop offset="0.85" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></linearGradient>
<radialGradient id="gm_perilla" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.6"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/></radialGradient>
'''

d = []
a = d.append
# Carril DIN a los lados del aparato: labios, fondo y ranuras oblongas
for x0, x1 in ((0, 58), (262, 320)):
    w = x1 - x0
    a(f'<rect x="{x0}" y="166" width="{w}" height="10" fill="#e7eaeb"/><rect x="{x0}" y="166" width="{w}" height="1.5" fill="#fff"/>')
    a(f'<rect x="{x0}" y="176" width="{w}" height="4" fill="#000" opacity="0.25"/>')
    a(f'<rect x="{x0}" y="324" width="{w}" height="10" fill="#7d8386"/><rect x="{x0}" y="320" width="{w}" height="4" fill="#fff" opacity="0.25"/>')
a('<rect x="10" y="232" width="34" height="36" rx="17" fill="#202427"/><rect x="13" y="262" width="28" height="2" fill="#fff" opacity="0.4"/>')
a('<rect x="276" y="232" width="34" height="36" rx="17" fill="#202427"/><rect x="279" y="262" width="28" height="2" fill="#fff" opacity="0.4"/>')
a('<rect x="58" y="168" width="5" height="164" fill="#000" opacity="0.3"/><rect x="257" y="168" width="5" height="164" fill="#000" opacity="0.3"/>')
# Brillo de los cantos del cuerpo
a('<rect x="58" y="20" width="204" height="460" rx="8" fill="url(#gm_lado)"/>')
# Rejillas de la cámara de corte, arriba y abajo a los lados
for y0 in (34, 408):
    for k in range(6):
        y = y0 + k * 10
        for x in (66, 244):
            a(f'<rect x="{x}" y="{y}" width="10" height="5" rx="2.5" fill="#0b0c0d"/><rect x="{x}" y="{y + 4.2}" width="10" height="1" fill="#c3c8cb" opacity="0.35"/>')
# Bornes: jaula de acero estañado alrededor del tornillo
for x in (102, 160, 218):
    for y in (72, 428):
        a(f'<path fill-rule="evenodd" fill="url(#gm_jaula)" stroke="#2a2d30" stroke-width="0.8" '
          f'd="M{x - 15},{y - 14} H{x + 15} V{y + 14} H{x - 15} Z M{x + 11.6},{y} A11.6,11.6 0 1 0 {x - 11.6},{y} A11.6,11.6 0 1 0 {x + 11.6},{y} Z"/>')
        a(f'<rect x="{x - 15}" y="{y + 9}" width="30" height="5" fill="#000" opacity="0.35"/>')
# Canto con luz de las barreras entre fases
for x in (128, 186):
    for y in (28, 398):
        a(f'<rect x="{x}" y="{y}" width="1.6" height="74" rx="0.8" fill="#fff" opacity="0.22"/>')
# Escalones del frente: canto con luz arriba y sombra bajo el frente
a('<path d="M60,110 H260" stroke="#fff" stroke-opacity="0.18" stroke-width="1.2"/>')
a('<rect x="64" y="384" width="192" height="7" fill="url(#gm_sombraV)"/>')
# Ventana del dial: sombra interior
a('<rect x="70" y="124" width="70" height="10" fill="url(#gm_sombraV)"/>')
# Escala del dial de ajuste (de 17 a 23 A, cada 0,5 A) alrededor de la perilla
for i in range(13):
    g = math.radians(135 + i * 11.25)
    largo = 5.5 if i % 2 == 0 else 3.2
    r1, r2 = 29, 29 + largo
    a(f'<path d="M{105 + r1 * math.cos(g):.1f},{184 + r1 * math.sin(g):.1f} L{105 + r2 * math.cos(g):.1f},{184 + r2 * math.sin(g):.1f}" stroke="#20242a" stroke-width="{1.4 if i % 2 == 0 else 0.9}"/>')
# Perilla: moleteado del borde, brillo y flecha índice en la ranura
for i in range(36):
    g = math.radians(i * 10)
    a(f'<path d="M{105 + 23.5 * math.cos(g):.1f},{184 + 23.5 * math.sin(g):.1f} L{105 + 26.5 * math.cos(g):.1f},{184 + 26.5 * math.sin(g):.1f}" stroke="#7d8285" stroke-width="1.1"/>')
a('<circle cx="105" cy="184" r="27" fill="url(#gm_perilla)"/>')
g = math.radians(305)
a(f'<path d="M{105 + 17 * math.cos(g):.1f},{184 + 17 * math.sin(g):.1f} L{105 + 23 * math.cos(g):.1f},{184 + 23 * math.sin(g):.1f}" stroke="#f4f4f0" stroke-width="2" stroke-linecap="round"/>')
a('<circle cx="105" cy="184" r="2.2" fill="#8d9396"/>')
# Pulsadores de parada y de marcha: relieve, brillo y sombra en el alojamiento
a('<rect x="150" y="130" width="40" height="92" rx="3" fill="url(#gm_boton)"/>')
a('<rect x="204" y="130" width="42" height="80" rx="3" fill="url(#gm_boton)"/>')
a('<path d="M152,131.5 H188 M206,131.5 H244" stroke="#fff" stroke-opacity="0.45" stroke-width="1"/>')
a('<rect x="204" y="210" width="42" height="12" rx="2" fill="#fff" opacity="0.12"/><path d="M205,211 H245" stroke="#9ff0b9" stroke-opacity="0.6" stroke-width="1"/>')
for x in (146, 200):
    a(f'<rect x="{x}" y="226" width="{48 if x == 146 else 50}" height="6" fill="url(#gm_sombraV)"/>')
# Remaches de la placa de datos
for x, y in ((78, 278), (242, 278), (78, 370), (242, 370)):
    a(f'<circle cx="{x}" cy="{y}" r="2.6" fill="#8a9094"/><circle cx="{x - 0.6}" cy="{y - 0.6}" r="1.5" fill="url(#am_acero)"/>')
# Pestaña del clip del carril con la ranura para el destornillador
a('<path d="M140,478 H180 V490 Q180,494 176,494 H144 Q140,494 140,490 Z" fill="#3a3e42" stroke="#191b1d" stroke-width="1"/>')
a('<rect x="150" y="484" width="20" height="4" rx="2" fill="#0b0c0d"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "guardamotor.svg"), "".join(d), P.DEFS + DEFS)
