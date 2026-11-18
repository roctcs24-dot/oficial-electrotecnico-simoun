"""Varistor de disco (400×220) sobre su SVG: recubrimiento de epoxi azul por inmersión con su brillo
irregular, borde más grueso, relieve de las patillas soldadas al disco bajo el recubrimiento, gota de
epoxi que baja por las patillas, patillas estañadas con su doblez y brillo, y sombra de apoyo."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<radialGradient id="va_disco" cx="0.36" cy="0.3" r="0.8">
 <stop offset="0" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.35" stop-color="#fff" stop-opacity="0"/>
 <stop offset="0.82" stop-color="#000" stop-opacity="0"/><stop offset="0.93" stop-color="#7fb2ea" stop-opacity="0.18"/>
 <stop offset="1" stop-color="#000" stop-opacity="0.45"/></radialGradient>
<filter id="va_ondas" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="4" result="n"/>
 <feDiffuseLighting in="n" surfaceScale="2.2" diffuseConstant="1" lighting-color="#ffffff" result="l"><feDistantLight azimuth="235" elevation="50"/></feDiffuseLighting>
 <feColorMatrix in="l" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0.9 0 0 0 -0.62" result="b"/>
 <feComposite in="b" in2="SourceAlpha" operator="in"/>
</filter>
<linearGradient id="va_hilo" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.3" stop-color="#ffffff"/><stop offset="0.55" stop-color="#b8bec2"/><stop offset="1" stop-color="#6c7378"/></linearGradient>
<linearGradient id="va_gota" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#0f2a4d"/><stop offset="0.35" stop-color="#3f7ec4"/><stop offset="1" stop-color="#0f2a4d"/></linearGradient>
'''

d = []
a = d.append
a('<ellipse cx="200" cy="197" rx="26" ry="2" fill="#000" opacity="0.35" filter="url(#sombraCorta)"/>')
# Patillas estañadas con su doblez de apoyo
for x in (184, 216):
    s = -1 if x < 200 else 1
    a(f'<path d="M{x - 1},132 L{x + 4 * s - 1},150 V195" fill="none" stroke="#fff" stroke-width="1.1" opacity="0.85"/>')
    a(f'<path d="M{x + 1.4},132 L{x + 4 * s + 1.4},150 V195" fill="none" stroke="#4f5558" stroke-width="0.7" opacity="0.6"/>')
# Gota de epoxi que baja por las patillas desde el disco
a('<path d="M176,134 Q183,138 182,146 Q181.6,151 184,151 Q186.5,151 186,146 Q186,140 194,140 Z" fill="url(#va_gota)"/>')
a('<path d="M224,134 Q217,138 218,146 Q218.4,151 216,151 Q213.5,151 214,146 Q214,140 206,140 Z" fill="url(#va_gota)"/>')
# Recubrimiento: ondulación del baño, relieve de las patillas soldadas al disco y borde grueso
a('<circle cx="200" cy="84" r="57" fill="#fff" filter="url(#va_ondas)"/>')
a('<circle cx="200" cy="84" r="58" fill="url(#va_disco)"/>')
for x in (186, 214):
    a(f'<path d="M{x},106 V136" stroke="#0f2a4d" stroke-width="3" opacity="0.25" stroke-linecap="round"/>')
    a(f'<path d="M{x - 1.6},108 V134" stroke="#9cc8f4" stroke-width="0.9" opacity="0.35" stroke-linecap="round"/>')
a('<circle cx="200" cy="84" r="56.5" fill="none" stroke="#7fb2ea" stroke-width="0.8" opacity="0.35"/>')
a('<path d="M152,72 Q160,44 196,32" fill="none" stroke="#fff" stroke-width="1.8" opacity="0.75" stroke-linecap="round"/>')
a('<path d="M242,118 Q232,132 214,138" fill="none" stroke="#a9cdf4" stroke-width="1.4" opacity="0.35" stroke-linecap="round"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "varistor.svg"), "".join(d), P.DEFS + DEFS)
