extends RefCounted
## Generación: arranque, estatismo, sincronización, reparto de carga, potencia inversa,
## disparo preferente, blackout, emergencia, toma de tierra y monitor de aislamiento.

const A := preload("res://tests/ayuda_sim.gd")


func _cuadro() -> SimSimulacion:
	return A.circuito("cuadro_principal")


func _gen(sim: SimSimulacion, id: String) -> SimGenerador:
	return sim.componente(id)


func _acb(sim: SimSimulacion, id: String) -> SimInterruptorGenerador:
	return sim.componente(id)


## G1 arrancado y en barras, con las dos cargas del cuadro.
func _g1_en_barras() -> SimSimulacion:
	var sim := _cuadro()
	_gen(sim, "G1").arrancar()
	sim.avanzar_tiempo(10.0)
	_acb(sim, "Q1").cerrar()
	sim.avanzar_tiempo(10.0)
	return sim


func _frecuencia_barras(sim: SimSimulacion) -> float:
	return _gen(sim, "G1").frecuencia()


## Arranca G2, lo deja un poco más rápido que las barras y espera a que el sincronoscopio
## pase por el ángulo pedido. Devuelve false si no llegó a tiempo.
func _esperar_angulo(sim: SimSimulacion, angulo: float, tolerancia: float) -> bool:
	_gen(sim, "G2").arrancar()
	sim.avanzar_tiempo(10.0)
	_gen(sim, "G2").estado["f_ref"] = _frecuencia_barras(sim) + 0.25
	sim.avanzar_tiempo(3.0)
	var sy := sim.componente("SY")
	for _i in 2000:
		sim.paso()
		if sy.estado["valido"] and absf(Cx.diferencia_angulo(sy.estado["angulo"], angulo)) <= tolerancia:
			return true
	return false


func _en_paralelo() -> SimSimulacion:
	var sim := _g1_en_barras()
	_esperar_angulo(sim, 0.0, 4.0)
	_acb(sim, "Q2").cerrar()
	sim.avanzar_tiempo(5.0)
	return sim


func test_arranque_en_vacio() -> String:
	var sim := _cuadro()
	var g := _gen(sim, "G1")
	g.arrancar()
	sim.avanzar_tiempo(10.0)
	return A.primero([
		A.cerca(g.frecuencia(), 60.0, 0.005, "frecuencia en vacío"),
		A.cerca(g.estado["v"], 440.0, 0.01, "tensión en vacío"),
		A.cierto(not sim.hubo_evento("disparo_minima_tension"), "no debe disparar nada"),
	])


func test_cierre_sobre_barra_muerta_y_estatismo() -> String:
	var sim := _g1_en_barras()
	var g := _gen(sim, "G1")
	var p: float = g.estado["p_kw"]
	# La fricción también la aporta el diésel: cuenta como carga para el gobernador.
	var friccion_kw: float = g.params["friccion_pu"] * g.params["s_kva"]
	var esperada := 60.0 - 0.04 * 60.0 * (p + friccion_kw) / 450.0
	return A.primero([
		A.cierto(_acb(sim, "Q1").cerrado(), "Q1 debe cerrar sobre barra muerta"),
		A.cierto(sim.hubo_evento("cierre_barra_muerta"), "debe registrar el cierre en barra muerta"),
		A.cerca(p, 320.0, 0.05, "potencia de las dos cargas"),
		A.cerca(g.frecuencia(), esperada, 0.003, "la frecuencia baja con la carga según el estatismo"),
		A.cerca(g.estado["v"], 440.0, 0.03, "el AVR mantiene la tensión"),
	])


func test_isocrono_mantiene_60_hz() -> String:
	var sim := _cuadro()
	var g := _gen(sim, "G1")
	g.params["modo_gobernador"] = "isocrono"
	g.arrancar()
	sim.avanzar_tiempo(10.0)
	_acb(sim, "Q1").cerrar()
	sim.avanzar_tiempo(30.0)
	return A.cerca(g.frecuencia(), 60.0, 0.002, "un gobernador isócrono vuelve a 60 Hz con carga")


func test_no_cierra_sin_tension_del_generador() -> String:
	var sim := _g1_en_barras()
	var motivo := _acb(sim, "Q2").cerrar()
	return A.primero([
		A.cierto(not motivo.is_empty(), "debe rechazar el cierre"),
		A.cierto(not _acb(sim, "Q2").cerrado(), "debe seguir abierto"),
	])


