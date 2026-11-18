"""Caja de bornes del motor conectada en delta (480×400) sobre su SVG: los mismos detalles que la de
estrella (bornera_estrella.py), con el brillo en los tres puentes verticales."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano.bornera_estrella import DEFS, detalles

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "bornera_delta.svg"), detalles(True), P.DEFS + DEFS)
