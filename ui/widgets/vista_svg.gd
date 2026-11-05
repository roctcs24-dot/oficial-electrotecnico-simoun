class_name VistaSvg
extends Control
## Dibuja un SVG centrado y a la resolución real de la pantalla, sin perder nitidez.
## Godot no dibuja el texto de los SVG, por eso las etiquetas van aparte, en coordenadas del dibujo.

const LADO_MAX_PX := 2048.0

static var _fuentes := {}

var ruta := ""
var tamano_svg := Vector2(100.0, 100.0)
var etiquetas: Array = []
var color_etiquetas := Color("eceee8")
var _textura: Texture2D
var _escala_textura := 0.0


## Devuelve null si el archivo no existe o no se puede interpretar.
static func rasterizar(ruta_svg: String, escala: float) -> Texture2D:
	if not _fuentes.has(ruta_svg):
		if not FileAccess.file_exists(ruta_svg):
			return null
		_fuentes[ruta_svg] = FileAccess.get_file_as_string(ruta_svg)
	var imagen := Image.new()
	if imagen.load_svg_from_string(_fuentes[ruta_svg], escala) != OK:
		return null
	return ImageTexture.create_from_image(imagen)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func cargar(definicion: Dictionary) -> void:
	ruta = definicion["svg"]
	var t: Array = definicion["tamano"]
	tamano_svg = Vector2(t[0], t[1])
	etiquetas = definicion.get("etiquetas", [])
	_textura = null
	_escala_textura = 0.0
	queue_redraw()


func rect_imagen() -> Rect2:
	var escala := minf(size.x / tamano_svg.x, size.y / tamano_svg.y)
	var tam := tamano_svg * escala
	return Rect2((size - tam) / 2.0, tam)


func a_local(x: float, y: float) -> Vector2:
	var r := rect_imagen()
	return r.position + Vector2(x, y) * (r.size.x / tamano_svg.x)


func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED:
		queue_redraw()


func _actualizar_textura() -> void:
	var fisico := rect_imagen().size * get_window().content_scale_factor
	var escala := fisico.x / tamano_svg.x
	escala = minf(escala, LADO_MAX_PX / maxf(tamano_svg.x, tamano_svg.y))
	if escala <= 0.0 or ruta.is_empty():
		return
	if _textura != null and absf(escala - _escala_textura) / _escala_textura < 0.05:
		return
	_textura = rasterizar(ruta, escala)
	_escala_textura = escala


func _draw() -> void:
	_actualizar_textura()
	if _textura != null:
		draw_texture_rect(_textura, rect_imagen(), false)
	_dibujar_etiquetas()


func _dibujar_etiquetas() -> void:
	var fuente := get_theme_default_font()
	var factor := rect_imagen().size.x / tamano_svg.x
	for e: Dictionary in etiquetas:
		var tam := maxi(int(float(e.get("tam", 14)) * factor), 6)
		var color: Color = Color(e["color"]) if e.has("color") else color_etiquetas
		var ancho := fuente.get_string_size(e["texto"], HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var p := a_local(e["x"], e["y"]) + Vector2(-ancho / 2.0, tam * 0.35)
		draw_string(fuente, p, e["texto"], HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
