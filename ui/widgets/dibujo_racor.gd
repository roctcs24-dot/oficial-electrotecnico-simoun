class_name DibujoRacor
extends Control
## Racor visto de lado, con relieve: hexágonos con sus caras, roscas paralelas o cónicas, conos,
## juntas tóricas, arandelas, férulas, virolas prensadas y mangueras. Se dibuja en un espacio de
## 360 × 200 escalado al tamaño. Con «rotulos» se escriben las marcas que lo identifican (37°,
## 24°, G…); en el minijuego van apagadas para no dar la respuesta.

const ANCHO := 360.0
const ALTO := 200.0
const Y := 100.0
const TIPOS := ["bspp", "bspt_npt", "jic", "orfs", "din24", "compresion", "latiguillo", "enchufe_rapido", "banjo", "brida_sae"]

const ACERO := [Color("f4f7f9"), Color("c9d1d7"), Color("8a959e"), Color("b7c0c7"), Color("56616b")]
const LATON := [Color("fff1b8"), Color("e2bd5a"), Color("a7802a"), Color("c99f3c"), Color("6e5214")]
const COBRE := [Color("ffd0a8"), Color("d9864a"), Color("8f4a1c")]
const GOMA := [Color("4a5056"), Color("24282c"), Color("101214"), Color("1c2024")]
const TORICA := [Color("5a5f64"), Color("1d2124"), Color("08090a")]
const TEFLON := Color(1.0, 0.96, 0.82, 0.55)
const TINTA := Color("ffd166")

var tipo := "jic":
	set(valor):
		tipo = valor
		queue_redraw()
var rotulos := true:
	set(valor):
		rotulos = valor
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 140)
	resized.connect(queue_redraw)


