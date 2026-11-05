extends Pantalla
## Taller: banco libre. La mesa vive en args para sobrevivir al giro del celular.

const PESTANAS := [["cajon", "Cajón"], ["pieza", "Pieza"], ["medir", "Medir"], ["archivo", "Archivo"]]
const MODOS_MULTIMETRO := [["vac", "V~"], ["vdc", "V="], ["ohm", "Ω"], ["continuidad", "Cont."], ["a", "A"]]
const LECTURAS_POR_SEGUNDO := 4.0
const TAMANO_CENTRADO := Vector2(300.0, 300.0)

var mesa: MesaTaller
var vista: VistaMesa
var _panel: VBoxContainer
var _avisos: VBoxContainer
var _estado: Label
var _lectura: Label
var _acumulado := 0.0
var _hasta_lectura := 0.0
var _encuadre_pendiente := false
var _botones_pestana := {}


func construir() -> void:
	if not args.has("mesa"):
		args["mesa"] = MesaTaller.new(raiz.contenido)
		args["mesa"].recuperar_autoguardado()
		args["pestana"] = "cajon"
		args["multimetro"] = SimMultimetro.new()
		args["megohmetro"] = SimMegohmetro.new()
		args["instrumento"] = "multimetro"
		args["modo"] = "vac"
		args["v_prueba"] = 500
		args["pieza"] = ""
		args["primer_borne"] = ""
		args["roja"] = ""
		args["negra"] = ""
		args["cable"] = -1
		args["medicion"] = ""
		_encuadre_pendiente = true
	mesa = args["mesa"]
	_cabecera("Taller", "Toque dos bornes para unirlos con un cable")
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
	if _encuadre_pendiente:
		vista.resized.connect(_encuadrar_una_vez, CONNECT_ONE_SHOT)
	elif args.has("vista_zoom"):
		vista.zoom = args["vista_zoom"]
		vista.origen = args["vista_origen"]


## Conserva el encuadre al girar el celular.
func _al_salir() -> void:
	args["vista_zoom"] = vista.zoom
	args["vista_origen"] = vista.origen
	mesa.autoguardar()


func _encuadrar_una_vez() -> void:
	vista.encuadrar()


func _crear_vista() -> Control:
	var contenedor := VBoxContainer.new()
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_stretch_ratio = 1.6
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
	_estado = _etiqueta("", "Nota")
	_estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(_estado)
	return contenedor


func _zoom(factor: float) -> void:
	vista.cambiar_zoom(factor, vista.size / 2.0)


