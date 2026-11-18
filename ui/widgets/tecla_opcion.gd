class_name TeclaOpcion
extends Button
## Tecla de una opción en las preguntas de la lección, del examen y del repaso: gris con relieve
## y una moneda con la letra. Al contestar, la correcta se enciende en verde con su lámpara, la
## elegida mal en rojo y las demás quedan apagadas. Sin letra, la moneda va vacía (pasos de
## ordenar).

const ALTO := 50.0
const RADIO := 11.0
const GRIS := [Color("34414e"), Color("2d3946"), Color("27323d"), Color("1e2730")]
const BRILLO := [0.0, 0.48, 0.52, 1.0]

## «»: sin contestar; «ok»: la correcta; «mal»: la elegida equivocada; «apagada»: las demás.
var estado := "":
	set(valor):
		estado = valor
		_colores_texto()
		if _fondo != null:
			_fondo.queue_redraw()
var letra := ""
var _fondo: Fondo


class Fondo:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		show_behind_parent = true
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var t := get_parent() as TeclaOpcion
		var r := Rect2(Vector2(1, 1), size - Vector2(2, 3))
		var hundida := t.get_draw_mode() in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
		if hundida:
			r.position.y += 1.0
		var luz := Color(1, 1, 1, 0.16)
		var borde := Color("0d1318")
		match t.estado:
			"ok":
				_halo(r, Relieve.VERDE_MARCA)
				borde = Color("1f9d50")
				luz = Color(0.78, 1.0, 0.86, 0.2)
			"mal":
				_halo(r, Color("ff3c28"))
				borde = Color("c0352b")
				luz = Color(1.0, 0.82, 0.78, 0.2)
			"apagada":
				luz = Color(1, 1, 1, 0.07)
		var colores: Array = TeclaOpcion.GRIS
		if hundida:
			colores = colores.map(func(c: Color) -> Color: return c.darkened(0.15))
		DibujoAri.pieza(self, r, TeclaOpcion.RADIO, colores, TeclaOpcion.BRILLO, borde, luz, 0.0 if hundida else 0.5)
		var tinte := Color.TRANSPARENT
		if t.estado == "ok":
			tinte = Color(0.13, 0.77, 0.37, 0.22)
		elif t.estado == "mal":
			tinte = Color(0.93, 0.16, 0.11, 0.24)
		if tinte.a > 0.0:
			DibujoAri.degradado(self, r.grow(-1.0), TeclaOpcion.RADIO - 1.0, [tinte, Color(tinte, 0.02)], [], Rect2())
		# Moneda con la letra.
		var c := Vector2(r.position.x + 24.0, r.get_center().y)
		TeclaOpcion.moneda_letra(self, c, 13.0, t.letra, t.estado)
		if t.estado in ["ok", "mal"]:
			PiezasAri.lampara(self, Vector2(r.end.x - 18.0, r.get_center().y), 5.5, "verde" if t.estado == "ok" else "rojo", 1.0)

	func _halo(r: Rect2, color: Color) -> void:
		for i in 3:
			DibujoAri.borde(self, r.grow(1.0 + i * 1.6), TeclaOpcion.RADIO + 1.0 + i * 1.6, Color(color, 0.22 - i * 0.06), 1.8)


## Moneda con la letra de la opción: metálica sin contestar, verde la correcta y roja la mala.
static func moneda_letra(ci: CanvasItem, c: Vector2, r: float, t: String, estado_moneda := "") -> void:
	if estado_moneda == "ok":
		Relieve.halo(ci, c, r * 1.8, Relieve.VERDE_MARCA, 1.0)
	elif estado_moneda == "mal":
		Relieve.halo(ci, c, r * 1.8, Color("ff4a3a"), 1.0)
	ci.draw_circle(c + Vector2(0, 1.5), r + 2.6, Color(0, 0, 0, 0.5))
	PiezasAri._disco(ci, c, r + 2.2, Color("ffffff"), Color("2b3238"))
	var tinta := Color("c9d3dc")
	match estado_moneda:
		"ok":
			PiezasAri._disco(ci, c, r, Color("b6ffd0"), Color("0d6b30"), Vector2(-0.2, -0.35), 10)
			tinta = Color("06210f")
		"mal":
			PiezasAri._disco(ci, c, r, Color("ff8a7a"), Color("8f120b"), Vector2(-0.2, -0.35), 10)
			tinta = Color("2a0503")
		_:
			PiezasAri._disco(ci, c, r, Relieve.GRIS_OFF[0], Relieve.GRIS_OFF[2], Vector2(-0.2, -0.3), 8)
	PiezasAri._elipse(ci, c + Vector2(-r * 0.15, -r * 0.5), Vector2(r * 0.6, r * 0.25), 0.0, Color(1, 1, 1, 0.35))
	if not t.is_empty():
		PiezasAri.texto(ci, t, c.x, c.y + r * 0.38, r * 1.05, tinta, Tema.PESO_NEGRITA)


func _init(texto := "", p_letra := "") -> void:
	text = texto
	letra = p_letra
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(48, ALTO)
	add_theme_font_override("font", Tema.fuente(Tema.PESO_NEGRITA))
	add_theme_font_size_override("font_size", Tema.tam(15))
	var vacia := StyleBoxEmpty.new()
	vacia.content_margin_left = 50
	vacia.content_margin_right = 36
	vacia.content_margin_top = 8
	vacia.content_margin_bottom = 9
	for e in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(e, vacia)
	_colores_texto()
	_fondo = Fondo.new()
	add_child(_fondo, false, Node.INTERNAL_MODE_FRONT)
	for s in [button_down, button_up, mouse_entered, mouse_exited]:
		s.connect(_fondo.queue_redraw)


func _colores_texto() -> void:
	var tinta := Color("eef2f5") if estado != "apagada" else Color("8794a0")
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(clave, tinta)
