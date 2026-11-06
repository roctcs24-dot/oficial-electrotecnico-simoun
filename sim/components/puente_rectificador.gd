class_name SimPuenteRectificador
extends SimComponente
## Puente rectificador de cuatro diodos: alterna en ~1 y ~2, continua en + y −. El simulador
## resuelve la alterna y la continua por separado, así que el puente se modela por su efecto:
## en la continua es una fuente con la tensión media rectificada (o la de pico, con el
## condensador de filtro), y en la alterna una carga con la potencia que entrega.

const R_INTERNA := 0.5
const MEDIA_SIN_FILTRO := 0.9
const PICO := 1.414


func tipo() -> String:
	return "puente_rectificador"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vf": 0.7, "i_max": 10.0, "filtro": false}


func _estado_inicial() -> Dictionary:
	return {"v_ac": 0.0, "p_w": 0.0, "quemado": false}


func v_continua() -> float:
	if estado["quemado"]:
		return 0.0
	var factor := PICO if params["filtro"] else MEDIA_SIN_FILTRO
	return maxf(float(estado["v_ac"]) * factor - 2.0 * float(params["vf"]), 0.0)


func estampar(e: SimEstampa) -> void:
	if estado["quemado"]:
		return
	e.fuente_continua(n("+"), n("-"), v_continua(), R_INTERNA)
	var v_ac: float = estado["v_ac"]
	if v_ac > 1.0 and estado["p_w"] > 0.01:
		e.impedancia(n("~1"), n("~2"), v_ac * v_ac / float(estado["p_w"]))
	else:
		e.impedancia(n("~1"), n("~2"), 1e7)


## La tensión de alterna de la entrada fija la continua: si cambia, hay que volver a resolver.
func asentar(sol: SimSolver.Solucion) -> bool:
	var v := tension(sol, "~1", "~2")
	if absf(v - float(estado["v_ac"])) <= maxf(0.01 * v, 0.05):
		return false
	estado["v_ac"] = v
	return true


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"]:
		return
	var v := tension_dc(sol, "+", "-")
	var i := (v_continua() - v) / R_INTERNA
	estado["p_w"] = maxf(v * i, 0.0)
	if i > float(params["i_max"]):
		estado["quemado"] = true
		avisar("puente_quemado", {"corriente_a": i})
