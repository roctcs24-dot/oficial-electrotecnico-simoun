class_name Interruptor
extends Button
## Interruptor deslizante de encendido y apagado: verde con el botón a la derecha cuando está
## activo. Es un botón conmutable de 48 de alto para el dedo.

const ANCHO_PISTA := 64.0
const ALTO_PISTA := 34.0


func _init() -> void:
	toggle_mode = true
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(76.0, 48.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for estilo in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estilo, StyleBoxEmpty.new())
	toggled.connect(func(_activo: bool) -> void: queue_redraw())


func _draw() -> void:
	var pista := Rect2((size - Vector2(ANCHO_PISTA, ALTO_PISTA)) / 2.0, Vector2(ANCHO_PISTA, ALTO_PISTA))
	var fondo := Tema.caja(Tema.HECHO if button_pressed else Tema.BOTON, int(ALTO_PISTA / 2.0), 0, 0, Tema.BORDE if not button_pressed else Color.TRANSPARENT)
	draw_style_box(fondo, pista)
	var r := ALTO_PISTA / 2.0 - 4.0
	var x := pista.end.x - r - 4.0 if button_pressed else pista.position.x + r + 4.0
	draw_circle(Vector2(x, pista.get_center().y), r, Tema.TEXTO)
