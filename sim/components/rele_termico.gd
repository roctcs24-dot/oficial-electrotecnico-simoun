class_name SimReleTermico
extends SimComponente
## Relé térmico (overload relay): polos 1-2, 3-4, 5-6, contacto NC 95-96 y NA 97-98.
## No corta la potencia: al disparar abre 95-96 para que el mando suelte el contactor.

const POLOS := [["1", "2"], ["3", "4"], ["5", "6"]]


func tipo() -> String:
	return "rele_termico"


func _params_por_defecto() -> Dictionary:
	return {"ajuste_a": 14.5}


func _estado_inicial() -> Dictionary:
	return {"disparado": false, "memoria": [0.0, 0.0, 0.0]}


## El rearme manual solo funciona si el relé ya se enfrió.
func rearmar() -> bool:
	for m in estado["memoria"]:
		if m >= SimTermico.UMBRAL * 0.8:
			return false
	estado["disparado"] = false
	return true


func estampar(e: SimEstampa) -> void:
	for polo in POLOS:
		e.impedancia(n(polo[0]), n(polo[1]), R_CONTACTO)
	if estado["disparado"]:
		e.enlace(n("97"), n("98"))
	else:
		e.enlace(n("95"), n("96"))


func corriente(sol: SimSolver.Solucion, polo: int) -> float:
	return sol.entre(n(POLOS[polo][0]), n(POLOS[polo][1])).modulo() / R_CONTACTO


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var memoria: Array = estado["memoria"]
	for i in 3:
		var corr := corriente(sol, i)
		memoria[i] = SimTermico.actualizar(memoria[i], corr, params["ajuste_a"], dt)
		if not estado["disparado"] and memoria[i] >= SimTermico.UMBRAL:
			estado["disparado"] = true
			avisar("disparo_rele_termico", {"corriente_a": corr, "polo": i})
