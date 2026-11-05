class_name SimFuenteTrifasica
extends SimComponente
## Barras trifásicas en estrella interna. El neutro va a tierra por una resistencia
## alta porque la red del barco es aislada: la primera falla a tierra no dispara.
## El interruptor aguas arriba abre ante un cortocircuito, con retardo para que
## actúe primero la protección más cercana a la falla.

const ANGULOS := {"L1": 0.0, "L2": -120.0, "L3": 120.0}
const RETARDO_DISPARO_S := 0.2

var _sobrecorriente_s := 0.0


func tipo() -> String:
	return "fuente_trifasica"


func _params_por_defecto() -> Dictionary:
	return {"v_linea": 440.0, "f_hz": 60.0, "r": 0.005, "x": 0.02, "neutro_mohm": 1.0, "i_disparo_a": 3000.0}


func _estado_inicial() -> Dictionary:
	return {"activa": true, "disparada": false}


func con_tension() -> bool:
	return estado["activa"] and not estado["disparada"]


func rearmar() -> void:
	estado["disparada"] = false


func _v_fase() -> float:
	return params["v_linea"] / sqrt(3.0) if con_tension() else 0.0


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("N"), SimSolver.TIERRA, params["neutro_mohm"] * 1e6)
	for fase: String in ANGULOS:
		e.fuente(n(fase), n("N"), Cx.polar(_v_fase(), ANGULOS[fase]), params["r"], params["x"])


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if not con_tension():
		_sobrecorriente_s = 0.0
		return
	var z := Cx.new(params["r"], params["x"])
	var maxima := 0.0
	for fase: String in ANGULOS:
		var caida := Cx.polar(_v_fase(), ANGULOS[fase]).menos(sol.entre(n(fase), n("N")))
		maxima = maxf(maxima, caida.entre(z).modulo())
	if maxima <= params["i_disparo_a"]:
		_sobrecorriente_s = 0.0
		return
	_sobrecorriente_s += dt
	if _sobrecorriente_s >= RETARDO_DISPARO_S:
		estado["disparada"] = true
		avisar("disparo_barras", {"corriente_a": maxima})
