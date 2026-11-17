class_name PanelAri
extends PanelContainer
## Panel del marco de simulador: chapa azul con relieve y, si lleva título, una cabecera con
## brillo, como GENERACIÓN, CONSEJOS o ALARMAS (en rojo).

const RADIO := 6.0
const ALTO_CABECERA := 24.0

var contenido: VBoxContainer
var cabecera: Label
var colores: Array = Tema.ARI_PANEL
var radio := RADIO
## Línea clara en el borde de arriba, para las hojas que suben desde el pie.
var linea_arriba := false


class Cabecera:
	extends PanelContainer
	var colores: Array

	func _init(c: Array) -> void:
		colores = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size.y = PanelAri.ALTO_CABECERA
		var vacia := StyleBoxEmpty.new()
		vacia.content_margin_left = 8
		vacia.content_margin_right = 8
		add_theme_stylebox_override("panel", vacia)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DibujoAri.degradado(self, Rect2(r.position, r.size + Vector2(0, PanelAri.RADIO * 2.0)), PanelAri.RADIO - 1.0, colores, DibujoAri.BRILLO, r)
		draw_line(Vector2(0, size.y - 0.5), Vector2(size.x, size.y - 0.5), Tema.ARI_BORDE, 1.0)


## Fuente con letras espaciadas para los rótulos en mayúsculas.
static func fuente_rotulo(peso := Tema.PESO_NEGRITA, espacio := 2) -> Font:
	var f := FontVariation.new()
	f.base_font = Tema.fuente(peso)
	f.spacing_glyph = espacio
	return f


func _init(titulo := "", icono := "", rojo := false, margen := 6, colores_cabecera: Array = []) -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var vacia := StyleBoxEmpty.new()
	vacia.set_content_margin_all(1)
	add_theme_stylebox_override("panel", vacia)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(columna)
	if not titulo.is_empty():
		var tonos: Array = colores_cabecera if not colores_cabecera.is_empty() else (Tema.ARI_CABECERA_ROJA if rojo else Tema.ARI_CABECERA)
		var cab := Cabecera.new(tonos)
		columna.add_child(cab)
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 6)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cab.add_child(fila)
		if not icono.is_empty():
			var ic := TextureRect.new()
			ic.texture = VistaSvg.rasterizar("res://art/iconos/%s.svg" % icono, 14.0 / 64.0 * 2.0)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(14, 14)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fila.add_child(ic)
		cabecera = Label.new()
		cabecera.text = titulo.to_upper()
		cabecera.add_theme_font_override("font", fuente_rotulo())
		cabecera.add_theme_font_size_override("font_size", Tema.tam(12))
		cabecera.add_theme_color_override("font_color", Tema.ARI_TEXTO)
		cabecera.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		cabecera.add_theme_constant_override("shadow_offset_y", 1)
		fila.add_child(cabecera)
	var margenes := MarginContainer.new()
	margenes.mouse_filter = Control.MOUSE_FILTER_PASS
	for lado in ["left", "right", "top", "bottom"]:
		margenes.add_theme_constant_override("margin_" + lado, margen)
	columna.add_child(margenes)
	contenido = VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 3)
	contenido.mouse_filter = Control.MOUSE_FILTER_PASS
	margenes.add_child(contenido)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	DibujoAri.sombra(self, r, radio, 0.35, Vector2(0, 3))
	DibujoAri.degradado(self, r, radio, colores)
	DibujoAri.borde(self, r, radio, Tema.ARI_BORDE)
	DibujoAri.brillo_superior(self, r.grow(-1.0), radio, Color(1, 1, 1, 0.5) if linea_arriba else Color(1, 1, 1, 0.18))


## Texto del marco: blanco azulado, con el tamaño de letra elegido en Mi progreso.
static func texto(t: String, puntos := 12.0, color := Tema.ARI_TEXTO, peso := Tema.PESO_MEDIO) -> Label:
	var e := Label.new()
	e.text = t
	e.add_theme_font_override("font", Tema.fuente(peso))
	e.add_theme_font_size_override("font_size", Tema.tam(puntos))
	e.add_theme_color_override("font_color", color)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e
