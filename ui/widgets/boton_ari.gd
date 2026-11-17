class_name BotonAri
extends Button
## Botón del marco de simulador: azul con brillo, ámbar cuando está activo y rojo para las
## alarmas. La zona táctil mide al menos 48; el dibujo queda algo más adentro.

const ESTILOS := {
	"azul": Tema.ARI_BOTON,
	"ambar": Tema.ARI_AMBAR,
	"rojo": Tema.ARI_ROJO,
	"claro": [Color("eef2f5"), Color("d8e0e7"), Color("ccd5dd"), Color("b4c0cb")],
	# Gris oscuro con relieve, para el inicio y la Escuela, que siguen con el tema oscuro.
	"oscuro": [Color("3a4754"), Color("2d3843"), Color("26303a"), Color("1e2730")],
}
const LADO_ICONO := 18.0

var estilo := "azul":
	set(valor):
		estilo = valor
		_colores_texto()
		if _fondo != null:
			_fondo.queue_redraw()
## Signo dibujado en lugar de texto: «atras», «anterior», «siguiente» o «ayuda».
var signo := "":
	set(valor):
		signo = valor
		if _fondo != null:
			_fondo.queue_redraw()
## Distancia entre el borde de la zona táctil y el dibujo del botón.
var hueco := Vector2(3.0, 3.0)
## Número en una insignia roja en la esquina, como los temas del repaso; vacío, sin insignia.
var insignia := "":
	set(valor):
		insignia = valor
		if _fondo != null:
			_fondo.queue_redraw()
## Lámpara piloto a la izquierda del texto («rojo», «verde» o «ambar»); vacío, sin lámpara.
var lampara := "":
	set(valor):
		lampara = valor
		var vacia := get_theme_stylebox("normal") as StyleBoxEmpty
		if vacia != null:
			vacia.content_margin_left = 30.0 if not valor.is_empty() else 10.0
		if _fondo != null:
			_fondo.queue_redraw()
var lampara_encendida := false:
	set(valor):
		lampara_encendida = valor
		if _fondo != null:
			_fondo.queue_redraw()
var redondo := false
var radio := 6.0
var _fondo: Fondo


class Fondo:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		show_behind_parent = true
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var b := get_parent() as BotonAri
		var r := Rect2(b.hueco, size - b.hueco * 2.0)
		var hundido := b.get_draw_mode() in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
		var colores: Array = BotonAri.ESTILOS.get(b.estilo, Tema.ARI_BOTON)
		if b.disabled:
			colores = colores.map(func(c: Color) -> Color: return c.darkened(0.35).lerp(Color("5a6f82"), 0.5))
		elif hundido:
			colores = colores.map(func(c: Color) -> Color: return c.darkened(0.18))
		var rad := minf(r.size.x, r.size.y) / 2.0 if b.redondo else b.radio
		if hundido:
			r.position.y += 1.0
		DibujoAri.pieza(self, r, rad, colores, DibujoAri.BRILLO, Tema.ARI_BORDE, Color(1, 1, 1, 0.25 if hundido else 0.5), 0.0 if hundido else 0.4)
		var tinta := Tema.ARI_TEXTO_OSCURO if b.estilo in ["ambar", "claro"] else Color.WHITE
		var c := r.get_center()
		var tam := minf(r.size.x, r.size.y)
		match b.signo:
			"anterior":
				DibujoAri.galon(self, c, tam * 0.42, -1, tinta)
			"siguiente":
				DibujoAri.galon(self, c, tam * 0.42, 1, tinta)
			"atras":
				DibujoAri.flecha_volver(self, c, tam * 0.62, tinta)
			"ayuda":
				var f := Tema.fuente(Tema.PESO_NEGRITA)
				var t := roundi(tam * 0.5)
				var w := f.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
				draw_string(f, c + Vector2(-w / 2.0, f.get_ascent(t) * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, t, tinta)
		if not b.lampara.is_empty():
			PiezasAri.lampara(self, Vector2(r.position.x + 15.0, c.y), 5.0, b.lampara, 1.0 if b.lampara_encendida else 0.0)
		if not b.insignia.is_empty():
			Relieve.insignia(self, Vector2(r.end.x - 4.0, r.position.y + 4.0), b.insignia, Tema.tam(11))


func _init(texto := "", al_pulsar := Callable(), estilo_inicial := "azul", icono := "") -> void:
	text = texto
	estilo = estilo_inicial
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(48, 48)
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_font_override("font", Tema.fuente(Tema.PESO_NEGRITA))
	add_theme_font_size_override("font_size", Tema.tam(13))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	add_theme_constant_override("shadow_offset_y", 1)
	add_theme_constant_override("shadow_offset_x", 0)
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("icon_max_width", int(LADO_ICONO))
	var vacia := StyleBoxEmpty.new()
	vacia.content_margin_left = 10
	vacia.content_margin_right = 10
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estado, vacia)
	if not icono.is_empty():
		self.icon = VistaSvg.rasterizar("res://art/iconos/%s.svg" % icono, LADO_ICONO / 64.0 * 2.0)
		expand_icon = true
	_colores_texto()
	_fondo = Fondo.new()
	add_child(_fondo, false, Node.INTERNAL_MODE_FRONT)
	for s in [button_down, button_up, mouse_entered, mouse_exited]:
		s.connect(_fondo.queue_redraw)
	toggled.connect(func(_p: bool) -> void: _fondo.queue_redraw())
	if al_pulsar.is_valid():
		pressed.connect(al_pulsar)


## Ancho mínimo para que el texto quepa entero, sin puntos suspensivos.
func ajustar_ancho() -> void:
	var tam := get_theme_font_size("font_size")
	var ancho := Tema.fuente(Tema.PESO_NEGRITA).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	ancho += 24.0 + (20.0 if not lampara.is_empty() else 0.0) + (LADO_ICONO + 6.0 if icon != null else 0.0)
	custom_minimum_size.x = maxf(custom_minimum_size.x, ceilf(ancho))


func _colores_texto() -> void:
	var tinta := Tema.ARI_TEXTO_OSCURO if estilo in ["ambar", "claro"] else Color.WHITE
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		add_theme_color_override(clave, tinta)
	add_theme_color_override("font_disabled_color", Color(tinta, 0.5))
	for clave in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		add_theme_color_override(clave, tinta)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.0 if estilo in ["ambar", "claro"] else 0.45))
