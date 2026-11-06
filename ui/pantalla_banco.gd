class_name PantallaBanco
extends Pantalla
## Base del Taller y de las misiones: la mesa con sus piezas, las pestañas laterales y los
## instrumentos. El estado vive en args para sobrevivir al giro del celular.

const MODOS_MULTIMETRO := [["vac", "V~"], ["vdc", "V="], ["ohm", "Ω"], ["continuidad", "Cont."], ["diodo", "Diodo"], ["a", "A"], ["ma", "mA="]]
const LECTURAS_POR_SEGUNDO := 4.0
## La vista tarda unos cuadros en tomar su tamaño final: mientras tanto se repite el encuadre.
const CUADROS_ENCUADRE := 4
const TAMANO_PESTANA_APRETADA := 14
const MARGEN_PESTANA_APRETADA := 4.0

var mesa: MesaTaller
var vista: VistaMesa
var _panel: VBoxContainer
var _desplazable_panel: ScrollContainer
var _estado: Label
var _lectura: Label
var _acumulado := 0.0
var _hasta_lectura := 0.0
var _cuadros_encuadre := 0
var _botones_pestana := {}


## Lista de [id, nombre] de las pestañas.
func _pestanas() -> Array:
	return []


func _mostrar_panel(_id: String) -> void:
	pass


func _opciones_instrumento() -> Array:
	return [["multimetro", "Multímetro"], ["megohmetro", "Megóhmetro"], ["pinza", "Pinza"], ["no", "Cablear"]]


## Una lectura ya tomada. Las misiones la registran como evidencia.
func _tras_medir(_instrumento: String, _modo: String, _a: String, _b: String, _resultado: Dictionary) -> void:
	pass


func _tocar_borne_sin_instrumento(_nodo: String) -> void:
	pass


func _proporcion_vista() -> float:
	return 1.6


func _iniciar_banco(nueva_mesa: MesaTaller, pestana: String, medicion := "") -> void:
	args["mesa"] = nueva_mesa
	args["pestana"] = pestana
	args["multimetro"] = SimMultimetro.new()
	args["megohmetro"] = SimMegohmetro.new()
	args["pinza"] = SimPinza.new()
	args["pinza_cables"] = []
	args["modo"] = "vac"
	args["v_prueba"] = 500
	args["pieza"] = ""
	args["primer_borne"] = ""
	args["roja"] = ""
	args["negra"] = ""
	args["cable"] = -1
	args["medicion"] = medicion
	_cuadros_encuadre = CUADROS_ENCUADRE


func _montar_banco() -> void:
	mesa = args["mesa"]
	_avisos = _columna(6)
	add_child(_avisos)
	var cuerpo: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 8)
	add_child(cuerpo)
	cuerpo.add_child(_crear_vista())
	cuerpo.add_child(_crear_lateral())
	_reconstruir_panel()
	_actualizar_marcas()
	tree_exiting.connect(_al_salir)
	if args.has("vista_zoom"):
		vista.zoom = args["vista_zoom"]
		vista.origen = args["vista_origen"]


## Conserva el encuadre al girar el celular.
func _al_salir() -> void:
	args["vista_zoom"] = vista.zoom
	args["vista_origen"] = vista.origen


