extends RefCounted
## Autómata programable: intérprete ladder, tarjetas de entradas y salidas, entrada analógica
## y el circuito de ejemplo de la bomba de achique.

const A := preload("res://tests/ayuda_sim.gd")


# --- Intérprete ladder ---

func _scan(programa: Array, mem: Dictionary, bits := {}, dt := 0.05) -> void:
	mem["bits"].merge(bits, true)
	SimLadder.ejecutar(programa, mem, dt)


func test_marcha_con_retencion_y_parada() -> String:
	var programa := [{"logica": [{"paralelo": [[{"na": "%I0.0"}], [{"na": "%Q0.0"}]]}, {"nc": "%I0.1"}], "salidas": [{"bobina": "%Q0.0"}]}]
	var mem := SimLadder.memoria()
	_scan(programa, mem)
	var reposo := SimLadder.bit(mem, "%Q0.0")
	_scan(programa, mem, {"%I0.0": true})
	_scan(programa, mem, {"%I0.0": false})
	var retenida := SimLadder.bit(mem, "%Q0.0")
	_scan(programa, mem, {"%I0.1": true})
	var parada := SimLadder.bit(mem, "%Q0.0")
	return A.primero([
		A.cierto(not reposo, "en reposo la salida está a 0"),
		A.cierto(retenida, "tras soltar marcha, la retención la mantiene"),
		A.cierto(not parada, "la parada la suelta"),
	])


func test_set_y_reset() -> String:
	var programa := [
		{"logica": [{"na": "%I0.0"}], "salidas": [{"set": "%M0.0"}]},
		{"logica": [{"na": "%I0.1"}], "salidas": [{"reset": "%M0.0"}]},
	]
	var mem := SimLadder.memoria()
	_scan(programa, mem, {"%I0.0": true})
	_scan(programa, mem, {"%I0.0": false})
	var puesta := SimLadder.bit(mem, "%M0.0")
	_scan(programa, mem, {"%I0.1": true})
	return A.cierto(puesta and not SimLadder.bit(mem, "%M0.0"), "set la pone y se queda; reset la quita")


func test_temporizador_a_la_conexion() -> String:
	var programa := [{"logica": [{"na": "%I0.0"}], "salidas": [{"ton": "%T0", "ms": 3000}]}]
	var mem := SimLadder.memoria()
	for _i in 58:
		_scan(programa, mem, {"%I0.0": true})
	var antes := SimLadder.bit(mem, "%T0")
	for _i in 2:
		_scan(programa, mem, {"%I0.0": true})
	var cumplido := SimLadder.bit(mem, "%T0")
	_scan(programa, mem, {"%I0.0": false})
	return A.primero([
		A.cierto(not antes, "a los 2,9 s todavía no"),
		A.cierto(cumplido, "a los 3 s se activa"),
		A.cierto(not SimLadder.bit(mem, "%T0") and mem["temporizadores"]["%T0"]["acc_ms"] == 0.0, "sin entrada se repone"),
	])


func test_temporizador_a_la_desconexion() -> String:
	var programa := [{"logica": [{"na": "%I0.0"}], "salidas": [{"tof": "%T1", "ms": 1000}]}]
	var mem := SimLadder.memoria()
	_scan(programa, mem, {"%I0.0": true})
	var activo := SimLadder.bit(mem, "%T1")
	for _i in 10:
		_scan(programa, mem, {"%I0.0": false})
	var mantiene := SimLadder.bit(mem, "%T1")
	for _i in 10:
		_scan(programa, mem, {"%I0.0": false})
	return A.primero([
		A.cierto(activo, "con entrada se activa en el acto"),
		A.cierto(mantiene, "a los 0,5 s de quitarla sigue activo"),
		A.cierto(not SimLadder.bit(mem, "%T1"), "al cumplir 1 s se desactiva"),
	])


func test_contador_con_flanco_y_reposicion() -> String:
	var programa := [
		{"logica": [{"flanco": "%I0.0"}], "salidas": [{"ctu": "%C0", "pv": 3}]},
		{"logica": [{"na": "%I0.1"}], "salidas": [{"rst": "%C0"}]},
	]
	var mem := SimLadder.memoria()
	for _i in 3:
		for _j in 4:
			_scan(programa, mem, {"%I0.0": true})
		_scan(programa, mem, {"%I0.0": false})
	var cuenta: int = mem["contadores"]["%C0"]["cv"]
	var hecho := SimLadder.bit(mem, "%C0")
	_scan(programa, mem, {"%I0.1": true})
	return A.primero([
		A.cierto(cuenta == 3, "cada pulsación cuenta una vez aunque dure varios scans: %d" % cuenta),
		A.cierto(hecho, "al llegar al preajuste se activa"),
		A.cierto(not SimLadder.bit(mem, "%C0") and int(mem["contadores"]["%C0"]["cv"]) == 0, "la reposición vuelve a cero"),
	])


