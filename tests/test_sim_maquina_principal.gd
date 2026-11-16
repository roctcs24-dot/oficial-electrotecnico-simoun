extends RefCounted
## Main Engine Control Panel de la máquina principal: permisivos, secuencia con aire de arranque,
## arranque fallido, paradas de seguridad retenidas y RESET ALARM.

const A := preload("res://tests/ayuda_sim.gd")


func _panel(averia := "") -> SimSimulacion:
	var sim := Contenido.new().circuito("panel_maquina_principal")
	sim.componente("MP").params["averia"] = averia
	# La prelubricación sube la presión de aceite antes de poder arrancar.
	sim.avanzar_tiempo(10.0)
	return sim


func _mp(sim: SimSimulacion) -> SimMaquinaPrincipal:
	return sim.componente("MP") as SimMaquinaPrincipal


func _luz(sim: SimSimulacion, id: String) -> bool:
	return sim.componente(id).estado["encendida"]


## Gira STOP-RUN-START a START y lo suelta: vuelve solo a RUN.
func _start(sim: SimSimulacion) -> void:
	var s: SimSelector = sim.componente("SRS")
	s.poner("START")
	sim.avanzar_tiempo(0.3)
	s.soltar()
	sim.paso()


func _arrancar(sim: SimSimulacion) -> void:
	_start(sim)
	sim.avanzar_tiempo(12.0)


func _stop(sim: SimSimulacion, segundos := 0.5) -> void:
	var s: SimSelector = sim.componente("SRS")
	s.poner("STOP")
	sim.avanzar_tiempo(segundos)
	s.poner("RUN")
	sim.paso()


func test_prelubricado_arranca_al_ralenti_del_buque() -> String:
	var sim := _panel()
	var aceite := _mp(sim).presion("aceite")
	var sistema := _luz(sim, "H1")
	_start(sim)
	sim.avanzar_tiempo(1.0)
	var con_aire: bool = _mp(sim).estado["arr"]
	sim.avanzar_tiempo(20.0)
	var s: SimSelector = sim.componente("SRS")
	return A.primero([
		A.cierto(aceite >= 0.6, "la prelubricación da presión de aceite: %.2f bar" % aceite),
		A.cierto(sistema, "SYSTEM OK encendida con el motor parado y sin fallas"),
		A.cierto(con_aire, "START abre el aire de arranque"),
		A.cierto(s.nombre_posicion() == "RUN", "el selector vuelve solo a RUN"),
		A.cerca(_mp(sim).rpm(), 440.0, 0.03, "llega al ralentí de 440 rpm de la pantalla del MEC2+"),
		A.cierto(not _mp(sim).estado["arr"], "encendido, el aire se corta"),
		A.cierto(_luz(sim, "H2"), "ENGINE RUNNING encendida"),
		A.cerca(_mp(sim).presion("aceite"), 2.8, 0.1, "aceite a la entrada: unos 2,8 bar al ralentí"),
	])


func test_speed_sube_y_baja_la_consigna() -> String:
	var sim := _panel()
	_arrancar(sim)
	var spd: SimSelector = sim.componente("SPD")
	spd.poner("INCR")
	sim.avanzar_tiempo(5.0)
	spd.soltar()
	sim.avanzar_tiempo(10.0)
	var subida := _mp(sim).rpm()
	var centrado := spd.nombre_posicion()
	spd.poner("DECR")
	sim.avanzar_tiempo(20.0)
	spd.soltar()
	sim.avanzar_tiempo(10.0)
	return A.primero([
		A.cierto(subida > 650.0, "INCR sube la velocidad: %.0f rpm" % subida),
		A.cierto(centrado == "0", "al soltar vuelve al centro: %s" % centrado),
		A.cerca(_mp(sim).rpm(), 440.0, 0.03, "DECR no baja del ralentí"),
	])


func test_virador_acoplado_corta_el_aire_y_da_arranque_fallido() -> String:
	var sim := _panel()
	(sim.componente("VIR") as SimSelector).poner("ACOPLADO")
	sim.avanzar_tiempo(0.5)
	_arrancar(sim)
	var plc: SimPLC = sim.componente("PLC")
	return A.primero([
		A.cierto(not _mp(sim).estado["arr"] and _mp(sim).rpm() < 1.0, "con el virador acoplado no llega el aire y el motor no gira"),
		A.cierto(not _luz(sim, "H1"), "el arranque fallido apaga SYSTEM OK"),
		A.cierto(not plc.salida_activa(0), "el controlador ya cortó la orden de aire"),
	])


