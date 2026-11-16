extends Animacion
## Corte de un aparato de mando con sus contactos: a la izquierda el accionamiento, a la derecha
## los contactos NA, NC o conmutados, que cambian al accionarse. Un solo guion para varios
## aparatos, elegidos con "tipo":
##   pulsador (vuelve por resorte), seta (queda enclavada), selector (posiciones con su tabla de
##   contactos), final_carrera (leva que empuja el rodillo), presostato (corte, diferencial y
##   rearme manual), termostato (consigna y diferencial), nivel (flotador) y rele (bobina).
## "contactos": [{"bornes": "13-14", "tipo": "NA"}, {"bornes": "11-12-14", "tipo": "conmutado"}].
## Los ajustes de presostato, termostato y nivel son los de SimPresostato, SimTermostato y
## SimInterruptorNivel: corte o consigna, diferencial y rearme.

const ANCHO := 408.0
const ALTO := 300.0
const PULSADO_S := 1.2

var tipo := "pulsador"
var accionado := false
## Valor del proceso o posición: presión, temperatura, nivel o leva, según el tipo.
var valor := 0.0
var posicion := 0
var _pulsado_s := 0.0
var _bobina := false
var _movimiento := 0.0
var _valor: Label
var _nota: Label
var _botones: Array[Button] = []
var _interruptor: Interruptor
var _barra: HSlider


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tipo = str(params.get("tipo", "pulsador"))
	valor = float(params.get("inicial", _minimo()))
	if tipo == "selector":
		posicion = maxi(_posiciones().find(str(params.get("inicial_posicion", "OFF"))), 0)
	if tipo == "rele":
		_interruptor = Interruptor.new()
		_interruptor.toggled.connect(poner_bobina)
		tarjeta_control("Tensión en A1-A2", "Toque para dar tensión a la bobina", _interruptor)
		_nota = nota_mandos(tarjeta_mandos())
		_actualizar()
		return
	var c := tarjeta_mandos()
	if tipo in ["presostato", "termostato", "nivel", "final_carrera"]:
		_valor = fila_valor(c, str(params.get("magnitud", "Valor")))
		_barra = barra(c, _minimo(), _maximo(), (_maximo() - _minimo()) / 200.0, valor, poner_valor)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	match tipo:
		"pulsador":
			_botones.append(boton_mando(fila, pulsar))
		"seta":
			_botones.append(boton_mando(fila, func() -> void: enclavar(not accionado)))
		"selector":
			_botones.append(boton_mando(fila, girar.bind(-1)))
			_botones.append(boton_mando(fila, girar.bind(1)))
		"presostato":
			_botones.append(boton_mando(fila, rearmar))
	if fila.get_child_count() == 0:
		fila.queue_free()
	_nota = nota_mandos(c)
	_actualizar()


func _minimo() -> float:
	return float(params.get("minimo", 0.0))


func _maximo() -> float:
	return float(params.get("maximo", 1.0))


func _posiciones() -> Array:
	return params.get("posiciones", ["MAN", "OFF", "AUT"])


func _corte() -> float:
	return float(params.get("corte", 0.5))


func _diferencial() -> float:
	return float(params.get("diferencial", 0.1))


func pulsar() -> void:
	_pulsado_s = PULSADO_S
	accionado = true
	_actualizar()


func enclavar(pulsada: bool) -> void:
	accionado = pulsada
	_actualizar()


func girar(sentido: int) -> void:
	posicion = clampi(posicion + sentido, 0, _posiciones().size() - 1)
	_actualizar()


func poner_bobina(con: bool) -> void:
	_bobina = con
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(con)
		_interruptor.queue_redraw()
	_actualizar()


func poner_valor(v: float) -> void:
	valor = v
	if _barra != null:
		_barra.set_value_no_signal(v)
	match tipo:
		"final_carrera":
			accionado = valor >= 0.55
		"presostato":
			# Rearme manual: abierto queda abierto hasta que se rearme.
			if valor > _corte():
				accionado = true
		"termostato", "nivel":
			if valor >= _corte():
				accionado = true
			elif valor <= _corte() - _diferencial():
				accionado = false
	_actualizar()


## Igual que SimPresostato.rearmar: solo con la presión por debajo del corte menos el diferencial.
func rearmar() -> bool:
	if valor > _corte() - _diferencial():
		_nota.text = "No rearma: la presión aún está por encima de %s %s (corte menos diferencial)." % [coma(_corte() - _diferencial()), params.get("unidad", "")]
		return false
	accionado = false
	_actualizar()
	return true


