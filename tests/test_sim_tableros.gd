extends RefCounted
## Simulación de los tableros del buque y de sus piezas: selector, seta, interruptor general con
## candado, horómetro y lámparas de tierra.

const A := preload("res://tests/ayuda_sim.gd")


func _tablero() -> SimSimulacion:
	var sim := A.circuito("tablero_bombas_mp")
	sim.avanzar_tiempo(0.5)
	return sim


func _luz(sim: SimSimulacion, id: String) -> bool:
	return sim.componente(id).estado["encendida"]


func test_encendido_y_apagado_de_la_bomba_de_enfriamiento() -> String:
	var sim := _tablero()
	var apagado_al_inicio: bool = _luz(sim, "HA1") and not _luz(sim, "HE1")
	A.pulsar(sim, "SM1", 0.3)
	sim.avanzar_tiempo(6.0)
	var en_marcha: bool = sim.componente("K1").cerrado() and sim.componente("M1").rpm() > 1400.0
	var luces_marcha: bool = _luz(sim, "HE1") and not _luz(sim, "HA1")
	A.pulsar(sim, "SP1", 0.3)
	sim.avanzar_tiempo(1.0)
	return A.primero([
		A.cierto(apagado_al_inicio, "parada: APAGADO encendida y ENCENDIDO apagada"),
		A.cierto(en_marcha, "ENCENDIDO arranca la bomba y se enclava"),
		A.cierto(luces_marcha, "en marcha se enciende ENCENDIDO y se apaga APAGADO"),
		A.cierto(not sim.componente("K1").cerrado() and _luz(sim, "HA1"), "APAGADO la para"),
		A.cierto(not _luz(sim, "HF1"), "sin falla térmica"),
	])


func test_prelubricacion_en_aut_sigue_la_orden_y_en_man_arranca() -> String:
	var sim := _tablero()
	var sel: SimSelector = sim.componente("SEL3")
	var orden: SimSelector = sim.componente("ORD3")
	var en_aut_sin_orden: bool = sel.nombre_posicion() == "AUT" and not sim.componente("K3").cerrado()
	orden.poner("ORDEN")
	sim.avanzar_tiempo(1.0)
	var con_orden: bool = sim.componente("K3").cerrado()
	sel.poner("OFF")
	sim.avanzar_tiempo(1.0)
	var en_off: bool = sim.componente("K3").cerrado()
	orden.poner("SIN ORDEN")
	sel.poner("MAN")
	sim.avanzar_tiempo(1.0)
	return A.primero([
		A.cierto(en_aut_sin_orden, "en AUT y sin orden, parada"),
		A.cierto(con_orden, "en AUT arranca con la orden del control de propulsión"),
		A.cierto(not en_off, "en OFF no arranca de ninguna forma"),
		A.cierto(sim.componente("K3").cerrado() and _luz(sim, "HE3"), "en MAN trabaja sin orden"),
	])


func test_lamparas_de_tierra_iguales_con_la_red_sana() -> String:
	var sim := _tablero()
	# Las tres lámparas en estrella alumbran igual aunque no se pulse TEST: su centro queda en el
	# neutro de la red.
	var sin_test: float = sim.componente("HT1").estado["relacion"]
	sim.componente("ST").estado["presionado"] = true
	sim.avanzar_tiempo(0.2)
	var r: Array[float] = []
	for i in 3:
		r.append(float(sim.componente("HT%d" % (i + 1)).estado["relacion"]))
	return A.primero([
		A.cerca(sin_test, 1.0 / sqrt(3.0), 0.05, "sin pulsar TEST alumbran a la tensión de fase"),
		A.cerca(r[0], 1.0 / sqrt(3.0), 0.05, "L1 a la tensión de fase"),
		A.cerca(r[1], r[0], 0.02, "L2 igual que L1"),
		A.cerca(r[2], r[0], 0.02, "L3 igual que L1"),
	])


