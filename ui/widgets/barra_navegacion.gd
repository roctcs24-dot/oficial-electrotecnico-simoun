class_name BarraNavegacion
extends PanelContainer
## Barra fija de las pantallas principales: Inicio, Escuela, Buque, Pañol y Progreso. Solo
## aparece en el primer nivel, para no quitar sitio al Taller ni a las misiones.

const SECCIONES := [
	["inicio", "Inicio", "inicio"],
	["escuela", "Escuela", "escuela"],
	["plano_barco", "Buque", "buque"],
	["panol", "Pañol", "herramientas"],
	["progreso", "Progreso", "progreso"],
]
const ALTO := 62.0
const LADO_ICONO := 24.0

const FONDO := [Color("1a222b"), Color("0e1419")]
const CANTO := Color("3a4856")

var raiz: Raiz
var _activo: Button


func iniciar(raiz_juego: Raiz, actual: String) -> void:
	raiz = raiz_juego
	mouse_filter = Control.MOUSE_FILTER_PASS
	# El fondo con relieve se dibuja en _draw(); la caja vacía solo deja el margen.
	var caja := StyleBoxEmpty.new()
	caja.content_margin_top = 4
	caja.content_margin_bottom = 4
	add_theme_stylebox_override("panel", caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 2)
	add_child(fila)
	for s: Array in SECCIONES:
		var b := _boton(s[0], s[1], s[2], s[0] == actual)
		if s[0] == actual:
			_activo = b
			b.resized.connect(queue_redraw)
			b.item_rect_changed.connect(queue_redraw)
		fila.add_child(b)


## Barra con relieve: sombra hacia arriba, degradado oscuro, canto de luz y, sobre la sección
## activa, una barra ámbar encendida con su halo.
func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	for i in 4:
		draw_rect(Rect2(0, -2.0 - i * 2.0, size.x, 2.0), Color(0, 0, 0, 0.12 - i * 0.025))
	DibujoAri.degradado(self, r, 0.0, FONDO)
	draw_line(Vector2(0, 0.5), Vector2(size.x, 0.5), CANTO, 1.0)
	draw_line(Vector2(0, 1.5), Vector2(size.x, 1.5), Color(1, 1, 1, 0.05), 1.0)
	if _activo != null and _activo.is_inside_tree():
		var b := _activo.get_global_rect()
		var x0 := b.position.x - get_global_rect().position.x
		var ancho := b.size.x * 0.56
		var barra := Rect2(x0 + (b.size.x - ancho) / 2.0, 0.0, ancho, 3.0)
		for i in 4:
			DibujoAri.relleno(self, barra.grow(1.5 + i * 1.5), 3.0 + i * 1.5, Color(Relieve.AMBAR_HALO, 0.12 - i * 0.025))
		DibujoAri.relleno(self, barra, 1.5, Relieve.AMBAR)
		draw_line(barra.position + Vector2(2, 0.5), Vector2(barra.end.x - 2.0, 0.5), Color("ffe3a0"), 1.0)


func _boton(seccion: String, texto: String, icono: String, activo: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.icon = VistaSvg.rasterizar("res://art/iconos/%s.svg" % icono, LADO_ICONO / 64.0 * 2.0)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = ALTO
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_theme_font_size_override("font_size", Tema.tam(13))
	b.add_theme_constant_override("icon_max_width", int(LADO_ICONO))
	var color := Tema.ACENTO if activo else Tema.APAGADO
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(clave, color)
	for clave in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(clave, color)
	var vacia := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(estado, vacia)
	if not activo:
		b.pressed.connect(raiz.ir_a_seccion.bind(seccion))
	return b
