extends Animacion
## Condensador electrolítico de 4700 µF que se carga desde 24 V a través de una resistencia de
## 1 kΩ: constante de tiempo τ = R · C = 4,7 s; en 5τ está lleno. Sin la fuente guarda la carga
## (solo la pierde por su fuga, despacio); descargado con la resistencia de 1 kΩ, vuelve a 0 V.
## Seco, con la mitad de capacidad, todo va el doble de rápido y guarda la mitad de carga.

const ANCHO := 400.0
const ALTO := 260.0
const V_FUENTE := 24.0
const R_OHM := 1000.0
const C_UF := 4700.0
## Constante de tiempo de su propia fuga, con la fuente quitada.
const TAU_FUGA_S := 600.0
const SEGURO_V := 2.0
const HISTORIA_S := 30.0

var alimentado := true
var descargando := false
var seco := false
var vc := 0.0
var _historia: Array[float] = []
var _reloj := 0.0
var _interruptor: Interruptor
var _descargar: Button
var _seco: Button
var _tension: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.button_pressed = alimentado
	_interruptor.toggled.connect(poner_tension)
	tarjeta_control("Fuente de 24 V conectada", "Toque para conectarla o quitarla", _interruptor)
	var c := tarjeta_mandos()
	_tension = fila_valor(c, "Tensión en el condensador")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_descargar = boton_mando(fila, descargar)
	_seco = boton_mando(fila, func() -> void: secar(not seco))
	_nota = nota_mandos(c)
	_actualizar()


func poner_tension(si: bool) -> void:
	alimentado = si
	if si:
		descargando = false
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(si)
		_interruptor.queue_redraw()
	_actualizar()


## Con la fuente quitada, une los bornes a través de la resistencia de descarga.
func descargar() -> void:
	if alimentado:
		return
	descargando = true
	_actualizar()


func secar(si: bool) -> void:
	seco = si
	_actualizar()


func capacidad_uf() -> float:
	return C_UF * (0.5 if seco else 1.0)


func tau() -> float:
	return R_OHM * capacidad_uf() * 1e-6


func avanzar(dt: float) -> void:
	if alimentado:
		vc = V_FUENTE + (vc - V_FUENTE) * exp(-dt / tau())
	elif descargando:
		vc *= exp(-dt / tau())
	else:
		vc *= exp(-dt / TAU_FUGA_S)
	_reloj += dt
	_actualizar()


## 1 con la fuente; 2 sin la fuente y aún cargado; 3 descargado con la resistencia.
func fase() -> int:
	if alimentado:
		return 1
	return 3 if descargando else 2


