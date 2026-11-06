extends Pantalla
## Práctica libre de la planta de frío por amoníaco: esquema del ciclo con manómetros y
## termómetro, mando eléctrico del compresor con sus presostatos, diagrama presión–entalpía y
## seguridad de la sala. La simulación vive en args para sobrevivir al giro del celular.

const ACTUALIZACIONES_POR_SEGUNDO := 10.0
const PASOS_POR_CUADRO := 3
const PROPORCION_ESQUEMA := 1.2
const PRESOSTATOS := ["PA", "PB", "PO"]

var sim: SimSimulacion
var datos: Dictionary
var operador: OperadorPlanta
var _zonas: Array[Array] = []
var _desplazables: Array[ScrollContainer] = []
var _instrumentos := {}
var _textos := {}
var _luces := {}
var _esquema: EsquemaFrio
var _ph: DiagramaPH
var _botones_pestana := {}
var _firma := ""
var _acumulado := 0.0
var _hasta_lectura := 0.0


func construir() -> void:
	_preparar()
	if not raiz.vertical and args["pestana"] == "esquema":
		args["pestana"] = "mando"
	_cabecera("Planta de frío", "Práctica libre · valores típicos: verificar a bordo")
	_avisos = _columna(6)
	add_child(_avisos)
	_construir_cuerpo()
	_llenar()
	_actualizar()


func _preparar() -> void:
	datos = raiz.contenido.leer("planta.json")
	if not args.has("sim"):
		args["sim"] = raiz.contenido.circuito(datos["circuito"])
		args["pestana"] = args.get("pestana", "esquema")
		args["eventos"] = 0
		args["termometro"] = ""
		args["rapido"] = false
	sim = args["sim"]
	operador = OperadorPlanta.new(sim, datos)