func _draw() -> void:
	var k := minf(size.x / ANCHO, size.y / ALTO)
	draw_set_transform((size - Vector2(ANCHO, ALTO) * k) / 2.0, 0.0, Vector2(k, k))
	match tipo:
		"bspp":
			_cuerpo(150, 250, 16.0)
			_rosca(250, 330, 15.0, 15.0, LATON)
			_hexagono(100, 150, 30.0, LATON)
			_arandela(90, 100, 30.0, 17.0)
			_rosca(20, 90, 20.0, 20.0, LATON)
			_rotulo(55, 60, "G · paralela")
			_rotulo(95, 152, "arandela")
		"bspt_npt":
			_cuerpo(150, 250, 16.0, LATON)
			_rosca(250, 330, 15.0, 15.0, LATON)
			_hexagono(105, 150, 30.0, LATON)
			_rosca(20, 105, 15.0, 20.0, LATON)
			_teflon(34, 100, 15.0, 20.0)
			_rotulo(62, 60, "cónica 1:16")
		"jic":
			_cuerpo(180, 260, 15.0)
			_rosca(260, 330, 15.0, 15.0, ACERO)
			_hexagono(125, 180, 28.0, ACERO)
			_rosca(52, 125, 17.0, 17.0, ACERO)
			_cono(22, 52, 9.0, 15.0)
			_rotulo(37, 66, "37°")
			_rotulo(88, 150, "UNF")
		"orfs":
			_cuerpo(180, 260, 15.0)
			_rosca(260, 330, 15.0, 15.0, ACERO)
			_hexagono(125, 180, 28.0, ACERO)
			_rosca(34, 125, 17.0, 17.0, ACERO)
			_pieza(Rect2(24, Y - 15, 12, 30), ACERO)
			_torica(28, 14.0)
			_rotulo(30, 66, "cara plana")
			_rotulo(30, 150, "tórica")
		"din24":
			_tubo(195, 340, 9.0)
			_hexagono(140, 195, 27.0, ACERO)
			_pieza(Rect2(196, Y - 11, 10, 22), [Color("d6b25a"), Color("8a6a1c")])
			_rosca(100, 140, 19.0, 19.0, ACERO)
			_hexagono(40, 100, 30.0, ACERO)
			_rosca(20, 40, 14.0, 14.0, ACERO)
			_rotulo(70, 60, "cuerpo 24°")
			_rotulo(200, 140, "anillo cortante")
		"compresion":
			_tubo(20, 340, 6.0)
			_hexagono(80, 125, 20.0, LATON)
			_hexagono(235, 280, 20.0, LATON)
			_hexagono(140, 220, 24.0, LATON)
			_rosca(125, 140, 15.0, 15.0, LATON)
			_rosca(220, 235, 15.0, 15.0, LATON)
			for x in [72, 282]:
				var d := 1.0 if x > 200 else -1.0
				draw_colored_polygon(PackedVector2Array([Vector2(x, Y - 6), Vector2(x, Y + 6), Vector2(x + 8 * d, Y + 9), Vector2(x + 8 * d, Y - 9)]), COBRE[1])
			_rotulo(76, 64, "férula")
			_rotulo(180, 150, "tubo de instrumentos")
		"latiguillo":
			_manguera(200, 342, 17.0, "EN 853 2SN · DN12")
			_virola(118, 210, 21.0)
			_hexagono(54, 118, 27.0, ACERO)
			_rosca(22, 54, 15.0, 15.0, ACERO)
			_rotulo(86, 60, "tuerca giratoria")
			_rotulo(164, 150, "virola prensada")
		"enchufe_rapido":
			_manguera(270, 342, 13.0, "")
			_virola(230, 275, 16.0)
			_pieza(Rect2(170, Y - 11, 60, 22), ACERO)
			draw_rect(Rect2(186, Y - 11, 8, 22), Color(0, 0, 0, 0.35))
			_pieza(Rect2(70, Y - 26, 100, 52), ACERO, 6.0)
			for i in 14:
				draw_line(Vector2(80 + i * 6, Y - 24), Vector2(80 + i * 6, Y + 24), Color(0, 0, 0, 0.25), 1.5)
			_hexagono(30, 70, 22.0, ACERO)
			_rotulo(120, 62, "manguito de bolas")
			_rotulo(200, 150, "macho")
		"banjo":
			draw_rect(Rect2(40, 170, 160, 22), Color("6b7680"))
			draw_rect(Rect2(40, 170, 160, 3), Color(1, 1, 1, 0.25))
			_pieza(Rect2(104, 132, 32, 38), ACERO)
			for i in 6:
				draw_line(Vector2(104, 136 + i * 6), Vector2(136, 132 + i * 6), Color(0, 0, 0, 0.35), 1.2)
			_pieza(Rect2(92, 124, 56, 8), COBRE)
			_pieza(Rect2(84, 74, 72, 50), ACERO, 10.0)
			_tubo(156, 330, 9.0)
			_pieza(Rect2(92, 66, 56, 8), COBRE)
			_pieza(Rect2(96, 36, 48, 30), ACERO, 3.0)
			draw_line(Vector2(112, 37), Vector2(112, 65), Color(0, 0, 0, 0.3), 1.0)
			draw_line(Vector2(128, 37), Vector2(128, 65), Color(1, 1, 1, 0.35), 1.0)
			_rotulo(220, 56, "tornillo hueco")
			_rotulo(220, 140, "dos arandelas de cobre")
		"brida_sae":
			_pieza(Rect2(20, 30, 70, 140), [Color("8a959e"), Color("56616b"), Color("3a434b")])
			_tubo(150, 340, 16.0)
			_pieza(Rect2(120, Y - 22, 36, 44), ACERO)
			_pieza(Rect2(92, 40, 30, 120), ACERO, 4.0)
			draw_line(Vector2(92, Y), Vector2(122, Y), Color(0, 0, 0, 0.5), 1.5)
			for y in [52, 148]:
				_pieza(Rect2(122, y - 7, 26, 14), [Color("5b6670"), Color("2b3238")], 2.0)
			_pieza(Rect2(89, Y - 18, 5, 36), TORICA, 2.0)
			_rotulo(106, 30, "brida partida")
			_rotulo(240, 140, "código 61 / 62")


