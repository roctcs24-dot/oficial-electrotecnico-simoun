extends Animacion
## Corte de una fase del guardamotor: dos disparadores actúan sobre el mismo cerrojo. El térmico
## (bimetal, con SimTermico como la simulación) dispara tras un tiempo con sobrecarga; el
## magnético (bobina de pocas espiras con su núcleo móvil) dispara al instante por encima de
## magnetico_veces × Ir, como en un cortocircuito. Al soltarse el cerrojo, el muelle abre los
## contactos principales y el auxiliar 13-14, y cierra el de señal 97-98. Para rearmar hay que
## llevar el mando a O y después a I, igual que SimGuardamotor.accionar.
## Parámetros: ajuste_a (Ir, A), magnetico_veces y veces (corriente inicial en × Ir). Con
## "tipo": "interruptor" dibuja un interruptor automático: maneta en vez de mando giratorio,
## cámara de arco en vez de auxiliares y corriente en × In.

const ANCHO := 408.0
const ALTO := 340.0
const COBRE := Color("b26a1e")
const HIERRO := Color("596570")
const ACELERACION := 20.0
const UMBRAL_ACELERAR := 3.0

var veces := 1.0
var memoria := 0.0
var encendido := true
var disparado := false
## "termico" o "magnetico" tras un disparo.
var causa := ""
var reloj := 0.0
## 0 el núcleo del magnético en reposo, 1 golpeando el cerrojo.
var _nucleo := 0.0
## 0 contactos abiertos, 1 cerrados.
var _contactos := 1.0
## Segundos que le quedan al arco que se ve al abrir con corriente.
var _arco := 0.0
var _deslizador: HSlider
var _valor: Label
var _nota: Label
var _mando: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	veces = float(params.get("veces", 1.0))
	var tarjeta := PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tarjeta)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	tarjeta.add_child(columna)
	var fila := HBoxContainer.new()
	columna.add_child(fila)
	var titulo := Label.new()
	titulo.text = "Corriente del circuito"
	titulo.theme_type_variation = "Fuerte"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)
	_valor = Label.new()
	_valor.add_theme_color_override("font_color", Tema.ACENTO)
	fila.add_child(_valor)
	_deslizador = HSlider.new()
	_deslizador.min_value = 0.0
	_deslizador.max_value = 16.0
	_deslizador.step = 0.1
	_deslizador.value = veces
	_deslizador.custom_minimum_size.y = 48.0
	_deslizador.value_changed.connect(poner_corriente)
	columna.add_child(_deslizador)
	_nota = Label.new()
	_nota.theme_type_variation = "Nota"
	_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_nota)
	_mando = Button.new()
	_mando.mouse_filter = Control.MOUSE_FILTER_PASS
	_mando.custom_minimum_size.y = 48.0
	_mando.pressed.connect(func() -> void: accionar(not encendido or disparado))
	columna.add_child(_mando)
	_actualizar_textos()


func es_interruptor() -> bool:
	return params.get("tipo", "guardamotor") == "interruptor"


## Nombre de la corriente de ajuste: Ir en el guardamotor, In en el interruptor.
func _i() -> String:
	return "In" if es_interruptor() else "Ir"


func ajuste() -> float:
	return float(params.get("ajuste_a", 25.0))


func magnetico() -> float:
	return float(params.get("magnetico_veces", 13.0))


func cerrado() -> bool:
	return encendido and not disparado


func corriente() -> float:
	return veces * ajuste() if cerrado() else 0.0


func poner_corriente(v: float) -> void:
	veces = v
	_deslizador.set_value_no_signal(v)
	_comprobar_magnetico()
	_actualizar_textos()


## Girar el mando: tras un disparo, primero a O, que rearma el cerrojo, y después a I.
func accionar(encender: bool) -> void:
	if not encender and cerrado() and corriente() > 0.01:
		_arco = 0.4
	if not encender or disparado:
		encendido = false
		disparado = false
		causa = ""
	else:
		encendido = true
		reloj = 0.0
		_comprobar_magnetico()
	_actualizar_textos()


func _comprobar_magnetico() -> void:
	if cerrado() and veces > magnetico():
		_disparar("magnetico")


func _disparar(por: String) -> void:
	disparado = true
	causa = por
	_arco = 0.7 if por == "magnetico" else 0.4
	if por == "magnetico":
		_nucleo = 1.0
	_actualizar_textos()


