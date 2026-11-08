class_name SimGuardamotor
extends SimComponente
## Guardamotor (motor protection circuit breaker): disparo térmico ajustable,
## magnético instantáneo, contacto auxiliar 13-14 y contacto de señal de disparo 97-98, que
## solo cierra cuando ha disparado (bloque lateral tipo GVAD).

const POLOS := [["1", "2"], ["3", "4"], ["5", "6"]]


func tipo() -> String:
	return "guardamotor"


func _params_por_defecto() -> Dictionary:
	return {"ajuste_a": 16.0, "magnetico_veces": 13.0}


func _estado_inicial() -> Dictionary:
	return {"encendido": false, "disparado": false, "memoria": [0.0, 0.0, 0.0]}


func cerrado() -> bool:
	return estado["encendido"] and not estado["disparado"]


## Girar la perilla. Tras un disparo primero hay que llevarlo a apagado.
func accionar(encender: bool) -> void:
	if not encender:
		estado["encendido"] = false
		estado["disparado"] = false
	elif not estado["disparado"]:
		estado["encendido"] = true


func estampar(e: SimEstampa) -> void:
	if cerrado():
		for polo in POLOS:
			e.impedancia(n(polo[0]), n(polo[1]), R_CONTACTO)
		e.enlace(n("13"), n("14"))
	if estado["disparado"]:
		e.enlace(n("97"), n("98"))


func corriente(sol: SimSolver.Solucion, polo: int) -> float:
	if not cerrado():
		return 0.0
	return sol.entre(n(POLOS[polo][0]), n(POLOS[polo][1])).modulo() / R_CONTACTO


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var ajuste: float = params["ajuste_a"]
	var memoria: Array = estado["memoria"]
	for i in 3:
		var corr := corriente(sol, i)
		if cerrado() and corr > ajuste * params["magnetico_veces"]:
			_disparar("disparo_magnetico", corr)
		memoria[i] = SimTermico.actualizar(memoria[i], corriente(sol, i), ajuste, dt)
		if cerrado() and memoria[i] >= SimTermico.UMBRAL:
			_disparar("disparo_termico", corr)


func _disparar(evento: String, corr: float) -> void:
	estado["disparado"] = true
	avisar(evento, {"corriente_a": corr})
