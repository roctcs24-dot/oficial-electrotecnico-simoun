extends RefCounted
## Etapa C del rediseño: el inicio con el buque visto desde arriba (zonas por sistema con su
## lámpara de estado, avería y repaso) y la Escuela con medallas de módulo, camino de lecciones
## y cajón de piezas del atlas.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_rediseno_c.json"
const APAISADO := Vector2i(960, 432)
const VERTICAL := Vector2i(432, 960)
const LADO_TACTIL := 40.0


func _raiz(tam := APAISADO, preparar := Callable()) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.set_anchors_preset(Control.PRESET_TOP_LEFT)
	raiz.size = Vector2(tam)
	raiz._al_cambiar_tamano()
	if preparar.is_valid():
		preparar.call(raiz.partida)
	raiz.reconstruir()
	return raiz


## Coloca la pantalla a su tamaño, como si se hubiera dibujado un fotograma.
func _maquetar(raiz: Raiz) -> void:
	var p := raiz.pantalla_actual()
	p.size = raiz.size
	for nodo: Node in p.find_children("*", "Container", true, false):
		(nodo as Container).queue_sort()
	p.notification(Container.NOTIFICATION_SORT_CHILDREN)


func _buscar(nodo: Node, clase: String) -> Array[Node]:
	return nodo.find_children("*", clase, true, false)


func _planta(raiz: Raiz) -> PlantaBuque:
	var lista := _buscar(raiz.pantalla_actual(), "PlantaBuque")
	return lista[0] if not lista.is_empty() else null


func test_planta_tiene_una_zona_por_sistema_del_buque() -> String:
	var c := Contenido.new()
	var planta := c.planta()
	var vistos := {}
	var dentro := true
	var rects: Array[Rect2] = []
	for z: Dictionary in planta.get("zonas", []):
		vistos[int(z["sistema"])] = vistos.get(int(z["sistema"]), 0) + 1
		var r := Rect2(z["u"][0], z["v"][0], z["u"][1] - z["u"][0], z["v"][1] - z["v"][0])
		if r.position.x < PlantaBuque.POPA or r.end.x > PlantaBuque.PROA or r.position.y < PlantaBuque.EJE - PlantaBuque.MEDIA_MANGA or r.end.y > PlantaBuque.EJE + PlantaBuque.MEDIA_MANGA:
			dentro = false
		rects.append(r)
	var solapes := 0
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				solapes += 1
	var esperados := {}
	for s: Dictionary in c.sistemas():
		if int(s["id"]) != int(planta.get("aparte", {}).get("sistema", -1)):
			esperados[int(s["id"])] = 1
	return A.primero([
		A.cierto(vistos == esperados, "una zona por sistema del buque: %s" % str(vistos)),
		A.cierto(int(planta.get("aparte", {}).get("sistema", -1)) == 0, "la seguridad (sistema 0) va aparte, como medalla"),
		A.cierto(dentro, "las zonas quedan dentro del casco"),
		A.cierto(solapes == 0, "las zonas no se solapan: %d" % solapes),
		A.cierto("verificar" in str(planta.get("nota", "")), "la disposición está marcada para verificar a bordo"),
	])


func test_buque_en_ambas_orientaciones_con_zonas_tocables() -> String:
	var fallos: Array[String] = []
	for tam: Vector2i in [APAISADO, VERTICAL]:
		var raiz := _raiz(tam)
		_maquetar(raiz)
		var planta := _planta(raiz)
		if planta == null:
			fallos.append("%s: sin buque" % str(tam))
			raiz.free()
			continue
		if planta.size.x < 100.0 or planta.size.y < 100.0:
			planta.size = Vector2(560, 330) if tam == APAISADO else Vector2(408, 520)
		if planta.es_vertical() != (tam == VERTICAL):
			fallos.append("%s: orientación del buque" % str(tam))
		var caja := Rect2(Vector2.ZERO, planta.size)
		for z: Dictionary in planta.zonas_pantalla():
			var r: Rect2 = z["rect"]
			if not caja.encloses(r):
				fallos.append("%s: la zona %d se sale" % [str(tam), z["sistema"]])
			if r.size.x < LADO_TACTIL or r.size.y < LADO_TACTIL:
				fallos.append("%s: la zona %d mide %s" % [str(tam), z["sistema"], str(r.size)])
		raiz.free()
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_tocar_una_zona_o_la_medalla_abre_su_sistema() -> String:
	var raiz := _raiz()
	_maquetar(raiz)
	var planta := _planta(raiz)
	planta.size = Vector2(560, 330)
	var motores: Rect2
	for z: Dictionary in planta.zonas_pantalla():
		if z["sistema"] == 3:
			motores = z["rect"]
	var cerca := planta.zona_en(Vector2(motores.get_center().x, motores.end.y + 18.0))
	planta.tocar(motores.get_center())
	var abre_motores := raiz.nombre_actual() == "sistema" and int(raiz.args_actuales().get("id", -1)) == 3
	raiz.ir_a_seccion("inicio")
	_maquetar(raiz)
	planta = _planta(raiz)
	planta.size = Vector2(560, 330)
	planta.tocar(planta.centro_medalla())
	var abre_seguridad := raiz.nombre_actual() == "sistema" and int(raiz.args_actuales().get("id", -1)) == 0
	raiz.free()
	return A.primero([
		A.cierto(abre_motores, "tocar la zona de motores abre el sistema 3"),
		A.cierto(cerca == 3, "a 18 puntos del borde, el dedo todavía alcanza la zona: %d" % cerca),
		A.cierto(abre_seguridad, "la medalla de seguridad abre el sistema 0"),
	])


