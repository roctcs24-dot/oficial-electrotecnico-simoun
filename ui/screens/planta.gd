extends Pantalla
## Práctica libre de la planta de frío por amoníaco: esquema del ciclo con manómetros y
## termómetro, mando eléctrico del compresor con sus presostatos, diagrama presión–entalpía y
## seguridad de la sala. La simulación vive en args para sobrevivir al giro del celular.

const ACTUALIZACIONES_POR_SEGUNDO := 10.0
const PASOS_POR_CUADRO := 3
const PROPORCION_ESQUEMA := 1.2
## Presostatos e interruptor de nivel alto en serie con la bobina del contactor.
const PRESOSTATOS := ["PA", "PB", "PO", "LS"]

var sim: SimSimulacion
var datos: Dictionary
## OperadorPlanta en la práctica libre, o la misión, que ofrece los mismos mandos.
var operador
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
	_poner_cabecera()
	_avisos = _columna(6)
	add_child(_avisos)
	_construir_cuerpo()
	_llenar()
	_actualizar()


func _preparar() -> void:
	datos = raiz.contenido.leer("planta.json")
	if not args.has("sim"):
		args["circuito"] = args.get("circuito", datos["circuito"])
		args["sim"] = raiz.contenido.circuito(args["circuito"])
		args["pestana"] = args.get("pestana", "esquema")
		args["eventos"] = 0
		args["termometro"] = ""
		args["rapido"] = false
	sim = args["sim"]
	operador = OperadorPlanta.new(sim, datos)


func _poner_cabecera() -> void:
	_cabecera("Planta de frío", "Práctica libre · valores típicos: verificar a bordo")


## Pestañas propias de quien amplía esta pantalla, delante de las de la planta.
func _pestanas_extra() -> Array:
	return []


func _construir_cuerpo() -> void:
	var pestanas := _pestanas_extra() + [["mando", "Mando"], ["ph", "P–h"], ["seguridad", "Seguridad"]]
	if raiz.vertical:
		add_child(_fila_pestanas(_pestanas_extra() + [["esquema", "Esquema"], ["mando", "Mando"], ["ph", "P–h"], ["seguridad", "Seguridad"]]))
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


