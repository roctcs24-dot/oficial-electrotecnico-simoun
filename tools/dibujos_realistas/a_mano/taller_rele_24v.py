"""Relé auxiliar enchufable del Taller (240×310) sobre su SVG: zócalo con regletas y bornes de jaula,
cabeza del relé con el botón de prueba, cubierta transparente con reflejos, bobina bobinada con sus
carretes, yugo y armadura, láminas de contacto con pastillas de plata, alojamiento del LED (el juego
lo enciende en 200,92), pestañas de retención y etiqueta blanca donde el juego escribe la tensión."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="tr_acero" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#d2d6d8"/><stop offset="0.8" stop-color="#7d8386"/><stop offset="1" stop-color="#43494c"/></radialGradient>
<linearGradient id="tr_jaula" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f2ea"/><stop offset="0.45" stop-color="#b9bcae"/><stop offset="1" stop-color="#6b6f62"/></linearGradient>
<linearGradient id="tr_cobre" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6e3412"/><stop offset="0.3" stop-color="#e09a5e"/><stop offset="0.55" stop-color="#b8692e"/><stop offset="1" stop-color="#5a2a0c"/></linearGradient>
<linearGradient id="tr_hierro" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5b6164"/><stop offset="0.4" stop-color="#b7bdc0"/><stop offset="1" stop-color="#4c5154"/></linearGradient>
<linearGradient id="tr_cabeza" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a5f64"/><stop offset="0.2" stop-color="#3b3f43"/><stop offset="1" stop-color="#25282b"/></linearGradient>
<linearGradient id="tr_reflejo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.32"/><stop offset="0.55" stop-color="#fff" stop-opacity="0.05"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
'''


def borne(x, y):
    """Borne de jaula pequeño del zócalo: jaula cincada, boca del cable y tornillo pozidriv."""
    s = (f'<g filter="url(#bisel)"><path fill-rule="evenodd" fill="url(#tr_jaula)" d="M{x - 13},{y - 12} h26 v22 h-26 Z '
         f'M{x + 9.5},{y} a9.5,9.5 0 1 0 -19,0 a9.5,9.5 0 1 0 19,0 Z"/></g>')
    s += f'<rect x="{x - 8}" y="{y + 10}" width="16" height="4" rx="1" fill="#030304"/>'
    s += f'<circle cx="{x}" cy="{y}" r="9.4" fill="#0a0a0b"/>'
    s += f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="8.6" fill="url(#tr_acero)"/></g>'
    s += f'<path d="M{x - 5},{y} H{x + 5} M{x},{y - 5} V{y + 5}" stroke="#24282b" stroke-width="2.2" stroke-linecap="round"/>'
    s += f'<path d="M{x - 6},{y - 3.4} A7,7 0 0 1 {x - 1.6},{y - 6.8}" stroke="#fff" stroke-opacity="0.75" stroke-width="1.4" fill="none" stroke-linecap="round"/>'
    return s


d = []
a = d.append
# Zócalo: canto superior con luz, separadores entre bornes y numeración en relieve de las regletas
a('<path d="M12,11 H228" stroke="#fff" stroke-opacity="0.22" stroke-width="1.2"/>')
for y0 in (18, 186, 246):
    a(f'<rect x="22" y="{y0}" width="196" height="1.2" fill="#000" opacity="0.6"/><rect x="22" y="{y0 + 39}" width="196" height="1" fill="#fff" opacity="0.12"/>')
for x in (120,):
    a(f'<rect x="{x - 2}" y="20" width="4" height="36" rx="1.5" fill="#1a1c1f"/>')
for x in (71, 121, 171):
    a(f'<rect x="{x - 2}" y="188" width="4" height="36" rx="1.5" fill="#1a1c1f"/>')
a('<rect x="118" y="248" width="4" height="36" rx="1.5" fill="#1a1c1f"/>')
# Pestañas de retención del relé a los lados de la cubierta
for x in (30, 202):
    a(f'<g filter="url(#bisel)"><rect x="{x}" y="106" width="8" height="48" rx="2" fill="#6b7074"/></g>')
    a(f'<rect x="{x + 2}" y="110" width="4" height="40" rx="1.5" fill="#2a2d30"/>')
# Interior: carretes de la bobina, hilo de cobre, yugo y armadura de hierro
a('<rect x="62" y="90" width="50" height="60" rx="4" fill="url(#tr_cobre)"/>')
for y in range(92, 149, 2):
    a(f'<path d="M63,{y} H111" stroke="#5a2a0c" stroke-opacity="0.35" stroke-width="0.7"/>')
a('<path d="M66,94 V146" stroke="#ffd3a8" stroke-opacity="0.45" stroke-width="2"/>')
for y in (85, 148):
    a(f'<rect x="57" y="{y}" width="60" height="7" rx="1.5" fill="#1d1f22"/><rect x="57" y="{y}" width="60" height="1.4" fill="#fff" opacity="0.2"/>')
a('<path d="M117,150 H124 V92 H120" stroke="url(#tr_hierro)" stroke-width="6" fill="none"/>')
a('<path d="M84,84 L126,79" stroke="#9aa1a4" stroke-width="5" stroke-linecap="round"/>')
a('<path d="M84,82.6 L126,77.6" stroke="#fff" stroke-opacity="0.5" stroke-width="1.2" stroke-linecap="round"/>')
# Láminas de contacto con sus pastillas de plata (común, NC y NA)
for y in (98, 130):
    a(f'<path d="M130,{y} H182" stroke="#c7a64f" stroke-width="2.4" stroke-linecap="round" opacity="0.9"/>')
    a(f'<path d="M128,{y - 9} H180 M128,{y + 9} H180" stroke="#6f777b" stroke-width="3" stroke-linecap="round"/>')
    for yy in (y - 7, y + 7):
        a(f'<circle cx="176" cy="{yy}" r="2.6" fill="#e7eaeb" stroke="#6c7276" stroke-width="0.6"/>')
    a(f'<circle cx="176" cy="{y - 2}" r="2.4" fill="#f4f6f6" stroke="#6c7276" stroke-width="0.6"/>')
    a(f'<circle cx="176" cy="{y + 2}" r="2.4" fill="#f4f6f6" stroke="#6c7276" stroke-width="0.6"/>')
a('<path d="M126,78 V136" stroke="#e6e2d4" stroke-width="3" opacity="0.85"/>')
# Etiqueta blanca del relé: el juego escribe la tensión de la bobina en 150,160
a('<rect x="118" y="151" width="66" height="17" rx="1.5" fill="#f3f4f1" stroke="#b8bdbf" stroke-width="0.6"/>')
# Alojamiento del LED en el canto derecho de la cubierta
a('<circle cx="200" cy="92" r="9" fill="#1b1d20"/><circle cx="200" cy="92" r="7" fill="#3a0f0c"/>')
a('<circle cx="198" cy="90" r="2" fill="#fff" opacity="0.4"/>')
# Cubierta transparente: cantos, reflejos en diagonal y brillo del borde
a('<rect x="41" y="71" width="158" height="98" rx="5.5" fill="none" stroke="#fff" stroke-opacity="0.55" stroke-width="1.4"/>')
a('<path d="M52,170 L120,70 H150 L82,170 Z" fill="url(#tr_reflejo)"/>')
a('<path d="M150,170 L196,102 V120 L162,170 Z" fill="#fff" opacity="0.1"/>')
a('<path d="M44,80 V160" stroke="#fff" stroke-opacity="0.6" stroke-width="2" stroke-linecap="round"/>')
# Cabeza del relé sobre la cubierta, con el botón de prueba naranja (A1 y A2 se rotulan encima)
a('<g filter="url(#plastico)"><g filter="url(#bisel)"><rect x="40" y="64" width="160" height="16" rx="4" fill="url(#tr_cabeza)"/></g></g>')
a('<g filter="url(#biselFuerte)"><rect x="110" y="66" width="20" height="12" rx="3" fill="#e8892a"/></g>')
a('<rect x="113" y="70" width="14" height="1.6" rx="0.8" fill="#8a4a0c"/>')
for x, y in ((70, 38), (170, 38), (46, 206), (96, 206), (146, 206), (196, 206), (70, 266), (170, 266)):
    a(borne(x, y))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "taller", "rele_24v.svg"), "".join(d), P.DEFS + DEFS)