func test_comparacion_de_una_palabra() -> String:
	var programa := [{"logica": [{"cmp": ">=", "a": "%IW0", "b": 8.0}], "salidas": [{"bobina": "%Q0.0"}]}]
	var mem := SimLadder.memoria()
	mem["palabras"]["%IW0"] = 7.9
	_scan(programa, mem)
	var bajo := SimLadder.bit(mem, "%Q0.0")
	mem["palabras"]["%IW0"] = 8.0
	_scan(programa, mem)
	return A.cierto(not bajo and SimLadder.bit(mem, "%Q0.0"), "debe comparar la palabra con el número")


func test_direcciones_del_programa() -> String:
	var programa: Array = Contenido.new().plc("bomba_achique")["programa"]
	var lista := SimLadder.direcciones(programa)
	var etiquetas: Dictionary = Contenido.new().plc("bomba_achique")["etiquetas"]
	for d: String in lista:
		if not etiquetas.has(d):
			return "la dirección %s no tiene etiqueta" % d
	return A.cierto(lista.has("%IW0") and lista.has("%C0") and lista.has("%Q0.3"), "debe listar todas: %s" % str(lista))


# --- El PLC en su circuito ---

func _bomba() -> SimSimulacion:
	var sim := Contenido.new().circuito("plc_bomba_achique")
	sim.avanzar_tiempo(0.2)
	return sim


func _pulsar(sim: SimSimulacion, id: String, segundos := 0.3) -> void:
	sim.componente(id).estado["presionado"] = true
	sim.avanzar_tiempo(segundos)
	sim.componente(id).estado["presionado"] = false
	sim.avanzar_tiempo(0.2)


func _encendida(sim: SimSimulacion, id: String) -> bool:
	return sim.componente(id).estado["encendida"]


func test_marcha_y_parada_desde_los_pulsadores() -> String:
	var sim := _bomba()
	var plc: SimPLC = sim.componente("PLC")
	var k1: SimReleDC = sim.componente("K1")
	var en_reposo: bool = plc.en_marcha() and plc.entrada_activa(1) and plc.entrada_activa(2) and not plc.entrada_activa(0)
	_pulsar(sim, "S1")
	var arranca: bool = plc.salida_activa(0) and k1.estado["energizado"]
	sim.avanzar_tiempo(1.0)
	var sigue: bool = k1.estado["energizado"]
	_pulsar(sim, "S0")
	return A.primero([
		A.cierto(en_reposo, "en reposo: PLC en RUN, parada y térmico (NC) dan señal, marcha no"),
		A.cierto(arranca, "marcha arranca la bomba por Q0.0 y K1"),
		A.cierto(sigue, "al soltar marcha sigue en marcha"),
		A.cierto(not k1.estado["energizado"], "parada la detiene"),
	])


func test_arranque_por_nivel_con_retardo() -> String:
	var sim := _bomba()
	var plc: SimPLC = sim.componente("PLC")
	sim.componente("B1").estado["objeto"] = true
	sim.avanzar_tiempo(2.0)
	var a_los_2: bool = plc.salida_activa(0)
	sim.avanzar_tiempo(1.5)
	var a_los_3: bool = plc.salida_activa(0)
	sim.componente("B1").estado["objeto"] = false
	sim.avanzar_tiempo(0.3)
	return A.primero([
		A.cierto(plc.entrada_activa(3) == false and not a_los_2, "a los 2 s de nivel alto todavía no arranca"),
		A.cierto(a_los_3, "pasados 3 s arranca"),
		A.cierto(not plc.salida_activa(0), "sin nivel alto se para"),
	])


func test_disparo_del_termico_para_y_avisa() -> String:
	var sim := _bomba()
	_pulsar(sim, "S1")
	sim.componente("F2").estado["presionado"] = true
	sim.avanzar_tiempo(0.3)
	var plc: SimPLC = sim.componente("PLC")
	return A.primero([
		A.cierto(not plc.salida_activa(0), "con el térmico disparado la bomba para"),
		A.cierto(_encendida(sim, "H1"), "se enciende la luz de disparo"),
	])


