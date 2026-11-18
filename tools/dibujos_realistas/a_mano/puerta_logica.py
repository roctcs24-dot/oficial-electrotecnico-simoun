"""Circuito integrado de puertas lógicas en cápsula DIP-14 vista desde arriba (400×220) sobre su
SVG: epoxi negro mate con granulado de molde, cara superior con las paredes del molde, línea de
partición, muesca y punto de la pata 1, hoyuelo del expulsor, patas estañadas con su doblez y
sombras de contacto. La cápsula se dibuja con dip() de operacional.py."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T
from a_mano import operacional as O

d = [O.dip(90, 60, 224, 90, tuple(106 + 32 * i for i in range(7)), (106, 130, 6), (296, 80, 6.5), semilla=6)]

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "puerta_logica.svg"), "".join(d), P.DEFS + T.DEFS_TO220 + O.DEFS_DIP)
