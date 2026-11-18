"""Placa de montaje del arrancador estrella-triángulo (440×400) sobre su SVG: carriles DIN con sus
ranuras, tornillos de la placa, bornes de los aparatos con tornillo, maneta del guardamotor, escala
del temporizador, ventanas y rejillas de los contactores, dial y rearme del relé térmico, puentes de
cable entre aparatos, puente de cobre del punto de estrella en K3, topes de la bornera y brillo de
los cables de salida. Rótulos y nombres de bornes los pinta el juego."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="yd_cabeza" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d4d8db"/><stop offset="0.75" stop-color="#868d91"/><stop offset="1" stop-color="#4a5054"/></radialGradient>
<linearGradient id="yd_cobre" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7a3f14"/><stop offset="0.4" stop-color="#f0b07c"/><stop offset="1" stop-color="#7a3f14"/></linearGradient>
<linearGradient id="yd_maneta" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b3f43"/><stop offset="0.3" stop-color="#25282b"/><stop offset="1" stop-color="#121416"/></linearGradient>
'''


def tornillo(x, y, r=4.2):
    return (f'<circle cx="{x}" cy="{y + 0.5}" r="{r + 1.6}" fill="#1d2023" opacity="0.75"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#yd_cabeza)" stroke="#33383c" stroke-width="0.5"/>'
            f'<path d="M{x - r * 0.7},{y} H{x + r * 0.7} M{x},{y - r * 0.45} V{y + r * 0.45}" stroke="#2a2e31" stroke-width="{r * 0.3:.1f}" stroke-linecap="round"/>')


def cable(dd, color="#1d1e20", ancho=2.6):
    return (f'<path d="{dd}" fill="none" stroke="#000" stroke-opacity="0.35" stroke-width="{ancho + 1.4}" stroke-linecap="round" stroke-linejoin="round" transform="translate(1,1.4)"/>'
            f'<path d="{dd}" fill="none" stroke="{color}" stroke-width="{ancho}" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="{dd}" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="{max(0.6, ancho * 0.25):.1f}" stroke-linecap="round" stroke-linejoin="round" transform="translate(-{ancho * 0.2:.1f},-{ancho * 0.2:.1f})"/>')


d = []
a = d.append

# Tornillos de la placa de montaje
for x, y in ((18, 18), (422, 18), (18, 382), (422, 382)):
    a(f'<circle cx="{x}" cy="{y}" r="4.6" fill="#8a9095"/><circle cx="{x}" cy="{y}" r="3.6" fill="url(#yd_cabeza)"/>')
    a(f'<path d="M{x - 2.2},{y} H{x + 2.2} M{x},{y - 2.2} V{y + 2.2}" stroke="#30353a" stroke-width="1"/>')

# Ranuras alargadas de los carriles DIN y su pestaña iluminada
for y, tramos in ((29, ((24, 416),)), (145, ((24, 88), (172, 188), (272, 288), (372, 416))),
                  (307, ((24, 62), (198, 246), (380, 416)))):
    for x0, x1 in tramos:
        x = x0 + 2
        while x + 11 <= x1:
            a(f'<rect x="{x}" y="{y - 2.5}" width="11" height="5" rx="2.5" fill="#3d4246"/>')
            a(f'<rect x="{x}" y="{y + 1.6}" width="11" height="1" fill="#fff" opacity="0.5"/>')
            x += 18
a('<rect x="20" y="22" width="400" height="1.4" fill="#fff" opacity="0.6"/>')

# Guardamotor Q1: tornillos de entrada y maneta giratoria (la ventana verde es la posición ON)
for x in (104, 130, 156):
    a(tornillo(x, 49))
a('<rect x="112" y="62" width="36" height="22" rx="3" fill="none" stroke="#1d5b33" stroke-width="1.2"/>')
a('<rect x="122" y="57" width="16" height="32" rx="4" fill="url(#yd_maneta)" stroke="#0b0c0d" stroke-width="0.8"/>')
a('<rect x="124" y="59" width="4" height="28" rx="2" fill="#fff" opacity="0.18"/>')
a('<path d="M130,60 V68" stroke="#e8ecee" stroke-width="2" stroke-linecap="round"/>')

# Temporizador KT: tornillos, escala del dial, LED de tensión y brillo
for x in (304, 356):
    a(tornillo(x, 49, 3.8))
for i in range(11):
    ang = math.radians(135 + i * 27)
    r1, r2 = 15.5, 18 if i % 5 else 20
    a(f'<path d="M{330 + r1 * math.cos(ang):.1f},{72 + r1 * math.sin(ang):.1f} L{330 + r2 * math.cos(ang):.1f},{72 + r2 * math.sin(ang):.1f}" stroke="#30353a" stroke-width="0.9"/>')
a('<ellipse cx="325" cy="65" rx="6" ry="3" fill="#fff" opacity="0.5"/>')
a('<circle cx="362" cy="88" r="2.6" fill="#2fe06a"/><circle cx="362" cy="88" r="5" fill="#2fe06a" opacity="0.25"/>')

# Contactores K1, K3 y K2: tornillos de potencia, rejilla del apagachispas y ventana del indicador
for x0 in (90, 190, 290):
    for dx in (14, 40, 66):
        a(tornillo(x0 + dx, 131))
    for i in range(5):
        a(f'<rect x="{x0 + 22 + i * 8}" y="{142}" width="4" height="5" rx="1" fill="#2a2e32"/>')
    a(f'<rect x="{x0 + 26}" y="158" width="28" height="12" rx="2" fill="#e9ebe7"/>')
    a(f'<rect x="{x0 + 34}" y="160" width="12" height="8" rx="1" fill="#2a2e32"/>')
    a(f'<rect x="{x0 + 18}" y="152" width="44" height="3" fill="#fff" opacity="0.12"/>')
    a(f'<rect x="{x0 + 18}" y="187" width="44" height="3" fill="#000" opacity="0.3"/>')

# Relé térmico F2: dial de ajuste de corriente y botón de rearme
a('<circle cx="148" cy="247" r="8" fill="url(#yd_cabeza)" stroke="#3b4043" stroke-width="0.8"/>')
a('<path d="M148,247 L152,241" stroke="#20242a" stroke-width="2" stroke-linecap="round"/>')
a('<rect x="104" y="240" width="20" height="14" fill="url(#am_tubo)" opacity="0.6"/>')

# Cableado entre aparatos (negro de potencia, rojo de mando)
for dx in (14, 40, 66):
    a(cable(f"M{90 + dx},110 V121"))
    a(cable(f"M{90 + dx},219 V229"))
for xs, xd in ((104, 80), (130, 128), (156, 176)):
    a(cable(f"M{xs},278 Q{xs},286 {xd},289"))
for xs, xd in ((304, 264), (330, 312), (356, 360)):
    a(cable(f"M{xs},216 V250 Q{xs},262 {(xs + xd) / 2},270 Q{xd},278 {xd},289"))
a(cable("M310,110 V121", "#b3261e", 1.8))
a(cable("M350,110 V121", "#b3261e", 1.8))
# Punto de estrella: puente de cobre bajo K3
for dx in (14, 40, 66):
    a(f'<rect x="{190 + dx - 2}" y="216" width="4" height="8" fill="url(#yd_cobre)"/>')
a('<rect x="200" y="221" width="60" height="6" rx="2" fill="url(#yd_cobre)" stroke="#6b3510" stroke-width="0.6"/>')
for dx in (14, 40, 66):
    a(tornillo(190 + dx, 224, 2.2))

# Bornera de salida: topes en los extremos y brillo de los cables al motor
for x in (58, 196, 244, 382):
    a(f'<rect x="{x - 3}" y="292" width="6" height="32" rx="1.5" fill="#5b6267"/><rect x="{x - 3}" y="292" width="1.5" height="32" fill="#fff" opacity="0.35"/>')
for x in (80, 128, 176, 264, 312, 360):
    a(f'<rect x="{x - 8}" y="316" width="16" height="7" rx="1" fill="#2a2e32"/>')
    a(f'<path d="M{x - 1.2},330 V382" stroke="#fff" stroke-opacity="0.3" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "arrancador_yd.svg"), "".join(d), P.DEFS + DEFS)
