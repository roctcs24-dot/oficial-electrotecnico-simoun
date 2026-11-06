extends RefCounted
## Multímetro y megóhmetro, incluidas las consecuencias de usarlos mal.

const A := preload("res://tests/ayuda_sim.gd")


func _multimetro() -> SimMultimetro:
	var m := SimMultimetro.new()
	m.ruido = 0.0
	return m


func _megohmetro() -> SimMegohmetro:
	var m := SimMegohmetro.new()
	m.ruido = 0.0
	return m


## Motor en estrella, aislado de la alimentación por Q1 abierto.
func _motor_aislado(extra := {}) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.agregar(SimGuardamotor.new("Q1"))
	var p := A.PLACA_440D.duplicate()
	p.merge(extra, true)
	sim.agregar(SimMotorTrifasico.new("M1", p))
	for par in [["B.L1", "Q1.1"], ["B.L2", "Q1.3"], ["B.L3", "Q1.5"], ["Q1.2", "M1.U1"], ["Q1.4", "M1.V1"], ["Q1.6", "M1.W1"]]:
		sim.conectar(par[0], par[1])
	sim.conectar("M1.U2", "M1.V2")
	sim.conectar("M1.V2", "M1.W2")
	sim.paso()
	return sim


func test_voltimetro_lee_linea_y_nada_en_flotante() -> String:
	var sim := _motor_aislado()
	var m := _multimetro()
	var linea := m.medir(sim, "vac", "B.L1", "B.L2")
	var abierto := m.medir(sim, "vac", "Q1.1", "Q1.2")
	var flotante := m.medir(sim, "vac", "M1.U1", "M1.V1")
	# Sin retorno, la entrada de 10 MΩ queda en serie con los 100 MΩ de aislamiento del motor.
	return A.primero([
		A.cerca(linea["valor"], 440.0, 0.01, "tensión de línea"),
		A.cerca(abierto["valor"], 254.0 * 10.0 / 110.0, 0.1, "polo abierto sin retorno"),
		A.cierto(flotante["valor"] < 5.0, "un motor desconectado no debe mostrar tensión: %.1f V" % flotante["valor"]),
	])


func test_voltimetro_en_polo_abierto_con_retorno() -> String:
	var sim := _motor_aislado()
	sim.conectar("B.L2", "M1.V1")
	sim.conectar("B.L3", "M1.W1")
	sim.paso()
	var abierto := _multimetro().medir(sim, "vac", "Q1.1", "Q1.2")
	# El punto estrella queda en la mitad de L2-L3: 1,5 veces la tensión de fase.
	return A.cerca(abierto["valor"], 254.0 * 1.5, 0.02, "polo abierto con retorno por el motor")


func test_ohmetro_lee_el_devanado_y_detecta_abierto() -> String:
	var sim := _motor_aislado()
	var m := _multimetro()
	var motor: SimMotorTrifasico = sim.componente("M1")
	var lectura := m.medir(sim, "ohm", "M1.U1", "M1.V1")
	var abierto := m.medir(sim, "ohm", "M1.U1", SimSolver.TIERRA)
	var continuidad := m.medir(sim, "continuidad", "M1.U1", "M1.U2")
	return A.primero([
		A.cerca(lectura["valor"], motor.resistencia_devanado() * 2.0, 0.02, "dos devanados en serie"),
		A.cierto(abierto["fuera_de_rango"], "aislado a tierra debe mostrar fuera de rango"),
		A.cierto(continuidad["pita"], "un devanado sano debe pitar"),
	])


func test_ohmetro_con_tension_se_destruye() -> String:
	var sim := _motor_aislado()
	var m := _multimetro()
	var lectura := m.medir(sim, "ohm", "B.L1", "B.L2")
	var despues := m.medir(sim, "vac", "B.L1", "B.L2")
	return A.primero([
		A.cierto(lectura["averia"] == "multimetro_destruido", "440 V en ohmios destruye el equipo"),
		A.cierto(despues["averia"] == "multimetro_destruido", "sigue dañado"),
		A.cierto(sim.hubo_evento("multimetro_destruido"), "debe quedar registrado"),
	])


