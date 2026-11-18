"""Piezas de detalle para los dibujos hechos a mano sobre su SVG: pernos, bridas, válvulas, manómetros,
escarcha, placas con texto y rejillas. Sus degradados y filtros van en DEFS (prefijo am_)."""
import math

DEFS = '''
<radialGradient id="am_acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#c3c8cb"/><stop offset="1" stop-color="#4f5558"/></radialGradient>
<linearGradient id="am_tubo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.45"/><stop offset="0.35" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="am_brida" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6c7276"/><stop offset="0.35" stop-color="#d5d9db"/><stop offset="1" stop-color="#5a6064"/></linearGradient>
<linearGradient id="am_bridaV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6c7276"/><stop offset="0.35" stop-color="#d5d9db"/><stop offset="1" stop-color="#5a6064"/></linearGradient>
<linearGradient id="am_placa" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f2f4f4"/><stop offset="0.45" stop-color="#c6ccd0"/><stop offset="0.6" stop-color="#e9ecee"/><stop offset="1" stop-color="#b0b7bb"/></linearGradient>
<linearGradient id="am_cable" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0a0b0c"/><stop offset="0.35" stop-color="#4a4f53"/><stop offset="1" stop-color="#0d0e10"/></linearGradient>
<filter id="am_escarcha" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed="9" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 9 -4.2" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
'''


def perno(x, y, r=3.2):
    return (f'<polygon points="{_hex(x, y, r)}" fill="#596064"/>'
            f'<polygon points="{_hex(x, y, r * 0.86)}" fill="url(#am_acero)"/>')


def _hex(x, y, r):
    return " ".join(f"{x + r * math.cos(math.radians(30 + 60 * i)):.1f},{y + r * math.sin(math.radians(30 + 60 * i)):.1f}" for i in range(6))


def tuerca_pernos(cx, cy, r, n=6, rp=1.8):
    return "".join(perno(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n), rp) for i in range(n))


def brida(x, y, grosor, vertical=False):
    """Par de bridas atornilladas en un tubo de diámetro «grosor», centrado en (x, y)."""
    if vertical:
        w, h = grosor + 10, 7
        s = f'<rect x="{x - w / 2}" y="{y - h}" width="{w}" height="{2 * h}" rx="1.5" fill="url(#am_bridaV)" stroke="#3b4043" stroke-width="0.6"/>'
        s += f'<path d="M{x - w / 2},{y} H{x + w / 2}" stroke="#2a2e31" stroke-width="1"/>'
        s += perno(x - w / 2 + 3, y - 3.5, 1.6) + perno(x + w / 2 - 3, y - 3.5, 1.6) + perno(x - w / 2 + 3, y + 3.5, 1.6) + perno(x + w / 2 - 3, y + 3.5, 1.6)
    else:
        w, h = 7, grosor + 10
        s = f'<rect x="{x - w}" y="{y - h / 2}" width="{2 * w}" height="{h}" rx="1.5" fill="url(#am_brida)" stroke="#3b4043" stroke-width="0.6"/>'
        s += f'<path d="M{x},{y - h / 2} V{y + h / 2}" stroke="#2a2e31" stroke-width="1"/>'
        s += perno(x - 3.5, y - h / 2 + 3, 1.6) + perno(x + 3.5, y - h / 2 + 3, 1.6) + perno(x - 3.5, y + h / 2 - 3, 1.6) + perno(x + 3.5, y + h / 2 - 3, 1.6)
    return s


def valvula(x, y, r=9, color="#c0392b"):
    """Válvula de cierre con su volante, vista de frente sobre el tubo."""
    s = f'<rect x="{x - 6}" y="{y - 6}" width="12" height="12" rx="2" fill="#5a6064"/>'
    s += f'<path d="M{x},{y - 6} V{y - 14}" stroke="#8a9094" stroke-width="3"/>'
    s += f'<circle cx="{x}" cy="{y - 16}" r="{r}" fill="none" stroke="{color}" stroke-width="3"/>'
    for i in range(3):
        a = math.pi * 2 * i / 3 + 0.3
        s += f'<path d="M{x},{y - 16} L{x + r * math.cos(a):.1f},{y - 16 + r * math.sin(a):.1f}" stroke="{color}" stroke-width="2"/>'
    s += f'<circle cx="{x}" cy="{y - 16}" r="2.2" fill="#2a2e31"/>'
    return s


