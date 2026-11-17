class_name VistaSvg
extends Control
## Dibuja un SVG centrado y a la resolución real de la pantalla, sin perder nitidez.
## Godot no dibuja el texto de los SVG, por eso las etiquetas van aparte, en coordenadas del dibujo.

const LADO_MAX_PX := 2048.0
## Versión realista ya preparada de un dibujo (tools/dibujos_realistas): mismo encuadre que el SVG,
## con textura, relieve con luz y sombra. Si existe, se muestra en lugar del SVG.
const CARPETA_REALISTA := "res://art/realista/"

static var _fuentes := {}

var ruta := ""
var tamano_svg := Vector2(100.0, 100.0)
var etiquetas: Array = []
var color_etiquetas := Color("eceee8")
## Sombra suave del equipo sobre el fondo, para los dibujos que van en el visor de las fichas.
var sombra_dibujo := false
var _textura: Texture2D
## Imagen realista del dibujo, o null si solo hay SVG.
var realista: Texture2D
var _escala_textura := 0.0


## Ruta de la imagen realista de un SVG de art/: art/equipos/x.svg -> art/realista/equipos/x.webp.
static func ruta_realista(ruta_svg: String) -> String:
	if not ruta_svg.begins_with("res://art/"):
		return ""
	return CARPETA_REALISTA + ruta_svg.trim_prefix("res://art/").get_basename() + ".webp"


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
	realista = null
	var r := ruta_realista(ruta)
	if not r.is_empty() and ResourceLoader.exists(r):
		realista = load(r)
		# Se reduce mucho en el celular: con mipmaps no parpadea ni se ve granulada.
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	if realista != null:
		# La imagen realista ya lleva su sombra.
		draw_texture_rect(realista, rect_imagen(), false)
		_dibujar_etiquetas()
		return
	_actualizar_textura()
	if _textura != null:
		if sombra_dibujo:
			for i in 3:
				var sombra := rect_imagen().grow(float(i))
				sombra.position.y += 4.0 + i * 2.0
				draw_texture_rect(_textura, sombra, false, Color(0, 0, 0, 0.16))
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