## Si un contacto está cerrado ahora. Los conmutados cierran el NA (el último borne) al accionarse.
func cerrado(contacto: Dictionary) -> bool:
	if tipo == "selector":
		return params.get("tabla", {}).get(contacto["bornes"], []).has(_posiciones()[posicion])
	match str(contacto["tipo"]):
		"NA":
			return accionado
		"NC":
			return not accionado
	return accionado


## 1 en reposo, 2 cerca de actuar, 3 accionado; en el selector, el número de la posición.
func fase() -> int:
	if tipo == "selector":
		return clampi(posicion + 1, 1, 3)
	if accionado:
		return 3
	if tipo in ["presostato", "termostato", "nivel"] and valor >= _corte() - 2.0 * _diferencial():
		return 2
	if tipo == "final_carrera" and valor >= 0.3:
		return 2
	if tipo == "rele" and _bobina:
		return 2
	return 1


func avanzar(segundos: float) -> void:
	_process(segundos)


func _process(delta: float) -> void:
	if tipo == "pulsador" and _pulsado_s > 0.0:
		_pulsado_s -= delta
		if _pulsado_s <= 0.0:
			accionado = false
			_actualizar()
	if tipo == "rele":
		var antes := accionado
		_movimiento = move_toward(_movimiento, 1.0 if _bobina else 0.0, delta * 5.0)
		accionado = _movimiento > 0.99 or (_bobina and _movimiento > 0.5)
		if accionado != antes:
			_actualizar()
	else:
		_movimiento = move_toward(_movimiento, 1.0 if accionado else 0.0, delta * 6.0)
	super(delta)


func _actualizar() -> void:
	if _valor != null:
		_valor.text = "%s %s" % [coma(valor * float(params.get("escala_valor", 1.0)), 1), params.get("unidad", "")]
	match tipo:
		"pulsador":
			_botones[0].text = "Pulsar (vuelve solo)"
		"seta":
			_botones[0].text = "Girar para liberar" if accionado else "Pulsar la seta"
		"selector":
			_botones[0].text = "Girar a la izquierda"
			_botones[1].text = "Girar a la derecha"
			_botones[0].disabled = posicion == 0
			_botones[1].disabled = posicion == _posiciones().size() - 1
		"presostato":
			_botones[0].text = "Rearmar"
	var notas: Dictionary = params.get("notas", {})
	var clave := "accionado" if accionado else "reposo"
	if tipo == "selector":
		clave = str(_posiciones()[posicion])
	if _nota != null:
		_nota.text = str(notas.get(clave, ""))


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	texto(Vector2(204, 12), str(params.get("titulo", "")), 12, Color("5b6267"))
	match tipo:
		"pulsador", "seta":
			_dibujar_pulsador()
		"selector":
			_dibujar_selector()
		"final_carrera":
			_dibujar_final_carrera()
		"presostato", "termostato", "nivel":
			_dibujar_proceso()
		"rele":
			_dibujar_rele()
	_dibujar_contactos()
	var rotulo: String = params.get("rotulos", {}).get("accionado" if accionado else "reposo", "ACCIONADO" if accionado else "EN REPOSO")
	if tipo == "selector":
		rotulo = "POSICIÓN %s" % _posiciones()[posicion]
	rotulo_estado(Vector2(320, 280), rotulo, Color("c26a1a") if accionado and tipo != "selector" else Tema.ACIERTO)
	lienzo.draw_set_transform(Vector2.ZERO)


## Contactos en una caja a la derecha.
func _dibujar_contactos() -> void:
	var l := lienzo
	var contactos: Array = params.get("contactos", [])
	var alto := 26.0 + contactos.size() * 48.0
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(244, 30, 154, alto))
	for i in contactos.size():
		var c: Dictionary = contactos[i]
		var y := 52.0 + i * 48.0
		var cerrado_ := cerrado(c)
		texto(Vector2(254, y), "%s %s" % [c["bornes"], "" if c["tipo"] == "conmutado" else c["tipo"]], 12, Tema.TINTA, false)
		if c["tipo"] != "conmutado":
			texto_derecha(Vector2(392, y), "cerrado" if cerrado_ else "abierto", 10, Tema.ACIERTO if cerrado_ else Tema.FALLO)
		var o := Vector2(256, y + 22)
		if c["tipo"] == "conmutado":
			# Común abajo a la izquierda; NC arriba, NA abajo a la derecha.
			l.draw_line(o, o + Vector2(24, 0), Tema.TINTA, 3.0)
			l.draw_line(o + Vector2(52, -10), o + Vector2(90, -10), Tema.TINTA, 3.0)
			l.draw_line(o + Vector2(52, 6), o + Vector2(90, 6), Tema.TINTA, 3.0)
			var fin := o + Vector2(54, 6) if cerrado_ else o + Vector2(54, -10)
			l.draw_line(o + Vector2(24, 0), fin, Tema.TINTA, 3.0, true)
			var partes: PackedStringArray = str(c["bornes"]).split("-")
			if partes.size() == 3:
				texto(o + Vector2(102, -10), partes[1], 10, Tema.TINTA)
				texto(o + Vector2(102, 6), partes[2], 10, Tema.TINTA)
		else:
			l.draw_line(o, o + Vector2(28, 0), Tema.TINTA, 3.0)
			l.draw_line(o + Vector2(56, 0), o + Vector2(96, 0), Tema.TINTA, 3.0)
			var fin := o + Vector2(58, 0) if cerrado_ else o + Vector2(52, -14)
			l.draw_line(o + Vector2(28, 0), fin, Tema.TINTA, 3.0, true)


