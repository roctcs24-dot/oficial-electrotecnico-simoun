"""MOSFET de canal N en cápsula TO-220 (400×220) sobre su SVG: lengüeta de cobre niquelado con
acabado satinado y agujero troquelado, epoxi negro mate con el granulado del molde, línea de
partición, marcas de los expulsores, serigrafía láser tenue (datos de la ficha), patas estañadas con
su hombro ancho y sombras de contacto.

Las funciones to220() y DEFS_TO220 sirven también a tiristor.py, triac.py y regulador.py, que
tienen la misma cápsula en el mismo sitio."""
import os
import random
import realzar as R
from a_mano import _piezas as P

DEFS_TO220 = '''
<linearGradient id="to_hoja" x1="0" y1="0" x2="1" y2="0.35">
 <stop offset="0" stop-color="#959ca1"/><stop offset="0.18" stop-color="#cdd2d5"/><stop offset="0.42" stop-color="#e8ebed"/>
 <stop offset="0.62" stop-color="#b5bbbf"/><stop offset="0.85" stop-color="#d4d8db"/><stop offset="1" stop-color="#858c91"/></linearGradient>
<linearGradient id="to_reflejo" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.38"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/></linearGradient>
<radialGradient id="to_hueco" cx="0.42" cy="0.38" r="0.62">
 <stop offset="0" stop-color="#050607"/><stop offset="0.7" stop-color="#121416"/><stop offset="1" stop-color="#3b4044"/></radialGradient>
<linearGradient id="to_canto" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#5e656a"/><stop offset="0.5" stop-color="#8d9499"/><stop offset="1" stop-color="#ffffff"/></linearGradient>
<linearGradient id="to_epoxiG" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#3c4044"/><stop offset="0.07" stop-color="#2c2f32"/><stop offset="0.55" stop-color="#232628"/><stop offset="1" stop-color="#18191b"/></linearGradient>
<linearGradient id="to_estano" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#626a70"/><stop offset="0.22" stop-color="#c9ced1"/><stop offset="0.4" stop-color="#ffffff"/>
 <stop offset="0.58" stop-color="#b9bfc3"/><stop offset="0.85" stop-color="#868d92"/><stop offset="1" stop-color="#565d62"/></linearGradient>
<linearGradient id="to_sombraPata" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#000" stop-opacity="0.7"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<filter id="to_epoxi" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="2.3" numOctaves="2" seed="21" result="n"/>
 <feDiffuseLighting in="n" surfaceScale="1.3" diffuseConstant="1.05" lighting-color="#ffffff" result="l"><feDistantLight azimuth="235" elevation="52"/></feDiffuseLighting>
 <feComposite in="SourceGraphic" in2="l" operator="arithmetic" k1="1.15" k2="0" k3="0" k4="0" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
<filter id="to_satin" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.05 1.3" numOctaves="2" seed="4" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0.3 0" result="g"/>
 <feComposite in="g" in2="SourceAlpha" operator="in" result="g2"/>
 <feBlend in="SourceGraphic" in2="g2" mode="overlay"/>
</filter>
'''


def hoja(x=154, y=20, w=92, h=66, hueco=(200, 46, 12), con_hueco=True):
    """Lengüeta metálica satinada con sus cantos y el agujero troquelado."""
    s = f'<g filter="url(#bisel)"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="url(#to_hoja)" filter="url(#to_satin)"/></g>'
    s += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="url(#to_reflejo)"/>'
    # Cantos: luz arriba y a la izquierda, sombra abajo y a la derecha
    s += f'<path d="M{x + 4},{y + 0.8} H{x + w - 4}" stroke="#fff" stroke-width="1.2" opacity="0.85"/>'
    s += f'<path d="M{x + 0.8},{y + 4} V{y + h - 2}" stroke="#fff" stroke-width="1" opacity="0.5"/>'
    s += f'<path d="M{x + w - 0.8},{y + 4} V{y + h - 2}" stroke="#30363a" stroke-width="1.2" opacity="0.7"/>'
    s += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="none" stroke="#454c51" stroke-width="1"/>'
    if con_hueco:
        cx, cy, r = hueco
        s += f'<circle cx="{cx}" cy="{cy}" r="{r + 1.6}" fill="none" stroke="url(#to_canto)" stroke-width="2.2"/>'
        s += f'<circle cx="{cx}" cy="{cy}" r="{r + 0.4}" fill="url(#to_hueco)"/>'
        # Pared interior del agujero, iluminada al fondo (abajo a la derecha)
        s += (f'<path d="M{cx + r * 0.95:.1f},{cy - r * 0.3:.1f} A{r},{r} 0 0 1 {cx - r * 0.3:.1f},{cy + r * 0.95:.1f} '
              f'A{r * 1.15:.1f},{r * 1.15:.1f} 0 0 0 {cx + r * 0.95:.1f},{cy - r * 0.3:.1f} Z" fill="#9aa1a6" opacity="0.55"/>')
        s += f'<path d="M{cx - r * 0.7:.1f},{cy - r * 0.7:.1f} A{r},{r} 0 0 1 {cx + r * 0.7:.1f},{cy - r * 0.7:.1f}" fill="none" stroke="#000" stroke-width="1.5" opacity="0.5"/>'
    return s


