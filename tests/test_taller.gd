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
				if not mesa.bornes(id).has(nodo.get_slice(".", 1)):
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
	_montar_directo(mesa, "motor_440", true)
	_arrancar(mesa)
	mesa.avanzar(200)
	return A.primero([
		A.cierto(mesa.sim.componente("K1").cerrado(), "K1 debe quedar enclavado"),
		A.cierto(mesa.sim.componente("M1").rpm() > 1700.0, "debe llegar a su velocidad: %.0f" % mesa.sim.componente("M1").rpm()),
		A.cierto(mesa.eventos_nuevos().is_empty(), "un montaje correcto no debe generar eventos"),
	])


func test_motor_254_en_delta_dispara_y_avisa() -> String:
	var mesa := _mesa()
	_montar_directo(mesa, "motor_254", true)
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
	_montar_directo(mesa, "motor_440", true)
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
	_montar_directo(mesa, "motor_440", true)
	mesa.avanzar(2)
	var m := SimMultimetro.new()
	m.ruido = 0.0
	var v: Dictionary = m.medir(mesa.sim, "vac", "B1.L1", "B1.L2")
	var r: Dictionary = m.medir(mesa.sim, "ohm", "M1.U1", "M1.U2")
	var meg := SimMegohmetro.new()
	var aislamiento: Dictionary = meg.medir(mesa.sim, "M1.U1", SimSolver.TIERRA, 500)
	var destruido: Dictionary = m.medir(mesa.sim, "ohm", "B1.L1", "B1.L2")
	return A.primero([
		A.cerca(v["valor"], 440.0, 0.01, "tensión de línea"),
		A.cierto(float(r["valor"]) < 5.0, "devanado en delta: valor bajo, %.2f" % r["valor"]),
		A.cierto(aislamiento["aceptable"], "aislamiento sano"),
		A.cierto(destruido["averia"] == "multimetro_destruido", "ohmios con tensión debe destruirlo"),
		A.cierto(mesa.sim.hubo_evento("multimetro_destruido"), "debe generar el aviso"),
	])


func test_todas_las_consecuencias_tienen_explicacion() -> String:
	var textos: Dictionary = Contenido.new().leer("taller.json")["consecuencias"]
	for e in ["disparo_magnetico", "disparo_termico", "disparo_rele_termico", "disparo_barras", "arco_contactos_soldados", "bobina_quemada", "motor_quemado", "fusible_fundido", "lampara_quemada", "vibracion_mando", "multimetro_destruido", "fusible_multimetro", "megohmetro_destruido"]:
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
