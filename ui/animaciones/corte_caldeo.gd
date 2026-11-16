extends Animacion
## Resistencia de caldeo en un motor. Con el motor parado, el NC 21-22 del contactor la alimenta y
## el bobinado queda unos grados por encima del aire: no llega al punto de rocío y no condensa.
## En marcha, el contactor abre el NC y el propio motor se calienta con su carga. Temperaturas de
## ejemplo para una sala de máquinas a 32 °C con mucha humedad: valores de enseñanza.

const ANCHO := 400.0
const ALTO := 260.0
const AMBIENTE := 32.0
const ROCIO := 29.0

var en_marcha := false
var cortada := false
var _interruptor: Interruptor
var _cortar: Button
var _temperatura: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_marcha)
	tarjeta_control("Motor en marcha", "Toque para arrancarlo o pararlo", _interruptor)
	var c := tarjeta_mandos()
	_temperatura = fila_valor(c, "Bobinado / aire")
	_cortar = boton_mando(c, func() -> void: cortar(not cortada))
	_nota = nota_mandos(c)
	_actualizar()


func poner_marcha(si: bool) -> void:
	en_marcha = si
	_interruptor.set_pressed_no_signal(si)
	_interruptor.queue_redraw()
	_actualizar()


func cortar(si: bool) -> void:
	cortada = si
	_actualizar()


func calentando() -> bool:
	return not en_marcha and not cortada


func temperatura_bobinado() -> float:
	if en_marcha:
		return 75.0
	return AMBIENTE + 6.0 if calentando() else AMBIENTE - 2.0


func condensa() -> bool:
	return not en_marcha and temperatura_bobinado() <= ROCIO + 2.0


## 2 parado y calentando; 3 en marcha (el NC abierto). Con la resistencia cortada, 1.
func fase() -> int:
	if en_marcha:
		return 3
	return 2 if calentando() else 1


func _actualizar() -> void:
	if _nota == null:
		return
	_temperatura.text = "%d °C / %d °C" % [roundi(temperatura_bobinado()), roundi(AMBIENTE)]
	_cortar.text = "Cambiar la resistencia" if cortada else "Cortar la resistencia"
	if en_marcha:
		_nota.text = "En marcha, el contactor abre su NC 21-22: la resistencia se apaga y el motor se calienta con su propia carga."
	elif cortada:
		_nota.text = "Resistencia cortada: el motor parado se enfría por debajo del aire, condensa la humedad y su aislamiento baja."
	else:
		_nota.text = "Parado: 230 V por el NC 21-22. El bobinado queda %d °C por encima del aire y no condensa." % roundi(temperatura_bobinado() - AMBIENTE)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "RESISTENCIA DE CALDEO EN UN MOTOR", 12, Color("5b6267"))
	# Carcasa del motor en corte, con el bobinado y la resistencia.
	l.draw_style_box(Tema.caja(Color("9aa1a6"), 14, 0, 0, Color("5b6267")), Rect2(150, 40, 220, 150))
	var calor := 0.0 if not calentando() else 0.5 + 0.5 * sin(t * 3.0)
	var bobinado := Color("c27a45").lerp(Color("e05a2b"), 0.6 if en_marcha else 0.0)
	l.draw_rect(Rect2(170, 60, 180, 30), bobinado)
	l.draw_rect(Rect2(170, 140, 180, 30), bobinado)
	l.draw_rect(Rect2(175, 96, 170, 38), Color("6c7276"))
	texto(Vector2(260, 115), "rotor", 11, Color.WHITE)
	l.draw_rect(Rect2(180, 176, 160, 8), Color("8a949b").lerp(Color("ff5a2a"), calor))
	texto(Vector2(260, 204), "resistencia de caldeo", 10, Tema.TINTA)
	if condensa():
		for k in 7:
			var p := Vector2(180 + k * 26, 66 + fmod(t * 20.0 + k * 13.0, 18.0))
			l.draw_circle(p, 3.0, Color("2f7fd0"))
	# Mando: NC del contactor.
	var cable := Color("c0392b") if calentando() else Color("8a949b")
	texto(Vector2(40, 46), "230 V", 11, Tema.TINTA)
	l.draw_line(Vector2(40, 56), Vector2(40, 90), Color("c0392b"), 2.5)
	l.draw_line(Vector2(40, 90), Vector2(40, 100), Tema.TINTA, 2.5)
	if en_marcha:
		l.draw_line(Vector2(40, 130), Vector2(52, 104), Tema.TINTA, 3.0)
	else:
		l.draw_line(Vector2(40, 130), Vector2(48, 98), Tema.TINTA, 3.0)
		l.draw_line(Vector2(40, 100), Vector2(48, 100), Tema.TINTA, 3.0)
	texto(Vector2(84, 116), "K1 21-22", 10, Tema.TINTA)
	l.draw_line(Vector2(40, 130), Vector2(40, 180), cable, 2.5)
	l.draw_line(Vector2(40, 180), Vector2(180, 180), cable, 2.5)
	# Termómetros.
	texto(Vector2(80, 220), "Bobinado %d °C" % roundi(temperatura_bobinado()), 12, Tema.TINTA)
	texto(Vector2(80, 238), "Punto de rocío %d °C" % roundi(ROCIO), 11, Color("2f7fd0"))
	var rotulo := "EN MARCHA: CALDEO APAGADO" if en_marcha else ("CALENTANDO" if calentando() else "CONDENSA HUMEDAD")
	rotulo_estado(Vector2(290, 236), rotulo, Color("5b6267") if en_marcha else (Tema.ACIERTO if calentando() else Tema.FALLO))
	l.draw_set_transform(Vector2.ZERO)
