extends PantallaBanco
## Un tablero del buque. Por fuera, su frente con los mandos reales: se pulsan, se giran y se
## leen sus luces. Con la puerta abierta, el mismo circuito aparece en la mesa del Taller, donde se
## mide con los instrumentos y se ajustan las protecciones. El estado vive en args para
## sobrevivir al giro del celular.

const PESTANAS := [["mando", "Mando"], ["medir", "Medir"], ["pieza", "Equipo"], ["datos", "Datos"]]
const INSTRUMENTOS := [["multimetro", "Multímetro"], ["megohmetro", "Megóhmetro"], ["pinza", "Pinza"]]

var tablero := {}
var frente: VistaTablero
var _caja_mesa: Control
var _barra_frente: HBoxContainer
var _boton_puerta: Button


func construir() -> void:
	tablero = raiz.contenido.tablero(args["tablero"])
	if not args.has("mesa"):
		var nueva := MesaTaller.new(raiz.contenido)
		nueva.cargar_circuito(raiz.contenido.leer("circuitos/%s.json" % tablero["circuito"]), tablero["interior"])
		_iniciar_banco(nueva, "mando")
		args["puerta"] = false
	_cabecera(tablero["titulo"], tablero.get("ubicacion", ""))
	_montar_banco()


func _pestanas() -> Array:
	return PESTANAS


func _opciones_instrumento() -> Array:
	return INSTRUMENTOS


## El frente necesita más sitio que el panel de mandos.
func _proporcion_vista() -> float:
	return 1.8


func _crear_vista() -> Control:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = _proporcion_vista()
	caja.add_theme_constant_override("separation", 6)
	_boton_puerta = _boton("", _alternar_puerta)
	caja.add_child(_boton_puerta)
	frente = VistaTablero.new()
	frente.datos = tablero["frente"]
	frente.sim = mesa.sim
	frente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frente.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frente.custom_minimum_size.y = 280.0
	frente.elemento_tocado.connect(_al_tocar_elemento)
	frente.elemento_soltado.connect(_al_soltar_elemento)
	caja.add_child(frente)
	_barra_frente = HBoxContainer.new()
	_barra_frente.add_theme_constant_override("separation", 6)
	caja.add_child(_barra_frente)
	for d: Array in [["−", 1.0 / 1.25], ["+", 1.25]]:
		var b := _boton(d[0], func() -> void: frente.cambiar_zoom(d[1], frente.size / 2.0))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.custom_minimum_size.x = 56.0
		_barra_frente.add_child(b)
	var todo := _boton("Ver todo", func() -> void: frente.encuadrar())
	todo.autowrap_mode = TextServer.AUTOWRAP_OFF
	_barra_frente.add_child(todo)
	if args.has("frente_zoom"):
		frente.zoom = args["frente_zoom"]
		frente.desplazamiento = args["frente_desplazamiento"]
	_caja_mesa = super._crear_vista()
	caja.add_child(_caja_mesa)
	_aplicar_puerta()
	return caja


func _alternar_puerta() -> void:
	args["puerta"] = not args["puerta"]
	_aplicar_puerta()
	_reconstruir_panel()


func _aplicar_puerta() -> void:
	var abierta: bool = args["puerta"]
	_boton_puerta.text = "Cerrar la puerta y ver el frente" if abierta else "Abrir la puerta y ver el interior"
	frente.visible = not abierta
	_barra_frente.visible = not abierta
	_caja_mesa.visible = abierta
	if abierta:
		_cuadros_encuadre = CUADROS_ENCUADRE


func _al_salir() -> void:
	super()
	args["frente_zoom"] = frente.zoom
	args["frente_desplazamiento"] = frente.desplazamiento


func _process(delta: float) -> void:
	super(delta)
	if frente != null and frente.visible:
		frente.queue_redraw()


# --- Mandos del frente ---

func _elemento(indice: int) -> Dictionary:
	return tablero["frente"]["elementos"][indice]


func _al_tocar_elemento(indice: int, lado: int) -> void:
	accionar(indice, lado)


func _al_soltar_elemento(indice: int) -> void:
	soltar(indice)


