extends Animacion
## Corte de una bomba hidráulica de cilindrada fija: de engranajes (los dientes llevan el aceite
## por fuera, de la aspiración a la impulsión) o de pistones axiales (el plato inclinado hace
## subir y bajar los pistones del barrilete que gira). El caudal es cilindrada × rpm; la fuga
## interna crece con la presión y con el desgaste (SimHidraulica). La bomba da caudal, no
## presión: la presión la pone lo que se opone al aceite.
## Parámetros: "tipo" ("engranajes" o "pistones"), "cilindrada" (cm³/rev).

const ANCHO := 440.0
const ALTO := 210.0

var tipo := "engranajes"
var cilindrada := 20.0
var rpm := 1450.0
var presion := 0.0
var gastada := false
## Inclinación del plato, 0 a 1 (solo pistones): la cilindrada efectiva.
var plato := 1.0
var _giro := 0.0
var _avance := 0.0
var _teorico: Label
var _real: Label
var _rendimiento: Label
var _boton: Button


func preparar() -> void:
	tipo = str(params.get("tipo", tipo))
	cilindrada = float(params.get("cilindrada", 20.0 if tipo == "engranajes" else 45.0))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var v := fila_valor(c, "Velocidad del motor")
	barra(c, 0.0, 1800.0, 50.0, rpm, func(x: float) -> void:
		rpm = x
		v.text = "%d rpm" % roundi(x)
		_actualizar())
	v.text = "%d rpm" % roundi(rpm)
	var p := fila_valor(c, "Presión que pide el circuito")
	barra(c, 0.0, 200.0, 5.0, presion, func(x: float) -> void:
		presion = x
		p.text = "%d bar" % roundi(x)
		_actualizar())
	p.text = "%d bar" % roundi(presion)
	if tipo == "pistones":
		var a := fila_valor(c, "Inclinación del plato")
		barra(c, 0.0, 100.0, 5.0, plato * 100.0, func(x: float) -> void:
			plato = x / 100.0
			a.text = "%d %%" % roundi(x)
			_actualizar())
		a.text = "%d %%" % roundi(plato * 100.0)
	_teorico = fila_valor(c, "Caudal teórico")
	_real = fila_valor(c, "Caudal real")
	_rendimiento = fila_valor(c, "Rendimiento volumétrico")
	_boton = boton_mando(c, func() -> void:
		gastada = not gastada
		_actualizar())
	_actualizar()


func modelo() -> Dictionary:
	return {"motor": {"rpm": rpm}, "bomba": {"cilindrada": cilindrada * (plato if tipo == "pistones" else 1.0), "desgaste": 0.8 if gastada else 0.0}}


func caudal_real() -> float:
	return SimHidraulica.caudal_bomba(SimHidraulica.completar(modelo()), presion)


func _actualizar() -> void:
	if _teorico == null:
		return
	var p := SimHidraulica.completar(modelo())
	var teorico := SimHidraulica.caudal_teorico(p)
	var real := caudal_real()
	_teorico.text = "%s L/min" % coma(teorico, 1)
	_real.text = "%s L/min" % coma(real, 1)
	_rendimiento.text = "%d %%" % roundi(100.0 * real / teorico) if teorico > 0.0 else "—"
	_boton.text = "Bomba nueva" if gastada else "Bomba gastada (holguras abiertas)"


func fase() -> int:
	if rpm <= 0.0:
		return 1
	return 3 if presion >= 100.0 else 2


