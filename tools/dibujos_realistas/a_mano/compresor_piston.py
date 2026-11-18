"""Compresor de pistón Vilter de NH3 (480×320) sobre su SVG: escarcha en la succión, bridas,
válvula de succión, manómetros de succión, descarga y aceite, protector del acoplamiento y placas
del motor y del compresor (datos de la ficha)."""
import os
import realzar as R
from a_mano import _piezas as P

SUCCION = "M350,150 H404 V110 H470"
DESCARGA = "M204,66 H440 V20"
d = []
a = d.append
a(P.escarcha(SUCCION, 14))
a(P.brillo_tubo(DESCARGA, 12))
a(P.brida(378, 66, 12))
a(P.brida(440, 40, 12, True))
a(P.brida(372, 150, 14))
a(P.brida(404, 128, 14, True))
a(P.valvula(388, 150, 8, "#2f6fb0"))
# Manómetros: succión (verde en vacío ligero), descarga y aceite
a('<path d="M404,132 H416" stroke="#8a9094" stroke-width="3"/>' + P.manometro(424, 132, 8, 0.25))
a('<path d="M440,58 H452" stroke="#8a9094" stroke-width="3"/>' + P.manometro(460, 58, 8, 0.55, "#c0392b"))
a('<path d="M418,192 V184" stroke="#8a9094" stroke-width="3"/>' + P.manometro(418, 176, 7, 0.45))
# Protector del acoplamiento, chapa perforada amarilla
a('<rect x="152" y="190" width="30" height="50" rx="4" fill="#d9a400" stroke="#6b5200" stroke-width="0.8"/>')
for fila in range(6):
    for col in range(3):
        a(f'<circle cx="{159 + col * 8}" cy="{197 + fila * 7.5}" r="2" fill="#2a2000"/>')
# Placas del motor y del compresor
a(P.placa(96, 226, 50, 24, ["75 kW · 380 V Δ · 138 A", "50 Hz"], 4.2, "WEG"))
a(P.placa(258, 236, 52, 22, ["VMC 450 XL · NH3"], 4.2, "VILTER"))

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "compresor_piston.svg"), "".join(d), P.DEFS)
