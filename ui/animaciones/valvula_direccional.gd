extends Animacion
## Válvula direccional 4/3 de centro cerrado con dos bobinas: sin tensión, los muelles centran
## la corredera y el motor hidráulico queda parado; con Y1 la corredera se desplaza y el aceite
## de la bomba (P) va a A, y el motor vira; con Y2, a B, y arría. Con la bobina cortada, la
## corredera no se mueve aunque el mando le dé tensión.

const ACEITE := Color("c8902a")
const RETORNO := Color("7a8a96")
const ACERO := Color("9aa0a3")

var y1 := false
var y2 := false
var y1_cortada := false
var _posicion := 0.0
var _giro := 0.0
var _botones := {}


func preparar() -> void:
	lienzo.custom_minimum_size.y = 250.0
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	add_child(fila)
	for clave in ["y1", "y2", "cortar"]:
		var b := Button.new()
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y = 48.0
		b.pressed.connect(_pulsar.bind(clave))
		fila.add_child(b)
		_botones[clave] = b
	_actualizar_botones()


func _pulsar(clave: String) -> void:
	match clave:
		"y1":
			y1 = not y1
			y2 = false
		"y2":
			y2 = not y2
			y1 = false
		"cortar":
			y1_cortada = not y1_cortada
	_actualizar_botones()


func _actualizar_botones() -> void:
	_botones["y1"].text = "Quitar tensión a Y1" if y1 else "Tensión a Y1 (virar)"
	_botones["y2"].text = "Quitar tensión a Y2" if y2 else "Tensión a Y2 (arriar)"
	_botones["cortar"].text = "Reparar la bobina Y1" if y1_cortada else "Cortar el hilo de Y1"


## -1 a 1: posición de la corredera que piden las bobinas que de verdad tiran.
func objetivo() -> float:
	var tira1 := y1 and not y1_cortada
	if tira1 and not y2:
		return 1.0
	if y2 and not tira1:
		return -1.0
	return 0.0


func _process(delta: float) -> void:
	_posicion = move_toward(_posicion, objetivo(), delta * 4.0)
	_giro += _posicion * delta * 3.0
	super(delta)


func dibujar() -> void:
	fondo()
	var w := lienzo.size.x
	var c := Vector2(w * 0.5, 96.0)
	var celda := minf(w * 0.18, 76.0)
	# Cuerpo de la válvula con sus tres posiciones; la corredera se desplaza.
	var desplazamiento := _posicion * celda
	for k in 3:
		var r := Rect2(c.x - celda * 1.5 + k * celda + desplazamiento, c.y - celda * 0.5, celda, celda)
		lienzo.draw_rect(r, Color("f3f4f2"))
		lienzo.draw_rect(r, Tema.TINTA, false, 2.0)
		var centro := r.get_center()
		match k:
			0:
				flecha(centro + Vector2(-celda * 0.25, celda * 0.35), centro + Vector2(-celda * 0.25, -celda * 0.35), Tema.TINTA, 2.0)
				flecha(centro + Vector2(celda * 0.25, -celda * 0.35), centro + Vector2(celda * 0.25, celda * 0.35), Tema.TINTA, 2.0)
			1:
				for x in [-0.25, 0.25]:
					lienzo.draw_line(centro + Vector2(celda * x - 6.0, -celda * 0.35), centro + Vector2(celda * x + 6.0, -celda * 0.35), Tema.TINTA, 2.0)
					lienzo.draw_line(centro + Vector2(celda * x - 6.0, celda * 0.35), centro + Vector2(celda * x + 6.0, celda * 0.35), Tema.TINTA, 2.0)
			2:
				flecha(centro + Vector2(-celda * 0.25, celda * 0.35), centro + Vector2(celda * 0.25, -celda * 0.35), Tema.TINTA, 2.0)
				flecha(centro + Vector2(celda * 0.25, celda * 0.35), centro + Vector2(-celda * 0.25, -celda * 0.35), Tema.TINTA, 2.0)
	# Bobinas a los lados.
	for lado in [-1, 1]:
		var x0: float = c.x + lado * (celda * 1.5 + 4.0) + desplazamiento + (0.0 if lado > 0 else -36.0)
		var activa: bool = (lado < 0 and y1 and not y1_cortada) or (lado > 0 and y2)
		lienzo.draw_rect(Rect2(x0, c.y - 16.0, 36.0, 32.0), Color("ffcf4a") if activa else Color("d9dcdd"))
		lienzo.draw_rect(Rect2(x0, c.y - 16.0, 36.0, 32.0), Tema.TINTA, false, 2.0)
		lienzo.draw_line(Vector2(x0 + 4.0, c.y + 14.0), Vector2(x0 + 32.0, c.y - 14.0), Tema.TINTA, 1.5)
		texto(Vector2(x0 + 18.0, c.y - 28.0), "Y1" if lado < 0 else "Y2", 13)
		if lado < 0 and y1_cortada:
			texto(Vector2(x0 + 18.0, c.y + 30.0), "cortada", 11, Color("c0392b"))
	# Bomba (P) y tanque (T) abajo; motor hidráulico arriba con A y B.
	var p := Vector2(c.x - celda * 0.25, c.y + celda * 0.5)
	var t := Vector2(c.x + celda * 0.25, c.y + celda * 0.5)
	lienzo.draw_line(p, p + Vector2(0, 40.0), ACEITE, 4.0)
	lienzo.draw_line(t, t + Vector2(0, 40.0), RETORNO, 4.0)
	texto(p + Vector2(-12.0, 50.0), "P (bomba)", 11)
	texto(t + Vector2(14.0, 50.0), "T (tanque)", 11)
	var a := Vector2(c.x - celda * 0.25, c.y - celda * 0.5)
	var b := Vector2(c.x + celda * 0.25, c.y - celda * 0.5)
	var motor := Vector2(c.x, 22.0)
	var color_a := ACEITE if _posicion > 0.5 else (RETORNO if _posicion < -0.5 else ACERO)
	var color_b := ACEITE if _posicion < -0.5 else (RETORNO if _posicion > 0.5 else ACERO)
	lienzo.draw_polyline(PackedVector2Array([a, Vector2(a.x, motor.y), motor + Vector2(-16.0, 0)]), color_a, 4.0)
	lienzo.draw_polyline(PackedVector2Array([b, Vector2(b.x, motor.y), motor + Vector2(16.0, 0)]), color_b, 4.0)
	lienzo.draw_circle(motor, 15.0, Color("f3f4f2"))
	lienzo.draw_arc(motor, 15.0, 0.0, TAU, 32, Tema.TINTA, 2.0)
	lienzo.draw_line(motor, motor + Vector2(cos(_giro), sin(_giro)) * 12.0, Tema.TINTA, 3.0)
	texto(Vector2(motor.x + 86.0, motor.y), "Motor del power block", 11)
	var estado := "parado: corredera centrada por los muelles"
	if _posicion > 0.5:
		estado = "virando: P → A, B → T"
	elif _posicion < -0.5:
		estado = "arriando: P → B, A → T"
	texto(Vector2(w * 0.5, 232.0), estado, 13)
