"""Diodo Zener de vidrio (400×220) sobre su SVG: patillas estañadas con su brillo, ampolla de vidrio
tintado con los dos tetones metálicos y la pastilla de silicio vistos al trasluz, los hilos entrando
en el vidrio, reflejos del vidrio arriba y abajo, extremos más gruesos del sellado, franja negra del
cátodo pintada y sombra de apoyo. El símbolo de debajo queda como está."""
import os
import realzar as R
from a_mano import _piezas as P

DEFS = '''
<linearGradient id="dz_hilo" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#7d858a"/><stop offset="0.25" stop-color="#ffffff"/><stop offset="0.5" stop-color="#b8bec2"/>
 <stop offset="0.8" stop-color="#6c7378"/><stop offset="1" stop-color="#9aa1a6"/></linearGradient>
<linearGradient id="dz_teton" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#6f777c"/><stop offset="0.3" stop-color="#f2f4f5"/><stop offset="0.6" stop-color="#a7aeb3"/><stop offset="1" stop-color="#5a6166"/></linearGradient>
<linearGradient id="dz_vidrio" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#fff" stop-opacity="0.25"/><stop offset="0.12" stop-color="#fff" stop-opacity="0.05"/>
 <stop offset="0.55" stop-color="#fff" stop-opacity="0"/><stop offset="0.85" stop-color="#ffd9a8" stop-opacity="0.35"/>
 <stop offset="1" stop-color="#5a2a08" stop-opacity="0.45"/></linearGradient>
<linearGradient id="dz_cuello_i" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6b3510" stop-opacity="0.55"/><stop offset="1" stop-color="#6b3510" stop-opacity="0"/></linearGradient>
<linearGradient id="dz_franja" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#3a3f44"/><stop offset="0.2" stop-color="#6b7278"/><stop offset="0.4" stop-color="#1c1f22"/><stop offset="1" stop-color="#0b0c0d"/></linearGradient>
'''

d = []
a = d.append
a('<ellipse cx="200" cy="121" rx="42" ry="2.4" fill="#000" opacity="0.4" filter="url(#sombraCorta)"/>')
# Patillas estañadas
for x1, x2 in ((32, 158), (242, 368)):
    a(f'<rect x="{x1}" y="98" width="{x2 - x1}" height="4" rx="2" fill="url(#dz_hilo)"/>')
# Interior visto al trasluz: hilos, tetones de los electrodos y la pastilla de silicio entre ellos
a('<rect x="156" y="98.6" width="12" height="2.8" fill="#c9cdd0" opacity="0.8"/>')
a('<rect x="166" y="93.5" width="23" height="13" rx="2" fill="url(#dz_teton)" opacity="0.92"/>')
a('<rect x="196" y="93.5" width="26" height="13" rx="2" fill="url(#dz_teton)" opacity="0.92"/>')
a('<rect x="189" y="95.5" width="7" height="9" fill="#3a3f52"/>')
a('<rect x="189.6" y="96" width="5.8" height="2.2" fill="#8f97c4" opacity="0.7"/>')
# Vidrio: cuellos del sellado más gruesos, reflejo superior fino y luz que pasa por abajo
a('<rect x="156" y="82" width="20" height="36" rx="14" fill="url(#dz_cuello_i)"/>')
a('<rect x="156" y="82" width="88" height="36" rx="14" fill="url(#dz_vidrio)"/>')
a('<path d="M168,86.2 H226" stroke="#fff" stroke-width="1.4" opacity="0.85" stroke-linecap="round"/>')
a('<path d="M172,113.5 H218" stroke="#ffe2bd" stroke-width="1.6" opacity="0.55" stroke-linecap="round"/>')
a('<ellipse cx="160" cy="100" rx="2" ry="9" fill="#fff" opacity="0.25"/>')
# Franja del cátodo pintada sobre el vidrio
a('<rect x="222" y="82.4" width="12" height="35.2" fill="url(#dz_franja)"/>')
a('<path d="M222,83 V117 M234,83 V117" stroke="#000" stroke-width="0.6" opacity="0.6"/>')
# Trazos rectos del símbolo, que el relieve automático borra (su caja no tiene alto o ancho)
a('<path d="M140,164 H180 M214,164 H254" stroke="#20242a" stroke-width="3"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "diodo_zener.svg"), "".join(d), P.DEFS + DEFS)
