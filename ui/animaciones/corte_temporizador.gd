extends Animacion
## Temporizador a la conexión o a la desconexión con el mismo funcionamiento que SimTemporizador:
## un cronograma muestra la tensión en A1-A2 y el contacto 15-18 en los últimos segundos, con el
## retardo contando. Se elige la función, el retardo y se da o se quita la tensión.

const ANCHO := 408.0
const ALTO := 300.0
const VENTANA_S := 20.0
const MUESTRA_S := 0.1

var modo := "on_delay"
var retardo := 5.0
var bobina := false
var conmutado := false
var cuenta := 0.0
var _historia: Array = []
var _acumulado := 0.0
var _interruptor: Interruptor
var _modo: Button
var _valor: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modo = str(params.get("modo", "on_delay"))
	retardo = float(params.get("retardo_s", 5.0))
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_tension)
	tarjeta_control("Tensión en A1-A2", "Toque para dar o quitar la orden", _interruptor)
	var c := tarjeta_mandos()
	_valor = fila_valor(c, "Retardo")
	barra(c, 1.0, 10.0, 0.5, retardo, func(v: float) -> void:
		retardo = v
		_actualizar())
	_modo = boton_mando(c, func() -> void: poner_modo("off_delay" if modo == "on_delay" else "on_delay"))
	_nota = nota_mandos(c)
	_actualizar()


func poner_tension(con: bool) -> void:
	_interruptor.set_pressed_no_signal(con)
	_interruptor.queue_redraw()
	if con != bobina:
		bobina = con
		cuenta = 0.0
	if modo == "on_delay" and not bobina:
		conmutado = false
	elif modo == "off_delay" and bobina:
		conmutado = true
	_actualizar()


func poner_modo(m: String) -> void:
	modo = m
	conmutado = bobina if modo == "off_delay" else false
	cuenta = 0.0
	_historia.clear()
	_actualizar()


## Igual que SimTemporizador.avanzar.
func avanzar(segundos: float) -> void:
	var resto := segundos
	while resto > 0.0:
		var dt := minf(resto, MUESTRA_S)
		resto -= dt
		var activa := bobina if modo == "on_delay" else not bobina
		if activa and cuenta < retardo:
			cuenta += dt
			if cuenta >= retardo:
				conmutado = modo == "on_delay"
				_actualizar()
		_acumulado += dt
		if _acumulado >= MUESTRA_S:
			_acumulado = 0.0
			_historia.append([bobina, conmutado])
			if _historia.size() > int(VENTANA_S / MUESTRA_S):
				_historia.pop_front()


## 1 sin orden, 2 contando el retardo, 3 conmutado.
func fase() -> int:
	var contando := (bobina if modo == "on_delay" else not bobina) and cuenta < retardo and conmutado != (modo == "on_delay")
	if contando:
		return 2
	return 3 if conmutado else 1


func _process(delta: float) -> void:
	avanzar(delta)
	super(delta)


func _actualizar() -> void:
	if _valor == null:
		return
	_valor.text = "%s s" % coma(retardo)
	_modo.text = "Cambiar a la desconexión" if modo == "on_delay" else "Cambiar a la conexión"
	if modo == "on_delay":
		_nota.text = "A la conexión: con tensión en A1-A2 cuenta el retardo y después cierra 15-18. Al quitar la tensión vuelve al instante."
	else:
		_nota.text = "A la desconexión: con tensión cierra 15-18 al instante; al quitarla cuenta el retardo y después abre."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 12), "TEMPORIZADOR %s" % ("A LA CONEXIÓN" if modo == "on_delay" else "A LA DESCONEXIÓN"), 12, Color("5b6267"))
	# Cronograma: dos señales, de izquierda (hace 20 s) a derecha (ahora).
	var x0 := 70.0
	var x1 := 390.0
	var filas := [["A1-A2", 70.0, 0], ["15-18", 150.0, 1]]
	for f in filas:
		var y: float = f[1]
		texto(Vector2(36, y - 12), f[0], 12, Tema.TINTA)
		l.draw_line(Vector2(x0, y), Vector2(x1, y), Color("b8bec2"), 1.0)
		var puntos := PackedVector2Array()
		var n := _historia.size()
		var paso := (x1 - x0) / (VENTANA_S / MUESTRA_S)
		for i in n:
			var x := x1 - (n - 1 - i) * paso
			var alto: bool = _historia[i][f[2]]
			var yy := y - 30.0 if alto else y
			if i > 0 and bool(_historia[i - 1][f[2]]) != alto:
				puntos.append(Vector2(x, y - 30.0 if not alto else y))
			puntos.append(Vector2(x, yy))
		if puntos.size() > 1:
			l.draw_polyline(puntos, Color("2f6fb5") if f[2] == 0 else Color("c26a1a"), 3.0)
	texto(Vector2(x0, 172), "hace 20 s", 10, Color("5b6267"), false)
	texto_derecha(Vector2(x1, 172), "ahora", 10)
	# Reloj del retardo.
	var c := Vector2(120, 236)
	l.draw_circle(c, 34.0, Color("2b2f32"))
	var frac := clampf(cuenta / retardo, 0.0, 1.0)
	if frac > 0.0:
		l.draw_arc(c, 28.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 32, Color("ffcf4a"), 6.0, true)
	texto(c, "%s s" % coma(minf(cuenta, retardo)), 13, Color.WHITE)
	texto(Vector2(120, 282), "cuenta del retardo", 10, Tema.TINTA)
	# Contacto conmutado 15-16-18.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(232, 196, 166, 70))
	var o := Vector2(244, 240)
	l.draw_line(o, o + Vector2(28, 0), Tema.TINTA, 3.0)
	l.draw_line(o + Vector2(58, -12), o + Vector2(100, -12), Tema.TINTA, 3.0)
	l.draw_line(o + Vector2(58, 8), o + Vector2(100, 8), Tema.TINTA, 3.0)
	l.draw_line(o + Vector2(28, 0), o + (Vector2(60, 8) if conmutado else Vector2(60, -12)), Tema.TINTA, 3.0, true)
	texto(o + Vector2(-2, 14), "15", 10, Tema.TINTA)
	texto(o + Vector2(114, -12), "16", 10, Tema.TINTA)
	texto(o + Vector2(114, 8), "18", 10, Tema.TINTA)
	texto(Vector2(240, 210), "15-18 cerrado" if conmutado else "15-16 cerrado", 11, Tema.ACIERTO if conmutado else Tema.TINTA, false)
	l.draw_set_transform(Vector2.ZERO)
