extends RefCounted
## Pantallas de los tableros del buque: datos coherentes, frente que se toca y puerta que se abre.

const RUTA_PARTIDA := "user://pruebas_tableros.json"
const TIPOS_CON_COMPONENTE := ["luz", "pulsador", "selector", "seta", "seccionador", "horometro", "amperimetro"]


func _raiz(vertical := true) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.vertical = vertical
	return raiz


func _ids_tableros(c: Contenido) -> Array:
	var ids := []
	for s: Dictionary in c.sistemas():
		ids.append_array(s.get("modos", {}).get("taller", {}).get("tableros", []))
	return ids


func _indice(p, tipo: String, componente: String) -> int:
	var elementos: Array = p.tablero["frente"]["elementos"]
	for i in elementos.size():
		if elementos[i]["tipo"] == tipo and elementos[i].get("componente", "") == componente:
			return i
	return -1


func test_cada_tablero_es_coherente_con_su_circuito() -> String:
	var c := Contenido.new()
	var ids := _ids_tableros(c)
	if ids.is_empty():
		return "ningún sistema ofrece tableros"
	for id: String in ids:
		var t := c.tablero(id)
		if t.is_empty():
			return "falta data/tableros/%s.json" % id
		var sim := c.circuito(t["circuito"])
		if sim == null:
			return "%s: falta el circuito %s" % [id, t["circuito"]]
		for comp: String in sim.componentes:
			if not t["interior"].has(comp):
				return "%s: %s no tiene posición en el interior" % [id, comp]
		for e: Dictionary in t["frente"]["elementos"]:
			var comp: String = str(e.get("componente", ""))
			if TIPOS_CON_COMPONENTE.has(e["tipo"]) and not comp.is_empty() and not sim.componentes.has(comp):
				return "%s: el frente usa %s, que no está en el circuito" % [id, comp]
			if e.has("luz") and not sim.componentes.has(e["luz"]):
				return "%s: el pulsador luminoso usa la luz %s, que no existe" % [id, e["luz"]]
		for lista: String in ["senales", "averias"]:
			for s: Dictionary in t.get(lista, []):
				if not sim.componentes.has(s["componente"]):
					return "%s: %s usa %s, que no existe" % [id, lista, s["componente"]]
		if t.has("alimentacion") and sim.componente(t["alimentacion"]).tipo() != "seccionador":
			return "%s: la alimentación debe ser un interruptor con candado" % id
	return ""


func test_el_sistema_3_ofrece_el_banco_y_los_tableros() -> String:
	var raiz := _raiz()
	raiz.ir_a("sistema", {"id": 3})
	raiz.pantalla_actual()._abrir_modo("taller")
	var lista := raiz.pantalla_actual()
	var textos: Array[String] = []
	_textos(lista, textos)
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Banco libre"), "debe ofrecer el banco libre: %s" % str(textos)),
		A.cierto(textos.has("Tablero de bombas máquina principal"), "debe ofrecer el tablero: %s" % str(textos)),
	])


func _textos(nodo: Node, lista: Array[String]) -> void:
	if nodo is Label or nodo is Button:
		lista.append(nodo.text)
	for hijo in nodo.get_children():
		_textos(hijo, lista)


func test_pulsar_encendido_en_el_frente_arranca_la_bomba() -> String:
	var raiz := _raiz()
	raiz.ir_a("tablero", {"tablero": "bombas_mp"})
	var p = raiz.pantalla_actual()
	var sim: SimSimulacion = p.mesa.sim
	var i: int = _indice(p, "pulsador", "SM1")
	p.accionar(i)
	sim.avanzar_tiempo(0.3)
	p.soltar(i)
	sim.avanzar_tiempo(5.0)
	var en_marcha: bool = sim.componente("K1").cerrado()
	var suelto: bool = not sim.componente("SM1").estado["presionado"]
	raiz.free()
	return A.primero([
		A.cierto(i >= 0, "el frente tiene el pulsador ENCENDIDO de la bomba nº 1"),
		A.cierto(en_marcha, "el pulsador arranca la bomba y se enclava"),
		A.cierto(suelto, "al soltar, el pulsador vuelve"),
	])


