extends Animacion
## Regulador con Zener de 12 V: de la entrada, R1 de 470 Ω, y el Zener en paralelo con la carga,
## como zener_servicio. Mientras la carga sola no llega a 12 V, el Zener no conduce y la salida
## sigue a la entrada; pasados los 12 V conduce al revés y la salida queda en 12 V más su pequeña
## resistencia interna por la corriente que pasa.

const ANCHO := 400.0
const ALTO := 260.0
const R1 := 470.0
const VZ := 12.0
const RZ := 5.0
const CARGAS := [[1000.0, "1 kΩ"], [470.0, "470 Ω"], [0.0, "Sin carga"]]

var entrada := 24.0
var carga := 0
var _botones: Array[Button] = []
var _salida: Label
var _iz: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var e := fila_valor(c, "Tensión de entrada")
	e.text = "%d V" % roundi(entrada)
	barra(c, 0.0, 30.0, 1.0, entrada, func(v: float) -> void:
		e.text = "%d V" % roundi(v)
		poner_entrada(v))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for i in CARGAS.size():
		var b := boton_mando(fila, elegir_carga.bind(i))
		b.text = CARGAS[i][1]
		_botones.append(b)
	_salida = fila_valor(c, "Salida")
	_iz = fila_valor(c, "Corriente por el Zener")
	_nota = nota_mandos(c)
	_actualizar()


func poner_entrada(v: float) -> void:
	entrada = maxf(v, 0.0)
	_actualizar()


func elegir_carga(i: int) -> void:
	carga = clampi(i, 0, CARGAS.size() - 1)
	_actualizar()


func _r_carga() -> float:
	return CARGAS[carga][0]


## Tensión de la salida sin Zener: el divisor de R1 y la carga.
func _sin_zener() -> float:
	var rl := _r_carga()
	return entrada if rl <= 0.0 else entrada * rl / (R1 + rl)


func conduce() -> bool:
	return _sin_zener() > VZ


## Salida resolviendo el nudo con el Zener como fuente de 12 V y su resistencia interna.
func salida() -> float:
	if not conduce():
		return _sin_zener()
	var g := 1.0 / R1 + 1.0 / RZ + (1.0 / _r_carga() if _r_carga() > 0.0 else 0.0)
	return (entrada / R1 + VZ / RZ) / g


func corriente_zener() -> float:
	return maxf((salida() - VZ) / RZ, 0.0) if conduce() else 0.0


## 1 sin regular; 2 regulando con poca corriente de sobra; 3 regulando holgado.
func fase() -> int:
	if not conduce():
		return 1
	return 3 if corriente_zener() >= 0.005 else 2


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if k == carga else 0.6)
	_salida.text = "%s V" % coma(salida(), 1)
	_iz.text = "%s mA" % coma(corriente_zener() * 1000.0, 1)
	if not conduce():
		_nota.text = "La carga no llega a 12 V: el Zener no conduce y la salida sigue a la entrada."
	elif corriente_zener() < 0.005:
		_nota.text = "Regula, pero con muy poca corriente de sobra: con un poco más de carga dejaría de regular."
	else:
		_nota.text = "Regula: %s V en R1 y %s mA de sobra por el Zener, que disipa %s W." % [coma(entrada - salida(), 1), coma(corriente_zener() * 1000.0, 1), coma(corriente_zener() * salida(), 2)]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "REGULADOR CON DIODO ZENER DE 12 V", 12, Color("5b6267"))
	# Esquema.
	var rojo := Color("c0392b")
	l.draw_line(Vector2(30, 50), Vector2(70, 50), rojo, 3.0)
	l.draw_style_box(Tema.caja(Color.WHITE, 2, 0, 0, Color("20242a")), Rect2(70, 42, 50, 16))
	texto(Vector2(95, 72), "R1 470 Ω", 10, Tema.TINTA)
	l.draw_line(Vector2(120, 50), Vector2(200, 50), Tema.ACENTO_FUERTE if salida() > 0.1 else Color("8a949b"), 3.0)
	l.draw_line(Vector2(140, 50), Vector2(140, 92), Color("20242a"), 3.0)
	# Zener con el cátodo arriba.
	l.draw_colored_polygon(PackedVector2Array([Vector2(128, 116), Vector2(152, 116), Vector2(140, 96)]), Tema.TINTA)
	l.draw_polyline(PackedVector2Array([Vector2(122, 90), Vector2(128, 96), Vector2(152, 96), Vector2(158, 102)]), Tema.ACENTO_FUERTE if conduce() else Tema.TINTA, 3.5)
	l.draw_line(Vector2(140, 116), Vector2(140, 170), Color("20242a"), 3.0)
	texto(Vector2(176, 106), "DZ1", 10, Tema.TINTA)
	if _r_carga() > 0.0:
		l.draw_line(Vector2(200, 50), Vector2(200, 86), Color("20242a"), 3.0)
		l.draw_style_box(Tema.caja(Color.WHITE, 2, 0, 0, Color("20242a")), Rect2(192, 86, 16, 44))
		l.draw_line(Vector2(200, 130), Vector2(200, 170), Color("20242a"), 3.0)
		texto(Vector2(236, 108), "RL " + CARGAS[carga][1], 10, Tema.TINTA)
	l.draw_line(Vector2(30, 170), Vector2(200, 170), Color("20242a"), 3.0)
	texto(Vector2(30, 36), "%d V" % roundi(entrada), 12, Tema.TINTA)
	texto(Vector2(200, 34), "%s V" % coma(salida(), 1), 13, Tema.TINTA)
	if corriente_zener() > 0.0:
		for k in 3:
			var y := 52.0 + fmod(t * 40.0 + k * 40.0, 116.0)
			l.draw_circle(Vector2(140, y), 3.0, Tema.ACENTO_FUERTE)
	# Gráfica: salida frente a entrada.
	var marco := Rect2(270, 40, 110, 130)
	l.draw_rect(marco, Color.WHITE)
	l.draw_rect(marco, Color("8a949b"), false, 1.5)
	var puntos := PackedVector2Array()
	var guarda := entrada
	for k in 31:
		entrada = float(k)
		puntos.append(Vector2(marco.position.x + k / 30.0 * marco.size.x, marco.end.y - salida() / 30.0 * marco.size.y))
	entrada = guarda
	l.draw_polyline(puntos, Color("2c6e9e"), 2.5, true)
	l.draw_circle(Vector2(marco.position.x + entrada / 30.0 * marco.size.x, marco.end.y - salida() / 30.0 * marco.size.y), 5.0, Tema.ACENTO_FUERTE)
	texto(Vector2(325, 186), "salida frente a entrada", 9, Color("5b6267"))
	texto_derecha(Vector2(marco.position.x - 3, marco.end.y - 12.0 / 30.0 * marco.size.y), "12 V", 9)
	var rotulo := "REGULA" if conduce() else "NO CONDUCE"
	rotulo_estado(Vector2(200, 236), rotulo, Tema.ACIERTO if conduce() else Color("5b6267"))
	l.draw_set_transform(Vector2.ZERO)
