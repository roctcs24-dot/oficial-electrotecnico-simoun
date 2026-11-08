extends Animacion
## Una trama Modbus RTU recorre el bus RS-485: el maestro pide un registro a una dirección y
## solo contesta el esclavo que la tiene. Sin el terminador del final, la trama rebota en el
## extremo y algunas respuestas llegan con el CRC mal. A una dirección que nadie tiene, el
## maestro espera su tiempo de espera y pasa a la siguiente.

const CICLO_S := 3.6
const AMBAR := Color("d08a12")
const VERDE := Color("2f8f4a")
const ROJO := Color("c0392b")
const A_COLOR := Color("c8a12a")
const B_COLOR := Color("2a7a3c")
## Tramas reales, con su CRC: dirección, función 03, registro 0, 1 registro.
const PETICIONES := {
	1: "01 03 00 00 00 01 84 0A", 2: "02 03 00 00 00 01 84 39",
	3: "03 03 00 00 00 01 85 E8", 4: "04 03 00 00 00 01 84 5F",
}
const RESPUESTAS := {
	1: ["01 03 02 03 48 B8 82", 840], 2: ["02 03 02 03 6B BD 5B", 875], 3: ["03 03 02 01 68 C1 FA", 360],
}

var direccion := 2
var terminador := true
var _boton_terminador: Button
var _boton_direccion: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = 250.0
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	add_child(fila)
	_boton_terminador = _boton(alternar_terminador)
	fila.add_child(_boton_terminador)
	_boton_direccion = _boton(siguiente_direccion)
	fila.add_child(_boton_direccion)
	_actualizar_botones()


func _boton(accion: Callable) -> Button:
	var b := Button.new()
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.y = 48.0
	b.pressed.connect(accion)
	return b


func alternar_terminador() -> void:
	terminador = not terminador
	t = 0.0
	_actualizar_botones()


func siguiente_direccion() -> void:
	direccion = direccion % 4 + 1
	t = 0.0
	_actualizar_botones()


func _actualizar_botones() -> void:
	_boton_terminador.text = "Quitar el terminador del final" if terminador else "Poner el terminador del final"
	_boton_direccion.text = "Pedir a la dirección %d" % (direccion % 4 + 1)


## Sin terminador, una de cada dos respuestas llega deformada.
func respuesta_mala() -> bool:
	return not terminador and int(t / CICLO_S) % 2 == 0


func dibujar() -> void:
	fondo()
	var w := lienzo.size.x
	var y_a := 112.0
	var y_b := 122.0
	var x0 := 92.0
	var x1 := w - 18.0
	lienzo.draw_line(Vector2(x0, y_a), Vector2(x1, y_a), A_COLOR, 3.0)
	lienzo.draw_line(Vector2(x0, y_b), Vector2(x1, y_b), B_COLOR, 3.0)
	texto(Vector2(x1 + 8.0, y_a), "A", 11, A_COLOR)
	texto(Vector2(x1 + 8.0, y_b), "B", 11, B_COLOR)
	_terminador(x0 + 8.0, y_a, y_b, true)
	_terminador(x1 - 4.0, y_a, y_b, terminador)
	# Maestro y tres esclavos.
	lienzo.draw_rect(Rect2(10.0, 92.0, x0 - 18.0, 50.0), Color("c9cdcf"))
	lienzo.draw_rect(Rect2(10.0, 92.0, x0 - 18.0, 50.0), Color("6c7276"), false, 1.5)
	texto(Vector2((x0 - 8.0) / 2.0 + 5.0, 108.0), "Maestro", 12)
	texto(Vector2((x0 - 8.0) / 2.0 + 5.0, 126.0), "puesto", 11)
	var xs: Array[float] = []
	for k in 3:
		var x := x0 + 40.0 + (x1 - x0 - 90.0) * k / 2.0
		xs.append(x)
		var activo := direccion == k + 1 and _fase() == "respuesta"
		lienzo.draw_rect(Rect2(x - 30.0, 30.0, 60.0, 46.0), Color("dfe2e1") if not activo else Color("cfe8d6"))
		lienzo.draw_rect(Rect2(x - 30.0, 30.0, 60.0, 46.0), Color("6c7276"), false, 1.5)
		texto(Vector2(x, 44.0), "Esclavo", 11)
		texto(Vector2(x, 62.0), "dir. %d" % (k + 1), 12)
		lienzo.draw_line(Vector2(x - 6.0, 76.0), Vector2(x - 6.0, y_a), A_COLOR, 2.0)
		lienzo.draw_line(Vector2(x + 6.0, 76.0), Vector2(x + 6.0, y_b), B_COLOR, 2.0)
	_tramas(x0, x1, xs, y_a, y_b)
	_textos()