func test_lampara_de_estado_de_cada_sistema() -> String:
	var c := Contenido.new()
	var p := Partida.new()
	var s := c.sistema(2)
	var nuevo := Avance.estado(s, p)
	var modos: Dictionary = s["modos"]
	p.datos["lecciones"][modos["aprender"]["lecciones"][0]] = {"aciertos": 1, "total": 1}
	var en_curso := Avance.estado(s, p)
	for id: String in modos["aprender"]["lecciones"]:
		p.datos["lecciones"][id] = {"aciertos": 1, "total": 1}
	for id: String in modos["guardia"]["misiones"]:
		p.datos["misiones"][id] = {"completada": true, "estrellas": 3}
	for id: String in modos["examen"]["examenes"]:
		p.datos["examenes"][id] = {"aprobado": true, "estrellas": 3}
	var completo := Avance.estado(s, p)
	p.datos["equipos_danados"][modos["guardia"]["misiones"][0]] = {"breaker": "quemado"}
	var averia := Avance.estado(s, p)
	return A.primero([
		A.cierto(nuevo == "sin_empezar", "sin nada hecho: %s" % nuevo),
		A.cierto(en_curso == "en_curso", "con una lección: %s" % en_curso),
		A.cierto(completo == "completo", "con todo hecho: %s" % completo),
		A.cierto(averia == "averia", "un equipo dañado manda sobre todo: %s" % averia),
	])


func test_averia_y_repaso_en_el_inicio() -> String:
	var mision: String = Contenido.new().sistema(3)["modos"]["guardia"]["misiones"][0]
	var raiz := _raiz(APAISADO, func(p: Partida) -> void:
		p.datos["equipos_danados"][mision] = {"motor": "quemado"}
		p.registrar_error("loto"))
	var planta := _planta(raiz)
	var lampara: String = planta.estados.get(3, "")
	var boton := raiz.pantalla_actual().find_child("Averia", true, false) as BotonAri
	var repaso := raiz.pantalla_actual().find_child("Repaso", true, false) as BotonAri
	var insignia := repaso.insignia if repaso != null else ""
	if boton != null:
		boton.pressed.emit()
	var abre_guardia := raiz.nombre_actual() == "guardia" and int(raiz.args_actuales().get("id", -1)) == 3
	raiz.free()
	var limpia := _raiz()
	var sin_averia := limpia.pantalla_actual().find_child("Averia", true, false) == null
	var play := _buscar(limpia.pantalla_actual(), "BotonPlay")
	if not play.is_empty():
		(play[0] as BotonPlay).pressed.emit()
	var abre_leccion := limpia.nombre_actual() == "leccion"
	limpia.free()
	return A.primero([
		A.cierto(lampara == "averia", "la zona de motores enciende la lámpara roja: %s" % lampara),
		A.cierto(boton != null and abre_guardia, "el botón de avería lleva a la Guardia de motores"),
		A.cierto(insignia == "1", "el repaso lleva el número de temas pendientes: «%s»" % insignia),
		A.cierto(sin_averia, "sin equipos dañados no hay botón de avería"),
		A.cierto(play.size() == 1 and abre_leccion, "el botón redondo de «Continuar» abre la lección"),
	])


