extends RefCounted
## Taller: mesa, cableado, guardado, instrumentos y consecuencias.

const A := preload("res://tests/ayuda_sim.gd")
const CARPETA := "user://circuitos/"


func _mesa() -> MesaTaller:
	return MesaTaller.new(Contenido.new())


func _cables(mesa: MesaTaller, lista: Array) -> void:
	for c: Array in lista:
		mesa.conectar(c[0], c[1])


## Arranque directo montado pieza a pieza, como lo haría el jugador.
func _montar_directo(mesa: MesaTaller, motor: String, delta: bool) -> void:
	for p: Array in [["fuente_trifasica", "B1"], ["guardamotor", "Q1"], ["contactor", "K1"], ["rele_termico", "F1"], [motor, "M1"], ["transformador_mando", "T1"], ["pulsador_na", "S1"], ["pulsador_nc", "S2"]]:
		mesa.agregar(p[0], Vector2.ZERO)
	_cables(mesa, [
		["B1.L1", "Q1.1"], ["B1.L2", "Q1.3"], ["B1.L3", "Q1.5"],
		["Q1.2", "K1.1"], ["Q1.4", "K1.3"], ["Q1.6", "K1.5"],
		["K1.2", "F1.1"], ["K1.4", "F1.3"], ["K1.6", "F1.5"],
		["F1.2", "M1.U1"], ["F1.4", "M1.V1"], ["F1.6", "M1.W1"],
		["Q1.2", "T1.H1"], ["Q1.4", "T1.H2"],
		["T1.X1", "F1.95"], ["F1.96", "S2.21"], ["S2.22", "S1.13"], ["S2.22", "K1.13"],
		["S1.14", "K1.A1"], ["K1.14", "K1.A1"], ["K1.A2", "T1.X2"],
	])
	if delta:
		_cables(mesa, [["M1.U1", "M1.W2"], ["M1.V1", "M1.U2"], ["M1.W1", "M1.V2"]])
	else:
		_cables(mesa, [["M1.U2", "M1.V2"], ["M1.V2", "M1.W2"]])


func _arrancar(mesa: MesaTaller) -> void:
	mesa.sim.componente("Q1").accionar(true)
	mesa.avanzar(2)
	mesa.sim.componente("S1").estado["presionado"] = true
	mesa.avanzar(4)
	mesa.sim.componente("S1").estado["presionado"] = false


func test_todo_el_catalogo_se_puede_colocar() -> String:
	var mesa := _mesa()
	for e: Dictionary in mesa.catalogo():
		var id := mesa.agregar(e["id"], Vector2.ZERO)
		if not mesa.sim.componentes.has(id):
			return "no se creó %s" % e["id"]
		if VistaSvg.rasterizar(mesa.dibujo(e["id"])["svg"], 0.5) == null:
			return "%s no tiene dibujo" % e["id"]
		if mesa.bornes(id).is_empty():
			return "%s no tiene bornes" % e["id"]
		if mesa.estado_pieza(id).is_empty():
			return "%s no informa su estado" % e["id"]
	mesa.avanzar(1)
	return ""


func test_los_ids_no_se_repiten() -> String:
	var mesa := _mesa()
	var a := mesa.agregar("contactor", Vector2.ZERO)
	var b := mesa.agregar("contactor", Vector2.ZERO)
	mesa.quitar(a)
	var c := mesa.agregar("contactor", Vector2.ZERO)
	return A.primero([
		A.cierto(a == "K1" and b == "K2", "deben numerarse: %s %s" % [a, b]),
		A.cierto(c == "K1", "debe reutilizar el número libre: %s" % c),
	])


func test_plantillas_se_colocan_con_todos_sus_bornes() -> String:
	var mesa := _mesa()
	for p: Dictionary in mesa.contenido.leer("taller.json")["plantillas"]:
		if not mesa.cargar_plantilla(p["id"]):
			return "no carga %s" % p["id"]
		for c: Array in mesa.sim.cables:
			for nodo: String in c:
				var id := nodo.get_slice(".", 0)
				if not mesa.piezas.has(id):
					return "%s: pieza inexistente %s" % [p["id"], id]
				if not mesa.bornes(id).has(MesaTaller.borne_de(nodo)):
					return "%s: el borne %s no está en el dibujo" % [p["id"], nodo]
		mesa.avanzar(1)
	return ""


