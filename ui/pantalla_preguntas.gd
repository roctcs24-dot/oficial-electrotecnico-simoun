class_name PantallaPreguntas
extends Pantalla
## Base del examen y del repaso: una pregunta por página, con el relieve de la Escuela. Arriba,
## la cabecera con la medalla y el contador de preguntas; debajo, la tira de lámparas de las
## preguntas (o las cajas de la repetición espaciada en el repaso); la pregunta en su placa,
## con el símbolo en papel dentro de un visor, y «Siguiente» ámbar al pie.
## El estado vive en args para sobrevivir al giro del celular.

const ALTO_SIMBOLO := 170.0
const TITULOS_NORMA := {"iec": "IEC 60617", "ansi": "ANSI/IEEE 315 (NEMA)"}

var _siguiente: BotonAri


func _crear_items() -> Array:
	return []


func _titulo() -> String:
	return ""


## Subtítulo de la cabecera.
func _subtitulo() -> String:
	return ""


## Color e icono de la medalla de la cabecera.
func _color() -> Color:
	return Tema.ACENTO


func _icono() -> String:
	return "examen"


## Control bajo la cabecera que muestra la marcha; por defecto, la tira de preguntas.
func _indicador(items: Array, indice: int) -> Control:
	if items.size() < 2:
		return null
	var estados: Array = []
	for i in items.size():
		var r: Dictionary = args["respuestas"].get(i, {})
		estados.append("" if r.is_empty() else ("verde" if r["acierto"] else "rojo"))
	return PiezasLeccion.TiraPreguntas.new(items.size(), estados, indice)


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
	_poner_cabecera(_subtitulo(), PiezasLeccion.Contador.new(indice + 1, items.size()))
	var indicador := _indicador(items, indice)
	if indicador != null:
		var placa := PiezasLeccion.placa(8.0, 3.0)
		placa.name = "Marcha"
		placa.add_child(indicador)
		add_child(placa)
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	_crear_pregunta(columna, items[indice], indice)
	_siguiente = BotonAri.new("VER RESULTADO  ›" if indice + 1 >= items.size() else "SIGUIENTE  ›", avanzar, "ambar")
	_siguiente.name = "Siguiente"
	_siguiente.custom_minimum_size.y = 50.0
	add_child(_siguiente)
	_actualizar_siguiente()


func _poner_cabecera(sub: String, extra: Control = null) -> void:
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, _titulo(), sub, _color(), _icono(), 0.0, extra)
	add_child(cabecera)


func _actualizar_siguiente() -> void:
	var listo: bool = args["respuestas"].has(args["indice"])
	_siguiente.disabled = not listo
	_siguiente.estilo = "ambar" if listo else "oscuro"
	_siguiente.lampara = "" if listo else "ambar"


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	match item["tipo"]:
		"ordenar":
			var ordenar := BloqueOrdenar.new()
			ordenar.iniciar(item, not respuesta.is_empty(), respuesta.get("acierto", true))
			if respuesta.is_empty():
				ordenar.respondido.connect(_al_ordenar.bind(indice))
			columna.add_child(ordenar)
		"simbolo":
			# En horizontal, lado a lado: apilados, el dibujo dejaría la pregunta fuera de la vista.
			var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
			disposicion.add_theme_constant_override("separation", 12)
			disposicion.mouse_filter = Control.MOUSE_FILTER_PASS
			columna.add_child(disposicion)
			var visor := _visor_simbolo(item)
			visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			disposicion.add_child(visor)
			var lado := _columna()
			lado.size_flags_stretch_ratio = 1.1
			disposicion.add_child(lado)
			_agregar_quiz(lado, _quiz_de_simbolo(item), respuesta, indice, "Identificación de símbolos")
		_:
			_agregar_quiz(columna, item, respuesta, indice)