func test_sincronoscopio_indica_deslizamiento() -> String:
	var sim := _g1_en_barras()
	_gen(sim, "G2").arrancar()
	sim.avanzar_tiempo(10.0)
	_gen(sim, "G2").estado["f_ref"] = _frecuencia_barras(sim) + 0.5
	sim.avanzar_tiempo(4.0)
	var sy := sim.componente("SY")
	var esperado := _gen(sim, "G2").frecuencia() - _frecuencia_barras(sim)
	return A.primero([
		A.cierto(sy.estado["valido"], "con las dos tensiones debe medir"),
		A.cerca(sy.estado["deslizamiento_hz"], esperado, 0.05, "deslizamiento: entrante más rápido"),
		A.cierto(sy.estado["deslizamiento_hz"] > 0.0, "debe girar en sentido rápido"),
	])


func test_sincronizar_y_repartir_la_carga() -> String:
	var sim := _g1_en_barras()
	var llego := _esperar_angulo(sim, 0.0, 4.0)
	var motivo := _acb(sim, "Q2").cerrar()
	sim.avanzar_tiempo(5.0)
	var sincronizado := sim.hubo_evento("cierre_sincronizado")
	# Igualar las consignas de velocidad reparte la carga activa a partes iguales.
	_gen(sim, "G1").estado["f_ref"] = 61.2
	_gen(sim, "G2").estado["f_ref"] = 61.2
	sim.avanzar_tiempo(20.0)
	var p1: float = _gen(sim, "G1").estado["p_kw"]
	var p2: float = _gen(sim, "G2").estado["p_kw"]
	var q1: float = _gen(sim, "G1").estado["q_kvar"]
	var q2: float = _gen(sim, "G2").estado["q_kvar"]
	return A.primero([
		A.cierto(llego, "el sincronoscopio debe pasar por 0°"),
		A.cierto(motivo.is_empty() and _acb(sim, "Q2").cerrado(), "debe cerrar: %s" % motivo),
		A.cierto(sincronizado, "debe registrarse como cierre sincronizado"),
		A.cerca(p1, p2, 0.05, "reparto de kW"),
		A.cerca(p1 + p2, 320.0, 0.05, "entre los dos dan la carga"),
		A.cerca(q1, q2, 0.1, "reparto de kVAr"),
		A.cerca(_gen(sim, "G1").frecuencia(), 60.0, 0.01, "con más velocidad, la frecuencia vuelve a 60 Hz"),
		A.cierto(not _acb(sim, "Q1").estado["disparado"] and not _acb(sim, "Q2").estado["disparado"], "no debe disparar nada"),
	])


func test_el_paralelo_se_estabiliza() -> String:
	var sim := _en_paralelo()
	var a: float = _gen(sim, "G2").estado["p_kw"]
	sim.avanzar_tiempo(1.0)
	var b: float = _gen(sim, "G2").estado["p_kw"]
	return A.cierto(absf(a - b) < 3.0, "la potencia debe asentarse: %.1f y %.1f kW" % [a, b])


func test_cierre_fuera_de_fase() -> String:
	var sim := _g1_en_barras()
	var llego := _esperar_angulo(sim, 170.0, 8.0)
	_acb(sim, "Q2").cerrar()
	sim.avanzar_tiempo(1.0)
	var g2 := _gen(sim, "G2")
	return A.primero([
		A.cierto(llego, "el sincronoscopio debe pasar por 170°"),
		A.cierto(sim.hubo_evento("cierre_fuera_de_fase", "Q2"), "debe registrarse el cierre fuera de fase"),
		A.cierto(_acb(sim, "Q2").estado["disparado"], "Q2 debe disparar"),
		A.cierto(g2.estado["danado"], "el grupo debe quedar dañado"),
		A.cierto(not g2.arrancar().is_empty(), "dañado no debe arrancar"),
		A.cierto(_acb(sim, "Q1").cerrado(), "el grupo en barras debe seguir"),
	])


func test_cierre_brusco_avisa_sin_disparar() -> String:
	var sim := _g1_en_barras()
	_esperar_angulo(sim, 35.0, 4.0)
	_acb(sim, "Q2").cerrar()
	sim.avanzar_tiempo(3.0)
	return A.primero([
		A.cierto(sim.hubo_evento("cierre_brusco", "Q2"), "debe avisar del cierre brusco"),
		A.cierto(_acb(sim, "Q2").cerrado(), "no debe disparar"),
	])


