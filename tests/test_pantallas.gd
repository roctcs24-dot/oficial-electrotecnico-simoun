extends RefCounted
## Las pantallas se construyen sin errores en ambas orientaciones y con botones de tamaño táctil.

const A := preload("res://tests/ayuda_sim.gd")
const ESCENA := "res://ui/raiz.tscn"
const ALTO_MIN_BOTON := 48.0
const RUTA_PARTIDA := "user://pruebas_pantallas.json"


func _crear_raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load(ESCENA).instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	return raiz


func _botones_pequenos(nodo: Node, lista: Array[String]) -> void:
	if nodo is Button and nodo.get_combined_minimum_size().y < ALTO_MIN_BOTON:
		lista.append("%s (%d)" % [nodo.text, nodo.get_combined_minimum_size().y])
	for hijo in nodo.get_children():
		_botones_pequenos(hijo, lista)


## Elementos dentro de listas que impedirían arrastrarlas con el dedo. Los deslizadores y el
## pulsador que se mantiene deben conservar el gesto para sí.
func _botones_que_bloquean(nodo: Node, en_lista: bool, lista: Array[String]) -> void:
	if en_lista and nodo is Control and nodo.mouse_filter == Control.MOUSE_FILTER_STOP:
		if not nodo is Slider and not nodo.has_meta("se_mantiene"):
			lista.append("%s %s" % [nodo.get_class(), nodo.name])
	for hijo in nodo.get_children():
		_botones_que_bloquean(hijo, en_lista or nodo is ScrollContainer, lista)


func test_en_tactil_no_hay_resaltado_de_cursor() -> String:
	var tactil := Tema.crear(true)
	var pc := Tema.crear(false)
	var normal: StyleBoxFlat = tactil.get_stylebox("normal", "Button")
	var encima: StyleBoxFlat = tactil.get_stylebox("hover", "Button")
	var encima_pc: StyleBoxFlat = pc.get_stylebox("hover", "Button")
	return A.primero([
		A.cierto(encima.bg_color == normal.bg_color, "en táctil, hover debe verse igual que normal"),
		A.cierto(encima_pc.bg_color != normal.bg_color, "en PC, hover debe seguir resaltando"),
	])


func test_cancelar_pulsaciones_respeta_los_deshabilitados() -> String:
	var caja := VBoxContainer.new()
	var activo := Button.new()
	var inactivo := Button.new()
	inactivo.disabled = true
	caja.add_child(activo)
	caja.add_child(inactivo)
	Pantalla.cancelar_pulsaciones(caja)
	var resultado := A.primero([
		A.cierto(not activo.disabled, "un botón activo debe seguir activo"),
		A.cierto(inactivo.disabled, "un botón deshabilitado debe seguir deshabilitado"),
	])
	caja.free()
	return resultado


func _recorrer(raiz: Raiz) -> String:
	var pasos := [
		["sistema", {"id": 3}],
		["aprender", {"id": 3}],
		["ficha", {"id": "contactor"}],
		["ficha", {"id": "contactor", "vista": "simbolos"}],
		["aprender", {"id": 0}],
		["glosario", {}],
	]
	pasos.append(["examen", {"id": 3}])
	pasos.append(["minijuego_simbolos", {}])
	for id: String in raiz.contenido.sistema(3)["modos"]["aprender"]["fichas"]:
		pasos.append(["ficha", {"id": id}])
		pasos.append(["ficha", {"id": id, "vista": "simbolos"}])
		for n in raiz.contenido.ficha(id).get("dibujos_extra", []).size():
			pasos.append(["ficha", {"id": id, "vista": "extra_%d" % n}])
	for id: String in raiz.contenido.sistema(0)["modos"]["aprender"]["lecciones"]:
		for n in raiz.contenido.leccion(id)["paginas"].size():
			pasos.append(["leccion", {"id": id, "sistema": 0, "pagina": n, "respuestas": {}}])
	for vertical in [false, true]:
		raiz.vertical = vertical
		raiz.reconstruir()
		for p: Array in pasos:
			raiz.ir_a(p[0], p[1])
			var pequenos: Array[String] = []
			_botones_pequenos(raiz, pequenos)
			if not pequenos.is_empty():
				return "botones bajo %d en %s: %s" % [int(ALTO_MIN_BOTON), p[0], ", ".join(pequenos)]
			var bloquean: Array[String] = []
			_botones_que_bloquean(raiz, false, bloquean)
			if not bloquean.is_empty():
				return "botones que impiden arrastrar en %s: %s" % [p[0], ", ".join(bloquean)]
			raiz.volver()
		var en_plano: Array[String] = []
		_botones_que_bloquean(raiz, false, en_plano)
		if not en_plano.is_empty():
			return "botones que impiden arrastrar en el plano: %s" % ", ".join(en_plano)
	return ""


