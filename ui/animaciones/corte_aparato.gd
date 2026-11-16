extends Animacion
## Aparatos de cuadro por dentro. tipo "amperimetro" o "voltimetro": hierro móvil con su bobina
## fija y las dos piezas de hierro que se repelen; un deslizador elige la corriente de la barra
## (con TI de 100/5 A) o la tensión entre fases. tipo "horometro": el contador de rodillos con su
## motor síncrono, acelerado (un segundo de la animación son seis minutos); uno de 60 Hz en la
## red de 50 Hz cuenta una sexta parte menos.

const ANCHO := 400.0
const ALTO := 280.0
## Horas que cuenta la animación por cada segundo real.
const HORAS_POR_SEGUNDO := 0.1

var valor := 0.0
var en_marcha := false
var de_60_hz := false
var horas := 12408.6
var _interruptor: Interruptor
var _boton_60: Button
var _lectura: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _tipo() == "horometro":
		_interruptor = Interruptor.new()
		_interruptor.toggled.connect(poner_marcha)
		tarjeta_control("Bomba en marcha", "Toque para arrancarla o pararla", _interruptor)
		var c := tarjeta_mandos()
		_lectura = fila_valor(c, "Contador")
		_boton_60 = boton_mando(c, func() -> void: poner_60_hz(not de_60_hz))
		_nota = nota_mandos(c)
	else:
		valor = 76.0 if _tipo() == "amperimetro" else 380.0
		var c := tarjeta_mandos()
		_lectura = fila_valor(c, "Corriente en la barra" if _tipo() == "amperimetro" else "Tensión entre fases")
		barra(c, 0.0, escala(), escala() / 50.0, valor, func(v: float) -> void:
			valor = v
			_actualizar())
		_nota = nota_mandos(c)
	_actualizar()


func _tipo() -> String:
	return str(params.get("tipo", "amperimetro"))


func escala() -> float:
	return 100.0 if _tipo() == "amperimetro" else 500.0


func poner_marcha(si: bool) -> void:
	en_marcha = si
	_interruptor.set_pressed_no_signal(si)
	_interruptor.queue_redraw()
	_actualizar()


func poner_60_hz(si: bool) -> void:
	de_60_hz = si
	_actualizar()


## Horas que cuenta por cada hora real de marcha.
func ritmo() -> float:
	return 50.0 / 60.0 if de_60_hz else 1.0


func _process(delta: float) -> void:
	super(delta)
	if _tipo() == "horometro" and en_marcha:
		horas += delta * HORAS_POR_SEGUNDO * ritmo()
		_actualizar()


## Aguja: 1 en cero, 3 midiendo. Horómetro: 1 parado, 2 contando y 3 si es de 60 Hz.
func fase() -> int:
	if _tipo() == "horometro":
		if not en_marcha:
			return 1
		return 3 if de_60_hz else 2
	return 3 if valor > 0.0 else 1


func _actualizar() -> void:
	if _nota == null:
		return
	if _tipo() == "horometro":
		_lectura.text = "%s h" % ("%.1f" % horas).replace(".", ",")
		_boton_60.text = "Poner uno de 50 Hz" if de_60_hz else "Poner uno de 60 Hz"
		if not en_marcha:
			_nota.text = "Parada: sin tensión en A1-A2, el contador no avanza."
		elif de_60_hz:
			_nota.text = "Horómetro de 60 Hz en la red de 50 Hz: su motor gira más despacio y cuenta 50 minutos por cada hora."
		else:
			_nota.text = "En marcha: el rodillo rojo de las décimas da una vuelta por hora. Aquí, acelerado."
		return
	if _tipo() == "amperimetro":
		_lectura.text = "%d A (%s A en la bobina)" % [roundi(valor), coma(valor / 20.0, 2)]
		_nota.text = "Por la bobina pasan los %s A del secundario del TI; la escala ya está en amperios de la barra." % coma(valor / 20.0, 2)
	else:
		_lectura.text = "%d V" % roundi(valor)
		_nota.text = "La bobina, con su resistencia en serie, toma unos %s mA: lo justo para mover la aguja." % coma(valor / 200.0, 1)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	if _tipo() == "horometro":
		_dibujar_horometro()
	else:
		_dibujar_aguja()
	lienzo.draw_set_transform(Vector2.ZERO)


