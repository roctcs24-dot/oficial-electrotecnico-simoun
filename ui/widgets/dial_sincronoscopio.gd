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
	var lado := minf(size.x, size.y - 60.0)
	var marco := Rect2(Vector2((size.x - lado) / 2.0, 0.0), Vector2(lado, lado))
	var cara := DibujoInstrumentos.marco_cuadrado(self, marco)
	draw_rect(cara, CARA)
	var centro := cara.get_center()
	var radio := cara.size.x * 0.44
	var arriba := -PI / 2.0
	draw_arc(centro, radio * 0.85, arriba - deg_to_rad(VENTANA_GRADOS), arriba + deg_to_rad(VENTANA_GRADOS), 12, VENTANA, radio * 0.18, true)
	draw_arc(centro, radio * 0.94, 0.0, TAU, 48, MARCA, 1.5, true)
	for i in 60:
		var a := arriba + TAU * i / 60.0
		var largo := 0.14 if i % 5 == 0 else 0.06
		draw_line(centro + Vector2.from_angle(a) * radio * 0.94, centro + Vector2.from_angle(a) * radio * (0.94 - largo), MARCA, 2.0 if i % 5 == 0 else 1.0, true)
	var t := 12
	# Centrados a cada lado, dentro del aro y lejos de las marcas de las cuatro y las ocho.
	var ancho := radio * 0.7
	draw_string(fuente, centro + Vector2(radio * 0.38 - ancho / 2.0, radio * 0.62), "RÁPIDO", HORIZONTAL_ALIGNMENT_CENTER, ancho, t, MARCA)
	draw_string(fuente, centro + Vector2(-radio * 0.38 - ancho / 2.0, radio * 0.62), "LENTO", HORIZONTAL_ALIGNMENT_CENTER, ancho, t, MARCA)
	# Flechas de sentido: horario hacia RÁPIDO, antihorario hacia LENTO.
	for lado_flecha: float in [1.0, -1.0]:
		var a0 := arriba + lado_flecha * deg_to_rad(60.0)
		var a1 := arriba + lado_flecha * deg_to_rad(95.0)
		draw_arc(centro, radio * 0.62, minf(a0, a1), maxf(a0, a1), 10, MARCA, 1.5, true)
		var punta := centro + Vector2.from_angle(a1) * radio * 0.62
		var tangente := Vector2.from_angle(a1 + lado_flecha * PI / 2.0)
		var normal := Vector2.from_angle(a1)
		draw_colored_polygon(PackedVector2Array([punta + tangente * 8.0, punta - normal * 4.0, punta + normal * 4.0]), MARCA)
	if valido:
		DibujoInstrumentos.aguja(self, centro, arriba + deg_to_rad(angulo), radio * 0.88, AGUJA)
	else:
		DibujoInstrumentos.disco(self, centro, radio * 0.07, MARCA, MARCA.darkened(0.5), 4)
	DibujoInstrumentos.reflejo(self, centro, radio * 1.05)
	var y := marco.end.y + 32.0
	for i in 3:
		var p := Vector2(size.x / 2.0 + (i - 1) * 44.0, y)
		DibujoInstrumentos.lampara(self, p, 16.0, Color(0.15, 0.13, 0.1), LAMPARA, clampf(lamparas[i], 0.0, 1.0))