func test_tocar_el_selector_lo_gira_hacia_ese_lado() -> String:
	var raiz := _raiz()
	raiz.ir_a("tablero", {"tablero": "bombas_mp"})
	var p = raiz.pantalla_actual()
	var sel: SimSelector = p.mesa.sim.componente("SEL3")
	var i: int = _indice(p, "selector", "SEL3")
	var inicial: String = sel.nombre_posicion()
	p.accionar(i, -1)
	p.soltar(i)
	var tras_izquierda: String = sel.nombre_posicion()
	p.accionar(i, 1)
	p.accionar(i, 1)
	var tope: String = sel.nombre_posicion()
	raiz.free()
	return A.primero([
		A.cierto(inicial == "AUT", "la prelubricación está en AUT: %s" % inicial),
		A.cierto(tras_izquierda == "OFF", "a la izquierda pasa a OFF: %s" % tras_izquierda),
		A.cierto(tope == "AUT", "a la derecha no pasa del tope: %s" % tope),
	])


func test_el_toque_encuentra_el_elemento_bajo_el_dedo() -> String:
	var raiz := _raiz(false)
	raiz.ir_a("tablero", {"tablero": "bombas_mp"})
	var p = raiz.pantalla_actual()
	var f: VistaTablero = p.frente
	f.size = Vector2(500, 575)
	var i: int = _indice(p, "pulsador", "SP2")
	var punto: Vector2 = f.a_pantalla(f.centro(i)) + Vector2(4, -3)
	var encontrado: int = f.elemento_en(punto)
	var en_rotulo: int = f.elemento_en(f.a_pantalla(Vector2(500, 70)))
	f.cambiar_zoom(2.0, punto)
	var tras_zoom: int = f.elemento_en(punto)
	raiz.free()
	return A.primero([
		A.cierto(encontrado == i, "el toque sobre APAGADO nº 2 debe encontrarlo: %d" % encontrado),
		A.cierto(en_rotulo == -1, "un rótulo no es un mando"),
		A.cierto(tras_zoom == i, "al ampliar, el punto bajo el dedo sigue siendo el mismo mando"),
	])


func test_candado_desde_la_pestana_mando() -> String:
	var raiz := _raiz()
	raiz.ir_a("tablero", {"tablero": "bombas_mp"})
	var p = raiz.pantalla_actual()
	var q: SimSeccionador = p.mesa.sim.componente("Q0")
	p._maniobrar_alimentacion()
	p._alternar_candado()
	p._maniobrar_alimentacion()
	var bloqueado: bool = not q.cerrado() and q.estado["candado"]
	raiz.free()
	return A.cierto(bloqueado, "con el candado puesto el interruptor no se cierra")


func test_abrir_la_puerta_muestra_el_interior_y_sobrevive_al_giro() -> String:
	var raiz := _raiz()
	raiz.ir_a("tablero", {"tablero": "bombas_mp"})
	var p = raiz.pantalla_actual()
	p._alternar_puerta()
	var interior_visible: bool = p.vista.is_visible_in_tree() or p._caja_mesa.visible
	var frente_oculto: bool = not p.frente.visible
	p.mesa.sim.componente("Q0").accionar(false)
	raiz.vertical = false
	raiz.reconstruir()
	var p2 = raiz.pantalla_actual()
	var sigue_abierta: bool = p2.args["puerta"] and p2._caja_mesa.visible
	var misma_sim: bool = not p2.mesa.sim.componente("Q0").cerrado()
	raiz.free()
	return A.primero([
		A.cierto(interior_visible and frente_oculto, "con la puerta abierta se ve la mesa y no el frente"),
		A.cierto(sigue_abierta, "al girar sigue abierta"),
		A.cierto(misma_sim, "al girar conserva la simulación"),
	])


func test_recorre_las_pestanas_en_ambas_orientaciones() -> String:
	for vertical in [true, false]:
		var raiz := _raiz(vertical)
		raiz.ir_a("tablero", {"tablero": "bombas_mp"})
		var p = raiz.pantalla_actual()
		for pestana: String in ["mando", "medir", "pieza", "datos"]:
			p._elegir_pestana(pestana)
		p.args["pieza"] = "F1"
		p._elegir_pestana("pieza")
		var hijos: int = p._panel.get_child_count()
		raiz.free()
		if hijos < 3:
			return "la pestaña Equipo debe mostrar el relé y su ajuste"
	return ""


const A := preload("res://tests/ayuda_sim.gd")