func _dibujar_aguja() -> void:
	var l := lienzo
	texto(Vector2(200, 12), "APARATO DE HIERRO MÓVIL", 12, Color("5b6267"))
	var c := Vector2(130, 170)
	l.draw_style_box(Tema.caja(Color("2a2e32"), 6, 0, 0), Rect2(20, 30, 220, 220))
	l.draw_style_box(Tema.caja(Color("f4f5f2"), 3, 0, 0), Rect2(30, 40, 200, 200))
	var a0 := -PI * 0.8
	var a1 := -PI * 0.2
	l.draw_arc(c, 96.0, a0, a1, 32, Tema.TINTA, 2.0)
	for k in 11:
		var a := lerpf(a0, a1, k / 10.0)
		var largo := 12.0 if k % 5 == 0 else 7.0
		l.draw_line(c + Vector2(cos(a), sin(a)) * 96.0, c + Vector2(cos(a), sin(a)) * (96.0 - largo), Tema.TINTA, 2.0)
		if k % 5 == 0:
			texto(c + Vector2(cos(a), sin(a)) * 112.0, str(roundi(escala() * k / 10.0)), 10, Tema.TINTA)
	var angulo := lerpf(a0, a1, clampf(valor / escala(), 0.0, 1.0))
	l.draw_line(c, c + Vector2(cos(angulo), sin(angulo)) * 88.0, Color("c0392b"), 3.0)
	l.draw_circle(c, 7.0, Tema.TINTA)
	texto(c + Vector2(0, 40), "A" if _tipo() == "amperimetro" else "V", 20, Tema.TINTA)
	# Corte: bobina fija y las dos piezas de hierro.
	var b := Vector2(320, 140)
	l.draw_arc(b, 46.0, 0.0, TAU, 32, Color("c27a45"), 10.0)
	texto(b + Vector2(0, 70), "bobina fija", 11, Tema.TINTA)
	var giro := angulo - a0
	l.draw_rect(Rect2(b.x - 30, b.y - 6, 18, 12), Color("6c7276"))
	var movil := b + Vector2(cos(PI + giro), sin(PI + giro)) * 21.0
	l.draw_circle(movil, 8.0, Color("9aa1a6"))
	l.draw_line(b, movil, Tema.TINTA, 2.0)
	texto(b + Vector2(0, -62), "hierros que se repelen", 10, Tema.TINTA)
	if valor > 0.0:
		for k in 4:
			var a := TAU * (k / 4.0 + fmod(t * 0.5, 1.0))
			l.draw_circle(b + Vector2(cos(a), sin(a)) * 46.0, 3.0, Tema.ACENTO)


func _dibujar_horometro() -> void:
	var l := lienzo
	texto(Vector2(200, 12), "HORÓMETRO DE RODILLOS", 12, Color("5b6267"))
	l.draw_style_box(Tema.caja(Color("2a2e32"), 8, 0, 0), Rect2(70, 40, 260, 150))
	var digitos := ("%07.1f" % horas).replace(".", "")
	var decimas := fmod(horas * 10.0, 1.0)
	for i in digitos.length():
		var x := 92.0 + i * 32.0
		var rojo := i == digitos.length() - 1
		l.draw_rect(Rect2(x, 90, 28, 44), Color("c0392b") if rojo else Color("111417"))
		var desplaza := decimas * 44.0 if rojo else 0.0
		texto(Vector2(x + 14, 112 - desplaza), digitos[i], 22, Color.WHITE)
		if rojo:
			texto(Vector2(x + 14, 156 - desplaza), str((int(digitos[i]) + 1) % 10), 22, Color.WHITE)
	l.draw_rect(Rect2(70, 60, 260, 30), Color("2a2e32"))
	l.draw_rect(Rect2(70, 134, 260, 56), Color("2a2e32"))
	texto(Vector2(200, 72), "h", 14, Color.WHITE)
	texto(Vector2(200, 170), "%s · %s" % ["110 V", "60 Hz" if de_60_hz else "50 Hz"], 11, Color.WHITE)
	# Motor síncrono.
	var m := Vector2(200, 228)
	l.draw_circle(m, 18.0, Color("9aa1a6"))
	var giro := t * 4.0 * (ritmo() if en_marcha else 0.0)
	l.draw_line(m, m + Vector2(cos(giro), sin(giro)) * 15.0, Tema.TINTA, 3.0)
	texto(m + Vector2(80, 0), "motor síncrono", 11, Tema.TINTA)
	var rotulo := "PARADO" if not en_marcha else ("ATRASA: 60 Hz EN RED DE 50 Hz" if de_60_hz else "CONTANDO")
	rotulo_estado(Vector2(200, 264), rotulo, Color("5b6267") if not en_marcha else (Tema.FALLO if de_60_hz else Tema.ACIERTO))
