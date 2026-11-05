extends Animacion
## Tres flechas giratorias y sus ondas: la altura de cada flecha es el valor de esa fase.

const HERCIOS_LENTOS := 0.2
const DESFASE := [0.0, -TAU / 3.0, TAU / 3.0]
const NOMBRES := ["L1", "L2", "L3"]
## Colores de IEC 60445.
const COLORES := [Color("8a4b1f"), Color("1a1a1a"), Color("8a8f93")]


## Valor instantáneo de una fase, con amplitud 1.
static func valor_fase(fase: int, angulo: float) -> float:
	return sin(angulo + DESFASE[fase])


func preparar() -> void:
	lienzo.custom_minimum_size.y = 250.0


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var angulo := TAU * HERCIOS_LENTOS * t
	var radio := minf(tam.y * 0.36, tam.x * 0.17)
	var centro := Vector2(radio + 26.0, tam.y * 0.46)
	lienzo.draw_arc(centro, radio, 0.0, TAU, 60, Color("b4b9bc"), 1.5, true)
	var area := Rect2(centro.x + radio + 22.0, centro.y - radio, tam.x - (centro.x + radio + 22.0) - 14.0, radio * 2.0)
	lienzo.draw_line(Vector2(area.position.x, centro.y), Vector2(area.end.x, centro.y), Color("b4b9bc"), 1.5)
	for f in 3:
		var a: float = angulo + DESFASE[f]
		var punta := centro + Vector2(cos(a), -sin(a)) * radio
		var puntos := PackedVector2Array()
		for n in 81:
			var x := float(n) / 80.0
			puntos.append(Vector2(area.position.x + x * area.size.x, centro.y - radio * sin(a - x * TAU * 1.5)))
		lienzo.draw_polyline(puntos, COLORES[f], 3.0, true)
		lienzo.draw_dashed_line(punta, puntos[0], Color(COLORES[f], 0.5), 1.0, 5.0)
		flecha(centro, punta, COLORES[f], 4.0)
		texto(centro + Vector2(cos(a), -sin(a)) * (radio + 13.0), NOMBRES[f], 14, COLORES[f])
	var suma := valor_fase(0, angulo) + valor_fase(1, angulo) + valor_fase(2, angulo)
	texto(Vector2(tam.x / 2.0, tam.y - 18.0), "En cada instante, L1 + L2 + L3 = %s" % TextoTecnico.numero(absf(suma), 0), 15)
