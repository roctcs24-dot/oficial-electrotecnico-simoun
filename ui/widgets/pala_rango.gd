class_name PalaRango
extends Control
## Pala de hombro de un rango: azul marino con botón dorado y galones como en la marina mercante.
## «galones»: -1 ninguno (Aspirante), 0 el distintivo de cadete, 1 a 4 los galones de oficial.
## Con «activa» lleva halo ámbar; con «apagada», queda tenue (rango aún no alcanzado).

const MARINO := [Color("2b3d5c"), Color("16233a"), Color("0b1220")]
const ORO := [Color("fff0b0"), Color("e2b23a"), Color("8a6410")]
const BORDE := Color("5a7aa8")

var galones := 0
var activa := false
var apagada := false


func _init(numero_galones := 0, es_activa := false, es_apagada := false) -> void:
	galones = numero_galones
	activa = es_activa
	apagada = es_apagada
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(60, 30)


func _draw() -> void:
	var e := minf(size.x / 60.0, size.y / 30.0)
	var o := (size - Vector2(60, 30) * e) / 2.0
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * e
	modulate = Color(1, 1, 1, 0.4) if apagada else Color.WHITE
	if activa:
		for k in 4:
			draw_rect(Rect2(p.call(-2 - k * 2, 2 - k * 2), Vector2(64 + k * 4, 26 + k * 4) * e), Color(1.0, 0.69, 0.13, 0.08))
	var cuerpo := PackedVector2Array([p.call(2, 4), p.call(48, 4), p.call(58, 15), p.call(48, 26), p.call(2, 26)])
	var colores := PackedColorArray([MARINO[0], MARINO[0], MARINO[1], MARINO[2], MARINO[2]])
	draw_polygon(cuerpo, colores)
	var contorno := cuerpo.duplicate()
	contorno.append(cuerpo[0])
	draw_polyline(contorno, BORDE, 1.3 * e, true)
	draw_line(p.call(4, 6), p.call(47, 6), Color(1, 1, 1, 0.18), 1.2 * e)
	draw_circle(p.call(50, 15), 3.4 * e, ORO[2])
	draw_circle(p.call(50, 15), 2.8 * e, ORO[1])
	draw_circle(p.call(49.2, 14.2), 1.0 * e, ORO[0])
	if galones == 0:
		draw_rect(Rect2(p.call(8, 12), Vector2(6, 6) * e), ORO[1], false, 1.4 * e)
	for i in maxi(galones, 0):
		var r := Rect2(p.call(8 + i * 8, 6), Vector2(4, 18) * e)
		draw_rect(r, ORO[1])
		draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.3)), ORO[0])
		draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.75), Vector2(r.size.x, r.size.y * 0.25)), ORO[2])
