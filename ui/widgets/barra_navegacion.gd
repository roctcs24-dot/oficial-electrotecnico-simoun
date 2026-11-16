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

var raiz: Raiz


func iniciar(raiz_juego: Raiz, actual: String) -> void:
	raiz = raiz_juego
	mouse_filter = Control.MOUSE_FILTER_PASS
	var caja := Tema.caja(Tema.FONDO.darkened(0.25), 0, 4, 4, Color.TRANSPARENT)
	caja.border_color = Tema.BORDE
	caja.border_width_top = 1
	add_theme_stylebox_override("panel", caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 2)
	add_child(fila)
	for s: Array in SECCIONES:
		fila.add_child(_boton(s[0], s[1], s[2], s[0] == actual))


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
