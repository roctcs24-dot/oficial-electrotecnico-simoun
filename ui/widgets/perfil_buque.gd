class_name PerfilBuque
extends Control
## Perfil del atunero cerquero en línea clara sobre fondo de plano: casco, puente, palo con la
## pluma y el power block, montón de red y panga a popa. Los compartimentos llevan el color de
## su grupo de paneles. Es una silueta típica, no el plano del Vía Simoun.

const ANCHO_BASE := 300.0
const ALTO_BASE := 100.0
const LINEA := Color(0.81, 0.89, 0.96, 0.9)
const PAPEL := Color("0f2438")

## Compartimentos coloreados: [rectángulo en coordenadas base, grupo de paneles].
const ZONAS := [
	[Rect2(150, 64, 52, 22), "P"],
	[Rect2(206, 64, 26, 22), "G"],
	[Rect2(56, 64, 90, 22), "F"],
	[Rect2(188, 28, 50, 10), "X"],
	[Rect2(26, 50, 70, 12), "K"],
	[Rect2(176, 40, 66, 20), "D"],
]

var paneles: Paneles


func _init(indice: Paneles = null) -> void:
	paneles = indice
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 110)


func _p(x: float, y: float) -> Vector2:
	var escala := minf((size.x - 20.0) / ANCHO_BASE, (size.y - 12.0) / ALTO_BASE)
	var origen := Vector2((size.x - ANCHO_BASE * escala) / 2.0, (size.y - ALTO_BASE * escala) / 2.0)
	return origen + Vector2(x, y) * escala


func _r(r: Rect2) -> Rect2:
	var a := _p(r.position.x, r.position.y)
	return Rect2(a, _p(r.end.x, r.end.y) - a)


func _draw() -> void:
	var todo := Rect2(Vector2.ZERO, size)
	DibujoAri.relleno(self, todo, 6.0, PAPEL)
	var cuadricula := Color(1, 1, 1, 0.04)
	var x := 12.0
	while x < size.x:
		draw_line(Vector2(x, 2), Vector2(x, size.y - 2), cuadricula, 1.0)
		x += 12.0
	var y := 12.0
	while y < size.y:
		draw_line(Vector2(2, y), Vector2(size.x - 2, y), cuadricula, 1.0)
		y += 12.0
	if paneles != null:
		for z: Array in ZONAS:
			var g := paneles.grupo(z[1])
			if not g.is_empty():
				DibujoAri.relleno(self, _r(z[0]), 2.0, Color(Color(g["color"]), 0.35))
	var casco := PackedVector2Array([_p(10, 62), _p(284, 56), _p(298, 47), _p(272, 88), _p(42, 90), _p(16, 82), _p(10, 62)])
	draw_polyline(casco, LINEA, 1.6, true)
	# Cubierta, línea de flotación y quilla.
	draw_line(_p(12, 62), _p(284, 56), LINEA, 1.0)
	_discontinua(_p(4, 78), _p(296, 78), Color(LINEA, 0.5))
	# Mamparos.
	for mx in [56.0, 150.0, 206.0, 236.0]:
		draw_line(_p(mx, 62 - (mx - 10.0) * 6.0 / 274.0), _p(mx, 88), Color(LINEA, 0.45), 1.0)
	# Superestructura y puente con ventanas.
	draw_rect(_r(Rect2(176, 40, 66, 20)), LINEA, false, 1.4)
	draw_rect(_r(Rect2(188, 28, 50, 12)), LINEA, false, 1.4)
	for v in 4:
		draw_rect(_r(Rect2(192 + v * 11, 31, 8, 5)), LINEA, false, 1.0)
	for v in 3:
		draw_arc(_p(196 + v * 14, 50), 2.6 * (_p(1, 0) - _p(0, 0)).x, 0, TAU, 12, LINEA, 1.0, true)
	# Palo, cofa y pluma con el power block.
	draw_line(_p(160, 60), _p(160, 8), LINEA, 2.0)
	draw_rect(_r(Rect2(154, 6, 12, 5)), LINEA, false, 1.2)
	draw_line(_p(160, 56), _p(66, 20), LINEA, 1.6)
	draw_line(_p(160, 12), _p(66, 20), Color(LINEA, 0.6), 1.0)
	draw_arc(_p(64, 24), 4.0 * (_p(1, 0) - _p(0, 0)).x, 0, TAU, 16, LINEA, 1.4, true)
	draw_line(_p(64, 28), _p(64, 46), Color(LINEA, 0.5), 1.0)
	# Montón de red y panga a popa.
	var red := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		red.append(_p(60 + cos(a) * 34.0, 62 + sin(a) * 11.0))
	draw_polyline(red, LINEA, 1.2, true)
	draw_polyline(PackedVector2Array([_p(6, 50), _p(38, 50), _p(34, 58), _p(10, 58), _p(6, 50)]), LINEA, 1.2, true)


func _discontinua(a: Vector2, b: Vector2, color: Color) -> void:
	var largo := a.distance_to(b)
	var d := (b - a) / largo
	var t := 0.0
	while t < largo:
		draw_line(a + d * t, a + d * minf(t + 6.0, largo), color, 1.0)
		t += 10.0