def manometro(x, y, r, angulo=0.3, color_arco="#2f9e57"):
    """Manómetro con esfera blanca, escala, zona de color y aguja."""
    s = f'<circle cx="{x}" cy="{y}" r="{r + 2}" fill="url(#am_acero)"/>'
    s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="#f6f6f2" stroke="#2a2e31" stroke-width="0.8"/>'
    for i in range(11):
        a = math.radians(135 + i * 27)
        s += f'<path d="M{x + r * 0.78 * math.cos(a):.1f},{y + r * 0.78 * math.sin(a):.1f} L{x + r * 0.92 * math.cos(a):.1f},{y + r * 0.92 * math.sin(a):.1f}" stroke="#20242a" stroke-width="0.7"/>'
    a0, a1 = math.radians(135), math.radians(135 + 135)
    s += (f'<path d="M{x + r * 0.7 * math.cos(a0):.1f},{y + r * 0.7 * math.sin(a0):.1f} A{r * 0.7:.1f},{r * 0.7:.1f} 0 0 1 {x + r * 0.7 * math.cos(a1):.1f},{y + r * 0.7 * math.sin(a1):.1f}" '
          f'fill="none" stroke="{color_arco}" stroke-width="1.6" opacity="0.8"/>')
    a = math.radians(135 + 270 * angulo)
    s += f'<path d="M{x},{y} L{x + r * 0.8 * math.cos(a):.1f},{y + r * 0.8 * math.sin(a):.1f}" stroke="#c0392b" stroke-width="1.3" stroke-linecap="round"/>'
    s += f'<circle cx="{x}" cy="{y}" r="1.6" fill="#20242a"/>'
    s += f'<ellipse cx="{x - r * 0.3:.1f}" cy="{y - r * 0.45:.1f}" rx="{r * 0.5:.1f}" ry="{r * 0.22:.1f}" fill="#fff" opacity="0.55"/>'
    return s


def escarcha(d, ancho):
    """Escarcha sobre un tubo frío: puntos blancos sobre el mismo trazado."""
    return (f'<path d="{d}" fill="none" stroke="#dff3ff" stroke-width="{ancho}" stroke-linejoin="round" opacity="0.35"/>'
            f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="{ancho}" stroke-linejoin="round" filter="url(#am_escarcha)" opacity="0.9"/>')


def brillo_tubo(d, ancho):
    return f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="{max(1.2, ancho * 0.18):.1f}" transform="translate(0,-{ancho * 0.22:.1f})" stroke-linejoin="round"/>'


def placa(x, y, w, h, lineas, tam=5.2, titulo=None):
    """Placa de aluminio remachada con texto grabado; «titulo» en negrita arriba."""
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="1.5" fill="url(#am_placa)" stroke="#4f5558" stroke-width="0.8"/>'
    for px, py in ((x + 3, y + 3), (x + w - 3, y + 3), (x + 3, y + h - 3), (x + w - 3, y + h - 3)):
        s += f'<circle cx="{px}" cy="{py}" r="1.3" fill="#6c7276"/>'
    yy = y + 3 + tam * 1.15
    if titulo:
        s += f'<text x="{x + w / 2}" y="{yy}" text-anchor="middle" style="font:800 {tam * 1.25:.1f}px Plex;fill:#1d2226;letter-spacing:.06em">{titulo}</text>'
        yy += tam * 1.35
    for l in lineas:
        s += f'<text x="{x + w / 2}" y="{yy}" text-anchor="middle" style="font:600 {tam}px Plex;fill:#2a3034">{l}</text>'
        yy += tam * 1.22
    return s


def rejilla(x, y, w, h, n, vertical=False, color="#0d1114"):
    s = ""
    for i in range(n):
        if vertical:
            xx = x + (i + 0.5) * w / n
            s += f'<rect x="{xx - 1.6:.1f}" y="{y}" width="3.2" height="{h}" rx="1.6" fill="{color}"/>'
            s += f'<rect x="{xx + 1.6:.1f}" y="{y}" width="0.9" height="{h}" fill="#fff" opacity="0.25"/>'
        else:
            yy = y + (i + 0.5) * h / n
            s += f'<rect x="{x}" y="{yy - 1.6:.1f}" width="{w}" height="3.2" rx="1.6" fill="{color}"/>'
            s += f'<rect x="{x}" y="{yy + 1.6:.1f}" width="{w}" height="0.9" fill="#fff" opacity="0.25"/>'
    return s