func test_potencia_inversa() -> String:
	var sim := _en_paralelo()
	# Bajar demasiado la velocidad de G2 lo convierte en motor: absorbe potencia de las barras.
	_gen(sim, "G2").estado["f_ref"] = _frecuencia_barras(sim) - 1.5
	sim.avanzar_tiempo(12.0)
	return A.primero([
		A.cierto(sim.hubo_evento("disparo_potencia_inversa", "Q2"), "debe disparar por potencia inversa"),
		A.cierto(_acb(sim, "Q1").cerrado(), "G1 debe seguir en barras"),
		A.cierto(not sim.hubo_evento("disparo_potencia_inversa", "Q1"), "G1 no debe disparar"),
	])


func test_disparo_preferente() -> String:
	var sim := _g1_en_barras()
	sim.componente("C1").params["p_kw"] = 380.0
	sim.componente("C1").params["q_kvar"] = 285.0
	sim.avanzar_tiempo(10.0)
	return A.primero([
		A.cierto(sim.hubo_evento("disparo_preferente", "Q1"), "debe actuar el disparo preferente"),
		A.cierto(not sim.componente("C2").estado["conectada"], "la carga no esencial debe salir"),
		A.cierto(sim.componente("C1").estado["conectada"], "la esencial debe seguir"),
		A.cierto(_acb(sim, "Q1").cerrado(), "el generador debe seguir en barras"),
	])


func test_sobrecarga_del_diesel_provoca_blackout() -> String:
	var sim := _g1_en_barras()
	sim.componente("C1").params["p_kw"] = 600.0
	sim.componente("C1").params["q_kvar"] = 100.0
	sim.avanzar_tiempo(15.0)
	var v: float = sim.solucion.entre("BP.L1", "BP.L2").modulo()
	return A.primero([
		A.cierto(sim.hubo_evento("parada_por_sobrecarga", "G1"), "el diésel debe calarse"),
		A.cierto(not _acb(sim, "Q1").cerrado(), "Q1 debe abrir"),
		A.cierto(v < 44.0, "las barras deben quedar sin tensión: %.0f V" % v),
	])


## Barras principales con G1, barras de emergencia unidas por un interruptor de enlace con
## bobina de mínima, y el generador de emergencia con arranque y cierre automáticos.
func _con_emergencia() -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimGenerador.new("G1"))
	sim.agregar(SimInterruptorGenerador.new("Q1"))
	sim.agregar(SimInterruptorGenerador.new("QT", {"in_a": 200.0, "p_kw_nominal": 100.0}))
	sim.agregar(SimGenerador.new("GE", {"s_kva": 94.0, "p_kw": 75.0, "vigilar": ["BP.L1", "BP.L2"]}))
	sim.agregar(SimInterruptorGenerador.new("QE", {"in_a": 123.0, "p_kw_nominal": 75.0, "cierre_automatico": true, "enclavados": ["QT"]}))
	sim.agregar(SimBarras.new("BP"))
	sim.agregar(SimBarras.new("BE"))
	sim.agregar(SimCargaTrifasica.new("CE", {"p_kw": 40.0, "q_kvar": 20.0}))
	for t in [["G1", "Q1"], ["GE", "QE"]]:
		for f in [["L1", "1"], ["L2", "3"], ["L3", "5"]]:
			sim.conectar("%s.%s" % [t[0], f[0]], "%s.%s" % [t[1], f[1]])
	for f in [["1", "L1"], ["3", "L2"], ["5", "L3"]]:
		sim.conectar("QT.%s" % f[0], "BP.%s" % f[1])
	for f in [["2", "L1"], ["4", "L2"], ["6", "L3"]]:
		sim.conectar("Q1.%s" % f[0], "BP.%s" % f[1])
		sim.conectar("QT.%s" % f[0], "BE.%s" % f[1])
		sim.conectar("QE.%s" % f[0], "BE.%s" % f[1])
	for fase in ["L1", "L2", "L3"]:
		sim.conectar("CE.%s" % fase, "BE.%s" % fase)
	_gen(sim, "G1").arrancar()
	sim.avanzar_tiempo(10.0)
	_acb(sim, "Q1").cerrar()
	sim.avanzar_tiempo(1.0)
	_acb(sim, "QT").cerrar()
	# El arranque automático se habilita con la red ya normal, como al terminar una puesta en marcha.
	_gen(sim, "GE").params["arranque_automatico"] = true
	sim.avanzar_tiempo(3.0)
	return sim


