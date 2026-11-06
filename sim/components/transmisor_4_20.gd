class_name SimTransmisor420
extends SimComponente
## Transmisor de dos hilos, + y −: regula la corriente del lazo entre 4 y 20 mA según el valor
## medido dentro de su escala. Necesita al menos v_min entre sus bornes; con menos, la corriente
## se queda corta. Con la polaridad invertida no deja pasar corriente.
## El valor sale de params "valor" o, con "origen", de un proceso como la planta de frío.
## "averia": "abierto" (0 mA), "bajo" (3,6 mA, aviso de fallo) o "alto" (21 mA).

const R_PARALELO := 1e6
const I_MIN := 0.0038
const I_MAX := 0.0205
const CORRIENTES_AVERIA := {"bajo": 0.0036, "alto": 0.021}


func tipo() -> String:
	return "transmisor_4_20"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"min": 0.0, "max": 10.0, "unidad": "bar", "valor": 0.0, "origen": {}, "v_min": 10.0, "averia": ""}


func _estado_inicial() -> Dictionary:
	# regula, falta_tension o invertido.
	return {"modo": "regula"}


func valor() -> float:
	var origen: Dictionary = params["origen"]
	return lectura_proceso(origen) if not origen.is_empty() else float(params["valor"])


## Corriente que pide el transmisor, en amperios.
func corriente_objetivo() -> float:
	var averia: String = params["averia"]
	if CORRIENTES_AVERIA.has(averia):
		return CORRIENTES_AVERIA[averia]
	var fraccion := (valor() - float(params["min"])) / (float(params["max"]) - float(params["min"]))
	return clampf(0.004 + 0.016 * fraccion, I_MIN, I_MAX)


func estampar(e: SimEstampa) -> void:
	if params["averia"] == "abierto":
		return
	e.impedancia(n("+"), n("-"), R_PARALELO)
	if not e.continua:
		return
	match estado["modo"]:
		"regula":
			# Absorbe la corriente por + y la devuelve por −.
			e.inyectar(n("-"), n("+"), corriente_objetivo())
		"falta_tension":
			e.impedancia(n("+"), n("-"), float(params["v_min"]) / corriente_objetivo())


func corriente(sol: SimSolver.Solucion) -> float:
	if params["averia"] == "abierto" or estado["modo"] == "invertido":
		return 0.0
	var v := tension_dc(sol, "+", "-")
	if estado["modo"] == "regula":
		return corriente_objetivo() + v / R_PARALELO
	return v / (float(params["v_min"]) / corriente_objetivo()) + v / R_PARALELO


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var v := tension_dc(sol, "+", "-")
	var modo: String = estado["modo"]
	# Regulando, una tensión negativa puede ser solo falta de tensión del lazo: la polaridad
	# se decide con el transmisor sin forzar la corriente.
	match modo:
		"regula":
			if v < float(params["v_min"]) - 0.05:
				modo = "falta_tension"
		"falta_tension":
			if v < 0.0:
				modo = "invertido"
			elif v >= float(params["v_min"]):
				modo = "regula"
		"invertido":
			if v > 0.5:
				modo = "falta_tension"
	if modo == estado["modo"]:
		return false
	estado["modo"] = modo
	return true
