class_name FilaMenu
extends PanelContainer
## Tarjeta de menú con icono de color, título, detalle, estado, marca de hecho y barra de
## avance. Distingue un toque de un arrastre, así se puede desplazar la lista empezando el
## gesto sobre cualquier fila.
##
## Opciones de iniciar():
##   color: Color del área (icono, barra y borde de la siguiente recomendada).
##   avance: fracción de 0 a 1 para la barra; sin barra si no se da.
##   hecho: marca verde de completado.
##   siguiente: resalta la fila como la recomendada.

signal pulsada

const ZONA_MUERTA := 14.0
const LADO_ICONO := 26.0
const LADO_CAJA_ICONO := 46.0

var activa := true
var color := Tema.ACENTO
var siguiente := false
var _presionada := false
var _inicio := Vector2.ZERO
var _encima := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_al_entrar)
	mouse_exited.connect(_al_salir)


func iniciar(titulo: String, detalle := "", icono := "", estado := "", esta_activa := true, opciones := {}) -> void:
	activa = esta_activa
	color = opciones.get("color", Tema.ACENTO)
	siguiente = opciones.get("siguiente", false)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)
	if not icono.is_empty():
		fila.add_child(_caja_icono(icono))
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos.add_theme_constant_override("separation", 2)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	textos.add_child(_texto(titulo, "Fuerte", Tema.TEXTO if activa else Tema.APAGADO))
	if not detalle.is_empty():
		textos.add_child(_texto(detalle, "Nota", Tema.TEXTO_SUAVE if activa else Tema.APAGADO))
	if opciones.has("avance"):
		textos.add_child(_barra(float(opciones["avance"])))
	if not estado.is_empty():
		fila.add_child(_chip(estado))
	if opciones.get("hecho", false):
		var marca := MarcaHecho.new()
		marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(marca)
	elif activa:
		var flecha := _texto("›", "Subtitulo", Tema.TEXTO_SUAVE)
		flecha.autowrap_mode = TextServer.AUTOWRAP_OFF
		flecha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(flecha)
	_actualizar_estilo()


## Icono blanco teñido con el color del área, sobre un cuadrado redondeado del mismo color.
func _caja_icono(icono: String) -> Control:
	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.custom_minimum_size = Vector2(LADO_CAJA_ICONO, LADO_CAJA_ICONO)
	caja.add_theme_stylebox_override("panel", Tema.caja(Color(color, 0.2 if activa else 0.08), 12, 10, 10))
	var dibujo := VistaSvg.new()
	dibujo.cargar({"svg": "res://art/iconos/%s.svg" % icono, "tamano": [64, 64]})
	dibujo.custom_minimum_size = Vector2(LADO_ICONO, LADO_ICONO)
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dibujo.modulate = color.lightened(0.35) if activa else Color(Tema.APAGADO, 0.6)
	caja.add_child(dibujo)
	return caja


func _chip(estado: String) -> Control:
	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fondo := Color(Tema.ACENTO, 0.16) if siguiente else Color(Tema.TEXTO_SUAVE, 0.12)
	caja.add_theme_stylebox_override("panel", Tema.caja(fondo, 13, 10, 3))
	var e := _texto(estado, "Nota", Tema.ACENTO if siguiente else (Tema.TEXTO_SUAVE if activa else Tema.APAGADO))
	e.autowrap_mode = TextServer.AUTOWRAP_OFF
	e.add_theme_font_size_override("font_size", Tema.tam(14))
	caja.add_child(e)
	return caja


func _barra(fraccion: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = clampf(fraccion, 0.0, 1.0)
	b.show_percentage = false
	b.custom_minimum_size.y = 5.0
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("fill", Tema.caja(Tema.HECHO if fraccion >= 1.0 else color, 3, 0, 0))
	return b


func _texto(texto: String, variante: String, color_texto: Color) -> Label:
	var e := Label.new()
	e.text = texto
	e.theme_type_variation = variante
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.add_theme_color_override("font_color", color_texto)
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
	var fondo := Tema.PANEL.darkened(0.2)
	var borde := Tema.BORDE.darkened(0.2)
	if activa:
		fondo = Tema.PANEL
		borde = color if siguiente else Tema.BORDE
		if _presionada:
			fondo = Tema.PANEL.lightened(0.08)
			borde = color
		elif _encima and not OS.has_feature("mobile"):
			fondo = Tema.PANEL.lightened(0.04)
			borde = color
	var caja := Tema.caja(fondo, Tema.RADIO_TARJETA, 14, 12, borde)
	if siguiente:
		caja.set_border_width_all(2)
	add_theme_stylebox_override("panel", caja)
