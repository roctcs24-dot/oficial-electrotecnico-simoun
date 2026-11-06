class_name SimLampara
extends SimComponente
## Luz piloto X1-X2, de alterna o de continua. Se quema si recibe mucha más tensión que la nominal.


func tipo() -> String:
	return "lampara"


func _params_por_defecto() -> Dictionary:
	return {"v_nominal": 110.0, "r": 4000.0}


func _estado_inicial() -> Dictionary:
	return {"quemada": false, "encendida": false}


func estampar(e: SimEstampa) -> void:
	if not estado["quemada"]:
		e.impedancia(n("X1"), n("X2"), params["r"])


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemada"]:
		return
	# Una luz piloto de 24 V DC se enciende con la continua.
	var v := maxf(tension(sol, "X1", "X2"), absf(tension_dc(sol, "X1", "X2")))
	var relacion: float = v / params["v_nominal"]
	estado["encendida"] = relacion >= 0.5
	if relacion > 1.5:
		estado["quemada"] = true
		estado["encendida"] = false
		avisar("lampara_quemada")