## Acción sobre un elemento del frente: pulsar, girar un selector, enclavar o liberar la seta, o
## maniobrar el interruptor general. Devuelve false si el candado lo impide.
func accionar(indice: int, lado := 1) -> bool:
	var e := _elemento(indice)
	var c := mesa.sim.componente(e["componente"])
	var hecho := true
	match e["tipo"]:
		"pulsador":
			c.estado["presionado"] = true
		"selector":
			(c as SimSelector).girar(lado)
		"seta":
			var seta := c as SimSeta
			if seta.estado["enclavada"]:
				seta.liberar()
			else:
				seta.pulsar()
		"seccionador":
			var q := c as SimSeccionador
			hecho = q.accionar(not q.cerrado())
			if not hecho:
				_mostrar_aviso("Interruptor bloqueado", "Tiene puesto el candado de bloqueo y su tarjeta. Solo lo retira quien lo puso, cuando termina el trabajo.")
	if args["pestana"] == "mando":
		_reconstruir_panel()
	return hecho


func soltar(indice: int) -> void:
	var e := _elemento(indice)
	var c := mesa.sim.componente(e["componente"])
	match e["tipo"]:
		"pulsador":
			c.estado["presionado"] = false
		"selector":
			(c as SimSelector).soltar()


# --- Paneles ---

func _mostrar_panel(id: String) -> void:
	match id:
		"mando":
			_panel_mando()
		"medir":
			if not args["puerta"]:
				_panel.add_child(_etiqueta("Para medir, abra la puerta: los bornes están dentro del tablero.", "Nota"))
			_panel_medir()
		"pieza":
			_panel_pieza()
		"datos":
			_panel_datos()


func _panel_mando() -> void:
	_panel.add_child(_etiqueta("Pulse, gire y lea los mandos en el frente del tablero. Un pulsador funciona mientras lo mantiene tocado; un selector gira hacia el lado que toque.", "Nota"))
	var id_q: String = tablero.get("alimentacion", "")
	if not id_q.is_empty():
		var q: SimSeccionador = mesa.sim.componente(id_q)
		_panel.add_child(_rotulo("Alimentación del tablero"))
		var estado := "cerrado, con tensión" if q.cerrado() else "abierto, sin tensión"
		if q.estado["candado"]:
			estado += ", con candado y tarjeta"
		_panel.add_child(_etiqueta("Interruptor de alimentación %s: %s." % [id_q, estado]))
		_panel.add_child(_boton("Abrir el interruptor de alimentación" if q.cerrado() else "Cerrar el interruptor de alimentación", _maniobrar_alimentacion))
		if not q.cerrado():
			_panel.add_child(_boton("Quitar el candado y la tarjeta" if q.estado["candado"] else "Poner candado y tarjeta de bloqueo", _alternar_candado))
	var protecciones := false
	for id: String in mesa.piezas:
		var c := mesa.sim.componente(id)
		if c.tipo() in ["guardamotor", "rele_termico"] and c.estado.get("disparado", false):
			if not protecciones:
				_panel.add_child(_rotulo("Protecciones disparadas"))
				protecciones = true
			if c.tipo() == "rele_termico":
				_panel.add_child(_boton("Rearmar el relé térmico %s" % id, _rearmar_rele.bind(id)))
			else:
				_panel.add_child(_boton("Rearmar el guardamotor %s" % id, _rearmar_guardamotor.bind(id)))
	var senales: Array = tablero.get("senales", [])
	if not senales.is_empty():
		_panel.add_child(_rotulo("Señales de otros equipos"))
		for s: Dictionary in senales:
			var sel: SimSelector = mesa.sim.componente(s["componente"])
			var activa := sel.cerrado("13-14")
			_panel.add_child(_etiqueta("%s: %s." % [s["texto"], "dada" if activa else "sin orden"]))
			_panel.add_child(_boton("Quitar la orden" if activa else "Dar la orden", _alternar_senal.bind(s["componente"])))
	var averias: Array = tablero.get("averias", [])
	if not averias.is_empty():
		_panel.add_child(_rotulo("Averías de práctica"))
		for a: Dictionary in averias:
			var puesta := _averia_puesta(a)
			_panel.add_child(_boton(("Quitar: " if puesta else "Provocar: ") + str(a["texto"]), _alternar_averia.bind(a)))