func avanzar(segundos: float) -> void:
	var resto := segundos
	while resto > 0.0:
		var dt := minf(resto, 0.5)
		resto -= dt
		_comprobar_magnetico()
		memoria = SimTermico.actualizar(memoria, corriente(), ajuste(), dt)
		if cerrado():
			reloj += dt
			if memoria >= SimTermico.UMBRAL:
				_disparar("termico")


## Paso de la explicación: 1 en servicio, 2 un disparador en marcha, 3 disparado.
func fase() -> int:
	if disparado:
		return 3
	return 2 if cerrado() and (memoria >= SimTermico.UMBRAL * 0.5 or veces > 1.15) else 1


func acelerado() -> bool:
	return veces < UMBRAL_ACELERAR or not cerrado()


func _process(delta: float) -> void:
	avanzar(delta * (ACELERACION if acelerado() else 1.0))
	_contactos = move_toward(_contactos, 1.0 if cerrado() else 0.0, delta * 6.0)
	_nucleo = move_toward(_nucleo, 0.0, delta * 1.5)
	_arco = maxf(_arco - delta, 0.0)
	super(delta)


func _actualizar_textos() -> void:
	_valor.text = "%s × %s · %s A" % [_coma(veces), _i(), _coma(veces * ajuste())]
	var causa_texto := "magnético: corriente de cortocircuito" if causa == "magnetico" else "térmico: sobrecarga mantenida"
	if es_interruptor():
		_mando.text = "Subir la maneta (ON)" if not cerrado() else "Bajar la maneta (OFF)"
		if disparado:
			_mando.text = "Rearmar: bajar la maneta"
			_nota.text = "Disparo %s. La maneta queda abajo: busque la causa antes de volver a subirla." % causa_texto
		elif not encendido:
			_nota.text = "Abierto (OFF): el circuito no tiene tensión aguas abajo."
		else:
			_nota.text = "In = %s A, curva %s. Térmico: con 1,5 × In dispara en minutos. Magnético: al instante por encima de %s × In (la curva C abre entre 5 y 10 × In)." % [_coma(ajuste()), str(params.get("curva", "C")), _coma(magnetico())]
		return
	_mando.text = "Girar el mando a I (encender)" if not cerrado() else "Girar el mando a O (apagar)"
	if disparado:
		_mando.text = "Rearmar: girar el mando a O"
		_nota.text = "Disparo %s. Para rearmar, lleve el mando a O y después a I; antes, busque la causa." % causa_texto
	elif not encendido:
		_nota.text = "Apagado (O): los contactos principales y el 13-14 están abiertos."
	else:
		_nota.text = "Ir ajustada a %s A. Térmico: con 1,5 × Ir dispara en minutos y con 7,2 × Ir en unos 6 s. Magnético: al instante por encima de %s × Ir." % [_coma(ajuste()), _coma(magnetico())]


