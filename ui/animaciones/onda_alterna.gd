extends Animacion
## Electrones en CC y en CA, y la onda con sus valores eficaz y de pico.

const HERCIOS_LENTOS := 0.5


static func valor_pico(v_eficaz: float) -> float:
	return v_eficaz * sqrt(2.0)


func preparar() -> void:
	lienzo.custom_minimum_size.y = 310.0


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var fase := TAU * HERCIOS_LENTOS * t
	_dibujar_cable(Vector2(tam.x, 58.0), "CC: siempre en el mismo sentido", fposmod(t * 40.0, 34.0))
	_dibujar_cable(Vector2(tam.x, 112.0), "CA: van y vienen", sin(fase) * 17.0 + 17.0)
	_dibujar_onda(Rect2(52.0, 136.0, tam.x - 68.0, tam.y - 170.0), fase)


func _dibujar_cable(fin: Vector2, rotulo: String, desplazamiento: float) -> void:
	var y := fin.y
	texto(Vector2(16.0, y - 26.0), rotulo, 15, Tema.TINTA, false)
	lienzo.draw_line(Vector2(16.0, y), Vector2(fin.x - 16.0, y), Color("c98a57"), 10.0)
	var x := 16.0 + desplazamiento
	while x < fin.x - 16.0:
		lienzo.draw_circle(Vector2(x, y), 3.5, Color("1668c4"))
		x += 34.0


func _dibujar_onda(area: Rect2, fase: float) -> void:
	var v_eficaz: float = params["v_rms"]
	var pico := valor_pico(v_eficaz)
	var medio := area.get_center().y
	var alto := area.size.y / 2.0 - 4.0
	lienzo.draw_line(Vector2(area.position.x, medio), Vector2(area.end.x, medio), Color("8a9094"), 1.5)
	var y_eficaz := medio - alto * v_eficaz / pico
	_linea_rayada(area.position.x, area.end.x, y_eficaz, Color("23804a"))
	var y_pico := medio - alto
	_linea_rayada(area.position.x, area.end.x, y_pico, Color("a8352a"))
	var rotulo := TextoTecnico.numero(pico, 0)
	texto(Vector2(area.position.x - 22.0, y_pico), rotulo, 14, Color("a8352a"), true)
	texto(Vector2(area.position.x - 22.0, y_eficaz), "%d" % int(v_eficaz), 14, Color("23804a"), true)
	var puntos := PackedVector2Array()
	var cantidad := 90
	for n in cantidad + 1:
		var x := float(n) / cantidad
		puntos.append(Vector2(area.position.x + x * area.size.x, medio - alto * sin(fase - x * TAU * 2.0)))
	lienzo.draw_polyline(puntos, Color("1668c4"), 3.0, true)
	lienzo.draw_circle(puntos[0], 6.0, Color("f2a93b"))
	var leyenda := "pico %s V   ·   eficaz %d V" % [rotulo, int(v_eficaz)]
	texto(Vector2(area.get_center().x, area.end.y + 18.0), leyenda, 13)


func _linea_rayada(x0: float, x1: float, y: float, color: Color) -> void:
	lienzo.draw_dashed_line(Vector2(x0, y), Vector2(x1, y), color, 1.5, 7.0)
