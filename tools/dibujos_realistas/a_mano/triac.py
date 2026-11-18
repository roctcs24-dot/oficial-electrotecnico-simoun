"""Triac de lengüeta aislada en cápsula TO-220 (400×220) sobre su SVG: lengüeta niquelada con su
agujero, epoxi que sube sobre la base de la lengüeta (la franja oscura del dibujo), granulado de
molde, expulsores, serigrafía láser tenue (datos de la ficha) y patas estañadas. La cápsula se
dibuja con las piezas de mosfet.py."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import mosfet as T

d = [T.to220("16 A · 600 V", banda=14)]

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "triac.svg"), "".join(d), P.DEFS + T.DEFS_TO220)