func test_blackout_arranca_la_emergencia() -> String:
	var sim := _con_emergencia()
	var antes := sim.solucion.entre("BE.L1", "BE.L2").modulo()
	var quieto := not _gen(sim, "GE").en_marcha()
	_gen(sim, "G1").parar()
	sim.avanzar_tiempo(25.0)
	var despues := sim.solucion.entre("BE.L1", "BE.L2").modulo()
	return A.primero([
		A.cierto(antes > 400.0 and quieto, "con tensión normal, la emergencia debe esperar"),
		A.cierto(sim.hubo_evento("disparo_minima_tension", "QT"), "el enlace debe abrir por mínima tensión"),
		A.cierto(sim.hubo_evento("arranque_automatico", "GE"), "la emergencia debe arrancar sola"),
		A.cierto(_acb(sim, "QE").cerrado(), "QE debe cerrar sobre las barras de emergencia"),
		A.cerca(despues, 440.0, 0.05, "las barras de emergencia recuperan la tensión"),
	])


func test_enclavamiento_impide_el_cierre() -> String:
	var sim := _con_emergencia()
	_gen(sim, "GE").arrancar()
	sim.avanzar_tiempo(10.0)
	var motivo := _acb(sim, "QE").cerrar()
	return A.primero([
		A.cierto(motivo.begins_with("Enclavado"), "con el enlace cerrado no debe cerrar: %s" % motivo),
		A.cierto(not _acb(sim, "QE").cerrado(), "debe seguir abierto"),
	])


func test_secuencimetro_y_toma_de_tierra() -> String:
	var s := SimSecuencimetro.new()
	var directa := SimSimulacion.new()
	directa.agregar(SimFuenteTrifasica.new("T"))
	var inversa := SimSimulacion.new()
	inversa.agregar(SimFuenteTrifasica.new("T", {"secuencia": "inversa"}))
	var sin_tension := SimSimulacion.new()
	sin_tension.agregar(SimFuenteTrifasica.new("T", {}, {"activa": false}))
	return A.primero([
		A.cierto(s.medir(directa, "T.L1", "T.L2", "T.L3") == "directa", "secuencia directa"),
		A.cierto(s.medir(inversa, "T.L1", "T.L2", "T.L3") == "inversa", "secuencia inversa"),
		A.cierto(s.medir(directa, "T.L1", "T.L3", "T.L2") == "inversa", "puntas cruzadas"),
		A.cierto(s.medir(directa, "T.L1", "T.L2", "T.N") == "falta_fase", "una punta sin fase"),
		A.cierto(s.medir(sin_tension, "T.L1", "T.L2", "T.L3") == "sin_tension", "sin tensión"),
	])


func test_monitor_de_aislamiento() -> String:
	var sim := _g1_en_barras()
	sim.avanzar_tiempo(2.0)
	var sano: float = sim.componente("MA").estado["mohm"]
	var sin_alarma: bool = not sim.componente("MA").estado["alarma"]
	sim.agregar(SimResistencia.new("RF", {"ohm": 400000.0}))
	sim.conectar("RF.A", "BP.L2")
	sim.conectar("RF.B", SimSolver.TIERRA)
	sim.avanzar_tiempo(2.0)
	var falla: float = sim.componente("MA").estado["mohm"]
	return A.primero([
		A.cierto(sano > 100.0 and sin_alarma, "red sana: %.1f MΩ" % sano),
		A.cerca(falla, 0.4, 0.05, "falla a tierra de 0,4 MΩ"),
		A.cierto(sim.hubo_evento("alarma_aislamiento", "MA"), "debe dar alarma"),
		A.cierto(_acb(sim, "Q1").cerrado(), "una primera falla a tierra no dispara"),
	])


func test_cuadro_se_guarda_y_carga() -> String:
	var sim := _en_paralelo()
	var copia := SimSimulacion.desde_dict(JSON.parse_string(JSON.stringify(sim.a_dict())))
	copia.avanzar_tiempo(2.0)
	return A.primero([
		A.cierto(_acb(copia, "Q2").cerrado(), "debe conservar el interruptor cerrado"),
		A.cierto(_gen(copia, "G2").en_marcha(), "debe conservar el grupo en marcha"),
		A.cerca(_gen(copia, "G2").frecuencia(), _gen(sim, "G2").frecuencia(), 0.01, "debe conservar la frecuencia"),
		A.cierto(not copia.hubo_evento("cierre_fuera_de_fase"), "cargar no debe provocar sacudidas"),
	])
