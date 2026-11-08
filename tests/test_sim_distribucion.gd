extends RefCounted
## Interruptor automático magnetotérmico en un circuito de 110 V entre dos fases.

const A := preload("res://tests/ayuda_sim.gd")


func _circuito(ohm: float, curva := "C", in_a := 10.0) -> SimSimulacion:
	var sim := SimSimulacion.desde_dict({
		"componentes": [
			{"id": "B", "tipo": "fuente_trifasica", "params": {"v_linea": 110}},
			{"id": "F1", "tipo": "interruptor_automatico", "params": {"in_a": in_a, "curva": curva, "polos": 2}},
			{"id": "R", "tipo": "resistencia", "params": {"ohm": ohm}},
		],
		"cables": [["B.L1", "F1.1"], ["B.L2", "F1.3"], ["F1.2", "R.A"], ["F1.4", "R.B"]],
	})
	(sim.componente("F1") as SimInterruptorAutomatico).accionar(true)
	sim.avanzar_tiempo(0.1)
	return sim


func _disparo(sim: SimSimulacion, limite_s: float) -> float:
	var f1: SimInterruptorAutomatico = sim.componente("F1")
	var t := 0.0
	while t < limite_s and not f1.estado["disparado"]:
		sim.avanzar_tiempo(1.0)
		t += 1.0
	return t if f1.estado["disparado"] else INF


func test_carga_normal_no_dispara() -> String:
	var sim := _circuito(110.0 / 9.0)
	var f1: SimInterruptorAutomatico = sim.componente("F1")
	var i := f1.corriente(sim.solucion, 0)
	return A.primero([
		A.cerca(i, 9.0, 0.3, "un C10 con 9 A"),
		A.cierto(is_inf(_disparo(sim, 600.0)), "no dispara en diez minutos"),
	])


func test_sobrecarga_dispara_por_termico() -> String:
	var t := _disparo(_circuito(110.0 / 20.0), 3600.0)
	var t3 := _disparo(_circuito(110.0 / 30.0), 3600.0)
	return A.primero([
		A.cierto(t > 5.0 and t < 600.0, "al doble de In dispara en segundos o minutos: %s s" % t),
		A.cierto(t3 < t, "con más sobrecarga, antes: %s s frente a %s s" % [t3, t]),
	])


func test_cortocircuito_dispara_por_magnetico_segun_la_curva() -> String:
	# 60 A son 6 × In: la curva B dispara al instante; la C y la D, no.
	var b := _circuito(110.0 / 60.0, "B")
	var c := _circuito(110.0 / 60.0, "C")
	var d := _circuito(110.0 / 200.0, "D")
	var corto := _circuito(0.05, "C")
	return A.primero([
		A.cierto(b.componente("F1").estado["disparado"], "B10 con 60 A: magnético al instante"),
		A.cierto(not c.componente("F1").estado["disparado"], "C10 con 60 A: aún no, irá por el térmico"),
		A.cierto(d.componente("F1").estado["disparado"], "D10 con 200 A: magnético"),
		A.cierto(corto.componente("F1").estado["disparado"], "un corto franco abre al instante"),
		A.cierto(c.eventos.is_empty() or c.eventos[-1]["tipo"] != "disparo_magnetico", "sin evento magnético en el C10"),
	])
