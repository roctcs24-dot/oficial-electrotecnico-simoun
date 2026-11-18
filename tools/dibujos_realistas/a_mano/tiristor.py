"""Tiristor en cápsula TO-220 (400×220) sobre su SVG: lengüeta niquelada unida al ánodo con su
agujero troquelado, epoxi negro mate con granulado de molde y expulsores, serigrafía láser tenue
(datos de la ficha) y patas estañadas. La cápsula se dibuja con las piezas de mosfet.py."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T

d = [T.to220("25 A · 800 V")]

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "tiristor.svg"), "".join(d), P.DEFS + T.DEFS_TO220)
