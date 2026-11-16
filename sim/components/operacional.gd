class_name SimOperacional
extends SimComponente
## Amplificador operacional (operational amplifier) usado como comparador, con la numeración de
## un 741: 2 entrada inversora (−), 3 no inversora (+), 4 alimentación negativa o 0 V, 6 salida
## y 7 alimentación positiva. Sin realimentación, la salida va al tope alto (unos 1,5 V por debajo
## de la alimentación) cuando la entrada + supera a la −, y al tope bajo en caso contrario. Las
## entradas casi no consumen. Avería: dañado, con la salida pegada abajo.

const R_ENTRADA := 1e9


func tipo() -> String:
	return "operacional"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"caida_alta": 1.5, "caida_baja": 0.0, "r_out": 50.0, "r_alimentacion": 6000.0}


func _estado_inicial() -> Dictionary:
	return {"alta": false, "v_alim": 0.0, "danado": false}


func v_salida() -> float:
	var v := float(estado["v_alim"])
	if v < 3.0 or estado["danado"]:
		return 0.0
	return maxf(v - float(params["caida_alta"]), 0.0) if estado["alta"] else float(params["caida_baja"])


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("3"), n("4"), R_ENTRADA)
	e.impedancia(n("2"), n("4"), R_ENTRADA)
	e.impedancia(n("7"), n("4"), params["r_alimentacion"])
	e.fuente_continua(n("6"), n("4"), v_salida(), params["r_out"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var v_alim := tension_dc(sol, "7", "4")
	var alta := tension_dc(sol, "3", "2") > 0.0
	var cambio: bool = alta != estado["alta"] or absf(v_alim - float(estado["v_alim"])) > 0.01
	estado["alta"] = alta
	estado["v_alim"] = v_alim
	return cambio
