extends Animacion
## Corte de un diferencial de 2 polos sobre la simulación: la fase y el neutro atraviesan el
## transformador toroidal; si una parte de la corriente se va a tierra por una fuga, la suma deja
## de ser cero, la bobina del toroide da señal y el relé abre los dos polos. Se elige la fuga, si
## el secundario está unido a tierra (TN) o aislado (IT, como la red del buque) y el botón T.
## Usa los circuitos diferencial_fuga y diferencial_fuga_aislada y SimDiferencial.

const ANCHO := 408.0
const ALTO := 330.0
const FASE := Color("8a4b1c")
const NEUTRO := Color("2f6fb5")
const FUGA := Color("e8462e")
const V_TOMA := 230.0

var fuga_ma := 12.0
var con_tierra := true
var sim: SimSimulacion
var _acumulado := 0.0
var _valor: Label
var _nota: Label
var _maneta: Button
var _tierra: Interruptor


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fuga_ma = float(params.get("fuga_ma", 12.0))
	_tierra = Interruptor.new()
	_tierra.button_pressed = con_tierra
	_tierra.toggled.connect(poner_tierra)
	tarjeta_control("Secundario unido a tierra", "Apáguelo para ver la red aislada del buque", _tierra)
	var c := tarjeta_mandos()
	_valor = fila_valor(c, "Fuga a tierra")
	barra(c, 0.0, 60.0, 1.0, fuga_ma, poner_fuga)
	_nota = nota_mandos(c)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	boton_mando(fila, probar).text = "Pulsar T (prueba)"
	_maneta = boton_mando(fila, func() -> void: accionar(not cerrado()))
	_montar()


func _montar() -> void:
	sim = contenido.circuito("diferencial_fuga" if con_tierra else "diferencial_fuga_aislada")
	_aplicar_fuga()
	sim.paso()
	_actualizar_textos()


func _diferencial() -> SimDiferencial:
	return sim.componente("ID")


func cerrado() -> bool:
	return _diferencial().cerrado()


func disparado() -> bool:
	return _diferencial().estado["disparado"]


func residual_ma() -> float:
	return float(_diferencial().estado["residual_a"]) * 1000.0


func _aplicar_fuga() -> void:
	var c: SimConsumidor = sim.componente("C1")
	c.params["fuga_ohm"] = V_TOMA / (fuga_ma / 1000.0) if fuga_ma > 0.0 else 1e12


func poner_fuga(v: float) -> void:
	fuga_ma = v
	_aplicar_fuga()
	_actualizar_textos()


func poner_tierra(con: bool) -> void:
	var estaba := _diferencial().estado.duplicate()
	con_tierra = con
	_interruptor_sin_senal(con)
	_montar()
	_diferencial().estado.merge(estaba, true)
	_actualizar_textos()


func _interruptor_sin_senal(con: bool) -> void:
	_tierra.set_pressed_no_signal(con)
	_tierra.queue_redraw()


func accionar(subir: bool) -> void:
	_diferencial().accionar(subir)
	sim.paso()
	_actualizar_textos()


## El botón T se pulsa un instante: la fuga interna dispara un diferencial sano.
func probar() -> void:
	_diferencial().pulsar_prueba(true)
	sim.paso()
	_diferencial().pulsar_prueba(false)
	_actualizar_textos()


func avanzar(segundos: float) -> void:
	sim.avanzar_tiempo(segundos)
	_actualizar_textos()


## 1 sin fuga, 2 con fuga por debajo de IΔn, 3 disparado.
func fase() -> int:
	if disparado():
		return 3
	return 2 if fuga_ma >= 1.0 else 1


func _process(delta: float) -> void:
	_acumulado += delta
	if _acumulado >= SimSimulacion.PASO_S:
		_acumulado = 0.0
		var antes := disparado()
		sim.paso()
		if disparado() != antes:
			_actualizar_textos()
	super(delta)


