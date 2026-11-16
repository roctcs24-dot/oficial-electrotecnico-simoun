class_name SimRegulador
extends SimComponente
## Regulador lineal de tensión (linear voltage regulator) de tres patas, como un 7812: entrada IN,
## común GND y salida OUT. Da vout fijos mientras la entrada supere vout más su caída mínima;
## por debajo, la salida sigue a la entrada. Lo que sobra, (Vin − Vout) × I, se convierte en
## calor: sin disipador se calienta hasta su protección térmica (150 °C), corta la salida y vuelve
## al enfriarse (120 °C). La entrada consume la corriente de la salida más su consumo propio.
## Averías: abierto (salida 0 V) y en corto entre IN y OUT (la salida recibe toda la entrada).

const R_CORTO := 0.05
const AMBIENTE := 40.0
const T_CORTE := 150.0
const T_REARME := 120.0


func tipo() -> String:
	return "regulador"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vout": 12.0, "caida_min": 2.0, "r_out": 0.05, "iq": 0.005, "i_max": 1.5, "disipador": true,
		"rth_disipador": 5.0, "rth_sin": 50.0, "tau_s": 20.0}


func _estado_inicial() -> Dictionary:
	return {"v_in": 0.0, "i_out": 0.0, "temperatura": AMBIENTE, "corte_termico": false, "abierto": false, "corto": false}


func v_salida() -> float:
	if estado["abierto"] or estado["corte_termico"]:
		return 0.0
	return clampf(float(estado["v_in"]) - float(params["caida_min"]), 0.0, float(params["vout"]))


func estampar(e: SimEstampa) -> void:
	if estado["corto"]:
		e.impedancia(n("IN"), n("OUT"), R_CORTO)
		return
	var v_in := float(estado["v_in"])
	var consumo := float(estado["i_out"]) + float(params["iq"])
	e.impedancia(n("IN"), n("GND"), v_in / consumo if v_in > 0.5 else 1e6)
	if not estado["abierto"]:
		e.fuente_continua(n("OUT"), n("GND"), v_salida(), params["r_out"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null or estado["corto"]:
		return false
	var v_in := maxf(tension_dc(sol, "IN", "GND"), 0.0)
	var i_out := 0.0
	if not estado["abierto"]:
		i_out = maxf((v_salida() - tension_dc(sol, "OUT", "GND")) / float(params["r_out"]), 0.0)
	var cambio := absf(v_in - float(estado["v_in"])) > maxf(0.002 * v_in, 0.01) or absf(i_out - float(estado["i_out"])) > maxf(0.01 * i_out, 1e-4)
	estado["v_in"] = v_in
	estado["i_out"] = i_out
	return cambio


func potencia(_sol: SimSolver.Solucion = null) -> float:
	if estado["corto"] or estado["abierto"]:
		return 0.0
	return maxf(float(estado["v_in"]) - v_salida(), 0.0) * float(estado["i_out"])


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if estado["corto"]:
		return
	var rth := float(params["rth_disipador"]) if params["disipador"] else float(params["rth_sin"])
	var final := AMBIENTE + potencia(sol) * rth
	var t := float(estado["temperatura"])
	estado["temperatura"] = final + (t - final) * exp(-dt / float(params["tau_s"]))
	if not estado["corte_termico"] and estado["temperatura"] >= T_CORTE:
		estado["corte_termico"] = true
		avisar("regulador_corte_termico", {"temperatura": estado["temperatura"]})
	elif estado["corte_termico"] and estado["temperatura"] <= T_REARME:
		estado["corte_termico"] = false