func _dibujar_pulsador() -> void:
	var l := lienzo
	var seta := tipo == "seta"
	var bajada := _movimiento * 14.0
	# Frente del tablero.
	l.draw_rect(Rect2(30, 92, 180, 10), Color("6e7a83"))
	if seta:
		l.draw_circle(Vector2(120, 70), 46.0, Color("f2c400"))
	# Cabeza y vástago.
	var cabeza := Color("c0392b") if seta else Color(params.get("color", "#2f9e57"))
	l.draw_rect(Rect2(112, 60 + bajada, 16, 90), Color("8a949b"))
	if seta:
		l.draw_circle(Vector2(120, 56 + bajada), 34.0, cabeza)
		l.draw_rect(Rect2(86, 56 + bajada, 68, 12), cabeza)
	else:
		l.draw_style_box(Tema.caja(cabeza, 6, 0, 0), Rect2(92, 62 + bajada, 56, 26))
		texto(Vector2(120, 75 + bajada), str(params.get("marca", "I")), 16, Color.WHITE)
	# Resorte y bloque de contactos.
	var resorte := PackedVector2Array()
	for k in 9:
		resorte.append(Vector2(120.0 + (8.0 if k % 2 == 1 else -8.0), lerpf(150 + bajada, 196, k / 8.0)))
	l.draw_polyline(resorte, Color("3b444b"), 2.5, true)
	l.draw_style_box(Tema.caja(Color("f2f3f1"), 6, 0, 0, Color("5b6267")), Rect2(70, 196, 100, 60))
	texto(Vector2(120, 270), "Bloque de contactos", 11, Tema.TINTA)
	if seta:
		texto(Vector2(120, 136), "enclavada: gire para liberar" if accionado else "", 10, Tema.FALLO)
	else:
		texto(Vector2(120, 136), "vuelve por resorte" if accionado else "", 10, Color("5b6267"))


func _dibujar_selector() -> void:
	var l := lienzo
	var c := Vector2(120, 150)
	var nombres := _posiciones()
	l.draw_circle(c, 56.0, Color("2b2f32"))
	var n := nombres.size()
	for i in n:
		var a := deg_to_rad(-90.0 + (i - (n - 1) / 2.0) * 45.0)
		texto(c + Vector2(cos(a), sin(a)) * 80.0, str(nombres[i]), 13, Tema.TINTA)
	var angulo := deg_to_rad(-90.0 + (posicion - (n - 1) / 2.0) * 45.0)
	var d := Vector2(cos(angulo), sin(angulo))
	l.draw_line(c - d * 44.0, c + d * 44.0, Color("e9ebe8"), 16.0, true)
	l.draw_circle(c + d * 40.0, 4.0, Color("c0392b"))
	texto(Vector2(120, 236), "Mantiene la posición elegida", 11, Color("5b6267"))


func _dibujar_final_carrera() -> void:
	var l := lienzo
	l.draw_style_box(Tema.caja(Color("e2b23a"), 8, 0, 0, Color("7a6416")), Rect2(110, 130, 90, 120))
	texto(Vector2(155, 196), "Final de carrera", 10, Tema.TINTA)
	var pivote := Vector2(155, 130)
	var angulo := lerpf(-0.25, 0.45, _movimiento)
	var punta := pivote + Vector2(-cos(angulo + 0.9), -sin(angulo + 0.9)) * 70.0
	l.draw_line(pivote, punta, Color("3b444b"), 6.0, true)
	l.draw_circle(punta, 12.0, Color("2b2f32"))
	l.draw_circle(punta, 5.0, Color("8a949b"))
	# Leva que avanza con la máquina y empuja el rodillo desde la izquierda.
	var x := minf(lerpf(-20.0, 140.0, valor), punta.x - 12.0)
	var leva := PackedVector2Array([Vector2(x - 90, punta.y - 22), Vector2(x - 14, punta.y - 22), Vector2(x, punta.y), Vector2(x - 14, punta.y + 22), Vector2(x - 90, punta.y + 22)])
	l.draw_colored_polygon(leva, Color("8a949b"))
	texto(Vector2(maxf(x - 50, 24), punta.y - 32), "leva", 11, Tema.TINTA)