func test_presion_alta_y_lazo_abierto_por_la_entrada_analogica() -> String:
	var sim := _bomba()
	var plc: SimPLC = sim.componente("PLC")
	var normal: float = plc.estado["palabras"]["%IW0"]
	var sin_alarma := not _encendida(sim, "H2")
	sim.componente("PT1").params["valor"] = 9.0
	sim.avanzar_tiempo(0.2)
	var alta := _encendida(sim, "H2")
	sim.componente("PT1").params["valor"] = 3.0
	sim.componente("PT1").params["averia"] = "abierto"
	sim.avanzar_tiempo(0.2)
	return A.primero([
		A.cerca(normal, 3.0, 0.01, "el PLC lee 3 bar en %IW0"),
		A.cierto(sin_alarma, "con 3 bar no hay alarma"),
		A.cierto(alta, "con 9 bar se enciende H2"),
		A.cierto(plc.bit("%AE0") and _encendida(sim, "H2"), "con el lazo abierto marca error y avisa"),
	])


func test_contador_de_arranques() -> String:
	var sim := _bomba()
	for _i in 5:
		_pulsar(sim, "S1")
		_pulsar(sim, "S0")
	var aviso := _encendida(sim, "H3")
	_pulsar(sim, "S2")
	return A.primero([
		A.cierto(aviso, "a los 5 arranques pide revisión"),
		A.cierto(not _encendida(sim, "H3"), "S2 repone el contador"),
	])


func test_sin_alimentacion_o_en_stop_las_salidas_se_abren() -> String:
	var sim := _bomba()
	var plc: SimPLC = sim.componente("PLC")
	_pulsar(sim, "S1")
	plc.cambiar_modo("STOP")
	sim.avanzar_tiempo(0.2)
	var en_stop: bool = sim.componente("K1").estado["energizado"]
	plc.cambiar_modo("RUN")
	(sim.componente("F") as SimFuenteDC).params["tension_pu"] = 0.7
	sim.avanzar_tiempo(0.2)
	return A.primero([
		A.cierto(not en_stop, "en STOP la salida se abre"),
		A.cierto(not plc.estado["alimentado"] and not sim.componente("K1").estado["energizado"], "con 16,8 V el PLC no funciona"),
	])


## PLC con entradas para NPN: el común 1M al +, y el sensor NPN cierra la entrada al −.
func _con_entrada_npn(salida_sensor: String) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimPLC.new("PLC", {"entradas": "npn", "programa": [{"logica": [{"na": "%I0.0"}], "salidas": [{"bobina": "%M0.0"}]}]}))
	sim.agregar(SimSensorProximidad.new("B", {"salida": salida_sensor}, {"objeto": true}))
	for par in [["F.+", "PLC.L+"], ["F.-", "PLC.M"], ["F.+", "PLC.1M"], ["F.+", "B.BN"], ["B.BU", "F.-"], ["B.BK", "PLC.I0.0"]]:
		sim.conectar(par[0], par[1])
	sim.avanzar_tiempo(0.2)
	return sim


func test_entradas_npn_con_sensor_npn_y_con_pnp() -> String:
	var bien := _con_entrada_npn("npn")
	var mal := _con_entrada_npn("pnp")
	return A.primero([
		A.cierto((bien.componente("PLC") as SimPLC).entrada_activa(0), "el sensor NPN activa una entrada NPN"),
		A.cierto(not (mal.componente("PLC") as SimPLC).entrada_activa(0), "un sensor PNP no activa una entrada NPN"),
	])


func test_salida_a_transistor_da_el_positivo() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimPLC.new("PLC", {"salidas": "transistor", "programa": [{"logica": [], "salidas": [{"bobina": "%Q0.0"}]}]}))
	sim.agregar(SimLampara.new("H", {"v_nominal": 24.0, "r": 480.0}))
	for par in [["F.+", "PLC.L+"], ["F.-", "PLC.M"], ["PLC.Q0.0", "H.X1"], ["H.X2", "F.-"]]:
		sim.conectar(par[0], par[1])
	sim.avanzar_tiempo(0.2)
	return A.cierto(sim.componente("H").estado["encendida"], "la salida a transistor alimenta la luz desde L+")


# --- Editor ---

func _programa_simple() -> Array:
	return [{"logica": [{"na": "%I0.0"}, {"nc": "%I0.1"}], "salidas": [{"bobina": "%Q0.0"}]}]


