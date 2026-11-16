extends Animacion
## Corte de una fase del relé térmico: la corriente del motor calienta el bimetal, que se curva y
## empuja la barra de disparo; al llegar al final abre 95-96 (NC, el mando suelta el contactor)
## y cierra 97-98 (NA, alarma). Con el motor parado se enfría, y el rearme solo vuelve a cerrar
## 95-96 cuando el bimetal ya se enfrió. El calentamiento usa SimTermico, el mismo modelo que
## la simulación: con 1,05 × Ir no dispara, con 1,5 × Ir tarda unos minutos y con 7,2 × Ir unos 6 s.
## Parámetros: ajuste_a (Ir, A) y veces (corriente inicial en × Ir).

const ANCHO := 408.0
const ALTO := 340.0
const COBRE := Color("b26a1e")
## Por debajo de 3 × Ir el disparo tarda minutos: el reloj corre más deprisa para verlo.
const ACELERACION := 20.0
const UMBRAL_ACELERAR := 3.0

var veces := 1.5
var memoria := 0.0
var disparado := false
## Segundos simulados desde el último arranque o rearme.
var reloj := 0.0
var _deslizador: HSlider
var _valor: Label
var _nota: Label
var _rearme: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	veces = float(params.get("veces", 1.5))
	var tarjeta := PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tarjeta)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	tarjeta.add_child(columna)
	var fila := HBoxContainer.new()
	columna.add_child(fila)
	var titulo := Label.new()
	titulo.text = "Corriente del motor"
	titulo.theme_type_variation = "Fuerte"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)
	_valor = Label.new()
	_valor.add_theme_color_override("font_color", Tema.ACENTO)
	fila.add_child(_valor)
	_deslizador = HSlider.new()
	_deslizador.min_value = 0.0
	_deslizador.max_value = 8.0
	_deslizador.step = 0.05
	_deslizador.value = veces
	_deslizador.custom_minimum_size.y = 48.0
	_deslizador.value_changed.connect(poner_corriente)
	columna.add_child(_deslizador)
	_nota = Label.new()
	_nota.theme_type_variation = "Nota"
	_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_nota)
	_rearme = Button.new()
	_rearme.text = "Pulsar el rearme (botón azul)"
	_rearme.mouse_filter = Control.MOUSE_FILTER_PASS
	_rearme.custom_minimum_size.y = 48.0
	_rearme.pressed.connect(rearmar)
	columna.add_child(_rearme)
	_actualizar_textos()


func ajuste() -> float:
	return float(params.get("ajuste_a", 15.2))


func poner_corriente(v: float) -> void:
	veces = v
	_deslizador.set_value_no_signal(v)
	_actualizar_textos()


## Corriente que circula de verdad: disparado, el contactor soltó y el motor está parado.
func corriente() -> float:
	return 0.0 if disparado else veces * ajuste()


## Igual que SimReleTermico.rearmar: solo rearma si el bimetal se enfrió lo suficiente.
func rearmar() -> bool:
	if not disparado:
		return true
	if memoria >= SimTermico.UMBRAL * 0.8:
		_nota.text = "Aún está caliente: el bimetal no deja rearmar. Espere a que se enfríe."
		return false
	disparado = false
	reloj = 0.0
	_actualizar_textos()
	return true


## Avanza el tiempo simulado, como la simulación: sirve también a las pruebas.
func avanzar(segundos: float) -> void:
	var resto := segundos
	while resto > 0.0:
		var dt := minf(resto, 0.5)
		resto -= dt
		memoria = SimTermico.actualizar(memoria, corriente(), ajuste(), dt)
		if not disparado:
			reloj += dt
			if memoria >= SimTermico.UMBRAL:
				disparado = true
				_actualizar_textos()


## Paso de la explicación: 1 calentándose, 2 el bimetal ya empuja la barra, 3 disparado.
func fase() -> int:
	if disparado:
		return 3
	return 2 if memoria >= SimTermico.UMBRAL * 0.5 else 1


func acelerado() -> bool:
	return veces < UMBRAL_ACELERAR or disparado


func _process(delta: float) -> void:
	avanzar(delta * (ACELERACION if acelerado() else 1.0))
	super(delta)


func _actualizar_textos() -> void:
	_valor.text = "%s × Ir · %s A" % [_coma(veces, 2), _coma(veces * ajuste(), 1)]
	if disparado:
		_nota.text = "Disparado: 95-96 abrió y el contactor soltó. El motor está parado y el bimetal se enfría; después, rearme."
	else:
		_nota.text = "Ir ajustada a %s A. Con 1,05 × Ir no dispara nunca; con 1,5 × Ir, en unos minutos; con 7,2 × Ir, en unos 6 s." % _coma(ajuste(), 1)


