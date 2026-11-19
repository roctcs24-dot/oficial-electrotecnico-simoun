class_name DibujoHidraulico
extends RefCounted
## Piezas comunes de las animaciones de hidráulica: tuberías con el aceite en movimiento según su
## presión, manómetro de esfera, tanque con mirilla, bomba y acero con relieve. Colores de
## enseñanza: rojo para la presión, naranja para la línea de trabajo, azul para el retorno.

const PRESION := [Color("ff9a7a"), Color("d9482b"), Color("7a1a0a")]
const TRABAJO := [Color("ffd08a"), Color("e08a1e"), Color("7a4206")]
const RETORNO := [Color("8fbcf0"), Color("2f6fb8"), Color("123766")]
const QUIETO := [Color("aeb7bd"), Color("6d777e"), Color("3b4247")]
const ACERO := [Color("f2f5f7"), Color("c9d1d6"), Color("97a2a9"), Color("6d777e")]
const PINTURA := [Color("6f9fd0"), Color("3a6ea6"), Color("1f4675"), Color("132c4b")]
const ACEITE := Color("e0a53a")
const FONDO := [Color("26313c"), Color("141b22")]
const CONTORNO := Color("0a0d10")


## Colores de una línea por su papel: "presion", "trabajo", "retorno" o "" (sin caudal).
static func colores(papel: String) -> Array:
	match papel:
		"presion":
			return PRESION
		"trabajo":
			return TRABAJO
		"retorno":
			return RETORNO
	return QUIETO


## Tubería: contorno oscuro, color medio, brillo arriba y, si hay caudal, trazos que avanzan.
static func tubo(ci: CanvasItem, puntos: PackedVector2Array, papel: String, avance: float, ancho := 8.0) -> void:
	var c := colores(papel)
	ci.draw_polyline(puntos, CONTORNO, ancho + 3.0, true)
	ci.draw_polyline(puntos, c[1], ancho, true)
	var brillo := PackedVector2Array()
	for p in puntos:
		brillo.append(p + Vector2(0, -ancho * 0.22))
	ci.draw_polyline(brillo, Color(c[0], 0.7), ancho * 0.28, true)
	if papel.is_empty() or avance < 0.0:
		return
	# Trazos claros que recorren la línea en el sentido del caudal.
	var paso := 16.0
	var desplazamiento := fposmod(avance, paso)
	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var largo := a.distance_to(b)
		var d := desplazamiento
		while d < largo:
			var p0 := a.lerp(b, d / largo)
			var p1 := a.lerp(b, minf(d + 6.0, largo) / largo)
			ci.draw_line(p0, p1, Color(1, 0.96, 0.84, 0.9), 2.2, true)
			d += paso
		desplazamiento = fposmod(desplazamiento - largo, paso)


static func pieza(ci: CanvasItem, r: Rect2, radio := 5.0, cols: Array = ACERO) -> void:
	DibujoAri.pieza(ci, r, radio, cols, [], CONTORNO, Color(1, 1, 1, 0.5), 0.45)


