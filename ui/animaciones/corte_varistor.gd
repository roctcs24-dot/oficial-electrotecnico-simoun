extends Animacion
## Varistor de 275 V a la entrada de una fuente de 24 V, detrás de su fusible. A 230 V casi no
## conduce; un pico de 2000 V lo hace conducir y queda recortado a unos 710 V (su tensión de
## recorte). Cada pico lo desgasta: al quinto queda en corto y funde el fusible. Reventado (abierto),
## el pico llega entero a la fuente. Valores de enseñanza — verificar con la hoja del varistor.

const ANCHO := 400.0
const ALTO := 260.0
const V_PICO := 2000.0
const V_RECORTE := 710.0
const V_PICO_RED := 325.0
const DESGASTE_POR_PICO := 0.2
const DURACION_PICO := 1.2

var desgaste := 0.0
var en_corto := false
var abierto := false
var fusible_fundido := false
var fuente_danada := false
## Tensión del último pico en la entrada de la fuente.
var ultimo_pico := 0.0
var _desde_pico := 99.0
var _pico: Button
var _abrir: Button
var _estado: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_pico = boton_mando(fila, func() -> void: pico())
	_pico.text = "Llega un pico de 2000 V"
	var cambiar := boton_mando(fila, cambiar_todo)
	cambiar.text = "Cambiar varistor y fusible"
	_abrir = boton_mando(c, func() -> void: poner_abierto(not abierto))
	_estado = fila_valor(c, "Varistor / desgaste")
	_nota = nota_mandos(c)
	_actualizar()


## Aplica un pico y devuelve la tensión que llega a la fuente.
func pico() -> float:
	_desde_pico = 0.0
	if fusible_fundido:
		ultimo_pico = 0.0
	elif abierto:
		ultimo_pico = V_PICO
		fuente_danada = true
	else:
		ultimo_pico = V_RECORTE
		desgaste = minf(desgaste + DESGASTE_POR_PICO, 1.0)
		if desgaste >= 1.0 - 1e-6:
			en_corto = true
			fusible_fundido = true
	_actualizar()
	return ultimo_pico


func poner_abierto(si: bool) -> void:
	abierto = si
	if si:
		en_corto = false
	_actualizar()


func cambiar_todo() -> void:
	desgaste = 0.0
	en_corto = false
	abierto = false
	fusible_fundido = false
	fuente_danada = false
	_actualizar()


func tension_fuente() -> float:
	return 0.0 if fusible_fundido else 230.0


## 1 en servicio normal; 2 recortando un pico; 3 en corto con el fusible fundido.
func fase() -> int:
	if fusible_fundido:
		return 3
	return 2 if _desde_pico < DURACION_PICO else 1


