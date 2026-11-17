class_name FilaParte
extends PanelContainer
## Fila de una lista numerada: la moneda con el número y el texto al lado. Sirve para las partes
## de una ficha, que se enlazan con las marcas del dibujo, y para los pasos de una animación.
## La elegida se ilumina en ámbar. Distingue un toque de un arrastre, como ControlToque.

signal tocada(numero: int)

const ZONA_MUERTA := 14.0

var numero := 0
var elegida := false
var marca: MarcaNumero
var texto: RichTextLabel
var _presionado := false
var _inicio := Vector2.ZERO


func _init(p_numero := 0, bbcode := "", tam := 15) -> void:
	numero = p_numero
	name = "Parte_%d" % p_numero
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size.y = 48.0
	var vacio := StyleBoxEmpty.new()
	vacio.content_margin_left = 6
	vacio.content_margin_right = 8
	vacio.content_margin_top = 5
	vacio.content_margin_bottom = 5
	add_theme_stylebox_override("panel", vacio)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)
	marca = MarcaNumero.new()
	marca.numero = numero
	marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(marca)
	texto = RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texto.mouse_filter = Control.MOUSE_FILTER_PASS
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		texto.add_theme_font_size_override(clave, Tema.tam(tam))
	texto.add_theme_color_override("default_color", Color("d6dde3"))
	texto.text = bbcode
	fila.add_child(texto)


func poner(p_elegida: bool, apagada := false) -> void:
	elegida = p_elegida
	marca.elegida = p_elegida
	marca.apagada = apagada
	marca.queue_redraw()
	texto.modulate.a = 0.55 if apagada else 1.0
	queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		var boton := evento as InputEventMouseButton
		if boton.pressed:
			_presionado = true
			_inicio = boton.position
			queue_redraw()
		elif _presionado:
			_presionado = false
			queue_redraw()
			if Rect2(Vector2.ZERO, size).has_point(boton.position):
				tocar()
	elif evento is InputEventMouseMotion and _presionado:
		if (evento as InputEventMouseMotion).position.distance_to(_inicio) > ZONA_MUERTA:
			cancelar_toque()


func cancelar_toque() -> void:
	if _presionado:
		_presionado = false
		queue_redraw()


func tocar() -> void:
	tocada.emit(numero)


func _draw() -> void:
	var caja := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	if elegida:
		for i in 3:
			DibujoAri.borde(self, caja.grow(1.0 + i * 1.5), 9.0 + i * 1.5, Color(Relieve.AMBAR_HALO, 0.16 - i * 0.05), 1.5)
		DibujoAri.degradado(self, caja, 9.0, [Color(1.0, 0.76, 0.23, 0.2), Color(1.0, 0.76, 0.23, 0.05)])
		DibujoAri.borde(self, caja, 9.0, Color(Relieve.AMBAR, 0.75), 1.2)
	elif _presionado:
		DibujoAri.relleno(self, caja, 9.0, Color(1, 1, 1, 0.06))


## Moneda pequeña con un número, la misma que las marcas del dibujo.
class MarcaNumero:
	extends Control

	var numero := 0
	var elegida := false
	var apagada := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(34, 34)

	func _draw() -> void:
		Relieve.marca(self, size / 2.0, minf(size.x, size.y) * 0.33, numero, false, apagada, false)
