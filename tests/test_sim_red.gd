extends RefCounted
## Solver y red: ley de Ohm, tensiones de línea y fase, red aislada.

const A := preload("res://tests/ayuda_sim.gd")


func test_tension_de_linea_y_de_fase() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.paso()
	var linea := sim.solucion.entre("B.L1", "B.L2").modulo()
	var fase := sim.solucion.entre("B.L1", "B.N").modulo()
	return A.primero([
		A.cerca(linea, 380.0, 0.001, "tensión de línea"),
		A.cerca(fase, 380.0 / sqrt(3.0), 0.001, "tensión de fase"),
	])


func test_ley_de_ohm() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.agregar(SimResistencia.new("R1", {"ohm": 100.0}))
	sim.conectar("B.L1", "R1.A")
	sim.conectar("B.L2", "R1.B")
	sim.paso()
	var v := sim.solucion.entre("R1.A", "R1.B").modulo()
	return A.cerca(v / 100.0, 3.8, 0.01, "corriente I = V / R")


func test_serie_reparte_la_tension() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.agregar(SimResistencia.new("R1", {"ohm": 100.0}))
	sim.agregar(SimResistencia.new("R2", {"ohm": 300.0}))
	sim.conectar("B.L1", "R1.A")
	sim.conectar("R1.B", "R2.A")
	sim.conectar("R2.B", "B.L2")
	sim.paso()
	return A.cerca(sim.solucion.entre("R2.A", "R2.B").modulo(), 285.0, 0.01, "tensión en R2")


func test_primera_falla_a_tierra_no_dispara() -> String:
	var sim := A.circuito("arranque_directo")
	sim.componente("Q1").accionar(true)
	sim.paso()
	var antes := sim.solucion.entre("B.L2", SimSolver.TIERRA).modulo()
	sim.conectar("B.L1", SimSolver.TIERRA)
	sim.avanzar_tiempo(1.0)
	var despues := sim.solucion.entre("B.L2", SimSolver.TIERRA).modulo()
	return A.primero([
		A.cierto(sim.componente("Q1").cerrado(), "la primera falla a tierra no debe disparar"),
		A.cerca(antes, 219.4, 0.01, "L2 a tierra antes de la falla"),
		A.cerca(despues, 380.0, 0.01, "L2 a tierra sube a tensión de línea"),
	])


func test_guardar_y_cargar_conserva_daños() -> String:
	var sim := A.banco_motor(A.PLACA_380D, "delta", 29.5)
	sim.componente("M1").estado["quemado"] = true
	sim.componente("F2").estado["disparado"] = true
	var texto := JSON.stringify(sim.a_dict())
	var copia := SimSimulacion.desde_dict(JSON.parse_string(texto))
	copia.paso()
	return A.primero([
		A.cierto(copia.componente("M1").quemado(), "el motor debe seguir quemado"),
		A.cierto(copia.componente("F2").estado["disparado"], "el relé debe seguir disparado"),
		A.cierto(copia.cables.size() == sim.cables.size(), "deben conservarse los cables"),
	])
