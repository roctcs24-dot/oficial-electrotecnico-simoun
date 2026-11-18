class_name DibujoHerramienta
extends Control
## Herramienta del pañol dibujada con relieve, de lado, cromada o con sus mangos aislados.
## Se dibuja en un espacio de 360 × 200 escalado al tamaño. «medida» se graba en el cuerpo de las
## llaves, como «19 mm» o «3/4"».

const ANCHO := 360.0
const ALTO := 200.0
const TIPOS := ["boca", "estrella", "combinada", "ajustable", "stillson", "carraca", "allen", "torx", "gancho",
	"dinamometrica", "destornillador", "alicate", "crimpadora", "calibre", "micrometro", "cortatubos"]

const CROMO := [Color("ffffff"), Color("d6dde3"), Color("8a959e"), Color("c9d1d7"), Color("5b6670")]
const NEGRO := [Color("5b6168"), Color("2b3036"), Color("15181b"), Color("0a0c0e")]
## Acero pavonado de las llaves Allen: más claro que el negro de los mangos para que se vea en el visor.
const PAVONADO := [Color("9aa4ae"), Color("56606a"), Color("2e353c"), Color("1b2026")]
const ROJO := [Color("ff8a7a"), Color("d02a1e"), Color("8f120b"), Color("5e0f0a")]
const AMARILLO := [Color("fff0a0"), Color("f2cc1a"), Color("b8920a"), Color("6a5200")]
const AZUL := [Color("8cc4f0"), Color("2c7ac8"), Color("174f86"), Color("0c2f52")]

var tipo := "combinada":
	set(valor):
		tipo = valor
		queue_redraw()
var medida := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 140)
	resized.connect(queue_redraw)