func test_fase_a_masa_apaga_su_lampara_y_aviva_las_otras() -> String:
	var sim := _tablero()
	sim.componente("M1").params["aislamiento_mohm"] = [0.005, 300.0, 300.0]
	A.pulsar(sim, "SM1", 0.3)
	sim.avanzar_tiempo(3.0)
	# Sin pulsar TEST el centro de la estrella no toca el casco: la falla no se ve.
	var antes: float = sim.componente("HT1").estado["relacion"]
	sim.componente("ST").estado["presionado"] = true
	sim.avanzar_tiempo(0.2)
	var r1: float = sim.componente("HT1").estado["relacion"]
	var r2: float = sim.componente("HT2").estado["relacion"]
	var r3: float = sim.componente("HT3").estado["relacion"]
	return A.primero([
		A.cerca(antes, 1.0 / sqrt(3.0), 0.05, "sin TEST la fase a masa no se nota"),
		A.cierto(r1 < 0.2, "la lámpara de la fase a masa casi se apaga: %.2f" % r1),
		A.cierto(r2 > 0.85 and r3 > 0.85, "las otras dos ven casi la tensión de línea: %.2f y %.2f" % [r2, r3]),
		A.cierto(not sim.componente("HT2").estado["quemada"], "las lámparas de tierra son de 380 V: no se queman"),
	])


func test_bomba_agarrotada_dispara_y_enciende_falla_termica() -> String:
	var sim := _tablero()
	sim.componente("M2").params["bloqueado"] = true
	A.pulsar(sim, "SM2", 0.3)
	var disparo := false
	for _i in 120:
		sim.avanzar_tiempo(0.5)
		if sim.componente("F2").estado["disparado"] or not sim.componente("Q2").cerrado():
			disparo = true
			break
	sim.avanzar_tiempo(0.5)
	return A.primero([
		A.cierto(disparo, "con el rotor bloqueado debe disparar la protección"),
		A.cierto(not sim.componente("K2").cerrado(), "la bomba queda parada"),
	])


func test_candado_impide_cerrar_el_interruptor_general() -> String:
	var sim := _tablero()
	var q0: SimSeccionador = sim.componente("Q0")
	var con_tension_cerrado: bool = not q0.poner_candado(true)
	q0.accionar(false)
	var candado := q0.poner_candado(true)
	var cerrar := q0.accionar(true)
	A.pulsar(sim, "SM1", 0.3)
	sim.avanzar_tiempo(1.0)
	return A.primero([
		A.cierto(con_tension_cerrado, "el candado no entra con el interruptor cerrado"),
		A.cierto(candado and not cerrar, "abierto y con candado no se puede cerrar"),
		A.cierto(not sim.componente("K1").cerrado() and not _luz(sim, "HA1"), "sin tensión no hay mando ni luces"),
	])


func test_seta_enclava_hasta_girarla() -> String:
	var s := SimSimulacion.new()
	var seta: SimSeta = s.agregar(SimSeta.new("S0"))
	var abierta_al_pulsar: bool = false
	seta.pulsar()
	abierta_al_pulsar = seta.estado["enclavada"]
	var sigue: bool = seta.estado["enclavada"]
	seta.liberar()
	return A.primero([
		A.cierto(abierta_al_pulsar and sigue, "pulsada queda enclavada"),
		A.cierto(not seta.estado["enclavada"], "girándola se libera"),
	])


func test_selector_con_retorno_vuelve_al_soltar() -> String:
	var sel := SimSelector.new("S1", {"posiciones": ["0", "1", "START"], "contactos": {"13-14": ["1", "START"], "23-24": ["START"]}, "retorno": ["START"]})
	sel.girar(1)
	sel.girar(1)
	var en_start: bool = sel.nombre_posicion() == "START" and sel.cerrado("23-24")
	sel.soltar()
	return A.primero([
		A.cierto(en_start, "llega a START y cierra 23-24"),
		A.cierto(sel.nombre_posicion() == "1" and not sel.cerrado("23-24") and sel.cerrado("13-14"), "al soltar vuelve a 1"),
	])


func test_horometro_cuenta_y_uno_de_60_hz_atrasa() -> String:
	var s := A.circuito("arranque_directo")
	var bien: SimHorometro = s.agregar(SimHorometro.new("P1", {"v_nominal": 110.0}))
	var de_60: SimHorometro = s.agregar(SimHorometro.new("P2", {"v_nominal": 110.0, "hz_nominal": 60.0}))
	for p in ["P1", "P2"]:
		s.conectar("K1.A1", p + ".A1")
		s.conectar("K1.A2", p + ".A2")
	s.componente("Q1").accionar(true)
	s.paso()
	A.pulsar(s, "S1")
	s.avanzar_tiempo(36.0)
	return A.primero([
		A.cerca(bien.estado["horas"], 0.01, 0.03, "36 s son 0,01 h"),
		A.cerca(de_60.estado["horas"], bien.estado["horas"] * 50.0 / 60.0, 0.03, "el de 60 Hz cuenta 50/60"),
	])
