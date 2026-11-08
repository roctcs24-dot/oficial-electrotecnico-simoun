class_name SimReleDC
extends SimComponente
## Relé auxiliar de 24 V DC: bobina A1-A2 y dos contactos conmutados, común 11 con NC 12 y NA
## 14, y común 21 con NC 22 y NA 24. Cierra con el 70 % de su tensión y suelta por debajo del 30 %.
## La bobina no tiene polaridad. Con el parámetro alterna, la bobina es de alterna, como los
## relés enchufables de 110 V AC del tablero de bombas de la máquina principal.

const CONTACTOS := [["11", "12", "14"], ["21", "22", "24"]]
const CIERRA := 0.7
const SUELTA := 0.3
const QUEMA := 1.3
const QUEMA_S := 5.0

var _sobretension_s := 0.0


func tipo() -> String:
	return "rele_dc"


func usa_continua() -> bool:
	return not params.get("alterna", false)


func _params_por_defecto() -> Dictionary:
	return {"v_bobina": 24.0, "r_bobina": 640.0}


func _estado_inicial() -> Dictionary:
	return {"energizado": false, "bobina_quemada": false}


func estampar(e: SimEstampa) -> void:
	if not estado["bobina_quemada"]:
		e.impedancia(n("A1"), n("A2"), params["r_bobina"])
	for c: Array in CONTACTOS:
		e.enlace(n(c[0]), n(c[2] if estado["energizado"] else c[1]))


func _relacion(sol: SimSolver.Solucion) -> float:
	if params.get("alterna", false):
		return tension(sol, "A1", "A2") / float(params["v_bobina"])
	return absf(tension_dc(sol, "A1", "A2")) / float(params["v_bobina"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null and usa_continua():
		return false
	var energizado: bool = estado["energizado"]
	if estado["bobina_quemada"]:
		energizado = false
	elif _relacion(sol) >= CIERRA:
		energizado = true
	elif _relacion(sol) < SUELTA:
		energizado = false
	if energizado == estado["energizado"]:
		return false
	estado["energizado"] = energizado
	return true


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if estado["bobina_quemada"] or (sol.dc == null and usa_continua()):
		return
	if _relacion(sol) > QUEMA:
		_sobretension_s += dt
		if _sobretension_s >= QUEMA_S:
			estado["bobina_quemada"] = true
			avisar("bobina_quemada")
	else:
		_sobretension_s = 0.0