func _draw() -> void:
	var k := minf(size.x / ANCHO, size.y / ALTO)
	draw_set_transform((size - Vector2(ANCHO, ALTO) * k) / 2.0, 0.0, Vector2(k, k))
	match tipo:
		"boca":
			_barra(Rect2(80, 90, 200, 20), CROMO, 9.0)
			_boca(Vector2(70, 100), 26.0, PI)
			_boca(Vector2(290, 100), 22.0, 0.0)
			_grabado(Vector2(180, 104))
		"estrella":
			_barra(Rect2(90, 90, 180, 20), CROMO, 9.0)
			_anillo(Vector2(70, 92), 30.0, 15.0)
			_anillo(Vector2(290, 92), 26.0, 13.0)
			_grabado(Vector2(180, 104))
		"combinada":
			_barra(Rect2(80, 90, 200, 20), CROMO, 9.0)
			_boca(Vector2(70, 100), 26.0, PI)
			_anillo(Vector2(292, 100), 28.0, 14.0)
			_grabado(Vector2(180, 104))
		"ajustable":
			_barra(Rect2(110, 88, 220, 24), CROMO, 11.0)
			var cabeza := PackedVector2Array([Vector2(30, 52), Vector2(84, 52), Vector2(104, 80), Vector2(110, 100), Vector2(104, 120), Vector2(84, 148), Vector2(30, 148), Vector2(30, 122), Vector2(62, 122), Vector2(62, 78), Vector2(30, 78)])
			_poligono(cabeza, CROMO)
			_barra(Rect2(58, 92, 30, 16), [Color("8a959e"), Color("5b6670")], 3.0)
			for i in 7:
				draw_line(Vector2(61 + i * 4, 92), Vector2(61 + i * 4, 108), Color("2b3238"), 1.0)
			draw_circle(Vector2(316, 100), 6.0, Color("2b3238"))
		"stillson":
			_barra(Rect2(120, 86, 220, 28), [Color("e05a4a"), Color("b0261a"), Color("6a120b")], 8.0)
			var gancho := PackedVector2Array([Vector2(28, 54), Vector2(110, 54), Vector2(120, 86), Vector2(110, 96), Vector2(56, 96), Vector2(56, 78), Vector2(28, 78)])
			_poligono(gancho, CROMO)
			var mordaza := PackedVector2Array([Vector2(40, 116), Vector2(120, 116), Vector2(120, 140), Vector2(40, 140)])
			_poligono(mordaza, CROMO)
			for i in 9:
				draw_line(Vector2(58 + i * 6, 96), Vector2(61 + i * 6, 90), Color("2b3238"), 1.5)
				draw_line(Vector2(42 + i * 7, 116), Vector2(45 + i * 7, 122), Color("2b3238"), 1.5)
			_barra(Rect2(96, 96, 20, 22), [Color("8a959e"), Color("5b6670")], 3.0)
		"carraca":
			_barra(Rect2(130, 90, 200, 22), NEGRO, 10.0)
			PiezasAri._disco(self, Vector2(100, 100), 36.0, CROMO[0], CROMO[4], Vector2(-0.3, -0.4), 10)
			PiezasAri._disco(self, Vector2(100, 100), 12.0, Color("5b6670"), Color("1b2228"))
			_barra(Rect2(94, 54, 12, 16), CROMO, 3.0)
			# Dado al lado.
			_barra(Rect2(24, 140, 52, 40), CROMO, 6.0, false)
			_hexagono(Vector2(50, 160), 12.0, Color("141b22"))
		"allen", "torx":
			var l := PackedVector2Array([Vector2(60, 70), Vector2(300, 70), Vector2(300, 88), Vector2(78, 88), Vector2(78, 160), Vector2(60, 160)])
			_poligono(l, PAVONADO if tipo == "allen" else CROMO)
			if tipo == "allen":
				_hexagono(Vector2(69, 168), 9.0, Color("2b3036"))
			else:
				_estrella(Vector2(69, 168), 10.0, 6.5, 6, Color("5b6670"))
			_grabado(Vector2(190, 82))
		"gancho":
			_barra(Rect2(150, 90, 190, 20), CROMO, 9.0)
			draw_arc(Vector2(100, 100), 46.0, -PI * 0.15, PI * 1.55, 40, Color(0, 0, 0, 0.4), 16.0, true)
			draw_arc(Vector2(100, 96), 46.0, -PI * 0.15, PI * 1.55, 40, CROMO[2], 16.0, true)
			draw_arc(Vector2(100, 93), 46.0, -PI * 0.1, PI * 1.5, 40, CROMO[1], 8.0, true)
			var punta := Vector2(100, 96) + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * 46.0
			_barra(Rect2(punta.x - 6.0, punta.y - 4.0, 18.0, 10.0), CROMO, 3.0)
		"dinamometrica":
			_barra(Rect2(80, 90, 270, 22), CROMO, 10.0)
			_barra(Rect2(270, 86, 80, 30), NEGRO, 12.0)
			PiezasAri._disco(self, Vector2(60, 100), 30.0, CROMO[0], CROMO[4], Vector2(-0.3, -0.4), 10)
			_barra(Rect2(54, 66, 12, 12), CROMO, 2.0)
			var escala := Rect2(150, 92, 100, 16)
			DibujoAri.relleno(self, escala, 3.0, Color("f4f1e6"))
			for i in 11:
				draw_line(Vector2(152 + i * 9.6, 92), Vector2(152 + i * 9.6, 92 + (8 if i % 5 == 0 else 5)), Color("20262c"), 1.0)
			PiezasAri.texto(self, "N·m", 200, 107, 9.0, Color("20262c"), Tema.PESO_NEGRITA)
		"destornillador":
			_barra(Rect2(30, 76, 120, 48), ROJO, 18.0)
			_barra(Rect2(146, 82, 26, 36), AMARILLO, 8.0)
			_barra(Rect2(170, 94, 140, 12), AMARILLO, 2.0)
			_poligono(PackedVector2Array([Vector2(310, 94), Vector2(338, 97), Vector2(338, 103), Vector2(310, 106)]), CROMO)
			PiezasAri.texto(self, "1000 V", 90, 105, 13.0, Color.WHITE, Tema.PESO_NEGRITA)
		"alicate", "crimpadora":
			var mango := AZUL if tipo == "alicate" else AMARILLO
			_poligono(PackedVector2Array([Vector2(150, 92), Vector2(330, 60), Vector2(336, 74), Vector2(160, 104)]), mango)
			_poligono(PackedVector2Array([Vector2(150, 108), Vector2(330, 140), Vector2(336, 126), Vector2(160, 96)]), mango)
			PiezasAri._disco(self, Vector2(150, 100), 14.0, CROMO[0], CROMO[4])
			if tipo == "alicate":
				_poligono(PackedVector2Array([Vector2(40, 94), Vector2(140, 86), Vector2(150, 100), Vector2(40, 100)]), CROMO)
				_poligono(PackedVector2Array([Vector2(40, 106), Vector2(140, 114), Vector2(150, 100), Vector2(40, 100)]), CROMO)
				for i in 8:
					draw_line(Vector2(50 + i * 8, 97), Vector2(54 + i * 8, 103), Color("2b3238"), 1.0)
			else:
				_poligono(PackedVector2Array([Vector2(60, 80), Vector2(140, 84), Vector2(150, 100), Vector2(60, 100)]), CROMO)
				_poligono(PackedVector2Array([Vector2(60, 120), Vector2(140, 116), Vector2(150, 100), Vector2(60, 100)]), CROMO)
				for i in 3:
					var c := Vector2(78 + i * 22, 100)
					draw_circle(c, 6.0 + i, [Color("d02a1e"), Color("2c7ac8"), Color("f2cc1a")][i])
					draw_circle(c, 3.0, Color("1b2228"))
		"calibre":
			_barra(Rect2(40, 92, 300, 22), CROMO, 2.0)
			_poligono(PackedVector2Array([Vector2(40, 40), Vector2(64, 40), Vector2(64, 92), Vector2(40, 92)]), CROMO)
			_poligono(PackedVector2Array([Vector2(110, 52), Vector2(130, 52), Vector2(150, 92), Vector2(150, 128), Vector2(110, 128)]), CROMO)
			_poligono(PackedVector2Array([Vector2(110, 52), Vector2(116, 52), Vector2(116, 92), Vector2(110, 92)]), CROMO)
			for i in 30:
				draw_line(Vector2(70 + i * 9, 94), Vector2(70 + i * 9, 94 + (9 if i % 5 == 0 else 5)), Color("20262c"), 1.0)
			for i in 10:
				draw_line(Vector2(116 + i * 3.2, 114), Vector2(116 + i * 3.2, 120), Color("20262c"), 0.8)
		"micrometro":
			draw_arc(Vector2(110, 100), 52.0, PI * 0.5, PI * 1.5, 32, Color(0, 0, 0, 0.4), 18.0, true)
			draw_arc(Vector2(110, 97), 52.0, PI * 0.5, PI * 1.5, 32, AZUL[2], 18.0, true)
			draw_arc(Vector2(110, 94), 52.0, PI * 0.6, PI * 1.4, 32, AZUL[1], 6.0, true)
			_barra(Rect2(104, 38, 14, 18), CROMO, 2.0)
			_barra(Rect2(110, 38, 50, 14), CROMO, 2.0)
			_barra(Rect2(160, 34, 60, 22), CROMO, 3.0)
			_barra(Rect2(214, 30, 70, 30), CROMO, 6.0)
			_barra(Rect2(282, 34, 30, 22), NEGRO, 6.0)
			for i in 10:
				draw_line(Vector2(218 + i * 6.5, 30), Vector2(218 + i * 6.5, 60), Color(0, 0, 0, 0.35), 1.0)
		"cortatubos":
			draw_arc(Vector2(120, 100), 50.0, 0, TAU, 40, Color(0, 0, 0, 0.4), 22.0, true)
			draw_arc(Vector2(120, 96), 50.0, PI * 0.2, PI * 1.8, 40, NEGRO[1], 22.0, true)
			PiezasAri._disco(self, Vector2(170, 96), 16.0, CROMO[0], CROMO[4])
			_barra(Rect2(180, 86, 150, 20), NEGRO, 9.0)
			_barra(Rect2(14, 86, 212, 20), [Color("e0a070"), Color("b06a2a"), Color("6a3a12")], 10.0)
	draw_set_transform(Vector2.ZERO)


