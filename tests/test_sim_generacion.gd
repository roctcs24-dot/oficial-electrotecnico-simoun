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
		A.cerca(g.frecuencia(), 50.0, 0.005, "frecuencia en vacío"),
		A.cerca(g.estado["v"], 380.0, 0.01, "tensión en vacío"),
		A.cierto(not sim.hubo_evento("disparo_minima_tension"), "no debe disparar nada"),
	])


func test_cierre_sobre_barra_muerta_y_estatismo() -> String:
	var sim := _g1_en_barras()
	var g := _gen(sim, "G1")
	var p: float = g.estado["p_kw"]
	# La fricción también la aporta el diésel: cuenta como carga para el gobernador.
	var friccion_kw: float = g.params["friccion_pu"] * g.params["s_kva"]
	var esperada := 50.0 - 0.04 * 50.0 * (p + friccion_kw) / 452.0
	return A.primero([
		A.cierto(_acb(sim, "Q1").cerrado(), "Q1 debe cerrar sobre barra muerta"),
		A.cierto(sim.hubo_evento("cierre_barra_muerta"), "debe registrar el cierre en barra muerta"),
		A.cerca(p, 320.0, 0.05, "potencia de las dos cargas"),
		A.cerca(g.frecuencia(), esperada, 0.003, "la frecuencia baja con la carga según el estatismo"),
		A.cerca(g.estado["v"], 380.0, 0.03, "el AVR mantiene la tensión"),
	])


func test_isocrono_mantiene_60_hz() -> String:
	var sim := _cuadro()
	var g := _gen(sim, "G1")
	g.params["modo_gobernador"] = "isocrono"
	g.arrancar()
	sim.avanzar_tiempo(10.0)
	_acb(sim, "Q1").cerrar()
	sim.avanzar_tiempo(30.0)
	return A.cerca(g.frecuencia(), 50.0, 0.002, "un gobernador isócrono vuelve a 50 Hz con carga")


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
	_gen(sim, "G1").estado["f_ref"] = 51.0
	_gen(sim, "G2").estado["f_ref"] = 51.0
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
		A.cerca(_gen(sim, "G1").frecuencia(), 50.0, 0.01, "con más velocidad, la frecuencia vuelve a 50 Hz"),
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
		A.cierto(antes > 340.0 and quieto, "con tensión normal, la emergencia debe esperar: %.0f V" % antes),
		A.cierto(sim.hubo_evento("disparo_minima_tension", "QT"), "el enlace debe abrir por mínima tensión"),
		A.cierto(sim.hubo_evento("arranque_automatico", "GE"), "la emergencia debe arrancar sola"),
		A.cierto(_acb(sim, "QE").cerrado(), "QE debe cerrar sobre las barras de emergencia"),
		A.cerca(despues, 380.0, 0.05, "las barras de emergencia recuperan la tensión"),
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


func _pms(sim: SimSimulacion) -> SimPMS:
	return sim.componente("PMS")


func test_pms_reparte_y_mantiene_60_hz() -> String:
	var sim := _en_paralelo()
	_gen(sim, "G1").estado["f_ref"] = 51.25
	_pms(sim).fijar_automatico(true)
	sim.avanzar_tiempo(40.0)
	var p1: float = _gen(sim, "G1").estado["p_kw"]
	var p2: float = _gen(sim, "G2").estado["p_kw"]
	return A.primero([
		A.cerca(p1, p2, 0.05, "reparto de kW"),
		A.cerca(_gen(sim, "G1").frecuencia(), 50.0, 0.002, "frecuencia"),
	])


func test_pms_arranca_y_sincroniza_la_reserva() -> String:
	var sim := _g1_en_barras()
	_pms(sim).fijar_automatico(true)
	sim.componente("C1").params["p_kw"] = 290.0
	sim.componente("C1").params["q_kvar"] = 200.0
	sim.avanzar_tiempo(45.0)
	return A.primero([
		A.cierto(sim.hubo_evento("pms_arranque"), "debe arrancar un grupo de reserva"),
		A.cierto(_acb(sim, "Q2").cerrado(), "G2 debe quedar en barras"),
		A.cierto(sim.hubo_evento("cierre_sincronizado", "Q2"), "debe cerrar sincronizado"),
		A.cierto(not sim.hubo_evento("cierre_fuera_de_fase") and not sim.hubo_evento("cierre_brusco"), "sin cierres bruscos"),
		A.cerca(_gen(sim, "G1").estado["p_kw"], _gen(sim, "G2").estado["p_kw"], 0.1, "deben repartirse la carga"),
		A.cierto(not _acb(sim, "Q3").cerrado(), "no debe arrancar más grupos de los necesarios"),
	])


func test_pms_recupera_las_barras() -> String:
	var sim := _cuadro()
	_pms(sim).fijar_automatico(true)
	sim.avanzar_tiempo(20.0)
	var primero := _acb(sim, "Q1").cerrado()
	_gen(sim, "G1").parar()
	sim.avanzar_tiempo(25.0)
	var v: float = sim.solucion.entre("BP.L1", "BP.L2").modulo()
	return A.primero([
		A.cierto(primero, "sin grupos, debe arrancar uno y cerrar sobre barra muerta"),
		A.cerca(v, 380.0, 0.05, "tras el blackout debe recuperar las barras: %.0f V" % v),
	])


