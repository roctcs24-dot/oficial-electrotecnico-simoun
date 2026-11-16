class_name SimTransistor
extends SimComponente
## Transistor bipolar NPN (bipolar junction transistor) de bornes B, C y E, como interruptor.
## La unión base-emisor es un diodo; con corriente de base, el colector conduce. Si la base da
## de sobra (β · Ib mayor que la corriente que pide la carga), satura y entre C y E quedan unos
## 0,2 V; si no, trabaja en activa: el colector lleva β · Ib, la tensión C-E sube y se calienta.
## Sin tensión, el óhmetro ve dos diodos: B→E y B→C. Averías: C-E en corto (quemado) y la unión
## base-emisor abierta.

const R_OFF := 1e8
const R_CORTO := 0.1
const I_ACTIVA := 1e-9


func tipo() -> String:
	return "transistor"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"beta": 100.0, "vbe": 0.7, "r_be": 1.0, "vce_sat": 0.2, "r_sat": 0.5, "ic_max": 0.8, "p_max": 0.6}


func _estado_inicial() -> Dictionary:
	return {"base": false, "activa": false, "ib": 0.0, "be_prueba": false, "bc_prueba": false, "quemado": false, "be_abierta": false}


func estampar(e: SimEstampa) -> void:
	if e.dc and not e.continua:
		_estampar_prueba(e)
		return
	if not estado["be_abierta"]:
		if estado["base"]:
			e.caida(n("B"), n("E"), params["vbe"], params["r_be"])
		else:
			e.impedancia(n("B"), n("E"), R_OFF)
	if estado["quemado"]:
		e.impedancia(n("C"), n("E"), R_CORTO)
	elif estado["base"] and estado["activa"]:
		e.impedancia(n("C"), n("E"), 1e6)
		if e.continua:
			e.inyectar(n("E"), n("C"), float(params["beta"]) * float(estado["ib"]))
	elif estado["base"]:
		e.caida(n("C"), n("E"), params["vce_sat"], params["r_sat"])
	else:
		e.impedancia(n("C"), n("E"), R_OFF)


## Lo que ve el óhmetro: los diodos base-emisor y base-colector.
func _estampar_prueba(e: SimEstampa) -> void:
	if not estado["be_abierta"]:
		if estado["be_prueba"]:
			e.caida(n("B"), n("E"), params["vbe"], 0.05)
		else:
			e.impedancia(n("B"), n("E"), R_OFF)
	if estado["bc_prueba"]:
		e.caida(n("B"), n("C"), params["vbe"], 0.05)
	else:
		e.impedancia(n("B"), n("C"), R_OFF)
	e.impedancia(n("C"), n("E"), R_CORTO if estado["quemado"] else R_OFF)


static func _tramo(v: float, conduce: bool, vf: float, r: float) -> bool:
	return (v - vf) / r > -I_ACTIVA if conduce else v > vf


func corriente_base(sol: SimSolver.Solucion) -> float:
	if not estado["base"] or estado["be_abierta"]:
		return 0.0
	return maxf((tension_dc(sol, "B", "E") - float(params["vbe"])) / float(params["r_be"]), 0.0)


func corriente_colector(sol: SimSolver.Solucion) -> float:
	if estado["quemado"]:
		return tension_dc(sol, "C", "E") / R_CORTO
	if not estado["base"]:
		return 0.0
	if estado["activa"]:
		return float(params["beta"]) * float(estado["ib"])
	return maxf((tension_dc(sol, "C", "E") - float(params["vce_sat"])) / float(params["r_sat"]), 0.0)


func saturado() -> bool:
	return estado["base"] and not estado["activa"] and not estado["quemado"]


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var cambio := false
	if not estado["be_abierta"]:
		var base := _tramo(tension_dc(sol, "B", "E"), estado["base"], params["vbe"], params["r_be"])
		if base != estado["base"]:
			estado["base"] = base
			estado["activa"] = false
			return true
	var ib := corriente_base(sol)
	if not estado["base"]:
		return false
	if estado["activa"]:
		if tension_dc(sol, "C", "E") < float(params["vce_sat"]):
			estado["activa"] = false
			cambio = true
		elif absf(ib - float(estado["ib"])) > maxf(0.01 * ib, 1e-7):
			estado["ib"] = ib
			cambio = true
	else:
		estado["ib"] = ib
		var ic := corriente_colector(sol)
		if ic > float(params["beta"]) * ib * 1.001:
			estado["activa"] = true
			cambio = true
	return cambio


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	var cambio := false
	if not estado["be_abierta"]:
		var be := _tramo(sol.entre(n("B"), n("E")).re, estado["be_prueba"], params["vbe"], 0.05)
		if be != estado["be_prueba"]:
			estado["be_prueba"] = be
			cambio = true
	var bc := _tramo(sol.entre(n("B"), n("C")).re, estado["bc_prueba"], params["vbe"], 0.05)
	if bc != estado["bc_prueba"]:
		estado["bc_prueba"] = bc
		cambio = true
	return cambio


func terminar_prueba() -> void:
	estado["be_prueba"] = false
	estado["bc_prueba"] = false


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"] or sol.dc == null:
		return
	var ic := corriente_colector(sol)
	var p := ic * maxf(tension_dc(sol, "C", "E"), 0.0)
	if ic > float(params["ic_max"]) or p > float(params["p_max"]):
		estado["quemado"] = true
		avisar("transistor_quemado", {"corriente_a": ic, "potencia_w": p})
