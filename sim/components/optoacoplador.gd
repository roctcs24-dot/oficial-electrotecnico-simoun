class_name SimOptoacoplador
extends SimComponente
## Optoacoplador (optocoupler) de cuatro patas, como un PC817: LED de entrada entre 1 (ánodo) y
## 2 (cátodo) y fototransistor de salida entre 4 (colector) y 3 (emisor). La luz del LED hace
## conducir la salida: pasa la señal sin unir eléctricamente los dos lados, que quedan aislados
## miles de voltios. Con 1 mA en el LED, la salida satura. Averías: LED abierto (quemado),
## salida en corto y salida abierta.

const R_OFF := 1e8
const R_CORTO := 0.5
const I_ACTIVA := 1e-9
const R_AISLAMIENTO := 1e13


func tipo() -> String:
	return "optoacoplador"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vf": 1.2, "r_led": 10.0, "i_led_max": 0.06, "i_min": 0.001, "vce_sat": 0.2, "r_sat": 20.0}


func _estado_inicial() -> Dictionary:
	return {"led": false, "led_prueba": false, "salida": false, "quemado": false, "salida_corto": false, "salida_abierta": false}


func estampar(e: SimEstampa) -> void:
	var prueba: bool = e.dc and not e.continua
	e.impedancia(n("2"), n("3"), R_AISLAMIENTO)
	if not estado["quemado"]:
		if estado["led_prueba" if prueba else "led"]:
			e.caida(n("1"), n("2"), params["vf"], params["r_led"])
		else:
			e.impedancia(n("1"), n("2"), R_OFF)
	if estado["salida_corto"]:
		e.impedancia(n("4"), n("3"), R_CORTO)
	elif estado["salida"] and not estado["salida_abierta"] and not prueba:
		e.caida(n("4"), n("3"), params["vce_sat"], params["r_sat"])
	else:
		e.impedancia(n("4"), n("3"), R_OFF)


func _tramo(v: float, conduce: bool) -> bool:
	if conduce:
		return (v - float(params["vf"])) / float(params["r_led"]) > -I_ACTIVA
	return v > float(params["vf"])


func corriente_led(sol: SimSolver.Solucion) -> float:
	if estado["quemado"] or not estado["led"]:
		return 0.0
	return maxf((tension_dc(sol, "1", "2") - float(params["vf"])) / float(params["r_led"]), 0.0)


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null or estado["quemado"]:
		return false
	var led := _tramo(tension_dc(sol, "1", "2"), estado["led"])
	if led != estado["led"]:
		estado["led"] = led
		return true
	var salida := corriente_led(sol) >= float(params["i_min"])
	if salida != estado["salida"]:
		estado["salida"] = salida
		return true
	return false


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	if estado["quemado"]:
		return false
	var nuevo := _tramo(sol.entre(n("1"), n("2")).re, estado["led_prueba"])
	if nuevo == estado["led_prueba"]:
		return false
	estado["led_prueba"] = nuevo
	return true


func terminar_prueba() -> void:
	estado["led_prueba"] = false


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"] or sol.dc == null:
		return
	var i := corriente_led(sol)
	if i > float(params["i_led_max"]):
		estado["quemado"] = true
		estado["led"] = false
		estado["salida"] = false
		avisar("optoacoplador_quemado", {"corriente_a": i})
