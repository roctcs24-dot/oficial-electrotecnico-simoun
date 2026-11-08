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


func test_hidroforo_en_aut_arranca_y_para_con_el_presostato() -> String:
	var sim := A.circuito("tablero_hidroforo_salada")
	var th: SimHidroforo = sim.componente("TH")
	th.estado["presion"] = 2.6
	var arranco := false
	var paro_lleno := false
	for _i in 200:
		sim.avanzar_tiempo(0.5)
		if sim.componente("K1").cerrado():
			arranco = true
		elif arranco and th.estado["presion"] >= 3.9:
			paro_lleno = true
			break
	return A.primero([
		A.cierto(arranco, "al bajar de 2,5 bar la bomba nº 1 debe arrancar"),
		A.cierto(paro_lleno, "al llegar a 4 bar debe parar: %.2f bar" % th.estado["presion"]),
		A.cierto(not sim.componente("K2").cerrado(), "con el selector en BOMBA #1, la nº 2 no trabaja"),
	])


func test_hidroforo_sin_una_fase_dispara_el_termico() -> String:
	var sim := A.circuito("tablero_hidroforo_salada")
	sim.componente("Q0").params["polo_danado"] = "5-6"
	(sim.componente("SM") as SimSelector).poner("MAN")
	var disparo := false
	for _i in 240:
		sim.avanzar_tiempo(0.5)
		if sim.componente("F1").estado["disparado"] or not sim.componente("Q1").cerrado():
			disparo = true
			break
	sim.avanzar_tiempo(0.5)
	return A.primero([
		A.cierto(disparo, "con una fase perdida el motor no arranca y dispara su protección"),
		A.cierto(not sim.componente("K1").cerrado(), "la bomba queda parada"),
	])


func test_purificadora_arranca_en_orden_y_la_seta_lo_para_todo() -> String:
	var sim := A.circuito("tablero_purificadora")
	(sim.componente("Q0") as SimSeccionador).accionar(true)
	var s1: SimSelector = sim.componente("S1")
	var s2: SimSelector = sim.componente("S2")
	s2.poner("START")
	sim.avanzar_tiempo(0.3)
	s2.soltar()
	sim.avanzar_tiempo(0.5)
	var bomba_sin_separadora: bool = sim.componente("K2").cerrado()
	s1.poner("START")
	sim.avanzar_tiempo(0.3)
	s1.soltar()
	sim.avanzar_tiempo(10.0)
	var separadora: bool = sim.componente("K1").cerrado() and sim.componente("M1").rpm() > 2700.0
	s2.poner("START")
	sim.avanzar_tiempo(0.3)
	s2.soltar()
	sim.avanzar_tiempo(2.0)
	var bomba: bool = sim.componente("K2").cerrado() and sim.componente("H2").estado["encendida"]
	var horas: float = sim.componente("P1").estado["horas"]
	(sim.componente("SE") as SimSeta).pulsar()
	sim.avanzar_tiempo(0.5)
	return A.primero([
		A.cierto(not bomba_sin_separadora, "la bomba no arranca con la separadora parada"),
		A.cierto(separadora, "START y soltar en 1: la separadora arranca y se enclava"),
		A.cierto(bomba, "con la separadora en marcha arranca la bomba"),
		A.cierto(horas > 1824.6, "el horómetro cuenta con la separadora en marcha"),
		A.cierto(not sim.componente("K1").cerrado() and not sim.componente("K2").cerrado(), "la seta para las dos"),
	])


func test_servotimon_en_local_mueve_el_timon_con_los_pulsadores() -> String:
	var sim := A.circuito("tablero_servotimon")
	sim.avanzar_tiempo(6.0)
	var en_remoto: bool = sim.componente("K1").cerrado() and sim.componente("HR").estado["encendida"]
	var yv: SimTimon = sim.componente("YV")
	sim.componente("SB").estado["presionado"] = true
	sim.avanzar_tiempo(3.0)
	var remoto_no_mueve: bool = absf(yv.estado["angulo"]) < 0.1
	sim.componente("SB").estado["presionado"] = false
	(sim.componente("S1") as SimSelector).poner("2. STOP")
	sim.avanzar_tiempo(1.0)
	var calefaccion: bool = sim.componente("HH").estado["encendida"] and not sim.componente("K1").cerrado()
	(sim.componente("S1") as SimSelector).poner("3. LOCAL")
	sim.avanzar_tiempo(6.0)
	sim.componente("SB").estado["presionado"] = true
	sim.avanzar_tiempo(5.0)
	sim.componente("SB").estado["presionado"] = false
	var a_babor: float = yv.estado["angulo"]
	return A.primero([
		A.cierto(en_remoto, "en remoto, con la orden del puente, la bomba trabaja"),
		A.cierto(remoto_no_mueve, "en remoto los pulsadores de emergencia no actúan"),
		A.cierto(calefaccion, "parada, se enciende HEATING ON"),
		A.cierto(a_babor < -10.0 and a_babor > -16.0, "en local, 5 s a babor mueven unos 13°: %.1f°" % a_babor),
	])


