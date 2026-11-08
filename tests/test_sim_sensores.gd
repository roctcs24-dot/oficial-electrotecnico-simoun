extends RefCounted
## Banco de sensores y PLC: tipo de sensor frente al tipo de entrada, común 1M y salidas.

const A := preload("res://tests/ayuda_sim.gd")


func _banco() -> SimSimulacion:
	var c := Contenido.new()
	var sim := c.circuito("banco_sensores")
	sim.avanzar_tiempo(0.3)
	return sim


func _acercar(sim: SimSimulacion, objeto: bool) -> void:
	for id in ["B1", "B2"]:
		sim.componente(id).estado["objeto"] = objeto
	sim.avanzar_tiempo(0.3)


func test_pnp_activa_su_entrada_y_su_luz() -> String:
	var sim := _banco()
	var plc: SimPLC = sim.componente("PLC")
	var reposo: bool = not plc.entrada_activa(0) and not sim.componente("H1").estado["encendida"]
	_acercar(sim, true)
	var v_salida := sim.componente("B1").tension_dc(sim.solucion, "BK", "BU")
	return A.primero([
		A.cierto(reposo, "sin pieza delante, I0.0 y H1 apagadas"),
		A.cierto(plc.entrada_activa(0), "con la pieza delante, el PNP activa I0.0"),
		A.cierto(sim.componente("H1").estado["encendida"], "Q0.0 repite I0.0 y enciende H1"),
		A.cerca(v_salida, 24.0, 2.0, "la salida del PNP da el + respecto al azul"),
	])


func test_npn_no_activa_una_entrada_pnp() -> String:
	var sim := _banco()
	_acercar(sim, true)
	var b2: SimSensorProximidad = sim.componente("B2")
	return A.primero([
		A.cierto(b2.estado["activa"], "el NPN conmuta: su LED se enciende"),
		A.cierto(not (sim.componente("PLC") as SimPLC).entrada_activa(1), "pero la entrada PNP con 1M al − no ve el − del NPN"),
		A.cierto(not sim.componente("H2").estado["encendida"], "H2 sigue apagada"),
	])


func test_con_entradas_npn_y_1m_al_mas_funciona_el_npn() -> String:
	var sim := _banco()
	var plc: SimPLC = sim.componente("PLC")
	plc.params["entradas"] = "npn"
	sim.desconectar("PLC.1M", "G1.-")
	sim.conectar("PLC.1M", "G1.+")
	_acercar(sim, true)
	return A.primero([
		A.cierto(plc.entrada_activa(1), "con 1M al + el NPN activa I0.1"),
		A.cierto(sim.componente("H2").estado["encendida"], "H2 repite I0.1"),
		A.cierto(not plc.entrada_activa(0), "ahora el PNP es el que no activa su entrada"),
	])


func test_el_cajon_del_taller_trae_sensores_fuente_rele_y_plc() -> String:
	var mesa := MesaTaller.new(Contenido.new())
	mesa.cargar_plantilla("banco_sensores")
	var tipos := {}
	for id: String in mesa.piezas:
		tipos[mesa.piezas[id]["tipo"]] = true
	var plc := mesa.agregar("plc", Vector2(0, 900))
	var programa: Array = mesa.sim.componente(plc).params["programa"]
	return A.primero([
		A.cierto(tipos.has("sensor_pnp") and tipos.has("sensor_npn"), "la plantilla usa las piezas de sensor: %s" % str(tipos.keys())),
		A.cierto(tipos.has("fuente_dc") and tipos.has("plc") and tipos.has("lampara_24"), "y la fuente, el PLC y las luces de 24 V: %s" % str(tipos.keys())),
		A.cierto(not programa.is_empty(), "un PLC sacado del cajón llega con su programa de prueba"),
		A.cierto(not mesa.estado_pieza("PLC").is_empty(), "el PLC informa su estado"),
	])


func test_el_taller_del_sistema_6_ofrece_las_practicas() -> String:
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = "user://pruebas_sensores.json"
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("sistema", {"id": 6})
	raiz.pantalla_actual()._abrir_modo("taller")
	var textos: Array[String] = []
	_textos(raiz.pantalla_actual(), textos)
	raiz.ir_a("taller", {"plantilla": "banco_sensores"})
	var piezas: int = raiz.pantalla_actual().mesa.piezas.size()
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Sensores PNP y NPN con PLC"), "debe ofrecer el banco de sensores: %s" % str(textos)),
		A.cierto(textos.has("PLC: bomba de achique de sentina"), "debe ofrecer el PLC"),
		A.cierto(piezas == 6, "el Taller abre con la plantilla montada: %d piezas" % piezas),
	])


func _textos(nodo: Node, lista: Array[String]) -> void:
	if nodo is Label or nodo is Button:
		lista.append(nodo.text)
	for hijo in nodo.get_children():
		_textos(hijo, lista)
