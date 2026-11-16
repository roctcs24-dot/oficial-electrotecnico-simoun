extends Animacion
## Entrada de 24 V aislada con un optoacoplador, como optoacoplador_servicio: la señal del campo
## enciende el LED y la luz hace conducir el fototransistor, que baja la entrada de la tarjeta de
## 5 V a 0,2 V. Un pico de 1000 V en el cableado de campo no pasa al lado lógico mientras los
## comunes estén separados; si se unen, el pico llega a la tarjeta y la daña.

const ANCHO := 400.0
const ALTO := 260.0
const PICO_S := 1.5

var entrada := false
var unidos := false
var danada := false
var _desde_pico := 99.0
var _interruptor: Interruptor
var _unir: Button
var _salida: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_entrada)
	tarjeta_control("Final de carrera (24 V)", "Toque para activar la entrada", _interruptor)
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	boton_mando(fila, func() -> void: pico()).text = "Pico de 1000 V en el campo"
	_unir = boton_mando(fila, func() -> void: unir(not unidos))
	_salida = fila_valor(c, "Entrada de la tarjeta")
	_nota = nota_mandos(c)
	_actualizar()


func poner_entrada(si: bool) -> void:
	entrada = si
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(si)
		_interruptor.queue_redraw()
	_actualizar()


func unir(si: bool) -> void:
	unidos = si
	if not si:
		danada = false
	_actualizar()


func pico() -> void:
	_desde_pico = 0.0
	if unidos:
		danada = true
	_actualizar()


func luz() -> bool:
	return entrada and not danada


func salida() -> float:
	if danada:
		return 0.0
	return 0.2 if luz() else 5.0


## 1 entrada inactiva; 2 activa; 3 un pico en el campo.
func fase() -> int:
	if _desde_pico < PICO_S:
		return 3
	return 2 if entrada else 1


func _process(delta: float) -> void:
	_desde_pico += delta
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_unir.text = "Separar los comunes" if unidos else "Unir los comunes"
	_salida.text = "%s V · %s" % [coma(salida(), 1), "DAÑADA" if danada else ("activa" if salida() < 1.0 else "inactiva")]
	if danada:
		_nota.text = "Con los comunes unidos, el pico pasó a la electrónica y dañó la tarjeta. Separe los comunes: cada lado con el suyo."
	elif _desde_pico < PICO_S:
		_nota.text = "El pico se queda en el lado de campo: entre los dos lados solo pasa la luz."
	elif entrada:
		_nota.text = "24 V por R1 encienden el LED con unos 10 mA; la luz hace conducir el fototransistor y la tarjeta lee 0,2 V."
	else:
		_nota.text = "Sin señal, el LED está apagado y la tarjeta lee sus 5 V por R2."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "OPTOACOPLADOR: DOS LADOS AISLADOS", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	# Cápsula.
	l.draw_rect(Rect2(150, 60, 100, 130), Color("2a2e32"))
	l.draw_rect(Rect2(150, 60, 100, 130), tinta, false, 2.0)
	l.draw_line(Vector2(200, 64), Vector2(200, 186), Color("5b6267"), 1.0)
	texto(Vector2(200, 204), "OK1", 11, tinta)
	# LED.
	var c_led := Vector2(176, 125)
	l.draw_colored_polygon(PackedVector2Array([c_led + Vector2(-10, -10), c_led + Vector2(10, -10), c_led + Vector2(0, 8)]), Color("ff5a45") if luz() else Color("8a949b"))
	l.draw_line(c_led + Vector2(-10, 9), c_led + Vector2(10, 9), Color("cfd3d6"), 2.5)
	if luz():
		for k in 3:
			var x := 186.0 + fmod(t * 40.0 + k * 9.0, 26.0)
			l.draw_line(Vector2(x, 118 + k * 7), Vector2(x + 6, 118 + k * 7), Color("ff9a8a"), 2.0)
	# Fototransistor.
	var color_sal := Tema.ACENTO_FUERTE if luz() else Color("cfd3d6")
	l.draw_line(Vector2(222, 110), Vector2(222, 140), Color("cfd3d6"), 3.0)
	l.draw_line(Vector2(222, 116), Vector2(238, 100), color_sal, 2.5)
	l.draw_line(Vector2(222, 134), Vector2(238, 150), color_sal, 2.5)
	# Lado de campo.
	var campo := Color("c0392b") if entrada else Color("8a949b")
	l.draw_polyline(PackedVector2Array([Vector2(40, 40), Vector2(40, 100), Vector2(176, 100), Vector2(176, 115)]), campo, 3.0)
	l.draw_polyline(PackedVector2Array([Vector2(176, 135), Vector2(176, 160), Vector2(40, 160), Vector2(40, 230)]), tinta, 3.0)
	texto(Vector2(40, 30), "24 V campo", 10, tinta)
	texto(Vector2(90, 88), "R1", 10, tinta)
	texto(Vector2(70, 244), "0 V campo", 10, tinta)
	# Lado lógico.
	l.draw_polyline(PackedVector2Array([Vector2(360, 40), Vector2(360, 100), Vector2(238, 100)]), Color("2c6e9e"), 3.0)
	l.draw_polyline(PackedVector2Array([Vector2(238, 150), Vector2(238, 170), Vector2(360, 170), Vector2(360, 230)]), tinta, 3.0)
	texto(Vector2(360, 30), "5 V tarjeta", 10, tinta)
	texto(Vector2(300, 88), "R2", 10, tinta)
	texto(Vector2(330, 244), "0 V lógico", 10, tinta)
	texto(Vector2(300, 126), "%s V" % coma(salida(), 1), 14, Tema.FALLO if danada else tinta)
	if unidos:
		l.draw_line(Vector2(40, 230), Vector2(360, 230), Tema.FALLO, 3.0)
		texto(Vector2(200, 222), "comunes unidos", 10, Tema.FALLO)
	if _desde_pico < PICO_S:
		var brillo := 1.0 - _desde_pico / PICO_S
		l.draw_circle(Vector2(40, 130), 22.0, Color(1.0, 0.8, 0.1, 0.7 * brillo))
		texto(Vector2(80, 130), "1000 V", 11, Tema.FALLO)
		if unidos:
			l.draw_circle(Vector2(330, 160), 22.0, Color(1.0, 0.4, 0.1, 0.7 * brillo))
	var rotulo := "TARJETA DAÑADA" if danada else ("AISLADO" if not unidos else "SIN AISLAMIENTO")
	rotulo_estado(Vector2(200, 244), rotulo, Tema.FALLO if danada or unidos else Tema.ACIERTO)
	l.draw_set_transform(Vector2.ZERO)
