"""Diésel-generador (480×340) sobre su SVG: tapas de balancines con pernos, inyectores, escape con
fuelle, filtro de aceite, varilla, volante atornillado, alternador con rejillas, cáncamos, caja de
bornes con prensaestopas, placa de datos grabada, soportes antivibratorios y cable de tierra."""
import os
import realzar as R
from a_mano import _piezas as P

d = []
a = d.append
# Tapas de balancines con sus pernos y rampa de inyectores
for i in range(6):
    x = 58 + i * 25
    a(f'<rect x="{x}" y="72" width="22" height="20" rx="4" fill="#3b5848" stroke="#1d2b24" stroke-width="0.8"/>')
    a(P.perno(x + 5, 77, 2) + P.perno(x + 17, 77, 2))
    a(f'<path d="M{x + 11},94 V108" stroke="#c9ced1" stroke-width="2"/>')
a('<path d="M60,108 H212" stroke="#aeb4b7" stroke-width="3" stroke-linecap="round"/>')
a(P.brillo_tubo("M60,108 H212", 3))
# Escape desde el turbo con su fuelle y aislamiento térmico
a('<path d="M44,80 V22" stroke="#6b4a36" stroke-width="16" stroke-linecap="round"/>')
for y in range(30, 70, 6):
    a(f'<rect x="35" y="{y}" width="18" height="3" rx="1.5" fill="#3a271c" opacity="0.7"/>')
a('<path d="M44,80 V22" stroke="url(#am_tubo)" stroke-width="16"/>')
a('<rect x="33" y="70" width="22" height="7" rx="2" fill="url(#am_bridaV)"/>')
# Filtro de aceite y varilla
a('<rect x="196" y="176" width="20" height="42" rx="5" fill="#2f5d86" stroke="#173149" stroke-width="0.8"/>')
a('<rect x="196" y="176" width="20" height="42" rx="5" fill="url(#am_brida)" opacity="0.35"/>')
a('<rect x="194" y="172" width="24" height="6" rx="2" fill="#5a6064"/>')
a('<path d="M62,236 V214" stroke="#9aa0a3" stroke-width="2"/><rect x="57" y="208" width="10" height="7" rx="3" fill="#f2c200"/>')
# Pernos del cárter y del volante
for x in range(50, 222, 20):
    a(P.perno(x, 240, 2.2))
for y in range(146, 258, 18):
    a(P.perno(246, y, 2.4))
# Alternador: rejillas del lado del acoplamiento, cáncamos y pernos de la excitatriz
a(P.rejilla(268, 136, 26, 84, 9))
for x in (282, 414):
    a(f'<circle cx="{x}" cy="114" r="6" fill="none" stroke="#2c3238" stroke-width="5"/>')
    a(f'<circle cx="{x}" cy="114" r="6" fill="none" stroke="#9aa6b0" stroke-width="2.5"/>')
for y in (146, 244):
    a(P.perno(444, y, 2.6))
# Caja de bornes: tornillos de la tapa y prensaestopas de latón en los cables
for x, y in ((304, 82), (388, 82), (304, 118), (388, 118)):
    a(P.perno(x, y, 2.4))
for x in (318, 346, 374):
    a(f'<circle cx="{x}" cy="74" r="8" fill="none" stroke="#b8963a" stroke-width="3"/>')
    a(f'<path d="M{x - 2},66 V42" stroke="#fff" stroke-opacity="0.25" stroke-width="1.5"/>')
# Placa de datos con el texto grabado (datos de la ficha)
a(P.placa(326, 186, 78, 42, ["HCI534F · 565 kVA · 452 kW", "380 V · 50 Hz · 1500 r/min", "IP23 · Ins. H · cos φ 0,8"], 4.4, "STAMFORD"))
# Soportes antivibratorios con su perno
for x in (48, 240, 432):
    a(f'<rect x="{x - 18}" y="298" width="36" height="5" rx="2" fill="#3a3e42"/>')
    a(P.perno(x, 304, 3))
# Cable de tierra verde y amarillo del alternador a la bancada
a('<path d="M424,262 C428,276 432,284 440,292" stroke="#35b552" stroke-width="5" fill="none" stroke-linecap="round"/>')
a('<path d="M424,262 C428,276 432,284 440,292" stroke="#f2c200" stroke-width="5" fill="none" stroke-dasharray="5 5" stroke-linecap="round"/>')

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "alternador.svg"), "".join(d), P.DEFS)
