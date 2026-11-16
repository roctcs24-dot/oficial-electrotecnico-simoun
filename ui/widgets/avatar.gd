class_name Avatar
extends Control
## Círculo amarillo con la inicial del rango y un anillo con el avance hacia el siguiente.

var inicial := ""
var avance := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_arc(c, r - 2.0, 0.0, TAU, 48, Color(Tema.TEXTO_SUAVE, 0.2), 3.0, true)
	if avance > 0.0:
		draw_arc(c, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(avance, 0.0, 1.0), 48, Tema.ACENTO, 3.0, true)
	draw_circle(c, r - 7.0, Tema.ACENTO)
	var fuente := Tema.fuente(Tema.PESO_NEGRITA)
	var tam := int(r * 0.9)
	var medida := fuente.get_string_size(inicial, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
	draw_string(fuente, c + Vector2(-medida.x / 2.0, fuente.get_ascent(tam) / 2.0 - 2.0), inicial, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Tema.FONDO)
