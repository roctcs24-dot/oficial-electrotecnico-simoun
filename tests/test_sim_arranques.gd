extends RefCounted
## Plantillas de data/circuitos: arranque directo, estrella-triángulo, cortos y mando.

const A := preload("res://tests/ayuda_sim.gd")


func _dol_en_marcha() -> SimSimulacion:
	var sim := A.circuito("arranque_directo")
	sim.componente("Q1").accionar(true)
	sim.paso()
	A.pulsar(sim, "S1")
	sim.avanzar_tiempo(10.0)
	return sim


func test_dol_arranca_y_se_enclava() -> String:
	var sim := _dol_en_marcha()
	return A.primero([
		A.cierto(sim.componente("K1").cerrado(), "K1 debe quedar enclavado al soltar S1"),
		A.cierto(sim.componente("H1").estado["encendida"], "la luz piloto debe encender"),
		A.cierto(sim.componente("M1").rpm() > 1400.0, "el motor debe llegar a su velocidad"),
	])


func test_dol_para_con_s0() -> String:
	var sim := _dol_en_marcha()
	A.pulsar(sim, "S0")
	sim.avanzar_tiempo(30.0)
	return A.primero([
		A.cierto(not sim.componente("K1").cerrado(), "K1 debe soltar"),
		A.cierto(sim.componente("M1").rpm() < 5.0, "el motor debe detenerse: %.0f rpm" % sim.componente("M1").rpm()),
	])


func test_disparo_del_termico_suelta_k1_y_rearma() -> String:
	var sim := _dol_en_marcha()
	sim.componente("M1").params["bloqueado"] = true
	sim.avanzar_tiempo(20.0)
	var solto: bool = not sim.componente("K1").cerrado()
	var f2: SimReleTermico = sim.componente("F2")
	var rearme_caliente := f2.rearmar()
	sim.componente("M1").params["bloqueado"] = false
	sim.avanzar_tiempo(600.0)
	var rearme_frio := f2.rearmar()
	sim.paso()
	A.pulsar(sim, "S1")
	sim.avanzar_tiempo(10.0)
	return A.primero([
		A.cierto(solto, "F2 debe soltar K1 por 95-96"),
		A.cierto(not rearme_caliente, "no debe rearmar en caliente"),
		A.cierto(rearme_frio, "debe rearmar en frío"),
		A.cierto(sim.componente("M1").rpm() > 1400.0, "debe volver a arrancar"),
	])


func test_baja_tension_suelta_y_no_rearranca_solo() -> String:
	var sim := _dol_en_marcha()
	sim.componente("B").estado["activa"] = false
	sim.avanzar_tiempo(1.0)
	var solto: bool = not sim.componente("K1").cerrado()
	sim.componente("B").estado["activa"] = true
	sim.avanzar_tiempo(1.0)
	return A.primero([
		A.cierto(solto, "K1 debe soltar sin tensión"),
		A.cierto(not sim.componente("K1").cerrado(), "no debe rearrancar sin pulsar S1"),
	])


func test_bobina_en_380v_se_quema() -> String:
	var sim := A.circuito("arranque_directo")
	sim.conectar("Q1.2", "K1.A1")
	sim.conectar("Q1.4", "K1.A2")
	sim.desconectar("K1.A2", "T1.X2")
	sim.desconectar("S1.14", "K1.A1")
	sim.desconectar("K1.14", "K1.A1")
	sim.desconectar("K1.A1", "H1.X1")
	sim.componente("Q1").accionar(true)
	sim.avanzar_tiempo(5.0)
	return A.cierto(sim.hubo_evento("bobina_quemada", "K1"), "una bobina de 110 V en 380 V debe quemarse")


func test_cortocircuito_entre_fases_dispara_magnetico() -> String:
	var sim := A.circuito("arranque_directo")
	sim.conectar("K1.2", "K1.4")
	sim.componente("Q1").accionar(true)
	sim.paso()
	A.pulsar(sim, "S1", 0.1)
	return A.primero([
		A.cierto(sim.hubo_evento("disparo_magnetico", "Q1"), "debe disparar el magnético"),
		A.cierto(not sim.componente("Q1").cerrado(), "Q1 debe abrir"),
		A.cierto(sim.hubo_evento("arco_contactos_soldados", "K1"), "el arco debe soldar K1"),
		A.cierto(sim.componente("K1").estado["soldado"], "K1 sigue dañado"),
	])