func _construir_cuerpo() -> void:
	var pestanas := [["mando", "Mando"], ["ph", "P–h"], ["seguridad", "Seguridad"]]
	if raiz.vertical:
		add_child(_fila_pestanas([["esquema", "Esquema"]] + pestanas))
		_zonas.append([_agregar_zona(self), args["pestana"]])
		return
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 10)
	add_child(cuerpo)
	var izquierda := _agregar_zona(cuerpo)
	_desplazables[-1].size_flags_stretch_ratio = PROPORCION_ESQUEMA
	_zonas.append([izquierda, "esquema"])
	var derecha := _columna(6)
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(derecha)
	derecha.add_child(_fila_pestanas(pestanas))
	_zonas.append([_agregar_zona(derecha), args["pestana"]])


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
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.clip_text = true
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["pestana"] == p[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Más ancho para los nombres largos, como «Seguridad» frente a «P–h».
		b.size_flags_stretch_ratio = p[1].length() + 2.0
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
	_instrumentos = {}
	_textos = {}
	_luces = {}
	_esquema = null
	_ph = null
	for z: Array in _zonas:
		var columna: VBoxContainer = z[0]
		for hijo in columna.get_children():
			columna.remove_child(hijo)
			hijo.queue_free()
		match z[1]:
			"esquema":
				_panel_esquema(columna)
			"mando":
				_panel_mando(columna)
			"ph":
				_panel_ph(columna)
			"seguridad":
				_panel_seguridad(columna)
	_firma = _calcular_firma()


# --- Esquema, manómetros y termómetro ---

func _panel_esquema(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Ciclo de refrigeración"))
	_esquema = EsquemaFrio.new()
	_esquema.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_esquema.punto_marcado = args["termometro"]
	_esquema.punto_tocado.connect(_medir_tuberia)
	columna.add_child(_esquema)
	columna.add_child(_etiqueta("Rojo: vapor caliente de la descarga. Naranja: líquido a alta presión. Azul: baja presión, desde la válvula de expansión hasta la succión.", "Nota"))
	columna.add_child(_rotulo("Manómetros"))
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 8)
	fila.add_theme_constant_override("v_separation", 8)
	columna.add_child(fila)
	var escalas := [
		["succion", "Succión", "bar", -1.0, 6.0, INF, 2],
		["descarga", "Descarga", "bar", 0.0, 25.0, 16.0, 1],
		["aceite", "Aceite (dif.)", "bar", 0.0, 6.0, INF, 1],
		["salmuera", "Salmuera", "°C", -25.0, 10.0, INF, 1],
	]
	for e: Array in escalas:
		_instrumentos[e[0]] = InstrumentoAguja.new().configurar(e[1], e[2], e[3], e[4], e[5], e[6])
		fila.add_child(_instrumentos[e[0]])
	_textos["lecturas"] = _etiqueta("", "Nota")
	columna.add_child(_textos["lecturas"])
	columna.add_child(_rotulo("Termómetro de contacto o infrarrojo"))
	_textos["termometro"] = _etiqueta("")
	columna.add_child(_textos["termometro"])


func _medir_tuberia(id: String) -> void:
	args["termometro"] = id
	if _esquema != null:
		_esquema.punto_marcado = id
		_esquema.queue_redraw()
	_actualizar()


# --- Mando eléctrico del compresor ---

func _panel_mando(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Compresor"))
	columna.add_child(_luz_con_texto("marcha", "Compresor en marcha: contactor K1 cerrado", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	_instrumentos["corriente"] = InstrumentoAguja.new().configurar("Motor", "A", 0.0, 300.0, 180.0)
	var instrumento := HFlowContainer.new()
	instrumento.add_child(_instrumentos["corriente"])
	columna.add_child(instrumento)
	var mandos := _rejilla()
	columna.add_child(mandos)
	var q := operador.guardamotor()
	_agregar_a(mandos, _boton("Abrir el guardamotor Q1" if q.cerrado() else "Cerrar el guardamotor Q1", _atender_orden.bind(operador.alternar_guardamotor)))
	_agregar_a(mandos, _pulsador("Marcha (S1): mantener", "S1"))
	_agregar_a(mandos, _pulsador("Parada (S0): mantener", "S0"))
	var rele: SimReleTermico = sim.componente("F2")
	if rele.estado["disparado"]:
		_agregar_a(mandos, _boton("Rearmar el relé térmico F2", _atender_orden.bind(operador.rearmar_rele)))
	columna.add_child(_luz_con_texto("rele", "Relé térmico F2 disparado", LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO))
	columna.add_child(_rotulo("Presostatos de seguridad"))
	for p: Dictionary in datos["presostatos"]:
		var presostato: SimPresostato = sim.componente(p["id"])
		var ajuste := "corta a %s bar, rearme %s" % [TextoTecnico.numero(presostato.params["corte_bar"], 1), "manual" if presostato.params["rearme"] == "manual" else "automático"]
		columna.add_child(_luz_con_texto(p["id"], "%s %s: %s" % [p["id"], p["nombre"], ajuste], LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO))
		if presostato.estado["disparado"] and presostato.params["rearme"] == "manual":
			columna.add_child(_boton("Rearmar %s" % p["id"], _atender_orden.bind(operador.rearmar_presostato.bind(p["id"]))))
	columna.add_child(_rotulo("Capacidad"))
	_textos["capacidad"] = _etiqueta("")
	columna.add_child(_textos["capacidad"])
	var capacidad := _rejilla()
	columna.add_child(capacidad)
	var automatico: bool = operador.planta().estado["automatico"]
	_agregar_a(capacidad, _boton("Pasar a manual" if automatico else "Pasar a automático", _atender_orden.bind(operador.alternar_automatico)))
	_agregar_a(capacidad, _boton("Capacidad −", _atender_orden.bind(operador.capacidad.bind(-1.0))))
	_agregar_a(capacidad, _boton("Capacidad +", _atender_orden.bind(operador.capacidad.bind(1.0))))
	columna.add_child(_rotulo("Bombas"))
	for b: Array in [["bomba_agua_mar", "agua de mar del condensador"], ["bomba_salmuera", "salmuera de las cubas"]]:
		var marcha: bool = operador.planta().estado[b[0]]
		columna.add_child(_luz_con_texto(b[0], "Bomba de %s" % b[1], LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
		columna.add_child(_boton("Parar la bomba de %s" % b[1] if marcha else "Arrancar la bomba de %s" % b[1], _atender_orden.bind(operador.alternar_bomba.bind(b[0]))))
	_textos["potencias"] = _etiqueta("", "Nota")
	columna.add_child(_textos["potencias"])
	columna.add_child(_etiqueta(datos["nota"], "Nota"))
	var rapido: bool = args["rapido"]
	columna.add_child(_boton("Tiempo normal" if rapido else "Acelerar el tiempo ×%d" % int(datos["aceleracion"]), _alternar_rapido))
	columna.add_child(_boton("Reiniciar la práctica", _reiniciar))


func _rejilla() -> GridContainer:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	return rejilla


func _agregar_a(padre: Control, b: Button) -> void:
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(b)


## Un pulsador con retorno: actúa mientras se mantiene apretado.
func _pulsador(texto: String, id: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.button_down.connect(_pulsar.bind(id, true))
	b.button_up.connect(_pulsar.bind(id, false))
	return b


func _pulsar(id: String, presionado: bool) -> void:
	operador.pulsar(id, presionado)


func _luz_con_texto(clave: String, texto: String, apagado: Color, encendido: Color) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var luz := LuzPiloto.new()
	luz.color_apagado = apagado
	luz.color_encendido = encendido
	luz.custom_minimum_size = Vector2(36.0, 36.0)
	fila.add_child(luz)
	_luces[clave] = luz
	var etiqueta := _etiqueta(texto)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(etiqueta)
	return fila


func _alternar_rapido() -> void:
	args["rapido"] = not args["rapido"]
	_comprobar_firma()


func _reiniciar() -> void:
	for clave in ["sim", "pestana", "eventos", "termometro", "rapido"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Diagrama P–h ---

func _panel_ph(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Diagrama presión–entalpía"))
	_ph = DiagramaPH.new()
	_ph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_child(_ph)
	columna.add_child(_etiqueta("1-2: el compresor aspira vapor y lo comprime. 2-3: en el condensador se enfría y condensa a presión constante. 3-4: la válvula de expansión baja la presión sin cambiar la entalpía. 4-1: en el evaporador el líquido hierve y toma el calor de la salmuera.", "Nota"))
	columna.add_child(_etiqueta("Las presiones son las de la simulación, en escala logarítmica. Las entalpías son esquemáticas: el diagrama sirve para ver la forma del ciclo, no para calcular.", "Nota"))


# --- Seguridad de la sala ---

func _panel_seguridad(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Detector de amoníaco de la sala"))
	var planta := operador.planta()
	_instrumentos["ppm"] = InstrumentoAguja.new().configurar("NH3", "ppm", 0.0, 300.0, planta.params["alarma_alta_ppm"])
	var detector := HFlowContainer.new()
	detector.add_child(_instrumentos["ppm"])
	columna.add_child(detector)
	columna.add_child(_luz_con_texto("alarma", "Alarma de amoníaco", LuzPiloto.AMBAR_APAGADO, LuzPiloto.AMBAR_ENCENDIDO))
	columna.add_child(_etiqueta("Aviso a %s ppm y alarma alta a %s ppm: ajustes típicos, verificar a bordo. 25 ppm es el límite de exposición de una jornada, y 300 ppm, la concentración inmediatamente peligrosa para la vida." % [TextoTecnico.numero(planta.params["alarma_ppm"], 0), TextoTecnico.numero(planta.params["alarma_alta_ppm"], 0)], "Nota"))
	var ventilacion: bool = planta.estado["ventilacion_emergencia"]
	columna.add_child(_luz_con_texto("ventilacion", "Ventilación de emergencia", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_boton("Parar la ventilación de emergencia" if ventilacion else "Arrancar la ventilación de emergencia", _atender_orden.bind(operador.alternar_ventilacion)))
	columna.add_child(_rotulo("Válvula de seguridad"))
	_textos["valvula"] = _etiqueta("")
	columna.add_child(_textos["valvula"])


# --- Órdenes y lecturas ---

func _atender_orden(orden: Callable) -> void:
	var aviso: Dictionary = orden.call()
	if not aviso.get("titulo", "").is_empty():
		_mostrar_aviso(aviso["titulo"], aviso["texto"])
	_comprobar_firma()


func _actualizar() -> void:
	if sim.solucion == null:
		sim.paso()
	var planta := operador.planta()
	var marcha := operador.en_marcha()
	if _esquema != null:
		_esquema.en_marcha = planta.compresor_en_marcha()
		_esquema.bomba_agua_mar = planta.bomba_en_marcha("bomba_agua_mar")
		_esquema.bomba_salmuera = planta.bomba_en_marcha("bomba_salmuera")
		_esquema.presion_succion = planta.presion("succion")
		_esquema.presion_descarga = planta.presion("descarga")
		_esquema.queue_redraw()
	if _instrumentos.has("succion"):
		_instrumentos["succion"].valor = planta.presion("succion")
		_instrumentos["descarga"].valor = planta.presion("descarga")
		_instrumentos["aceite"].valor = planta.presion("aceite")
		_instrumentos["salmuera"].valor = planta.temperatura("salmuera")
		_textos["lecturas"].text = "Succión: %s psi, evaporación a %s °C. Descarga: %s psi, condensación a %s °C." % [
			TextoTecnico.numero(SimNH3.bar_a_psi(planta.presion("succion")), 0), TextoTecnico.numero(planta.temperatura("evaporacion"), 1),
			TextoTecnico.numero(SimNH3.bar_a_psi(planta.presion("descarga")), 0), TextoTecnico.numero(planta.temperatura("condensacion"), 1)]
		var punto: String = args["termometro"]
		if punto.is_empty():
			_textos["termometro"].text = "Toque un punto marcado del esquema para medir su temperatura."
		else:
			_textos["termometro"].text = "%s: %s °C" % [datos["tuberias"][punto], TextoTecnico.numero(planta.temperatura_tuberia(punto), 1)]
	if _luces.has("marcha"):
		_luces["marcha"].encendida = marcha
		_instrumentos["corriente"].valor = operador.corriente_motor()
		_luces["rele"].encendida = (sim.componente("F2") as SimReleTermico).estado["disparado"]
		for id: String in PRESOSTATOS:
			_luces[id].encendida = not (sim.componente(id) as SimPresostato).cerrado()
		_luces["bomba_agua_mar"].encendida = planta.bomba_en_marcha("bomba_agua_mar")
		_luces["bomba_salmuera"].encendida = planta.bomba_en_marcha("bomba_salmuera")
		_textos["capacidad"].text = "Corredera al %d %% · %s" % [roundi(planta.estado["capacidad"] * 100.0), "automático, consigna de la salmuera %s °C" % TextoTecnico.numero(planta.params["consigna_salmuera"], 0) if planta.estado["automatico"] else "manual, objetivo %d %%" % roundi(planta.estado["capacidad_manual"] * 100.0)]
		_textos["potencias"].text = "Frío producido: %s kW. Potencia en el eje: %s kW." % [TextoTecnico.numero(planta.estado["q_kw"], 0), TextoTecnico.numero(planta.estado["w_kw"], 0)]
	if _ph != null:
		_ph.actualizar(planta.temperatura("evaporacion"), planta.temperatura("condensacion"), planta.compresor_en_marcha())
	if _instrumentos.has("ppm"):
		_instrumentos["ppm"].valor = planta.estado["ppm_sala"]
		_luces["alarma"].encendida = not planta.estado["alarma"].is_empty()
		_luces["ventilacion"].encendida = planta.estado["ventilacion_emergencia"]
		_textos["valvula"].text = "Tarada a %s bar. %s" % [TextoTecnico.numero(planta.params["valvula_seguridad_bar"], 0), "Abierta: descarga amoníaco a la atmósfera." if planta.estado["valvula_abierta"] else "Cerrada."]


func _calcular_firma() -> String:
	var planta := operador.planta()
	var partes := PackedStringArray()
	for v in [operador.guardamotor().cerrado(), (sim.componente("F2") as SimReleTermico).estado["disparado"],
			planta.estado["automatico"], planta.estado["bomba_agua_mar"], planta.estado["bomba_salmuera"], planta.estado["ventilacion_emergencia"], args["rapido"]]:
		partes.append(str(v))
	for id: String in PRESOSTATOS:
		partes.append(str((sim.componente(id) as SimPresostato).estado["disparado"]))
	return "|".join(partes)


## Si cambió el estado de algún equipo, los botones deben cambiar de texto.
func _comprobar_firma() -> void:
	if _calcular_firma() == _firma:
		return
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


func _process(delta: float) -> void:
	if sim == null:
		return
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), PASOS_POR_CUADRO)
	if pasos > 0:
		_acumulado = 0.0
		var dt := SimSimulacion.PASO_S * (float(datos["aceleracion"]) if args["rapido"] else 1.0)
		for _i in pasos:
			sim.paso(dt)
		_revisar_eventos()
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / ACTUALIZACIONES_POR_SEGUNDO
		_comprobar_firma()
		_actualizar()


func _revisar_eventos() -> void:
	var textos: Dictionary = raiz.contenido.leer("taller.json").get("consecuencias", {}).duplicate()
	textos.merge(datos["consecuencias"], true)
	var eventos := sim.eventos
	for i in range(args["eventos"], eventos.size()):
		var e: Dictionary = eventos[i]
		var tipo: String = e["tipo"]
		if tipo == "disparo_presostato":
			tipo += "_" + str(e["detalle"].get("punto", ""))
		var c: Dictionary = textos.get(tipo, {})
		if not c.is_empty():
			_mostrar_aviso("%s (%s)" % [c["titulo"], e["componente"]], c["texto"])
	args["eventos"] = eventos.size()
