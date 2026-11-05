class_name PantallaPreguntas
extends Pantalla
## Base del examen y del repaso: una pregunta por página. El estado vive en args para
## sobrevivir al giro del celular.

const ALTO_SIMBOLO := 170.0
const TITULOS_NORMA := {"iec": "IEC 60617", "ansi": "ANSI/IEEE 315 (NEMA)"}

var _siguiente: Button


func _crear_items() -> Array:
	return []


func _titulo() -> String:
	return ""


func _al_contestar(_item: Dictionary, _acierto: bool) -> void:
	pass


func _construir_final() -> void:
	pass


func construir() -> void:
	if not args.has("items"):
		args["items"] = _crear_items()
		args["indice"] = 0
		args["respuestas"] = {}
	var items: Array = args["items"]
	var indice: int = args["indice"]
	if indice >= items.size():
		_construir_final()
		return
	_cabecera(_titulo(), "Pregunta %d de %d" % [indice + 1, items.size()])
	add_child(_barra_avance(float(indice + 1) / items.size()))
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	_crear_pregunta(columna, items[indice], indice)
	_siguiente = _boton("Ver resultado" if indice + 1 >= items.size() else "Siguiente ›", avanzar)
	_siguiente.disabled = not args["respuestas"].has(indice)
	add_child(_siguiente)


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	if item.has("caso"):
		columna.add_child(_rotulo("Caso práctico"))
		columna.add_child(_texto_rico(item["caso"]))
	match item["tipo"]:
		"ordenar":
			var ordenar := BloqueOrdenar.new()
			ordenar.iniciar(item, not respuesta.is_empty())
			if respuesta.is_empty():
				ordenar.respondido.connect(_al_ordenar.bind(indice))
			columna.add_child(ordenar)
		"simbolo":
			# En horizontal, lado a lado: apilados, el dibujo dejaría la pregunta fuera de la vista.
			var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
			disposicion.add_theme_constant_override("separation", 12)
			columna.add_child(disposicion)
			var tarjeta := _tarjeta_simbolo(item)
			tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			disposicion.add_child(tarjeta)
			var lado := _columna()
			disposicion.add_child(lado)
			_agregar_quiz(lado, _quiz_de_simbolo(item), respuesta, indice)
		_:
			_agregar_quiz(columna, item, respuesta, indice)


func _agregar_quiz(columna: VBoxContainer, datos: Dictionary, respuesta: Dictionary, indice: int) -> void:
	var quiz := BloqueQuiz.new()
	quiz.iniciar(datos, respuesta.get("elegida", -1))
	if respuesta.is_empty():
		quiz.respondido.connect(_al_responder.bind(indice))
	columna.add_child(quiz)


func _tarjeta_simbolo(item: Dictionary) -> Control:
	var datos := raiz.contenido.simbolo(item["id"])
	var tarjeta := _tarjeta_base("Papel")
	var columna := _columna(2)
	tarjeta.add_child(columna)
	var titulo := _etiqueta(TITULOS_NORMA[item["norma"]], "Nota")
	titulo.add_theme_color_override("font_color", Tema.TINTA)
	columna.add_child(titulo)
	var dibujo := VistaSvg.new()
	dibujo.color_etiquetas = Tema.TINTA
	dibujo.cargar(datos[item["norma"]])
	dibujo.custom_minimum_size.y = ALTO_SIMBOLO
	columna.add_child(dibujo)
	return tarjeta


func _quiz_de_simbolo(item: Dictionary) -> Dictionary:
	var nombres := []
	for id: String in item["opciones"]:
		nombres.append(raiz.contenido.simbolo(id)["nombre"])
	return {
		"pregunta": "¿Qué representa este símbolo?",
		"opciones": nombres,
		"correcta": item["correcta"],
		"explicacion": "%s." % raiz.contenido.simbolo(item["id"])["nombre"],
	}


func _al_responder(acierto: bool, elegida: int, indice: int) -> void:
	_resolver(indice, acierto, elegida)


func _al_ordenar(errores: int, indice: int) -> void:
	_resolver(indice, errores == 0, -1)


func _resolver(indice: int, acierto: bool, elegida: int) -> void:
	args["respuestas"][indice] = {"acierto": acierto, "elegida": elegida}
	_al_contestar(args["items"][indice], acierto)
	_siguiente.disabled = false


func avanzar() -> void:
	args["indice"] += 1
	raiz.reconstruir()


func aciertos() -> int:
	var total := 0
	for r: Dictionary in args["respuestas"].values():
		if r["acierto"]:
			total += 1
	return total
