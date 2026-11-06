extends Animacion
## Curva de saturación del amoníaco: para cada temperatura, una sola presión. El deslizador
## elige la temperatura y se leen la presión absoluta, la relativa y los psi del manómetro.

const T_MIN := -40.0
const T_MAX := 45.0
const P_MAX_REL := 18.0
const CURVA := Color("1668c4")

var temperatura := -15.0
var _lectura: Label


func preparar() -> void:
	temperatura = float(params.get("temperatura", -15.0))
	_lectura = deslizador(T_MIN, T_MAX, 1.0, temperatura, _al_cambiar)
	_actualizar_lectura()


func _al_cambiar(valor: float) -> void:
	temperatura = valor
	_actualizar_lectura()


func _actualizar_lectura() -> void:
	_lectura.text = "%s °C" % TextoTecnico.numero(temperatura, 0)


func presion_relativa() -> float:
	return SimNH3.p_sat_rel(temperatura)


func _punto(t_c: float, p_rel: float) -> Vector2:
	var tam := lienzo.size
	var x := 56.0 + (t_c - T_MIN) / (T_MAX - T_MIN) * (tam.x - 76.0)
	var y := tam.y - 40.0 - (p_rel + 1.0) / (P_MAX_REL + 1.0) * (tam.y - 70.0)
	return Vector2(x, y)


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var eje := Color("8d989f")
	lienzo.draw_line(_punto(T_MIN, -1.0), _punto(T_MAX, -1.0), eje, 1.5)
	lienzo.draw_line(_punto(T_MIN, -1.0), _punto(T_MIN, P_MAX_REL), eje, 1.5)
	for p: float in [0.0, 5.0, 10.0, 15.0]:
		texto(_punto(T_MIN, p) - Vector2(22.0, 0.0), TextoTecnico.numero(p, 0), 12)
	for t_c: float in [-40.0, -20.0, 0.0, 20.0, 40.0]:
		texto(_punto(t_c, -1.0) + Vector2(0.0, 16.0), TextoTecnico.numero(t_c, 0), 12)
	texto(Vector2(16.0, 14.0), "bar relativos", 12, Tema.TINTA, false)
	texto(Vector2(tam.x - 16.0, tam.y - 10.0), "°C", 12, Tema.TINTA, false)
	var curva := PackedVector2Array()
	var t_c := T_MIN
	while t_c <= T_MAX:
		curva.append(_punto(t_c, SimNH3.p_sat_rel(t_c)))
		t_c += 1.0
	lienzo.draw_polyline(curva, CURVA, 3.0, true)
	var p := presion_relativa()
	var punto := _punto(temperatura, p)
	lienzo.draw_circle(punto, 6.0, Tema.TINTA)
	var abs_bar := SimNH3.p_sat_abs(temperatura)
	texto(Vector2(70.0, 38.0), "A %s °C: %s bar absolutos" % [TextoTecnico.numero(temperatura, 0), TextoTecnico.numero(abs_bar, 2)], 14, Tema.TINTA, false)
	texto(Vector2(70.0, 60.0), "Manómetro: %s bar = %s psi" % [TextoTecnico.numero(p, 2), TextoTecnico.numero(SimNH3.bar_a_psi(p), 0)], 14, Tema.TINTA, false)
