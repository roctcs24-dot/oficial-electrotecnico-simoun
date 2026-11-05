extends Animacion
## Circuito con fuente y lámpara: los electrones circulan según la ley de Ohm.

const CANTIDAD_PUNTOS := 22
const VELOCIDAD_MAX := 0.5

var _v := 12.0
var _r := 6.0
var _i_max := 1.0
var _p_max := 1.0
var _recorrido := 0.0
var _etiqueta_v: Label
var _etiqueta_r: Label


static func corriente(v: float, r: float) -> float:
	return 0.0 if r <= 0.0 else v / r


static func potencia(v: float, r: float) -> float:
	return v * corriente(v, r)


func preparar() -> void:
	_v = params.get("v", 12.0)
	_r = params.get("r", 6.0)
	var v_max: float = params["v_max"]
	var r_min: float = params["r_min"]
	_i_max = corriente(v_max, r_min)
	_p_max = potencia(v_max, r_min)
	_etiqueta_v = deslizador(params["v_min"], v_max, 1.0, _v, _al_cambiar_v)
	_etiqueta_r = deslizador(r_min, params["r_max"], 1.0, _r, _al_cambiar_r)
	_actualizar_etiquetas()


func _al_cambiar_v(valor: float) -> void:
	_v = valor
	_actualizar_etiquetas()


func _al_cambiar_r(valor: float) -> void:
	_r = valor
	_actualizar_etiquetas()


func _actualizar_etiquetas() -> void:
	_etiqueta_v.text = "V = %d V" % int(_v)
	_etiqueta_r.text = "R = %d Ω" % int(_r)


func _process(delta: float) -> void:
	super(delta)
	_recorrido = fposmod(_recorrido + delta * VELOCIDAD_MAX * corriente(_v, _r) / _i_max, 1.0)


## Punto del camino rectangular; s de 0 a 1 en el sentido de los electrones.
func _punto(rect: Rect2, s: float) -> Vector2:
	var perimetro := 2.0 * (rect.size.x + rect.size.y)
	var d := fposmod(s, 1.0) * perimetro
	var ancho := rect.size.x
	var alto := rect.size.y
	if d < alto / 2.0:
		return rect.position + Vector2(0.0, alto / 2.0 + d)
	d -= alto / 2.0
	if d < ancho:
		return rect.position + Vector2(d, alto)
	d -= ancho
	if d < alto:
		return rect.position + Vector2(ancho, alto - d)
	d -= alto
	if d < ancho:
		return rect.position + Vector2(ancho - d, 0.0)
	d -= ancho
	return rect.position + Vector2(0.0, d)


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var rect := Rect2(tam.x * 0.2, 34.0, tam.x * 0.6, tam.y - 78.0)
	lienzo.draw_rect(rect, Tema.TINTA, false, 3.0)
	_dibujar_fuente(rect)
	_dibujar_lampara(rect)
	if _v > 0.0:
		for n in CANTIDAD_PUNTOS:
			lienzo.draw_circle(_punto(rect, _recorrido + float(n) / CANTIDAD_PUNTOS), 4.0, Color("1668c4"))
	var i := corriente(_v, _r)
	var lectura := "I = V ÷ R = %s A" % TextoTecnico.numero(i, 2)
	if params.get("potencia", false):
		lectura += "     P = V × I = %s W" % TextoTecnico.numero(potencia(_v, _r), 0)
	texto(Vector2(tam.x / 2.0, tam.y - 20.0), lectura, 18)


func _dibujar_fuente(rect: Rect2) -> void:
	var c := Vector2(rect.position.x, rect.get_center().y)
	lienzo.draw_rect(Rect2(c - Vector2(16.0, 12.0), Vector2(32.0, 24.0)), Tema.PAPEL)
	lienzo.draw_line(c + Vector2(-20.0, -7.0), c + Vector2(20.0, -7.0), Tema.TINTA, 3.0)
	lienzo.draw_line(c + Vector2(-11.0, 7.0), c + Vector2(11.0, 7.0), Tema.TINTA, 5.0)
	texto(c + Vector2(-32.0, -13.0), "+", 18)
	texto(c + Vector2(-32.0, 14.0), "−", 18)


func _dibujar_lampara(rect: Rect2) -> void:
	var c := Vector2(rect.end.x, rect.get_center().y)
	var brillo := clampf(potencia(_v, _r) / _p_max, 0.0, 1.0)
	if brillo > 0.0:
		lienzo.draw_circle(c, 22.0 + 22.0 * brillo, Color(1.0, 0.8, 0.2, 0.4 * sqrt(brillo)))
	lienzo.draw_circle(c, 20.0, Color("fbe8a8").lerp(Color("ffb400"), brillo) if brillo > 0.01 else Color("d8d8d0"))
	lienzo.draw_arc(c, 20.0, 0.0, TAU, 40, Tema.TINTA, 3.0, true)
	var d := 20.0 * 0.707
	lienzo.draw_line(c + Vector2(-d, -d), c + Vector2(d, d), Tema.TINTA, 2.0)
	lienzo.draw_line(c + Vector2(-d, d), c + Vector2(d, -d), Tema.TINTA, 2.0)