## Número con coma decimal y sin ceros sobrantes: 1,5 y no 1,50.
static func _coma(v: float, decimales: int) -> String:
	var s := ("%." + str(decimales) + "f") % v
	if s.contains("."):
		s = s.rstrip("0").trim_suffix(".")
	return s.replace(".", ",")


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 14), "CORTE DE UNA FASE DEL RELÉ TÉRMICO", 12, Color("5b6267"))
	# Curvatura del bimetal: 0 frío, 1 en el punto de disparo.
	# Disparado, el cerrojo retiene los contactos aunque el bimetal se enderece al enfriarse.
	var k := clampf(memoria / SimTermico.UMBRAL, 0.0, 1.0)
	# Conductor de la fase: entra por 1 y sale por 2 a través del calefactor.
	var con_corriente := corriente() > 0.01
	l.draw_line(Vector2(40, 34), Vector2(40, 300), COBRE, 6.0)
	l.draw_line(Vector2(40, 84), Vector2(70, 84), COBRE, 5.0)
	l.draw_line(Vector2(40, 250), Vector2(70, 250), COBRE, 5.0)
	texto(Vector2(24, 44), "1", 12, Tema.TINTA)
	texto(Vector2(24, 296), "2", 12, Tema.TINTA)
	# Calefactor: ondas más intensas cuanto más corriente.
	var calor := clampf(pow(corriente() / ajuste(), 2.0) / 4.0, 0.0, 1.0)
	if con_corriente:
		var color_calor := Color("e8462e", 0.3 + 0.7 * calor)
		for j in 3:
			var x := 56.0 + j * 9.0
			var ondas := PackedVector2Array()
			for m in 13:
				var y := 236.0 - m * 9.0 - fmod(t * 20.0, 9.0)
				ondas.append(Vector2(x + sin(m * 1.3 + t * 4.0) * 3.0, y))
			l.draw_polyline(ondas, color_calor, 2.0, true)
	# Bimetal: dos láminas soldadas que se curvan hacia la que dilata menos.
	var punta := Vector2(lerpf(82.0, 152.0, k), lerpf(100.0, 96.0, k))
	for capa in 2:
		var desplazamiento := Vector2(6.0 * capa, 0.0)
		var puntos := PackedVector2Array()
		var c1 := Vector2(lerpf(74.0, 90.0, k), 200.0)
		var c2 := Vector2(lerpf(78.0, 112.0, k), 150.0)
		var base := Vector2(72.0, 250.0)
		for m in 17:
			var u := m / 16.0
			var a := base.lerp(c1, u).lerp(c1.lerp(c2, u), u)
			var b := c1.lerp(c2, u).lerp(c2.lerp(punta, u), u)
			puntos.append(a.lerp(b, u) + desplazamiento)
		var color := Color("c2412e").lerp(Color("e0563f"), k) if capa == 0 else Color("8a95a0")
		l.draw_polyline(puntos, color, 8.0 if capa == 0 else 6.0, true)
	texto(Vector2(96, 272), "Bimetal %s" % ("caliente: se curva" if k > 0.35 else "frío: recto"), 12, Tema.TINTA, false)
	# Barra de disparo empujada por la punta del bimetal.
	var barra_x := maxf(punta.x, 150.0)
	l.draw_style_box(Tema.caja(Color("6e7a83"), 4, 0, 0), Rect2(barra_x, 86, 120, 14))
	l.draw_line(Vector2(barra_x + 120, 93), Vector2(barra_x + 150, 93), Color("6e7a83"), 6.0)
	texto(Vector2(barra_x + 60, 74), "Barra de disparo", 12, Tema.TINTA)
	# Contactos auxiliares.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(298, 120, 100, 124))
	texto(Vector2(308, 142), "95-96 NC", 12, Tema.TINTA, false)
	_contacto(Vector2(308, 160), not disparado)
	texto(Vector2(308, 180), "abierto: para" if disparado else "cerrado: marcha", 11, Tema.FALLO if disparado else Tema.ACIERTO, false)
	texto(Vector2(308, 204), "97-98 NA", 12, Tema.TINTA, false)
	_contacto(Vector2(308, 222), disparado)
	texto(Vector2(308, 236), "cerrado: alarma" if disparado else "abierto", 11, Tema.ACIERTO if disparado else Color("5b6267"), false)
	# Botón de rearme y estado.
	l.draw_circle(Vector2(340, 284), 18.0, Color("2f7fd0"))
	l.draw_arc(Vector2(340, 284), 18.0, 0.0, TAU, 32, Color("1b4f86"), 2.0, true)
	texto(Vector2(340, 316), "Rearme", 12, Tema.TINTA)
	var rotulo := "DISPARADO" if disparado else "EN SERVICIO"
	l.draw_style_box(Tema.caja(Color("c0392b") if disparado else Tema.ACIERTO, 5, 0, 0), Rect2(150, 296, 120, 24))
	texto(Vector2(210, 308), rotulo, 12, Color.WHITE)
	# Reloj simulado.
	var reloj_texto := "%d min %02d s" % [int(reloj) / 60, int(reloj) % 60]
	_texto_derecha(Vector2(398, 36), "Tiempo: %s" % reloj_texto)
	if acelerado():
		_texto_derecha(Vector2(398, 52), "reloj × %d" % int(ACELERACION))
	l.draw_set_transform(Vector2.ZERO)


func _texto_derecha(posicion: Vector2, cadena: String) -> void:
	var fuente := get_theme_default_font()
	var ancho := fuente.get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	texto(Vector2(posicion.x - ancho, posicion.y), cadena, 12, Color("3b444b"), false)


func _contacto(origen: Vector2, cerrado_: bool) -> void:
	var l := lienzo
	l.draw_line(origen, origen + Vector2(22, 0), Tema.TINTA, 3.0)
	l.draw_line(origen + Vector2(46, 0), origen + Vector2(80, 0), Tema.TINTA, 3.0)
	var fin := origen + Vector2(48, 0) if cerrado_ else origen + Vector2(44, -12)
	l.draw_line(origen + Vector2(22, 0), fin, Tema.TINTA, 3.0, true)
