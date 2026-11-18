class_name BloqueQuiz
extends PanelContainer
## Pregunta de opción múltiple en una placa con relieve: rótulo, caso práctico en una hoja del
## libro de guardia (si lo hay), la pregunta y una tecla por opción con su letra. Se responde una
## vez: la correcta se enciende en verde, la elegida mal en rojo, y debajo sale la explicación.

const LETRAS := "ABCDEFGH"

signal respondido(acierto: bool, indice: int)

## Rótulo de la placa, como «PREGUNTA» o «IDENTIFICACIÓN DE SÍMBOLOS»; vacío, sin rótulo.
var rotulo := "Pregunta"
## Sin placa propia, para ponerla dentro de otra.
var sin_placa := false
var _datos := {}
var _columna: VBoxContainer
var _botones: Array[Button] = []
var _explicacion: Label
var _caja_explicacion: Control


## respuesta es la opción ya elegida si se vuelve a una página, o -1.
func iniciar(datos: Dictionary, respuesta := -1) -> void:
	_datos = datos
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new() if sin_placa else Relieve.estilo_placa(14.0, 12.0))
	_columna = VBoxContainer.new()
	_columna.add_theme_constant_override("separation", 7)
	_columna.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_columna)
	if datos.has("caso"):
		_columna.add_child(PiezasLeccion.rotulo("Caso práctico"))
		_columna.add_child(hoja_caso(str(datos["caso"])))
	elif not rotulo.is_empty():
		_columna.add_child(PiezasLeccion.rotulo(rotulo))
	var pregunta := PiezasLeccion.etiqueta(TextoTecnico.unir_unidades(datos["pregunta"]), 17, Color.WHITE, Tema.PESO_NEGRITA)
	pregunta.name = "Pregunta"
	_columna.add_child(pregunta)
	var opciones: Array = datos["opciones"]
	for i in opciones.size():
		var b := TeclaOpcion.new(TextoTecnico.unir_unidades(opciones[i]), LETRAS[i] if i < LETRAS.length() else "")
		b.pressed.connect(elegir.bind(i))
		_columna.add_child(b)
		_botones.append(b)
	if respuesta >= 0:
		_mostrar_resultado(respuesta)


## Caso práctico en una hoja rayada del libro de guardia.
static func hoja_caso(texto: String) -> Control:
	var hoja := HojaGuardia.new()
	var t := PiezasLeccion.texto_rico(TextoTecnico.unir_unidades(texto), 15, PiezasLeccion.TINTA_PAPEL)
	hoja.add_child(t)
	return hoja


func elegir(indice: int) -> void:
	_mostrar_resultado(indice)
	respondido.emit(indice == int(_datos["correcta"]), indice)


func _mostrar_resultado(indice: int) -> void:
	var correcta := int(_datos["correcta"])
	for i in _botones.size():
		var b := _botones[i] as TeclaOpcion
		b.disabled = true
		if i == correcta:
			b.estado = "ok"
		elif i == indice:
			b.estado = "mal"
		else:
			b.estado = "apagada"
	if _caja_explicacion != null:
		_caja_explicacion.queue_free()
	_caja_explicacion = PiezasLeccion.explicacion(indice == correcta, TextoTecnico.unir_unidades(str(_datos["explicacion"])))
	_columna.add_child(_caja_explicacion)
	_explicacion = _caja_explicacion.find_child("Texto", true, false) as Label


## Hoja crema con renglones y el margen rojo del libro de guardia.
class HojaGuardia:
	extends PanelContainer

	func _init() -> void:
		name = "CasoPractico"
		mouse_filter = Control.MOUSE_FILTER_PASS
		var e := Relieve.estilo_papel(10.0)
		e.content_margin_left = 30.0
		add_theme_stylebox_override("panel", e)

	func _draw() -> void:
		var y := 30.0
		while y < size.y - 4.0:
			draw_line(Vector2(4, y), Vector2(size.x - 4.0, y), Color(0.55, 0.5, 0.4, 0.22), 1.0)
			y += 22.0
		draw_line(Vector2(18, 2), Vector2(18, size.y - 2.0), Color(0.85, 0.4, 0.4, 0.7), 1.0)
