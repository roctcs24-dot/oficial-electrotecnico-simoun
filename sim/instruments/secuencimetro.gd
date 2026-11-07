class_name SimSecuencimetro
extends RefCounted
## Secuencímetro de fases: con tres puntas en L1, L2 y L3 indica si la secuencia es directa
## o inversa. Con la secuencia inversa, los motores giran al revés.

const TENSION_MINIMA := 50.0
const TOLERANCIA_GRADOS := 30.0
const DESEQUILIBRIO_MAXIMO := 1.3


## Devuelve "directa", "inversa", "falta_fase" o "sin_tension".
func medir(sim: SimSimulacion, a: String, b: String, c: String) -> String:
	var sol := sim.resolver()
	var v_ab := sol.entre(a, b)
	var v_bc := sol.entre(b, c)
	var v_ca := sol.entre(c, a)
	var presentes := 0
	var maxima := 0.0
	var minima := INF
	for v: Cx in [v_ab, v_bc, v_ca]:
		if v.modulo() >= TENSION_MINIMA:
			presentes += 1
		maxima = maxf(maxima, v.modulo())
		minima = minf(minima, v.modulo())
	if presentes == 0:
		return "sin_tension"
	# Con una punta en el neutro, una tensión es la de línea y las otras dos, la de fase.
	if presentes < 3 or maxima > minima * DESEQUILIBRIO_MAXIMO:
		return "falta_fase"
	var desfase := Cx.diferencia_angulo(v_bc.angulo(), v_ab.angulo())
	if absf(desfase + 120.0) <= TOLERANCIA_GRADOS:
		return "directa"
	if absf(desfase - 120.0) <= TOLERANCIA_GRADOS:
		return "inversa"
	return "falta_fase"
