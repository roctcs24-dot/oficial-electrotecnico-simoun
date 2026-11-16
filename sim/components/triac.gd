class_name SimTriac
extends SimComponente
## Triac de bornes A1, A2 y G, para alterna. Conduce en los dos sentidos entre A1 y A2 mientras
## su puerta recibe corriente (de G a A1, en cualquier sentido, en continua o en alterna); en
## alterna se apaga en cada paso por cero, así que sin puerta deja de conducir enseguida. La
## simulación trabaja con valores eficaces: conduce los dos semiciclos enteros o nada. La puerta
## es una resistencia de unas decenas de ohmios hacia A1. Averías: A1-A2 en corto y puerta abierta.

const R_OFF := 1e8
const R_CORTO := 0.05


func tipo() -> String:
	return "triac"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"r_on": 0.05, "r_puerta": 60.0, "igt": 0.01, "i_max": 16.0}


func _estado_inicial() -> Dictionary:
	return {"conduce": false, "quemado": false, "puerta_abierta": false}


func estampar(e: SimEstampa) -> void:
	if not estado["puerta_abierta"]:
		e.impedancia(n("G"), n("A1"), params["r_puerta"])
	var r: float = R_CORTO if estado["quemado"] else (float(params["r_on"]) if estado["conduce"] and not (e.dc and not e.continua) else R_OFF)
	e.impedancia(n("A1"), n("A2"), r)


func corriente_puerta(sol: SimSolver.Solucion) -> float:
	if estado["puerta_abierta"]:
		return 0.0
	var i_ac := tension(sol, "G", "A1") / float(params["r_puerta"])
	var i_dc := absf(tension_dc(sol, "G", "A1")) / float(params["r_puerta"]) if sol.dc != null else 0.0
	return maxf(i_ac, i_dc)


func corriente(sol: SimSolver.Solucion) -> float:
	var r: float = R_CORTO if estado["quemado"] else (float(params["r_on"]) if estado["conduce"] else R_OFF)
	return tension(sol, "A1", "A2") / r


func asentar(sol: SimSolver.Solucion) -> bool:
	var conduce := corriente_puerta(sol) >= float(params["igt"])
	if conduce == estado["conduce"]:
		return false
	estado["conduce"] = conduce
	return true


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"]:
		return
	var i := corriente(sol)
	if i > float(params["i_max"]):
		estado["quemado"] = true
		avisar("triac_quemado", {"corriente_a": i})