func test_cable_repetido_o_consigo_mismo() -> String:
	var mesa := _mesa()
	mesa.agregar("contactor", Vector2.ZERO)
	var primero := mesa.conectar("K1.1", "K1.3")
	var repetido := mesa.conectar("K1.3", "K1.1")
	var mismo := mesa.conectar("K1.1", "K1.1")
	return A.primero([
		A.cierto(primero, "debe crear el cable"),
		A.cierto(not repetido, "no debe repetirlo al revés"),
		A.cierto(not mismo, "no debe unir un borne consigo mismo"),
		A.cierto(mesa.sim.cables.size() == 1, "debe haber un cable"),
	])


func test_quitar_pieza_quita_sus_cables() -> String:
	var mesa := _mesa()
	mesa.agregar("contactor", Vector2.ZERO)
	mesa.agregar("lampara", Vector2.ZERO)
	mesa.conectar("K1.13", "H1.X1")
	mesa.quitar("H1")
	return A.cierto(mesa.sim.cables.is_empty(), "no deben quedar cables sueltos")


func test_tocar_bornes_y_piezas() -> String:
	var mesa := _mesa()
	mesa.agregar("contactor", Vector2(100.0, 100.0))
	var a1 := mesa.posicion_borne("K1.A1")
	var cerca := mesa.borne_en(a1 + Vector2(5.0, 5.0), 20.0)
	var lejos := mesa.borne_en(a1 + Vector2(500.0, 0.0), 20.0)
	var pieza := mesa.pieza_en(Vector2(120.0, 120.0))
	var nada := mesa.pieza_en(Vector2(-50.0, -50.0))
	return A.primero([
		A.cierto(cerca == "K1.A1", "debe encontrar el borne cercano: %s" % cerca),
		A.cierto(lejos.is_empty(), "no debe encontrar un borne lejano"),
		A.cierto(pieza == "K1", "debe encontrar la pieza"),
		A.cierto(nada.is_empty(), "fuera de la pieza no hay nada"),
	])


func test_tocar_cable() -> String:
	var mesa := _mesa()
	mesa.agregar("lampara", Vector2.ZERO)
	mesa.agregar("lampara", Vector2(1000.0, 0.0))
	mesa.conectar("H1.X1", "H2.X2")
	var mitad: Vector2 = mesa.puntos_cable(0)[6]
	return A.primero([
		A.cierto(mesa.cable_en(mitad, 10.0) == 0, "debe encontrar el cable"),
		A.cierto(mesa.cable_en(mitad + Vector2(0.0, 300.0), 10.0) == -1, "lejos no debe encontrarlo"),
	])


func _mesa_con_cable() -> MesaTaller:
	var mesa := _mesa()
	mesa.agregar("lampara", Vector2.ZERO)
	mesa.agregar("lampara", Vector2(1000.0, 300.0))
	mesa.conectar("H1.X1", "H2.X2")
	return mesa


func test_cable_en_angulos_es_rectilineo_y_se_acomoda() -> String:
	var mesa := _mesa_con_cable()
	mesa.fijar_estilo_cable(0, "angulos")
	var p := mesa.puntos_cable(0)
	var rectos := true
	for i in p.size() - 1:
		if not (is_equal_approx(p[i].x, p[i + 1].x) or is_equal_approx(p[i].y, p[i + 1].y)):
			rectos = false
	var antes := p[1].y
	mesa.mover_mango(0, mesa.mango_cable(0) + Vector2(0.0, 80.0))
	var despues := mesa.puntos_cable(0)[1].y
	return A.primero([
		A.cierto(rectos, "todos los tramos deben ser rectos"),
		A.cerca(despues - antes, 80.0, 0.01, "el canal debe seguir al mango"),
		A.cierto(mesa.puntos_cable(0)[0] == mesa.posicion_borne("H1.X1"), "debe seguir conectado al borne"),
	])


func test_mango_de_la_curva_sigue_al_dedo() -> String:
	var mesa := _mesa_con_cable()
	var destino := Vector2(500.0, 900.0)
	mesa.mover_mango(0, destino)
	var llegada := mesa.mango_cable(0)
	var p := mesa.puntos_cable(0)
	return A.primero([
		A.cierto(llegada.distance_to(destino) < 1.0, "el mango debe quedar bajo el dedo: %s" % llegada),
		A.cierto(p[0] == mesa.posicion_borne("H1.X1") and p[-1] == mesa.posicion_borne("H2.X2"), "los extremos no deben moverse"),
	])