func test_bobina_por_su_propio_nc_vibra() -> String:
	var sim := A.circuito("arranque_directo")
	sim.desconectar("S1.14", "K1.A1")
	sim.desconectar("K1.14", "K1.A1")
	sim.desconectar("K1.A1", "H1.X1")
	sim.conectar("S0.22", "K1.21")
	sim.conectar("K1.22", "K1.A1")
	sim.componente("Q1").accionar(true)
	sim.avanzar_tiempo(2.0)
	return A.cierto(sim.hubo_evento("vibracion_mando", "K1"), "una bobina por su propio NC debe vibrar")


func test_guardamotor_exige_apagar_tras_disparo() -> String:
	var q := SimGuardamotor.new("Q1")
	q.estado["encendido"] = true
	q.estado["disparado"] = true
	q.accionar(true)
	var sigue := not q.cerrado()
	q.accionar(false)
	q.accionar(true)
	return A.primero([
		A.cierto(sigue, "no debe cerrar directamente tras un disparo"),
		A.cierto(q.cerrado(), "debe cerrar tras pasar por apagado"),
	])


func _pico_directo() -> float:
	var sim := A.circuito("arranque_directo")
	sim.componente("Q1").params["ajuste_a"] = 1000.0
	sim.componente("Q1").accionar(true)
	sim.paso()
	sim.componente("S1").estado["presionado"] = true
	sim.paso()
	return sim.componente("Q1").corriente(sim.solucion, 0)


func test_estrella_triangulo_secuencia_completa() -> String:
	var sim := A.circuito("estrella_triangulo")
	sim.componente("M1").params["carga"] = 0.5
	var q1: SimGuardamotor = sim.componente("Q1")
	q1.params["ajuste_a"] = 1000.0
	q1.accionar(true)
	sim.paso()
	sim.componente("S1").estado["presionado"] = true
	sim.paso()
	var pico_estrella := q1.corriente(sim.solucion, 0)
	var estrella_ok: bool = sim.componente("K3").cerrado() and not sim.componente("K2").cerrado()
	sim.componente("S1").estado["presionado"] = false
	var ambos := false
	var v_estrella := sim.solucion.entre("M1.U1", "M1.U2").modulo()
	for _i in 240:
		sim.paso()
		if sim.componente("K2").cerrado() and sim.componente("K3").cerrado():
			ambos = true
	var v_delta := sim.solucion.entre("M1.U1", "M1.U2").modulo()
	var pico_directo := _pico_directo()
	return A.primero([
		A.cierto(estrella_ok, "debe arrancar con K3 (estrella) y sin K2"),
		A.cerca(v_estrella, 219.4, 0.02, "devanado en estrella"),
		A.cerca(pico_estrella / pico_directo, 1.0 / 3.0, 0.15, "pico de estrella frente a directo"),
		A.cierto(not ambos, "K2 y K3 nunca deben estar cerrados a la vez"),
		A.cierto(sim.componente("K2").cerrado(), "al final debe quedar K2 (delta)"),
		A.cierto(not sim.componente("K3").cerrado(), "al final K3 debe abrir"),
		A.cerca(v_delta, 380.0, 0.02, "devanado en delta"),
		A.cierto(sim.componente("M1").rpm() > 1400.0, "debe llegar a su velocidad"),
		A.cierto(not sim.hubo_evento("vibracion_mando"), "el mando no debe vibrar"),
	])


func test_sin_enclavamiento_es_cortocircuito() -> String:
	var sim := A.circuito("estrella_triangulo")
	sim.conectar("K1.A1", "K2.A1")
	sim.conectar("K1.A1", "K3.A1")
	sim.componente("Q1").accionar(true)
	sim.paso()
	A.pulsar(sim, "S1", 0.1)
	return A.primero([
		A.cierto(sim.hubo_evento("disparo_magnetico", "Q1"), "K2 y K3 juntos deben disparar Q1"),
		A.cierto(sim.componente("K3").estado["soldado"], "el arco debe soldar K3"),
	])


func test_rendimiento_estrella_triangulo() -> String:
	var sim := A.circuito("estrella_triangulo")
	sim.componente("Q1").accionar(true)
	sim.paso()
	var inicio := Time.get_ticks_usec()
	for _i in 100:
		sim.paso()
	var ms := (Time.get_ticks_usec() - inicio) / 100000.0
	print("      paso de simulación: %.2f ms en este equipo" % ms)
	return A.cierto(ms < 25.0, "un paso tarda %.1f ms" % ms)