func test_escuela_recomienda_el_modulo_y_cambia_con_la_medalla() -> String:
	var raiz := _raiz(VERTICAL)
	raiz.ir_a_seccion("escuela")
	var p = raiz.pantalla_actual()
	var primero: int = p.modulo_elegido
	var medalla_7: MedallaModulo = null
	for m: MedallaModulo in p.medallas:
		if m.name == "Modulo7":
			medalla_7 = m
	medalla_7.pulsada.emit()
	var elegido: int = raiz.pantalla_actual().modulo_elegido
	# Al girar el celular se rehace la pantalla y se conserva el módulo elegido.
	raiz.reconstruir()
	var tras_girar: int = raiz.pantalla_actual().modulo_elegido
	var cerradas := 0
	for m: MedallaModulo in raiz.pantalla_actual().medallas:
		if m.cerrada:
			cerradas += 1
	var en_preparacion := 0
	for m: Dictionary in raiz.contenido.modulos_escuela():
		if m.get("estado", "") != "activo":
			en_preparacion += 1
	raiz.free()
	var hecha := _raiz(APAISADO, func(par: Partida) -> void:
		for id: String in Contenido.new().sistema(0)["modos"]["aprender"]["lecciones"]:
			par.datos["lecciones"][id] = {"aciertos": 1, "total": 1}
		par.datos["examenes"]["v1"] = {"aprobado": true, "estrellas": 3})
	hecha.ir_a_seccion("escuela")
	var tras_fundamentos: int = hecha.pantalla_actual().modulo_elegido
	hecha.free()
	return A.primero([
		A.cierto(primero == 0, "una partida nueva empieza por los fundamentos: %d" % primero),
		A.cierto(elegido == 7 and tras_girar == 7, "la medalla elige el módulo y se conserva: %d, %d" % [elegido, tras_girar]),
		A.cierto(cerradas == en_preparacion, "los módulos en preparación salen con candado: %d" % cerradas),
		A.cierto(tras_fundamentos == 7, "hechos los fundamentos, recomienda electricidad: %d" % tras_fundamentos),
	])


func test_camino_marca_lo_hecho_y_abre_la_leccion() -> String:
	var lecciones: Array = Contenido.new().sistema(7)["modos"]["aprender"]["lecciones"]
	var raiz := _raiz(VERTICAL, func(p: Partida) -> void:
		for i in 3:
			p.datos["lecciones"][lecciones[i]] = {"aciertos": 1, "total": 1})
	raiz.ir_a_seccion("escuela")
	raiz.pantalla_actual().elegir_modulo(7)
	var camino: CaminoLecciones = raiz.pantalla_actual().camino
	camino.size = Vector2(408, camino.get_combined_minimum_size().y)
	var actual := camino.actual()
	var hechas: int = camino.pasos.filter(func(x: Dictionary) -> bool: return x["hecho"]).size()
	camino.tocar(camino.centros()[3])
	var abre: bool = raiz.nombre_actual() == "leccion" and raiz.args_actuales().get("id", "") == lecciones[3]
	raiz.free()
	return A.primero([
		# Una moneda por lección y, al final, la del examen de la Escuela I (desde la 5.1.0).
		A.cierto(camino.pasos.size() == lecciones.size() + 1 and camino.pasos[-1]["tipo"] == "examen", "una moneda por lección y el examen: %d" % camino.pasos.size()),
		A.cierto(hechas == 3 and actual == 3, "tres hechas y la cuarta es la siguiente: %d, %d" % [hechas, actual]),
		A.cierto(abre, "tocar la moneda abre su lección"),
	])


func test_camino_de_fundamentos_termina_en_el_examen() -> String:
	var raiz := _raiz(APAISADO)
	raiz.ir_a_seccion("escuela")
	raiz.pantalla_actual().elegir_modulo(0)
	var camino: CaminoLecciones = raiz.pantalla_actual().camino
	camino.size = Vector2(640, camino.get_combined_minimum_size().y)
	var ultimo: Dictionary = camino.pasos.back()
	camino.tocar(camino.centros().back())
	var abre: bool = raiz.nombre_actual() == "prueba_examen" and raiz.args_actuales().get("id", "") == "v1"
	raiz.free()
	return A.primero([
		A.cierto(ultimo.get("tipo", "") == "examen" and ultimo.get("id", "") == "v1", "el último paso es el examen v1: %s" % str(ultimo)),
		A.cierto(abre, "tocarlo abre el examen"),
	])