func test_la_ruta_sigue_a_la_pieza_y_se_guarda() -> String:
	var mesa := _mesa_con_cable()
	mesa.fijar_estilo_cable(0, "angulos")
	mesa.mover_mango(0, mesa.mango_cable(0) + Vector2(0.0, 40.0))
	mesa.mover("H2", Vector2(1000.0, 500.0))
	var extremo := mesa.puntos_cable(0)[-1] == mesa.posicion_borne("H2.X2")
	var ok := mesa.guardar("prueba_rutas")
	var otra := _mesa()
	var cargado := otra.cargar("prueba_rutas")
	otra.borrar("prueba_rutas")
	return A.primero([
		A.cierto(extremo, "el cable debe seguir a la pieza"),
		A.cierto(ok and cargado, "debe guardar y cargar"),
		A.cierto(otra.ruta_cable(0)["estilo"] == "angulos", "debe conservar el estilo"),
		A.cierto(is_equal_approx(otra.ruta_cable(0)["dy"], 40.0), "debe conservar el acomodo"),
	])


func test_ordenar_cables_y_deshacer() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_380", true)
	mesa.ordenar_cables()
	var estilos := {}
	var canales := {}
	for i in mesa.sim.cables.size():
		estilos[mesa.ruta_cable(i)["estilo"]] = true
		canales[mesa.ruta_cable(i)["dy"]] = true
	mesa.ordenar_cables()
	var deshecho: bool = mesa.ruta_cable(0)["estilo"] == "curva"
	return A.primero([
		A.cierto(estilos.keys() == ["angulos"], "todos deben quedar en ángulos: %s" % str(estilos.keys())),
		A.cierto(canales.size() > 1, "deben repartirse en varios canales"),
		A.cierto(deshecho, "ordenar de nuevo debe devolver las curvas"),
	])


func test_acomodar_no_afecta_a_la_simulacion() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_380", true)
	mesa.ordenar_cables()
	mesa.fijar_estilo_cable(0, "recta")
	_arrancar(mesa)
	mesa.avanzar(200)
	return A.cierto(mesa.sim.componente("M1").rpm() > 1400.0, "el circuito debe funcionar igual")


func test_quitar_cable_borra_su_ruta() -> String:
	var mesa := _mesa_con_cable()
	mesa.fijar_estilo_cable(0, "recta")
	mesa.quitar_cable(0)
	return A.cierto(mesa.rutas.is_empty(), "no debe quedar la ruta de un cable quitado")


func test_arrastrar_el_mango_en_pantalla() -> String:
	var v := VistaMesa.new()
	v.mesa = _mesa_con_cable()
	v.zoom = 1.0
	v.origen = Vector2.ZERO
	v.cable_marcado = 0
	var inicio := v.mesa.mango_cable(0)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = inicio
	v._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = inicio + Vector2(0.0, 120.0)
	motion.relative = Vector2(0.0, 120.0)
	v._gui_input(motion)
	var final := v.mesa.mango_cable(0)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = motion.position
	var tocado := []
	v.fondo_tocado.connect(func() -> void: tocado.append(true))
	v._gui_input(release)
	var distancia := final.distance_to(motion.position)
	v.free()
	return A.primero([
		A.cierto(distancia < 1.0, "el mango debe seguir al dedo: %f" % distancia),
		A.cierto(tocado.is_empty(), "arrastrar no debe contar como toque"),
	])


func test_zoom_mantiene_el_punto_bajo_el_dedo() -> String:
	var v := VistaMesa.new()
	v.origen = Vector2(30.0, 40.0)
	v.zoom = 0.5
	var centro := Vector2(200.0, 100.0)
	var antes := v.a_mesa(centro)
	v.cambiar_zoom(1.5, centro)
	var despues := v.a_mesa(centro)
	v.cambiar_zoom(1000.0, centro)
	var tope := v.zoom
	v.free()
	return A.primero([
		A.cierto(antes.is_equal_approx(despues), "el punto debe quedar fijo: %s %s" % [antes, despues]),
		A.cierto(tope == VistaMesa.ZOOM_MAX, "debe respetar el zoom máximo"),
	])


