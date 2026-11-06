extends Pantalla
## Práctica con un autómata programable: el frente del PLC con los LEDs de entradas y salidas,
## los pulsadores y sensores que tiene cableados, y el programa ladder en vivo, que se puede
## editar y transferir al PLC. La simulación y el borrador viven en args para sobrevivir al giro.

const ACTUALIZACIONES_POR_SEGUNDO := 10.0
const PASOS_POR_CUADRO := 3
const PASO_VALOR := 0.5

var sim: SimSimulacion
var plc: SimPLC
var _zonas: Array[Array] = []
var _desplazables: Array[ScrollContainer] = []
var _luces := {}
var _textos := {}
var _ladder: EsquemaLadder
var _botones_pestana := {}
var _firma := ""
var _acumulado := 0.0
var _hasta_lectura := 0.0


func construir() -> void:
	_preparar()
	if not raiz.vertical and args["pestana"] == "equipo":
		args["pestana"] = "programa"
	var circuito := raiz.contenido.leer("circuitos/%s.json" % args["circuito"])
	_cabecera(circuito.get("nombre", "PLC"), "Práctica libre · valores típicos: verificar a bordo")
	_avisos = _columna(6)
	add_child(_avisos)
	if raiz.vertical:
		add_child(_fila_pestanas([["equipo", "Equipo"], ["programa", "Programa"]]))
		_zonas.append([_agregar_zona(self), args["pestana"]])
	else:
		var cuerpo := HBoxContainer.new()
		cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_theme_constant_override("separation", 10)
		add_child(cuerpo)
		_zonas.append([_agregar_zona(cuerpo), "equipo"])
		_zonas.append([_agregar_zona(cuerpo), "programa"])
		_desplazables[-1].size_flags_stretch_ratio = 1.6
	_llenar()
	_actualizar()


func _preparar() -> void:
	if not args.has("sim"):
		args["circuito"] = args.get("circuito", "plc_bomba_achique")
		args["sim"] = raiz.contenido.circuito(args["circuito"])
		args["pestana"] = args.get("pestana", "equipo")
		args["eventos"] = 0
		args["seleccion"] = []
	sim = args["sim"]
	plc = sim.componente("PLC")
	if not args.has("borrador"):
		args["borrador"] = plc.params["programa"].duplicate(true)


func _agregar_zona(padre: Control) -> VBoxContainer:
	var desplazable := _desplazable()
	padre.add_child(desplazable)
	_desplazables.append(desplazable)
	var columna := _columna(8)
	desplazable.add_child(columna)
	return columna