func _crear_vista() -> Control:
	var contenedor := VBoxContainer.new()
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_stretch_ratio = _proporcion_vista()
	contenedor.add_theme_constant_override("separation", 6)
	vista = VistaMesa.new()
	vista.mesa = mesa
	vista.custom_minimum_size.y = 220.0
	vista.borne_tocado.connect(_al_tocar_borne)
	vista.pieza_tocada.connect(_al_tocar_pieza)
	vista.cable_tocado.connect(_al_tocar_cable)
	vista.fondo_tocado.connect(_al_tocar_fondo)
	contenedor.add_child(vista)
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 6)
	contenedor.add_child(barra)
	for d: Array in [["−", 1.0 / 1.25], ["+", 1.25]]:
		var b := _boton(d[0], _zoom.bind(d[1]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.custom_minimum_size.x = 56.0
		barra.add_child(b)
	var ver := _boton("Ver todo", func() -> void: vista.encuadrar())
	ver.autowrap_mode = TextServer.AUTOWRAP_OFF
	barra.add_child(ver)
	var ordenar := _boton("Ordenar cables", ordenar_cables)
	ordenar.autowrap_mode = TextServer.AUTOWRAP_OFF
	barra.add_child(ordenar)
	# En su propia línea y sin ajuste: en vertical no queda ancho junto a los botones.
	_estado = _etiqueta("", "Nota")
	_estado.autowrap_mode = TextServer.AUTOWRAP_OFF
	_estado.clip_text = true
	contenedor.add_child(_estado)
	return contenedor


func ordenar_cables() -> void:
	mesa.ordenar_cables()
	vista.queue_redraw()
	if args["cable"] >= 0:
		_reconstruir_panel()


func _zoom(factor: float) -> void:
	vista.cambiar_zoom(factor, vista.size / 2.0)


func _crear_lateral() -> Control:
	var lateral := _columna(6)
	lateral.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grupo := ButtonGroup.new()
	var pestanas := HBoxContainer.new()
	pestanas.add_theme_constant_override("separation", 4)
	lateral.add_child(pestanas)
	var muchas := _pestanas().size() > 4
	for p: Array in _pestanas():
		var b := _boton(p[1], _elegir_pestana.bind(p[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		if muchas:
			_apretar_pestana(b)
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["pestana"] == p[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pestanas.add_child(b)
		_botones_pestana[p[0]] = b
	_desplazable_panel = _desplazable()
	lateral.add_child(_desplazable_panel)
	_panel = _columna(8)
	_desplazable_panel.add_child(_panel)
	return lateral


## Sin esto, cinco pestañas ensancharían la pantalla más allá del celular.
func _apretar_pestana(b: Button) -> void:
	b.clip_text = true
	b.custom_minimum_size.y = 48.0
	for estado: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		if raiz.theme.has_stylebox(estado, "Button"):
			var caja: StyleBox = raiz.theme.get_stylebox(estado, "Button").duplicate()
			caja.content_margin_left = MARGEN_PESTANA_APRETADA
			caja.content_margin_right = MARGEN_PESTANA_APRETADA
			b.add_theme_stylebox_override(estado, caja)
	if raiz.vertical:
		b.add_theme_font_size_override("font_size", TAMANO_PESTANA_APRETADA)


func _elegir_pestana(id: String) -> void:
	args["pestana"] = id
	for clave: String in _botones_pestana:
		_botones_pestana[clave].set_pressed_no_signal(clave == id)
	_desplazable_panel.scroll_vertical = 0
	_reconstruir_panel()


func _reconstruir_panel() -> void:
	# La lista se rehace entera: sin esto, cada acción devolvería el desplazamiento al inicio.
	var desplazado := _desplazable_panel.scroll_vertical
	for hijo in _panel.get_children():
		_panel.remove_child(hijo)
		hijo.queue_free()
	_lectura = null
	_mostrar_panel(args["pestana"])
	_restaurar_desplazamiento.call_deferred(desplazado)


func _restaurar_desplazamiento(desplazado: int) -> void:
	if is_instance_valid(_desplazable_panel):
		_desplazable_panel.scroll_vertical = desplazado


func _agregar_ajuste(c: SimComponente, titulo: String, minimo: float, maximo: float) -> void:
	var etiqueta := _etiqueta("%s: %s A" % [titulo, TextoTecnico.numero(c.params["ajuste_a"], 1)])
	_panel.add_child(etiqueta)
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = 0.5
	control.value = c.params["ajuste_a"]
	control.custom_minimum_size.y = 48.0
	control.value_changed.connect(func(v: float) -> void:
		c.params["ajuste_a"] = v
		etiqueta.text = "%s: %s A" % [titulo, TextoTecnico.numero(v, 1)])
	_panel.add_child(control)


func _agregar_pulsador(id: String, texto := "Mantener pulsado") -> void:
	var pulsar := Button.new()
	pulsar.text = texto
	pulsar.set_meta("se_mantiene", true)
	pulsar.button_down.connect(_pulsar.bind(id, true))
	pulsar.button_up.connect(_pulsar.bind(id, false))
	_panel.add_child(pulsar)


func _pulsar(id: String, presionado: bool) -> void:
	if mesa.piezas.has(id):
		mesa.sim.componente(id).estado["presionado"] = presionado


func _rearmar_rele(id: String) -> void:
	if not mesa.sim.componente(id).rearmar():
		_mostrar_aviso("Todavía caliente", "El relé no rearma hasta enfriarse. Aproveche para buscar la causa del disparo.")
	_reconstruir_panel()


func _panel_medir() -> void:
	var grupo := ButtonGroup.new()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_panel.add_child(fila)
	var opciones := _opciones_instrumento()
	for i: Array in opciones:
		var b := _boton(i[1], _elegir_instrumento.bind(i[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		if opciones.size() > 3:
			_apretar_pestana(b)
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["medicion"] == i[0] or (args["medicion"] == "" and i[0] == "no"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	if args["medicion"] == "multimetro":
		_panel_multimetro()
	elif args["medicion"] == "megohmetro":
		_panel_megohmetro()
	elif args["medicion"] == "pinza":
		_panel_pinza()
	else:
		_panel.add_child(_etiqueta("Elija un instrumento. Después, toque dos bornes para colocar las puntas.", "Nota"))


func _elegir_instrumento(id: String) -> void:
	args["medicion"] = "" if id == "no" else id
	args["primer_borne"] = ""
	args["roja"] = ""
	args["negra"] = ""
	args["pinza_cables"] = []
	_actualizar_marcas()
	_reconstruir_panel()


func _pantalla_instrumento() -> Label:
	var tarjeta := _tarjeta_base("Papel")
	_panel.add_child(tarjeta)
	_lectura = _etiqueta("---", "Titulo")
	_lectura.add_theme_color_override("font_color", Tema.TINTA)
	_lectura.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tarjeta.add_child(_lectura)
	return _lectura


func _panel_multimetro() -> void:
	_pantalla_instrumento()
	var grupo := ButtonGroup.new()
	# Siete modos no caben en una línea de un celular vertical: pasan a la siguiente.
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 4)
	fila.add_theme_constant_override("v_separation", 4)
	_panel.add_child(fila)
	for m: Array in MODOS_MULTIMETRO:
		var b := _boton(m[1], _elegir_modo.bind(m[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		_apretar_pestana(b)
		# Sin recortar: cada modo ocupa su ancho y los que no caben bajan de línea.
		b.clip_text = false
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["modo"] == m[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	_panel.add_child(_etiqueta("Antes de pasar a Ω o A, compruebe que el modo sea adecuado: un error daña el instrumento.", "Nota"))
	var m: SimMultimetro = args["multimetro"]
	if not m.fusible_ok and not m.destruido:
		_panel.add_child(_boton("Cambiar el fusible del multímetro", _cambiar_fusible))
	if m.destruido:
		_panel.add_child(_boton("Usar un multímetro nuevo", _multimetro_nuevo))


func _elegir_modo(id: String) -> void:
	args["modo"] = id
	_hasta_lectura = 0.0


func _cambiar_fusible() -> void:
	args["multimetro"].cambiar_fusible()
	_reconstruir_panel()


func _multimetro_nuevo() -> void:
	args["multimetro"] = SimMultimetro.new()
	_reconstruir_panel()


func _panel_megohmetro() -> void:
	_pantalla_instrumento()
	var grupo := ButtonGroup.new()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_panel.add_child(fila)
	for v: int in SimMegohmetro.TENSIONES:
		var b := _boton("%d V" % v, _elegir_v_prueba.bind(v))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["v_prueba"] == v)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	_panel.add_child(_boton("Realizar la prueba", medir_aislamiento))
	if args["megohmetro"].destruido:
		_panel.add_child(_boton("Usar un megóhmetro nuevo", _megohmetro_nuevo))
	_panel.add_child(_etiqueta("Devanados de menos de 1 kV: mínimo 5 MΩ según IEEE 43. Verificar el criterio del buque.", "Nota"))


func _panel_pinza() -> void:
	_pantalla_instrumento()
	var abrazados: Array = args["pinza_cables"]
	if abrazados.is_empty():
		_panel.add_child(_etiqueta("Toque un cable de la mesa para abrazarlo con la pinza.", "Nota"))
	else:
		var nombres := PackedStringArray()
		for i: int in abrazados:
			nombres.append("%s — %s" % mesa.sim.cables[i])
		_panel.add_child(_etiqueta("Abraza: %s" % ", ".join(nombres)))
		_panel.add_child(_boton("Soltar la pinza", _soltar_pinza))
	_panel.add_child(_etiqueta("Abrace un solo conductor. Con las tres fases de un mismo circuito, las corrientes se anulan y la pinza marca casi cero. Rango de 400 A y resolución de 0,1 A: valores típicos, verificar con la pinza del buque.", "Nota"))


## Tocar un cable lo añade a la pinza; tocarlo de nuevo lo saca.
func _abrazar_cable(indice: int) -> void:
	var abrazados: Array = args["pinza_cables"]
	if abrazados.has(indice):
		abrazados.erase(indice)
	else:
		abrazados.append(indice)
	_hasta_lectura = 0.0
	if args["pestana"] != "medir":
		_elegir_pestana("medir")
	else:
		_reconstruir_panel()
	_actualizar_marcas()


func _soltar_pinza() -> void:
	args["pinza_cables"] = []
	_reconstruir_panel()
	_actualizar_marcas()


func _elegir_v_prueba(v: int) -> void:
	args["v_prueba"] = v


func _megohmetro_nuevo() -> void:
	args["megohmetro"] = SimMegohmetro.new()
	_reconstruir_panel()


## El megóhmetro solo mide a petición: aplica tensión y no debe hacerlo continuamente.
func medir_aislamiento() -> void:
	if args["roja"].is_empty() or args["negra"].is_empty():
		_mostrar_aviso("Faltan las puntas", "Toque dos bornes o puntos de la mesa para colocar las puntas.")
		return
	var r: Dictionary = args["megohmetro"].medir(mesa.sim, args["roja"], args["negra"], args["v_prueba"])
	_tras_medir("megohmetro", str(args["v_prueba"]), args["roja"], args["negra"], r)
	_revisar_eventos()
	if _lectura == null:
		return
	if not r["averia"].is_empty():
		_lectura.text = "AVERIADO"
	else:
		var valor := "> 999" if r["fuera_de_rango"] else TextoTecnico.numero(r["mohm"], 2)
		_lectura.text = "%s MΩ  %s" % [valor, "aceptable" if r["aceptable"] else "bajo"]
	if args["megohmetro"].destruido:
		_reconstruir_panel()


func _actualizar_lectura() -> void:
	if args["medicion"] == "pinza" and _lectura != null:
		_actualizar_lectura_pinza()
		return
	if args["medicion"] != "multimetro" or _lectura == null:
		return
	if args["roja"].is_empty() or args["negra"].is_empty():
		_lectura.text = "Coloque las puntas"
		return
	var m: SimMultimetro = args["multimetro"]
	var estaba_bien := m.fusible_ok and not m.destruido
	var r: Dictionary = m.medir(mesa.sim, args["modo"], args["roja"], args["negra"])
	_tras_medir("multimetro", args["modo"], args["roja"], args["negra"], r)
	if not r["averia"].is_empty():
		_lectura.text = "AVERIADO" if m.destruido else "Fusible fundido"
	elif r["fuera_de_rango"]:
		_lectura.text = "OL"
	else:
		var decimales := 3 if absf(float(r["valor"])) < 10.0 else 1
		var pita := "  · continuidad" if r.get("pita", false) else ""
		_lectura.text = "%s %s%s" % [TextoTecnico.numero(r["valor"], decimales), r["unidad"], pita]
	if estaba_bien and not (m.fusible_ok and not m.destruido):
		_reconstruir_panel()


func _actualizar_lectura_pinza() -> void:
	var abrazados: Array = args["pinza_cables"]
	if abrazados.is_empty():
		_lectura.text = "Abrace un cable"
		return
	var r: Dictionary = args["pinza"].medir(mesa.sim, abrazados)
	var primero: Array = mesa.sim.cables[abrazados[0]]
	_tras_medir("pinza", "a" if abrazados.size() == 1 else "a_varios", primero[0], primero[1], r)
	if r["fuera_de_rango"]:
		_lectura.text = "OL"
	else:
		_lectura.text = "%s A" % TextoTecnico.numero(r["valor"], 1)


func _al_tocar_borne(nodo: String) -> void:
	if args["medicion"] == "pinza":
		_estado.text = "La pinza no tiene puntas: se coloca abrazando un cable."
		return
	if args["medicion"] != "":
		_colocar_punta(nodo)
	else:
		_tocar_borne_sin_instrumento(nodo)


func _colocar_punta(nodo: String) -> void:
	if args["roja"].is_empty() or not args["negra"].is_empty():
		args["roja"] = nodo
		args["negra"] = ""
	else:
		args["negra"] = nodo
	_hasta_lectura = 0.0
	_actualizar_marcas()


func _al_tocar_pieza(id: String) -> void:
	args["pieza"] = id
	args["cable"] = -1
	args["primer_borne"] = ""
	_elegir_pestana("pieza")
	_actualizar_marcas()


func _al_tocar_cable(indice: int) -> void:
	if args["medicion"] == "pinza":
		_abrazar_cable(indice)
		return
	args["cable"] = indice
	args["pieza"] = ""
	_elegir_pestana("pieza")
	_actualizar_marcas()


func _al_tocar_fondo() -> void:
	args["primer_borne"] = ""
	args["pieza"] = ""
	args["cable"] = -1
	_estado.text = ""
	_actualizar_marcas()


func _actualizar_marcas() -> void:
	vista.borne_marcado = args["primer_borne"]
	vista.punta_roja = args["roja"]
	vista.punta_negra = args["negra"]
	vista.pieza_marcada = args["pieza"]
	vista.cable_marcado = args["cable"]
	vista.cables_pinza = args.get("pinza_cables", [])
	vista.queue_redraw()


func _process(delta: float) -> void:
	if mesa == null or vista == null:
		return
	if _cuadros_encuadre > 0:
		_cuadros_encuadre -= 1
		vista.encuadrar()
	_avanzar_simulacion(delta)
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / LECTURAS_POR_SEGUNDO
		_actualizar_lectura()


func _avanzar_simulacion(delta: float) -> void:
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), 3)
	if pasos > 0:
		_acumulado = 0.0
		mesa.avanzar(pasos)
		_revisar_eventos()
		vista.queue_redraw()


func _revisar_eventos() -> void:
	var textos: Dictionary = raiz.contenido.leer("taller.json").get("consecuencias", {})
	for e: Dictionary in mesa.eventos_nuevos():
		vista.mostrar_evento(e["tipo"], e["componente"])
		var c: Dictionary = textos.get(e["tipo"], {})
		if not c.is_empty():
			var quien: String = e["componente"]
			_mostrar_aviso("%s (%s)" % [c["titulo"], quien] if mesa.piezas.has(quien) else c["titulo"], c["texto"])


