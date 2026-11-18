"""Pulsadores de 22 mm (480×420) sobre su SVG. Arriba, frente del tablero: tornillos de la chapa,
aros cromados con moleteado y sombra interior, botones cóncavos con brillo y portaetiquetas con su
canto. Abajo, por detrás del tablero: adaptador de fijación con su leva, bloques de contacto con
nervios, arandela del borne y cable de mando con puntera y marcador."""
import math, os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="pu_concavo" cx="0.62" cy="0.68" r="0.75"><stop offset="0" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></radialGradient>
<linearGradient id="pu_brillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="pu_puntera" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f1f3f4"/><stop offset="0.5" stop-color="#a9b0b4"/><stop offset="1" stop-color="#6d7377"/></linearGradient>
<linearGradient id="pu_cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a4f54"/><stop offset="0.35" stop-color="#25292c"/><stop offset="1" stop-color="#050607"/></linearGradient>
<linearGradient id="pu_lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.12"/><stop offset="0.15" stop-color="#fff" stop-opacity="0"/><stop offset="0.85" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
'''

d = []
a = d.append
# Chapa del tablero: tornillos y canto con luz
for x, y in ((24, 24), (456, 24), (24, 192), (456, 192)):
    a(P.perno(x, y, 4.2))
a('<path d="M12,11.5 H468" stroke="#fff" stroke-opacity="0.6" stroke-width="1.2"/>')
for cx, borde in ((125, "#0a3d18"), (355, "#5a0f09")):
    # Aro cromado: moleteado del borde exterior y sombra interior hacia el botón
    for i in range(48):
        g = math.radians(i * 7.5)
        a(f'<path d="M{cx + 54.5 * math.cos(g):.1f},{90 + 54.5 * math.sin(g):.1f} L{cx + 57.5 * math.cos(g):.1f},{90 + 57.5 * math.sin(g):.1f}" stroke="#6d7377" stroke-width="1.2"/>')
    a(f'<circle cx="{cx}" cy="90" r="49.5" fill="none" stroke="#1d2124" stroke-width="3" opacity="0.6"/>')
    a(f'<path d="M{cx - 40},{50} A57,57 0 0 1 {cx + 28},{40}" stroke="#fff" stroke-width="2" fill="none" opacity="0.7" stroke-linecap="round"/>')
    # Botón cóncavo: sombra arriba, brillo abajo y reflejo de la luz
    a(f'<circle cx="{cx}" cy="90" r="47" fill="url(#pu_concavo)"/>')
    a(f'<ellipse cx="{cx - 14}" cy="62" rx="22" ry="10" fill="url(#pu_brillo)" transform="rotate(-20 {cx - 14} 62)"/>')
    a(f'<path d="M{cx - 30},{124} A44,44 0 0 0 {cx + 34},{118}" stroke="#fff" stroke-opacity="0.25" stroke-width="2" fill="none" stroke-linecap="round"/>')
    # Portaetiqueta: canto con luz y sombra
    a(f'<rect x="{cx - 63}" y="162" width="126" height="30" rx="2" fill="none" stroke="#5f6466" stroke-width="1.2"/>')
    a(f'<path d="M{cx - 61},163.5 H{cx + 61}" stroke="#fff" stroke-opacity="0.2" stroke-width="1"/>')
    a(f'<rect x="{cx - 63}" y="192" width="126" height="4" fill="#000" opacity="0.2"/>')
for cx, lado in ((125, -1), (355, 1)):
    # Adaptador de fijación con su leva y nervios
    for k in range(9):
        a(f'<rect x="{cx - 44 + k * 11}" y="228" width="2" height="18" fill="#5d6367" opacity="0.7"/>')
    a(f'<rect x="{cx - 50}" y="224" width="100" height="2" fill="#fff" opacity="0.5"/>')
    a(f'<rect x="{cx + lado * 54 - 7}" y="228" width="14" height="18" rx="3" fill="#2a2d30"/><rect x="{cx + lado * 54 - 4}" y="232" width="8" height="10" rx="2" fill="#5a6064"/>')
    # Bloque de contacto: cantos y nervios laterales
    a(f'<rect x="{cx - 40}" y="250" width="80" height="150" rx="5" fill="url(#pu_lado)"/>')
    for y in range(280, 396, 8):
        for x in (cx - 37, cx + 33):
            a(f'<rect x="{x}" y="{y}" width="4" height="2" rx="1" fill="#0d0f11"/>')
    for y in (304, 366):
        a(f'<circle cx="{cx}" cy="{y}" r="12.4" fill="none" stroke="#9aa1a5" stroke-width="2.6"/>')
        # Cable de mando: puntera bajo la arandela y cable que sale por el lado
        xa, xb = cx + lado * 13, cx + lado * 30
        a(f'<path d="M{min(xa, xb)},{y - 3.5} H{max(xa, xb)} V{y + 3.5} H{min(xa, xb)} Z" fill="url(#pu_puntera)" stroke="#4a5054" stroke-width="0.5"/>')
        a(f'<rect x="{min(xb, xb + lado * 10)}" y="{y - 5}" width="10" height="10" rx="2" fill="#c03228"/>')
        x1 = xb + lado * 10
        vuelta = 34 if y == 304 else 18
        cable = f'M{x1},{y} H{x1 + lado * (vuelta - 12)} Q{x1 + lado * vuelta},{y} {x1 + lado * vuelta},{y + 12} V420'
        a(f'<path d="{cable}" fill="none" stroke="url(#pu_cable)" stroke-width="7"/>')
        a(f'<path d="M{x1},{y - 1.5} H{x1 + lado * (vuelta - 12)}" stroke="#fff" stroke-opacity="0.25" stroke-width="1.2"/>')
        a(f'<path d="M{x1 + lado * vuelta - lado * 1.5},{y + 12} V420" stroke="#fff" stroke-opacity="0.2" stroke-width="1.2"/>')
        a(f'<rect x="{x1 + lado * vuelta - 5}" y="{y + 22}" width="10" height="11" rx="1.5" fill="#f2f2ec" stroke="#9aa0a3" stroke-width="0.5"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "pulsadores.svg"), "".join(d), P.DEFS + DEFS)