## Las pestañas no recortan su nombre: si no caben en una línea, como las cinco de una misión
## en un celular vertical, pasan a la siguiente.
func _fila_pestanas(pestanas: Array) -> Control:
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 4)
	fila.add_theme_constant_override("v_separation", 4)
	var grupo := ButtonGroup.new()
	for p: Array in pestanas:
		var b := _boton(p[1], _elegir_pestana.bind(p[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
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
		_llenar_zona(columna, z[1])
	_firma = _calcular_firma()


func _llenar_zona(columna: VBoxContainer, id: String) -> void:
	match id:
		"esquema":
			_panel_esquema(columna)
		"mando":
			_panel_mando(columna)
		"ph":
			_panel_ph(columna)
		"seguridad":
			_panel_seguridad(columna)


# --- Esquema, manómetros y termómetro ---

func _panel_esquema(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Ciclo de refrigeración"))
	_esquema = EsquemaFrio.new()
	_esquema.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_esquema.punto_marcado = args["termometro"]
	_esquema.punto_tocado.connect(_medir_tuberia)
	columna.add_child(_esquema)
	var baja := "desde la botella de baja, por la bomba de amoníaco y el evaporador, hasta la succión" if operador.planta().bombeo() else "desde la válvula de expansión hasta la succión"
	columna.add_child(_etiqueta("Rojo: vapor caliente de la descarga. Naranja: líquido a alta presión. Azul: baja presión, %s." % baja, "Nota"))
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
	_selector_compresor(columna)
	columna.add_child(_rotulo("Compresor"))
	columna.add_child(_luz_con_texto("marcha", "Compresor en marcha: contactor K1 cerrado", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	var motor: SimMotorTrifasico = sim.componente("M1")
	var i_n: float = motor.params["i_delta"]
	_instrumentos["corriente"] = InstrumentoAguja.new().configurar("Motor", "A", 0.0, i_n * 1.6, i_n)
	var instrumento := HFlowContainer.new()
	instrumento.add_child(_instrumentos["corriente"])
	columna.add_child(instrumento)
	var mandos := _rejilla()
	columna.add_child(mandos)
	var q: SimGuardamotor = operador.guardamotor()
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
		var rearme := "manual" if presostato.params["rearme"] == "manual" else "automático"
		var ajuste := "corta a %s bar, rearme %s" % [TextoTecnico.numero(presostato.params["corte_bar"], 1), rearme]
		if p.get("unidad", "") == "nivel":
			ajuste = "corta al %d %% de nivel, rearme %s" % [roundi(float(presostato.params["corte_bar"]) * 100.0), rearme]
		columna.add_child(_luz_con_texto(p["id"], "%s %s: %s" % [p["id"], p["nombre"], ajuste], LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO))
		if presostato.estado["disparado"] and presostato.params["rearme"] == "manual":
			columna.add_child(_boton("Rearmar %s" % p["id"], _atender_orden.bind(operador.rearmar_presostato.bind(p["id"]))))
	columna.add_child(_rotulo("Capacidad"))
	_textos["capacidad"] = _etiqueta("")
	columna.add_child(_textos["capacidad"])
	var capacidad := _rejilla()
	columna.add_child(capacidad)
	var planta: SimPlantaFrio = operador.planta()
	var automatico: bool = planta.estado["automatico"]
	_agregar_a(capacidad, _boton("Pasar a manual" if automatico else "Pasar a automático", _atender_orden.bind(operador.alternar_automatico)))
	if planta.piston():
		# Como el tablero del compresor nº 5: un selector por cada solenoide de capacidad.
		# El Vilter carga al 75 % y al 100 %; el MYCOM 6WB, a dos tercios y al 100 %.
		var media := "%d %%" % roundi(planta.etapa_media() * 100.0)
		for s: Array in [["solenoide_75", "1 · %s" % media], ["solenoide_100", "2 · 100 %"]]:
			columna.add_child(_luz_con_texto(s[0], "Solenoide de capacidad %s" % s[1], LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
			var activa: bool = planta.estado[s[0]]
			_agregar_a(capacidad, _boton("Solenoide %s: %s" % [s[1], "desactivar" if activa else "activar"], _atender_orden.bind(operador.alternar_solenoide.bind(s[0]))))
	else:
		_agregar_a(capacidad, _boton("Capacidad −", _atender_orden.bind(operador.capacidad.bind(-1.0))))
		_agregar_a(capacidad, _boton("Capacidad +", _atender_orden.bind(operador.capacidad.bind(1.0))))
	if planta.bombeo():
		columna.add_child(_rotulo("Botella de baja"))
		_textos["botella"] = _etiqueta("")
		columna.add_child(_textos["botella"])
		columna.add_child(_luz_con_texto("solenoide_nivel", "Solenoide de líquido abierta (la mandan los interruptores de nivel)", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_rotulo("Bombas"))
	var bombas := [["bomba_agua_mar", "agua de mar del condensador"], ["bomba_salmuera", "salmuera de las cubas"]]
	if planta.bombeo():
		bombas.append(["bomba_amoniaco", "amoníaco al evaporador"])
	if planta.piston():
		bombas.append(["bomba_cabezas", "enfriamiento de cabezas"])
	for b: Array in bombas:
		var marcha: bool = operador.planta().estado[b[0]]
		columna.add_child(_luz_con_texto(b[0], "Bomba de %s" % b[1], LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
		columna.add_child(_boton("Parar la bomba de %s" % b[1] if marcha else "Arrancar la bomba de %s" % b[1], _atender_orden.bind(operador.alternar_bomba.bind(b[0]))))
	_textos["potencias"] = _etiqueta("", "Nota")
	columna.add_child(_textos["potencias"])
	columna.add_child(_etiqueta(datos["nota"], "Nota"))
	var rapido: bool = args["rapido"]
	columna.add_child(_boton("Tiempo normal" if rapido else "Acelerar el tiempo ×%d" % int(datos["aceleracion"]), _alternar_rapido))
	_pie_mando(columna)


## Compresores del buque que se pueden practicar: cambiar reinicia la práctica.
func _selector_compresor(columna: VBoxContainer) -> void:
	var lista: Array = datos.get("compresores", [])
	if lista.size() < 2:
		return
	columna.add_child(_rotulo("Compresor de la práctica"))
	var fila := _rejilla()
	columna.add_child(fila)
	for c: Dictionary in lista:
		var b := _boton(c["nombre"], _elegir_compresor.bind(c["circuito"]))
		b.toggle_mode = true
		b.set_pressed_no_signal(args.get("circuito", datos["circuito"]) == c["circuito"])
		_agregar_a(fila, b)


func _elegir_compresor(circuito: String) -> void:
	if circuito == args.get("circuito", ""):
		return
	for clave in ["sim", "eventos", "termometro", "rapido"]:
		args.erase(clave)
	args["circuito"] = circuito
	raiz.reconstruir()


func _pie_mando(columna: VBoxContainer) -> void:
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
	var planta: SimPlantaFrio = operador.planta()
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
	_atender(orden.call())


## Muestra lo que explica una orden y rehace los mandos si cambió algún equipo.
func _atender(aviso: Dictionary) -> void:
	if not aviso.get("titulo", "").is_empty():
		_mostrar_aviso(aviso["titulo"], aviso["texto"])
	_comprobar_firma()


func _actualizar() -> void:
	if sim.solucion == null:
		sim.paso()
	var planta: SimPlantaFrio = operador.planta()
	var marcha: bool = operador.en_marcha()
	if _esquema != null:
		_esquema.en_marcha = planta.compresor_en_marcha()
		_esquema.bomba_agua_mar = planta.bomba_en_marcha("bomba_agua_mar")
		_esquema.bomba_salmuera = planta.bomba_en_marcha("bomba_salmuera")
		_esquema.presion_succion = planta.presion("succion")
		_esquema.presion_descarga = planta.presion("descarga")
		_esquema.recirculacion = planta.bombeo()
		_esquema.nivel_botella = planta.estado["nivel_botella"]
		_esquema.bomba_amoniaco = planta.estado["bomba_amoniaco"]
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
		for clave in ["bomba_amoniaco", "bomba_cabezas", "solenoide_75", "solenoide_100", "solenoide_nivel"]:
			if _luces.has(clave):
				_luces[clave].encendida = planta.estado[clave]
		var consigna := "automático, consigna de la salmuera %s °C" % TextoTecnico.numero(planta.params["consigna_salmuera"], 0)
		if planta.piston():
			var cabezas := "cabezas a %s °C" % TextoTecnico.numero(planta.temperatura("cabezas"), 0)
			_textos["capacidad"].text = "Etapa del %d %% · %s · %s" % [roundi(planta.estado["capacidad"] * 100.0), consigna if planta.estado["automatico"] else "manual, con los selectores", cabezas]
		else:
			_textos["capacidad"].text = "Corredera al %d %% · %s" % [roundi(planta.estado["capacidad"] * 100.0), consigna if planta.estado["automatico"] else "manual, objetivo %d %%" % roundi(planta.estado["capacidad_manual"] * 100.0)]
		if _textos.has("botella"):
			_textos["botella"].text = "Nivel %d %% · la solenoide abre por debajo del %d %% y cierra en el %d %%; nivel alto al %d %%." % [roundi(planta.estado["nivel_botella"] * 100.0), roundi(float(planta.params["nivel_bajo"]) * 100.0), roundi(float(planta.params["nivel_medio"]) * 100.0), roundi(float(planta.params["nivel_alto"]) * 100.0)]
		_textos["potencias"].text = "Frío producido: %s kW. Potencia en el eje: %s kW." % [TextoTecnico.numero(planta.estado["q_kw"], 0), TextoTecnico.numero(planta.estado["w_kw"], 0)]
	if _ph != null:
		_ph.actualizar(planta.temperatura("evaporacion"), planta.temperatura("condensacion"), planta.compresor_en_marcha())
	if _instrumentos.has("ppm"):
		_instrumentos["ppm"].valor = planta.estado["ppm_sala"]
		_luces["alarma"].encendida = not planta.estado["alarma"].is_empty()
		_luces["ventilacion"].encendida = planta.estado["ventilacion_emergencia"]
		_textos["valvula"].text = "Tarada a %s bar. %s" % [TextoTecnico.numero(planta.params["valvula_seguridad_bar"], 0), "Abierta: descarga amoníaco a la atmósfera." if planta.estado["valvula_abierta"] else "Cerrada."]


func _calcular_firma() -> String:
	var planta: SimPlantaFrio = operador.planta()
	var partes := PackedStringArray()
	for v in [operador.guardamotor().cerrado(), (sim.componente("F2") as SimReleTermico).estado["disparado"],
			planta.estado["automatico"], planta.estado["bomba_agua_mar"], planta.estado["bomba_salmuera"], planta.estado["ventilacion_emergencia"], args["rapido"],
			planta.estado["bomba_amoniaco"], planta.estado["bomba_cabezas"], planta.estado["solenoide_75"], planta.estado["solenoide_100"]]:
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
		_avanzar(pasos, dt)
		_revisar_eventos()
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / ACTUALIZACIONES_POR_SEGUNDO
		_comprobar_firma()
		_actualizar()


func _avanzar(pasos: int, dt: float) -> void:
	for _i in pasos:
		sim.paso(dt)


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
