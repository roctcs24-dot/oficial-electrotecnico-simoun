class_name SimInterruptorAutomatico
extends SimGuardamotor
## Interruptor automático magnetotérmico (miniature circuit breaker, MCB) de 1 a 3 polos,
## polos 1-2, 3-4 y 5-6. Disparo térmico de tiempo inverso según su corriente nominal
## "in_a" y disparo magnético instantáneo según su curva (IEC 60898-1):
##   B: entre 3 y 5 × In; C: entre 5 y 10 × In; D: entre 10 y 20 × In.
## El simulador dispara a mitad de la banda; el margen real depende de cada aparato.
## Contacto auxiliar 13-14 como el del guardamotor.

const UMBRALES_CURVA := {"B": 4.0, "C": 7.5, "D": 15.0}
const BANDAS_CURVA := {"B": [3.0, 5.0], "C": [5.0, 10.0], "D": [10.0, 20.0]}


func tipo() -> String:
	return "interruptor_automatico"


func _params_por_defecto() -> Dictionary:
	return {"in_a": 16.0, "curva": "C", "polos": 3, "poder_corte_ka": 6.0}


func _preparar() -> void:
	params["ajuste_a"] = float(params["in_a"])
	params["magnetico_veces"] = UMBRALES_CURVA.get(params["curva"], 7.5)


func estampar(e: SimEstampa) -> void:
	if cerrado():
		for i in int(params["polos"]):
			e.impedancia(n(POLOS[i][0]), n(POLOS[i][1]), R_CONTACTO)
		e.enlace(n("13"), n("14"))


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var memoria: Array = estado["memoria"]
	for i in int(params["polos"]):
		var corr := corriente(sol, i)
		if cerrado() and corr > float(params["ajuste_a"]) * float(params["magnetico_veces"]):
			_disparar("disparo_magnetico", corr)
		memoria[i] = SimTermico.actualizar(memoria[i], corr, float(params["ajuste_a"]), dt)
		if cerrado() and memoria[i] >= SimTermico.UMBRAL:
			_disparar("disparo_termico", corr)