func _process(delta: float) -> void:
	_desde_pico += delta
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_abrir.text = "Poner un varistor sano" if abierto else "Reventar el varistor"
	var estado := "reventado" if abierto else ("en corto" if en_corto else ("degradado" if desgaste > 0.0 else "sano"))
	_estado.text = "%s · %d %%" % [estado, roundi(desgaste * 100.0)]
	if fusible_fundido:
		_nota.text = "Gastado por los picos, el varistor quedó en corto y fundió el fusible: la fuente está sin tensión. Cambie los dos."
	elif fuente_danada:
		_nota.text = "Sin varistor que lo recorte, el pico de 2000 V llegó entero a la fuente y la dañó."
	elif abierto:
		_nota.text = "Reventado: la fuente funciona, pero el próximo pico llegará entero."
	elif desgaste > 0.0:
		_nota.text = "Recortó el pico a unos 710 V. Cada pico le deja más fuga: se calienta y se acerca al corto."
	else:
		_nota.text = "A 230 V casi no conduce: solo unos microamperios de fuga."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "VARISTOR A LA ENTRADA DE UNA FUENTE", 12, Color("5b6267"))
	# Onda en la entrada de la fuente: la red y, si hay pico, el pico (recortado o no).
	var marco := Rect2(20, 30, 360, 110)
	l.draw_rect(marco, Color.WHITE)
	l.draw_rect(marco, Color("8a949b"), false, 1.5)
	var escala := marco.size.y / 2.0 / 2100.0
	var medio := marco.position.y + marco.size.y / 2.0
	l.draw_dashed_line(Vector2(marco.position.x, medio - V_RECORTE * escala), Vector2(marco.end.x, medio - V_RECORTE * escala), Color("2c6e9e"), 1.0, 5.0)
	texto(Vector2(marco.end.x - 4, medio - V_RECORTE * escala - 8), "recorte 710 V", 9, Color("2c6e9e"), false)
	var onda := PackedVector2Array()
	for k in 181:
		var x := marco.position.x + k * marco.size.x / 180.0
		var v := 0.0 if fusible_fundido else V_PICO_RED * sin(k / 180.0 * TAU * 3.0)
		var en_pico := _desde_pico < DURACION_PICO and k >= 70 and k <= 78
		if en_pico:
			v = ultimo_pico * sin(float(k - 70) / 8.0 * PI)
		onda.append(Vector2(x, medio - v * escala))
	l.draw_polyline(onda, Color("c0392b"), 2.0, true)
	# Esquema: fusible, varistor y fuente.
	var cable := Color("8a949b") if fusible_fundido else Color("c0392b")
	l.draw_line(Vector2(30, 170), Vector2(90, 170), Color("c0392b"), 3.0)
	l.draw_style_box(Tema.caja(Color.WHITE, 2, 0, 0, Color("20242a")), Rect2(90, 162, 40, 16))
	if fusible_fundido:
		l.draw_line(Vector2(96, 178), Vector2(124, 162), Tema.FALLO, 3.0)
	texto(Vector2(110, 192), "F1", 11, Tema.TINTA)
	l.draw_line(Vector2(130, 170), Vector2(300, 170), cable, 3.0)
	l.draw_line(Vector2(30, 240), Vector2(300, 240), Color("20242a"), 3.0)
	var calor := clampf(desgaste, 0.0, 1.0)
	var disco := Color("2c6eb5").lerp(Color("5a2a1a"), calor)
	if abierto:
		disco = Color("8a949b")
	l.draw_line(Vector2(200, 170), Vector2(200, 186), cable, 3.0)
	l.draw_line(Vector2(200, 224), Vector2(200, 240), Color("20242a"), 3.0)
	l.draw_circle(Vector2(200, 205), 20.0, disco)
	if abierto:
		l.draw_line(Vector2(186, 192), Vector2(214, 218), Tema.FALLO, 3.0)
	if _desde_pico < DURACION_PICO and not abierto and not fusible_fundido:
		var brillo := 1.0 - _desde_pico / DURACION_PICO
		l.draw_circle(Vector2(200, 205), 26.0, Color(1.0, 0.85, 0.2, 0.6 * brillo))
		flecha(Vector2(200, 186), Vector2(200, 226), Tema.ACENTO_FUERTE)
	texto(Vector2(240, 205), "RV1", 11, Tema.TINTA)
	l.draw_style_box(Tema.caja(Color.WHITE, 6, 0, 0, Color("20242a")), Rect2(300, 160, 80, 90))
	texto(Vector2(340, 186), "FUENTE", 10, Color("5b6267"))
	texto(Vector2(340, 208), "24 V", 14, Tema.TINTA)
	var rotulo := "SIN TENSIÓN" if fusible_fundido else ("DAÑADA" if fuente_danada else "EN SERVICIO")
	var color := Color("5b6267") if fusible_fundido else (Tema.FALLO if fuente_danada else Tema.ACIERTO)
	rotulo_estado(Vector2(340, 234), rotulo, color)
	l.draw_set_transform(Vector2.ZERO)
