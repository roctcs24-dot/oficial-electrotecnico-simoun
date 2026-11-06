extends Animacion
## Práctica de las lecciones de generación con la simulación del cuadro principal.
## Escenario "sincronizar": G1 en barras con carga y G2 en marcha sin cerrar. Se ajusta la
## velocidad de G2 y se cierra Q2 mirando el sincronoscopio.
## Escenario "reparto": G1 y G2 en paralelo. Se ajustan la velocidad y la tensión de G2 y se
## ve cómo cambian los kW y los kVAr de cada grupo.

const PASO_VELOCIDAD_HZ := 0.1
const PASO_TENSION_V := 2.0
## El entrante empieza demasiado rápido: la aguja da una vuelta cada 3 s.
const DESLIZAMIENTO_INICIAL_HZ := 0.3
const PREPARACION_MAXIMA_S := 60.0
const ESCALA_KW := 500.0
const COLOR_KW := Color("1668c4")
const COLOR_KVAR := Color("c2a25a")

var sim: SimSimulacion
var _escenario := "sincronizar"
var _dial: DialSincronoscopio
var _boton_q2: Button
var _mensaje: Label
var _consecuencias := {}
var _eventos := 0
var _acumulado := 0.0


func preparar() -> void:
	_escenario = params.get("escenario", "sincronizar")
	_consecuencias = contenido.leer("cuadro.json").get("consecuencias", {})
	if _escenario == "sincronizar":
		lienzo.custom_minimum_size.y = 120.0
		_dial = DialSincronoscopio.new()
		add_child(_dial)
		move_child(_dial, 0)
	else:
		lienzo.custom_minimum_size.y = 230.0
	var mandos := GridContainer.new()
	mandos.columns = 2
	mandos.add_theme_constant_override("h_separation", 8)
	mandos.add_theme_constant_override("v_separation", 8)
	add_child(mandos)
	if _escenario == "reparto":
		mandos.add_child(_boton("Velocidad − G1", velocidad.bind(-1.0, "G1")))
		mandos.add_child(_boton("Velocidad + G1", velocidad.bind(1.0, "G1")))
	mandos.add_child(_boton("Velocidad − G2", velocidad.bind(-1.0)))
	mandos.add_child(_boton("Velocidad + G2", velocidad.bind(1.0)))
	if _escenario == "sincronizar":
		_boton_q2 = _boton("", alternar_q2)
		mandos.add_child(_boton_q2)
	else:
		mandos.add_child(_boton("Tensión − G2", tension.bind(-1.0)))
		mandos.add_child(_boton("Tensión + G2", tension.bind(1.0)))
	mandos.add_child(_boton("Reiniciar", reiniciar))
	_mensaje = Label.new()
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.theme_type_variation = "Nota"
	add_child(_mensaje)
	reiniciar()


func _boton(titulo: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = titulo
	b.custom_minimum_size.y = 48.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(accion)
	return b


func reiniciar() -> void:
	sim = contenido.circuito("cuadro_principal")
	var g1: SimGenerador = sim.componente("G1")
	var g2: SimGenerador = sim.componente("G2")
	g1.arrancar()
	sim.avanzar_tiempo(10.0)
	sim.componente("Q1").cerrar()
	# El gobernador de G1 trabaja con estatismo: se sube su consigna hasta dejar 60 Hz con carga.
	for _i in 3:
		sim.avanzar_tiempo(4.0)
		g1.ajustar_velocidad(SimGenerador.F_NOMINAL - g1.frecuencia())
	g2.arrancar()
	sim.avanzar_tiempo(10.0)
	# Sin carga, el rozamiento deja la velocidad algo por debajo de la consigna: se corrige sobre la medida.
	g2.ajustar_velocidad(g1.frecuencia() + DESLIZAMIENTO_INICIAL_HZ - g2.frecuencia())
	sim.avanzar_tiempo(4.0)
	if _escenario == "reparto":
		var pms: SimPMS = sim.componente("PMS")
		pms.sincronizar("G2")
		var limite := sim.tiempo + PREPARACION_MAXIMA_S
		while not sim.componente("Q2").cerrado() and sim.tiempo < limite:
			sim.paso()
		# Recién cerrado, G2 casi no lleva carga: el reparto queda para el alumno.
		g2.estado["f_ref"] = g2.frecuencia()
		sim.avanzar_tiempo(2.0)
	_eventos = sim.eventos.size()
	_mensaje.text = _instruccion()
	_actualizar_q2()


func _instruccion() -> String:
	if _escenario == "sincronizar":
		return "G2 gira demasiado rápido: la aguja da vueltas. Baje su velocidad hasta que gire despacio en sentido RÁPIDO y cierre Q2 justo antes de las doce."
	return "G2 acaba de entrar en paralelo y casi no lleva carga. Para pasarle kW sin cambiar la frecuencia, suba su velocidad y baje la de G1 el mismo número de toques. Su tensión le pasa kVAr."


func velocidad(signo: float, id := "G2") -> void:
	(sim.componente(id) as SimGenerador).ajustar_velocidad(signo * PASO_VELOCIDAD_HZ)


func tension(signo: float) -> void:
	(sim.componente("G2") as SimGenerador).ajustar_tension(signo * PASO_TENSION_V)


func alternar_q2() -> void:
	var q2: SimInterruptorGenerador = sim.componente("Q2")
	if q2.cerrado():
		q2.abrir()
	else:
		var motivo := q2.cerrar()
		if not motivo.is_empty():
			_mensaje.text = motivo
	_revisar_eventos()
	_actualizar_q2()


func _actualizar_q2() -> void:
	if _boton_q2 != null:
		_boton_q2.text = "Abrir Q2" if sim.componente("Q2").cerrado() else "Cerrar Q2"


func avanzar_pasos(pasos: int) -> void:
	for _i in pasos:
		sim.paso()
	_revisar_eventos()
	_actualizar_q2()


## El último evento con explicación sustituye a la instrucción.
func _revisar_eventos() -> void:
	for i in range(_eventos, sim.eventos.size()):
		var c: Dictionary = _consecuencias.get(sim.eventos[i]["tipo"], {})
		if not c.is_empty():
			_mensaje.text = "%s. %s" % [c["titulo"], c["texto"]]
	_eventos = sim.eventos.size()


func _process(delta: float) -> void:
	super(delta)
	if sim == null:
		return
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), 4)
	if pasos > 0:
		_acumulado = 0.0
		avanzar_pasos(pasos)
	if _dial != null:
		_actualizar_dial()