# --- Piezas ---

func _pieza(r: Rect2, colores: Array, radio := 2.0) -> void:
	DibujoAri.relleno(self, Rect2(r.position + Vector2(0, 4), r.size), radio, Color(0, 0, 0, 0.35))
	DibujoAri.degradado(self, r, radio, colores)
	DibujoAri.borde(self, r, radio, Color(0, 0, 0, 0.45), 1.0)
	DibujoAri.relleno(self, Rect2(r.position + Vector2(2, 2), Vector2(maxf(r.size.x - 4.0, 1.0), minf(r.size.y * 0.18, 5.0))), 1.5, Color(1, 1, 1, 0.3))


func _cuerpo(x1: float, x2: float, r: float, colores: Array = ACERO) -> void:
	_pieza(Rect2(x1, Y - r, x2 - x1, r * 2.0), colores)


func _tubo(x1: float, x2: float, r: float) -> void:
	_pieza(Rect2(x1, Y - r, x2 - x1, r * 2.0), [Color("eef2f4"), Color("b9c2c9"), Color("6d7880"), Color("a3adb5")], minf(r, 3.0))


## Hexágono de lado: tres caras, la del medio de frente y más clara.
func _hexagono(x1: float, x2: float, r: float, colores: Array) -> void:
	var w := x2 - x1
	DibujoAri.relleno(self, Rect2(x1, Y - r + 4, w, r * 2.0), 2.0, Color(0, 0, 0, 0.4))
	var bandas := [[Y - r, Y - r * 0.5, 0.75], [Y - r * 0.5, Y + r * 0.5, 0.0], [Y + r * 0.5, Y + r, 1.0]]
	for b: Array in bandas:
		var t: float = b[2]
		var claro: Color = (colores[0] as Color).lerp(colores[2], t * 0.8)
		var oscuro: Color = (colores[1] as Color).lerp(colores[colores.size() - 1], t)
		DibujoAri.degradado(self, Rect2(x1, b[0], w, b[1] - b[0]), 1.0, [claro, oscuro])
		draw_line(Vector2(x1, b[0]), Vector2(x2, b[0]), Color(0, 0, 0, 0.35), 1.0)
	# Chaflanes de las esquinas.
	for x in [x1, x2]:
		var d := 1.0 if x == x1 else -1.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, Y - r), Vector2(x + 5 * d, Y - r), Vector2(x, Y - r + 6)]), Color(0.06, 0.08, 0.1))
		draw_colored_polygon(PackedVector2Array([Vector2(x, Y + r), Vector2(x + 5 * d, Y + r), Vector2(x, Y + r - 6)]), Color(0.06, 0.08, 0.1))
	DibujoAri.borde(self, Rect2(x1, Y - r, w, r * 2.0), 1.0, Color(0, 0, 0, 0.5), 1.0)


## Rosca de lado: radio r1 en x1 y r2 en x2 (iguales si es paralela), con los hilos inclinados.
func _rosca(x1: float, x2: float, r1: float, r2: float, colores: Array) -> void:
	var cuerpo := PackedVector2Array([Vector2(x1, Y - r1), Vector2(x2, Y - r2), Vector2(x2, Y + r2), Vector2(x1, Y + r1)])
	var sombra := PackedVector2Array()
	for p in cuerpo:
		sombra.append(p + Vector2(0, 4))
	draw_colored_polygon(sombra, Color(0, 0, 0, 0.35))
	Relieve.poligono_degradado(self, cuerpo, [colores[0], colores[1], colores[2], colores[colores.size() - 1]], Vector2(x1, Y - maxf(r1, r2)), Vector2(x1, Y + maxf(r1, r2)))
	var paso := 4.5
	var n := int((x2 - x1) / paso)
	for i in n:
		var x := x1 + 2.0 + i * paso
		var r := lerpf(r1, r2, (x - x1) / (x2 - x1))
		draw_line(Vector2(x, Y - r), Vector2(x + 2.5, Y + r), Color(0, 0, 0, 0.35), 1.4)
		draw_line(Vector2(x + 1.2, Y - r), Vector2(x + 3.7, Y + r), Color(1, 1, 1, 0.22), 0.8)
	var linea := cuerpo.duplicate()
	linea.append(cuerpo[0])
	draw_polyline(linea, Color(0, 0, 0, 0.45), 1.0, true)