func test_amperimetro_en_paralelo_quema_el_fusible() -> String:
	var sim := _motor_aislado()
	var m := _multimetro()
	var lectura := m.medir(sim, "a", "B.L1", "B.L2")
	var sigue := m.medir(sim, "a", "B.L1", "B.L2")
	m.cambiar_fusible()
	return A.primero([
		A.cierto(lectura["averia"] == "fusible_multimetro", "en paralelo debe quemar el fusible"),
		A.cierto(sigue["averia"] == "fusible_multimetro", "no mide sin fusible"),
		A.cierto(m.fusible_ok, "cambiar el fusible lo repara"),
	])


func test_amperimetro_en_serie_lee_la_corriente() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.agregar(SimResistencia.new("R1", {"ohm": 100.0}))
	sim.conectar("B.L1", "R1.A")
	sim.paso()
	var lectura := _multimetro().medir(sim, "a", "R1.B", "B.L2")
	return A.cerca(lectura["valor"], 4.4, 0.01, "corriente en serie")


func test_modo_diodo() -> String:
	var sim := _motor_aislado()
	var bobina := SimSimulacion.new()
	bobina.agregar(SimResistencia.new("R1", {"ohm": 360.0}))
	bobina.paso()
	var devanado := _multimetro().medir(sim, "diodo", "M1.U1", "M1.U2")
	var resistencia := _multimetro().medir(bobina, "diodo", "R1.A", "R1.B")
	var abierto := _multimetro().medir(bobina, "diodo", "R1.A", SimSolver.TIERRA)
	var m := _multimetro()
	var con_tension := m.medir(sim, "diodo", "B.L1", "B.L2")
	return A.primero([
		A.cierto(devanado["unidad"] == "V" and float(devanado["valor"]) < 0.01, "un devanado casi no da caída: %s" % str(devanado)),
		A.cerca(resistencia["valor"], 0.36, 0.02, "360 Ω con 1 mA"),
		A.cierto(abierto["fuera_de_rango"], "abierto debe marcar OL"),
		A.cierto(not con_tension["averia"].is_empty(), "con tensión debe dañarse como el óhmetro"),
	])


## Una fase perdida a la salida del contactor, con el motor conectado: el caso del examen.
func test_falta_de_fase_a_la_salida_del_contactor() -> String:
	var sim := A.circuito("arranque_directo")
	sim.componente("K1").params["r_contacto"] = [0.0, 0.0, 1e9]
	sim.componente("Q1").accionar(true)
	sim.avanzar_tiempo(0.1)
	sim.componente("S1").estado["presionado"] = true
	sim.avanzar_tiempo(1.0)
	var m := _multimetro()
	var sana: float = m.medir(sim, "vac", "K1.2", "K1.4")["valor"]
	var otra: float = m.medir(sim, "vac", "K1.4", "K1.6")["valor"]
	return A.primero([
		A.cierto(sana > 400.0, "la fase sana: %.0f V" % sana),
		A.cerca(otra, 220.0, 0.1, "con la fase perdida"),
		A.cierto(absf(sim.componente("M1").rpm()) < 5.0, "parado no arranca"),
	])


func test_megohmetro_motor_sano() -> String:
	var sim := _motor_aislado()
	var lectura := _megohmetro().medir(sim, "M1.U1", SimSolver.TIERRA, 500)
	return A.primero([
		A.cerca(lectura["mohm"], 100.0, 0.1, "tres devanados en paralelo a tierra"),
		A.cierto(lectura["aceptable"], "debe ser aceptable"),
	])


func test_megohmetro_detecta_bajo_aislamiento() -> String:
	var sim := _motor_aislado({"aislamiento_mohm": [300.0, 0.3, 300.0]})
	var lectura := _megohmetro().medir(sim, "M1.U1", SimSolver.TIERRA, 500)
	return A.primero([
		A.cerca(lectura["mohm"], 0.3, 0.05, "devanado con bajo aislamiento"),
		A.cierto(not lectura["aceptable"], "no debe ser aceptable"),
	])