func _agregar_quiz(columna: VBoxContainer, datos: Dictionary, respuesta: Dictionary, indice: int, rotulo := "Pregunta") -> void:
	var quiz := BloqueQuiz.new()
	quiz.rotulo = rotulo
	quiz.iniciar(datos, respuesta.get("elegida", -1))
	if respuesta.is_empty():
		quiz.respondido.connect(_al_responder.bind(indice))
	columna.add_child(quiz)


## El símbolo en una hoja de papel dentro del visor hundido, con la norma encima.
func _visor_simbolo(item: Dictionary) -> Control:
	var datos := raiz.contenido.simbolo(item["id"])
	var visor := VisorFicha.new(14.0)
	visor.name = "VisorSimbolo"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Identifique el símbolo"))
	var hoja := PiezasLeccion.papel(8.0)
	hoja.name = "Papel"
	columna.add_child(hoja)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 2)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoja.add_child(dentro)
	var titulo := PiezasLeccion.etiqueta(TITULOS_NORMA[item["norma"]], 12, Color("4b545c"), Tema.PESO_NEGRITA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dentro.add_child(titulo)
	var dibujo := VistaSvg.new()
	dibujo.color_etiquetas = Tema.TINTA
	dibujo.cargar(datos[item["norma"]])
	dibujo.custom_minimum_size.y = ALTO_SIMBOLO if raiz.vertical else ALTO_SIMBOLO * 0.72
	dentro.add_child(dibujo)
	return visor


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
	_actualizar_siguiente()


func avanzar() -> void:
	args["indice"] += 1
	raiz.reconstruir()


func aciertos() -> int:
	var total := 0
	for r: Dictionary in args["respuestas"].values():
		if r["acierto"]:
			total += 1
	return total


# --- Piezas de las pantallas de resultado ---

func _placa_con(rotulo: String, nombre: String) -> Array:
	var placa := PiezasLeccion.placa(16.0, 12.0)
	placa.name = nombre
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	if not rotulo.is_empty():
		columna.add_child(PiezasLeccion.rotulo(rotulo))
	return [placa, columna]


## Coloca las placas del resultado: en dos columnas en apaisado y apiladas en vertical.
func _disponer(izquierda: Array[Control], derecha: Array[Control]) -> void:
	var desplazable := _desplazable()
	add_child(desplazable)
	if not raiz.vertical and raiz.ancho_contenido() >= 720.0 and not derecha.is_empty():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		fila.mouse_filter = Control.MOUSE_FILTER_PASS
		desplazable.add_child(_ancho_lectura(fila))
		for lado: Array in [izquierda, derecha]:
			var col := _columna(12)
			for c: Control in lado:
				col.add_child(c)
			fila.add_child(col)
	else:
		var columna := _columna(12)
		desplazable.add_child(_ancho_lectura(columna))
		for c: Control in izquierda + derecha:
			columna.add_child(c)


## Botones del pie: el primero ámbar, los demás oscuros; en vertical, el ámbar ocupa su fila.
func _botones_pie(lista: Array) -> void:
	var caja: BoxContainer = VBoxContainer.new() if raiz.vertical and lista.size() > 2 else HBoxContainer.new()
	caja.name = "Botones"
	caja.add_theme_constant_override("separation", 10)
	add_child(caja)
	var fila_oscuros: BoxContainer = caja
	if caja is VBoxContainer:
		fila_oscuros = HBoxContainer.new()
		fila_oscuros.add_theme_constant_override("separation", 10)
	for i in lista.size():
		var datos: Array = lista[i]
		var b := BotonAri.new(datos[0], datos[1], "ambar" if i == 0 else "oscuro")
		b.name = datos[2] if datos.size() > 2 else "Boton_%d" % i
		b.custom_minimum_size.y = 50.0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if datos.size() > 3:
			b.insignia = datos[3]
		if i == 0 or caja is HBoxContainer:
			caja.add_child(b)
		else:
			fila_oscuros.add_child(b)
	if fila_oscuros != caja:
		if fila_oscuros.get_child_count() > 0:
			caja.add_child(fila_oscuros)
		else:
			fila_oscuros.free()