func _maniobrar_alimentacion() -> void:
	var q: SimSeccionador = mesa.sim.componente(tablero["alimentacion"])
	if not q.accionar(not q.cerrado()):
		_mostrar_aviso("Interruptor bloqueado", "Tiene puesto el candado de bloqueo y su tarjeta. Solo lo retira quien lo puso, cuando termina el trabajo.")
	_reconstruir_panel()


func _alternar_candado() -> void:
	var q: SimSeccionador = mesa.sim.componente(tablero["alimentacion"])
	q.poner_candado(not q.estado["candado"])
	_reconstruir_panel()


func _rearmar_guardamotor(id: String) -> void:
	var q: SimGuardamotor = mesa.sim.componente(id)
	q.accionar(false)
	q.accionar(true)
	_reconstruir_panel()


func _alternar_senal(id: String) -> void:
	var sel: SimSelector = mesa.sim.componente(id)
	sel.girar(-1 if sel.cerrado("13-14") else 1)
	_reconstruir_panel()


func _averia_puesta(a: Dictionary) -> bool:
	return mesa.sim.componente(a["componente"]).params[a["param"]] == a["valor"]


## Las averías cambian un parámetro del componente; al quitarlas vuelve el del circuito original.
func _alternar_averia(a: Dictionary) -> void:
	var c := mesa.sim.componente(a["componente"])
	if _averia_puesta(a):
		var original := SimSimulacion.desde_dict(raiz.contenido.leer("circuitos/%s.json" % tablero["circuito"]).duplicate(true))
		c.params[a["param"]] = original.componente(a["componente"]).params[a["param"]]
	else:
		c.params[a["param"]] = a["valor"]
	_reconstruir_panel()


func _panel_pieza() -> void:
	var id: String = args["pieza"]
	if id.is_empty() or not mesa.piezas.has(id):
		_panel.add_child(_etiqueta("Abra la puerta y toque una pieza para ver su estado y sus ajustes.", "Nota"))
		return
	var e := mesa.entrada(mesa.piezas[id]["tipo"])
	_panel.add_child(_etiqueta("%s: %s" % [id, e["nombre"]], "Subtitulo"))
	_panel.add_child(_etiqueta(mesa.estado_pieza(id)))
	var c := mesa.sim.componente(id)
	match c.tipo():
		"guardamotor":
			_agregar_ajuste(c, "Ajuste térmico", 1.0, maxf(40.0, float(c.params["ajuste_a"]) * 2.0))
		"rele_termico":
			_agregar_ajuste(c, "Ajuste", 1.0, maxf(40.0, float(c.params["ajuste_a"]) * 2.0))
			if c.estado["disparado"]:
				_panel.add_child(_boton("Rearmar (botón azul)", _rearmar_rele.bind(id)))
		"motor_trifasico":
			var m := c as SimMotorTrifasico
			_panel.add_child(_etiqueta("Placa: %s kW · %d Δ / %d Y V · %s / %s A · %d rpm" % [TextoTecnico.numero(m.params["p_kw"], 1), roundi(m.params["v_delta"]), roundi(m.params["v_estrella"]), TextoTecnico.numero(m.params["i_delta"], 1), TextoTecnico.numero(m.params["i_estrella"], 1), roundi(m.params["rpm"])], "Nota"))
	if mesa.danada(id):
		_panel.add_child(_boton("Cambiar por un repuesto", _reparar.bind(id)))


func _reparar(id: String) -> void:
	mesa.reparar(id)
	_reconstruir_panel()


func _panel_datos() -> void:
	_panel.add_child(_etiqueta(tablero.get("nota", ""), "Nota"))
	if tablero.has("foto"):
		_panel.add_child(_etiqueta("Referencia: %s." % tablero["foto"], "Nota"))
	var circuito := raiz.contenido.leer("circuitos/%s.json" % tablero["circuito"])
	_panel.add_child(_etiqueta(circuito.get("nota", ""), "Nota"))