func _actualizar_dial() -> void:
	var sy: SimSincronoscopio = sim.componente("SY")
	var sol := sim.solucion
	var brillos: Array[float] = []
	var v_fase: float = 440.0 / sqrt(3.0)
	for fase in ["L1", "L2", "L3"]:
		brillos.append(sol.entre("G2.%s" % fase, "BP.%s" % fase).modulo() / (2.0 * v_fase))
	_dial.actualizar(sy.estado["angulo"], sy.estado["valido"] and not sim.componente("Q2").cerrado(), brillos)


func dibujar() -> void:
	fondo()
	if sim == null or sim.solucion == null:
		return
	if _escenario == "sincronizar":
		_dibujar_sincronismo()
	else:
		_dibujar_reparto()


func _dibujar_sincronismo() -> void:
	var g1: SimGenerador = sim.componente("G1")
	var g2: SimGenerador = sim.componente("G2")
	var sy: SimSincronoscopio = sim.componente("SY")
	var x := 16.0
	texto(Vector2(x, 22.0), "Barras %s Hz · G2 %s Hz · %s V" % [
		TextoTecnico.numero(g1.frecuencia(), 2), TextoTecnico.numero(g2.frecuencia(), 2),
		TextoTecnico.numero(g2.estado["v"], 0)], 15, Tema.TINTA, false)
	if sim.componente("Q2").cerrado():
		texto(Vector2(x, 52.0), "Q2 cerrado: G2 en paralelo con G1.", 15, Tema.TINTA, false)
	else:
		var desliz: float = sy.estado["deslizamiento_hz"]
		texto(Vector2(x, 52.0), "Ángulo %s° · deslizamiento %s Hz (%s)" % [
			TextoTecnico.numero(sy.estado["angulo"], 0), TextoTecnico.numero(absf(desliz), 2),
			"rápido" if desliz > 0.0 else "lento"], 15, Tema.TINTA, false)
		texto(Vector2(x, 82.0), "Diferencia de tensión %s %%" % TextoTecnico.numero(sy.estado["dv_pct"], 1), 15, Tema.TINTA, false)
	texto(Vector2(x, 106.0), "P: G1 %s kW · G2 %s kW" % [
		TextoTecnico.numero(g1.estado["p_kw"], 0), TextoTecnico.numero(g2.estado["p_kw"], 0)], 15, Tema.TINTA, false)


func _dibujar_reparto() -> void:
	var tam := lienzo.size
	var base := tam.y - 90.0
	var alto := base - 30.0
	var cero := Vector2(54.0, base)
	lienzo.draw_line(cero, Vector2(tam.x - 14.0, base), Color("8d989f"), 1.5)
	texto(Vector2(28.0, base - alto), TextoTecnico.numero(ESCALA_KW, 0), 12)
	texto(Vector2(28.0, base), "0", 12)
	var ancho := (tam.x - 80.0) / 2.0
	for i in 2:
		var id := "G%d" % (i + 1)
		var g: SimGenerador = sim.componente(id)
		var x0 := cero.x + 12.0 + i * ancho
		var barra := minf(ancho * 0.3, 60.0)
		_barra(Vector2(x0, base), barra, alto, g.estado["p_kw"], COLOR_KW)
		_barra(Vector2(x0 + barra + 8.0, base), barra, alto, g.estado["q_kvar"], COLOR_KVAR)
		texto(Vector2(x0 + barra + 4.0, base + 44.0), id, 15)
		texto(Vector2(x0 + barra + 4.0, base + 66.0), "%s kW · %s kVAr" % [
			TextoTecnico.numero(g.estado["p_kw"], 0), TextoTecnico.numero(g.estado["q_kvar"], 0)], 13)
	var g1: SimGenerador = sim.componente("G1")
	texto(Vector2(16.0, 14.0), "Barras %s Hz · %s V · azul kW, ocre kVAr" % [
		TextoTecnico.numero(g1.frecuencia(), 2), TextoTecnico.numero(sim.solucion.entre("BP.L1", "BP.L2").modulo(), 0)], 14, Tema.TINTA, false)


## Barra vertical desde la base. Los valores negativos, como la potencia inversa, bajan.
func _barra(base: Vector2, ancho: float, alto: float, valor: float, color: Color) -> void:
	var h := clampf(valor / ESCALA_KW, -0.2, 1.0) * alto
	var rect := Rect2(base.x, base.y - maxf(h, 0.0), ancho, absf(h))
	lienzo.draw_rect(rect, color if h >= 0.0 else Color("b03a2e"))
