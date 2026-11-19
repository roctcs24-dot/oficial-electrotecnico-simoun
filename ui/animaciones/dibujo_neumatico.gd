class_name DibujoNeumatico
extends RefCounted
## Piezas comunes de las animaciones de neumática: tubos de aire con trazos que avanzan, bobina
## con LED, silenciador que sopla, detector magnético y nubes de escape. Colores de enseñanza:
## azul para el aire a presión y gris claro para el escape.

const PRESION := [Color("9fd0ff"), Color("2f8fe0"), Color("0f3d6e")]
const ESCAPE := [Color("e2e8ec"), Color("8a96a0"), Color("3e474e")]
const QUIETO := [Color("aeb7bd"), Color("5d6870"), Color("2e353b")]
const LED := Color("ffc23a")
const FONDO := DibujoHidraulico.FONDO
const CONTORNO := DibujoHidraulico.CONTORNO


static func colores(papel: String) -> Array:
	match papel:
		"presion":
			return PRESION
		"escape":
			return ESCAPE
	return QUIETO


## Tubo de poliuretano: contorno, color, brillo y, con caudal, trazos que avanzan.
static func tubo(ci: CanvasItem, puntos: PackedVector2Array, papel: String, avance: float, ancho := 6.0) -> void:
	var c := colores(papel)
	ci.draw_polyline(puntos, CONTORNO, ancho + 3.0, true)
	ci.draw_polyline(puntos, c[1], ancho, true)
	var brillo := PackedVector2Array()
	for p in puntos:
		brillo.append(p + Vector2(0, -ancho * 0.22))
	ci.draw_polyline(brillo, Color(c[0], 0.75), ancho * 0.3, true)
	if papel.is_empty() or avance < 0.0:
		return
	var paso := 12.0
	var desplazamiento := fposmod(avance, paso)
	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var largo := a.distance_to(b)
		var d := desplazamiento
		while d < largo:
			ci.draw_line(a.lerp(b, d / largo), a.lerp(b, minf(d + 3.0, largo) / largo), Color(1, 1, 1, 0.95), 2.0, true)
			d += paso
		desplazamiento = fposmod(desplazamiento - largo, paso)


## Bobina negra con su conector y LED; con halo ámbar si tiene tensión.
static func bobina(ci: CanvasItem, fuente: Font, r: Rect2, nombre: String, con_tension: bool) -> void:
	if con_tension:
		ci.draw_rect(r.grow(5.0), Color(1.0, 0.69, 0.0, 0.3))
	DibujoAri.pieza(ci, r, 4.0, [Color("3a3f44"), Color("1c2024"), Color("0b0d0f")], [], CONTORNO)
	var conector := Rect2(r.position.x + 6, r.position.y - 12, r.size.x - 12, 13)
	DibujoAri.pieza(ci, conector, 3.0, [Color("5a6570"), Color("2c343c"), Color("171c21")], [], CONTORNO)
	var led := conector.get_center()
	if con_tension:
		ci.draw_circle(led, 6.0, Color(LED, 0.45))
	ci.draw_circle(led, 2.6, LED if con_tension else Color("4b3a12"))
	var w := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	ci.draw_string(fuente, r.get_center() + Vector2(-w / 2.0, 4.0), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LED if con_tension else Color("cfd8df"))


## Silenciador de bronce; «soplo» de 0 a 1 dibuja la nube de escape.
static func silenciador(ci: CanvasItem, arriba: Vector2, soplo: float, t: float) -> void:
	DibujoAri.pieza(ci, Rect2(arriba.x - 6, arriba.y, 12, 16), 4.0, [Color("f2cf8a"), Color("c9963a"), Color("6a4a1a")], [], CONTORNO)
	if soplo <= 0.0:
		return
	for k in 3:
		var fase := fposmod(t * 1.6 + k / 3.0, 1.0)
		var centro := arriba + Vector2((k - 1) * 6.0, 18.0 + fase * 18.0)
		ci.draw_circle(centro, 4.0 + fase * 8.0, Color(1, 1, 1, 0.35 * soplo * (1.0 - fase)))


## Detector magnético en la ranura del cilindro con su LED.
static func detector(ci: CanvasItem, fuente: Font, c: Vector2, nombre: String, activo: bool) -> void:
	DibujoAri.relleno(ci, Rect2(c.x - 9, c.y - 3, 18, 6), 2.0, Color("15181b"))
	if activo:
		ci.draw_circle(c + Vector2(5, 0), 6.0, Color(LED, 0.5))
	ci.draw_circle(c + Vector2(5, 0), 2.2, LED if activo else Color("4b3a12"))
	var w := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	ci.draw_string(fuente, c + Vector2(-w / 2.0, -8.0), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LED if activo else Color("9aa5ad"))


## Manómetro pequeño de 0 a «maximo» bar.
static func manometro(ci: CanvasItem, fuente: Font, c: Vector2, r: float, valor: float, maximo := 10.0) -> void:
	DibujoHidraulico.manometro(ci, fuente, c, r, valor, maximo)
