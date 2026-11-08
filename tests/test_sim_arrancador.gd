extends RefCounted
## Arrancador suave: rampa de tensión, límite de corriente, bypass, parada y fallos.

const A := preload("res://tests/ayuda_sim.gd")


func _arrancar() -> SimSimulacion:
	var sim := A.circuito("arranque_suave")
	sim.componente("Q1").accionar(true)
	sim.paso()
	A.pulsar(sim, "S1")
	return sim


## Corriente máxima de línea durante el tiempo indicado, leída en el arrancador.
func _pico(sim: SimSimulacion, segundos: float) -> float:
	var pico := 0.0
	var pasos := roundi(segundos / SimSimulacion.PASO_S)
	for _i in pasos:
		sim.paso()
		pico = maxf(pico, (sim.componente("AS1") as SimArrancadorSuave).corriente())
	return pico


func test_rampa_limita_la_corriente_y_cierra_el_bypass() -> String:
	var sim := _arrancar()
	var as1: SimArrancadorSuave = sim.componente("AS1")
	var fase_al_principio := as1.fase()
	var pico := _pico(sim, 25.0)
	var limite: float = 3.5 * 173.0
	return A.primero([
		A.cierto(fase_al_principio == "arranque", "debe empezar en rampa: %s" % fase_al_principio),
		A.cierto(pico <= limite * 1.1, "la corriente no debe pasar del límite: %.0f A" % pico),
		A.cierto(pico >= 2.0 * 173.0, "debe haber corriente de arranque: %.0f A" % pico),
		A.cierto(as1.fase() == "bypass", "al final de la rampa debe cerrar el bypass: %s" % as1.fase()),
		A.cierto(sim.componente("M1").rpm() > 1400.0, "el motor debe llegar a su velocidad: %.0f rpm" % sim.componente("M1").rpm()),
		A.cierto(sim.componente("H1").estado["encendida"], "la luz de bypass debe encender"),
		A.cierto(sim.hubo_evento("arrancador_bypass", "AS1"), "debe avisar del bypass"),
	])


func test_tension_del_motor_sube_en_rampa() -> String:
	var sim := _arrancar()
	sim.avanzar_tiempo(0.5)
	var v_inicio := sim.componente("M1").tension(sim.solucion, "U1", "V1")
	sim.avanzar_tiempo(25.0)
	var v_final := sim.componente("M1").tension(sim.solucion, "U1", "V1")
	return A.primero([
		A.cierto(v_inicio < 0.75 * 380.0, "al principio el motor debe recibir tensión reducida: %.0f V" % v_inicio),
		A.cerca(v_final, 380.0, 15.0, "en bypass el motor recibe la tensión de línea"),
	])


func test_menos_corriente_que_el_arranque_directo() -> String:
	var suave := _arrancar()
	var pico_suave := _pico(suave, 8.0)
	var directo := A.circuito("arranque_suave")
	directo.componente("AS1").params["u_inicial"] = 1.0
	directo.componente("AS1").params["limite_corriente"] = 0.0
	directo.componente("Q1").accionar(true)
	directo.paso()
	A.pulsar(directo, "S1")
	var pico_directo := _pico(directo, 8.0)
	return A.cierto(pico_suave < 0.7 * pico_directo, "el arranque suave debe pedir mucha menos corriente: %.0f A frente a %.0f A" % [pico_suave, pico_directo])


func test_paro_suelta_el_arrancador_y_el_motor_se_detiene() -> String:
	var sim := _arrancar()
	sim.avanzar_tiempo(25.0)
	A.pulsar(sim, "S0")
	sim.avanzar_tiempo(40.0)
	var as1: SimArrancadorSuave = sim.componente("AS1")
	return A.primero([
		A.cierto(as1.fase() == "listo", "sin orden debe quedar listo: %s" % as1.fase()),
		A.cierto(not sim.componente("K1").cerrado(), "K1 debe soltar"),
		A.cierto(sim.componente("M1").rpm() < 5.0, "el motor debe detenerse: %.0f rpm" % sim.componente("M1").rpm()),
	])


func test_falta_de_fase_da_fallo_y_abre_el_mando() -> String:
	var sim := _arrancar()
	sim.avanzar_tiempo(25.0)
	sim.desconectar("Q1.6", "K1.5")
	sim.avanzar_tiempo(2.0)
	var as1: SimArrancadorSuave = sim.componente("AS1")
	var en_fallo := as1.fase() == "fallo"
	var texto := as1.pantalla()[1]
	var k_abierto: bool = not sim.componente("K1").cerrado()
	var rearme := as1.rearmar()
	return A.primero([
		A.cierto(en_fallo, "sin una fase debe pasar a fallo: %s" % as1.fase()),
		A.cierto(texto.contains("fase"), "la pantalla debe indicar la falta de fase: %s" % texto),
		A.cierto(k_abierto, "el contacto 95-96 debe soltar K1"),
		A.cierto(rearme and as1.fase() == "listo", "debe poder rearmarse"),
	])


func test_arranque_que_no_termina_da_fallo_por_tiempo() -> String:
	var sim := A.circuito("arranque_suave")
	var as1: SimArrancadorSuave = sim.componente("AS1")
	as1.params["t_max_arranque_s"] = 6.0
	as1.params["rampa_s"] = 3.0
	sim.componente("M1").params["bloqueado"] = true
	sim.componente("Q1").accionar(true)
	sim.paso()
	A.pulsar(sim, "S1")
	sim.avanzar_tiempo(8.0)
	return A.primero([
		A.cierto(as1.fase() == "fallo", "con el motor bloqueado debe fallar por tiempo: %s" % as1.fase()),
		A.cierto(str(as1.estado["fallo"]).contains("Tiempo"), "el fallo debe ser por tiempo: %s" % as1.estado["fallo"]),
	])
