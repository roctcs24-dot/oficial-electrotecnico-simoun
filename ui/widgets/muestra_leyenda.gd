class_name MuestraLeyenda
extends Control
## Muestra dibujada de la leyenda del marco: un tramo de tubería del color de su fluido, una
## bomba en su estado, un selector MAN/AUTO o un interruptor en ON o en TRIP.

var tipo := "tuberia"
var color := Color.WHITE
var discontinua := false
var estado := ""


func _init(tipo_muestra: String, color_muestra := Color.WHITE, variante := "") -> void:
	tipo = tipo_muestra
	color = color_muestra
	estado = variante
	discontinua = variante == "discontinua"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64, 30) if tipo == "tuberia" else Vector2(40, 40)


func _draw() -> void:
	var c := size / 2.0
	match tipo:
		"tuberia":
			var a := Vector2(4, c.y)
			var b := Vector2(size.x - 4, c.y)
			if discontinua:
				var x := a.x
				while x < b.x:
					draw_line(Vector2(x, c.y), Vector2(minf(x + 9.0, b.x), c.y), color, 4.0)
					x += 13.0
			else:
				draw_line(a, b, color, 4.0)
			# Flecha del sentido del flujo.
			var p := Vector2(c.x + 6.0, c.y)
			draw_colored_polygon(PackedVector2Array([p + Vector2(6, 0), p + Vector2(-4, -6), p + Vector2(-4, 6)]), color)
		"bomba":
			var r := minf(size.x, size.y) / 2.0 - 4.0
			draw_circle(c + Vector2(0, 1.5), r + 1.5, Color(0, 0, 0, 0.4))
			draw_circle(c, r, color)
			draw_arc(c, r, 0, TAU, 24, Color("0b1d2c"), 2.0, true)
			var t := PackedVector2Array([c + Vector2(r * 0.6, 0), c + Vector2(-r * 0.4, -r * 0.5), c + Vector2(-r * 0.4, r * 0.5)])
			draw_colored_polygon(t, Color("0b1d2c"))
		"selector":
			var r := minf(size.x, size.y) / 2.0 - 4.0
			draw_circle(c + Vector2(0, 1.5), r + 1.0, Color(0, 0, 0, 0.45))
			draw_circle(c, r, Color("8a9198"))
			draw_circle(c, r * 0.82, Color("1e2226"))
			var ang := deg_to_rad(-35.0 if estado == "auto" else -145.0)
			var d := Vector2.from_angle(ang)
			var n := d.orthogonal()
			var barra := PackedVector2Array([c + d * r * 0.85 + n * 3.0, c + d * r * 0.85 - n * 3.0, c - d * r * 0.85 - n * 3.0, c - d * r * 0.85 + n * 3.0])
			draw_colored_polygon(barra, Color("3d434a"))
			draw_line(c + d * r * 0.3, c + d * r * 0.8, Color.WHITE, 2.0, true)
		"interruptor":
			var r := Rect2(c.x - 13, 2, 26, size.y - 4)
			DibujoAri.relleno(self, r, 3.0, Color("2c3136"))
			DibujoAri.borde(self, r, 3.0, Color("0c0e10"))
			var disparo := estado == "trip"
			var palanca := Rect2(c.x - 5, r.position.y + (r.size.y * 0.35 if disparo else 4.0), 10, 10)
			DibujoAri.relleno(self, palanca, 1.5, Color("6a7178"))
			var placa := Rect2(r.position.x + 2, r.end.y - 11, r.size.x - 4, 9)
			DibujoAri.relleno(self, placa, 1.5, Tema.ARI_LCD_AMBAR if disparo else Color("c81b12"))
			var f := Tema.fuente(Tema.PESO_NEGRITA)
			var t := "TRIP" if disparo else "ON"
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			draw_string(f, Vector2(c.x - w / 2.0, placa.end.y - 2), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Tema.ARI_TEXTO_OSCURO if disparo else Color.WHITE)
