class_name SimBornera
extends SimComponente
## Bornera (terminal block) de n bornes de paso. Cada borne une su lado A, el del tablero, con su
## lado B, el del campo. Un borne flojo tiene la resistencia r_flojo_ohm: con corriente se
## calienta y cae tensión en él. Uno suelto no conduce.


func tipo() -> String:
	return "bornera"


func _params_por_defecto() -> Dictionary:
	return {"bornes": 3, "r_flojo_ohm": 0.05}


func _estado_inicial() -> Dictionary:
	return {"flojos": [], "sueltos": []}


func _r(borne: String) -> float:
	return float(params["r_flojo_ohm"]) if borne in estado["flojos"] else R_CONTACTO


func estampar(e: SimEstampa) -> void:
	for i in int(params["bornes"]):
		var b := str(i + 1)
		if not b in estado["sueltos"]:
			e.impedancia(n(b + "A"), n(b + "B"), _r(b))


## Calor en un borne, en vatios.
func calor_w(sol: SimSolver.Solucion, borne: String) -> float:
	if borne in estado["sueltos"]:
		return 0.0
	return pow(tension(sol, borne + "A", borne + "B"), 2.0) / _r(borne)
