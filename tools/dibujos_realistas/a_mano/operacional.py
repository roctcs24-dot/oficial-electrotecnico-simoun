"""Amplificador operacional en cápsula DIP-8 vista desde arriba (400×220) sobre su SVG: epoxi negro
mate con granulado de molde, cara superior más pequeña que la base por la salida del molde, línea
de partición, muesca de la pata 1 con su pared, punto de la pata 1 hundido y liso, hoyuelo del
expulsor, patas estañadas con el doblez hacia abajo y sombras de contacto.

La función dip() y DEFS_DIP sirven también a optoacoplador.py y puerta_logica.py."""
import os
import random
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T

DEFS_DIP = '''
<linearGradient id="dp_cara" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#34383b"/><stop offset="0.35" stop-color="#2a2d30"/><stop offset="1" stop-color="#1d1f21"/></linearGradient>
<linearGradient id="dp_pataArriba" x1="0" y1="1" x2="0" y2="0">
 <stop offset="0" stop-color="#6f767c"/><stop offset="0.2" stop-color="#b8bec2"/><stop offset="0.5" stop-color="#cdd2d5"/>
 <stop offset="0.6" stop-color="#f6f8f8"/><stop offset="0.68" stop-color="#c3c9cc"/><stop offset="0.86" stop-color="#686f74"/><stop offset="1" stop-color="#3a4045"/></linearGradient>
<linearGradient id="dp_pataAbajo" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#6f767c"/><stop offset="0.2" stop-color="#b8bec2"/><stop offset="0.5" stop-color="#cdd2d5"/>
 <stop offset="0.6" stop-color="#f6f8f8"/><stop offset="0.68" stop-color="#c3c9cc"/><stop offset="0.86" stop-color="#686f74"/><stop offset="1" stop-color="#3a4045"/></linearGradient>
<linearGradient id="dp_cantos" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#000" stop-opacity="0.45"/><stop offset="0.18" stop-color="#000" stop-opacity="0"/>
 <stop offset="0.82" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.5"/></linearGradient>
<radialGradient id="dp_hoyo" cx="0.62" cy="0.66" r="0.62">
 <stop offset="0" stop-color="#2c2f32"/><stop offset="0.7" stop-color="#202224"/><stop offset="1" stop-color="#0d0e0f"/></radialGradient>
'''


def _pata(x, y0, y1, ancho, arriba, rnd):
    """Pata vista desde arriba: tramo plano que sale del epoxi y doblez hacia abajo en la punta."""
    alto = abs(y1 - y0)
    y = min(y0, y1)
    s = f'<rect x="{x - ancho / 2}" y="{y}" width="{ancho}" height="{alto}" rx="1.2" fill="url(#{"dp_pataArriba" if arriba else "dp_pataAbajo"})"/>'
    s += f'<rect x="{x - ancho / 2}" y="{y}" width="{ancho}" height="{alto}" rx="1.2" fill="url(#dp_cantos)"/>'
    for _ in range(3):
        s += (f'<ellipse cx="{x + rnd.uniform(-ancho * 0.25, ancho * 0.25):.1f}" cy="{rnd.uniform(y + 4, y + alto - 6):.1f}" '
              f'rx="{rnd.uniform(1.5, 3):.1f}" ry="{rnd.uniform(1, 2):.1f}" fill="#fff" opacity="{rnd.uniform(0.15, 0.35):.2f}"/>')
    # Sombra del cuerpo sobre la pata, junto al epoxi
    if arriba:
        s += f'<rect x="{x - ancho / 2}" y="{y1 - 6}" width="{ancho}" height="6" fill="url(#to_sombraPata)" transform="rotate(180 {x} {y1 - 3})"/>'
    else:
        s += f'<rect x="{x - ancho / 2}" y="{y0}" width="{ancho}" height="6" fill="url(#to_sombraPata)"/>'
    return s