static func _coma(v: float) -> String:
	var s := "%.1f" % v
	s = s.trim_suffix(".0")
	return s.replace(".", ",")


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 14), str(params.get("titulo", "CORTE DE UNA FASE DEL GUARDAMOTOR")), 12, Color("5b6267"))
	var hay_corriente := corriente() > 0.01
	# Conductor de la fase: 1 → contacto principal → bobina magnética → bimetal → 2.
	texto(Vector2(36, 34), "1", 12, Tema.TINTA)
	l.draw_line(Vector2(50, 30), Vector2(50, 62), COBRE, 6.0)
	l.draw_rect(Rect2(42, 60, 16, 6), Color("d8a24a"))
	# Contacto móvil: pivota abajo y abre hacia la derecha.
	var pivote := Vector2(50, 104)
	var angulo := lerpf(0.55, 0.0, _contactos)
	var punta := pivote + Vector2(sin(angulo), -cos(angulo)) * 38.0
	l.draw_line(pivote, punta, COBRE, 6.0, true)
	l.draw_circle(pivote, 4.0, Color("3b444b"))
	texto(Vector2(66, 120), "Contacto principal", 11, Tema.TINTA, false)
	# Varilla del cerrojo al contacto móvil.
	_discontinua(punta + Vector2(4, 4), Vector2(196, 120))
	# Bobina magnética alrededor de su núcleo móvil.
	l.draw_line(pivote, Vector2(50, 124), COBRE, 6.0)
	var avance_nucleo := _nucleo * 30.0
	l.draw_rect(Rect2(64 + avance_nucleo, 140, 70, 16), HIERRO)
	for j in 6:
		var x := 70.0 + j * 10.0
		l.draw_arc(Vector2(x, 148), 14.0, PI * 0.5, PI * 1.5, 10, COBRE, 4.0, true)
	l.draw_line(Vector2(50, 124), Vector2(70, 134), COBRE, 4.0)
	l.draw_line(Vector2(120, 162), Vector2(50, 184), COBRE, 4.0)
	texto(Vector2(140, 134), "Magnético", 11, Tema.TINTA, false)
	# Bimetal del disparo térmico.
	var k := clampf(memoria / SimTermico.UMBRAL, 0.0, 1.0)
	l.draw_line(Vector2(50, 184), Vector2(50, 300), COBRE, 6.0)
	l.draw_line(Vector2(50, 278), Vector2(76, 278), COBRE, 5.0)
	var tip := Vector2(lerpf(90.0, 186.0, k), lerpf(206.0, 202.0, k))
	for capa in 2:
		var puntos := PackedVector2Array()
		var base := Vector2(78.0, 278.0)
		var c1 := Vector2(lerpf(82.0, 112.0, k), 246.0)
		for m in 13:
			var u := m / 12.0
			puntos.append(base.lerp(c1, u).lerp(c1.lerp(tip, u), u) + Vector2(6.0 * capa, 0.0))
		l.draw_polyline(puntos, Color("c2412e") if capa == 0 else Color("8a95a0"), 7.0 if capa == 0 else 5.0, true)
	if hay_corriente:
		var calor := clampf(pow(corriente() / ajuste(), 2.0) / 4.0, 0.0, 1.0)
		var ondas := PackedVector2Array()
		for m in 9:
			ondas.append(Vector2(64.0 + sin(m * 1.3 + t * 4.0) * 3.0, 270.0 - m * 7.0))
		l.draw_polyline(ondas, Color("e8462e", 0.3 + 0.7 * calor), 2.0, true)
	texto(Vector2(96, 296), "Térmico (bimetal)", 11, Tema.TINTA, false)
	texto(Vector2(36, 314), "2", 12, Tema.TINTA)
	# Cerrojo: lo sueltan el núcleo o el bimetal.
	l.draw_style_box(Tema.caja(Color("8a949b") if not disparado else Color("c0392b"), 4, 0, 0, Color("3b444b")), Rect2(196, 110, 34, 110))
	texto(Vector2(213, 236), "Cerrojo", 11, Tema.TINTA)
	# El arco al abrir con corriente, que la cámara enfría y corta.
	if _arco > 0.0:
		var zig := PackedVector2Array()
		var desde := punta + Vector2(6, 0)
		var hasta := Vector2(256, 60) if es_interruptor() else punta + Vector2(30, -14)
		for m in 9:
			var u := m / 8.0
			var desvio := 0.0 if m in [0, 8] else (-6.0 if m % 2 == 0 else 6.0)
			zig.append(desde.lerp(hasta, u) + Vector2(0, desvio))
		l.draw_polyline(zig, Color("ffd84a", minf(_arco * 2.0, 1.0)), 4.0, true)
	if es_interruptor():
		_dibujar_camara()
		_dibujar_maneta()
		l.draw_set_transform(Vector2.ZERO)
		return
	# Auxiliares y señal.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(256, 40, 142, 128))
	texto(Vector2(266, 60), "13-14 NA (auxiliar)", 12, Tema.TINTA, false)
	_contacto(Vector2(266, 80), cerrado())
	texto(Vector2(266, 98), "cerrado" if cerrado() else "abierto", 11, Tema.ACIERTO if cerrado() else Tema.FALLO, false)
	texto(Vector2(266, 120), "97-98 NA (señal)", 12, Tema.TINTA, false)
	_contacto(Vector2(266, 140), disparado)
	texto(Vector2(266, 158), "cerrado: alarma" if disparado else "abierto", 11, Tema.ACIERTO if disparado else Color("5b6267"), false)
	# Mando y estado.
	var centro := Vector2(326, 228)
	l.draw_circle(centro, 26.0, Color("2b2f32"))
	var giro := -0.6 if not encendido or disparado else 0.6
	if disparado:
		giro = 0.0
	l.draw_line(centro, centro + Vector2(sin(giro), -cos(giro)) * 22.0, Color("e9ebe8"), 6.0, true)
	texto(centro + Vector2(-30, -26), "O", 13, Tema.TINTA)
	texto(centro + Vector2(30, -26), "I", 13, Tema.TINTA)
	var rotulo := "EN SERVICIO"
	var color := Tema.ACIERTO
	if disparado:
		rotulo = "DISPARO " + ("MAGNÉTICO" if causa == "magnetico" else "TÉRMICO")
		color = Color("c0392b")
	elif not encendido:
		rotulo = "APAGADO (O)"
		color = Color("5b6267")
	var fuente := get_theme_default_font()
	var ancho := fuente.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20.0
	l.draw_style_box(Tema.caja(color, 5, 0, 0), Rect2(326 - ancho / 2.0, 270, ancho, 24))
	texto(Vector2(326, 282), rotulo, 12, Color.WHITE)
	var reloj_texto := "Tiempo: %d min %02d s%s" % [int(reloj) / 60, int(reloj) % 60, "  (reloj × %d)" % int(ACELERACION) if acelerado() else ""]
	var ancho_reloj := fuente.get_string_size(reloj_texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	texto(Vector2(398 - ancho_reloj, 318), reloj_texto, 11, Color("3b444b"), false)
	l.draw_set_transform(Vector2.ZERO)


## Cámara de arco del interruptor: placas de acero que dividen y enfrían el arco.
func _dibujar_camara() -> void:
	var l := lienzo
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(256, 36, 142, 86))
	for j in 7:
		l.draw_rect(Rect2(266 + j * 18, 48, 8, 50), Color("6e7a83"))
	texto(Vector2(327, 112), "Cámara de arco", 11, Tema.TINTA)


