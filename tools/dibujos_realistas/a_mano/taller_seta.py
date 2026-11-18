"""Seta de emergencia del Taller (200×260) sobre su SVG: caja moldeada con tornillos de la tapa,
collar amarillo con el rótulo en arco, cabeza roja abombada con su sombra, brillo y las flechas de
«girar para desenclavar» en relieve, y dos bloques de contacto (NC 11-12 rojo y NA 13-14 verde) con
su indicador de color y bornes de jaula. El juego escribe los números sobre los bornes."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="ts_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="ts_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<radialGradient id="ts_cabeza" cx="0.42" cy="0.36" r="0.66"><stop offset="0" stop-color="#ff6a5a" stop-opacity="0.55"/><stop offset="0.35" stop-color="#e2473a" stop-opacity="0"/><stop offset="0.8" stop-color="#5e100a" stop-opacity="0.25"/><stop offset="1" stop-color="#3a0804" stop-opacity="0.7"/></radialGradient>
<radialGradient id="ts_collar" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#fff6c8" stop-opacity="0.45"/><stop offset="0.6" stop-color="#f4cf3a" stop-opacity="0"/><stop offset="1" stop-color="#7a5c06" stop-opacity="0.35"/></radialGradient>
<path id="ts_arco" d="M43,80 A57,57 0 0 1 157,80"/>
'''


def tornillo_tapa(x, y):
    """Tornillo pequeño de la tapa, ranurado, en su avellanado."""
    return (f'<circle cx="{x}" cy="{y}" r="5" fill="#1b1d20"/><circle cx="{x}" cy="{y}" r="3.8" fill="url(#ts_acero)"/>'
            f'<path d="M{x - 2.6},{y + 1.2} L{x + 2.6},{y - 1.2}" stroke="#30353a" stroke-width="1.2" stroke-linecap="round"/>')


def borne(x, y):
    """Borne de jaula: alojamiento hundido, jaula cincada, boca del cable abajo y tornillo pozidriv."""
    s = f'<rect x="{x - 17}" y="{y - 16}" width="34" height="34" rx="4" fill="#0c0d0f"/>'
    s += (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#ts_jaula)" d="M{x - 14.5},{y - 14} h29 v26 h-29 Z '
          f'M{x + 11.5},{y} a11.5,11.5 0 1 0 -23,0 a11.5,11.5 0 1 0 23,0 Z"/></g>')
    s += f'<rect x="{x - 9}" y="{y + 13}" width="18" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="11.2" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="10.4" fill="url(#ts_acero)"/></g>'
    s += f'<path d="M{x - 6},{y} H{x + 6} M{x},{y - 6} V{y + 6}" stroke="#24282b" stroke-width="2.6" stroke-linecap="round"/>'
    s += f'<path d="M{x - 3.2},{y - 3.2} L{x - 1.6},{y - 1.6} M{x + 3.2},{y - 3.2} L{x + 1.6},{y - 1.6} M{x - 3.2},{y + 3.2} L{x - 1.6},{y + 1.6} M{x + 3.2},{y + 3.2} L{x + 1.6},{y + 1.6}" stroke="#4a5054" stroke-width="0.9"/>'
    s += f'<path d="M{x - 7.5},{y - 4} A8.5,8.5 0 0 1 {x - 2},{y - 8.2}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return s


def flecha_giro(a0, a1, r=31):
    """Flecha curva en relieve sobre la cabeza: sentido para desenclavar."""
    x0, y0 = 100 + r * math.cos(math.radians(a0)), 76 + r * math.sin(math.radians(a0))
    x1, y1 = 100 + r * math.cos(math.radians(a1)), 76 + r * math.sin(math.radians(a1))
    t = math.radians(a1 + 90)
    n = math.radians(a1)
    px, py = x1 + 6 * math.cos(t), y1 + 6 * math.sin(t)
    p1 = f"{x1 + 4 * math.cos(n):.1f},{y1 + 4 * math.sin(n):.1f}"
    p2 = f"{x1 - 4 * math.cos(n):.1f},{y1 - 4 * math.sin(n):.1f}"
    camino = f'M{x0:.1f},{y0:.1f} A{r},{r} 0 0 1 {x1:.1f},{y1:.1f}'
    s = f'<path d="{camino}" stroke="#7a1209" stroke-width="3" fill="none" stroke-linecap="round" transform="translate(0.8,1)"/>'
    s += f'<path d="{camino}" stroke="#ff8f80" stroke-opacity="0.55" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
    s += f'<polygon points="{p1} {px:.1f},{py:.1f} {p2}" fill="#7a1209" transform="translate(0.8,1)"/>'
    s += f'<polygon points="{p1} {px:.1f},{py:.1f} {p2}" fill="#ff8f80" fill-opacity="0.55"/>'
    return s


d = []
a = d.append
# Caja moldeada: canto de la tapa, línea de junta y tornillos de las esquinas
a('<rect x="9.5" y="9.5" width="181" height="241" rx="4" fill="none" stroke="#000" stroke-opacity="0.45" stroke-width="1.2"/>')
a('<rect x="10.5" y="10.5" width="181" height="241" rx="4" fill="none" stroke="#fff" stroke-opacity="0.1" stroke-width="1"/>')
a('<path d="M6,6.5 H194" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
for x, y in ((16, 16), (184, 16), (16, 246), (184, 246)):
    a(tornillo_tapa(x, y))
# Collar amarillo: sombra sobre la tapa, brillo del plástico, canto y rótulo en arco
a('<circle cx="102" cy="83" r="66" fill="none" stroke="#000" stroke-opacity="0.5" stroke-width="5" filter="url(#sombraCorta)"/>')
a('<circle cx="100" cy="80" r="66" fill="url(#ts_collar)"/>')
a('<circle cx="100" cy="80" r="65" fill="none" stroke="#8a6a08" stroke-width="1.6"/>')
a('<circle cx="100" cy="80" r="63.5" fill="none" stroke="#fff6c8" stroke-opacity="0.6" stroke-width="0.9"/>')
a('<text style="font:800 9.5px Plex;fill:#1d1a10;letter-spacing:.14em"><textPath xlink:href="#ts_arco" startOffset="50%" text-anchor="middle">EMERGENCIA</textPath></text>')
# Sombra de la cabeza sobre el collar y cabeza abombada
a('<circle cx="103" cy="84" r="46" fill="#000" opacity="0.45" filter="url(#sombraCorta)"/>')
a('<circle cx="100" cy="80" r="46" fill="#5e100a"/>')
a('<circle cx="100" cy="76" r="44" fill="#d03a2d"/>')
a('<circle cx="100" cy="76" r="44" fill="url(#ts_cabeza)"/>')
a('<circle cx="100" cy="76" r="43.3" fill="none" stroke="#ff8f80" stroke-opacity="0.35" stroke-width="1"/>')
a('<circle cx="100" cy="76" r="36" fill="none" stroke="#5e100a" stroke-opacity="0.2" stroke-width="1.5"/>')
a(flecha_giro(200, 250) + flecha_giro(20, 70))
a('<ellipse cx="84" cy="56" rx="17" ry="8" fill="#fff" opacity="0.45" transform="rotate(-28 84 56)" filter="url(#desenfoque)"/>')
a('<ellipse cx="80" cy="54" rx="6" ry="2.6" fill="#fff" opacity="0.7" transform="rotate(-28 80 54)"/>')
a('<path d="M134,100 A40,40 0 0 1 106,118" stroke="#3a0804" stroke-opacity="0.45" stroke-width="4" fill="none" stroke-linecap="round" filter="url(#desenfoque)"/>')
# Bloques de contacto: NC 11-12 (indicador rojo) y NA 13-14 (indicador verde)
for x0, color in ((16, "#d0392d"), (104, "#2fa84d")):
    a(f'<rect x="{x0 + 0.5}" y="170.5" width="79" height="63" rx="4" fill="none" stroke="#000" stroke-opacity="0.55"/>')
    a(f'<rect x="{x0 + 1.5}" y="171.2" width="77" height="1" fill="#fff" opacity="0.18"/>')
    cx = x0 + 40
    a(f'<rect x="{cx - 6}" y="173" width="12" height="5" rx="1" fill="#050607"/><rect x="{cx - 4}" y="174.4" width="8" height="2" rx="0.8" fill="{color}"/>')
for x in (36, 76, 124, 164):
    a(borne(x, 212))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "seta.svg"), "".join(d), P.DEFS + DEFS)
