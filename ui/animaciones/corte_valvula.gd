extends Animacion
## Corte de una válvula de bola: al girar la maneta, el agujero de la bola se cruza con el tubo y
## el paso se cierra. El paso relativo es aproximado: los asientos tapan el agujero un poco antes
## de los 90°, hacia los 80° (valor de enseñanza, no de un fabricante).

const ANCHO := 420.0
const ALTO := 200.0
const CIERRE := 80.0

var angulo := 0.0
var _paso: Label
var _estado: Label


## Paso relativo (0 a 1) con la maneta girada «grados» desde la posición abierta.
static func paso(grados: float) -> float:
	var c := cos(deg_to_rad(clampf(grados, 0.0, 90.0)))
	var cierre := cos(deg_to_rad(CIERRE))
	return clampf((c - cierre) / (1.0 - cierre), 0.0, 1.0)


static func estado(grados: float) -> String:
	var p := paso(grados)
	if p >= 0.97:
		return "abierta"
	return "cerrada" if p <= 0.0 else "a medias"


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var giro := fila_valor(c, "Giro de la maneta")
	barra(c, 0.0, 90.0, 5.0, angulo, func(v: float) -> void:
		angulo = v
		giro.text = "%d°" % roundi(v)
		_actualizar())
	giro.text = "%d°" % roundi(angulo)
	_paso = fila_valor(c, "Paso")
	_estado = fila_valor(c, "Estado")
	_actualizar()


func _actualizar() -> void:
	if _estado == null:
		return
	_paso.text = "%d %%" % roundi(paso(angulo) * 100.0)
	_estado.text = estado(angulo)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, [Color("26313c"), Color("141b22")])
	var c := Vector2(ANCHO / 2.0, 104)
	var p := paso(angulo)
	# Tubo en corte, con el agua según el paso.
	l.draw_rect(Rect2(10, c.y - 30, ANCHO - 20, 60), Color("1b2a36"))
	var h := 52.0 * p
	if h > 0.5:
		l.draw_rect(Rect2(10, c.y - h / 2.0, ANCHO - 20, h), Color("3a9be0"))
	DibujoAri.degradado(l, Rect2(10, c.y - 34, ANCHO - 20, 8), 0.0, DibujoValvula.HIERRO)
	DibujoAri.degradado(l, Rect2(10, c.y + 26, ANCHO - 20, 8), 0.0, DibujoValvula.HIERRO)
	# Cuerpo y bola girada.
	PiezasAri._disco(l, c, 60.0, DibujoValvula.BRONCE[0], DibujoValvula.BRONCE[3], Vector2(-0.3, -0.4), 10)
	PiezasAri._disco(l, c, 47.0, Color("ffffff"), Color("3b444c"), Vector2(-0.3, -0.35), 10)
	var a := deg_to_rad(angulo)
	var eje := Vector2(cos(a), sin(a))
	var normal := eje.orthogonal()
	var agujero := PackedVector2Array([c - eje * 47.0 - normal * 20.0, c + eje * 47.0 - normal * 20.0, c + eje * 47.0 + normal * 20.0, c - eje * 47.0 + normal * 20.0])
	l.draw_colored_polygon(agujero, Color("1b2a36"))
	if p > 0.0:
		var w := 20.0 * p
		var agua := PackedVector2Array([c - eje * 47.0 - normal * w, c + eje * 47.0 - normal * w, c + eje * 47.0 + normal * w, c - eje * 47.0 + normal * w])
		l.draw_colored_polygon(agua, Color("3a9be0"))
	l.draw_arc(c, 47.0, 0, TAU, 48, Color("3b444c"), 2.0, true)
	l.draw_arc(c, 60.0, 0, TAU, 48, Color("3b2c0b"), 2.0, true)
	# Flechas del agua: menos visibles aguas abajo cuanto menos paso.
	if p > 0.05:
		var t0 := fmod(t * 50.0, 32.0)
		var x := 16.0 + t0
		while x < ANCHO - 16.0:
			if absf(x - c.x) > 66.0:
				var alfa := 0.85 if x < c.x else 0.25 + 0.6 * p
				DibujoAri.galon(l, Vector2(x, c.y), 7.0, 1, Color(1, 1, 1, alfa), 2.4)
			x += 32.0
	# Maneta vista desde arriba, en un recuadro: en línea con el tubo o cruzada.
	var m := Vector2(ANCHO - 46.0, 30.0)
	DibujoAri.relleno(l, Rect2(m - Vector2(36, 22), Vector2(72, 44)), 6.0, Color(0, 0, 0, 0.35))
	l.draw_line(m - Vector2(30, 0), m + Vector2(30, 0), Color("8a959e"), 6.0)
	var dm := Vector2(cos(a), -sin(a)) * 26.0
	l.draw_line(m, m + dm, Color("d02a1e"), 7.0, true)
	l.draw_circle(m, 5.0, Color("c9d1d7"))
	texto(Vector2(m.x, m.y + 30.0), "maneta", 10, Color("a9b6c1"))
	l.draw_set_transform(Vector2.ZERO)
