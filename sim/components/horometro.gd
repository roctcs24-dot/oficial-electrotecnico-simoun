class_name SimHorometro
extends SimComponente
## Horómetro A1-A2 (hour meter): cuenta las horas que está alimentado, en paralelo con la bobina
## del contactor de la bomba. Es de motor síncrono: cuenta al ritmo de la frecuencia de la red. Uno
## de 60 Hz montado en la red de 50 Hz del buque atrasa una sexta parte, como algunos de a bordo.


func tipo() -> String:
	return "horometro"


func _params_por_defecto() -> Dictionary:
	return {"v_nominal": 230.0, "hz_nominal": SimRed.F_HZ, "r": 20000.0}


func _estado_inicial() -> Dictionary:
	return {"horas": 0.0, "contando": false}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("A1"), n("A2"), params["r"])


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	estado["contando"] = tension(sol, "A1", "A2") >= 0.8 * float(params["v_nominal"])
	if estado["contando"]:
		estado["horas"] += dt / 3600.0 * SimRed.F_HZ / float(params["hz_nominal"])