func test_habitabilidad_fase_a_masa_con_test() -> String:
	var sim := A.circuito("tablero_habitabilidad_110")
	sim.componente("CA").params["falla_mohm"] = 0.0005
	sim.componente("ST").estado["presionado"] = true
	sim.avanzar_tiempo(0.3)
	var r1: float = sim.componente("HT1").estado["relacion"]
	var r2: float = sim.componente("HT2").estado["relacion"]
	return A.primero([
		A.cierto(r1 < 0.2, "la lámpara R se apaga: %.2f" % r1),
		A.cierto(r2 > 0.85 and not sim.componente("HT2").estado["quemada"], "S brilla más sin quemarse: %.2f" % r2),
	])


# --- Tablero de compresores NH3 ---

func _compresores() -> SimSimulacion:
	var sim := A.circuito("tablero_compresores_nh3")
	sim.avanzar_tiempo(0.5)
	return sim


func test_bomba_de_amoniaco_marcha_y_paro_con_sus_luces() -> String:
	var sim := _compresores()
	var paro_al_inicio: bool = _luz(sim, "HA1") and not _luz(sim, "HE1")
	A.pulsar(sim, "SM1", 0.3)
	sim.avanzar_tiempo(5.0)
	var en_marcha: bool = sim.componente("K1").cerrado() and sim.componente("M1").rpm() > 2800.0
	var luces_marcha: bool = _luz(sim, "HE1") and not _luz(sim, "HA1")
	A.pulsar(sim, "SP1", 0.3)
	sim.avanzar_tiempo(1.0)
	return A.primero([
		A.cierto(paro_al_inicio, "parada: luz de PARO encendida y MARCHA apagada"),
		A.cierto(en_marcha, "MARCHA arranca la bomba: %.0f rpm" % sim.componente("M1").rpm()),
		A.cierto(luces_marcha, "en marcha se enciende la verde y se apaga la roja"),
		A.cierto(not sim.componente("K1").cerrado() and _luz(sim, "HA1"), "PARO la detiene"),
	])


func test_compresor_3_arranca_con_el_arrancador_suave() -> String:
	var sim := _compresores()
	(sim.componente("ORDC3") as SimSelector).girar(1)
	sim.avanzar_tiempo(3.0)
	var as3: SimArrancadorSuave = sim.componente("AS3")
	var en_rampa := as3.fase() == "arranque"
	var limitada := as3.corriente() <= 3.5 * 173.0 * 1.1
	sim.avanzar_tiempo(25.0)
	return A.primero([
		A.cierto(en_rampa, "a los 3 s debe estar en rampa: %s" % as3.fase()),
		A.cierto(limitada, "la corriente de arranque no pasa del límite: %.0f A" % as3.corriente()),
		A.cierto(as3.fase() == "bypass", "termina en bypass: %s" % as3.fase()),
		A.cierto(as3.corriente() < 173.0, "en marcha, por debajo de Ie: %.0f A" % as3.corriente()),
		A.cierto(sim.componente("PC3").estado["contando"], "el horómetro cuenta"),
		A.cierto(not sim.componente("KC4").cerrado(), "el nº 4 sigue parado"),
	])


func test_bobina_en_corto_funde_el_fusible_y_apaga_las_dos_luces() -> String:
	var sim := _compresores()
	sim.componente("K1").params["espiras_en_corto"] = true
	A.pulsar(sim, "SM1", 0.3)
	sim.avanzar_tiempo(1.0)
	return A.primero([
		A.cierto(sim.componente("FM1").estado["fundido"], "el fusible de mando FM1 debe fundirse"),
		A.cierto(not sim.componente("K1").cerrado(), "K1 no cierra con la bobina en corto"),
		A.cierto(not _luz(sim, "HE1") and not _luz(sim, "HA1"), "las dos luces de la bomba nº 1 quedan apagadas"),
		A.cierto(_luz(sim, "HA2") and not sim.componente("FM2").estado["fundido"], "la bomba nº 2 no se entera"),
	])
