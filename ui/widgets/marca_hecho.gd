class_name MarcaHecho
extends Control
## Círculo verde con una marca de verificación: lección, misión o modo completados. Se dibuja
## con líneas para no depender de que la fuente tenga el carácter ✓.

const LADO := 26.0


func _init() -> void:
	custom_minimum_size = Vector2(LADO, LADO)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_circle(c, r, Tema.HECHO)
	var puntos := PackedVector2Array([c + Vector2(-0.45, 0.02) * r, c + Vector2(-0.12, 0.35) * r, c + Vector2(0.48, -0.32) * r])
	draw_polyline(puntos, Tema.FONDO, maxf(2.0, r * 0.22), true)