func _terminador(x: float, y_a: float, y_b: float, puesto: bool) -> void:
	if not puesto:
		texto(Vector2(x, y_b + 18.0), "sin 120 Ω", 10, ROJO)
		return
	var puntos := PackedVector2Array([Vector2(x, y_a)])
	for k in 4:
		puntos.append(Vector2(x + (-4.0 if k % 2 == 0 else 4.0), y_a + (y_b - y_a) * (k + 0.5) / 4.0))
	puntos.append(Vector2(x, y_b))
	lienzo.draw_polyline(puntos, Color("8c3b30"), 1.5)
	texto(Vector2(x, y_b + 18.0), "120 Ω", 10, Color("8c3b30"))


func _fase() -> String:
	var f := fmod(t, CICLO_S)
	if f < 1.2:
		return "peticion"
	if f < 1.5:
		return "pausa"
	if direccion <= 3 and f < 2.5:
		return "respuesta"
	return "resultado"


func _paquete(x: float, y: float, color: Color, alfa := 1.0) -> void:
	var r := Rect2(x - 16.0, y - 8.0, 32.0, 26.0)
	lienzo.draw_rect(r, Color(color, 0.85 * alfa))
	lienzo.draw_rect(r, Color(color.darkened(0.4), alfa), false, 1.5)


func _tramas(x0: float, x1: float, xs: Array[float], y_a: float, _y_b: float) -> void:
	var f := fmod(t, CICLO_S)
	if f < 1.2:
		_paquete(lerpf(x0, x1, f / 1.2), y_a, AMBAR)
	elif not terminador and f < 2.1:
		# La trama rebota en el extremo sin terminador y vuelve, más débil.
		_paquete(lerpf(x1, x0, (f - 1.2) / 0.9), y_a, AMBAR, 0.35)
	if direccion <= 3 and f >= 1.5 and f < 2.5:
		var origen: float = xs[direccion - 1]
		_paquete(lerpf(origen, x0, (f - 1.5)), y_a, ROJO if respuesta_mala() else VERDE)


func _textos() -> void:
	var f := fmod(t, CICLO_S)
	var y := 168.0
	texto(Vector2(12.0, y), "Petición:  %s" % PETICIONES[direccion], 12, Tema.TINTA, false)
	texto(Vector2(12.0, y + 18.0), "dirección %d · función 03, leer · registro 0 · cantidad 1 · CRC" % direccion, 11, Color("4c555b"), false)
	if f < 1.5:
		return
	if direccion > 3:
		var espera := clampf((f - 1.5) / 1.5 * 300.0, 0.0, 300.0)
		var texto_espera := "Nadie tiene la dirección 4: el maestro espera %d ms" % int(espera)
		if espera >= 300.0:
			texto_espera = "Sin respuesta tras 300 ms: tiempo de espera agotado"
		texto(Vector2(12.0, y + 42.0), texto_espera, 12, ROJO, false)
		return
	var r: Array = RESPUESTAS[direccion]
	texto(Vector2(12.0, y + 42.0), "Respuesta: %s" % r[0], 12, Tema.TINTA, false)
	if f < 2.5:
		return
	if respuesta_mala():
		texto(Vector2(12.0, y + 60.0), "CRC erróneo: la trama se deformó con el rebote y se descarta", 11, ROJO, false)
	else:
		var v: int = r[1]
		texto(Vector2(12.0, y + 60.0), "2 bytes de datos: 0x%04X = %d → %s °C (escala 0,1)" % [v, v, TextoTecnico.numero(v / 10.0, 1)], 11, VERDE.darkened(0.2), false)
