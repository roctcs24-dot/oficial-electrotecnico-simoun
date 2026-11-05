extends Animacion
## Generador en estrella: se elige qué medir y la lectura sale del motor de simulación.

const COLORES := {"L1": Color("8a4b1f"), "L2": Color("1a1a1a"), "L3": Color("8a8f93")}
const MEDIDAS := [["L1", "N"], ["L2", "N"], ["L1", "L2"], ["L2", "L3"]]

var _sim: SimSimulacion
var _medida: Array = MEDIDAS[2]


func preparar() -> void:
	lienzo.custom_minimum_size.y = 250.0
	var v_linea: float = contenido.barco()["red_principal"]["tension_v"]["valor"]
	_sim = SimSimulacion.new()
	_sim.agregar(SimFuenteTrifasica.new("B", {"v_linea": v_linea}))
	_sim.paso()
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	add_child(rejilla)
	var grupo := ButtonGroup.new()
	for m: Array in MEDIDAS:
		var b := Button.new()
		b.text = "%s – %s" % m
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = m == _medida
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.pressed.connect(_elegir.bind(m))
		rejilla.add_child(b)


func _elegir(medida: Array) -> void:
	_medida = medida
	lienzo.queue_redraw()


func lectura(a: String, b: String) -> float:
	return _sim.solucion.entre("B.%s" % a, "B.%s" % b).modulo()


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var radio := minf(tam.y * 0.38, tam.x * 0.24)
	var c := Vector2(tam.x * 0.33, tam.y * 0.56)
	var puntos := {
		"N": c,
		"L1": c + Vector2(0.0, -radio),
		"L2": c + Vector2(radio * 0.866, radio * 0.5),
		"L3": c + Vector2(-radio * 0.866, radio * 0.5),
	}
	for nombre: String in COLORES:
		lienzo.draw_line(c, puntos[nombre], COLORES[nombre], 5.0, true)
		var fuera: Vector2 = c + (puntos[nombre] - c) * 1.2
		texto(fuera, nombre, 16, COLORES[nombre])
		lienzo.draw_circle(puntos[nombre], 6.0, COLORES[nombre])
	lienzo.draw_circle(c, 7.0, Tema.TINTA)
	texto(c + Vector2(-18.0, -8.0), "N", 15)
	var a: Vector2 = puntos[_medida[0]]
	var b: Vector2 = puntos[_medida[1]]
	lienzo.draw_line(a, b, Tema.ACENTO, 8.0, true)
	lienzo.draw_circle(a, 8.0, Color("c9352b"))
	lienzo.draw_circle(b, 8.0, Color("20242a"))
	_dibujar_instrumento(Rect2(tam.x * 0.62, tam.y * 0.18, tam.x * 0.34, tam.y * 0.62))


func _dibujar_instrumento(r: Rect2) -> void:
	lienzo.draw_style_box(Tema.caja(Color("2a2d31"), 4, 0, 0), r)
	var pantalla := r.grow_individual(-10.0, -10.0, -10.0, -r.size.y * 0.42)
	lienzo.draw_style_box(Tema.caja(Color("bcd0b4"), 2, 0, 0), pantalla)
	var valor := lectura(_medida[0], _medida[1])
	texto(pantalla.get_center(), "%s V" % TextoTecnico.numero(valor, 0), 26, Tema.TINTA)
	var tipo := "tensión de fase" if _medida[1] == "N" else "tensión de línea"
	texto(Vector2(r.get_center().x, r.end.y - r.size.y * 0.26), tipo, 14, Tema.TEXTO)
