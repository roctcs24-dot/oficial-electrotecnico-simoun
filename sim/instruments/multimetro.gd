class_name SimMultimetro
extends RefCounted
## Multímetro: modos vac, vdc, ohm, continuidad, diodo, a (alterna) y ma (continua). Las medidas
## añaden su propia impedancia a la red, por eso un punto flotante no muestra una tensión falsa.
## En vdc la lectura tiene signo: negativa si la punta roja (a) está por debajo de la negra (b).
## Medir resistencia con tensión o corriente en paralelo lo daña, como en la realidad.

const R_ENTRADA := 1e7
const R_AMPERIMETRO := 0.01
const R_MILIAMPERIMETRO := 1.0
const I_PRUEBA := 0.001
const V_MAX_OHM := 3.0
const V_DESTRUYE_OHM := 250.0
const I_FUSIBLE := 10.0
const I_FUSIBLE_MA := 0.4
const OHM_MAX := 4e7
const CONTINUIDAD_MAX := 30.0
const V_MAX_DIODO := 2.0
## Resoluciones como máximo para que diodos y LEDs elijan su tramo con la corriente de prueba.
const MAX_PRUEBA := 8

var ruido := 0.003
var fusible_ok := true
var destruido := false
var _azar := RandomNumberGenerator.new()


## Devuelve {valor, unidad, fuera_de_rango, averia}.
func medir(sim: SimSimulacion, modo: String, a: String, b: String) -> Dictionary:
	if destruido:
		return _lectura(0.0, "", false, "multimetro_destruido")
	match modo:
		"vac":
			return _lectura(_voltios(sim, a, b), "V", false, "")
		"vdc":
			return _lectura(_voltios_dc(sim, a, b), "V", false, "")
		"ohm", "continuidad", "diodo":
			return _medir_ohm(sim, modo, a, b)
		"a":
			return _medir_corriente(sim, a, b)
		"ma":
			return _medir_miliamperios(sim, a, b)
	push_error("Modo de multímetro desconocido: %s" % modo)
	return _lectura(0.0, "", false, "modo_desconocido")


func cambiar_fusible() -> void:
	fusible_ok = true


func _voltios(sim: SimSimulacion, a: String, b: String) -> float:
	var sol := sim.resolver(false, func(e: SimEstampa) -> void: e.impedancia(a, b, R_ENTRADA))
	return sol.entre(a, b).modulo()


func _voltios_dc(sim: SimSimulacion, a: String, b: String) -> float:
	if not sim.con_continua():
		return 0.0
	var sol := sim.resolver_continua(func(e: SimEstampa) -> void: e.impedancia(a, b, R_ENTRADA))
	return sol.entre(a, b).re


func _medir_ohm(sim: SimSimulacion, modo: String, a: String, b: String) -> Dictionary:
	var v := maxf(_voltios(sim, a, b), absf(_voltios_dc(sim, a, b)))
	if v > V_MAX_OHM:
		var averia := "fusible_multimetro"
		if v >= V_DESTRUYE_OHM:
			destruido = true
			averia = "multimetro_destruido"
		fusible_ok = false
		sim.registrar_evento(averia, "multimetro", {"modo": modo, "tension_v": v})
		return _lectura(0.0, "Ω", false, averia)
	var sol := _resolver_prueba(sim, a, b)
	var r := sol.entre(a, b).modulo() / I_PRUEBA
	# En modo diodo muestra la caída de tensión con la corriente de prueba, hasta su límite.
	if modo == "diodo":
		var caida := r * I_PRUEBA
		return _lectura(caida, "V", caida > V_MAX_DIODO, "")
	var resultado := _lectura(r, "Ω", r > OHM_MAX, "")
	if modo == "continuidad":
		resultado["pita"] = r < CONTINUIDAD_MAX
	return resultado


## La corriente de prueba sale por a y vuelve por b. Los diodos de la red conducen o no según
## esa corriente: se resuelve hasta que todos están en su tramo.
func _resolver_prueba(sim: SimSimulacion, a: String, b: String) -> SimSolver.Solucion:
	var inyectar := func(e: SimEstampa) -> void: e.inyectar(a, b, I_PRUEBA)
	var sol := sim.resolver(true, inyectar)
	if sim.con_continua():
		for _i in MAX_PRUEBA:
			var cambio := false
			for c: SimComponente in sim.componentes.values():
				if c.ajustar_prueba(sol):
					cambio = true
			if not cambio:
				break
			sol = sim.resolver(true, inyectar)
		for c: SimComponente in sim.componentes.values():
			c.terminar_prueba()
	return sol


func _medir_corriente(sim: SimSimulacion, a: String, b: String) -> Dictionary:
	if not fusible_ok:
		return _lectura(0.0, "A", false, "fusible_multimetro")
	var sol := sim.resolver(false, func(e: SimEstampa) -> void: e.impedancia(a, b, R_AMPERIMETRO))
	var i := sol.entre(a, b).modulo() / R_AMPERIMETRO
	if i > I_FUSIBLE:
		fusible_ok = false
		sim.registrar_evento("fusible_multimetro", "multimetro", {"modo": "a", "corriente_a": i})
		return _lectura(0.0, "A", false, "fusible_multimetro")
	return _lectura(i, "A", false, "")


## Miliamperios en continua, en serie con el circuito abierto entre las puntas. La entrada de
## mA tiene su propio fusible, mucho menor: en paralelo con una fuente se funde enseguida.
func _medir_miliamperios(sim: SimSimulacion, a: String, b: String) -> Dictionary:
	if not fusible_ok:
		return _lectura(0.0, "mA", false, "fusible_multimetro")
	if not sim.con_continua():
		return _lectura(0.0, "mA", false, "")
	var sol := _resolver_cerrado(sim, func(e: SimEstampa) -> void: e.impedancia(a, b, R_MILIAMPERIMETRO))
	var i := sol.entre(a, b).re / R_MILIAMPERIMETRO
	if absf(i) > I_FUSIBLE_MA:
		fusible_ok = false
		sim.registrar_evento("fusible_multimetro", "multimetro", {"modo": "ma", "corriente_a": i})
		return _lectura(0.0, "mA", false, "fusible_multimetro")
	return _lectura(i * 1000.0, "mA", false, "")


## En serie, el multímetro cierra el circuito: un transmisor que no tenía lazo empieza a
## regular, o un relé se activa. Los componentes de continua ajustan su estado con el
## multímetro puesto, y la continua se vuelve a resolver hasta que nada cambia.
func _resolver_cerrado(sim: SimSimulacion, extra: Callable) -> SimSolver.Solucion:
	var sol := sim.resolver_continua(extra)
	for _i in MAX_PRUEBA:
		var completa := sim.resolver(false, extra)
		completa.dc = sol
		var cambio := false
		for c: SimComponente in sim.componentes.values():
			if c.usa_continua() and c.asentar(completa):
				cambio = true
		if not cambio:
			break
		sol = sim.resolver_continua(extra)
	return sol


func _lectura(valor: float, unidad: String, fuera: bool, averia: String) -> Dictionary:
	var con_ruido := valor * (1.0 + ruido * _azar.randf_range(-1.0, 1.0))
	return {"valor": con_ruido, "unidad": unidad, "fuera_de_rango": fuera, "averia": averia}
