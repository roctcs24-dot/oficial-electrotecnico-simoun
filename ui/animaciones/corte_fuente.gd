extends Animacion
## Fuente conmutada de 24 V y 5 A por etapas: rectificado de la entrada (unos 325 V), troceado a
## alta frecuencia por el MOSFET, transformador de ferrita y salida rectificada y regulada. Con la
## protección de SimFuenteDC: por encima de 1,1 × 5 A durante 0,1 s corta la salida 2 s y vuelve
## a probar.

const ANCHO := 400.0
const ALTO := 260.0
const CARGAS := [[12.0, "2 A"], [4.8, "5 A"], [1.0, "Corto"]]

var entrada := true
var carga := 0
var protegida := false
var _sobrecarga_s := 0.0
var _corte_s := 0.0
var _p: Dictionary
var _interruptor: Interruptor
var _botones: Array[Button] = []
var _salida: Label
var _nota: Label


func preparar() -> void:
	_p = SimFuenteDC.new("U1").params
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.button_pressed = entrada
	_interruptor.toggled.connect(poner_entrada)
	tarjeta_control("Entrada de 230 V", "Toque para conectarla o quitarla", _interruptor)
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for i in CARGAS.size():
		var b := boton_mando(fila, elegir_carga.bind(i))
		b.text = CARGAS[i][1]
		_botones.append(b)
	_salida = fila_valor(c, "Salida")
	_nota = nota_mandos(c)
	_actualizar()


func poner_entrada(si: bool) -> void:
	entrada = si
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(si)
		_interruptor.queue_redraw()
	_actualizar()


func elegir_carga(i: int) -> void:
	carga = clampi(i, 0, CARGAS.size() - 1)
	_actualizar()


func salida() -> float:
	if not entrada or protegida:
		return 0.0
	var v := float(_p["v_salida"])
	var r := float(CARGAS[carga][0])
	return v * r / (r + float(_p["r_interna"]))


func corriente() -> float:
	return salida() / float(CARGAS[carga][0])


func avanzar(dt: float) -> void:
	if protegida:
		_corte_s += dt
		if _corte_s >= SimFuenteDC.CORTE_S:
			protegida = false
			_corte_s = 0.0
	elif entrada and corriente() > float(_p["i_max"]) * 1.1:
		_sobrecarga_s += dt
		if _sobrecarga_s >= SimFuenteDC.SOBRECARGA_S:
			protegida = true
			_sobrecarga_s = 0.0
	else:
		_sobrecarga_s = 0.0
	_actualizar()


## 1 sin entrada; 2 en servicio; 3 protección por sobrecarga o corto.
func fase() -> int:
	if not entrada:
		return 1
	return 3 if protegida or corriente() > float(_p["i_max"]) * 1.1 else 2


func _process(delta: float) -> void:
	avanzar(delta)
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if k == carga else 0.6)
	_salida.text = "%s V · %s A" % [coma(salida(), 1), coma(corriente(), 1)]
	match fase():
		1:
			_nota.text = "Sin entrada no hay salida: el LED DC OK se apaga."
		2:
			_nota.text = "La entrada se rectifica (unos 325 V), el MOSFET la trocea a decenas de kHz, el transformador la baja y la salida se regula a 24 V."
		3:
			_nota.text = "Con el corto, la fuente limita la corriente, corta la salida 2 s y vuelve a probar: los relés castañetean. Busque el corto."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "FUENTE CONMUTADA POR ETAPAS", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	var etapas := [["230 V~", "entrada"], ["325 V=", "rectifica"], ["kHz", "trocea"], ["ferrita", "baja"], ["24 V=", "regula"]]
	var activo := entrada and not protegida
	for k in etapas.size():
		var r := Rect2(14 + k * 76, 40, 66, 86)
		l.draw_style_box(Tema.caja(Color.WHITE, 6, 0, 0, tinta), r)
		texto(Vector2(r.get_center().x, 112), etapas[k][1], 10, Color("5b6267"))
		texto(Vector2(r.get_center().x, 54), etapas[k][0], 10, tinta)
		var c := Vector2(r.get_center().x, 82)
		var puntos := PackedVector2Array()
		for j in 25:
			var f := j / 24.0
			var y := 0.0
			if activo or k == 0 and entrada:
				match k:
					0:
						y = sin(f * TAU * 2.0 + t * 4.0) * 14.0
					1:
						y = -12.0 + sin(f * TAU * 4.0) * 1.5
					2:
						y = -12.0 if fmod(f * 6.0 + t * 3.0, 1.0) < 0.5 else 12.0
					3:
						y = -8.0 if fmod(f * 6.0 + t * 3.0, 1.0) < 0.5 else 8.0
					4:
						y = -10.0
			puntos.append(c + Vector2((f - 0.5) * 52.0, y))
		l.draw_polyline(puntos, Color("c0392b") if k < 2 else Color("2c6e9e"), 2.0, true)
		if k < etapas.size() - 1:
			flecha(Vector2(r.end.x, 83), Vector2(r.end.x + 10, 83), tinta, 2.0)
	# Salida y carga.
	l.draw_line(Vector2(200, 150), Vector2(200, 170), tinta, 2.0)
	texto(Vector2(200, 186), "%s V · %s A" % [coma(salida(), 1), coma(corriente(), 1)], 14, tinta)
	l.draw_circle(Vector2(330, 186), 9.0, Color("2a8f4f") if salida() > 20.0 else Color("8a949b"))
	texto(Vector2(366, 186), "DC OK", 10, tinta)
	var rotulo := "SIN ENTRADA" if not entrada else ("PROTECCIÓN" if protegida else "EN SERVICIO")
	rotulo_estado(Vector2(200, 230), rotulo, Color("5b6267") if not entrada else (Tema.FALLO if protegida else Tema.ACIERTO))
	l.draw_set_transform(Vector2.ZERO)