func test_megohmetro_con_tension_se_destruye() -> String:
	var sim := _motor_aislado()
	var m := _megohmetro()
	var lectura := m.medir(sim, "B.L1", SimSolver.TIERRA, 500)
	return A.primero([
		A.cierto(lectura["averia"] == "megohmetro_destruido", "con tensión debe destruirse"),
		A.cierto(m.destruido, "queda dañado"),
	])


func test_ruido_es_pequeño_y_fluctua() -> String:
	var sim := _motor_aislado()
	var m := SimMultimetro.new()
	m.ruido = 0.01
	var a: float = m.medir(sim, "vac", "B.L1", "B.L2")["valor"]
	var b: float = m.medir(sim, "vac", "B.L1", "B.L2")["valor"]
	return A.primero([
		A.cerca(a, 440.0, 0.02, "lectura con ruido"),
		A.cierto(a != b, "dos lecturas no deben ser idénticas"),
	])


## Arranque directo con el motor en marcha y a su carga.
func _motor_en_marcha() -> SimSimulacion:
	var sim := A.circuito("arranque_directo")
	sim.componente("Q1").accionar(true)
	sim.avanzar_tiempo(0.1)
	A.pulsar(sim, "S1", 0.3)
	sim.avanzar_tiempo(4.0)
	return sim


func _indice_cable(sim: SimSimulacion, a: String, b: String) -> int:
	for i in sim.cables.size():
		if sim.cables[i][0] == a and sim.cables[i][1] == b:
			return i
	return -1


func test_pinza_mide_la_corriente_de_una_fase() -> String:
	var sim := _motor_en_marcha()
	var pinza := SimPinza.new()
	pinza.ruido = 0.0
	var rele: SimReleTermico = sim.componente("F2")
	var esperado := rele.corriente(sim.solucion, 0)
	var l1: Dictionary = pinza.medir(sim, [_indice_cable(sim, "K1.2", "F2.1")])
	return A.primero([
		A.cierto(esperado > 10.0, "el motor debe estar en marcha: %.1f A" % esperado),
		A.cerca(l1["valor"], esperado, 0.01, "la pinza en L1 marca la corriente de la fase"),
		A.cierto(not l1["fuera_de_rango"] and l1["averia"].is_empty(), "lectura válida"),
	])


func test_pinza_con_tres_fases_marca_casi_cero() -> String:
	var sim := _motor_en_marcha()
	var pinza := SimPinza.new()
	var fases := [_indice_cable(sim, "K1.2", "F2.1"), _indice_cable(sim, "K1.4", "F2.3"), _indice_cable(sim, "K1.6", "F2.5")]
	var una: float = pinza.medir(sim, [fases[0]])["valor"]
	var tres: float = pinza.medir(sim, fases)["valor"]
	return A.primero([
		A.cierto(una > 10.0, "una fase: %.1f A" % una),
		A.cierto(tres < 0.2, "las tres fases juntas deben sumar casi cero: %.2f A" % tres),
	])


## En delta, por el puente de la bornera pasa la corriente de un devanado: la de línea ÷ √3.
func test_pinza_en_el_puente_delta() -> String:
	var sim := _motor_en_marcha()
	var pinza := SimPinza.new()
	pinza.ruido = 0.0
	var linea: float = pinza.medir(sim, [_indice_cable(sim, "F2.2", "M1.U1")])["valor"]
	var puente: float = pinza.medir(sim, [_indice_cable(sim, "M1.U1", "M1.W2")])["valor"]
	return A.cerca(puente, linea / sqrt(3.0), 0.03, "corriente de devanado en el puente")


func test_pinza_no_cambia_el_circuito_ni_mide_sin_corriente() -> String:
	var sim := A.circuito("arranque_directo")
	var pinza := SimPinza.new()
	var parado: Dictionary = pinza.medir(sim, [_indice_cable(sim, "K1.2", "F2.1")])
	var vacia: Dictionary = pinza.medir(sim, [])
	var cables := sim.cables.size()
	return A.primero([
		A.cierto(parado["valor"] == 0.0, "sin tensión debe marcar cero: %.2f" % parado["valor"]),
		A.cierto(vacia["averia"] == "sin_conductor", "sin conductor no mide"),
		A.cierto(sim.cables.size() == cables, "medir no quita cables"),
	])
