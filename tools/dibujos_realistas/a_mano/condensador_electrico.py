"""Condensadores (400×220) sobre su SVG. Izquierda, condensador de marcha de polipropileno: faston de
latón con su agujero y su collar de plástico, tapa sellada con resina, brillo de la caja moldeada,
etiqueta impresa con su franja y su símbolo, y espárrago de fijación roscado. Derecha, electrolítico:
tapa de aluminio con la válvula de seguridad grabada, funda termorretráctil con el borde enrollado,
brillo de la funda, franja del negativo, ranura de sellado y patillas estañadas."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="ce_resina" cx="0.4" cy="0.35" r="0.8"><stop offset="0" stop-color="#f4ead0"/><stop offset="0.7" stop-color="#d9c79a"/><stop offset="1" stop-color="#a99567"/></radialGradient>
<radialGradient id="ce_alu" cx="0.38" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#cfd5da"/><stop offset="1" stop-color="#7d868d"/></radialGradient>
<linearGradient id="ce_funda" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.12" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.22" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.3" stop-color="#fff" stop-opacity="0.05"/>
 <stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
<linearGradient id="ce_caja" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#000" stop-opacity="0.18"/><stop offset="0.14" stop-color="#fff" stop-opacity="0.7"/>
 <stop offset="0.24" stop-color="#fff" stop-opacity="0"/><stop offset="0.8" stop-color="#000" stop-opacity="0"/>
 <stop offset="1" stop-color="#000" stop-opacity="0.22"/></linearGradient>
<linearGradient id="ce_etiqueta" x1="0" y1="0" x2="1" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.5"/><stop offset="0.35" stop-color="#fff" stop-opacity="0"/>
 <stop offset="1" stop-color="#000" stop-opacity="0.06"/></linearGradient>
<linearGradient id="ce_laton" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#8a6a22"/><stop offset="0.3" stop-color="#fff2c4"/><stop offset="0.55" stop-color="#d2ad55"/><stop offset="1" stop-color="#7a5c1c"/></linearGradient>
<linearGradient id="ce_rosca" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#5d6367"/><stop offset="0.35" stop-color="#e9ecee"/><stop offset="1" stop-color="#4f5558"/></linearGradient>
'''

d = []
a = d.append


def sombra_contacto(cx, cy, rx, ry, op=0.45):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#000" opacity="{op}" filter="url(#sombraCorta)"/>'


def brillo_patilla(x, y1, y2, ancho):
    """Patilla vertical estañada: filo oscuro a la derecha y reflejo blanco a la izquierda."""
    return (f'<path d="M{x + ancho * 0.3:.1f},{y1} V{y2}" stroke="#3d4347" stroke-opacity="0.55" stroke-width="{ancho * 0.25:.1f}"/>'
            f'<path d="M{x - ancho * 0.18:.1f},{y1} V{y2 - 1}" stroke="#fff" stroke-opacity="0.9" stroke-width="{ancho * 0.22:.1f}" stroke-linecap="round"/>')


# ----- Condensador de marcha -----
# Espárrago de fijación M8 bajo la caja, con su rosca y la sombra de apoyo
a(sombra_contacto(100, 192, 56, 4))
a('<rect x="94" y="184" width="12" height="17" rx="1.5" fill="url(#ce_rosca)" stroke="#3b4043" stroke-width="0.6"/>')
for y in range(187, 200, 2):
    a(f'<path d="M94,{y} L106,{y + 1.2}" stroke="#30363a" stroke-width="0.7" opacity="0.8"/>')
# Brillo de la caja moldeada y línea de la junta del molde
a('<rect x="40" y="56" width="120" height="130" rx="10" fill="url(#ce_caja)"/>')
a('<path d="M44,170 Q100,177 156,170" fill="none" stroke="#7b8084" stroke-width="0.9" opacity="0.7"/>')
a('<path d="M44,171.5 Q100,178.5 156,171.5" fill="none" stroke="#fff" stroke-width="0.8" opacity="0.6"/>')
# Tapa sellada con resina dentro del borde de la caja
a('<ellipse cx="100" cy="55" rx="54" ry="7.2" fill="url(#ce_resina)" stroke="#9c9f9f" stroke-width="1"/>')
a('<path d="M50,56 Q100,64 150,56" fill="none" stroke="#fff" stroke-width="1" opacity="0.6"/>')
a('<ellipse cx="78" cy="53" rx="18" ry="2.4" fill="#fff" opacity="0.35"/>')
# Collares de plástico de los faston y los faston de latón con su agujero
for x in (80, 120):
    a(f'<ellipse cx="{x}" cy="53" rx="12" ry="3.6" fill="#d6d8d8" stroke="#8e9396" stroke-width="0.8"/>')
    a(f'<rect x="{x - 8}" y="24" width="16" height="28" rx="2" fill="url(#ce_laton)" stroke="#5b4a1e" stroke-width="0.8"/>')
    a(f'<path d="M{x - 8},44 H{x + 8}" stroke="#5b4a1e" stroke-width="0.7" opacity="0.7"/>')
    a(f'<path d="M{x - 8},45 H{x + 8}" stroke="#fff3c8" stroke-width="0.6" opacity="0.7"/>')
    a(f'<circle cx="{x}" cy="35" r="2.8" fill="#2b2210"/>')
    a(f'<path d="M{x - 2.4},36.4 A2.8,2.8 0 0 0 {x + 2.4},36.4" fill="none" stroke="#fff0c0" stroke-width="0.7" opacity="0.8"/>')
    a(f'<path d="M{x - 4},26 V50" stroke="#fffbe8" stroke-width="1.4" opacity="0.75" stroke-linecap="round"/>')
# Etiqueta impresa: franja de color, filete, brillo y símbolo del condensador
a('<rect x="48" y="78" width="104" height="9" rx="3" fill="#24477a"/>')
a('<rect x="48" y="84" width="104" height="3" fill="#24477a"/>')
a('<path d="M54,82.5 H146" stroke="#ffffff" stroke-width="0.8" opacity="0.5" stroke-dasharray="10 3"/>')
a('<rect x="51.5" y="89.5" width="97" height="61" rx="2" fill="none" stroke="#9aa3aa" stroke-width="0.7"/>')
a('<path d="M60,147 H66 M66,143 V151 M69,143 V151 M69,147 H75" stroke="#3b4043" stroke-width="1" fill="none"/>')
a('<path d="M125,147 H140" stroke="#3b4043" stroke-width="0.8"/>')
a('<rect x="48" y="78" width="104" height="76" rx="4" fill="url(#ce_etiqueta)"/>')

# ----- Electrolítico -----
a(sombra_contacto(291, 177, 44, 3.5, 0.5))
# Brillo de la funda termorretráctil, encima de todo el cuerpo
a('<rect x="246" y="66" width="90" height="108" rx="10" fill="url(#ce_funda)"/>')
a('<rect x="263" y="72" width="5" height="96" rx="2.5" fill="#fff" opacity="0.45" filter="url(#desenfoque)"/>')
# Franja del negativo: filetes y signos
a('<path d="M314,70 V172" stroke="#8ea1b6" stroke-width="0.8"/><path d="M330,70 V172" stroke="#0f2a4d" stroke-width="0.8" opacity="0.6"/>')
for y in (86, 112, 138, 160):
    a(f'<path d="M318.5,{y - 1.2} H325.5" stroke="#fff" stroke-width="0.7" opacity="0.5"/>')
# Ranura de sellado cerca de la base y borde de la funda enrollado abajo
a('<path d="M247,157 Q291,165 335,157" fill="none" stroke="#0d2442" stroke-width="2.2" opacity="0.75"/>')
a('<path d="M247,159.5 Q291,167.5 335,159.5" fill="none" stroke="#a9c7ea" stroke-width="1" opacity="0.6"/>')
a('<path d="M249,170 Q291,177 333,170" fill="none" stroke="#0d2442" stroke-width="1.6" opacity="0.6"/>')
# Tapa de aluminio dentro del borde enrollado de la funda, con la válvula de seguridad grabada
a('<ellipse cx="291" cy="64" rx="44.5" ry="7.8" fill="#1f4f8c" stroke="#123056" stroke-width="1.4"/>')
a('<ellipse cx="291" cy="64.4" rx="39" ry="6" fill="url(#ce_alu)" stroke="#5f6c78" stroke-width="0.6"/>')
for dd in ("M271,64.4 H311", "M291,59 V69.8", "M277,60.4 L305,68.4", "M305,60.4 L277,68.4"):
    a(f'<path d="{dd}" stroke="#4f5b66" stroke-width="1.4" stroke-linecap="round"/>')
    a(f'<path d="{dd}" stroke="#fff" stroke-width="0.6" opacity="0.8" transform="translate(0.6,0.9)" stroke-linecap="round"/>')
a('<ellipse cx="280" cy="61.6" rx="11" ry="1.8" fill="#fff" opacity="0.55"/>')
a('<path d="M248,65 Q291,73 334,65" fill="none" stroke="#7fb0e8" stroke-width="1" opacity="0.6"/>')
# Patillas estañadas
a(brillo_patilla(268, 175, 202, 4))
a(brillo_patilla(314, 175, 196, 4))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "condensador_electrico.svg"), "".join(d), P.DEFS + DEFS)
