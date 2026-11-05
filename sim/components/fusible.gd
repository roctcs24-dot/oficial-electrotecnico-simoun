class_name SimFusible
extends SimComponente
## Fusible de mando. Acumula energía I²t por encima de 1,25 × In y se funde.


func tipo() -> String:
	return "fusible"


func _params_por_defecto() -> Dictionary:
	return {"i_nominal": 2.0, "energia_fusion": 50.0}


func _estado_inicial() -> Dictionary:
	return {"fundido": false, "energia": 0.0}


func estampar(e: SimEstampa) -> void:
	if not estado["fundido"]:
		e.impedancia(n("1"), n("2"), R_CONTACTO)


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if estado["fundido"]:
		return
	var corr := tension(sol, "1", "2") / R_CONTACTO
	var veces: float = corr / params["i_nominal"]
	if veces > 1.25:
		estado["energia"] += veces * veces * dt
	else:
		estado["energia"] = maxf(0.0, estado["energia"] - dt)
	if estado["energia"] >= params["energia_fusion"]:
		estado["fundido"] = true
		avisar("fusible_fundido", {"corriente_a": corr})