def cuerpo(x=156, y=80, w=88, h=62, texto=None, banda=None):
    """Epoxi negro mate con granulado de molde, chaflanes, partición y expulsores.
    «banda»: altura extra de epoxi que sube sobre la lengüeta (cápsulas aisladas)."""
    s = ""
    if banda:
        y0 = y - banda
        s += f'<g filter="url(#to_epoxi)"><rect x="{x - 2}" y="{y0}" width="{w + 4}" height="{banda + 4}" rx="1.5" fill="#2e3236"/></g>'
        s += f'<path d="M{x - 2},{y0 + 0.6} H{x + w + 2}" stroke="#fff" stroke-width="0.9" opacity="0.3"/>'
        s += f'<path d="M{x - 2},{y0 + banda + 3} H{x + w + 2}" stroke="#000" stroke-width="1" opacity="0.5"/>'
    s += f'<g filter="url(#to_epoxi)"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#to_epoxiG)"/></g>'
    # Chaflanes del molde
    s += f'<path d="M{x + 3},{y} H{x + w - 3} L{x + w - 6},{y + 4} H{x + 6} Z" fill="#fff" opacity="0.13"/>'
    s += f'<path d="M{x},{y + 3} L{x + 3.5},{y + 6} V{y + h - 6} L{x},{y + h - 3} Z" fill="#fff" opacity="0.08"/>'
    s += f'<path d="M{x + w},{y + 3} L{x + w - 3.5},{y + 6} V{y + h - 6} L{x + w},{y + h - 3} Z" fill="#000" opacity="0.3"/>'
    s += f'<path d="M{x + 3},{y + h} H{x + w - 3} L{x + w - 6},{y + h - 4} H{x + 6} Z" fill="#000" opacity="0.4"/>'
    s += f'<path d="M{x + 6},{y + 4.2} H{x + w - 6}" stroke="#000" stroke-width="0.6" opacity="0.45"/>'
    s += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="none" stroke="#0b0c0d" stroke-width="1.2"/>'
    # Expulsores: dos hoyuelos lisos, algo más brillantes que el granulado
    for ex in (x + 13, x + w - 13):
        ey = y + h - 12
        s += f'<circle cx="{ex}" cy="{ey}" r="4.4" fill="#2b2e31" opacity="0.8"/>'
        s += f'<circle cx="{ex}" cy="{ey}" r="4.4" fill="none" stroke="#000" stroke-width="0.7" stroke-dasharray="7 20" stroke-dashoffset="-9" opacity="0.6"/>'
        s += f'<circle cx="{ex}" cy="{ey}" r="4.4" fill="none" stroke="#7a8085" stroke-width="0.5" stroke-dasharray="7 20" stroke-dashoffset="5" opacity="0.5"/>'
    if texto:
        s += (f'<text x="{x + w / 2}" y="{y + h - 15}" text-anchor="middle" '
              f'style="font:600 6.2px Plex;fill:#a7adb2;letter-spacing:.1em" opacity="0.38">{texto}</text>')
    return s


def patas(xs=(170, 200, 230), y0=142, y1=210, ancho=6, hombro=9.6, semilla=3):
    """Patas estañadas con hombro ancho a la salida del epoxi, brillo y grumos de estaño."""
    rnd = random.Random(semilla)
    s = ""
    for x in xs:
        s += f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="{y1 - y0 + ancho / 2}" rx="{ancho / 2}" fill="url(#to_estano)"/>'
        s += (f'<path d="M{x - hombro / 2},{y0} V{y0 + 8} L{x - ancho / 2},{y0 + 12} H{x + ancho / 2} '
              f'L{x + hombro / 2},{y0 + 8} V{y0} Z" fill="url(#to_estano)"/>')
        s += f'<path d="M{x - hombro / 2 + 1},{y0 + 8.3} L{x - ancho / 2 + 0.6},{y0 + 11.6}" stroke="#fff" stroke-width="0.7" opacity="0.7"/>'
        s += f'<rect x="{x - ancho * 0.12:.2f}" y="{y0 + 13}" width="{ancho * 0.16:.2f}" height="{y1 - y0 - 15}" rx="0.5" fill="#fff" opacity="0.75"/>'
        for _ in range(5):
            yy = rnd.uniform(y0 + 16, y1 - 6)
            s += f'<ellipse cx="{x + rnd.uniform(-1.2, 1.2):.1f}" cy="{yy:.1f}" rx="{ancho * 0.38:.1f}" ry="{rnd.uniform(1.2, 2.6):.1f}" fill="#fff" opacity="{rnd.uniform(0.12, 0.3):.2f}"/>'
        # Corte de la punta: cobre a la vista
        s += f'<ellipse cx="{x}" cy="{y1 + ancho / 2 - 1.2}" rx="{ancho / 2 - 0.8}" ry="1.1" fill="#b87a4b" opacity="0.65"/>'
        # Sombra de contacto bajo el epoxi
        s += f'<rect x="{x - hombro / 2}" y="{y0}" width="{hombro}" height="7" fill="url(#to_sombraPata)"/>'
    return s


def to220(texto=None, con_hueco=True, banda=None):
    return hoja(con_hueco=con_hueco) + cuerpo(texto=texto, banda=banda) + patas()


d = [to220("55 V · 49 A")]

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "mosfet.svg"), "".join(d), P.DEFS + DEFS_TO220)
