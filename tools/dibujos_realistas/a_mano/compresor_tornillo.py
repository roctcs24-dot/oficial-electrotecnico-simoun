"""Compresor de tornillo MYCOM de NH3 (480×320) sobre su SVG: escarcha en la succión, bridas,
válvula de succión, manómetros, protector del acoplamiento, costuras soldadas del separador y placas."""
import os
import realzar as R
from a_mano import _piezas as P

SUCCION = "M210,160 V90 H170"
DESCARGA = "M300,160 V112 H372"
d = []
a = d.append
a(P.escarcha(SUCCION, 14))
a(P.brillo_tubo(DESCARGA, 14))
a(P.brida(210, 150, 14, True))
a(P.brida(186, 90, 14))
a(P.brida(352, 112, 14))
a(P.brida(410, 38, 12, True))
# Válvula de succión con el volante hacia la izquierda
a('<rect x="204" y="114" width="12" height="12" rx="2" fill="#5a6064"/><path d="M204,120 H196" stroke="#8a9094" stroke-width="3"/>')
a('<circle cx="190" cy="120" r="7" fill="none" stroke="#2f6fb0" stroke-width="3"/><circle cx="190" cy="120" r="2" fill="#2a2e31"/>')
# Manómetros de succión y de descarga
a('<path d="M217,104 H228" stroke="#8a9094" stroke-width="3"/>' + P.manometro(236, 104, 8, 0.25))
a('<path d="M410,58 H452" stroke="#8a9094" stroke-width="3"/>' + P.manometro(460, 58, 8, 0.55, "#c0392b"))
# Costuras soldadas del separador
for y in (96, 214):
    a(f'<path d="M374,{y} H446" stroke="#000" stroke-opacity="0.35" stroke-width="2"/>')
    a(f'<path d="M374,{y + 2} H446" stroke="#fff" stroke-opacity="0.25" stroke-width="1"/>')
# Protector del acoplamiento
a('<rect x="152" y="182" width="30" height="50" rx="4" fill="#d9a400" stroke="#6b5200" stroke-width="0.8"/>')
for fila in range(6):
    for col in range(3):
        a(f'<circle cx="{159 + col * 8}" cy="{189 + fila * 7.5}" r="2" fill="#2a2000"/>')
# Placas del motor y del compresor
a(P.placa(96, 226, 50, 22, ["380 V · 50 Hz"], 4.2, "MOTOR"))
a(P.placa(186, 212, 40, 20, ["NH3 · R-717"], 4.0, "MYCOM"))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "compresor_tornillo.svg"), "".join(d), P.DEFS)
