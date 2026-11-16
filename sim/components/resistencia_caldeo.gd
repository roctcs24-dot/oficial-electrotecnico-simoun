class_name SimResistenciaCaldeo
extends SimComponente
## Resistencia de caldeo (anti-condensation heater) de un motor o de un tablero, bornes 1-2.
## Se conecta cuando el motor para, por un contacto NC del contactor, y mantiene el bobinado
## unos grados por encima del ambiente para que no condense la humedad. Tiene su aislamiento
## contra la carcasa.


func tipo() -> String:
	return "resistencia_caldeo"


func _params_por_defecto() -> Dictionary:
	return {"w": 100.0, "v": 230.0, "aislamiento_mohm": 200.0}


func _estado_inicial() -> Dictionary:
	return {"cortada": false, "aislamiento_mohm": -1.0}


func ohmios() -> float:
	return pow(float(params["v"]), 2.0) / float(params["w"])


func aislamiento() -> float:
	var propio := float(estado["aislamiento_mohm"])
	return propio if propio >= 0.0 else float(params["aislamiento_mohm"])


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("1"), SimSolver.TIERRA, maxf(aislamiento(), 0.001) * 1e6)
	if not estado["cortada"]:
		e.impedancia(n("1"), n("2"), ohmios())


func potencia(sol: SimSolver.Solucion) -> float:
	if estado["cortada"]:
		return 0.0
	return pow(tension(sol, "1", "2"), 2.0) / ohmios()
