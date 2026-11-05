class_name FilaMenu
extends PanelContainer
## Fila de menú con icono, título, detalle y estado. Distingue un toque de un arrastre, así
## se puede desplazar la lista empezando el gesto sobre cualquier fila.

signal pulsada

const ZONA_MUERTA := 14.0
const LADO_ICONO := 34.0

var activa := true
var _presionada := false
var _inicio := Vector2.ZERO
var _encima := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_al_entrar)
	mouse_exited.connect(_al_salir)


func iniciar(titulo: String, detalle := "", icono := "", estado := "", esta_activa := true) -> void:
	activa = esta_activa
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)
	if not icono.is_empty():
		var dibujo := VistaSvg.new()
		dibujo.cargar({"svg": "res://art/iconos/%s.svg" % icono, "tamano": [64, 64]})
		dibujo.custom_minimum_size = Vector2(LADO_ICONO, LADO_ICONO)
		dibujo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not activa:
			dibujo.modulate = Color(1.0, 1.0, 1.0, 0.4)
		fila.add_child(dibujo)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos.add_theme_constant_override("separation", 0)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	textos.add_child(_texto(titulo, "Fuerte", Tema.TEXTO if activa else Tema.APAGADO))
	if not detalle.is_empty():
		textos.add_child(_texto(detalle, "Nota", Tema.TEXTO_SUAVE if activa else Tema.APAGADO))
	if not estado.is_empty():
		var chip := _texto(estado, "Nota", Tema.ACENTO if activa else Tema.APAGADO)
		chip.autowrap_mode = TextServer.AUTOWRAP_OFF
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(chip)
	if activa:
		var flecha := _texto("›", "Subtitulo", Tema.TEXTO_SUAVE)
		flecha.autowrap_mode = TextServer.AUTOWRAP_OFF
		flecha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(flecha)
	_actualizar_estilo()


func _texto(texto: String, variante: String, color: Color) -> Label:
	var e := Label.new()
	e.text = texto
	e.theme_type_variation = variante
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.add_theme_color_override("font_color", color)
	return e


func _gui_input(evento: InputEvent) -> void:
	if not activa:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_presionada = true
			_inicio = evento.position
			_actualizar_estilo()
		elif _presionada:
			_presionada = false
			_actualizar_estilo()
			if Rect2(Vector2.ZERO, size).has_point(evento.position):
				pulsada.emit()
	elif evento is InputEventMouseMotion and _presionada:
		if evento.position.distance_to(_inicio) > ZONA_MUERTA:
			cancelar()


## La lista la llama al empezar a desplazarse.
func cancelar() -> void:
	_presionada = false
	_actualizar_estilo()


func _al_entrar() -> void:
	_encima = true
	_actualizar_estilo()


func _al_salir() -> void:
	_encima = false
	_presionada = false
	_actualizar_estilo()


func _actualizar_estilo() -> void:
	var fondo := Tema.PANEL.darkened(0.15)
	var borde := Tema.PANEL.lightened(0.08)
	if activa:
		fondo = Tema.BOTON
		borde = Tema.BORDE
		if _presionada:
			fondo = Tema.SELECCION
			borde = Tema.SELECCION.lightened(0.2)
		elif _encima and not OS.has_feature("mobile"):
			fondo = Tema.BOTON.lightened(0.06)
			borde = Tema.ACENTO
	add_theme_stylebox_override("panel", Tema.caja(fondo, Tema.RADIO, 12, 11, borde))