func test_presostato_de_aire_averiado_quita_el_permisivo() -> String:
	var sim := _panel("presostato_aire")
	var plc: SimPLC = sim.componente("PLC")
	_arrancar(sim)
	return A.primero([
		A.cerca(_mp(sim).presion("aire"), 8.5, 0.05, "la línea tiene unos 8,5 bar (123 psi del monitor)"),
		A.cierto(not plc.entrada_activa(5), "la entrada I0.5 no se activa"),
		A.cierto(not _mp(sim).encendida() and _mp(sim).rpm() < 1.0, "sin el permisivo, START no hace nada"),
		A.cierto(_luz(sim, "H1"), "no es un arranque fallido: SYSTEM OK sigue encendida"),
	])


func test_no_enciende_corta_el_aire_y_marca_arranque_fallido() -> String:
	var sim := _panel("no_enciende")
	var aire_antes := _mp(sim).presion("botellas")
	_start(sim)
	sim.avanzar_tiempo(4.0)
	var gira: bool = _mp(sim).rpm() > 80.0
	sim.avanzar_tiempo(10.0)
	var gastado := aire_antes - _mp(sim).presion("botellas")
	return A.primero([
		A.cierto(gira, "el aire hace girar el motor"),
		A.cierto(not _mp(sim).estado["arr"], "a los 8 s se corta el aire"),
		A.cierto(gastado > 5.0 and gastado < 12.0, "gasta aire solo durante el tiempo máximo: %.1f bar" % gastado),
		A.cierto(not _luz(sim, "H1"), "el arranque fallido apaga SYSTEM OK"),
	])


func test_cop_para_queda_retenido_y_reset_alarm_lo_repone() -> String:
	var sim := _panel("cop")
	_arrancar(sim)
	sim.avanzar_tiempo(30.0)
	var parada: bool = not _mp(sim).encendida() and _luz(sim, "H3") and _mp(sim).estado["par"]
	sim.avanzar_tiempo(20.0)
	A.pulsar(sim, "RA", 0.3)
	sim.avanzar_tiempo(1.0)
	var sin_reponer := _luz(sim, "H3")
	_mp(sim).params["averia"] = ""
	var rearmado := _mp(sim).rearmar()
	sim.avanzar_tiempo(0.5)
	A.pulsar(sim, "RA", 0.3)
	sim.avanzar_tiempo(2.0)
	return A.primero([
		A.cierto(parada, "el COP abre la cadena, enciende COP / OVERSPEED y para el motor"),
		A.cierto(sin_reponer, "con el COP abierto, RESET ALARM no repone"),
		A.cierto(rearmado, "con el motor parado se rearma el COP"),
		A.cierto(not _luz(sim, "H3") and _luz(sim, "H1"), "RESET ALARM repone y vuelve SYSTEM OK"),
	])


func test_baja_presion_de_aceite_en_marcha_para_el_motor() -> String:
	var sim := _panel("baja_presion_aceite")
	_arrancar(sim)
	var encendio := _mp(sim).encendida()
	sim.avanzar_tiempo(25.0)
	return A.primero([
		A.cierto(encendio, "arranca, con la presión inhibida al encender"),
		A.cierto(not _mp(sim).encendida() and _luz(sim, "H5"), "pasada la inhibición, se para con LOW OIL PRESSURE"),
		A.cierto(not _luz(sim, "H3"), "no es una parada de la cadena"),
	])


func test_motor_frio_limita_la_carga_y_stop_lo_para() -> String:
	var sim := _panel()
	_start(sim)
	sim.avanzar_tiempo(4.0)
	var limitado := _luz(sim, "H4")
	sim.avanzar_tiempo(60.0)
	var caliente := not _luz(sim, "H4")
	_stop(sim)
	sim.avanzar_tiempo(20.0)
	var parado: bool = _mp(sim).rpm() < 1.0
	sim.avanzar_tiempo(5.0)
	_arrancar(sim)
	return A.primero([
		A.cierto(limitado, "recién encendido y frío, LOAD LIMIT encendida"),
		A.cierto(caliente, "con el agua caliente se apaga LOAD LIMIT"),
		A.cierto(parado, "STOP corta el combustible y el motor se para"),
		A.cierto(_mp(sim).encendida(), "y arranca de nuevo"),
	])


func test_emergencia_para_y_system_power_apaga_el_panel() -> String:
	var sim := _panel()
	_arrancar(sim)
	(sim.componente("S0") as SimSeta).pulsar()
	sim.avanzar_tiempo(20.0)
	var parado: bool = _mp(sim).rpm() < 1.0
	(sim.componente("S0") as SimSeta).liberar()
	(sim.componente("SPW") as SimSelector).poner("OFF")
	sim.avanzar_tiempo(1.0)
	var plc: SimPLC = sim.componente("PLC")
	return A.primero([
		A.cierto(parado, "la seta de emergencia para el motor"),
		A.cierto(not plc.estado["alimentado"] and not _luz(sim, "H1"), "SYSTEM POWER en OFF deja el panel sin alimentación"),
	])