func test_arranque_montado_a_mano_funciona() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_380", true)
	_arrancar(mesa)
	mesa.avanzar(200)
	return A.primero([
		A.cierto(mesa.sim.componente("K1").cerrado(), "K1 debe quedar enclavado"),
		A.cierto(mesa.sim.componente("M1").rpm() > 1400.0, "debe llegar a su velocidad: %.0f" % mesa.sim.componente("M1").rpm()),
		A.cierto(mesa.eventos_nuevos().is_empty(), "un montaje correcto no debe generar eventos"),
	])


func test_motor_220_en_delta_dispara_y_avisa() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_220", true)
	mesa.sim.componente("F1").params["ajuste_a"] = 43.0
	_arrancar(mesa)
	mesa.avanzar(1200)
	var tipos := []
	for e: Dictionary in mesa.eventos_nuevos():
		tipos.append(e["tipo"])
	# Con el núcleo saturado, el pico supera el umbral magnético de Q1 (13 × 32 A).
	return A.primero([
		A.cierto(tipos.has("disparo_magnetico"), "debe disparar Q1: %s" % str(tipos)),
		A.cierto(not mesa.sim.componente("K1").cerrado(), "sin mando, K1 debe soltar"),
		A.cierto(not mesa.danada("M1"), "la protección debe salvar el motor"),
	])


func test_cortocircuito_sin_protección_dispara_barras() -> String:
	var mesa := _mesa()
	mesa.agregar("fuente_trifasica", Vector2.ZERO)
	mesa.conectar("B1.L1", "B1.L2")
	mesa.avanzar(10)
	var barras := mesa.sim.componente("B1")
	return A.primero([
		A.cierto(barras.estado["disparada"], "un puente entre fases debe disparar las barras"),
		A.cierto(mesa.sim.hubo_evento("disparo_barras", "B1"), "debe avisar"),
		A.cierto(mesa.estado_pieza("B1") == "Interruptor disparado", "debe mostrar el estado"),
	])


func test_guardamotor_actua_antes_que_las_barras() -> String:
	var mesa := _mesa()
	for p in ["fuente_trifasica", "guardamotor"]:
		mesa.agregar(p, Vector2.ZERO)
	_cables(mesa, [["B1.L1", "Q1.1"], ["B1.L2", "Q1.3"], ["Q1.2", "Q1.4"]])
	mesa.sim.componente("Q1").accionar(true)
	mesa.avanzar(10)
	return A.primero([
		A.cierto(mesa.sim.hubo_evento("disparo_magnetico", "Q1"), "debe disparar Q1"),
		A.cierto(not mesa.sim.componente("B1").estado["disparada"], "las barras no deben disparar"),
	])


func test_danos_persisten_y_se_reparan() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_380", true)
	mesa.sim.componente("M1").estado["quemado"] = true
	mesa.sim.componente("K1").estado["soldado"] = true
	if not mesa.guardar("prueba_danos"):
		return "no se pudo guardar"
	var otra := _mesa()
	var cargado := otra.cargar("prueba_danos")
	otra.borrar("prueba_danos")
	var persisten := otra.danada("M1") and otra.danada("K1")
	var posicion_ok := otra.piezas.has("Q1")
	otra.reparar("M1")
	return A.primero([
		A.cierto(cargado, "debe cargar"),
		A.cierto(persisten, "los daños deben seguir tras guardar y cargar"),
		A.cierto(posicion_ok, "debe conservar las piezas"),
		A.cierto(otra.sim.cables.size() == mesa.sim.cables.size(), "debe conservar los cables"),
		A.cierto(not otra.danada("M1"), "el repuesto debe quedar sano"),
		A.cierto(otra.danada("K1"), "reparar uno no repara los demás"),
	])


func test_archivo_danado_no_cambia_la_mesa() -> String:
	var mesa := _mesa()
	mesa.agregar("contactor", Vector2.ZERO)
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var f := FileAccess.open(CARPETA + "dañado.json", FileAccess.WRITE)
	f.store_string("{ no es json")
	f.close()
	var cargado := mesa.cargar("dañado")
	mesa.borrar("dañado")
	var malo := mesa.desde_dict({"piezas": {"X1": {"tipo": "inexistente"}}, "circuito": {}})
	return A.primero([
		A.cierto(not cargado, "no debe cargar un JSON dañado"),
		A.cierto(not malo, "no debe aceptar una pieza desconocida"),
		A.cierto(mesa.piezas.has("K1"), "la mesa debe seguir igual"),
	])


