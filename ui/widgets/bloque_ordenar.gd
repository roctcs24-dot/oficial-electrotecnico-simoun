class_name BloqueOrdenar
extends PanelContainer
## Ordenar pasos tocándolos. Un toque equivocado no avanza y se cuenta como error.

signal respondido(errores: int)

var _datos := {}
var _hechos: VBoxContainer
var _pendientes: VBoxContainer
var _aviso: Label
var _explicacion: Label
var _siguiente := 0
var _errores := 0


## ya_resuelto muestra el resultado si se vuelve a una página ya completada.
func iniciar(datos: Dictionary, ya_resuelto := false) -> void:
	_datos = datos
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	add_child(columna)
	var pregunta := Label.new()
	pregunta.text = datos["pregunta"]
	pregunta.theme_type_variation = "Subtitulo"
	pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(pregunta)
	_hechos = VBoxContainer.new()
	_hechos.add_theme_constant_override("separation", 4)
	columna.add_child(_hechos)
	_aviso = Label.new()
	_aviso.add_theme_color_override("font_color", Tema.ACENTO)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_aviso)
	_pendientes = VBoxContainer.new()
	_pendientes.add_theme_constant_override("separation", 8)
	columna.add_child(_pendientes)
	_explicacion = Label.new()
	_explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explicacion.visible = false
	columna.add_child(_explicacion)
	if ya_resuelto:
		for paso: String in datos["pasos"]:
			_agregar_hecho(paso)
		_siguiente = datos["pasos"].size()
		_mostrar_explicacion()
	else:
		_crear_pendientes()


func _crear_pendientes() -> void:
	var indices := range(_datos["pasos"].size())
	# Mezcla fija, para que al girar el celular no se reordene.
	var azar := RandomNumberGenerator.new()
	azar.seed = hash(_datos["tema"])
	for i in range(indices.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var temporal: int = indices[i]
		indices[i] = indices[j]
		indices[j] = temporal
	for i: int in indices:
		var b := Button.new()
		b.text = _datos["pasos"][i]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.pressed.connect(_tocar.bind(i, b))
		_pendientes.add_child(b)


func _tocar(indice: int, boton: Button) -> void:
	if indice != _siguiente:
		_errores += 1
		_aviso.text = "Paso fuera de secuencia. Revise qué debe ejecutarse antes."
		return
	_aviso.text = ""
	_agregar_hecho(boton.text)
	_pendientes.remove_child(boton)
	boton.queue_free()
	_siguiente += 1
	if _siguiente == _datos["pasos"].size():
		_mostrar_explicacion()
		respondido.emit(_errores)


func _agregar_hecho(paso: String) -> void:
	var e := Label.new()
	e.text = "%d. %s" % [_hechos.get_child_count() + 1, paso]
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.add_theme_color_override("font_color", Color("9fe3b5"))
	_hechos.add_child(e)


func _mostrar_explicacion() -> void:
	_explicacion.text = _datos["explicacion"]
	_explicacion.visible = true