func test_sincronizador_automatico_en_manual() -> String:
	var sim := _g1_en_barras()
	var sin_marcha := _pms(sim).sincronizar("G2")
	_gen(sim, "G2").arrancar()
	sim.avanzar_tiempo(10.0)
	var motivo := _pms(sim).sincronizar("G2")
	sim.avanzar_tiempo(40.0)
	return A.primero([
		A.cierto(not sin_marcha.is_empty(), "sin el diésel en marcha no debe empezar"),
		A.cierto(motivo.is_empty(), "debe aceptar la petición: %s" % motivo),
		A.cierto(_acb(sim, "Q2").cerrado(), "debe cerrar Q2"),
		A.cierto(sim.hubo_evento("cierre_sincronizado", "Q2"), "debe cerrar sincronizado"),
		A.cierto(_pms(sim).sincronizando().is_empty(), "debe terminar la sincronización"),
		A.cierto(not _pms(sim).automatico(), "el PMS debe seguir en manual"),
	])


func test_sincronizar_sin_barras_se_rechaza() -> String:
	var sim := _cuadro()
	_gen(sim, "G1").arrancar()
	sim.avanzar_tiempo(10.0)
	var motivo := _pms(sim).sincronizar("G1")
	return A.cierto(motivo.contains("cierre directamente"), "con barras muertas no hace falta sincronizar: %s" % motivo)


func test_pms_en_manual_no_actua() -> String:
	var sim := _cuadro()
	sim.avanzar_tiempo(10.0)
	return A.cierto(not _gen(sim, "G1").en_marcha() and not sim.hubo_evento("pms_arranque"), "en manual no debe arrancar nada")


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


func test_diesel_parado_se_detiene_en_segundos() -> String:
	var sim := _cuadro()
	var g := _gen(sim, "G1")
	g.arrancar()
	sim.avanzar_tiempo(10.0)
	g.parar()
	sim.avanzar_tiempo(2.0)
	var f_2s := g.frecuencia()
	sim.avanzar_tiempo(18.0)
	return A.primero([
		A.cierto(f_2s > 40.0, "no se para de golpe: %.1f Hz a los 2 s" % f_2s),
		A.cierto(g.frecuencia() < 1.0, "a los 20 s debe estar parado: %.1f Hz" % g.frecuencia()),
	])


func test_bloqueado_o_parado_por_alarma_no_arranca() -> String:
	var sim := _cuadro()
	var g1 := _gen(sim, "G1")
	var g2 := _gen(sim, "G2")
	g1.estado["bloqueado"] = true
	var bloqueado := g1.arrancar()
	g2.arrancar()
	sim.avanzar_tiempo(5.0)
	g2.parar_por_alarma("Baja presión de aceite")
	var alarma := g2.arrancar()
	g2.estado["parada"] = ""
	var reconocida := g2.arrancar()
	return A.primero([
		A.cierto(not bloqueado.is_empty() and not g1.en_marcha(), "bloqueado no debe arrancar"),
		A.cierto(alarma.contains("aceite") and not g1.disponible(), "parado por alarma debe decir cuál: %s" % alarma),
		A.cierto(sim.hubo_evento("parada_por_alarma", "G2"), "debe registrarse la parada"),
		A.cierto(reconocida.is_empty() and g2.en_marcha(), "reconocida la alarma, arranca"),
	])


func test_deriva_de_la_consigna_de_velocidad() -> String:
	var sim := _cuadro()
	var g := _gen(sim, "G1")
	g.params["deriva_hz_s"] = -0.02
	g.arrancar()
	sim.avanzar_tiempo(10.0)
	var antes: float = g.estado["f_ref"]
	sim.avanzar_tiempo(20.0)
	var despues: float = g.estado["f_ref"]
	g.parar()
	sim.avanzar_tiempo(10.0)
	return A.primero([
		A.cerca(antes - despues, 0.4, 0.02, "en 20 s la consigna baja 0,4 Hz"),
		A.cerca(g.estado["f_ref"], despues, 0.0001, "parado, la consigna no se mueve"),
	])


func test_falla_a_tierra_de_una_salida_solo_cuenta_conectada() -> String:
	var sim := _g1_en_barras()
	var c: SimCargaTrifasica = sim.componente("C2")
	c.params["falla_mohm"] = 0.05
	c.params["falla_fase"] = "L2"
	sim.avanzar_tiempo(2.0)
	var con_falla: float = sim.componente("MA").estado["mohm"]
	var v_l2 := sim.solucion.entre("BP.L2", SimSolver.TIERRA).modulo()
	c.desconectar()
	sim.avanzar_tiempo(2.0)
	var sin_falla: float = sim.componente("MA").estado["mohm"]
	return A.primero([
		A.cierto(con_falla < 0.1, "con la salida conectada, el monitor ve la falla: %.3f MΩ" % con_falla),
		A.cierto(v_l2 < 20.0, "L2 queda al potencial del casco: %.0f V" % v_l2),
		A.cierto(sin_falla > 10.0, "desconectada, la falla sale de la red: %.1f MΩ" % sin_falla),
		A.cerca(c.aislamiento_mohm(), 0.05, 0.001, "el megóhmetro mide la falla en la salida abierta"),
	])


func test_pms_sin_sincronizador_arranca_pero_no_cierra() -> String:
	var sim := _g1_en_barras()
	var pms: SimPMS = sim.componente("PMS")
	pms.params["sincronizador"] = false
	pms.fijar_automatico(true)
	sim.componente("C1").params["p_kw"] = 340.0
	sim.avanzar_tiempo(30.0)
	return A.primero([
		A.cierto(_gen(sim, "G2").en_marcha(), "con carga alta debe arrancar la reserva"),
		A.cierto(not _acb(sim, "Q2").cerrado(), "sin sincronizador no debe cerrarla"),
		A.cierto(pms.estado["mensaje"].contains("a mano"), "debe pedir sincronizar a mano: %s" % pms.estado["mensaje"]),
		A.cierto(not pms.sincronizar("G2").is_empty(), "la sincronización automática debe negarse"),
	])
