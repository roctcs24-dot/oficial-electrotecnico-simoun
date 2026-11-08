extends RefCounted
## Mando electrohidráulico del power block: selector, parada de emergencia, bobinas y presión.

const A := preload("res://tests/ayuda_sim.gd")


func _mando(averias := {}) -> SimSimulacion:
	var sim := Contenido.new().circuito("mando_power_block")
	sim.componente("PB").params.merge(averias, true)
	sim.avanzar_tiempo(0.5)
	return sim


func _poner(sim: SimSimulacion, posicion: String, segundos := 6.0) -> float:
	(sim.componente("S1") as SimSelector).poner(posicion)
	sim.avanzar_tiempo(segundos)
	return sim.componente("PB").estado["rpm"]


func test_virar_arriar_y_parar() -> String:
	var sim := _mando()
	var luz: bool = sim.componente("H1").estado["encendida"]
	var virando := _poner(sim, "VIRAR")
	var arriando := _poner(sim, "ARRIAR")
	var parado := _poner(sim, "0")
	return A.primero([
		A.cierto(luz, "con tensión de mando, H1 encendida"),
		A.cerca(virando, 20.0, 1.0, "VIRAR: gira hacia la recogida"),
		A.cerca(arriando, -20.0, 1.0, "ARRIAR: gira al revés"),
		A.cierto(absf(parado) < 1.0, "en 0 se para"),
	])


func test_parada_de_emergencia() -> String:
	var sim := _mando()
	_poner(sim, "VIRAR")
	(sim.componente("S0") as SimSeta).pulsar()
	sim.avanzar_tiempo(6.0)
	return A.primero([
		A.cierto(absf(sim.componente("PB").estado["rpm"]) < 1.0, "la seta quita tensión a las bobinas y para el giro"),
		A.cierto(not sim.componente("H1").estado["encendida"], "y apaga la luz de mando"),
	])


func test_averias_de_bobinas_y_presion() -> String:
	var cortada := _mando({"averia_y1": "abierta"})
	var en_corto := _mando({"averia_y2": "corto"})
	var sin_presion := _mando({"presion": false})
	var vira_cortada := _poner(cortada, "VIRAR")
	var arria_cortada := _poner(cortada, "ARRIAR")
	_poner(en_corto, "ARRIAR", 2.0)
	var fuente: SimFuenteDC = en_corto.componente("G1")
	return A.primero([
		A.cierto(absf(vira_cortada) < 1.0, "con Y1 cortada no vira"),
		A.cerca(arria_cortada, -20.0, 1.0, "pero arría"),
		A.cierto(not fuente.activa(), "Y2 en corto sobrecarga la fuente de 24 V, que se protege"),
		A.cierto(not en_corto.componente("H1").estado["encendida"], "y se apaga la luz de mando"),
		A.cierto(absf(_poner(sin_presion, "VIRAR")) < 1.0, "sin presión de la central no gira"),
	])
