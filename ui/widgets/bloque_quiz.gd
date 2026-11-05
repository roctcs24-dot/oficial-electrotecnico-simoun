class_name BloqueQuiz
extends PanelContainer
## Pregunta de opción múltiple. Se responde una vez y siempre explica la respuesta correcta.

signal respondido(acierto: bool, indice: int)

var _datos := {}
var _columna: VBoxContainer
var _botones: Array[Button] = []
var _explicacion: Label


## respuesta es la opción ya elegida si se vuelve a una página, o -1.
func iniciar(datos: Dictionary, respuesta := -1) -> void:
	_datos = datos
	_columna = VBoxContainer.new()
	_columna.add_theme_constant_override("separation", 8)
	add_child(_columna)
	var pregunta := Label.new()
	pregunta.text = datos["pregunta"]
	pregunta.theme_type_variation = "Subtitulo"
	pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_columna.add_child(pregunta)
	var opciones: Array = datos["opciones"]
	for i in opciones.size():
		var b := Button.new()
		b.text = opciones[i]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(elegir.bind(i))
		_columna.add_child(b)
		_botones.append(b)
	_explicacion = Label.new()
	_explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explicacion.visible = false
	_columna.add_child(_explicacion)
	if respuesta >= 0:
		_mostrar_resultado(respuesta)


func elegir(indice: int) -> void:
	_mostrar_resultado(indice)
	respondido.emit(indice == int(_datos["correcta"]), indice)


func _mostrar_resultado(indice: int) -> void:
	var correcta := int(_datos["correcta"])
	for i in _botones.size():
		var b := _botones[i]
		b.disabled = true
		if i == correcta:
			_pintar(b, Tema.ACIERTO)
		elif i == indice:
			_pintar(b, Tema.FALLO)
	var inicio := "Correcto. " if indice == correcta else "No es correcto. "
	_explicacion.text = inicio + _datos["explicacion"]
	_explicacion.visible = true


func _pintar(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("disabled", Tema.caja(color))
	b.add_theme_color_override("font_disabled_color", Tema.TEXTO)
