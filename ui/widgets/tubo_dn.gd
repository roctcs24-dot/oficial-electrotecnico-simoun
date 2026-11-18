class_name TuboDN
extends Control
## Tramo de tubo de acero visto en perspectiva, con la boca abierta a la derecha y la cota de su
## diámetro exterior. El grosor dibujado crece con el exterior (de DN15 a DN150), para que se
## note la diferencia entre medidas.

const MINIMO := 21.3
const MAXIMO := 168.3

var exterior := 60.3:
	set(v):
		exterior = v
		queue_redraw()
## Texto de la cota; vacío para escribir «exterior N mm».
var cota := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 150)
	resized.connect(queue_redraw)


## Radio dibujado: proporcional a la raíz del exterior para que DN15 y DN150 quepan los dos.
func radio() -> float:
	var t := (sqrt(exterior) - sqrt(MINIMO)) / (sqrt(MAXIMO) - sqrt(MINIMO))
	return lerpf(0.09, 0.3, clampf(t, 0.0, 1.0)) * minf(size.y, size.x * 0.6)


func _draw() -> void:
	var r := radio()
	var y := size.y * 0.58
	var x1 := size.x * 0.08
	var x2 := size.x * 0.86
	var e := r * 0.38
	var cuerpo := Rect2(x1, y - r, x2 - x1, r * 2.0)
	DibujoAri.relleno(self, Rect2(cuerpo.position + Vector2(0, 6), cuerpo.size), 4.0, Color(0, 0, 0, 0.35))
	DibujoAri.degradado(self, cuerpo, 2.0, [Color("eef2f4"), Color("c3ccd3"), Color("7d8891"), Color("a9b3bb"), Color("5b6670")], [0.0, 0.25, 0.55, 0.8, 1.0])
	_elipse(Vector2(x2, y), Vector2(e, r), Color("a9b3bb"))
	_elipse(Vector2(x2, y), Vector2(e * 0.82, r * 0.86), Color("141b22"))
	_elipse(Vector2(x2 + e * 0.12, y), Vector2(e * 0.55, r * 0.72), Color("0a0d10"))
	DibujoAri.relleno(self, Rect2(x1 + 6, y - r + 3, x2 - x1 - 12, maxf(r * 0.16, 2.0)), 2.0, Color(1, 1, 1, 0.4))
	# Cota del exterior.
	var cy := y - r - 16.0
	var amarillo := Color("ffc23a")
	draw_line(Vector2(x2, y - r), Vector2(x2, cy - 6), amarillo, 1.5)
	draw_line(Vector2(x2, y + r), Vector2(x2 + 22, y + r), amarillo, 1.0)
	draw_line(Vector2(x2 + 16, y - r), Vector2(x2 + 16, y + r), amarillo, 2.0)
	for s in [-1.0, 1.0]:
		var p := Vector2(x2 + 16, y + r * s)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(-5, -8 * s), p + Vector2(5, -8 * s)]), amarillo)
	draw_line(Vector2(x2, y - r), Vector2(x2 + 22, y - r), amarillo, 1.0)
	var texto := cota if not cota.is_empty() else "exterior %s mm" % JuegoRacores.mm(exterior)
	PiezasAri.texto(self, texto, (x1 + x2) / 2.0, cy, 14.0, amarillo)


func _elipse(c: Vector2, radios: Vector2, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		p.append(c + Vector2(cos(a) * radios.x, sin(a) * radios.y))
	draw_colored_polygon(p, color)
