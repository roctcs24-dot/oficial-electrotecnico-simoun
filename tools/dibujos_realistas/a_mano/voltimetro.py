"""Voltímetro de cuadro de hierro móvil (300×330) sobre su SVG: la misma capa que el amperímetro
(tornillos del marco, cristal, subdivisiones, aguja con contrapeso, ajuste de cero, símbolos de la
esfera y bornes con terminal y cable), con la aguja del voltímetro."""
import os
import realzar as R
from a_mano import _piezas as P
from a_mano import amperimetro as AM

ANCHO, ALTO, CUERPO = R.automatico(os.path.join(R.REPO, "art", "equipos", "voltimetro.svg"), AM.capa((200, 116)), P.DEFS + AM.DEFS)
