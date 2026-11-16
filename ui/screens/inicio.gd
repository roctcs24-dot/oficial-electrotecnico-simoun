extends Pantalla
## Pantalla de inicio: saludo con el rango, la lección recomendada para continuar, el repaso
## pendiente y una tarjeta de color por cada sistema del buque.

const LADO_AVATAR := 52.0
const LADO_PLAY := 54.0


func construir() -> void:
	var c := raiz.contenido
	var avisos := _columna(6)
	if not raiz.partida.aviso.is_empty():
		avisos.add_child(_aviso(raiz.partida.aviso))
	for error in c.errores:
		avisos.add_child(_aviso(error))
	# En vertical, todo en una columna desplazable; en horizontal, el saludo y lo recomendado a
	# la izquierda y las tarjetas de los sistemas a la derecha.
	var izquierda := _columna(12)
	var derecha := _columna(12)
	if raiz.vertical:
		add_child(_crear_saludo())
		add_child(avisos)
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(12)
		desplazable.add_child(_ancho_lectura(columna))
		izquierda = columna
		derecha = columna
	else:
		var cuerpo := HBoxContainer.new()
		cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_theme_constant_override("separation", 14)
		add_child(cuerpo)
		var lado := _desplazable()
		lado.size_flags_stretch_ratio = 0.8
		cuerpo.add_child(lado)
		lado.add_child(izquierda)
		izquierda.add_child(_crear_saludo())
		izquierda.add_child(avisos)
		var principal := _desplazable()
		cuerpo.add_child(principal)
		principal.add_child(derecha)
	var siguiente := Ruta.siguiente(c, raiz.partida)
	if not siguiente.is_empty():
		izquierda.add_child(_crear_continuar(siguiente))
	var pendientes := raiz.partida.temas_pendientes().size()
	if pendientes > 0:
		izquierda.add_child(_fila("Repaso de hoy", "%d temas que conviene repasar" % pendientes, raiz.ir_a_seccion.bind("repaso"), "repaso", str(pendientes), true, {"color": Tema.ACENTO_FUERTE}))
	derecha.add_child(_rotulo("Sistemas del buque"))
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", 10)
	rejilla.add_theme_constant_override("v_separation", 10)
	derecha.add_child(rejilla)
	for s: Dictionary in c.sistemas():
		if s.get("estado", "") == "activo":
			rejilla.add_child(_tarjeta_sistema(s))
	var mas := derecha if raiz.vertical else izquierda
	mas.add_child(_rotulo("Más"))
	mas.add_child(_fila("Plano del buque, tableros y exámenes", "El barco por zonas, sus tableros reales y los exámenes", raiz.ir_a_seccion.bind("plano_barco"), "buque", "", true, {"color": Tema.SELECCION}))


func _crear_saludo() -> Control:
	var rangos := raiz.contenido.rangos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	var rango := raiz.partida.rango(rangos)
	var avatar := Avatar.new()
	avatar.inicial = rango.substr(0, 1)
	avatar.avance = raiz.partida.progreso_rango(rangos)
	avatar.custom_minimum_size = Vector2(LADO_AVATAR, LADO_AVATAR)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(avatar)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	textos.add_child(_etiqueta(_resumen_barco(raiz.contenido.barco()), "Nota"))
	textos.add_child(_etiqueta(rango, "Titulo"))
	var proximo := raiz.partida.siguiente_rango(rangos)
	var puntos := "%d pts" % int(raiz.partida.datos["puntos"])
	if not proximo.is_empty():
		puntos += " · %d para %s" % [proximo["faltan"], proximo["nombre"]]
	var e := _etiqueta(puntos, "Nota")
	e.add_theme_color_override("font_color", Tema.ACENTO)
	textos.add_child(e)
	return fila


## Tarjeta con la lección recomendada y un botón redondo para abrirla.
func _crear_continuar(siguiente: Dictionary) -> Control:
	var s := raiz.contenido.sistema(siguiente["sistema"])
	var l := raiz.contenido.leccion(siguiente["leccion"])
	var color := Tema.color_area(s)
	var tarjeta := _tarjeta_base()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_TARJETA, 14, 12, Color(color, 0.7)))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	tarjeta.add_child(fila)
	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_theme_stylebox_override("panel", Tema.caja(Color(color, 0.22), 14, 12, 12))
	var icono := VistaSvg.new()
	icono.cargar({"svg": "res://art/iconos/sistema_%d.svg" % int(s["id"]), "tamano": [64, 64]})
	icono.custom_minimum_size = Vector2(30, 30)
	icono.modulate = color.lightened(0.35)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(icono)
	fila.add_child(caja)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	var rotulo := _etiqueta("CONTINUAR", "Rotulo")
	rotulo.add_theme_color_override("font_color", Tema.ACENTO_FUERTE)
	textos.add_child(rotulo)
	textos.add_child(_etiqueta(l.get("titulo", siguiente["leccion"]), "Subtitulo"))
	textos.add_child(_etiqueta("%s · lección %d de %d · %d min" % [s.get("nombre", ""), siguiente["numero"], siguiente["total"], int(l.get("minutos", 0))], "Nota"))
	var play := _boton("", _abrir_leccion.bind(siguiente))
	play.icon = _icono_play()
	play.custom_minimum_size = Vector2(LADO_PLAY, LADO_PLAY)
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play.tooltip_text = "Continuar la lección"
	for estado in ["normal", "hover", "pressed", "hover_pressed"]:
		play.add_theme_stylebox_override(estado, Tema.caja(Tema.ACENTO_FUERTE.darkened(0.15 if estado.begins_with("pressed") else 0.0), int(LADO_PLAY / 2.0), 0, 0))
	fila.add_child(play)
	return tarjeta


func _abrir_leccion(siguiente: Dictionary) -> void:
	raiz.ir_a("sistema", {"id": siguiente["sistema"]})
	raiz.ir_a("leccion", {"id": siguiente["leccion"], "sistema": siguiente["sistema"]})


func _tarjeta_sistema(s: Dictionary) -> TarjetaArea:
	var t := TarjetaArea.new()
	var id := int(s["id"])
	var lecciones := Avance.lecciones(s, raiz.partida)
	var misiones := Avance.misiones(s, raiz.partida)
	var detalle := "%d de %d lecciones" % lecciones
	if misiones[1] > 0:
		detalle += " · %d de %d misiones" % misiones
	t.iniciar_area(s.get("nombre", ""), detalle, "sistema_%d" % id, Tema.color_area(s), Avance.fraccion(Avance.sistema(s, raiz.partida)))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.pulsada.connect(raiz.ir_a.bind("sistema", {"id": id}))
	return t


## Triángulo de reproducción dibujado como imagen, oscuro sobre el botón amarillo.
func _icono_play() -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 48:
		for x in 48:
			var dx := float(x) - 17.0
			var dy := absf(float(y) - 24.0)
			if dx >= 0.0 and dx <= 18.0 and dy <= 12.0 * (1.0 - dx / 18.0):
				img.set_pixel(x, y, Tema.FONDO)
	return ImageTexture.create_from_image(img)


func _resumen_barco(barco: Dictionary) -> String:
	if not barco.has("red_principal"):
		return barco.get("nombre", "")
	var red: Dictionary = barco["red_principal"]
	return "%s · %d V · %d Hz" % [barco.get("nombre", "B/P Vía Simoun"), red["tension_v"]["valor"], red["frecuencia_hz"]["valor"]]
