class_name SimTiristor
extends SimComponente
## Tiristor (thyristor, SCR) de bornes A, K y G, en continua. Bloquea de ánodo a cátodo hasta
## que una corriente de puerta de G a K lo dispara; después sigue conduciendo aunque se quite la
## puerta, mientras la corriente de ánodo no baje de la de mantenimiento. Se apaga cortando esa
## corriente. La puerta es un diodo G→K. Averías: A-K en corto y puerta abierta.

const R_OFF := 1e8
const R_CORTO := 0.05
const I_ACTIVA := 1e-9


func tipo() -> String:
	return "tiristor"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vt": 1.0, "r_on": 0.05, "vgt": 0.7, "r_puerta": 30.0, "igt": 0.01, "ih": 0.02, "i_max": 25.0}


func _estado_inicial() -> Dictionary:
	return {"disparado": false, "puerta": false, "puerta_prueba": false, "quemado": false, "puerta_abierta": false}


func estampar(e: SimEstampa) -> void:
	var prueba: bool = e.dc and not e.continua
	if not estado["puerta_abierta"]:
		if estado["puerta_prueba" if prueba else "puerta"]:
			e.caida(n("G"), n("K"), params["vgt"], params["r_puerta"])
		else:
			e.impedancia(n("G"), n("K"), R_OFF)
	if estado["quemado"]:
		e.impedancia(n("A"), n("K"), R_CORTO)
	elif estado["disparado"] and not prueba:
		e.caida(n("A"), n("K"), params["vt"], params["r_on"])
	else:
		e.impedancia(n("A"), n("K"), R_OFF)


func _tramo_puerta(v: float, conduce: bool) -> bool:
	if conduce:
		return (v - float(params["vgt"])) / float(params["r_puerta"]) > -I_ACTIVA
	return v > float(params["vgt"])


func corriente_puerta(sol: SimSolver.Solucion) -> float:
	if not estado["puerta"] or estado["puerta_abierta"]:
		return 0.0
	return maxf((tension_dc(sol, "G", "K") - float(params["vgt"])) / float(params["r_puerta"]), 0.0)


func corriente_anodo(sol: SimSolver.Solucion) -> float:
	if estado["quemado"]:
		return tension_dc(sol, "A", "K") / R_CORTO
	if not estado["disparado"]:
		return 0.0
	return (tension_dc(sol, "A", "K") - float(params["vt"])) / float(params["r_on"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null or estado["quemado"]:
		return false
	if not estado["puerta_abierta"]:
		var puerta := _tramo_puerta(tension_dc(sol, "G", "K"), estado["puerta"])
		if puerta != estado["puerta"]:
			estado["puerta"] = puerta
			return true
	var ig := corriente_puerta(sol)
	if not estado["disparado"]:
		if ig >= float(params["igt"]) and tension_dc(sol, "A", "K") > float(params["vt"]):
			estado["disparado"] = true
			return true
		return false
	if corriente_anodo(sol) < float(params["ih"]) and ig < float(params["igt"]):
		estado["disparado"] = false
		return true
	return false


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	if estado["puerta_abierta"]:
		return false
	var nuevo := _tramo_puerta(sol.entre(n("G"), n("K")).re, estado["puerta_prueba"])
	if nuevo == estado["puerta_prueba"]:
		return false
	estado["puerta_prueba"] = nuevo
	return true


func terminar_prueba() -> void:
	estado["puerta_prueba"] = false


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"] or sol.dc == null:
		return
	var i := corriente_anodo(sol)
	if i > float(params["i_max"]):
		estado["quemado"] = true
		estado["disparado"] = false
		avisar("tiristor_quemado", {"corriente_a": i})
