class_name FondoAri
extends Control
## Fondo del marco de simulador: azul degradado con una cuadrícula muy tenue.

const PASO_CUADRICULA := 24.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	DibujoAri.degradado(self, Rect2(Vector2.ZERO, size), 0.0, Tema.ARI_FONDO, [0.0, 0.4, 1.0])
	var linea := Color(1, 1, 1, 0.025)
	var x := PASO_CUADRICULA
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), linea, 1.0)
		x += PASO_CUADRICULA
	var y := PASO_CUADRICULA
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), linea, 1.0)
		y += PASO_CUADRICULA