func _teflon(x1: float, x2: float, r1: float, r2: float) -> void:
	var n := 7
	for i in n:
		var x := lerpf(x1, x2, float(i) / n)
		var w := (x2 - x1) / n
		var r := lerpf(r1, r2, (x - x1) / (x2 - x1)) + 0.5
		draw_colored_polygon(PackedVector2Array([Vector2(x, Y - r), Vector2(x + w * 0.9, Y - r), Vector2(x + w * 0.5, Y + r), Vector2(x - w * 0.4, Y + r)]), TEFLON)


## Cono macho de asiento (JIC): de radio r1 en la punta a r2 en la base.
func _cono(x1: float, x2: float, r1: float, r2: float) -> void:
	var p := PackedVector2Array([Vector2(x1, Y - r1), Vector2(x2, Y - r2), Vector2(x2, Y + r2), Vector2(x1, Y + r1)])
	Relieve.poligono_degradado(self, p, [ACERO[0], ACERO[1], ACERO[2], ACERO[4]], Vector2(x1, Y - r2), Vector2(x1, Y + r2))
	draw_rect(Rect2(x1 - 1, Y - 4, 3, 8), Color("141b22"))
	var linea := p.duplicate()
	linea.append(p[0])
	draw_polyline(linea, Color(0, 0, 0, 0.45), 1.0, true)


func _torica(x: float, r: float) -> void:
	_pieza(Rect2(x - 3, Y - r, 6, r * 2.0), TORICA, 3.0)


func _arandela(x1: float, x2: float, r: float, interior: float) -> void:
	_pieza(Rect2(x1, Y - r, x2 - x1, r * 2.0), [Color("c9d1d7"), Color("6d7880")], 1.0)
	_pieza(Rect2(x1 + 1, Y - interior - 4, x2 - x1 - 2, 4), TORICA, 1.0)
	_pieza(Rect2(x1 + 1, Y + interior, x2 - x1 - 2, 4), TORICA, 1.0)


func _virola(x1: float, x2: float, r: float) -> void:
	_pieza(Rect2(x1, Y - r, x2 - x1, r * 2.0), ACERO, 3.0)
	var n := 5
	for i in n:
		var x := lerpf(x1 + 8, x2 - 8, float(i) / (n - 1))
		draw_line(Vector2(x, Y - r + 1), Vector2(x, Y + r - 1), Color(0, 0, 0, 0.35), 2.0)
		draw_line(Vector2(x + 2, Y - r + 1), Vector2(x + 2, Y + r - 1), Color(1, 1, 1, 0.3), 1.0)


func _manguera(x1: float, x2: float, r: float, marca: String) -> void:
	_pieza(Rect2(x1, Y - r, x2 - x1, r * 2.0), GOMA, r * 0.6)
	if not marca.is_empty():
		PiezasAri.texto(self, marca, (x1 + x2) / 2.0 + 8, Y + 4, 9.0, Color("ffd166"), Tema.PESO_NEGRITA)


func _rotulo(x: float, y: float, texto: String) -> void:
	if not rotulos:
		return
	var w := PiezasAri.ancho_texto(texto, 10.0) + 12
	var r := Rect2(x - w / 2.0, y - 10, w, 18)
	DibujoAri.relleno(self, r, 4.0, Color(0.04, 0.05, 0.06, 0.8))
	DibujoAri.borde(self, r, 4.0, Color(1, 0.82, 0.4, 0.5), 1.0)
	PiezasAri.texto(self, texto, x, y + 3.5, 10.0, TINTA, Tema.PESO_NEGRITA)
