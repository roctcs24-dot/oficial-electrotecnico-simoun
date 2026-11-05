class_name InstrumentoAguja
extends Control
## Instrumento analógico de cuadro: escala de 240°, aguja y lectura digital debajo.
## Desde zona_roja la escala se pinta en rojo, como en los instrumentos reales.

const APERTURA := 240.0
const MARCAS := 10
const CARA := Color("e9ebe8")
const TINTA := Color("20242a")
const ROJO := Color("b02a22")
const AGUJA := Color("1a1c1e")

var titulo := ""
var unidad := ""
var minimo := 0.0
var maximo := 100.0
var zona_roja := INF
var decimales := 0
var valor := 0.0:
	set(nuevo):
		if not is_equal_approx(nuevo, valor):
			valor = nuevo
			queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(132.0, 152.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configurar(p_titulo: String, p_unidad: String, p_minimo: float, p_maximo: float, p_zona_roja := INF, p_decimales := 0) -> InstrumentoAguja:
	titulo = p_titulo
	unidad = p_unidad
	minimo = p_minimo
	maximo = p_maximo
	zona_roja = p_zona_roja
	decimales = p_decimales
	return self


func _angulo(v: float) -> float:
	var t := clampf((v - minimo) / (maximo - minimo), 0.0, 1.0)
	return deg_to_rad(90.0 + APERTURA / 2.0 + t * APERTURA)


func _draw() -> void:
	var fuente := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color("8e9496"))
	draw_rect(Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0)), CARA)
	# Los extremos de la escala quedan por encima de la lectura digital, sin pisarla.
	var centro := Vector2(size.x / 2.0, size.y * 0.5)
	var radio := minf(size.x * 0.4, size.y * 0.32)
	for i in MARCAS + 1:
		var v := minimo + (maximo - minimo) * i / MARCAS
		var a := _angulo(v)
		var color := ROJO if v >= zona_roja else TINTA
		var largo := 0.18 if i % 5 == 0 else 0.1
		draw_line(centro + Vector2.from_angle(a) * radio, centro + Vector2.from_angle(a) * radio * (1.0 - largo), color, 2.0, true)
	if zona_roja < maximo:
		draw_arc(centro, radio, _angulo(zona_roja), _angulo(maximo), 16, ROJO, 3.0, true)
	var t := 11
	for v: float in [minimo, maximo]:
		var p := centro + Vector2.from_angle(_angulo(v)) * radio * 0.62 - Vector2(0.0, 6.0)
		var texto := TextoTecnico.numero(v, 0)
		draw_string(fuente, p - Vector2(fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x / 2.0, -4.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, TINTA)
	var cabecera := 13
	draw_string(fuente, Vector2(size.x / 2.0 - fuente.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, cabecera).x / 2.0, 18.0), titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, cabecera, TINTA)
	var a := _angulo(valor)
	draw_line(centro, centro + Vector2.from_angle(a) * radio * 0.92, AGUJA, 3.0, true)
	draw_circle(centro, 5.0, AGUJA)
	var lectura := "%s %s" % [TextoTecnico.numero(valor, decimales), unidad]
	var tl := 16
	draw_string(fuente, Vector2(size.x / 2.0 - fuente.get_string_size(lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tl).x / 2.0, size.y - 9.0), lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tl, TINTA)
