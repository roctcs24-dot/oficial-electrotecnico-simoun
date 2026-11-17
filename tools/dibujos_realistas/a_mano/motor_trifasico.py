"""Motor trifásico con aspecto casi fotográfico (660×400): fundición pintada con textura, aletas con
relieve, pernos, placa de datos grabada y sombras difuminadas. Misma disposición que el dibujo actual."""
import comun as C

o = []
a = o.append
a('<defs>' + C.FILTROS + '''
<linearGradient id="cil" x1="0" y1="0" x2="0" y2="1">
 <stop offset="0" stop-color="#1d3344"/><stop offset="0.07" stop-color="#4d6f8c"/><stop offset="0.16" stop-color="#9dbad0"/>
 <stop offset="0.24" stop-color="#6a8ca7"/><stop offset="0.55" stop-color="#3a5b75"/><stop offset="0.85" stop-color="#213a4e"/><stop offset="1" stop-color="#122230"/></linearGradient>
<linearGradient id="lado" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.4"/><stop offset="0.25" stop-color="#000" stop-opacity="0"/><stop offset="0.8" stop-color="#fff" stop-opacity="0.06"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
<linearGradient id="eje" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4e5457"/><stop offset="0.2" stop-color="#cfd4d6"/><stop offset="0.36" stop-color="#ffffff"/><stop offset="0.55" stop-color="#9ea4a7"/><stop offset="1" stop-color="#3f4447"/></linearGradient>
<linearGradient id="placa" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f2f4f4"/><stop offset="0.3" stop-color="#c9cfd2"/><stop offset="0.5" stop-color="#eef1f2"/><stop offset="0.8" stop-color="#b5bcc0"/><stop offset="1" stop-color="#d4d9dc"/></linearGradient>
<linearGradient id="laton" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fbeab0"/><stop offset="0.4" stop-color="#cfaa4c"/><stop offset="1" stop-color="#6e5418"/></linearGradient>
<linearGradient id="cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a5f63"/><stop offset="0.3" stop-color="#2a2d30"/><stop offset="1" stop-color="#0a0b0c"/></linearGradient>
<radialGradient id="acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#c9ced1"/><stop offset="1" stop-color="#4e5457"/></radialGradient>
<g id="perno"><polygon points="-6.5,-3.8 0,-7.5 6.5,-3.8 6.5,3.8 0,7.5 -6.5,3.8" fill="#6f777b"/><circle r="4" fill="url(#acero)"/></g>
</defs>''')

PINTURA = "#3f6079"
# Sombra en el suelo, difuminada
a('<ellipse cx="330" cy="344" rx="290" ry="14" fill="#000" opacity="0.6" filter="url(#sombra)"/>')
a('<rect x="170" y="330" width="270" height="12" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')

# Patas
patas = []
for x0 in (164, 332):
    patas.append(f'<path d="M{x0 + 12},286 H{x0 + 92} L{x0 + 104},328 H{x0} Z" fill="{PINTURA}"/>')
    patas.append(f'<rect x="{x0 - 2}" y="326" width="108" height="16" rx="3" fill="#2f4d64"/>')
a('<g filter="url(#fundicion)"><g filter="url(#biselFuerte)">' + "".join(patas) + '</g></g>')
for x0 in (164, 332):
    a(f'<path d="M{x0 + 12},288 L{x0},328 H{x0 + 104} L{x0 + 92},288 Z" fill="url(#lado)" opacity="0.8"/>')
    for dx in (18, 86):
        a(f'<rect x="{x0 + dx - 10}" y="330" width="20" height="8" rx="4" fill="#04080b"/>')
        a(f'<g filter="url(#bisel)"><polygon points="{x0 + dx - 8},333 {x0 + dx},328 {x0 + dx + 8},333 {x0 + dx + 8},339 {x0 + dx},343 {x0 + dx - 8},339" fill="#7d868b"/></g>')

