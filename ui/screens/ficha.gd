extends Pantalla
## Ficha de un equipo: dibujo realista, símbolos, banco de prueba con la simulación real y texto.

const ALTO_VISUAL_VERTICAL := 460.0

var _ficha := {}
var _vista := "real"
var _visual: Control
var _nota: Label
var _botones_vista := {}
var _sim: SimSimulacion
var _dibujo: VistaEquipo
var _luz: LuzPiloto
var _lectura: Label
var _acumulado := 0.0


func construir() -> void:
	var id: String = args["id"]
	_ficha = raiz.contenido.ficha(id)
	if _ficha.is_empty():
		_cabecera("Ficha no disponible")
		for error in raiz.contenido.errores:
			add_child(_aviso(error))
		return
	raiz.partida.marcar_ficha_vista(id)
	_vista = args.get("vista", "real")
	_cabecera(_ficha["titulo"], _ficha.get("resumen", ""))

	_visual = _columna()
	_nota = _etiqueta("", "Nota")
	var textos := _crear_textos()
	var desplazable := _desplazable()
	var columna := _columna(12)
	desplazable.add_child(columna)
	if raiz.vertical:
		add_child(desplazable)
		columna.add_child(_crear_selector())
		_visual.custom_minimum_size.y = ALTO_VISUAL_VERTICAL
		columna.add_child(_visual)
		columna.add_child(_nota)
	else:
		# En horizontal el alto escasea: el dibujo ocupa toda su columna y el resto se desplaza.
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 12)
		add_child(fila)
		_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_visual.size_flags_stretch_ratio = 0.8
		fila.add_child(_visual)
		fila.add_child(desplazable)
		columna.add_child(_crear_selector())
		columna.add_child(_nota)
	columna.add_child(_crear_banco())
	columna.add_child(textos)
	_mostrar_vista(_vista)


func _crear_selector() -> Control:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	var grupo := ButtonGroup.new()
	_agregar_vista(rejilla, grupo, "Equipo", "real")
	_agregar_vista(rejilla, grupo, "Símbolos", "simbolos")
	var extras: Array = _ficha.get("dibujos_extra", [])
	for i in extras.size():
		_agregar_vista(rejilla, grupo, extras[i]["titulo"], "extra_%d" % i)
	return rejilla


func _agregar_vista(rejilla: GridContainer, grupo: ButtonGroup, titulo: String, vista: String) -> void:
	var b := _boton(titulo, _mostrar_vista.bind(vista))
	b.toggle_mode = true
	b.button_group = grupo
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_child(b)
	_botones_vista[vista] = b


func _mostrar_vista(vista: String) -> void:
	_vista = vista
	args["vista"] = vista
	for clave: String in _botones_vista:
		_botones_vista[clave].set_pressed_no_signal(clave == vista)
	for hijo in _visual.get_children():
		_visual.remove_child(hijo)
		hijo.queue_free()
	_dibujo = null
	if vista == "real":
		_mostrar_dibujo(_ficha["dibujo"])
	elif vista == "simbolos":
		_mostrar_simbolos()
	else:
		_mostrar_dibujo(_ficha["dibujos_extra"][vista.trim_prefix("extra_").to_int()])


func _mostrar_dibujo(definicion: Dictionary) -> void:
	_dibujo = VistaEquipo.new()
	_dibujo.cargar(definicion)
	_dibujo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual.add_child(_dibujo)
	_nota.text = definicion.get("nota", "")
	_actualizar_banco()


func _mostrar_simbolos() -> void:
	var simbolos: Dictionary = _ficha["simbolos"]
	var caja: BoxContainer = VBoxContainer.new()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual.add_child(caja)
	if simbolos.has("lista"):
		for id: String in simbolos["lista"]:
			var datos := raiz.contenido.simbolo(id)
			caja.add_child(_tarjeta_simbolo(_con_titulo(datos["iec"], "IEC 60617")))
			caja.add_child(_tarjeta_simbolo(_con_titulo(datos["ansi"], "ANSI/IEEE 315 (NEMA)")))
	else:
		for clave: String in ["iec", "ansi"]:
			caja.add_child(_tarjeta_simbolo(simbolos[clave]))
	_nota.text = simbolos.get("nota", "")


