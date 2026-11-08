extends PantallaBanco
## Taller: banco libre, donde el jugador monta y guarda sus propios circuitos.

const PESTANAS := [["cajon", "Cajón"], ["pieza", "Pieza"], ["medir", "Medir"], ["archivo", "Archivo"]]
const TAMANO_CENTRADO := Vector2(300.0, 300.0)


func construir() -> void:
	if not args.has("mesa"):
		var nueva := MesaTaller.new(raiz.contenido)
		# Desde el Taller de un sistema se puede abrir con una plantilla ya montada.
		if args.has("plantilla"):
			nueva.cargar_plantilla(args["plantilla"])
		else:
			nueva.recuperar_autoguardado()
		_iniciar_banco(nueva, "cajon")
	_cabecera("Taller", "Toque dos bornes para unirlos con un cable")
	_montar_banco()


func _pestanas() -> Array:
	return PESTANAS


func _al_salir() -> void:
	super()
	mesa.autoguardar()


func _mostrar_panel(id: String) -> void:
	match id:
		"cajon":
			_panel_cajon()
		"pieza":
			_panel_pieza()
		"medir":
			_panel_medir()
		"archivo":
			_panel_archivo()


func _panel_cajon() -> void:
	_panel.add_child(_etiqueta("Toque un componente para ponerlo en la mesa. Arrastre las piezas para ordenarlas.", "Nota"))
	for e: Dictionary in mesa.catalogo():
		# Equipos que solo tienen sentido dentro de un tablero del buque, como el hidróforo.
		if e.get("oculto", false):
			continue
		var b := _boton(e["nombre"], _agregar.bind(e["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_panel.add_child(b)


## Coloca la pieza en el centro de la vista, con un pequeño desfase para que no se tapen.
func agregar_pieza(id_catalogo: String) -> String:
	var centro := vista.a_mesa(vista.size / 2.0)
	var desfase := Vector2(30.0, 30.0) * (mesa.piezas.size() % 5)
	var id := mesa.agregar(id_catalogo, centro - TAMANO_CENTRADO / 2.0 + desfase)
	args["pieza"] = id
	_actualizar_marcas()
	return id


func _agregar(id_catalogo: String) -> void:
	agregar_pieza(id_catalogo)


func _panel_pieza() -> void:
	var id: String = args["pieza"]
	var cable: int = args["cable"]
	if cable >= 0 and cable < mesa.sim.cables.size():
		var c: Array = mesa.sim.cables[cable]
		_panel.add_child(_etiqueta("Cable %s — %s" % [c[0], c[1]], "Subtitulo"))
		_panel.add_child(_selector_estilo_cable(cable))
		if mesa.tiene_mango(cable):
			_panel.add_child(_etiqueta("Arrastre el punto dorado para acomodarlo.", "Nota"))
		_panel.add_child(_boton("Quitar este cable", _quitar_cable.bind(cable)))
		return
	if id.is_empty() or not mesa.piezas.has(id):
		_panel.add_child(_etiqueta("Toque una pieza o un cable en la mesa para ver sus opciones.", "Nota"))
		return
	var e := mesa.entrada(mesa.piezas[id]["tipo"])
	_panel.add_child(_etiqueta("%s: %s" % [id, e["nombre"]], "Subtitulo"))
	_panel.add_child(_etiqueta(mesa.estado_pieza(id)))
	var c := mesa.sim.componente(id)
	match c.tipo():
		"fuente_trifasica":
			_panel.add_child(_boton("Conectar o desconectar barras", _alternar_barras.bind(id)))
			if c.estado["disparada"]:
				_panel.add_child(_boton("Rearmar interruptor", _rearmar_barras.bind(id)))
		"guardamotor":
			_panel.add_child(_boton("Abrir" if c.estado["encendido"] else "Cerrar", _alternar_guardamotor.bind(id)))
			_agregar_ajuste(c, "Ajuste térmico", 6.0, 40.0)
		"rele_termico":
			_panel.add_child(_boton("Rearmar", _rearmar_rele.bind(id)))
			_agregar_ajuste(c, "Ajuste", 6.0, 50.0)
		"pulsador":
			_agregar_pulsador(id)
		"arrancador_suave":
			_agregar_rearme_arrancador(c)
		"sensor_proximidad":
			_agregar_objeto_sensor(c)
		"plc":
			_agregar_mandos_plc(c)
		"motor_trifasico":
			_agregar_carga(c)
	if mesa.danada(id):
		_panel.add_child(_boton("Cambiar el repuesto", _reparar.bind(id)))
	_panel.add_child(_boton("Quitar de la mesa", _quitar.bind(id)))


func _selector_estilo_cable(cable: int) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	var grupo := ButtonGroup.new()
	var actual: String = mesa.ruta_cable(cable)["estilo"]
	for e: Array in [["curva", "Curva"], ["angulos", "Ángulos"], ["recta", "Recta"]]:
		var b := _boton(e[1], _elegir_estilo_cable.bind(cable, e[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(actual == e[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	return fila


func _elegir_estilo_cable(cable: int, estilo: String) -> void:
	mesa.fijar_estilo_cable(cable, estilo)
	vista.queue_redraw()
	_reconstruir_panel()


func _agregar_carga(c: SimComponente) -> void:
	var etiqueta := _etiqueta("Carga: %d %%" % roundi(float(c.params["carga"]) * 100.0))
	_panel.add_child(etiqueta)
	var control := HSlider.new()
	control.min_value = 0.0
	control.max_value = 1.6
	control.step = 0.05
	control.value = c.params["carga"]
	control.custom_minimum_size.y = 48.0
	control.value_changed.connect(func(v: float) -> void:
		c.params["carga"] = v
		etiqueta.text = "Carga: %d %%" % roundi(v * 100.0))
	_panel.add_child(control)
	var bloqueo := _boton("Liberar el rotor" if c.params["bloqueado"] else "Bloquear el rotor", _alternar_bloqueo.bind(c))
	_panel.add_child(bloqueo)


func _alternar_bloqueo(c: SimComponente) -> void:
	c.params["bloqueado"] = not c.params["bloqueado"]
	_reconstruir_panel()


func _alternar_barras(id: String) -> void:
	var c := mesa.sim.componente(id)
	c.estado["activa"] = not c.estado["activa"]
	_reconstruir_panel()


func _rearmar_barras(id: String) -> void:
	mesa.sim.componente(id).rearmar()
	_reconstruir_panel()


func _alternar_guardamotor(id: String) -> void:
	var c: SimGuardamotor = mesa.sim.componente(id)
	c.accionar(not c.estado["encendido"])
	_reconstruir_panel()


func _reparar(id: String) -> void:
	mesa.reparar(id)
	_reconstruir_panel()


func _quitar(id: String) -> void:
	mesa.quitar(id)
	args["pieza"] = ""
	if args["roja"].begins_with(id + "."):
		args["roja"] = ""
	if args["negra"].begins_with(id + "."):
		args["negra"] = ""
	args["primer_borne"] = ""
	_actualizar_marcas()
	_reconstruir_panel()


func _quitar_cable(indice: int) -> void:
	mesa.quitar_cable(indice)
	args["cable"] = -1
	_actualizar_marcas()
	_reconstruir_panel()


func _panel_archivo() -> void:
	_panel.add_child(_etiqueta("Plantillas", "Subtitulo"))
	for p: Dictionary in raiz.contenido.leer("taller.json").get("plantillas", []):
		_panel.add_child(_boton(p["nombre"], _cargar_plantilla.bind(p["id"])))
	_panel.add_child(_etiqueta("Sus circuitos", "Subtitulo"))
	var nombre := LineEdit.new()
	nombre.placeholder_text = "Nombre del circuito"
	nombre.custom_minimum_size.y = 48.0
	nombre.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.add_child(nombre)
	_panel.add_child(_boton("Guardar", func() -> void: _guardar(nombre.text)))
	for n: String in mesa.circuitos_guardados():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_panel.add_child(fila)
		var cargar := _boton(n, _cargar.bind(n))
		cargar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cargar.alignment = HORIZONTAL_ALIGNMENT_LEFT
		fila.add_child(cargar)
		var borrar := _boton("Borrar", _borrar.bind(n))
		borrar.autowrap_mode = TextServer.AUTOWRAP_OFF
		fila.add_child(borrar)
	_panel.add_child(_boton("Vaciar la mesa", _vaciar))


func _tras_cargar() -> void:
	args["pieza"] = ""
	args["cable"] = -1
	args["primer_borne"] = ""
	args["roja"] = ""
	args["negra"] = ""
	_actualizar_marcas()
	vista.encuadrar()


func _cargar_plantilla(id: String) -> void:
	mesa.cargar_plantilla(id)
	_tras_cargar()


func _guardar(nombre: String) -> void:
	if mesa.guardar(nombre):
		_reconstruir_panel()
	else:
		_mostrar_aviso("No se pudo guardar", "Escriba un nombre para el circuito.")


func _cargar(nombre: String) -> void:
	if mesa.cargar(nombre):
		_tras_cargar()
	else:
		_mostrar_aviso("No se pudo cargar", "El archivo del circuito está dañado.")


func _borrar(nombre: String) -> void:
	mesa.borrar(nombre)
	_reconstruir_panel()


func _vaciar() -> void:
	mesa.vaciar()
	_tras_cargar()


func _tocar_borne_sin_instrumento(nodo: String) -> void:
	var primero: String = args["primer_borne"]
	if primero.is_empty():
		args["primer_borne"] = nodo
		_estado.text = "%s: toque el otro borne" % nodo
	elif primero == nodo:
		args["primer_borne"] = ""
		_estado.text = ""
	else:
		var hecho := mesa.conectar(primero, nodo)
		args["primer_borne"] = ""
		_estado.text = "Cable %s — %s" % [primero, nodo] if hecho else "Ese cable ya existe"
	_actualizar_marcas()
