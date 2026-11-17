"""Contactor con aspecto casi fotográfico (360×500), con la misma disposición que el dibujo actual."""
import comun as C

o = []
a = o.append
a('<defs>' + C.FILTROS + '''
<linearGradient id="carril" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#5f6568"/><stop offset="0.05" stop-color="#eef0f0"/><stop offset="0.1" stop-color="#9aa0a3"/>
 <stop offset="0.5" stop-color="#c9cdce"/><stop offset="0.9" stop-color="#9ea4a6"/><stop offset="0.95" stop-color="#e4e7e7"/><stop offset="1" stop-color="#5c6265"/></linearGradient>
<linearGradient id="cuerpo" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#2a2d31"/><stop offset="0.05" stop-color="#5a5f64"/><stop offset="0.12" stop-color="#4c5156"/>
 <stop offset="0.5" stop-color="#54595e"/><stop offset="0.9" stop-color="#464b50"/><stop offset="0.96" stop-color="#5e6368"/><stop offset="1" stop-color="#222528"/></linearGradient>
<linearGradient id="escalon" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#70757a"/><stop offset="0.15" stop-color="#5a5f64"/><stop offset="1" stop-color="#43484d"/></linearGradient>
<linearGradient id="escalonInf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4d5257"/><stop offset="1" stop-color="#33373b"/></linearGradient>
<linearGradient id="tapa" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#46494e"/><stop offset="0.1" stop-color="#2d3034"/><stop offset="0.6" stop-color="#1c1e21"/><stop offset="1" stop-color="#111214"/></linearGradient>
<linearGradient id="banda" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6f7f7"/><stop offset="0.5" stop-color="#e2e5e5"/><stop offset="1" stop-color="#b6bbbd"/></linearGradient>
<linearGradient id="laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f5e2a4"/><stop offset="0.4" stop-color="#c4a24f"/><stop offset="1" stop-color="#6b5520"/></linearGradient>
<radialGradient id="acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#d7dbdd"/><stop offset="0.7" stop-color="#8d9396"/><stop offset="1" stop-color="#4c5255"/></radialGradient>
<radialGradient id="hueco" cx="0.5" cy="0.38" r="0.62"><stop offset="0.5" stop-color="#020203"/><stop offset="0.85" stop-color="#151719"/><stop offset="1" stop-color="#303336"/></radialGradient>
<g id="tornillo">
 <circle r="9.6" fill="url(#acero)"/>
 <path d="M-5.6,0 H5.6 M0,-5.6 V5.6" stroke="#2a2e31" stroke-width="2.8" stroke-linecap="round"/>
 <path d="M-3.4,-3.4 L3.4,3.4 M-3.4,3.4 L3.4,-3.4" stroke="#4d5356" stroke-width="1"/>
</g>
</defs>''')

# Carril DIN de acero cepillado con ranuras
a('<rect x="0" y="172" width="360" height="178" fill="#000" opacity="0.45" filter="url(#sombraCorta)"/>')
a('<g filter="url(#cepillado)"><g filter="url(#bisel)"><rect x="0" y="176" width="360" height="168" fill="url(#carril)"/></g></g>')
for x in (25, 335):
    a(f'<rect x="{x - 15}" y="244" width="30" height="32" rx="15" fill="#0c0e10"/>')
    a(f'<rect x="{x - 14}" y="247" width="28" height="8" rx="4" fill="#000" opacity="0.8"/>')
    a(f'<rect x="{x - 12}" y="271" width="24" height="3" rx="1.5" fill="#f1f3f3" opacity="0.6"/>')

# Sombra difuminada del aparato
a('<path d="M84,34 H302 L318,110 V402 L302,496 H84 L70,402 V110 Z" fill="#000" opacity="0.7" filter="url(#sombra)"/>')

# Clip y oreja de fijación
a('<g filter="url(#plastico)"><g filter="url(#biselFuerte)">'
  '<path d="M146,470 H214 V494 Q214,498 210,498 H150 Q146,498 146,494 Z" fill="#33363a"/>'
  '<path d="M62,410 H42 Q34,410 34,418 V452 Q34,460 42,460 H62 Z" fill="#3a3e42"/></g></g>')
