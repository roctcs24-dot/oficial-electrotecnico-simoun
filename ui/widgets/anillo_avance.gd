class_name AnilloAvance
extends Control
## Anillo ámbar con el porcentaje en el centro, para el avance de la Escuela.

var fraccion := 0.0:
	set(valor):
		fraccion = clampf(valor, 0.0, 1.0)
		queue_redraw()


func _init(valor := 0.0, lado := 46.0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(lado, lado)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fraccion = valor


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	draw_circle(c + Vector2(0, 1.5), r + 3.0, Color(0, 0, 0, 0.45))
	draw_circle(c, r + 3.0, Color("0c1116"))
	draw_arc(c, r + 3.0, 0, TAU, 40, Relieve.PLACA_BORDE, 1.0, true)
	Relieve.anillo(self, c, r, 4.0, fraccion)
	var tam := r * 0.62
	PiezasAri.texto(self, "%d%%" % roundi(fraccion * 100.0), c.x, c.y + tam * 0.36, tam, Color.WHITE)
