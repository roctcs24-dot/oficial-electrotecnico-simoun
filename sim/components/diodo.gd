class_name SimDiodo
extends SimComponente
## Diodo de ánodo A a cátodo K. Conduce cuando el ánodo supera al cátodo en su caída vf, y
## entonces la caída se mantiene; en inversa no deja pasar corriente. El modelo es por tramos:
## la simulación vuelve a resolver hasta que cada diodo está en el tramo que le corresponde.
## Se daña con demasiada corriente o demasiada tensión inversa, y queda en corto o abierto.

const R_AVERIA_CORTO := 0.1
const I_ACTIVA := 1e-9


func tipo() -> String:
	return "diodo"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vf": 0.7, "r_on": 0.05, "r_off": 1e8, "i_max": 1.0, "v_inversa": 400.0, "falla": "corto"}


func _estado_inicial() -> Dictionary:
	return {"conduce": false, "conduce_prueba": false, "quemado": false}


func estampar(e: SimEstampa) -> void:
	if estado["quemado"]:
		if params["falla"] == "corto":
			e.impedancia(n("A"), n("K"), R_AVERIA_CORTO)
		return
	# Con el óhmetro vale el estado que ajusta la corriente de prueba; si no, el de la red.
	var conduce: bool = estado["conduce_prueba"] if e.dc and not e.continua else estado["conduce"]
	if conduce:
		e.caida(n("A"), n("K"), params["vf"], params["r_on"])
	else:
		e.impedancia(n("A"), n("K"), params["r_off"])


## Corriente de ánodo a cátodo con una tensión v entre ellos.
func _corriente(v: float, conduce: bool) -> float:
	if conduce:
		return (v - float(params["vf"])) / float(params["r_on"])
	return v / float(params["r_off"])


func corriente(sol: SimSolver.Solucion) -> float:
	if estado["quemado"]:
		return tension_dc(sol, "A", "K") / R_AVERIA_CORTO if params["falla"] == "corto" else 0.0
	return _corriente(tension_dc(sol, "A", "K"), estado["conduce"])


## Decide el tramo: conduce si la tensión supera la caída; deja de conducir si la corriente
## se invertiría.
func _tramo(v: float, conduce: bool) -> bool:
	if conduce:
		return _corriente(v, true) > -I_ACTIVA
	return v > float(params["vf"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null or estado["quemado"]:
		return false
	var nuevo := _tramo(tension_dc(sol, "A", "K"), estado["conduce"])
	if nuevo == estado["conduce"]:
		return false
	estado["conduce"] = nuevo
	return true


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	if estado["quemado"]:
		return false
	var v: float = sol.entre(n("A"), n("K")).re
	var nuevo := _tramo(v, estado["conduce_prueba"])
	if nuevo == estado["conduce_prueba"]:
		return false
	estado["conduce_prueba"] = nuevo
	return true


func terminar_prueba() -> void:
	estado["conduce_prueba"] = false


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"] or sol.dc == null:
		return
	var v := tension_dc(sol, "A", "K")
	var i := corriente(sol)
	if i > float(params["i_max"]) or -v > float(params["v_inversa"]):
		estado["quemado"] = true
		estado["conduce"] = false
		avisar(tipo() + "_quemado", {"corriente_a": i, "tension_v": v})
