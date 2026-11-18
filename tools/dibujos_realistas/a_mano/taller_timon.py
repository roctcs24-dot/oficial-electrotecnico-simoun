"""Válvulas de gobierno del servomotor de la mesa del Taller (340×240) sobre su SVG: bloque
distribuidor rojo mecanizado con tornillos Allen y tapones de los puertos, cuerpo de la válvula
direccional con su corredera, bobinas BR y ER con aletas, tuerca moleteada del accionamiento
manual y conector de bobina, mangueras hidráulicas con racores prensados, y cables de las bobinas
hasta la regleta de baquelita de X1 a X4."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tti_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d9dddf"/><stop offset="0.72" stop-color="#8b9194"/><stop offset="1" stop-color="#454b4e"/></radialGradient>
<linearGradient id="tti_bloque" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.08" stop-color="#fff" stop-opacity="0.04"/><stop offset="0.85" stop-color="#000" stop-opacity="0.08"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="tti_cuerpo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9ea4a7"/><stop offset="0.3" stop-color="#6c7276"/><stop offset="1" stop-color="#3a3f43"/></linearGradient>
<linearGradient id="tti_bobina" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.4"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
<linearGradient id="tti_manguera" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0b0c"/><stop offset="0.35" stop-color="#4a4f53"/><stop offset="1" stop-color="#0d0e10"/></linearGradient>
<linearGradient id="tti_baquelita" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3d40"/><stop offset="1" stop-color="#141516"/></linearGradient>
'''

d = []
a = d.append


def tornillo(x, y, r, ang):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = f'<circle cx="{x}" cy="{y}" r="{r + 1.3}" fill="#0c0d0e"/>'
    t += f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#tti_acero)"/></g>'
    l = r * 0.6
    t += f'<path d="M{x - l * c:.1f},{y - l * s:.1f} L{x + l * c:.1f},{y + l * s:.1f} M{x + l * s:.1f},{y - l * c:.1f} L{x - l * s:.1f},{y + l * c:.1f}" stroke="#2a2e31" stroke-width="{r * 0.24:.1f}" stroke-linecap="round"/>'
    return t


def allen(x, y, r=4.2):
    hexa = " ".join(f"{x + r * 0.5 * math.cos(math.radians(60 * i)):.1f},{y + r * 0.5 * math.sin(math.radians(60 * i)):.1f}" for i in range(6))
    return (f'<circle cx="{x}" cy="{y}" r="{r + 0.8}" fill="#2a0c06" opacity="0.7"/>'
            f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="{r}" fill="#3a3e42"/></g><polygon points="{hexa}" fill="#0b0c0d"/>')


def tapon(x, y):
    hexa = " ".join(f"{x + 6 * math.cos(math.radians(30 + 60 * i)):.1f},{y + 6 * math.sin(math.radians(30 + 60 * i)):.1f}" for i in range(6))
    return f'<g filter="url(#bisel)"><polygon points="{hexa}" fill="#b9bfc2"/></g><circle cx="{x}" cy="{y}" r="2.4" fill="#5f6568"/>'


# Mangueras hidráulicas a los costados con racor prensado
for x0, x1, xr in ((4, 30, 22), (310, 336, 312)):
    a(f'<rect x="{x0}" y="102" width="{x1 - x0}" height="16" fill="url(#tti_manguera)"/>')
    a(f'<g filter="url(#bisel)"><rect x="{xr}" y="100" width="10" height="20" rx="2" fill="#b9bfc2"/></g>')
    for k in range(3):
        a(f'<rect x="{xr + 1 + k * 3}" y="100" width="1" height="20" fill="#5f6568"/>')
# Bloque distribuidor: caras mecanizadas, tornillos Allen y tapones de los puertos
a('<rect x="30" y="40" width="280" height="110" rx="8" fill="url(#tti_bloque)"/>')
a('<path d="M36,42 H304" stroke="#e98c78" stroke-opacity="0.5" stroke-width="1.2"/>')
for x, y in ((42, 92), (298, 92), (42, 140), (298, 140)):
    a(allen(x, y))
a(tapon(52, 116) + tapon(288, 116))
# Cuerpo de la válvula direccional con la corredera entre las bobinas
a('<g filter="url(#biselFuerte)"><rect x="68" y="88" width="204" height="52" rx="4" fill="url(#tti_cuerpo)"/></g>')
a('<path d="M70,90 H270" stroke="#fff" stroke-opacity="0.45" stroke-width="1"/>')
for x, y in ((78, 98), (262, 98), (78, 130), (262, 130)):
    a(allen(x, y, 3.6))
a('<rect x="96" y="108" width="148" height="12" rx="6" fill="#2a2e31"/>')
a('<rect x="100" y="110" width="140" height="3" rx="1.5" fill="#c9ced1" opacity="0.6"/>')
for x in (140, 170, 200):
    a(f'<rect x="{x - 1}" y="106" width="2" height="16" fill="#1a1d1f"/>')

# Bobinas BR y ER: curvatura, aletas, tuerca moleteada y conector de bobina
for x0, conector in ((60, 38), (210, 280)):
    a(f'<rect x="{x0}" y="20" width="70" height="60" rx="6" fill="url(#tti_bobina)"/>')
    for k in range(5):
        y = 26 + k * 12
        if 46 <= y <= 66:
            continue
        a(f'<rect x="{x0 + 4}" y="{y}" width="62" height="2.4" rx="1.2" fill="#063218" opacity="0.6"/>')
        a(f'<rect x="{x0 + 4}" y="{y + 2.4}" width="62" height="0.8" fill="#fff" opacity="0.25"/>')
    xc = x0 + 35
    a(f'<g filter="url(#bisel)"><rect x="{xc - 10}" y="8" width="20" height="13" rx="2" fill="#b9bfc2"/></g>')
    for k in range(7):
        a(f'<rect x="{xc - 9 + k * 3}" y="9" width="1.2" height="11" fill="#5f6568"/>')
    a(f'<circle cx="{xc}" cy="8" r="3.4" fill="#c0392b"/>')
    a(f'<g filter="url(#bisel)"><rect x="{conector}" y="30" width="22" height="40" rx="3" fill="#1b1d1f"/></g>')
    a(tornillo(conector + 11, 40, 3.4, 20))
    a(f'<rect x="{conector + 5}" y="56" width="12" height="8" rx="2" fill="#2f3337"/>')

# Regleta de baquelita de X1 a X4 con su separador en el centro
a('<rect x="26" y="182" width="288" height="36" rx="4" fill="url(#tti_baquelita)" stroke="#0a0b0c" stroke-width="1"/>')
a('<rect x="26" y="182" width="288" height="1.6" fill="#fff" opacity="0.15"/>')
for x in (90, 170, 250):
    a(f'<g filter="url(#bisel)"><rect x="{x - 3}" y="180" width="6" height="40" rx="2" fill="#2e3134"/></g>')
for i, x in enumerate((50, 130, 210, 290)):
    a(f'<circle cx="{x}" cy="200" r="15" fill="#c9ced1" stroke="#4f5558" stroke-width="1"/>')
    a(tornillo(x, 200, 11, 15 - i * 11))
# Cables de las bobinas hasta la regleta, por fuera de las marcas
for dd in ("M40,64 H22 Q14,64 14,72 V218 Q14,228 24,228 H88 V218", "M300,64 H318 Q326,64 326,72 V218 Q326,228 316,228 H252 V218"):
    a(f'<path d="{dd}" fill="none" stroke="#0e1012" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>')
    a(f'<path d="{dd}" fill="none" stroke="#fff" stroke-opacity="0.2" stroke-width="1.4" transform="translate(-1,-1)"/>')
a('<path d="M10,5 H330" stroke="#fff" stroke-opacity="0.28" stroke-width="1.2"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "timon.svg"), "".join(d), P.DEFS + DEFS)
