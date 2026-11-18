"""Optoacoplador en cápsula DIP-4 vista desde arriba (400×220) sobre su SVG: epoxi negro mate con
granulado de molde, cara superior con las paredes del molde, línea de partición, muesca y punto de
la pata 1, hoyuelo del expulsor, patas estañadas con su doblez y sombras de contacto. La cápsula
se dibuja con dip() de operacional.py."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T
from a_mano import operacional as O

d = [O.dip(150, 60, 100, 90, (175, 225), (166, 130, 6), (234, 80, 5.5), semilla=4)]

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "optoacoplador.svg"), "".join(d), P.DEFS + T.DEFS_TO220 + O.DEFS_DIP)