func test_cajon_de_piezas_con_el_atlas_del_modulo() -> String:
	var raiz := _raiz(VERTICAL, func(p: Partida) -> void:
		for pestana: String in ["que_es", "funciona", "conexion"]:
			p.marcar_pestana_atlas("rele_termico", pestana)
		for pestana: String in ["que_es", "funciona", "conexion", "medir", "fallas"]:
			p.marcar_pestana_atlas("contactor", pestana))
	raiz.ir_a_seccion("escuela")
	raiz.pantalla_actual().elegir_modulo(7)
	var atlas: Array = raiz.contenido.sistema(7)["modos"]["aprender"]["atlas"]
	var piezas: Array[PiezaAtlas] = raiz.pantalla_actual().piezas
	var avances := {}
	for pieza: PiezaAtlas in piezas:
		avances[String(pieza.name).trim_prefix("Pieza_")] = pieza.avance
	piezas[0].pulsada.emit()
	var abre: bool = raiz.nombre_actual() == "atlas" and raiz.args_actuales().get("id", "") == atlas[0]
	raiz.ir_a_seccion("escuela")
	# El módulo 9 (hidráulica, etapa 45) ya tiene camino y cajón con sus ocho piezas.
	raiz.pantalla_actual().elegir_modulo(9)
	var p = raiz.pantalla_actual()
	var hidraulica: bool = p.camino != null and p.piezas.size() == raiz.contenido.sistema(9)["modos"]["aprender"]["atlas"].size()
	raiz.free()
	return A.primero([
		A.cierto(piezas.size() == atlas.size(), "una pieza por ficha del atlas: %d de %d" % [piezas.size(), atlas.size()]),
		A.cierto(is_equal_approx(avances.get("contactor", 0.0), 1.0), "el contactor, con sus cinco vistas, está completo"),
		A.cierto(is_equal_approx(avances.get("rele_termico", 0.0), 0.6), "el relé térmico lleva 3 de 5: %s" % str(avances.get("rele_termico"))),
		A.cierto(abre, "tocar la pieza abre su ficha del atlas"),
		A.cierto(hidraulica, "el módulo de hidráulica tiene camino y una pieza por ficha del atlas"),
	])


func test_camino_en_serpentina_sin_salirse() -> String:
	var pasos := []
	for i in 9:
		pasos.append({"tipo": "leccion", "titulo": "Lección %d" % i, "hecho": i < 2})
	var camino := CaminoLecciones.new()
	camino.iniciar(pasos, Color.GOLD)
	camino.size = Vector2(408, 300)
	var columnas_estrecho := camino.columnas()
	var filas_estrecho := camino.filas()
	var dentro := camino.centros().all(func(c: Vector2) -> bool: return c.x - CaminoLecciones.RADIO_ACTUAL >= 0.0 and c.x + CaminoLecciones.RADIO_ACTUAL <= 408.0)
	var alto := camino.get_minimum_size().y
	var ultimo: Vector2 = camino.centros().back()
	var ultimo_abajo := ultimo.y + CaminoLecciones.RADIO_ACTUAL < alto
	camino.size = Vector2(680, 200)
	var una_fila := camino.filas()
	camino.free()
	return A.primero([
		A.cierto(columnas_estrecho == 5 and filas_estrecho == 2, "en 408 puntos, dos filas de cinco: %d × %d" % [filas_estrecho, columnas_estrecho]),
		A.cierto(dentro, "las monedas no se salen por los lados"),
		A.cierto(ultimo_abajo, "el alto mínimo deja sitio a la última fila"),
		A.cierto(una_fila == 1, "en 680 puntos, nueve monedas van en una fila: %d" % una_fila),
	])


func test_toque_cancelado_al_arrastrar_no_abre_nada() -> String:
	var camino := CaminoLecciones.new()
	camino.iniciar([{"tipo": "leccion", "titulo": "A", "hecho": false}], Color.GOLD)
	camino.size = Vector2(300, 120)
	var tocados := [0]
	camino.paso_tocado.connect(func(_i: int) -> void: tocados[0] += 1)
	var centro: Vector2 = camino.centros()[0]
	var pulsar := InputEventMouseButton.new()
	pulsar.button_index = MOUSE_BUTTON_LEFT
	pulsar.pressed = true
	pulsar.position = centro
	camino._gui_input(pulsar)
	var mover := InputEventMouseMotion.new()
	mover.position = centro + Vector2(0, 40)
	camino._gui_input(mover)
	var soltar := pulsar.duplicate() as InputEventMouseButton
	soltar.pressed = false
	camino._gui_input(soltar)
	var tras_arrastre: int = tocados[0]
	camino._gui_input(pulsar)
	camino._gui_input(soltar)
	var tras_toque: int = tocados[0]
	var filtro := camino.mouse_filter
	camino.free()
	return A.primero([
		A.cierto(tras_arrastre == 0, "arrastrar no abre la lección"),
		A.cierto(tras_toque == 1, "un toque sí la abre"),
		A.cierto(filtro == Control.MOUSE_FILTER_PASS, "deja pasar el gesto a la lista"),
	])


func test_nombre_largo_de_pieza_en_dos_lineas() -> String:
	var corto := PiezaAtlas.partir("Contactor", 10.5, 80.0)
	var largo := PiezaAtlas.partir("Interruptor automático", 10.5, 80.0)
	return A.primero([
		A.cierto(corto.size() == 1, "un nombre corto va en una línea"),
		A.cierto(largo == ["Interruptor", "automático"], "uno largo se parte por el espacio: %s" % str(largo)),
	])