func _fila_pestanas(pestanas: Array) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	var grupo := ButtonGroup.new()
	for p: Array in pestanas:
		var b := _boton(p[1], _elegir_pestana.bind(p[0]))
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["pestana"] == p[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
		_botones_pestana[p[0]] = b
	return fila


func _elegir_pestana(id: String) -> void:
	args["pestana"] = id
	for clave: String in _botones_pestana:
		_botones_pestana[clave].set_pressed_no_signal(clave == id)
	_zonas[-1][1] = id
	_desplazables[-1].scroll_vertical = 0
	_llenar()
	_actualizar()


func _llenar() -> void:
	_luces = {}
	_textos = {}
	_ladder = null
	for z: Array in _zonas:
		var columna: VBoxContainer = z[0]
		for hijo in columna.get_children():
			columna.remove_child(hijo)
			hijo.queue_free()
		if z[1] == "equipo":
			_panel_equipo(columna)
		else:
			_panel_programa(columna)
	_firma = _calcular_firma()


# --- Frente del PLC y mandos ---

func _panel_equipo(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Autómata"))
	columna.add_child(_luz("alimentado", "Alimentación de 24 V DC", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_luz("run", "RUN: ejecutando el programa", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_boton("Pasar a STOP" if plc.estado["modo"] == "RUN" else "Pasar a RUN", _alternar_modo))
	var etiquetas: Dictionary = plc.params["etiquetas"]
	columna.add_child(_rotulo("Entradas"))
	for i in SimPLC.ENTRADAS:
		var d := "%" + SimPLC.entrada(i)
		if etiquetas.has(d):
			columna.add_child(_luz(d, "%s  %s" % [d, etiquetas[d]], LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_rotulo("Salidas"))
	for i in SimPLC.SALIDAS:
		var d := "%" + SimPLC.salida(i)
		if etiquetas.has(d):
			columna.add_child(_luz(d, "%s  %s" % [d, etiquetas[d]], LuzPiloto.AMBAR_APAGADO, LuzPiloto.AMBAR_ENCENDIDO))
	columna.add_child(_rotulo("Entrada analógica"))
	_textos["analogica"] = _etiqueta("")
	columna.add_child(_textos["analogica"])
	columna.add_child(_rotulo("En el campo"))
	var mandos := _rejilla()
	columna.add_child(mandos)
	for c: SimComponente in sim.componentes.values():
		if c is SimPulsador:
			_agregar_a(mandos, _pulsador("%s: mantener" % _nombre_corto(c.id), c.id))
	for c: SimComponente in sim.componentes.values():
		if c is SimSensorProximidad:
			var hay: bool = c.estado["objeto"]
			_agregar_a(mandos, _boton("%s: %s" % [_nombre_corto(c.id), "quitar el nivel" if hay else "poner nivel alto"], _alternar_objeto.bind(c.id)))
		elif c is SimTransmisor420:
			_agregar_a(mandos, _boton("%s −%s" % [c.id, TextoTecnico.numero(PASO_VALOR, 1)], _ajustar_transmisor.bind(c.id, -PASO_VALOR)))
			_agregar_a(mandos, _boton("%s +%s" % [c.id, TextoTecnico.numero(PASO_VALOR, 1)], _ajustar_transmisor.bind(c.id, PASO_VALOR)))
			var abierto: bool = c.params["averia"] == "abierto"
			_agregar_a(mandos, _boton("%s: %s" % [c.id, "reponer el cable" if abierto else "cortar el cable"], _alternar_cable.bind(c.id)))
	columna.add_child(_etiqueta(raiz.contenido.leer("circuitos/%s.json" % args["circuito"]).get("nota", ""), "Nota"))
	columna.add_child(_boton("Reiniciar la práctica", _reiniciar))


## Nombre del dispositivo de campo según la etiqueta de la entrada a la que va.
func _nombre_corto(id: String) -> String:
	for d: String in plc.params["etiquetas"]:
		var etiqueta: String = plc.params["etiquetas"][d]
		if etiqueta.begins_with(id + " · "):
			return etiqueta
	return id


func _rejilla() -> GridContainer:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	return rejilla


func _agregar_a(padre: Control, b: Button) -> void:
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(b)


func _pulsador(texto: String, id: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.button_down.connect(_pulsar.bind(id, true))
	b.button_up.connect(_pulsar.bind(id, false))
	return b


func _pulsar(id: String, presionado: bool) -> void:
	sim.componente(id).estado["presionado"] = presionado


func _luz(clave: String, texto: String, apagado: Color, encendido: Color) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var luz := LuzPiloto.new()
	luz.color_apagado = apagado
	luz.color_encendido = encendido
	luz.custom_minimum_size = Vector2(28.0, 28.0)
	fila.add_child(luz)
	_luces[clave] = luz
	var etiqueta := _etiqueta(texto)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(etiqueta)
	return fila


func _alternar_modo() -> void:
	plc.cambiar_modo("STOP" if plc.estado["modo"] == "RUN" else "RUN")
	_comprobar_firma()


func _alternar_objeto(id: String) -> void:
	var s := sim.componente(id)
	s.estado["objeto"] = not s.estado["objeto"]
	_comprobar_firma()


func _ajustar_transmisor(id: String, paso: float) -> void:
	var t: SimTransmisor420 = sim.componente(id)
	t.params["valor"] = clampf(float(t.params["valor"]) + paso, float(t.params["min"]), float(t.params["max"]))


func _alternar_cable(id: String) -> void:
	var t := sim.componente(id)
	t.params["averia"] = "" if t.params["averia"] == "abierto" else "abierto"
	_comprobar_firma()


func _reiniciar() -> void:
	for clave in ["sim", "pestana", "eventos", "seleccion", "borrador"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Programa ---

func modificado() -> bool:
	return args["borrador"] != plc.params["programa"]


func _panel_programa(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Programa ladder"))
	columna.add_child(_etiqueta("En verde, por dónde pasa la señal en este scan. Toque un contacto o una bobina para cambiarlo.", "Nota"))
	if modificado():
		columna.add_child(_etiqueta("Hay cambios sin transferir: el PLC sigue ejecutando el programa anterior.", "Nota"))
	_ladder = EsquemaLadder.new()
	_ladder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ladder.etiquetas = plc.params["etiquetas"]
	_ladder.seleccion = args["seleccion"]
	_ladder.elemento_tocado.connect(_seleccionar)
	columna.add_child(_ladder)
	_panel_edicion(columna)
	var transferir := _rejilla()
	columna.add_child(transferir)
	_agregar_a(transferir, _boton("Añadir peldaño", _editar.bind(EditorLadder.agregar_peldano)))
	_agregar_a(transferir, _boton("Transferir al PLC", _transferir))
	if modificado():
		_agregar_a(transferir, _boton("Descartar los cambios", _descartar))
	_agregar_a(transferir, _boton("Recuperar el programa original", _recuperar_original))


func _panel_edicion(columna: VBoxContainer) -> void:
	var ruta: Array = args["seleccion"]
	var programa: Array = args["borrador"]
	var e := EditorLadder.obtener(programa, ruta)
	if e.is_empty():
		return
	var tipo := EditorLadder.tipo(e)
	columna.add_child(_rotulo("Elemento seleccionado"))
	var d := EditorLadder.direccion(e)
	var etiqueta: String = plc.params["etiquetas"].get(d, "sin etiqueta")
	columna.add_child(_etiqueta("%s · %s" % [d, etiqueta]))
	var botones := _rejilla()
	columna.add_child(botones)
	if EditorLadder.es_salida(ruta):
		for t: Array in [["bobina", "Bobina"], ["set", "Set (S)"], ["reset", "Reset (R)"], ["ton", "TON"], ["tof", "TOF"], ["ctu", "Contador"], ["rst", "Reponer contador"]]:
			var b := _boton(t[1], _editar.bind(EditorLadder.cambiar_tipo.bind(ruta, t[0])))
			b.disabled = tipo == t[0]
			_agregar_a(botones, b)
	elif tipo != "cmp":
		for t: Array in [["na", "Contacto NA"], ["nc", "Contacto NC"], ["flanco", "Flanco P"]]:
			var b := _boton(t[1], _editar.bind(EditorLadder.cambiar_tipo.bind(ruta, t[0])))
			b.disabled = tipo == t[0]
			_agregar_a(botones, b)
	if tipo != "cmp":
		_agregar_a(botones, _boton("‹ Dirección", _editar.bind(EditorLadder.mover_direccion.bind(ruta, -1))))
		_agregar_a(botones, _boton("Dirección ›", _editar.bind(EditorLadder.mover_direccion.bind(ruta, 1))))
	if e.has("ms") or e.has("pv") or e.has("cmp"):
		_agregar_a(botones, _boton("Valor −", _editar.bind(EditorLadder.ajustar_valor.bind(ruta, -1))))
		_agregar_a(botones, _boton("Valor +", _editar.bind(EditorLadder.ajustar_valor.bind(ruta, 1))))
	if EditorLadder.es_salida(ruta):
		_agregar_a(botones, _boton("Añadir otra salida", _editar.bind(EditorLadder.agregar_salida.bind(ruta[0]))))
	else:
		_agregar_a(botones, _boton("Añadir contacto en serie", _editar.bind(EditorLadder.agregar_en_serie.bind(ruta))))
		_agregar_a(botones, _boton("Añadir rama en paralelo", _editar.bind(EditorLadder.agregar_paralelo.bind(ruta))))
	_agregar_a(botones, _boton("Borrar el elemento", _borrar_seleccion))
	_agregar_a(botones, _boton("Borrar el peldaño %d" % (int(ruta[0]) + 1), _borrar_peldano))


func _seleccionar(ruta: Array) -> void:
	args["seleccion"] = ruta
	_rehacer_programa()


## Aplica un cambio del editor al borrador. El cambio recibe el programa como primer argumento.
func _editar(cambio: Callable) -> void:
	cambio.call(args["borrador"])
	if EditorLadder.obtener(args["borrador"], args["seleccion"]).is_empty():
		args["seleccion"] = []
	_rehacer_programa()


func _borrar_seleccion() -> void:
	var ruta: Array = args["seleccion"]
	if EditorLadder.es_salida(ruta) and args["borrador"][ruta[0]]["salidas"].size() == 1:
		_mostrar_aviso("Última salida", "Cada peldaño necesita al menos una salida. Borre el peldaño entero si no lo necesita.")
		return
	EditorLadder.borrar(args["borrador"], ruta)
	args["seleccion"] = []
	_rehacer_programa()


func _borrar_peldano() -> void:
	EditorLadder.borrar_peldano(args["borrador"], args["seleccion"][0])
	args["seleccion"] = []
	_rehacer_programa()


## Como en un PLC real, el programa se transfiere con el autómata en STOP.
func _transferir() -> void:
	if plc.estado["modo"] == "RUN":
		_mostrar_aviso("PLC en RUN", "Pase el PLC a STOP antes de transferir: al cargar el programa las salidas se abren y la memoria vuelve a cero.")
		return
	plc.cargar_programa(args["borrador"])
	_mostrar_aviso("Programa transferido", "Pase el PLC a RUN para ejecutarlo.")
	_rehacer_programa()


func _descartar() -> void:
	args["borrador"] = plc.params["programa"].duplicate(true)
	args["seleccion"] = []
	_rehacer_programa()


func _recuperar_original() -> void:
	var p: SimPLC = raiz.contenido.circuito(args["circuito"]).componente("PLC")
	args["borrador"] = p.params["programa"].duplicate(true)
	args["seleccion"] = []
	_rehacer_programa()


func _rehacer_programa() -> void:
	var desplazados: Array[int] = []
	for d in _desplazables:
		desplazados.append(d.scroll_vertical)
	_llenar()
	_actualizar()
	_restaurar.call_deferred(desplazados)


func _restaurar(desplazados: Array[int]) -> void:
	for i in mini(desplazados.size(), _desplazables.size()):
		if is_instance_valid(_desplazables[i]):
			_desplazables[i].scroll_vertical = desplazados[i]


# --- Lecturas y tiempo ---

func _actualizar() -> void:
	if sim.solucion == null:
		sim.paso()
	if _luces.has("run"):
		_luces["alimentado"].encendida = plc.estado["alimentado"]
		_luces["run"].encendida = plc.en_marcha()
		for i in SimPLC.ENTRADAS:
			var d := "%" + SimPLC.entrada(i)
			if _luces.has(d):
				_luces[d].encendida = plc.entrada_activa(i)
		for i in SimPLC.SALIDAS:
			var d := "%" + SimPLC.salida(i)
			if _luces.has(d):
				_luces[d].encendida = plc.salida_activa(i)
		var a: Dictionary = plc.params["analogica"]
		var ma := plc.miliamperios(sim.solucion)
		var texto := "AI0: %s mA → %%IW0 = %s %s" % [TextoTecnico.numero(ma, 1), TextoTecnico.numero(plc.estado["palabras"].get("%IW0", 0.0), 2), a["unidad"]]
		if plc.bit("%AE0"):
			texto += " · ERROR del lazo (%AE0)"
		_textos["analogica"].text = texto
	if _ladder != null:
		_ladder.actualizar(args["borrador"], plc.estado if plc.en_marcha() else {})


func _calcular_firma() -> String:
	return "%s|%s|%s" % [plc.estado["modo"], plc.estado["alimentado"], modificado()]


func _comprobar_firma() -> void:
	if _calcular_firma() == _firma:
		_actualizar()
		return
	_rehacer_programa()


func _process(delta: float) -> void:
	if sim == null:
		return
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), PASOS_POR_CUADRO)
	if pasos > 0:
		_acumulado = 0.0
		for _i in pasos:
			sim.paso()
		_revisar_eventos()
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / ACTUALIZACIONES_POR_SEGUNDO
		_comprobar_firma()


func _revisar_eventos() -> void:
	var textos: Dictionary = raiz.contenido.leer("taller.json").get("consecuencias", {})
	var eventos := sim.eventos
	for i in range(args["eventos"], eventos.size()):
		var e: Dictionary = eventos[i]
		var c: Dictionary = textos.get(e["tipo"], {})
		if not c.is_empty():
			_mostrar_aviso("%s (%s)" % [c["titulo"], e["componente"]], c["texto"])
	args["eventos"] = eventos.size()
