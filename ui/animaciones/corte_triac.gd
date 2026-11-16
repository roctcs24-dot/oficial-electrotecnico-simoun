extends Animacion
## Triac con una resistencia de 230 V, a cámara lenta (un ciclo cada 2 s). Mientras hay corriente de
## puerta conduce los dos semiciclos; al quitarla, sigue hasta el siguiente paso por cero y se
## apaga ahí. La onda muestra en color lo que llega a la carga.

const ANCHO := 400.0
const ALTO := 260.0
const PERIODO_S := 2.0
const MUESTRAS := 120

var puerta := false
var conduce := false
var fase_onda := 0.0
## Lo que ha llegado a la carga en el último ciclo: true donde conducía.
var _historia: Array[bool] = []
var _interruptor: Interruptor
var _estado: Label
var _nota: Label


func preparar() -> void:
	for _i in MUESTRAS:
		_historia.append(false)
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_puerta)
	tarjeta_control("Corriente de puerta (S1)", "Toque para darla o quitarla", _interruptor)
	var c := tarjeta_mandos()
	_estado = fila_valor(c, "Triac / carga")
	_nota = nota_mandos(c)
	_actualizar()


func poner_puerta(si: bool) -> void:
	puerta = si
	if si:
		conduce = true
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(si)
		_interruptor.queue_redraw()
	_actualizar()


## Avanza la onda; sin puerta, el triac se apaga al pasar por cero.
func avanzar(dt: float) -> void:
	var antes := fase_onda
	fase_onda = fmod(fase_onda + dt / PERIODO_S, 1.0)
	var cruza := int(floor(antes * 2.0)) != int(floor((antes + dt / PERIODO_S) * 2.0))
	if cruza and not puerta:
		conduce = false
	var k := int(fase_onda * MUESTRAS) % MUESTRAS
	_historia[k] = conduce
	_actualizar()


## 1 bloqueando; 2 conduciendo con puerta; 3 sin puerta, esperando el paso por cero.
func fase() -> int:
	if not conduce:
		return 1
	return 2 if puerta else 3


func _process(delta: float) -> void:
	avanzar(delta)
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_estado.text = "conduce · 230 V" if conduce else "bloquea · 0 V"
	match fase():
		1:
			_nota.text = "Sin corriente de puerta, el triac bloquea: la resistencia no recibe tensión."
		2:
			_nota.text = "Con unos miliamperios de puerta conduce en los dos semiciclos: la carga recibe la alterna entera."
		3:
			_nota.text = "Sin puerta, sigue conduciendo hasta que la corriente pasa por cero; ahí se apaga."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "TRIAC EN ALTERNA (A CÁMARA LENTA)", 12, Color("5b6267"))
	var marco := Rect2(30, 30, 340, 120)
	l.draw_rect(marco, Color.WHITE)
	l.draw_rect(marco, Color("8a949b"), false, 1.5)
	var medio := marco.position.y + marco.size.y / 2.0
	l.draw_line(Vector2(marco.position.x, medio), Vector2(marco.end.x, medio), Color("cfd3d6"), 1.0)
	var red := PackedVector2Array()
	for k in MUESTRAS + 1:
		var f := float(k) / MUESTRAS
		red.append(Vector2(marco.position.x + f * marco.size.x, medio - sin(f * TAU) * marco.size.y * 0.42))
	l.draw_polyline(red, Color("9db8d6"), 2.0, true)
	for k in MUESTRAS:
		if _historia[k]:
			var f0 := float(k) / MUESTRAS
			var f1 := float(k + 1) / MUESTRAS
			l.draw_line(Vector2(marco.position.x + f0 * marco.size.x, medio - sin(f0 * TAU) * marco.size.y * 0.42),
				Vector2(marco.position.x + f1 * marco.size.x, medio - sin(f1 * TAU) * marco.size.y * 0.42), Color("c0392b"), 3.5)
	var x := marco.position.x + fase_onda * marco.size.x
	l.draw_line(Vector2(x, marco.position.y), Vector2(x, marco.end.y), Color(0.2, 0.2, 0.2, 0.4), 1.5)
	texto(Vector2(200, 164), "azul: la red · rojo: lo que llega a la carga", 10, Color("5b6267"))
	# Triac y carga.
	var tinta := Tema.TINTA
	var color := Tema.ACENTO_FUERTE if conduce else tinta
	l.draw_line(Vector2(60, 200), Vector2(140, 200), tinta, 3.0)
	l.draw_rect(Rect2(140, 190, 60, 20), Color("ffb08a") if conduce else Color.WHITE)
	l.draw_rect(Rect2(140, 190, 60, 20), tinta, false, 2.0)
	texto(Vector2(170, 224), "RL 230 W", 10, tinta)
	l.draw_line(Vector2(200, 200), Vector2(250, 200), tinta, 3.0)
	l.draw_colored_polygon(PackedVector2Array([Vector2(250, 188), Vector2(250, 200), Vector2(270, 194)]), color)
	l.draw_colored_polygon(PackedVector2Array([Vector2(270, 200), Vector2(270, 212), Vector2(250, 206)]), color)
	l.draw_line(Vector2(250, 186), Vector2(250, 214), tinta, 2.5)
	l.draw_line(Vector2(270, 186), Vector2(270, 214), tinta, 2.5)
	l.draw_line(Vector2(270, 212), Vector2(286, 230), Tema.ACENTO_FUERTE if puerta else tinta, 2.5)
	l.draw_line(Vector2(270, 200), Vector2(340, 200), tinta, 3.0)
	texto(Vector2(260, 172), "V1", 11, tinta)
	texto(Vector2(300, 236), "G", 10, tinta)
	rotulo_estado(Vector2(80, 236), ["", "BLOQUEA", "CONDUCE", "HASTA EL CERO"][fase()], Color("5b6267") if not conduce else Tema.ACIERTO)
	l.draw_set_transform(Vector2.ZERO)