# --- Piezas ---

func _barra(r: Rect2, colores: Array, radio := 3.0, horizontal := true) -> void:
	DibujoAri.relleno(self, Rect2(r.position + Vector2(0, 4), r.size), radio, Color(0, 0, 0, 0.4))
	if horizontal:
		DibujoAri.degradado(self, r, radio, colores)
	else:
		var n := colores.size() - 1
		for i in n:
			draw_rect(Rect2(r.position.x + r.size.x * i / n, r.position.y, r.size.x / n + 0.5, r.size.y), (colores[i] as Color).lerp(colores[i + 1], 0.5))
	DibujoAri.borde(self, r, radio, Color(0, 0, 0, 0.45), 1.0)
	DibujoAri.relleno(self, Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6.0, minf(r.size.y * 0.25, 6.0))), 2.0, Color(1, 1, 1, 0.35))


func _poligono(puntos: PackedVector2Array, colores: Array) -> void:
	var sombra := PackedVector2Array()
	for p in puntos:
		sombra.append(p + Vector2(0, 4))
	draw_colored_polygon(sombra, Color(0, 0, 0, 0.4))
	var caja := Rect2(puntos[0], Vector2.ZERO)
	for p in puntos:
		caja = caja.expand(p)
	Relieve.poligono_degradado(self, puntos, colores, caja.position, Vector2(caja.position.x, caja.end.y))
	var linea := puntos.duplicate()
	linea.append(puntos[0])
	draw_polyline(linea, Color(0, 0, 0, 0.45), 1.0, true)


