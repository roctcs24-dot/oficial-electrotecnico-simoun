class_name SimBarras
extends SimComponente
## Barras del cuadro: tres bornes L1, L2 y L3 donde se unen generadores y salidas. No
## añaden nada a la red; dan un punto con nombre para cablear y medir.


func tipo() -> String:
	return "barras"
