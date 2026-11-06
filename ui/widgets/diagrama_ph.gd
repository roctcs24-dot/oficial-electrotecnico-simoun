class_name DiagramaPH
extends Control
## Diagrama presión–entalpía simplificado del ciclo. Las presiones son las de la simulación, en
## escala logarítmica; las entalpías son esquemáticas, para ver la forma del ciclo y cómo se
## mueve con las presiones, no para calcular.

const FONDO := Color("14181b")
const EJE := Color("8e9496")
const CAMPANA := Color("6b7378")
const TEXTO := Color("d8dcd8")
const COMPRESION := Color("d9534f")
const CONDENSACION := Color("e0a030")
const EVAPORACION := Color("5aa0e0")
const P_MIN := 0.3
const P_MAX := 40.0
const MARCAS_BAR := [0.5, 1.0, 2.0, 5.0, 10.0, 20.0]
const MARGEN := Vector2(52.0, 26.0)

var te := -1.0
var tc := 29.0
var en_marcha := false


func _init() -> void:
	custom_minimum_size = Vector2(300.0, 240.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func actualizar(t_evaporacion: float, t_condensacion: float, marcha: bool) -> void:
	te = t_evaporacion
	tc = t_condensacion
	en_marcha = marcha
	queue_redraw()


## Entalpías esquemáticas del líquido y del vapor saturados, de 0 a 1.
static func h_liquido(t: float) -> float:
	return 0.14 + 0.30 * (t + 50.0) / 110.0


static func h_vapor(t: float) -> float:
	return 0.80 + 0.03 * (t + 50.0) / 110.0


func _area() -> Rect2:
	return Rect2(MARGEN, size - MARGEN * Vector2(1.3, 2.4))


func _punto(h: float, p_abs: float) -> Vector2:
	var a := _area()
	var y := (log(p_abs) - log(P_MIN)) / (log(P_MAX) - log(P_MIN))
	return Vector2(a.position.x + h * a.size.x, a.end.y - y * a.size.y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	var fuente := get_theme_default_font()
	var t := 12
	var a := _area()
	draw_line(a.position, Vector2(a.position.x, a.end.y), EJE, 1.5)
	draw_line(Vector2(a.position.x, a.end.y), a.end, EJE, 1.5)
	for bar: float in MARCAS_BAR:
		var y := _punto(0.0, bar).y
		draw_line(Vector2(a.position.x - 4.0, y), Vector2(a.end.x, y), EJE.darkened(0.6), 1.0)
		var etiqueta := TextoTecnico.numero(bar, 1 if bar < 1.0 else 0)
		draw_string(fuente, Vector2(4.0, y + 4.0), etiqueta, HORIZONTAL_ALIGNMENT_RIGHT, MARGEN.x - 10.0, t, TEXTO)
	draw_string(fuente, Vector2(4.0, a.position.y - 10.0), "bar abs.", HORIZONTAL_ALIGNMENT_LEFT, -1, t, TEXTO)
	draw_string(fuente, Vector2(a.position.x, a.end.y + 18.0), "Entalpía (esquemática)", HORIZONTAL_ALIGNMENT_LEFT, -1, t, TEXTO)
	_dibujar_campana(fuente, t)
	var p_e := SimNH3.p_sat_abs(te)
	var p_c := SimNH3.p_sat_abs(tc)
	if not en_marcha:
		for par in [[p_e, "Succión"], [p_c, "Descarga"]]:
			var y := _punto(0.0, par[0]).y
			draw_dashed_line(Vector2(a.position.x, y), Vector2(a.end.x, y), TEXTO, 1.0, 6.0)
			draw_string(fuente, Vector2(a.position.x + 6.0, y - 4.0), "%s %s bar" % [par[1], TextoTecnico.numero(par[0], 1)], HORIZONTAL_ALIGNMENT_LEFT, -1, t, TEXTO)
		draw_string(fuente, Vector2(a.position.x + 6.0, a.position.y + 14.0), "Compresor parado: no hay ciclo.", HORIZONTAL_ALIGNMENT_LEFT, -1, t, TEXTO)
		return
	# 1 aspiración, 2 descarga, 3 líquido, 4 tras la válvula de expansión.
	var h1 := h_vapor(te) + 0.03
	var h2 := h1 + 0.08 + 0.04 * log(p_c / p_e)
	var h3 := h_liquido(tc) - 0.01
	var p1 := _punto(h1, p_e)
	var p2 := _punto(h2, p_c)
	var p3 := _punto(h3, p_c)
	var p4 := _punto(h3, p_e)
	draw_line(p1, p2, COMPRESION, 3.0, true)
	draw_line(p2, p3, CONDENSACION, 3.0, true)
	draw_dashed_line(p3, p4, CONDENSACION, 2.0, 5.0)
	draw_line(p4, p1, EVAPORACION, 3.0, true)
	# Los números de los puntos van por fuera del ciclo, y los rótulos de las líneas en su centro.
	for par in [[p1, "1", Vector2(4.0, 16.0)], [p2, "2", Vector2(6.0, -6.0)], [p3, "3", Vector2(-14.0, -6.0)], [p4, "4", Vector2(-14.0, 16.0)]]:
		draw_circle(par[0], 4.0, TEXTO)
		draw_string(fuente, par[0] + par[2], par[1], HORIZONTAL_ALIGNMENT_LEFT, -1, t + 1, TEXTO)
	draw_string(fuente, Vector2(p3.x, p3.y - 8.0), "Condensación a %s °C" % TextoTecnico.numero(tc, 0), HORIZONTAL_ALIGNMENT_CENTER, p2.x - p3.x, t, CONDENSACION)
	draw_string(fuente, Vector2(p4.x, p4.y + 16.0), "Evaporación a %s °C" % TextoTecnico.numero(te, 0), HORIZONTAL_ALIGNMENT_CENTER, p1.x - p4.x, t, EVAPORACION)


## La campana de saturación: a la izquierda líquido, a la derecha vapor, dentro la mezcla.
## El punto crítico del amoníaco, a 132 °C, queda fuera del diagrama.
func _dibujar_campana(fuente: Font, t: int) -> void:
	var izquierda := PackedVector2Array()
	var derecha := PackedVector2Array()
	for paso in 23:
		var temp := -50.0 + paso * 5.0
		var p := SimNH3.p_sat_abs(temp)
		if p > P_MAX:
			break
		izquierda.append(_punto(h_liquido(temp), p))
		derecha.append(_punto(h_vapor(temp), p))
	draw_polyline(izquierda, CAMPANA, 2.0, true)
	draw_polyline(derecha, CAMPANA, 2.0, true)
	var a := _area()
	draw_string(fuente, Vector2(a.position.x + a.size.x * 0.03, a.end.y - 8.0), "Líquido", HORIZONTAL_ALIGNMENT_LEFT, -1, t, CAMPANA.lightened(0.3))
	draw_string(fuente, Vector2(a.position.x + a.size.x * 0.45, a.end.y - 8.0), "Mezcla", HORIZONTAL_ALIGNMENT_LEFT, -1, t, CAMPANA.lightened(0.3))
	draw_string(fuente, Vector2(a.position.x + a.size.x * 0.88, a.end.y - 8.0), "Vapor", HORIZONTAL_ALIGNMENT_LEFT, -1, t, CAMPANA.lightened(0.3))
