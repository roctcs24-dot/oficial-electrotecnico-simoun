extends Animacion
## Variador de frecuencia por dentro: rectificador, bus de continua y ondulador de IGBT hasta el
## motor. Se da la marcha y se elige la consigna; la frecuencia sube en rampa y la tensión la
## sigue en proporción (V/f). Corrientes de una bomba de 15 kW como las de la simulación
## (variador_servicio): 24 A en el motor a 50 Hz y 12,8 A a 25 Hz.

const ANCHO := 420.0
const ALTO := 300.0
const RED_V := 380.0
const F_NOMINAL := 50.0
const RPM_NOMINAL := 1460.0
## Hz por segundo de la rampa de la animación (de 0 a 50 Hz en 5 s).
const RAMPA := 10.0

var marcha := false
var consigna := 50.0
var f := 0.0
var _interruptor: Interruptor
var _f: Label
var _v: Label
var _i: Label
var _rpm: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_marcha)
	tarjeta_control("Marcha (DI1)", "Toque para arrancar o parar en rampa", _interruptor)
	var c := tarjeta_mandos()
	var consigna_texto := fila_valor(c, "Consigna")
	consigna_texto.text = "%d Hz" % roundi(consigna)
	barra(c, 10.0, 50.0, 5.0, consigna, func(v: float) -> void:
		consigna = v
		consigna_texto.text = "%d Hz" % roundi(v))
	_f = fila_valor(c, "Salida")
	_v = fila_valor(c, "Corriente motor / red")
	_rpm = fila_valor(c, "Velocidad")
	_i = fila_valor(c, "Bus de continua")
	_nota = nota_mandos(c)
	_actualizar()


func poner_marcha(si: bool) -> void:
	marcha = si
	_interruptor.set_pressed_no_signal(si)
	_interruptor.queue_redraw()
	_actualizar()


func _process(delta: float) -> void:
	super(delta)
	avanzar(delta)


func avanzar(delta: float) -> void:
	var objetivo := consigna if marcha else 0.0
	var antes := f
	f = move_toward(f, objetivo, RAMPA * delta)
	if f != antes:
		_actualizar()


func tension_salida() -> float:
	return RED_V * minf(f / F_NOMINAL, 1.0)


func rpm() -> float:
	return RPM_NOMINAL * f / F_NOMINAL


func corriente_motor() -> float:
	return 0.0 if f <= 0.0 else 9.5 + 14.5 * pow(f / F_NOMINAL, 2.4)


func corriente_red() -> float:
	return 0.3 + 20.7 * pow(f / F_NOMINAL, 2.7) if f > 0.0 else 0.3


func bus() -> float:
	return 1.35 * RED_V


## 1 parado con el bus cargado, 2 en rampa, 3 a la consigna.
func fase() -> int:
	if f <= 0.0:
		return 1
	return 3 if is_equal_approx(f, consigna) else 2


func _actualizar() -> void:
	if _nota == null:
		return
	_f.text = "%s Hz · %d V" % [coma(f), roundi(tension_salida())]
	_v.text = "%s / %s A" % [coma(corriente_motor()), coma(corriente_red())]
	_rpm.text = "%d rpm" % roundi(rpm())
	_i.text = "%d V=" % roundi(bus())
	match fase():
		1:
			_nota.text = "Parado: el bus está cargado a %d V aunque el motor no gire. Al abrir el equipo, espere a que baje." % roundi(bus())
		2:
			_nota.text = "En rampa: la frecuencia y la tensión suben juntas, sin pico de corriente."
		_:
			_nota.text = "A %d Hz el motor gira a %d rpm. La red da menos corriente que el motor: la potencia de una bomba baja mucho con la velocidad." % [roundi(f), roundi(rpm())]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(210, 12), "VARIADOR DE FRECUENCIA POR DENTRO", 12, Color("5b6267"))
	var cajas := [["Red", "380 V 50 Hz", 10.0], ["Rectificador", "diodos", 92.0], ["Bus", "%d V=" % roundi(bus()), 174.0], ["Ondulador", "IGBT", 256.0]]
	for i in cajas.size():
		var x: float = cajas[i][2]
		var activo := i <= 2 or f > 0.0
		l.draw_style_box(Tema.caja(Color("e9ebe7") if activo else Color("d4d7d4"), 6, 0, 0, Color("5b6267")), Rect2(x, 40, 72, 56))
		texto(Vector2(x + 36, 58), cajas[i][0], 11, Tema.TINTA)
		texto(Vector2(x + 36, 78), cajas[i][1], 10, Color("3b444b"))
		if i < cajas.size() - 1:
			flecha(Vector2(x + 72, 68), Vector2(x + 82, 68), Color("c0392b") if i < 2 or f > 0.0 else Color("8a949b"), 2.5)
	flecha(Vector2(328, 68), Vector2(338, 68), Color("c0392b") if f > 0.0 else Color("8a949b"), 2.5)
	# Motor con su eje girando.
	var m := Vector2(372, 68)
	l.draw_circle(m, 26.0, Color("6c7276"))
	l.draw_circle(m, 22.0, Color("9aa1a6"))
	var giro := t * rpm() / 60.0 * TAU * 0.05
	for k in 3:
		var a := giro + TAU * k / 3.0
		l.draw_line(m, m + Vector2(cos(a), sin(a)) * 18.0, Tema.TINTA, 3.0)
	texto(Vector2(372, 106), "%d rpm" % roundi(rpm()), 10, Tema.TINTA)
	# Ondas: el bus y los pulsos del ondulador con su fundamental.
	var origen := Vector2(30, 200)
	l.draw_line(origen, origen + Vector2(360, 0), Color("8a949b"), 1.0)
	texto(Vector2(30, 140), "Salida U-V: pulsos PWM y su onda fundamental", 11, Tema.TINTA, false)
	var ciclos := f / F_NOMINAL * 3.0
	var amplitud := 46.0 * minf(f / F_NOMINAL, 1.0)
	if f > 0.0:
		var anterior := origen
		for k in 121:
			var x := k * 3.0
			var y := sin(x / 360.0 * TAU * ciclos - t * 2.0) * amplitud
			var signo := 1.0 if y >= 0.0 else -1.0
			if k % 3 == 0 and absf(y) > 2.0:
				l.draw_rect(Rect2(origen.x + x, origen.y - (46.0 if signo > 0 else 0.0), 2.0 + absf(y) / 46.0 * 4.0, 46.0), Color(0.75, 0.22, 0.17, 0.25))
			var punto := origen + Vector2(x, -y)
			if k > 0:
				l.draw_line(anterior, punto, Color("c0392b"), 2.5)
			anterior = punto
	else:
		texto(origen + Vector2(180, -14), "Sin salida: los IGBT están bloqueados", 11, Color("5b6267"))
	var rotulo := "PARADO · BUS CARGADO" if fase() == 1 else ("RAMPA %s Hz" % coma(f) if fase() == 2 else "RUN %d Hz" % roundi(f))
	rotulo_estado(Vector2(210, 278), rotulo, Color("5b6267") if fase() == 1 else (Tema.ACENTO_FUERTE if fase() == 2 else Tema.ACIERTO))
	l.draw_set_transform(Vector2.ZERO)