## Manómetro de esfera con escala de 0 a «maximo» bar y zona roja desde el 80 %.
static func manometro(ci: CanvasItem, fuente: Font, c: Vector2, r: float, valor: float, maximo := 250.0) -> void:
	ci.draw_circle(c + Vector2(0, 2), r + 5.0, Color(0, 0, 0, 0.4))
	ci.draw_circle(c, r + 4.0, Color("8a959e"))
	ci.draw_arc(c, r + 3.0, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.6), 1.5, true)
	ci.draw_circle(c, r, Color("f6f6f0"))
	var a0 := deg_to_rad(135.0)
	var barrido := deg_to_rad(270.0)
	ci.draw_arc(c, r - 3.0, a0 + barrido * 0.8, a0 + barrido, 10, Color("d9302b"), 3.0, true)
	for i in 11:
		var a := a0 + barrido * i / 10.0
		var largo := 6.0 if i % 2 == 0 else 3.5
		ci.draw_line(c + Vector2.from_angle(a) * (r - largo), c + Vector2.from_angle(a) * (r - 1.0), Color("20262c"), 1.4 if i % 2 == 0 else 0.8, true)
	var tam := int(maxf(r * 0.28, 7.0))
	for i: int in [0, 4, 8]:
		var a: float = a0 + barrido * i / 10.0
		var t := str(roundi(maximo * i / 10.0))
		var w := fuente.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		ci.draw_string(fuente, c + Vector2.from_angle(a) * (r - 14.0) + Vector2(-w / 2.0, tam * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color("20262c"))
	var wb := fuente.get_string_size("bar", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	ci.draw_string(fuente, c + Vector2(-wb / 2.0, r * 0.62), "bar", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color("20262c"))
	var aguja := a0 + barrido * clampf(valor / maximo, 0.0, 1.03)
	ci.draw_line(c, c + Vector2.from_angle(aguja) * (r - 6.0), Color("c0281f"), 2.4, true)
	ci.draw_circle(c, 3.4, Color("20262c"))


## Tanque pintado con mirilla de nivel.
static func tanque(ci: CanvasItem, fuente: Font, r: Rect2) -> void:
	DibujoAri.pieza(ci, r, 6.0, PINTURA, [], CONTORNO, Color(1, 1, 1, 0.35), 0.45)
	var mirilla := Rect2(r.end.x - 22.0, r.position.y + 8.0, 12.0, r.size.y - 16.0)
	DibujoAri.relleno(ci, mirilla, 4.0, Color("0b1015"))
	DibujoAri.relleno(ci, Rect2(mirilla.position + Vector2(2, mirilla.size.y * 0.3), Vector2(8, mirilla.size.y * 0.7 - 2)), 3.0, ACEITE)
	var t := "TANQUE"
	var w := fuente.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	ci.draw_string(fuente, Vector2(r.position.x + (r.size.x - 26.0 - w) / 2.0, r.get_center().y + 4.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e8f0f7"))


## Bomba de engranajes cortada: carcasa y dos piñones que giran «giro» radianes.
static func bomba(ci: CanvasItem, c: Vector2, giro: float, escala := 1.0) -> void:
	var r := Rect2(c - Vector2(34, 24) * escala, Vector2(68, 48) * escala)
	pieza(ci, r, 9.0 * escala)
	DibujoAri.relleno(ci, r.grow(-6.0 * escala), 6.0 * escala, Color("2a2f33"))
	for lado: int in [-1, 1]:
		var centro := c + Vector2(10.0 * lado, 0) * escala
		var ang: float = giro * lado + (0.0 if lado < 0 else PI / 12.0)
		for i in 12:
			var a := ang + TAU * i / 12.0
			var u := Vector2.from_angle(a)
			var diente := PackedVector2Array([centro + u.rotated(-0.16) * 9.0 * escala, centro + u.rotated(-0.1) * 14.5 * escala,
				centro + u.rotated(0.1) * 14.5 * escala, centro + u.rotated(0.16) * 9.0 * escala])
			ci.draw_colored_polygon(diente, Color("c9d1d6"))
		ci.draw_circle(centro, 10.0 * escala, Color("aab4bb"))
		ci.draw_circle(centro, 3.0 * escala, Color("2a2f33"))


## Rótulo en una píldora oscura.
static func rotulo(ci: CanvasItem, fuente: Font, centro: Vector2, texto: String, tam := 10, color := Color("ffd08a")) -> void:
	var w := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	DibujoAri.relleno(ci, Rect2(centro.x - w / 2.0 - 6.0, centro.y - tam * 0.8, w + 12.0, tam * 1.6), 5.0, Color(0.06, 0.09, 0.11, 0.85))
	ci.draw_string(fuente, Vector2(centro.x - w / 2.0, centro.y + tam * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