## Maneta: arriba ON, abajo OFF; tras un disparo cae abajo sola.
func _dibujar_maneta() -> void:
	var l := lienzo
	var fuente := get_theme_default_font()
	var caja := Rect2(296, 150, 60, 96)
	l.draw_style_box(Tema.caja(Color("2b2f32"), 8, 0, 0), caja)
	var arriba := cerrado()
	var palanca := Rect2(caja.position.x + 14, caja.position.y + (10.0 if arriba else 50.0), 32, 36)
	l.draw_style_box(Tema.caja(Color("e9ebe8"), 5, 0, 0), palanca)
	texto(Vector2(caja.get_center().x, caja.position.y - 10), "ON  I", 11, Tema.TINTA)
	texto(Vector2(caja.get_center().x, caja.end.y + 10), "OFF  O", 11, Tema.TINTA)
	var rotulo := "EN SERVICIO"
	var color := Tema.ACIERTO
	if disparado:
		rotulo = "DISPARO " + ("MAGNÉTICO" if causa == "magnetico" else "TÉRMICO")
		color = Color("c0392b")
	elif not encendido:
		rotulo = "ABIERTO (OFF)"
		color = Color("5b6267")
	var ancho := fuente.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20.0
	l.draw_style_box(Tema.caja(color, 5, 0, 0), Rect2(326 - ancho / 2.0, 272, ancho, 24))
	texto(Vector2(326, 284), rotulo, 12, Color.WHITE)
	var reloj_texto := "Tiempo: %d min %02d s%s" % [int(reloj) / 60, int(reloj) % 60, "  (reloj × %d)" % int(ACELERACION) if acelerado() else ""]
	var ancho_reloj := fuente.get_string_size(reloj_texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	texto(Vector2(398 - ancho_reloj, 318), reloj_texto, 11, Color("3b444b"), false)


func _discontinua(a: Vector2, b: Vector2) -> void:
	var largo := a.distance_to(b)
	var s := 0.0
	while s < largo:
		lienzo.draw_line(a.lerp(b, s / largo), a.lerp(b, minf(s + 6.0, largo) / largo), Color("5b6267"), 2.0)
		s += 11.0


func _contacto(origen: Vector2, cerrado_: bool) -> void:
	var l := lienzo
	l.draw_line(origen, origen + Vector2(26, 0), Tema.TINTA, 3.0)
	l.draw_line(origen + Vector2(52, 0), origen + Vector2(90, 0), Tema.TINTA, 3.0)
	var fin := origen + Vector2(54, 0) if cerrado_ else origen + Vector2(50, -12)
	l.draw_line(origen + Vector2(26, 0), fin, Tema.TINTA, 3.0, true)