func test_instrumentos_sobre_la_mesa() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_380", true)
	mesa.avanzar(2)
	var m := SimMultimetro.new()
	m.ruido = 0.0
	var v: Dictionary = m.medir(mesa.sim, "vac", "B1.L1", "B1.L2")
	var r: Dictionary = m.medir(mesa.sim, "ohm", "M1.U1", "M1.U2")
	var meg := SimMegohmetro.new()
	var aislamiento: Dictionary = meg.medir(mesa.sim, "M1.U1", SimSolver.TIERRA, 500)
	var destruido: Dictionary = m.medir(mesa.sim, "ohm", "B1.L1", "B1.L2")
	return A.primero([
		A.cerca(v["valor"], 380.0, 0.01, "tensión de línea"),
		A.cierto(float(r["valor"]) < 5.0, "devanado en delta: valor bajo, %.2f" % r["valor"]),
		A.cierto(aislamiento["aceptable"], "aislamiento sano"),
		A.cierto(destruido["averia"] == "multimetro_destruido", "ohmios con tensión debe destruirlo"),
		A.cierto(mesa.sim.hubo_evento("multimetro_destruido"), "debe generar el aviso"),
	])


func test_las_consecuencias_se_ven_en_la_mesa() -> String:
	var raiz := _raiz_taller()
	var p = raiz.pantalla_actual()
	p.mesa.vaciar()
	p.mesa.agregar("fuente_trifasica", Vector2.ZERO)
	p.mesa.conectar("B1.L1", "B1.L2")
	p.mesa.avanzar(10)
	p._revisar_eventos()
	var arco: bool = p.vista.efectos.size() == 1 and p.vista.efectos[0]["tipo"] == "arco"
	var sin_pieza: bool = not p.vista.mostrar_evento("motor_quemado", "M9")
	p.vista._process(5.0)
	var termina: bool = p.vista.efectos.is_empty()
	raiz.free()
	return A.primero([
		A.cierto(arco, "un cortocircuito debe mostrar el arco"),
		A.cierto(sin_pieza, "sin pieza no hay efecto"),
		A.cierto(termina, "el efecto debe terminar"),
	])


func test_todas_las_consecuencias_tienen_explicacion() -> String:
	var textos: Dictionary = Contenido.new().leer("taller.json")["consecuencias"]
	for e in ["disparo_magnetico", "disparo_termico", "disparo_rele_termico", "disparo_barras", "arco_contactos_soldados", "bobina_quemada", "motor_quemado", "fusible_fundido", "lampara_quemada", "vibracion_mando", "multimetro_destruido", "fusible_multimetro", "megohmetro_destruido",
			"fuente_sobrecarga", "diodo_quemado", "led_quemado", "puente_quemado", "ssr_quemado", "sensor_cortocircuito", "sensor_averiado"]:
		if not textos.has(e) or textos[e]["texto"].is_empty():
			return "falta explicar el evento %s" % e
	return ""


func _raiz_taller() -> Raiz:
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = "user://pruebas_taller.json"
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("taller")
	return raiz


func test_cablear_tocando_dos_bornes_en_pantalla() -> String:
	var raiz := _raiz_taller()
	var p = raiz.pantalla_actual()
	p.mesa.vaciar()
	p.mesa.agregar("lampara", Vector2.ZERO)
	p.mesa.agregar("lampara", Vector2(400.0, 0.0))
	p._al_tocar_borne("H1.X1")
	var marcado: String = p.vista.borne_marcado
	p._al_tocar_borne("H2.X2")
	var cables: int = p.mesa.sim.cables.size()
	var limpio: String = p.vista.borne_marcado
	raiz.free()
	return A.primero([
		A.cierto(marcado == "H1.X1", "el primer borne debe quedar marcado"),
		A.cierto(cables == 1, "el segundo toque debe crear el cable"),
		A.cierto(limpio.is_empty(), "después no debe quedar marca"),
	])


