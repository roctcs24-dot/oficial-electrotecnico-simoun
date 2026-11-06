class_name DialSincronoscopio
extends Control
## Sincronoscopio de cuadro: la aguja gira en sentido horario si el generador entrante va
## más rápido que las barras. El sector verde arriba es la ventana de cierre. Debajo, las tres
## lámparas de sincronismo: se apagan a la vez cuando las tensiones coinciden.

const CARA := Color("1c2226")
const MARCA := Color("d8dcd8")
const VENTANA := Color("2f8f55")
const AGUJA := Color("ffc24a")
const LAMPARA := Color("ffd27a")
const VENTANA_GRADOS := 10.0

var angulo := 0.0
var valido := false
## Brillo de cada lámpara, de 0 a 1.
var lamparas: Array[float] = [0.0, 0.0, 0.0]


func _init() -> void:
	custom_minimum_size = Vector2(200.0, 250.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func actualizar(nuevo_angulo: float, es_valido: bool, brillos: Array[float]) -> void:
	angulo = nuevo_angulo
	valido = es_valido
	lamparas = brillos
	queue_redraw()


func _draw() -> void:
	var fuente := get_theme_default_font()
	var radio := minf(size.x, size.y - 60.0) * 0.45
	var centro := Vector2(size.x / 2.0, radio + 8.0)
	draw_circle(centro, radio + 6.0, Color("8e9496"))
	draw_circle(centro, radio, CARA)
	var arriba := -PI / 2.0
	draw_arc(centro, radio * 0.85, arriba - deg_to_rad(VENTANA_GRADOS), arriba + deg_to_rad(VENTANA_GRADOS), 12, VENTANA, radio * 0.18, true)
	for i in 12:
		var a := arriba + TAU * i / 12.0
		draw_line(centro + Vector2.from_angle(a) * radio * 0.92, centro + Vector2.from_angle(a) * radio * 0.8, MARCA, 2.0, true)
	var t := 12
	# Centrados a cada lado, dentro del aro y lejos de las marcas de las cuatro y las ocho.
	var ancho := radio * 0.7
	draw_string(fuente, centro + Vector2(radio * 0.38 - ancho / 2.0, radio * 0.62), "RÁPIDO", HORIZONTAL_ALIGNMENT_CENTER, ancho, t, MARCA)
	draw_string(fuente, centro + Vector2(-radio * 0.38 - ancho / 2.0, radio * 0.62), "LENTO", HORIZONTAL_ALIGNMENT_CENTER, ancho, t, MARCA)
	if valido:
		var a := arriba + deg_to_rad(angulo)
		draw_line(centro - Vector2.from_angle(a) * radio * 0.2, centro + Vector2.from_angle(a) * radio * 0.88, AGUJA, 4.0, true)
	draw_circle(centro, 6.0, MARCA)
	var y := centro.y + radio + 32.0
	for i in 3:
		var p := Vector2(size.x / 2.0 + (i - 1) * 44.0, y)
		draw_circle(p, 15.0, Color("8e9496"))
		draw_circle(p, 12.0, Color(0.15, 0.13, 0.1).lerp(LAMPARA, clampf(lamparas[i], 0.0, 1.0)))
