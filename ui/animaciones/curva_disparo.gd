extends Animacion
## Curva de disparo de un interruptor automático magnetotérmico (IEC 60898-1), en escala
## doble logarítmica: la banda térmica de tiempo inverso y la magnética instantánea de la
## curva B, C o D. Un deslizador mueve la corriente y se lee el tiempo de disparo.
## La forma de la banda térmica es una aproximación de una curva típica.

const BANDAS := {"B": [3.0, 5.0], "C": [5.0, 10.0], "D": [10.0, 20.0]}
const X_MIN := 1.0
const X_MAX := 50.0
const T_MIN := 0.005
const T_MAX := 10000.0
const T_MAGNETICO := 0.01

var curva := "C"
var veces := 2.0
var _boton: Button
var _texto: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = 260.0
	_boton = Button.new()
	_boton.mouse_filter = Control.MOUSE_FILTER_PASS
	_boton.custom_minimum_size.y = 48.0
	_boton.pressed.connect(siguiente_curva)
	add_child(_boton)
	_texto = deslizador(1.0, 30.0, 0.1, veces, cambiar_corriente)
	_actualizar()


func siguiente_curva() -> void:
	curva = {"B": "C", "C": "D", "D": "B"}[curva]
	_actualizar()


func cambiar_corriente(v: float) -> void:
	veces = v
	_actualizar()


func _actualizar() -> void:
	_boton.text = "Curva %s: cambiar de curva" % curva
	_texto.text = "%s × In" % TextoTecnico.numero(veces, 1)


## Tiempo de la banda térmica, en segundos: la curva lenta no dispara hasta 1,13 × In y la
## rápida dispara a 1,45 × In en menos de una hora.
static func tiempo_termico(x: float, rapido: bool) -> float:
	var umbral := 1.45 if rapido else 1.13
	if x <= umbral:
		return INF
	var k := 60.0 if rapido else 1200.0
	return k / pow(x - umbral + 0.15, 2.0)


## [más rápido, más lento] en que puede disparar a x veces In.
func tiempo_disparo(x: float) -> Array:
	var banda: Array = BANDAS[curva]
	if x >= float(banda[1]):
		return [T_MAGNETICO, T_MAGNETICO]
	if x >= float(banda[0]):
		return [T_MAGNETICO, tiempo_termico(x, false)]
	return [tiempo_termico(x, true), tiempo_termico(x, false)]


func _x(r: Rect2, x: float) -> float:
	return r.position.x + r.size.x * log(x / X_MIN) / log(X_MAX / X_MIN)


func _y(r: Rect2, tiempo: float) -> float:
	var tt := clampf(tiempo, T_MIN, T_MAX)
	return r.end.y - r.size.y * log(tt / T_MIN) / log(T_MAX / T_MIN)


func dibujar() -> void:
	fondo()
	var r := Rect2(Vector2(46.0, 26.0), lienzo.size - Vector2(60.0, 64.0))
	lienzo.draw_rect(r, Color.WHITE)
	for x: float in [1.0, 2.0, 3.0, 5.0, 10.0, 20.0, 50.0]:
		lienzo.draw_line(Vector2(_x(r, x), r.position.y), Vector2(_x(r, x), r.end.y), Color("dde3e6"), 1.0)
		texto(Vector2(_x(r, x), r.end.y + 12.0), TextoTecnico.numero(x, 0), 11, Color("4c555b"))
	for tiempo: float in [0.01, 0.1, 1.0, 10.0, 100.0, 1000.0]:
		lienzo.draw_line(Vector2(r.position.x, _y(r, tiempo)), Vector2(r.end.x, _y(r, tiempo)), Color("dde3e6"), 1.0)
		texto(Vector2(24.0, _y(r, tiempo)), _texto_tiempo(tiempo), 10, Color("4c555b"))
	lienzo.draw_rect(r, Color("7c8a93"), false, 1.0)
	texto(Vector2(r.get_center().x, r.end.y + 28.0), "Corriente en veces la nominal (× In)", 11, Color("4c555b"))
	# Banda magnética de la curva y banda de disparo completa.
	var banda: Array = BANDAS[curva]
	var x0 := _x(r, float(banda[0]))
	lienzo.draw_rect(Rect2(Vector2(x0, r.position.y), Vector2(_x(r, float(banda[1])) - x0, r.size.y)), Color(0.16, 0.37, 0.69, 0.10))
	var poligono := PackedVector2Array()
	var pasos := 60
	for k in pasos + 1:
		var x := 1.14 * pow(X_MAX / 1.14, float(k) / pasos)
		poligono.append(Vector2(_x(r, x), _y(r, tiempo_disparo(x)[1])))
	for k in range(pasos, -1, -1):
		var x := 1.46 * pow(X_MAX / 1.46, float(k) / pasos)
		poligono.append(Vector2(_x(r, x), _y(r, tiempo_disparo(x)[0])))
	lienzo.draw_colored_polygon(poligono, Color(0.75, 0.22, 0.17, 0.25))
	lienzo.draw_polyline(poligono, Color("c0392b"), 1.5)
	# Corriente elegida y su tiempo de disparo.
	var xx := _x(r, veces)
	lienzo.draw_line(Vector2(xx, r.position.y), Vector2(xx, r.end.y), Color("2a5fb0"), 2.0)
	texto(Vector2(lienzo.size.x * 0.5, 12.0), lectura(), 12, Color("1f4e79"))


func lectura() -> String:
	var td := tiempo_disparo(veces)
	if is_inf(td[1]):
		return "No dispara: corriente admisible"
	if td[1] <= T_MAGNETICO:
		return "Disparo magnético instantáneo"
	if is_inf(td[0]):
		return "Puede disparar, tras más de %s" % _texto_tiempo(td[1])
	if td[0] <= T_MAGNETICO:
		return "Magnético o térmico: entre instantáneo y %s" % _texto_tiempo(td[1])
	return "Disparo térmico entre %s y %s" % [_texto_tiempo(td[0]), _texto_tiempo(td[1])]


func _texto_tiempo(tiempo: float) -> String:
	if tiempo < 1.0:
		return "%s s" % TextoTecnico.numero(tiempo, 2)
	if tiempo < 120.0:
		return "%s s" % TextoTecnico.numero(tiempo, 0)
	if tiempo < 7200.0:
		return "%s min" % TextoTecnico.numero(tiempo / 60.0, 0)
	return "%s h" % TextoTecnico.numero(tiempo / 3600.0, 0)
