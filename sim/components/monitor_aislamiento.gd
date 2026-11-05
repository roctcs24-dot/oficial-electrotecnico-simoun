class_name SimMonitorAislamiento
extends SimComponente
## Monitor de aislamiento de una red aislada: inyecta una pequeña corriente continua entre
## la red (borne L) y la masa (PE), y mide la resistencia de toda la red contra el casco.
## El umbral de alarma es un valor típico: verificar a bordo.

const I_PRUEBA := 1e-4
const MOHM_MAX := 999.0


func tipo() -> String:
	return "monitor_aislamiento"


func _params_por_defecto() -> Dictionary:
	return {"alarma_mohm": 1.0, "periodo_s": 1.0}


func _estado_inicial() -> Dictionary:
	return {"mohm": MOHM_MAX, "alarma": false, "espera_s": 0.0}


func estampar(e: SimEstampa) -> void:
	e.enlace(n("PE"), SimSolver.TIERRA)


func medir() -> float:
	var simulacion := sim()
	if simulacion == null:
		return MOHM_MAX
	var punto := n("L")
	var sol := simulacion.resolver(true, func(e: SimEstampa) -> void: e.inyectar(punto, SimSolver.TIERRA, I_PRUEBA))
	return minf(sol.entre(punto, SimSolver.TIERRA).modulo() / I_PRUEBA / 1e6, MOHM_MAX)


func avanzar(dt: float, _sol: SimSolver.Solucion) -> void:
	estado["espera_s"] -= dt
	if estado["espera_s"] > 0.0:
		return
	estado["espera_s"] = params["periodo_s"]
	estado["mohm"] = medir()
	var alarma: bool = estado["mohm"] < params["alarma_mohm"]
	if alarma and not estado["alarma"]:
		avisar("alarma_aislamiento", {"mohm": estado["mohm"]})
	estado["alarma"] = alarma