# Eje con chaveta, acero cepillado
a('<rect x="510" y="190" width="114" height="40" rx="3" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
a('<g filter="url(#cepillado)"><rect x="508" y="186" width="112" height="38" fill="url(#eje)"/></g>')
a('<path d="M620,186 L626,191 V219 L620,224 Z" fill="#7b8285"/>')
a('<rect x="550" y="186" width="56" height="9" rx="3" fill="#2a2e31"/>')
a('<g filter="url(#bisel)"><rect x="553" y="181" width="50" height="9" rx="2" fill="#9ba1a4"/></g>')

# Cubreventilador de chapa embutida, con agujeros con fondo
cubre = 'M40,142 Q40,121 58,119 L130,110 V300 L58,291 Q40,289 40,268 Z'
a(f'<g filter="url(#plastico)"><g filter="url(#biselFuerte)"><path d="{cubre}" fill="url(#cil)"/></g></g>')
a(f'<path d="{cubre}" fill="url(#lado)"/>')
for fila in range(10):
    y = 134 + fila * 16
    for col in range(5):
        x = 52 + col * 14
        a(f'<rect x="{x}" y="{y}" width="9" height="11" rx="3" fill="#03080c"/>')
        a(f'<rect x="{x + 1}" y="{y + 1}" width="7" height="3" rx="1.5" fill="#000" opacity="0.8"/>')
        a(f'<rect x="{x}" y="{y + 10}" width="9" height="1.6" rx="0.8" fill="#9dbad0" opacity="0.55"/>')

# Carcasa con aletas axiales en relieve
a('<rect x="120" y="104" width="356" height="206" rx="12" fill="#000" opacity="0.55" filter="url(#sombraCorta)"/>')
a('<g filter="url(#fundicion)">')
a('<rect x="122" y="102" width="352" height="204" rx="10" fill="url(#cil)"/>')
aletas = []
for i in range(13):
    y = 108 + i * 15.2
    aletas.append(f'<rect x="126" y="{y:.1f}" width="344" height="9" rx="4.5" fill="url(#cil)"/>')
a('<g filter="url(#biselFuerte)">' + "".join(aletas) + '</g>')
a('</g>')
for i in range(13):
    y = 108 + i * 15.2
    a(f'<rect x="126" y="{y + 9:.1f}" width="344" height="5" fill="#06121b" opacity="0.55"/>')
a('<rect x="122" y="102" width="352" height="204" rx="10" fill="url(#lado)"/>')

# Tapa del lado del accionamiento, con rodamiento y pernos
a('<g filter="url(#fundicion)"><g filter="url(#biselFuerte)"><rect x="466" y="106" width="46" height="196" rx="9" fill="url(#cil)"/>'
  '<rect x="508" y="168" width="14" height="74" rx="5" fill="url(#cil)"/></g></g>')
a('<rect x="466" y="106" width="46" height="196" rx="9" fill="url(#lado)"/>')
pernos = "".join(f'<use xlink:href="#perno" x="489" y="{y}"/>' for y in (122, 160, 248, 286))
pernos += "".join(f'<use xlink:href="#perno" x="134" y="{y}"/>' for y in (116, 292))
a(f'<g filter="url(#biselFuerte)">{pernos}</g>')

# Caja de bornes con tapa atornillada y junta
a('<path d="M244,58 H366 L370,108 H240 Z" fill="#000" opacity="0.5" filter="url(#sombraCorta)"/>')
a('<g filter="url(#fundicion)"><g filter="url(#biselFuerte)"><path d="M248,52 H362 L366,104 H244 Z" fill="url(#cil)"/>'
  '<rect x="243" y="34" width="124" height="22" rx="4" fill="url(#cil)"/></g></g>')
a('<rect x="245" y="55" width="120" height="2.5" fill="#0b1218"/>')
a(f'<g filter="url(#biselFuerte)"><use xlink:href="#perno" x="255" y="45"/><use xlink:href="#perno" x="355" y="45"/></g>')
# Prensaestopas de latón y cable
a('<path d="M206,84 C186,84 174,98 168,116" stroke="#000" stroke-opacity="0.5" stroke-width="16" fill="none" filter="url(#sombraCorta)"/>')
a('<path d="M206,82 C186,82 176,96 170,112" stroke="url(#cable)" stroke-width="14" fill="none" stroke-linecap="round"/>')
a('<path d="M206,77 C189,77 180,89 174,103" stroke="#8a9094" stroke-opacity="0.55" stroke-width="2" fill="none"/>')
a('<g filter="url(#biselFuerte)"><rect x="206" y="72" width="16" height="20" rx="2" fill="url(#laton)"/>'
  '<polygon points="222,67 236,67 243,82 236,97 222,97" fill="url(#laton)"/></g>')

# Placa de datos de aluminio remachada, con el texto grabado
a('<rect x="259" y="178" width="134" height="80" rx="2" fill="#000" opacity="0.55" filter="url(#sombraCorta)"/>')
a('<g filter="url(#cepillado)"><g filter="url(#bisel)"><rect x="257" y="175" width="132" height="78" rx="2" fill="url(#placa)"/></g></g>')
a('<rect x="257.5" y="175.5" width="131" height="77" rx="2" fill="none" stroke="#5c6366" stroke-width="1"/>')
for (x, y) in ((263, 181), (383, 181), (263, 247), (383, 247)):
    a(f'<g filter="url(#bisel)"><circle cx="{x}" cy="{y}" r="2.6" fill="#a7adb0"/></g>')
texto = [(206, "3~ MOT  IEC 60034   132M"), (215, "7,5 kW   380 V Y   15,2 A"), (224, "1460 r/min   50 Hz   cos φ 0,84"),
         (233, "IP55   Ins.cl. F   S1   IE3"), (242, "Rodam. 6308-2Z / 6208-2Z")]
for y, t in texto:
    a(f'<text x="267" y="{y}" style="font-size:6.6px;font-weight:600;fill:#2a3034;letter-spacing:0.02em">{t}</text>')
    a(f'<text x="267" y="{y + 0.6}" style="font-size:6.6px;font-weight:600;fill:#fff;opacity:0.35;letter-spacing:0.02em">{t}</text>')

# Brillo de canto superior y desgaste
a('<path d="M134,103.5 H462" stroke="#d6e6f1" stroke-opacity="0.55" stroke-width="1.4"/>')
a('<path d="M480,108 Q500,106 506,110" stroke="#d6e6f1" stroke-opacity="0.4" stroke-width="1.2" fill="none"/>')
ANCHO, ALTO = 660, 400
CUERPO = "".join(o)
