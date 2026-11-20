class_name MuestraCable
extends Control
## Tramo corto de cable con volumen, su raya longitudinal (PE, 0 V) y la puntera con el cuello de
## color: la muestra de la leyenda del código de colores y de la ficha del hilo.

const CUELLO_POTENCIA := Color("2f74c6")
const CUELLO_MANDO := Color("d23a2f")

var color := Color.WHITE
var raya := Color.TRANSPARENT
var potencia := false


func _init(conductor: String) -> void:
	var d: Dictionary = MesaTaller.CONDUCTORES[conductor]
	color = d["color"]
	raya = d.get("raya", Color.TRANSPARENT)
	potencia = conductor in ["L1", "L2", "L3", "PE"]
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(72, 30)


func _draw() -> void:
	var y := size.y / 2.0
	var fin := size.x - 16.0
	var a := Vector2(4.0, y)
	var b := Vector2(fin, y)
	var ancho := 7.0
	draw_line(a + Vector2(1.5, 3.0), b + Vector2(1.5, 3.0), Color(0.0, 0.0, 0.0, 0.35), ancho + 3.0)
	draw_line(a, b, color.darkened(0.6), ancho + 1.6)
	draw_line(a, b, color, ancho)
	if raya.a > 0.0:
		draw_line(a + Vector2(0.0, 0.6), b + Vector2(0.0, 0.6), raya, ancho * 0.42)
	draw_line(a + Vector2(0.0, -1.7), b + Vector2(0.0, -1.7), color.lightened(0.45), ancho * 0.35)
	draw_line(a + Vector2(0.0, -2.1), b + Vector2(0.0, -2.1), Color(1.0, 1.0, 1.0, 0.5), 1.0)
	# Cuello trapecial y tubo de la puntera.
	var cuello := CUELLO_POTENCIA if potencia else CUELLO_MANDO
	draw_colored_polygon(PackedVector2Array([Vector2(fin - 4.0, y - 5.5), Vector2(fin + 4.0, y - 4.5),
			Vector2(fin + 4.0, y + 4.5), Vector2(fin - 4.0, y + 5.5)]), cuello)
	draw_rect(Rect2(fin + 4.0, y - 2.5, 10.0, 5.0), Color("c9cfd3"))
	draw_rect(Rect2(fin + 4.0, y - 2.5, 10.0, 1.8), Color(1.0, 1.0, 1.0, 0.45))