func _actualizar_textos() -> void:
	if _valor == null:
		return
	_valor.text = "%s mA · IΔn 30 mA" % coma(fuga_ma, 0)
	_maneta.text = "Bajar la maneta" if cerrado() else ("Rearmar: bajar la maneta" if disparado() else "Subir la maneta")
	if disparado():
		_nota.text = "Disparado: los dos polos abrieron. Busque la fuga antes de volver a subir la maneta."
	elif not con_tierra:
		_nota.text = "Red aislada: la fuga no tiene por dónde volver al transformador. No circula corriente y el diferencial no la ve; aquí avisa el monitor de aislamiento."
	elif fuga_ma > 30.0:
		_nota.text = "Más de 30 mA de fuga: dispara en menos de 300 ms."
	else:
		_nota.text = "Por debajo de 30 mA no dispara, aunque la fuga existe. Pulse T para probarlo."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 12), "CORTE DEL DIFERENCIAL Y SU CIRCUITO", 12, Color("5b6267"))
	var abierto := not cerrado()
	var r := residual_ma()
	# Conductores: fase por x = 110 y neutro por x = 150.
	texto(Vector2(110, 30), "1 · L", 12, Tema.TINTA)
	texto(Vector2(150, 30), "3 · N", 12, Tema.TINTA)
	for par in [[110.0, FASE], [150.0, NEUTRO]]:
		var x: float = par[0]
		l.draw_line(Vector2(x, 40), Vector2(x, 64), par[1], 5.0)
		var pivote := Vector2(x, 100)
		var angulo := 0.5 if abierto else 0.0
		l.draw_line(pivote, pivote + Vector2(sin(angulo), -cos(angulo)) * 34.0, par[1], 5.0, true)
		l.draw_line(pivote, Vector2(x, 236), par[1], 5.0)
	# Transformador toroidal: un anillo por el que pasan los dos conductores.
	l.draw_arc(Vector2(130, 150), 40.0, 0.0, TAU, 40, Color("3b444b"), 10.0, true)
	var senal := clampf(r / 30.0, 0.0, 1.5)
	if senal > 0.03 and not abierto:
		l.draw_arc(Vector2(130, 150), 40.0, 0.0, TAU, 40, Color(FUGA, minf(senal, 1.0) * 0.7), 5.0, true)
	texto(Vector2(52, 150), "Toroide", 11, Tema.TINTA)
	# Bobina del toroide al relé de disparo.
	for j in 4:
		l.draw_arc(Vector2(176 + j * 7, 150), 6.0, PI, TAU, 8, Color("b26a1e"), 3.0, true)
	l.draw_line(Vector2(204, 150), Vector2(236, 150), Color("b26a1e"), 2.5)
	l.draw_style_box(Tema.caja(Color("c0392b") if disparado() else Color("8a949b"), 4, 0, 0, Color("3b444b")), Rect2(236, 126, 60, 48))
	texto(Vector2(266, 186), "Relé de disparo", 11, Tema.TINTA)
	_discontinua(Vector2(266, 126), Vector2(150, 84))
	# Consumidor y fuga.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 6, 0, 0, Color("5b6267")), Rect2(92, 236, 76, 36))
	texto(Vector2(130, 254), "Toma 230 V", 11, Tema.TINTA)
	var flujo := 0.0 if abierto else 1.0
	if fuga_ma > 0.5:
		var punto := Vector2(110, 210)
		var tierra := Vector2(40, 300)
		var camino := PackedVector2Array([punto, Vector2(40, 210), tierra])
		var color := Color(FUGA, 0.35 + 0.65 * flujo * (1.0 if con_tierra else 0.25))
		l.draw_polyline(camino, color, 3.0)
		l.draw_rect(Rect2(32, 230, 16, 34), Color("f1f2f0"))
		l.draw_rect(Rect2(32, 230, 16, 34), color, false, 2.0)
		texto(Vector2(16, 247), "fuga", 10, Tema.TINTA, false)
	# Tierra y, si existe, el camino de vuelta al transformador.
	for k in 3:
		l.draw_line(Vector2(24 + k * 5, 300 + k * 5), Vector2(56 - k * 5, 300 + k * 5), Tema.TINTA, 2.0)
	if con_tierra:
		l.draw_polyline(PackedVector2Array([Vector2(40, 300), Vector2(40, 318), Vector2(200, 318)]), Color("2f6f4a"), 2.5)
		texto(Vector2(204, 318), "vuelve por la tierra del secundario", 10, Color("2f6f4a"), false)
	else:
		texto(Vector2(64, 318), "red aislada: sin camino de vuelta", 10, Tema.FALLO, false)
	# Lecturas.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(256, 30, 142, 82))
	texto(Vector2(266, 48), "L − N en el toroide", 11, Tema.TINTA, false)
	texto(Vector2(266, 74), "%s mA" % coma(r, 1), 20, Tema.FALLO if r > 30.0 else Tema.TINTA, false)
	texto(Vector2(266, 98), "dispara con más de 30", 10, Color("5b6267"), false)
	var rotulo := "DISPARADO" if disparado() else ("EN SERVICIO" if cerrado() else "ABIERTO")
	rotulo_estado(Vector2(327, 222), rotulo, Color("c0392b") if disparado() else (Tema.ACIERTO if cerrado() else Color("5b6267")))
	l.draw_circle(Vector2(327, 262), 14.0, Color("e9c63a"))
	texto(Vector2(327, 262), "T", 13, Tema.TINTA)
	l.draw_set_transform(Vector2.ZERO)


func _discontinua(a: Vector2, b: Vector2) -> void:
	var largo := a.distance_to(b)
	var s := 0.0
	while s < largo:
		lienzo.draw_line(a.lerp(b, s / largo), a.lerp(b, minf(s + 6.0, largo) / largo), Color("5b6267"), 2.0)
		s += 11.0