## Boca abierta con la abertura hacia «angulo» (0 a la derecha, PI a la izquierda).
func _boca(c: Vector2, r: float, angulo: float) -> void:
	var puntos := PackedVector2Array()
	for i in 25:
		var a := angulo + PI * 0.28 + (TAU - PI * 0.56) * i / 24.0
		puntos.append(c + Vector2(cos(a), sin(a)) * r)
	var d := Vector2(cos(angulo), sin(angulo))
	var n := d.orthogonal()
	puntos.append(c + d * r * 0.95 + n * r * 0.42)
	puntos.append(c + n * r * 0.42 - d * r * 0.2)
	puntos.append(c - n * r * 0.42 - d * r * 0.2)
	puntos.append(c + d * r * 0.95 - n * r * 0.42)
	_poligono(puntos, CROMO)


func _anillo(c: Vector2, r: float, hueco: float) -> void:
	draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.4))
	PiezasAri._disco(self, c, r, CROMO[0], CROMO[4], Vector2(-0.3, -0.4), 10)
	_estrella(c, hueco, hueco * 0.82, 12, Color("141b22"))


func _estrella(c: Vector2, r1: float, r2: float, puntas: int, color: Color) -> void:
	var p := PackedVector2Array()
	for i in puntas * 2:
		var a := PI * i / puntas
		p.append(c + Vector2(cos(a), sin(a)) * (r1 if i % 2 == 0 else r2))
	draw_colored_polygon(p, color)


func _hexagono(c: Vector2, r: float, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 6:
		var a := PI / 3.0 * i
		p.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(p, color)


func _grabado(c: Vector2) -> void:
	if not medida.is_empty():
		PiezasAri.texto(self, medida, c.x, c.y, 12.0, Color("3b444c"), Tema.PESO_NEGRITA)
