class_name ModuloPlc
extends Control
## Frente de un autómata compacto de 24 V DC, dibujado como en el carril del armario: bornes
## arriba y abajo, pantalla con el estado, LED verdes de las entradas I0.0 a I0.7, LED ámbar de
## las salidas Q0.0 a Q0.5, y los LED POWER y RUN. Lee el SimPLC en cada refresco.

const DISENO := Vector2(220, 132)
const REFRESCO_S := 0.12

var plc: SimPLC
var _refresco := 0.0


func _init(p_plc: SimPLC = null) -> void:
	plc = p_plc
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(DISENO.x, DISENO.y)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED and size.x > 0.0:
		var alto := minf(size.x, 420.0) * DISENO.y / DISENO.x
		if not is_equal_approx(custom_minimum_size.y, alto):
			custom_minimum_size.y = alto


func escala() -> float:
	return minf(size.x / DISENO.x, size.y / DISENO.y)


func _p(x: float, y: float) -> Vector2:
	return Vector2((size.x - DISENO.x * escala()) / 2.0, 0.0) + Vector2(x, y) * escala()


func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_p(x, y), Vector2(w, h) * escala())


func _process(delta: float) -> void:
	_refresco += delta
	if _refresco >= REFRESCO_S:
		_refresco = 0.0
		queue_redraw()


func _draw() -> void:
	if plc == null:
		return
	var s := escala()
	# Carril DIN detrás del módulo.
	DibujoAri.degradado(self, _r(0, 58, 220, 14), 0.0, [Color("e9eef2"), Color("8d99a3"), Color("5a6670")])
	var cuerpo := _r(6, 4, 208, 124)
	DibujoAri.sombra(self, cuerpo, 5.0 * s, 0.5, Vector2(2, 4) * s)
	DibujoAri.degradado(self, cuerpo, 5.0 * s, [Color("e8ecef"), Color("c9d0d6"), Color("9aa5ae")])
	DibujoAri.borde(self, cuerpo, 5.0 * s, Color("5a6670"), 1.0)
	var alimentado: bool = plc.estado["alimentado"]
	for k in 11:
		for y: float in [8.0, 112.0]:
			var b := _r(14 + k * 18.0, y, 12, 12)
			DibujoAri.relleno(self, b, 1.5 * s, Color("3a4148"))
			PiezasAri.tornillo(self, b.get_center(), 3.2 * s)
	var arriba := ["L+", "M", "1M"]
	for i in 8:
		arriba.append("I0.%d" % i)
	for k in 11:
		PiezasAri.texto(self, arriba[k], _p(20 + k * 18.0, 28).x, _p(0, 28).y, 4.6 * s, Color("3a4148"))
	for i in 6:
		PiezasAri.texto(self, "Q0.%d" % i, _p(20 + i * 18.0, 109).x, _p(0, 109).y, 4.6 * s, Color("3a4148"))
	# Pantalla del autómata.
	var pantalla := _r(14, 34, 96, 46)
	DibujoAri.relleno(self, pantalla, 3.0 * s, Color("0a1a10"))
	var cristal := pantalla.grow(-2.0 * s)
	DibujoAri.degradado(self, cristal, 2.0 * s, [Color("b4d49a"), Color("94b87a")] if alimentado else [Color("3d4a38"), Color("2e3a2a")])
	if alimentado:
		var ent := ""
		for i in SimPLC.ENTRADAS:
			ent += str(i) if plc.entrada_activa(i) else "-"
		var sal := ""
		for i in SimPLC.SALIDAS:
			sal += str(i) if plc.salida_activa(i) else "-"
		var lineas := ["I: " + ent, "Q: " + sal, str(plc.estado["modo"])]
		for i in lineas.size():
			PiezasAri.texto(self, lineas[i], cristal.position.x + 5.0 * s, cristal.position.y + (12.0 + i * 12.0) * s, 8.0 * s, Color("1e2a14"), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
	# LED de entradas y salidas.
	for i in SimPLC.ENTRADAS:
		var c := _p(124 + (i % 4) * 14.0, 40 + floorf(i / 4.0) * 16.0)
		_led(c, s, Color("3dff74"), plc.entrada_activa(i))
		PiezasAri.texto(self, "I%d" % i, c.x, c.y + 9.5 * s, 4.4 * s, Color("3a4148"))
	for i in SimPLC.SALIDAS:
		var c := _p(124 + (i % 4) * 14.0, 76 + floorf(i / 4.0) * 16.0)
		_led(c, s, Color("ffb020"), plc.salida_activa(i))
		PiezasAri.texto(self, "Q%d" % i, c.x, c.y + 9.5 * s, 4.4 * s, Color("3a4148"))
	_led(_p(186, 40), s, Color("3dff74"), alimentado)
	PiezasAri.texto(self, "POWER", _p(186, 50).x, _p(186, 50).y, 4.4 * s, Color("3a4148"))
	_led(_p(186, 62), s, Color("3dff74"), plc.en_marcha())
	PiezasAri.texto(self, "RUN", _p(186, 72).x, _p(186, 72).y, 4.4 * s, Color("3a4148"))
	_led(_p(186, 84), s, Color("ff4a3a"), alimentado and plc.estado["modo"] != "RUN")
	PiezasAri.texto(self, "STOP", _p(186, 94).x, _p(186, 94).y, 4.4 * s, Color("3a4148"))
	PiezasAri.texto(self, "PLC 24 V DC", _p(62, 92).x, _p(62, 92).y, 7.5 * s, Color("2b3238"))
	PiezasAri.texto(self, "8 DI · 6 DO · 1 AI", _p(62, 100).x, _p(62, 100).y, 4.6 * s, Color("4a555e"), Tema.PESO_MEDIO)


func _led(c: Vector2, s: float, color: Color, encendido: bool) -> void:
	if encendido:
		for i in 4:
			draw_circle(c, (8.0 - i * 1.4) * s, Color(color, 0.08 + i * 0.06))
	draw_circle(c, 3.6 * s, color if encendido else color.darkened(0.75))
	draw_circle(c + Vector2(-1, -1) * s, 1.2 * s, Color(1, 1, 1, 0.6 if encendido else 0.15))