func _process(delta: float) -> void:
	_giro += rpm / 60.0 * TAU * delta * 0.08
	_avance += caudal_real() * delta * 2.0
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoHidraulico.FONDO)
	var hay := rpm > 0.0
	# Aspiración desde el tanque (izquierda) e impulsión (derecha).
	DibujoHidraulico.tanque(l, fuente, Rect2(14, 150, 118, 46))
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(70, 150), Vector2(70, 104), Vector2(150, 104)]), "retorno" if hay else "", _avance, 12.0)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(290, 104), Vector2(400, 104), Vector2(400, 60)]), ("presion" if presion > 0.0 else "trabajo") if hay else "", _avance, 9.0)
	DibujoHidraulico.manometro(l, fuente, Vector2(400, 36), 22.0, presion if hay else 0.0, 250.0)
	if tipo == "pistones":
		_pistones(l)
	else:
		_engranajes(l)
	DibujoHidraulico.rotulo(l, fuente, Vector2(110, 84), "ASPIRACIÓN", 10, Color("8fbcf0"))
	DibujoHidraulico.rotulo(l, fuente, Vector2(332, 84), "IMPULSIÓN", 10, Color("ff9a7a"))
	if gastada and hay and presion >= 100.0:
		DibujoHidraulico.rotulo(l, fuente, Vector2(220, 196), "FUGA INTERNA: EL CAUDAL CAE CON LA PRESIÓN", 10, Color("ff7a5a"))


func _engranajes(l: Control) -> void:
	var c := Vector2(220, 104)
	DibujoHidraulico.bomba(l, c, _giro, 1.9)
	# Bolsas de aceite que viajan por fuera de los piñones.
	if rpm > 0.0:
		for lado in [-1, 1]:
			var centro := c + Vector2(19.0 * lado, 0)
			for k in 3:
				var a: float = fposmod(_giro * 0.5 + k * TAU / 3.0, PI)
				var ang: float = (PI / 2.0 + a) if lado < 0 else (PI / 2.0 - a)
				l.draw_circle(centro + Vector2.from_angle(ang) * 24.0, 3.2, DibujoHidraulico.ACEITE)
	if gastada:
		l.draw_arc(c, 54.0, -0.6, 0.6, 10, Color("ff7a5a"), 2.0, true)


func _pistones(l: Control) -> void:
	# Vista lateral: eje, plato inclinado y barrilete con cinco pistones visibles.
	var izquierda := 150.0
	var derecha := 290.0
	var arriba := 58.0
	var abajo := 150.0
	DibujoHidraulico.pieza(l, Rect2(izquierda, arriba, derecha - izquierda, abajo - arriba), 10.0)
	DibujoAri.relleno(l, Rect2(izquierda + 6, arriba + 6, derecha - izquierda - 12, abajo - arriba - 12), 6.0, Color("2a2f33"))
	var inclinacion := 0.45 * plato
	var cx := izquierda + 34.0
	var cy := (arriba + abajo) / 2.0
	var mitad := (abajo - arriba) / 2.0 - 10.0
	# Plato inclinado.
	var d := Vector2(sin(inclinacion), cos(inclinacion)) * mitad
	l.draw_line(Vector2(cx, cy) - d, Vector2(cx, cy) + d, Color("c9d1d6"), 8.0, true)
	l.draw_line(Vector2(izquierda - 40, cy), Vector2(cx, cy), Color("dfe5e9"), 8.0, true)
	# Pistones: el recorrido de cada uno depende de su posición en el giro.
	for k in 5:
		var fase_k := _giro + k * TAU / 5.0
		var y := cy + sin(fase_k) * mitad * 0.85
		var x_plato := cx + (y - cy) * tan(inclinacion)
		var visible := cos(fase_k) > -0.2
		if not visible:
			continue
		var cuerpo := Rect2(x_plato + 6.0, y - 5.0, 48.0, 10.0)
		DibujoAri.pieza(l, cuerpo, 3.0, DibujoHidraulico.ACERO, [], DibujoHidraulico.CONTORNO, Color(1, 1, 1, 0.5), 0.0)
		# Cámara de aceite delante de cada pistón.
		var camara := Rect2(cuerpo.end.x, y - 5.0, derecha - 34.0 - cuerpo.end.x, 10.0)
		if camara.size.x > 0.0:
			l.draw_rect(camara, Color(DibujoHidraulico.ACEITE, 0.85))
	# Placa de distribución con sus dos riñones.
	DibujoAri.relleno(l, Rect2(derecha - 32, arriba + 8, 10, abajo - arriba - 16), 2.0, Color("97a2a9"))
	texto(Vector2((izquierda + derecha) / 2.0, abajo + 14.0), "Plato inclinado %d %%" % roundi(plato * 100.0), 11, Color("cfd8df"))
