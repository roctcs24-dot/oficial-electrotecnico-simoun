extends Animacion
## Termistores con la curva de SimTermistor. NTC: sonda de 10 kΩ que el controlador lee con un
## divisor de 5 V y 10 kΩ. PTC: las tres del bobinado de un motor con TNF de 130 °C, leídas por el
## relé de termistores, que dispara por encima de 3,6 kΩ y rearma por debajo de 1,65 kΩ (valores
## de IEC 60947-8 — verificar con el relé del buque).

const ANCHO := 400.0
const ALTO := 260.0
const DISPARO_OHM := 3600.0
const REARME_OHM := 1650.0
const V_DIVISOR := 5.0
const R_DIVISOR := 10000.0
const RANGO := {"ntc": [-20.0, 100.0], "ptc": [20.0, 160.0]}

var tipo := "ntc"
var temperatura := 25.0
var disparado := false
var _ntc: SimTermistor
var _ptc: SimTermistor
var _botones: Array[Button] = []
var _barra: HSlider
var _valor_t: Label
var _resistencia: Label
var _lectura: Label
var _nota: Label


func preparar() -> void:
	_ntc = SimTermistor.new("RT1", {"tipo": "ntc", "r25": 10000.0, "beta": 3950.0})
	_ptc = SimTermistor.new("RT2", {"tipo": "ptc", "tnf": 130.0, "sensores": 3})
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for par: Array in [["ntc", "Sonda NTC"], ["ptc", "PTC del motor"]]:
		var b := boton_mando(fila, elegir_tipo.bind(par[0]))
		b.text = par[1]
		_botones.append(b)
	_valor_t = fila_valor(c, "Temperatura")
	_barra = barra(c, RANGO["ntc"][0], RANGO["ntc"][1], 1.0, temperatura, poner_temperatura)
	_resistencia = fila_valor(c, "Resistencia")
	_lectura = fila_valor(c, "Lo que ve el equipo")
	_nota = nota_mandos(c)
	_actualizar()


func elegir_tipo(nuevo: String) -> void:
	tipo = nuevo
	disparado = false
	temperatura = 25.0
	if _barra != null:
		_barra.min_value = RANGO[tipo][0]
		_barra.max_value = RANGO[tipo][1]
		_barra.set_value_no_signal(temperatura)
	_actualizar()


func poner_temperatura(t_c: float) -> void:
	temperatura = t_c
	if tipo == "ptc":
		var r := resistencia()
		if r > DISPARO_OHM:
			disparado = true
		elif r < REARME_OHM:
			disparado = false
	_actualizar()


func resistencia() -> float:
	return (_ntc if tipo == "ntc" else _ptc).ohmios_a(temperatura)


## Tensión que lee el controlador en la NTC con el divisor de 5 V y 10 kΩ.
func tension_sonda() -> float:
	var r := _ntc.ohmios_a(temperatura)
	return V_DIVISOR * r / (r + R_DIVISOR)


## 1 la NTC; 2 la PTC sin disparar; 3 la PTC con el relé disparado.
func fase() -> int:
	if tipo == "ntc":
		return 1
	return 3 if disparado else 2


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if ["ntc", "ptc"][k] == tipo else 0.6)
	_valor_t.text = "%d °C" % roundi(temperatura)
	_resistencia.text = _ohmios(resistencia())
	if tipo == "ntc":
		_lectura.text = "%s V en la entrada" % coma(tension_sonda(), 2)
		_nota.text = "La NTC baja al calentarse: el controlador ve menos tensión y la convierte en temperatura con la tabla de la sonda."
	else:
		_lectura.text = "Relé DISPARADO" if disparado else "Relé en servicio"
		if disparado:
			_nota.text = "Más de 3,6 kΩ: el relé abre su contacto y para el motor. Rearma cuando las PTC bajan de 1,65 kΩ al enfriarse."
		else:
			_nota.text = "Las tres PTC casi no cambian hasta acercarse a 130 °C; ahí suben de golpe."