func _crear_lateral() -> Control:
	var lateral := _columna(6)
	lateral.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grupo := ButtonGroup.new()
	var pestanas := HBoxContainer.new()
	pestanas.add_theme_constant_override("separation", 4)
	lateral.add_child(pestanas)
	for p: Array in PESTANAS:
		var b := _boton(p[1], _elegir_pestana.bind(p[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["pestana"] == p[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pestanas.add_child(b)
		_botones_pestana[p[0]] = b
	var desplazable := _desplazable()
	lateral.add_child(desplazable)
	_panel = _columna(8)
	desplazable.add_child(_panel)
	return lateral


func _elegir_pestana(id: String) -> void:
	args["pestana"] = id
	for clave: String in _botones_pestana:
		_botones_pestana[clave].set_pressed_no_signal(clave == id)
	_reconstruir_panel()


func _reconstruir_panel() -> void:
	for hijo in _panel.get_children():
		_panel.remove_child(hijo)
		hijo.queue_free()
	_lectura = null
	match args["pestana"]:
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
			var pulsar := Button.new()
			pulsar.text = "Mantener pulsado"
			pulsar.set_meta("se_mantiene", true)
			pulsar.button_down.connect(_pulsar.bind(id, true))
			pulsar.button_up.connect(_pulsar.bind(id, false))
			_panel.add_child(pulsar)
		"motor_trifasico":
			_agregar_carga(c)
	if mesa.danada(id):
		_panel.add_child(_boton("Cambiar el repuesto", _reparar.bind(id)))
	_panel.add_child(_boton("Quitar de la mesa", _quitar.bind(id)))


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


func _rearmar_rele(id: String) -> void:
	if not mesa.sim.componente(id).rearmar():
		_mostrar_aviso("Todavía caliente", "El relé no rearma hasta enfriarse. Aproveche para buscar la causa del disparo.")
	_reconstruir_panel()


func _pulsar(id: String, presionado: bool) -> void:
	if mesa.piezas.has(id):
		mesa.sim.componente(id).estado["presionado"] = presionado


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


func _panel_medir() -> void:
	var grupo := ButtonGroup.new()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_panel.add_child(fila)
	for i: Array in [["multimetro", "Multímetro"], ["megohmetro", "Megóhmetro"], ["no", "Cablear"]]:
		var b := _boton(i[1], _elegir_instrumento.bind(i[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["medicion"] == i[0] or (args["medicion"] == "" and i[0] == "no"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	if args["medicion"] == "multimetro":
		_panel_multimetro()
	elif args["medicion"] == "megohmetro":
		_panel_megohmetro()
	else:
		_panel.add_child(_etiqueta("Elija un instrumento. Después, toque dos bornes para colocar las puntas.", "Nota"))


func _elegir_instrumento(id: String) -> void:
	args["medicion"] = "" if id == "no" else id
	args["primer_borne"] = ""
	args["roja"] = ""
	args["negra"] = ""
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
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_panel.add_child(fila)
	for m: Array in MODOS_MULTIMETRO:
		var b := _boton(m[1], _elegir_modo.bind(m[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
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
	_panel.add_child(_etiqueta("Criterio habitual en baja tensión: mínimo 1 MΩ. Verificar el criterio del buque.", "Nota"))


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
	if args["medicion"] != "multimetro" or _lectura == null:
		return
	if args["roja"].is_empty() or args["negra"].is_empty():
		_lectura.text = "Coloque las puntas"
		return
	var m: SimMultimetro = args["multimetro"]
	var estaba_bien := m.fusible_ok and not m.destruido
	var r: Dictionary = m.medir(mesa.sim, args["modo"], args["roja"], args["negra"])
	if not r["averia"].is_empty():
		_lectura.text = "AVERIADO" if m.destruido else "Fusible fundido"
	elif r["fuera_de_rango"]:
		_lectura.text = "OL"
	else:
		var decimales := 3 if float(r["valor"]) < 10.0 else 1
		var pita := "  ♪" if r.get("pita", false) else ""
		_lectura.text = "%s %s%s" % [TextoTecnico.numero(r["valor"], decimales), r["unidad"], pita]
	if estaba_bien and not (m.fusible_ok and not m.destruido):
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


func _al_tocar_borne(nodo: String) -> void:
	if args["medicion"] != "":
		_colocar_punta(nodo)
		return
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
	_elegir_pieza_en_panel()


func _al_tocar_cable(indice: int) -> void:
	args["cable"] = indice
	args["pieza"] = ""
	_elegir_pieza_en_panel()


func _elegir_pieza_en_panel() -> void:
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
	vista.queue_redraw()


func _process(delta: float) -> void:
	if mesa == null:
		return
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), 3)
	if pasos > 0:
		_acumulado = 0.0
		mesa.avanzar(pasos)
		_revisar_eventos()
		vista.queue_redraw()
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / LECTURAS_POR_SEGUNDO
		_actualizar_lectura()


func _revisar_eventos() -> void:
	var textos: Dictionary = raiz.contenido.leer("taller.json").get("consecuencias", {})
	for e: Dictionary in mesa.eventos_nuevos():
		var c: Dictionary = textos.get(e["tipo"], {})
		if not c.is_empty():
			var quien: String = e["componente"]
			_mostrar_aviso("%s (%s)" % [c["titulo"], quien] if mesa.piezas.has(quien) else c["titulo"], c["texto"])


func _mostrar_aviso(titulo: String, texto: String) -> void:
	for hijo in _avisos.get_children():
		if hijo.get_meta("titulo", "") == titulo:
			return
	var caja := _tarjeta_base("Aviso")
	caja.set_meta("titulo", titulo)
	_avisos.add_child(caja)
	var columna := _columna(4)
	caja.add_child(columna)
	columna.add_child(_etiqueta(titulo, "Subtitulo"))
	columna.add_child(_etiqueta(texto))
	columna.add_child(_boton("Entendido", caja.queue_free))
