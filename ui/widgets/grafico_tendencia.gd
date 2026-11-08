class_name GraficoTendencia
extends Control
## Tendencia de una pantalla HMI: varias trazas sobre una rejilla, cada una con su escala.
## trazas: [{sigla, min, max, color}] y series: una PackedFloat32Array por traza (NAN = sin dato).

var trazas: Array = []
var series: Array[PackedFloat32Array] = []
var muestras := 120


func _init() -> void:
	custom_minimum_size = Vector2(240.0, 170.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2(34.0, 8.0), size - Vector2(70.0, 28.0))
	draw_rect(Rect2(Vector2.ZERO, size), Color("f8fafb"))
	draw_rect(r, Color("ffffff"))
	for k in 5:
		var y := r.position.y + r.size.y * k / 4.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("d3dbe0"), 1.0)
	for k in 7:
		var x := r.position.x + r.size.x * k / 6.0
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color("e3e8eb"), 1.0)
	draw_rect(r, Color("7c8a93"), false, 1.0)
	var fuente := get_theme_default_font()
	for i in trazas.size():
		var t: Dictionary = trazas[i]
		var color := Color(t.get("color", "#2a5fb0"))
		var lo := float(t["min"])
		var hi := float(t["max"])
		# Escala de la primera traza a la izquierda; de la segunda, a la derecha.
		var x_escala := 2.0 if i == 0 else r.end.x + 4.0
		draw_string(fuente, Vector2(x_escala, r.position.y + 10.0), TextoTecnico.numero(hi, 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
		draw_string(fuente, Vector2(x_escala, r.end.y), TextoTecnico.numero(lo, 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
		draw_string(fuente, Vector2(r.position.x + 6.0 + 60.0 * i, size.y - 4.0), "— %s" % t["sigla"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		if i >= series.size():
			continue
		var serie := series[i]
		var linea := PackedVector2Array()
		for k in serie.size():
			var v := serie[k]
			var x := r.end.x - r.size.x * float(serie.size() - 1 - k) / float(muestras - 1)
			if is_nan(v):
				if linea.size() > 1:
					draw_polyline(linea, color, 2.0)
				linea = PackedVector2Array()
				continue
			var y := r.end.y - r.size.y * clampf((v - lo) / (hi - lo), 0.0, 1.0)
			linea.append(Vector2(x, y))
		if linea.size() > 1:
			draw_polyline(linea, color, 2.0)
	draw_string(fuente, Vector2(size.x - 64.0, size.y - 4.0), "últimos 2 min", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("5a646b"))