func _dibujar_proceso() -> void:
	var l := lienzo
	var frac := clampf((valor - _minimo()) / (_maximo() - _minimo()), 0.0, 1.0)
	var y_corte := lerpf(250.0, 40.0, (_corte() - _minimo()) / (_maximo() - _minimo()))
	var y_vuelta := lerpf(250.0, 40.0, (_corte() - _diferencial() - _minimo()) / (_maximo() - _minimo()))
	if tipo == "nivel":
		# Recipiente con el líquido y el flotador.
		l.draw_style_box(Tema.caja(Color("f2f3f1"), 6, 0, 0, Color("5b6267")), Rect2(40, 40, 120, 210))
		var y := lerpf(250.0, 40.0, frac)
		l.draw_rect(Rect2(42, y, 116, 248 - y), Color("8fbfe0"))
		l.draw_line(Vector2(100, 46), Vector2(100, y - 8), Color("5b6267"), 3.0)
		l.draw_rect(Rect2(80, y - 12, 40, 18), Color("eef0f1"))
		l.draw_rect(Rect2(80, y - 12, 40, 18), Color("3b444b"), false, 2.0)
	else:
		# Escala vertical con el valor, como un manómetro o un termómetro.
		l.draw_style_box(Tema.caja(Color("f2f3f1"), 12, 0, 0, Color("5b6267")), Rect2(80, 34, 40, 224))
		var y := lerpf(250.0, 40.0, frac)
		var color := Color("c0392b") if tipo == "termostato" else Color("2f6fb5")
		l.draw_rect(Rect2(88, y, 24, 250 - y), color)
		texto(Vector2(100, 272), "presión" if tipo == "presostato" else "bulbo", 11, Tema.TINTA)
	# Corte y vuelta.
	l.draw_line(Vector2(36, y_corte), Vector2(176, y_corte), Color("c0392b"), 2.0)
	texto(Vector2(180, y_corte), "%s %s" % [params.get("nombre_corte", "corte"), coma(_corte() * float(params.get("escala_valor", 1.0)), 1)], 10, Color("c0392b"), false)
	_discontinua(Vector2(36, y_vuelta), Vector2(176, y_vuelta))
	texto(Vector2(180, y_vuelta + 12), "vuelve", 10, Color("5b6267"), false)


func _dibujar_rele() -> void:
	var l := lienzo
	var color := Color("b9844f").lerp(Color("e58a2e"), _movimiento if _bobina else 0.0)
	# Núcleo con la bobina alrededor.
	l.draw_style_box(Tema.caja(Color("596570"), 3, 0, 0, Color("3b444b")), Rect2(70, 140, 36, 100))
	l.draw_style_box(Tema.caja(color, 4, 0, 0, Color("9a5512")), Rect2(56, 166, 64, 54))
	texto(Vector2(88, 193), "A1-A2", 11, Tema.TINTA)
	# Armadura: baja hasta el núcleo con la bobina activada y empuja la leva hacia los contactos.
	var y := lerpf(112.0, 128.0, _movimiento)
	l.draw_style_box(Tema.caja(Color("596570"), 3, 0, 0, Color("3b444b")), Rect2(54, y, 110, 12))
	var empuje := 14.0 * _movimiento
	l.draw_line(Vector2(164, y + 6), Vector2(226 + empuje, y + 6), Color("8a949b"), 5.0)
	l.draw_rect(Rect2(226 + empuje, y - 6, 12, 24), Color("6e7a83"))
	texto(Vector2(196, y - 8), "leva", 10, Tema.TINTA)
	# Muelle que la devuelve.
	var muelle := PackedVector2Array()
	for k in 7:
		muelle.append(Vector2(140.0 + (6.0 if k % 2 == 1 else -6.0), lerpf(y + 12.0, 170.0, k / 6.0)))
	l.draw_polyline(muelle, Color("3b444b"), 2.5, true)
	texto(Vector2(88, 262), "Bobina, armadura y muelle", 11, Tema.TINTA)


func _discontinua(a: Vector2, b: Vector2) -> void:
	var largo := a.distance_to(b)
	var s := 0.0
	while s < largo:
		lienzo.draw_line(a.lerp(b, s / largo), a.lerp(b, minf(s + 6.0, largo) / largo), Color("5b6267"), 2.0)
		s += 11.0