def dip(bx, by, bw, bh, xs, punto, hoyo=None, arriba=(38, 60), abajo=(150, 172), ancho=14, semilla=2):
    """Cápsula DIP: cuerpo (bx, by, bw, bh), centros de las patas «xs», punto de la pata 1
    (x, y, r) y hoyuelo del expulsor (x, y, r)."""
    rnd = random.Random(semilla)
    s = ""
    for x in xs:
        s += _pata(x, arriba[0], arriba[1] + 2, ancho, True, rnd)
        s += _pata(x, abajo[0] - 2, abajo[1], ancho, False, rnd)
    clip = f"dp_clip{bx}"
    caja = f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="6"/>'
    s += f'<clipPath id="{clip}">{caja}</clipPath>'
    s += f'<g filter="url(#to_epoxi)"><rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="6" fill="url(#dp_cara)"/></g>'
    # Paredes del molde: la cara de arriba es algo menor que la base
    c = 5
    s += f'<g clip-path="url(#{clip})">'
    s += f'<path d="M{bx},{by} H{bx + bw} L{bx + bw - c},{by + c} H{bx + c} Z" fill="#fff" opacity="0.12"/>'
    s += f'<path d="M{bx},{by} L{bx + c},{by + c} V{by + bh - c} L{bx},{by + bh} Z" fill="#fff" opacity="0.07"/>'
    s += f'<path d="M{bx + bw},{by} L{bx + bw - c},{by + c} V{by + bh - c} L{bx + bw},{by + bh} Z" fill="#000" opacity="0.32"/>'
    s += f'<path d="M{bx},{by + bh} H{bx + bw} L{bx + bw - c},{by + bh - c} H{bx + c} Z" fill="#000" opacity="0.42"/>'
    # Línea de partición a media altura de las paredes, donde salen las patas
    s += f'<rect x="{bx + 2.2}" y="{by + 2.2}" width="{bw - 4.4}" height="{bh - 4.4}" rx="4" fill="none" stroke="#000" stroke-width="0.6" opacity="0.5"/>'
    s += f'<rect x="{bx + c}" y="{by + c}" width="{bw - 2 * c}" height="{bh - 2 * c}" rx="2.5" fill="none" stroke="#6a7075" stroke-width="0.5" opacity="0.35"/>'
    s += '</g>'
    s += f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="6" fill="none" stroke="#0a0b0c" stroke-width="1.3"/>'
    # Muesca de la pata 1: medio círculo hundido con su pared iluminada al fondo
    mx, my = bx, by + bh / 2
    s += f'<path d="M{mx},{my - 10} A10,10 0 0 1 {mx},{my + 10} Z" fill="#0b0c0d"/>'
    s += f'<path d="M{mx},{my - 10} A10,10 0 0 1 {mx},{my + 10} A8.6,10 0 0 0 {mx},{my - 10} Z" fill="#5a6065" opacity="0.6"/>'
    s += f'<path d="M{mx + 1},{my - 9.8} A10,10 0 0 1 {mx + 8.6},{my - 5}" fill="none" stroke="#000" stroke-width="1.4" opacity="0.7"/>'
    # Punto de la pata 1: hoyuelo liso y algo brillante
    px, py, pr = punto
    s += f'<circle cx="{px}" cy="{py}" r="{pr}" fill="url(#dp_hoyo)"/>'
    s += f'<path d="M{px - pr * 0.8:.1f},{py - pr * 0.6:.1f} A{pr},{pr} 0 0 1 {px + pr * 0.6:.1f},{py - pr * 0.8:.1f}" fill="none" stroke="#000" stroke-width="1" opacity="0.7"/>'
    s += f'<path d="M{px + pr * 0.85:.1f},{py + pr * 0.5:.1f} A{pr},{pr} 0 0 1 {px - pr * 0.5:.1f},{py + pr * 0.85:.1f}" fill="none" stroke="#8a9095" stroke-width="0.7" opacity="0.6"/>'
    s += f'<ellipse cx="{px + pr * 0.15:.1f}" cy="{py + pr * 0.2:.1f}" rx="{pr * 0.45:.1f}" ry="{pr * 0.3:.1f}" fill="#fff" opacity="0.08"/>'
    # Hoyuelo del expulsor, ancho y poco profundo
    if hoyo:
        hx, hy, hr = hoyo
        s += f'<circle cx="{hx}" cy="{hy}" r="{hr}" fill="#26292b" opacity="0.7"/>'
        cc = 2 * 3.1416 * hr
        s += f'<circle cx="{hx}" cy="{hy}" r="{hr}" fill="none" stroke="#000" stroke-width="0.7" stroke-dasharray="{cc * 0.3:.2f} {cc:.2f}" stroke-dashoffset="{-cc * 0.46:.2f}" opacity="0.55"/>'
        s += f'<circle cx="{hx}" cy="{hy}" r="{hr}" fill="none" stroke="#757b80" stroke-width="0.5" stroke-dasharray="{cc * 0.3:.2f} {cc:.2f}" stroke-dashoffset="{cc * 0.04:.2f}" opacity="0.45"/>'
    return s


d = [dip(120, 60, 160, 90, (140, 180, 220, 260), (136, 130, 6), (262, 80, 6.5))]

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "operacional.svg"), "".join(d), P.DEFS + T.DEFS_TO220 + DEFS_DIP)