a('<rect x="166" y="484" width="28" height="6" rx="3" fill="#040505"/>')
a('<circle cx="47" cy="435" r="6.5" fill="#040505"/>')

# Cuerpo escalonado de poliamida mate
cuerpo = 'M76,20 H284 Q290,20 291,26 L300,100 V400 L291,474 Q290,480 284,480 H76 Q70,480 69,474 L60,400 V100 L69,26 Q70,20 76,20 Z'
a('<g filter="url(#plastico)"><g filter="url(#biselFuerte)">')
a(f'<path d="{cuerpo}" fill="url(#cuerpo)"/>')
a('</g><g filter="url(#bisel)">')
a('<path d="M76,20 H284 Q290,20 291,26 L300,100 V124 H60 V100 L69,26 Q70,20 76,20 Z" fill="url(#escalon)"/>')
a('<path d="M60,376 H300 V400 L291,474 Q290,480 284,480 H76 Q70,480 69,474 L60,400 Z" fill="url(#escalonInf)"/>')
a('</g></g>')
a('<rect x="60" y="124" width="240" height="3" fill="#0e1012"/><rect x="60" y="373" width="240" height="3" fill="#0e1012"/>')
# Rejillas de la cámara apagachispas
for y in (36, 48, 60, 72, 84, 96):
    for x in (67, 283):
        a(f'<rect x="{x}" y="{y}" width="10" height="6" rx="3" fill="#0b0c0d"/>')
        a(f'<rect x="{x}" y="{y + 5}" width="10" height="1.2" fill="#b8bec2" opacity="0.4"/>')
# Barreras entre fases
bar = "".join(f'<rect x="{x}" y="{y0}" width="7" height="94" rx="3.5" fill="#44494e"/>' for y0 in (26, 380) for x in (141, 211))
a(f'<g filter="url(#biselFuerte)">{bar}</g>')

# Bornes: alojamiento, jaula de latón con la entrada del cable y tornillo
def borne(x, y, grande):
    r = 26 if grande else 16.5
    lado = 15 if grande else 10
    t = 1.2 if grande else 0.98
    s = f'<circle cx="{x}" cy="{y}" r="{r + 1.5}" fill="#141618"/><circle cx="{x}" cy="{y}" r="{r}" fill="url(#hueco)"/>'
    s += f'<g filter="url(#biselFuerte)"><rect x="{x - lado - 1}" y="{y - lado}" width="{2 * lado + 2}" height="{2 * lado}" rx="2.5" fill="url(#laton)"/></g>'
    if grande:
        s += f'<rect x="{x - 11}" y="{y + 9}" width="22" height="6" rx="1.5" fill="#030303"/>'
    s += f'<g filter="url(#biselFuerte)"><use xlink:href="#tornillo" transform="translate({x},{y}) scale({t})"/></g>'
    return s
for x in (110, 180, 250):
    for y in (80, 420):
        a(borne(x, y, True))
    for y in (165, 336):
        a(borne(x, y, False))

# Tapa frontal con sombra de contacto
a('<rect x="48" y="194" width="266" height="126" rx="17" fill="#000" opacity="0.8" filter="url(#sombra)"/>')
a('<g filter="url(#plastico)"><g filter="url(#biselFuerte)"><rect x="50" y="188" width="260" height="124" rx="16" fill="url(#tapa)"/></g></g>')
a('<g filter="url(#bisel)"><rect x="62" y="197" width="236" height="26" rx="3" fill="url(#banda)"/></g>')
for x in (70, 86, 102, 252, 268, 284):
    a(f'<rect x="{x}" y="232" width="7" height="44" rx="3.5" fill="#040505"/>')
    a(f'<rect x="{x + 6}" y="233" width="1.5" height="42" fill="#fff" opacity="0.14"/>')
# Ventana del indicador con marco biselado
a('<g filter="url(#biselFuerte)"><rect x="144" y="222" width="72" height="60" rx="8" fill="#3a3d41"/></g>')
a('<rect x="148" y="226" width="64" height="52" rx="6" fill="#020203"/>')
a('<path d="M152,229 H208" stroke="#fff" stroke-opacity="0.16" stroke-width="2"/>')
ANCHO, ALTO = 360, 500
CUERPO = "".join(o)