func _con_titulo(definicion: Dictionary, titulo: String) -> Dictionary:
	var copia := definicion.duplicate()
	copia["titulo"] = titulo
	return copia


func _tarjeta_simbolo(definicion: Dictionary) -> Control:
	var tarjeta := _tarjeta_base("Papel")
	tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var columna := _columna(2)
	tarjeta.add_child(columna)
	var titulo := _etiqueta(definicion["titulo"], "Nota")
	titulo.add_theme_color_override("font_color", Tema.TINTA)
	columna.add_child(titulo)
	var dibujo := VistaSvg.new()
	dibujo.color_etiquetas = Tema.TINTA
	dibujo.cargar(definicion)
	dibujo.custom_minimum_size.y = 110.0
	dibujo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(dibujo)
	return tarjeta


func _crear_banco() -> Control:
	if not _ficha.has("banco"):
		var vacio := Control.new()
		vacio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return vacio
	var banco: Dictionary = _ficha["banco"]
	_sim = raiz.contenido.circuito(banco["circuito"])
	var tarjeta := _tarjeta_base()
	var columna := _columna(8)
	tarjeta.add_child(columna)
	columna.add_child(_etiqueta("Banco de prueba", "Subtitulo"))
	columna.add_child(_etiqueta(banco.get("explicacion", ""), "Nota"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	columna.add_child(fila)
	var pulsador := Button.new()
	pulsador.text = "Mantener pulsado %s" % banco["pulsador"]
	pulsador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Se mantiene pulsado: el filtro por defecto evita que un movimiento del dedo arrastre la lista.
	pulsador.set_meta("se_mantiene", true)
	pulsador.button_down.connect(pulsar_banco.bind(true))
	pulsador.button_up.connect(pulsar_banco.bind(false))
	fila.add_child(pulsador)
	_luz = LuzPiloto.new()
	fila.add_child(_luz)
	_lectura = _etiqueta("")
	columna.add_child(_lectura)
	if _sim != null:
		_sim.paso()
		_actualizar_banco()
	return tarjeta


func pulsar_banco(presionado: bool) -> void:
	if _sim == null:
		return
	_sim.componente(_ficha["banco"]["pulsador"]).estado["presionado"] = presionado
	_sim.paso()
	_actualizar_banco()


func _process(delta: float) -> void:
	if _sim == null:
		return
	_acumulado += delta
	if _acumulado >= SimSimulacion.PASO_S:
		_acumulado = 0.0
		_sim.paso()
		_actualizar_banco()


func _actualizar_banco() -> void:
	if _sim == null or _lectura == null:
		return
	var banco: Dictionary = _ficha["banco"]
	var k: SimContactor = _sim.componente(banco["contactor"])
	var cerrado := k.cerrado()
	_luz.encendida = _sim.componente(banco["lampara"]).estado["encendida"]
	if _dibujo != null:
		_dibujo.poner_cerrado(cerrado)
	_lectura.text = "Bobina A1-A2: %d V\nPolos 1-2, 3-4, 5-6 y auxiliar 13-14: %s\nAuxiliar 21-22: %s" % [
		roundi(k.tension(_sim.solucion, "A1", "A2")),
		"cerrados" if cerrado else "abiertos",
		"abierto" if cerrado else "cerrado",
	]


func _crear_textos() -> Control:
	var columna := _columna(8)
	var glosario := raiz.contenido.glosario()
	var vistos := {}
	for seccion: Dictionary in _ficha.get("secciones", []):
		_agregar_seccion(columna, seccion["titulo"], TextoTecnico.expandir(seccion["texto"], glosario, vistos))
	var referencias: Array = _ficha.get("para_saber_mas", [])
	if not referencias.is_empty():
		var lineas := PackedStringArray()
		for r: String in referencias:
			lineas.append("• %s" % r)
		_agregar_seccion(columna, "Para saber más", "\n".join(lineas))
	return columna


func _agregar_seccion(columna: VBoxContainer, titulo: String, texto: String) -> void:
	columna.add_child(_etiqueta(titulo, "Subtitulo"))
	columna.add_child(_texto_rico(texto))
