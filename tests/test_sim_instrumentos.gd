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