func test_editor_serie_paralelo_y_borrado() -> String:
	var p := _programa_simple()
	EditorLadder.agregar_paralelo(p, [0, "logica", 0])
	var envuelto := EditorLadder.tipo(EditorLadder.obtener(p, [0, "logica", 0])) == "paralelo"
	var rama := EditorLadder.obtener(p, [0, "logica", 0, 1, 0])
	EditorLadder.agregar_en_serie(p, [0, "logica", 0, 1, 0])
	var en_serie := EditorLadder.obtener(p, [0, "logica", 0, 1, 1])
	EditorLadder.borrar(p, [0, "logica", 0, 1, 1])
	EditorLadder.borrar(p, [0, "logica", 0, 1, 0])
	var deshecho: Dictionary = p[0]["logica"][0]
	return A.primero([
		A.cierto(envuelto and rama == {"na": "%M0.0"}, "el paralelo debe tener el contacto y uno nuevo: %s" % str(p)),
		A.cierto(en_serie == {"na": "%I0.0"}, "debe añadir en serie dentro de la rama"),
		A.cierto(deshecho == {"na": "%I0.0"} and p[0]["logica"].size() == 2, "con una sola rama el paralelo se deshace: %s" % str(p)),
	])


func test_editor_cambia_tipo_direccion_y_valor() -> String:
	var p := _programa_simple()
	EditorLadder.cambiar_tipo(p, [0, "logica", 0], "nc")
	var nc := EditorLadder.obtener(p, [0, "logica", 0]) == {"nc": "%I0.0"}
	EditorLadder.mover_direccion(p, [0, "logica", 0], -1)
	var anterior := EditorLadder.direccion(EditorLadder.obtener(p, [0, "logica", 0]))
	EditorLadder.cambiar_tipo(p, [0, "salidas", 0], "ton")
	EditorLadder.ajustar_valor(p, [0, "salidas", 0], 2)
	var t := EditorLadder.obtener(p, [0, "salidas", 0])
	return A.primero([
		A.cierto(nc, "debe pasar a NC conservando la dirección"),
		A.cierto(anterior == "%AE0", "antes de la primera dirección viene la última: %s" % anterior),
		A.cierto(t.get("ton", "") == "%T0" and is_equal_approx(float(t["ms"]), 4000.0), "TON con su temporizador y 4 s: %s" % str(t)),
	])


func _raiz() -> Raiz:
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = "user://pruebas_plc.json"
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("plc")
	return raiz


func test_pantalla_edita_y_transfiere_en_stop() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	p._elegir_pestana("programa")
	p._seleccionar([3, "logica", 0])
	p._editar(EditorLadder.cambiar_tipo.bind([3, "logica", 0], "na"))
	var pendiente: bool = p.modificado()
	p._transferir()
	var en_run: bool = p.modificado()
	p._alternar_modo()
	p._transferir()
	var transferido: bool = not p.modificado() and p.plc.params["programa"][3]["logica"][0] == {"na": "%I0.2"}
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var conserva: bool = q.sim == p.sim
	raiz.free()
	return A.primero([
		A.cierto(pendiente, "el cambio queda en el borrador"),
		A.cierto(en_run, "en RUN no se transfiere"),
		A.cierto(transferido, "en STOP se transfiere"),
		A.cierto(conserva, "girar el celular conserva la práctica"),
	])


func test_pantalla_muestra_la_senal_en_el_ladder() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	p._pulsar("S1", true)
	for _i in 10:
		p._process(0.05)
	p._pulsar("S1", false)
	p._elegir_pestana("programa")
	p._actualizar()
	var memoria: Dictionary = p._ladder.memoria
	var en_marcha: bool = p.plc.salida_activa(0)
	raiz.free()
	return A.primero([
		A.cierto(en_marcha, "pulsar S1 en la pantalla arranca la bomba"),
		A.cierto(not memoria.is_empty() and SimLadder.bit(memoria, "%Q0.0"), "el ladder recibe la memoria del PLC en RUN"),
	])


func test_cargar_programa_no_toca_el_contenido() -> String:
	var c := Contenido.new()
	var sim := c.circuito("plc_bomba_achique")
	var plc: SimPLC = sim.componente("PLC")
	plc.params["programa"][0]["salidas"][0]["bobina"] = "%M9.9"
	var otra: SimPLC = c.circuito("plc_bomba_achique").componente("PLC")
	plc.cargar_programa([])
	return A.primero([
		A.cierto(otra.params["programa"][0]["salidas"][0]["bobina"] == "%M0.0", "cambiar un PLC no debe cambiar el programa guardado"),
		A.cierto(plc.params["programa"].is_empty() and plc.estado["bits"].is_empty(), "al cargar, la memoria vuelve a cero"),
	])
