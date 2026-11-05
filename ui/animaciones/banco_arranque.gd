extends Animacion
## Banco de arranque con una plantilla de data/circuitos: se maniobra Q1, S1 y S0, y se
## registra la corriente de línea para ver el pico de arranque.

const DURACION_GRAFICA_S := 20.0
const MUESTRAS := 400
const AMARILLO := Color("c2a25a")

var sim: SimSimulacion
var _muestras := PackedFloat32Array()
var _acumulado := 0.0
var _boton_q1: Button
var _maximo := 0.0


func preparar() -> void:
	lienzo.custom_minimum_size.y = 240.0
	_crear_circuito()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	add_child(fila)
	_boton_q1 = Button.new()
	_boton_q1.mouse_filter = Control.MOUSE_FILTER_PASS
	_boton_q1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boton_q1.pressed.connect(alternar_q1)
	fila.add_child(_boton_q1)
	var reiniciar := Button.new()
	reiniciar.text = "Reiniciar"
	reiniciar.mouse_filter = Control.MOUSE_FILTER_PASS
	reiniciar.pressed.connect(_reiniciar)
	fila.add_child(reiniciar)
	var mando := HBoxContainer.new()
	mando.add_theme_constant_override("separation", 8)
	add_child(mando)
	mando.add_child(_pulsador("S1 marcha", "S1"))
	mando.add_child(_pulsador("S0 parada", "S0"))
	_actualizar_q1()


func _crear_circuito() -> void:
	sim = contenido.circuito(params["circuito"])
	_muestras.clear()
	_maximo = 0.0


func _reiniciar() -> void:
	_crear_circuito()
	_actualizar_q1()


func _pulsador(titulo: String, id: String) -> Button:
	var b := Button.new()
	b.text = titulo
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Se mantiene pulsado: el filtro por defecto evita que un movimiento arrastre la lista.
	b.set_meta("se_mantiene", true)
	b.button_down.connect(pulsar.bind(id, true))
	b.button_up.connect(pulsar.bind(id, false))
	return b


func pulsar(id: String, presionado: bool) -> void:
	sim.componente(id).estado["presionado"] = presionado


func alternar_q1() -> void:
	var q1: SimGuardamotor = sim.componente("Q1")
	q1.accionar(not q1.estado["encendido"])
	_actualizar_q1()


func _actualizar_q1() -> void:
	var q1: SimGuardamotor = sim.componente("Q1")
	_boton_q1.text = "Q1 cerrado (abrir)" if q1.cerrado() else "Q1 abierto (cerrar)"


func avanzar_pasos(pasos: int) -> void:
	for _i in pasos:
		sim.paso()
		var corr: float = sim.componente("Q1").corriente(sim.solucion, 0)
		_maximo = maxf(_maximo, corr)
		_muestras.append(corr)
		if _muestras.size() > MUESTRAS:
			_muestras.remove_at(0)


func corriente_maxima() -> float:
	return _maximo


func _process(delta: float) -> void:
	super(delta)
	if sim == null:
		return
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), 4)
	if pasos > 0:
		_acumulado = 0.0
		avanzar_pasos(pasos)


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var area := Rect2(44.0, 12.0, tam.x - 58.0, tam.y - 96.0)
	_dibujar_grafica(area)
	var y := area.end.y + 28.0
	var x := 16.0
	for id: String in params["contactores"]:
		var cerrado: bool = sim.componente(id).cerrado()
		lienzo.draw_rect(Rect2(x, y - 11.0, 22.0, 22.0), AMARILLO if cerrado else Color("b4b9bc"))
		lienzo.draw_rect(Rect2(x, y - 11.0, 22.0, 22.0), Tema.TINTA, false, 1.5)
		texto(Vector2(x + 28.0, y), id, 15, Tema.TINTA, false)
		x += 66.0
	var m: SimMotorTrifasico = sim.componente("M1")
	var corr: float = _muestras[-1] if not _muestras.is_empty() else 0.0
	texto(Vector2(16.0, y + 30.0), "%s A   ·   %s rpm   ·   máx. %s A" % [
		TextoTecnico.numero(corr, 1), TextoTecnico.numero(absf(m.rpm()), 0), TextoTecnico.numero(_maximo, 0),
	], 15, Tema.TINTA, false)


func _dibujar_grafica(area: Rect2) -> void:
	lienzo.draw_rect(area, Color("f7f8f6"))
	lienzo.draw_rect(area, Color("8d989f"), false, 1.0)
	var tope := maxf(_maximo * 1.1, 40.0)
	texto(Vector2(22.0, area.position.y + 6.0), TextoTecnico.numero(tope, 0), 12)
	texto(Vector2(22.0, area.end.y - 6.0), "0 A", 12)
	if _muestras.size() < 2:
		return
	var puntos := PackedVector2Array()
	for i in _muestras.size():
		var px := area.position.x + area.size.x * float(i) / MUESTRAS
		puntos.append(Vector2(px, area.end.y - area.size.y * _muestras[i] / tope))
	lienzo.draw_polyline(puntos, Color("1668c4"), 2.0, true)
