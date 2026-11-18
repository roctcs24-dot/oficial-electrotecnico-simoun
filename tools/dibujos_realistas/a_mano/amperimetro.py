"""Amperímetro de cuadro de hierro móvil (300×330) sobre su SVG: tornillos del marco, cristal con
reflejo y sombra interior de la esfera, subdivisiones de la escala, aguja con contrapeso, sombra y
tapa del eje, tornillo de ajuste de cero, símbolos de la esfera (hierro móvil, alterna, posición
vertical) y bornes traseros con arandela, terminal de ojo y cable con su marcador.
voltimetro.py usa la misma capa con su aguja."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="ic_sombraV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.38"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ic_sombraH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.28"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
<linearGradient id="ic_cristal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.34"/><stop offset="0.38" stop-color="#fff" stop-opacity="0.06"/><stop offset="0.62" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#9fb4c4" stop-opacity="0.10"/></linearGradient>
<linearGradient id="ic_estano" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f1f3f4"/><stop offset="0.5" stop-color="#a9b0b4"/><stop offset="1" stop-color="#6d7377"/></linearGradient>
<linearGradient id="ic_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#050607"/><stop offset="0.4" stop-color="#3d4247"/><stop offset="1" stop-color="#08090a"/></linearGradient>
<radialGradient id="ic_tapa" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#9aa0a5"/><stop offset="0.5" stop-color="#2c3034"/><stop offset="1" stop-color="#0c0d0f"/></radialGradient>
'''

CX, CY = 150, 190


def _polar(r, grados):
    a = math.radians(grados)
    return CX + r * math.cos(a), CY + r * math.sin(a)


def tornillo_cruz(x, y, r):
    return (f'<circle cx="{x}" cy="{y}" r="{r + 0.8}" fill="#0b0c0d"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#am_acero)"/>'
            f'<path d="M{x - r * 0.6:.1f},{y} H{x + r * 0.6:.1f} M{x},{y - r * 0.6:.1f} V{y + r * 0.6:.1f}" stroke="#2a2e31" stroke-width="{r * 0.32:.1f}" stroke-linecap="round"/>')


def capa(punta):
    d = []
    a = d.append
    # Tornillos del marco frontal en las esquinas
    for x, y in ((28, 18), (272, 18), (28, 262), (272, 262)):
        a(tornillo_cruz(x, y, 3.6))
    # Brillo del canto superior del marco y escalón hacia la esfera
    a('<path d="M26,11.5 H274" stroke="#fff" stroke-opacity="0.22" stroke-width="1.5"/>')
    a('<rect x="35" y="25" width="230" height="230" rx="3.5" fill="none" stroke="#0d0f11" stroke-width="2"/>')
    # Sombra interior: la esfera queda hundida bajo el cristal
    a('<rect x="36" y="26" width="228" height="12" fill="url(#ic_sombraV)"/>')
    a('<rect x="36" y="26" width="9" height="228" fill="url(#ic_sombraH)"/>')
    # Subdivisiones de la escala entre las marcas principales
    for i in range(10):
        g = 229.5 + i * 9
        x1, y1 = _polar(89, g)
        x2, y2 = _polar(96, g)
        a(f'<path d="M{x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f}" stroke="#20242a" stroke-width="1.1"/>')
    # Arco interior fino de la escala
    x1, y1 = _polar(78, 225)
    x2, y2 = _polar(78, 315)
    a(f'<path d="M{x1:.1f},{y1:.1f} A78,78 0 0 1 {x2:.1f},{y2:.1f}" fill="none" stroke="#20242a" stroke-width="0.7" opacity="0.55"/>')
    # Símbolos de la esfera, abajo a la izquierda: hierro móvil, alterna y posición vertical
    a('<g stroke="#2a2f34" stroke-width="1.3" fill="none" stroke-linecap="round">'
      '<path d="M52,246 A9,9 0 0 1 70,246"/><rect x="58" y="236" width="6" height="9" fill="#2a2f34"/>'
      '<path d="M78,241 q3.5,-5 7,0 t7,0"/>'
      '<path d="M102,236 V247 M97,247 H107"/></g>')
    # Estrella de la prueba de aislamiento, abajo a la derecha
    est = " ".join(f"{238 + (6 if k % 2 == 0 else 2.6) * math.cos(math.radians(-90 + k * 36)):.1f},{242 + (6 if k % 2 == 0 else 2.6) * math.sin(math.radians(-90 + k * 36)):.1f}" for k in range(10))
    a(f'<polygon points="{est}" fill="none" stroke="#2a2f34" stroke-width="1.1"/>')
    # Aguja: sombra sobre la esfera, contrapeso y tapa del eje
    px, py = punta
    dx, dy = px - CX, py - CY
    l = math.hypot(dx, dy)
    ux, uy = dx / l, dy / l
    cola = (CX - ux * 17, CY - uy * 17)
    a(f'<path d="M{cola[0] + 3:.1f},{cola[1] + 4:.1f} L{px + 3:.1f},{py + 4:.1f}" stroke="#000" stroke-opacity="0.28" stroke-width="3.5" stroke-linecap="round" filter="url(#desenfoque)"/>')
    a(f'<path d="M{CX:.1f},{CY:.1f} L{px},{py}" stroke="#c0392b" stroke-width="3" stroke-linecap="round"/>')
    a(f'<path d="M{CX - uy * 0.8:.1f},{CY + ux * 0.8:.1f} L{px - uy * 0.8:.1f},{py + ux * 0.8:.1f}" stroke="#ff8a7a" stroke-width="0.9" stroke-linecap="round" opacity="0.8"/>')
    a(f'<path d="M{CX:.1f},{CY:.1f} L{cola[0]:.1f},{cola[1]:.1f}" stroke="#1d2024" stroke-width="3.2" stroke-linecap="round"/>')
    a(f'<circle cx="{cola[0]:.1f}" cy="{cola[1]:.1f}" r="4.2" fill="#1d2024"/>')
    a(f'<circle cx="{CX}" cy="{CY}" r="9" fill="url(#ic_tapa)"/>')
    a(f'<circle cx="{CX}" cy="{CY}" r="3" fill="#0b0c0d"/>')
    a(f'<ellipse cx="{CX - 3}" cy="{CY - 3.5}" rx="3.2" ry="1.8" fill="#fff" opacity="0.45" transform="rotate(-35 {CX - 3} {CY - 3.5})"/>')
    # Cristal: reflejo en diagonal y brillo del borde superior
    a('<rect x="36" y="26" width="228" height="228" rx="3" fill="url(#ic_cristal)"/>')
    a('<path d="M36,92 L118,26 H150 L36,120 Z" fill="#fff" opacity="0.10"/>')
    a('<path d="M40,28.5 H260" stroke="#fff" stroke-opacity="0.55" stroke-width="1"/>')
    # Tornillo de ajuste de cero en el marco, bajo la esfera
    a('<circle cx="150" cy="262" r="5.6" fill="#0b0c0d"/><circle cx="150" cy="262" r="4.6" fill="url(#ic_tapa)"/>'
      '<path d="M146.6,262 H153.4" stroke="#050506" stroke-width="1.6" stroke-linecap="round"/>')
    # Bloque de bornes: tabique entre bornes, nervios laterales y tornillos de fijación
    a('<rect x="146" y="273" width="8" height="45" rx="2" fill="#24282b"/><rect x="146" y="273" width="2" height="45" fill="#fff" opacity="0.12"/>')
    for x in (76, 220):
        for k in range(4):
            a(f'<rect x="{x + k * 1.6 - 2.4:.1f}" y="276" width="0.8" height="38" fill="#0f1113" opacity="0.8"/>')
    # Bornes: arandela, terminal de ojo estañado y cable que baja por el lado
    for x, lado in ((110, -1), (190, 1)):
        a(f'<circle cx="{x}" cy="295" r="12.5" fill="none" stroke="url(#ic_estano)" stroke-width="3.4"/>')
        xt = x + lado * 12
        xf = x + lado * 34
        a(f'<path d="M{xt},290.5 H{xf} V299.5 H{xt} Z" fill="url(#ic_estano)" stroke="#4a5054" stroke-width="0.6"/>')
        a(f'<rect x="{min(xf, xf + lado * 10):.1f}" y="289" width="10" height="12" rx="2" fill="#c8ccce" stroke="#6d7377" stroke-width="0.5"/>')
        cable = f'M{xf + lado * 10},295 C{xf + lado * 22},295 {xf + lado * 26},305 {xf + lado * 26},330'
        a(f'<path d="{cable}" fill="none" stroke="url(#ic_cable)" stroke-width="6" stroke-linecap="round"/>')
        a(f'<path d="{cable}" fill="none" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2" transform="translate({-lado * 1.2},-1)"/>')
        a(f'<rect x="{xf + lado * 26 - 4.5:.1f}" y="312" width="9" height="11" rx="1.5" fill="#f2f2ec" stroke="#9aa0a3" stroke-width="0.5"/>')
    return "".join(d)


ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "amperimetro.svg"), capa((196, 112)), P.DEFS + DEFS)
