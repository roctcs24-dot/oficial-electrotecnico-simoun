extends Animacion
## Comparador de alarma de temperatura con un amplificador operacional, como operacional_servicio:
## la sonda NTC con R1 de 10 kΩ a 12 V llega a la entrada −; la referencia del potenciómetro, a la
## +. Cuando el calor hace bajar la tensión de la sonda por debajo de la referencia, la salida sube
## y enciende el LED de alarma. Con la sonda abierta, la entrada − queda en 12 V y no hay alarma.

const ANCHO := 400.0
const ALTO := 260.0
const V := 12.0
const R1 := 10000.0
const SALIDA_ALTA := 10.5

var temperatura := 25.0
var referencia := 0.2
var sonda_abierta := false
var _ntc: SimTermistor
var _abrir: Button
var _entradas: Label
var _nota: Label


func preparar() -> void:
	_ntc = SimTermistor.new("RT1", {"tipo": "ntc", "r25": 10000.0, "beta": 3950.0})
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var tt := fila_valor(c, "Temperatura de la sonda")
	tt.text = "%d °C" % roundi(temperatura)
	barra(c, 20.0, 90.0, 1.0, temperatura, func(v: float) -> void:
		tt.text = "%d °C" % roundi(v)
		poner_temperatura(v))
	var rr := fila_valor(c, "Referencia (P1)")
	rr.text = "%s V" % coma(V * referencia, 1)
	barra(c, 0.0, 0.5, 0.01, referencia, func(v: float) -> void:
		rr.text = "%s V" % coma(V * v, 1)
		poner_referencia(v))
	_abrir = boton_mando(c, func() -> void: abrir_sonda(not sonda_abierta))
	_entradas = fila_valor(c, "Entradas − / + · salida")
	_nota = nota_mandos(c)
	_actualizar()


func poner_temperatura(v: float) -> void:
	temperatura = v
	_actualizar()


func poner_referencia(p: float) -> void:
	referencia = clampf(p, 0.0, 1.0)
	_actualizar()


func abrir_sonda(si: bool) -> void:
	sonda_abierta = si
	_actualizar()


func v_menos() -> float:
	if sonda_abierta:
		return V
	var r := _ntc.ohmios_a(temperatura)
	return V * r / (r + R1)


func v_mas() -> float:
	return V * referencia


func alarma() -> bool:
	return v_mas() > v_menos()


## 2 vigilando; 3 en alarma.
func fase() -> int:
	return 3 if alarma() else 2


func _actualizar() -> void:
	if _nota == null:
		return
	_abrir.text = "Reparar la sonda" if sonda_abierta else "Cortar el cable de la sonda"
	_entradas.text = "%s V / %s V · %s V" % [coma(v_menos(), 1), coma(v_mas(), 1), coma(SALIDA_ALTA if alarma() else 0.0, 1)]
	if sonda_abierta:
		_nota.text = "Con la sonda abierta, la entrada − queda en 12 V, siempre por encima de la referencia: la alarma no salta nunca. Es un fallo peligroso que no avisa."
	elif alarma():
		_nota.text = "La sonda bajó de la referencia: la entrada + supera a la − y la salida sube a unos 10,5 V. LED de alarma encendido."
	else:
		_nota.text = "La sonda está por encima de la referencia: la salida está abajo y no hay alarma."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "COMPARADOR DE ALARMA DE TEMPERATURA", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	# Triángulo.
	l.draw_colored_polygon(PackedVector2Array([Vector2(170, 60), Vector2(170, 180), Vector2(260, 120)]), Color.WHITE)
	l.draw_polyline(PackedVector2Array([Vector2(170, 60), Vector2(170, 180), Vector2(260, 120), Vector2(170, 60)]), tinta, 3.0)
	texto(Vector2(184, 90), "−", 18, tinta)
	texto(Vector2(184, 150), "+", 18, tinta)
	# Entradas.
	l.draw_line(Vector2(40, 90), Vector2(170, 90), Color("2c6e9e"), 3.0)
	texto(Vector2(90, 76), "sonda %s V" % coma(v_menos(), 1), 11, tinta)
	if sonda_abierta:
		l.draw_line(Vector2(40, 100), Vector2(60, 80), Tema.FALLO, 3.0)
	l.draw_line(Vector2(40, 150), Vector2(170, 150), Color("8e5bd6"), 3.0)
	texto(Vector2(90, 166), "referencia %s V" % coma(v_mas(), 1), 11, tinta)
	# Barras de las dos tensiones.
	var marco := Rect2(40, 196, 200, 40)
	for par: Array in [[v_menos(), Color("2c6e9e"), 0], [v_mas(), Color("8e5bd6"), 1]]:
		var y: float = marco.position.y + par[2] * 22.0
		l.draw_rect(Rect2(marco.position.x, y, marco.size.x, 14), Color.WHITE)
		l.draw_rect(Rect2(marco.position.x, y, marco.size.x * clampf(par[0] / V, 0.0, 1.0), 14), par[1])
	texto(Vector2(250, 203), "−", 12, tinta, false)
	texto(Vector2(250, 225), "+", 12, tinta, false)
	# Salida y LED.
	var alta := alarma()
	l.draw_line(Vector2(260, 120), Vector2(330, 120), Tema.ACENTO_FUERTE if alta else Color("8a949b"), 3.0)
	if alta:
		l.draw_circle(Vector2(350, 120), 24.0, Color(1.0, 0.3, 0.2, 0.3 + 0.2 * sin(t * 6.0)))
	l.draw_circle(Vector2(350, 120), 14.0, Color("ff5a45") if alta else Color("8e1c15"))
	texto(Vector2(350, 150), "alarma", 10, tinta)
	rotulo_estado(Vector2(320, 228), "ALARMA" if alta else "VIGILANDO", Tema.FALLO if alta else Tema.ACIERTO)
	l.draw_set_transform(Vector2.ZERO)