func test_medir_ohmios_con_tension_avisa_en_pantalla() -> String:
	var raiz := _raiz_taller()
	var p = raiz.pantalla_actual()
	p.mesa.vaciar()
	p.mesa.agregar("fuente_trifasica", Vector2.ZERO)
	p.mesa.avanzar(1)
	p.args["pestana"] = "medir"
	p._elegir_instrumento("multimetro")
	p._elegir_modo("ohm")
	p._al_tocar_borne("B1.L1")
	p._al_tocar_borne("B1.L2")
	p._actualizar_lectura()
	p._revisar_eventos()
	var avisos: int = p._avisos.get_child_count()
	var destruido: bool = p.args["multimetro"].destruido
	raiz.free()
	return A.primero([
		A.cierto(destruido, "el multímetro debe destruirse"),
		A.cierto(avisos == 1, "debe explicar lo ocurrido: %d avisos" % avisos),
	])


func test_mesa_y_encuadre_sobreviven_al_giro() -> String:
	var raiz := _raiz_taller()
	var p = raiz.pantalla_actual()
	p.mesa.vaciar()
	p.mesa.agregar("contactor", Vector2.ZERO)
	var mesa: MesaTaller = p.mesa
	p.vista.zoom = 1.3
	p.vista.origen = Vector2(77.0, 88.0)
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var igual: bool = q.mesa == mesa
	var zoom: float = q.vista.zoom
	var origen: Vector2 = q.vista.origen
	raiz.free()
	return A.primero([
		A.cierto(igual, "girar el celular no debe perder la mesa"),
		A.cierto(is_equal_approx(zoom, 1.3), "debe conservar el zoom: %f" % zoom),
		A.cierto(origen.is_equal_approx(Vector2(77.0, 88.0)), "debe conservar el encuadre"),
	])


func test_tocar_una_pieza_no_mueve_la_vista() -> String:
	var raiz := _raiz_taller()
	var p = raiz.pantalla_actual()
	p.mesa.vaciar()
	p.mesa.agregar("contactor", Vector2.ZERO)
	p.vista.zoom = 1.3
	p.vista.origen = Vector2(77.0, 88.0)
	p._al_tocar_pieza("K1")
	var misma: bool = raiz.pantalla_actual() == p
	var zoom: float = p.vista.zoom
	var pestana: bool = p._botones_pestana["pieza"].button_pressed
	raiz.free()
	return A.primero([
		A.cierto(misma, "no debe rehacer la pantalla"),
		A.cierto(is_equal_approx(zoom, 1.3), "no debe cambiar el zoom"),
		A.cierto(pestana, "la pestaña Pieza debe quedar marcada"),
	])


func test_pinza_abraza_cables_en_pantalla() -> String:
	var raiz := _raiz_taller()
	var p = raiz.pantalla_actual()
	p.mesa.vaciar()
	_montar_directo(p.mesa, "motor_380", true)
	_arrancar(p.mesa)
	p.mesa.avanzar(60)
	p.args["pestana"] = "medir"
	p._elegir_instrumento("pinza")
	var fase := -1
	for i in p.mesa.sim.cables.size():
		if p.mesa.sim.cables[i][1].ends_with(".U1"):
			fase = i
	var cables: int = p.mesa.sim.cables.size()
	p._al_tocar_cable(fase)
	p._actualizar_lectura()
	var lectura: String = p._lectura.text
	var marcado: bool = p.vista.cables_pinza.has(fase)
	var sin_cambios: bool = p.mesa.sim.cables.size() == cables and p.args["cable"] == -1
	p._al_tocar_cable(fase)
	var soltado: bool = p.args["pinza_cables"].is_empty()
	p._al_tocar_borne("M1.U1")
	var sin_puntas: bool = p.args["roja"].is_empty()
	raiz.free()
	return A.primero([
		A.cierto(fase >= 0, "debe haber un cable a U1"),
		A.cierto(lectura.ends_with(" A") and not lectura.begins_with("0,0"), "debe mostrar la corriente del motor: %s" % lectura),
		A.cierto(marcado, "la mesa debe dibujar la pinza en el cable"),
		A.cierto(sin_cambios, "tocar un cable con la pinza no lo cambia ni lo selecciona"),
		A.cierto(soltado, "tocarlo otra vez lo saca de la pinza"),
		A.cierto(sin_puntas, "con la pinza, un borne no coloca puntas"),
	])