func test_recorrido_en_ambas_orientaciones() -> String:
	var raiz := _crear_raiz()
	var motivo := _recorrer(raiz)
	raiz.free()
	return motivo


func _buscar_quiz(nodo: Node) -> BloqueQuiz:
	if nodo is BloqueQuiz:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_quiz(hijo)
		if encontrado != null:
			return encontrado
	return null


func test_partida_completa_del_minijuego() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("minijuego_simbolos")
	var args: Dictionary = raiz.pantalla_actual().args
	var rondas: Array = args["rondas"]
	var cantidad := rondas.size()
	var bloquea := false
	for i in cantidad:
		var quiz := _buscar_quiz(raiz.pantalla_actual())
		var correcta := int(rondas[i]["correcta"])
		quiz.elegir(correcta if i > 0 else (correcta + 1) % 4)
		raiz.reconstruir()
		if _buscar_quiz(raiz.pantalla_actual())._botones[0].disabled == false:
			bloquea = true
		raiz.pantalla_actual()._avanzar()
	var fallo_id: String = "simbolo_%s" % rondas[0]["id"]
	var error: bool = raiz.partida.datos["errores"].has(fallo_id)
	var resultado: Dictionary = raiz.partida.datos["minijuegos"].get("simbolos", {})
	var puntos: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.primero([
		A.cierto(not bloquea, "una ronda contestada no debe poder responderse de nuevo"),
		A.cierto(error, "el símbolo fallado debe quedar para el repaso"),
		A.cierto(int(resultado.get("estrellas", -1)) == 3, "9 de 10 son 3 estrellas: %s" % str(resultado)),
		A.cierto(puntos == 30, "3 estrellas nuevas son 30 puntos: %d" % puntos),
	])


func test_volver_no_sale_de_la_primera_pantalla() -> String:
	var raiz := _crear_raiz()
	raiz.volver()
	var sigue := raiz.pantalla_actual() != null
	raiz.free()
	return A.cierto(sigue, "volver en el plano debe dejar el plano")


func test_abrir_una_ficha_queda_guardado() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("ficha", {"id": "contactor"})
	raiz.free()
	var p := Partida.new(RUTA_PARTIDA)
	p.cargar()
	return A.cierto(p.ficha_vista("contactor"), "debe recordar la ficha vista")


func test_el_banco_usa_la_simulacion() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("ficha", {"id": "contactor"})
	var ficha = raiz.pantalla_actual()
	var k: SimContactor = ficha._sim.componente("K1")
	var reposo := k.cerrado()
	ficha.pulsar_banco(true)
	var pulsado := k.cerrado()
	ficha.pulsar_banco(true)
	var luz: bool = ficha._luz.encendida
	ficha.pulsar_banco(false)
	ficha.pulsar_banco(false)
	var soltado := k.cerrado()
	ficha.pulsar_banco(false)
	var luz_soltado: bool = ficha._luz.encendida
	raiz.free()
	return A.primero([
		A.cierto(not reposo, "en reposo debe estar abierto"),
		A.cierto(pulsado, "con S1 pulsado debe cerrar"),
		A.cierto(luz, "la luz debe encender por el contacto 13-14"),
		A.cierto(not soltado, "al soltar debe abrir"),
		A.cierto(not luz_soltado, "al soltar debe apagarse la luz"),
	])