static func _ohmios(r: float) -> String:
	return "%s kΩ" % coma(r / 1000.0, 1) if r >= 1000.0 else "%d Ω" % roundi(r)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "TERMISTOR NTC: SONDA" if tipo == "ntc" else "TERMISTOR PTC: PROTECCIÓN DEL MOTOR", 12, Color("5b6267"))
	# Gráfica R(T) en escala logarítmica, de 100 Ω a 100 kΩ.
	var marco := Rect2(46, 34, 200, 170)
	l.draw_rect(marco, Color.WHITE)
	l.draw_rect(marco, Color("8a949b"), false, 1.5)
	var rango: Array = RANGO[tipo]
	var puntos := PackedVector2Array()
	for k in 61:
		var tc := lerpf(rango[0], rango[1], k / 60.0)
		puntos.append(_en_grafica(marco, tc, (_ntc if tipo == "ntc" else _ptc).ohmios_a(tc), rango))
	l.draw_polyline(puntos, Color("2c6e9e") if tipo == "ntc" else Color("c0392b"), 3.0, true)
	if tipo == "ptc":
		var y_disparo := _en_grafica(marco, rango[0], DISPARO_OHM, rango).y
		l.draw_dashed_line(Vector2(marco.position.x, y_disparo), Vector2(marco.end.x, y_disparo), Tema.FALLO, 1.5, 6.0)
		texto(Vector2(marco.position.x + 4, y_disparo - 8), "disparo 3,6 kΩ", 10, Tema.FALLO, false)
	var actual := _en_grafica(marco, temperatura, resistencia(), rango)
	l.draw_circle(actual, 6.0, Tema.ACENTO_FUERTE)
	for etiqueta: Array in [[100.0, "100 Ω"], [1000.0, "1 kΩ"], [10000.0, "10 kΩ"], [100000.0, "100 kΩ"]]:
		var y := _en_grafica(marco, rango[0], etiqueta[0], rango).y
		texto_derecha(Vector2(marco.position.x - 4, y), etiqueta[1], 9)
	texto(Vector2(marco.position.x, marco.end.y + 12), "%d °C" % roundi(rango[0]), 10, Tema.TINTA)
	texto(Vector2(marco.end.x, marco.end.y + 12), "%d °C" % roundi(rango[1]), 10, Tema.TINTA)
	# A la derecha, el equipo que lo lee.
	if tipo == "ntc":
		l.draw_style_box(Tema.caja(Color.WHITE, 6, 0, 0, Color("20242a")), Rect2(270, 60, 110, 90))
		texto(Vector2(325, 78), "CONTROLADOR", 10, Color("5b6267"))
		texto(Vector2(325, 104), "%s V" % coma(tension_sonda(), 2), 14, Tema.TINTA)
		texto(Vector2(325, 130), "%d °C" % roundi(temperatura), 20, Tema.TINTA)
		rotulo_estado(Vector2(325, 196), "SONDA", Color("2c6e9e"))
	else:
		var m := Vector2(325, 110)
		var calor := clampf((temperatura - 20.0) / 140.0, 0.0, 1.0)
		l.draw_circle(m, 44.0, Color("9aa1a6").lerp(Color("e05a2b"), calor))
		l.draw_circle(m, 30.0, Color("c27a45"))
		for k in 3:
			l.draw_circle(m + Vector2.from_angle(k * TAU / 3.0 - PI / 2.0) * 22.0, 5.0, Color("7a3b1e"))
		texto(m, "M1", 14, Color.WHITE)
		rotulo_estado(Vector2(325, 196), "DISPARADO" if disparado else "EN MARCHA", Tema.FALLO if disparado else Tema.ACIERTO)
	texto(Vector2(200, 240), "%d °C → %s" % [roundi(temperatura), _ohmios(resistencia())], 13, Tema.TINTA)
	l.draw_set_transform(Vector2.ZERO)


func _en_grafica(marco: Rect2, t_c: float, ohm: float, rango: Array) -> Vector2:
	var x: float = marco.position.x + (t_c - rango[0]) / (rango[1] - rango[0]) * marco.size.x
	var f := (log(clampf(ohm, 100.0, 100000.0)) / log(10.0) - 2.0) / 3.0
	return Vector2(x, marco.end.y - f * marco.size.y)