func _process(delta: float) -> void:
	avanzar(delta)
	_historia.append(vc)
	var maximo := int(HISTORIA_S * Engine.get_frames_per_second()) if Engine.get_frames_per_second() > 0 else 1800
	while _historia.size() > maxi(maximo, 60):
		_historia.pop_front()
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_tension.text = "%s V" % coma(vc, 1)
	_descargar.text = "Descargar con 1 kΩ"
	_descargar.disabled = alimentado
	_seco.text = "Cambiarlo por uno nuevo" if seco else "Secarlo (pierde la mitad)"
	if alimentado:
		_nota.text = "Se carga a través de 1 kΩ: τ = R · C = %s s; en unos %s s está lleno." % [coma(tau(), 1), coma(5.0 * tau(), 0)]
	elif descargando:
		_nota.text = "Descargándose por la resistencia: %s. Compruebe 0 V con el voltímetro antes de tocar." % ("ya se puede tocar" if vc < SEGURO_V else "aún no lo toque")
	else:
		_nota.text = "Sin la fuente sigue cargado: %s V entre sus bornes. Descárguelo antes de tocarlo." % coma(vc, 1)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "CARGA Y DESCARGA DE UN CONDENSADOR", 12, Color("5b6267"))
	# Circuito: fuente, resistencia y condensador con sus cargas.
	var lleno := clampf(vc / V_FUENTE, 0.0, 1.0)
	l.draw_line(Vector2(40, 60), Vector2(40, 200), Color("c0392b") if alimentado else Color("8a949b"), 3.0)
	l.draw_line(Vector2(28, 120), Vector2(52, 120), Tema.TINTA, 4.0)
	l.draw_line(Vector2(34, 134), Vector2(46, 134), Tema.TINTA, 4.0)
	texto(Vector2(16, 100), "24 V", 10, Tema.TINTA)
	l.draw_line(Vector2(40, 60), Vector2(80, 60), Color("20242a"), 3.0)
	l.draw_style_box(Tema.caja(Color.WHITE, 2, 0, 0, Color("20242a")), Rect2(80, 52, 40, 16))
	texto(Vector2(100, 82), "1 kΩ", 10, Tema.TINTA)
	l.draw_line(Vector2(120, 60), Vector2(160, 60), Color("20242a"), 3.0)
	l.draw_line(Vector2(160, 60), Vector2(160, 104), Color("20242a"), 3.0)
	l.draw_line(Vector2(130, 104), Vector2(190, 104), Tema.TINTA, 5.0)
	l.draw_line(Vector2(130, 120), Vector2(190, 120), Tema.TINTA, 5.0)
	l.draw_line(Vector2(160, 120), Vector2(160, 200), Color("20242a"), 3.0)
	l.draw_line(Vector2(40, 200), Vector2(160, 200), Color("20242a"), 3.0)
	if not alimentado:
		l.draw_line(Vector2(40, 60), Vector2(40, 90), Color("f4f4f0"), 5.0)
		l.draw_line(Vector2(40, 90), Vector2(54, 70), Tema.TINTA, 3.0)
	if descargando:
		l.draw_line(Vector2(120, 60), Vector2(120, 200), Color("2c6e9e"), 2.0)
		texto(Vector2(108, 160), "descarga", 9, Color("2c6e9e"))
	var n := roundi(lleno * 7.0)
	for k in n:
		texto(Vector2(136 + k * 8, 96), "+", 10, Color("c0392b"))
		texto(Vector2(136 + k * 8, 130), "−", 12, Color("2c6e9e"))
	texto(Vector2(210, 112), "C", 12, Tema.TINTA)
	# Gráfica de la tensión en el tiempo.
	var marco := Rect2(230, 40, 150, 150)
	l.draw_rect(marco, Color.WHITE)
	l.draw_rect(marco, Color("8a949b"), false, 1.5)
	var y_seguro := marco.end.y - SEGURO_V / V_FUENTE * marco.size.y
	l.draw_dashed_line(Vector2(marco.position.x, y_seguro), Vector2(marco.end.x, y_seguro), Tema.ACIERTO, 1.0, 4.0)
	if _historia.size() > 1:
		var puntos := PackedVector2Array()
		for k in _historia.size():
			puntos.append(Vector2(marco.position.x + k * marco.size.x / float(_historia.size() - 1), marco.end.y - _historia[k] / V_FUENTE * marco.size.y))
		l.draw_polyline(puntos, Color("c0392b"), 2.5, true)
	texto_derecha(Vector2(marco.position.x - 3, marco.position.y), "24 V", 9)
	texto_derecha(Vector2(marco.position.x - 3, marco.end.y), "0", 9)
	texto(Vector2(305, 204), "últimos %d s" % roundi(HISTORIA_S), 10, Color("5b6267"))
	texto(Vector2(120, 230), "%s V" % coma(vc, 1), 18, Tema.TINTA)
	var peligro := not alimentado and vc >= SEGURO_V
	var rotulo := "CARGANDO" if alimentado else ("PELIGRO: CARGADO" if peligro else "DESCARGADO")
	rotulo_estado(Vector2(305, 236), rotulo, Color("2c6e9e") if alimentado else (Tema.FALLO if peligro else Tema.ACIERTO))
	l.draw_set_transform(Vector2.ZERO)
