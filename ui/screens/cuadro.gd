extends Pantalla
## Práctica libre del cuadro principal: tres generadores, sincronización, reparto de carga
## y gestión de potencia. La simulación vive en args para sobrevivir al giro del celular.

const ACTUALIZACIONES_POR_SEGUNDO := 10.0
const PASOS_POR_CUADRO := 3
const COLOR_LCD := Color("0f1a14")
const BORDE_LCD := Color("2d4a38")
const TEXTO_LCD := Color("9fe3b5")
const PROPORCION_GENERADOR := 1.3

var sim: SimSimulacion
var datos: Dictionary
var _zonas: Array[Array] = []
var _desplazables: Array[ScrollContainer] = []
var _instrumentos := {}
var _textos := {}
var _luces := {}
var _dial: DialSincronoscopio
var _botones_pestana := {}
var _firma := ""
var _acumulado := 0.0
var _hasta_lectura := 0.0


func construir() -> void:
	datos = raiz.contenido.leer("cuadro.json")
	if not args.has("sim"):
		args["sim"] = raiz.contenido.circuito(datos["circuito"])
		args["pestana"] = args.get("pestana", "barras")
		args["sincronizar"] = "G2"
		args["eventos"] = 0
	sim = args["sim"]
	if not raiz.vertical and args["pestana"] == "barras":
		args["pestana"] = datos["generadores"][0]["id"]
	_cabecera("Cuadro principal", "Práctica libre · valores típicos: verificar a bordo")
	_avisos = _columna(6)
	add_child(_avisos)
	_construir_cuerpo()
	_llenar()
	_actualizar()


func _construir_cuerpo() -> void:
	if raiz.vertical:
		var pestanas := [["barras", "Barras"]]
		for g: Dictionary in datos["generadores"]:
			pestanas.append([g["id"], g["id"]])
		add_child(_fila_pestanas(pestanas))
		_zonas.append([_agregar_zona(self, 1.0), args["pestana"]])
		return
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 10)
	add_child(cuerpo)
	_zonas.append([_agregar_zona(cuerpo, 1.0), "barras"])
	var derecha := _columna(6)
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	derecha.size_flags_stretch_ratio = PROPORCION_GENERADOR
	cuerpo.add_child(derecha)
	var pestanas := []
	for g: Dictionary in datos["generadores"]:
		pestanas.append([g["id"], g["nombre"]])
	derecha.add_child(_fila_pestanas(pestanas))
	_zonas.append([_agregar_zona(derecha, 1.0), args["pestana"]])


func _agregar_zona(padre: Control, proporcion: float) -> VBoxContainer:
	var desplazable := _desplazable()
	desplazable.size_flags_stretch_ratio = proporcion
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


## Rehace el contenido de las zonas. Se llama al cambiar de pestaña o de estado de un equipo.
func _llenar() -> void:
	_instrumentos = {}
	_textos = {}
	_luces = {}
	_dial = null
	for z: Array in _zonas:
		var columna: VBoxContainer = z[0]
		for hijo in columna.get_children():
			columna.remove_child(hijo)
			hijo.queue_free()
		if z[1] == "barras":
			_panel_barras(columna)
		else:
			_panel_generador(columna, z[1])
	_firma = _calcular_firma()


# --- Barras, sincronización, aislamiento, PMS y salidas ---

func _panel_barras(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Barras principales"))
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 8)
	fila.add_theme_constant_override("v_separation", 8)
	columna.add_child(fila)
	_instrumentos["bp_v"] = InstrumentoAguja.new().configurar("Tensión", "V", 0.0, 600.0, 484.0)
	fila.add_child(_instrumentos["bp_v"])
	_instrumentos["bp_f"] = InstrumentoAguja.new().configurar("Frecuencia", "Hz", 54.0, 66.0, 63.0, 2)
	fila.add_child(_instrumentos["bp_f"])
	columna.add_child(_rotulo("Sincronización"))
	columna.add_child(_etiqueta("Generador entrante:", "Nota"))
	var selector := HBoxContainer.new()
	selector.add_theme_constant_override("separation", 4)
	columna.add_child(selector)
	var grupo := ButtonGroup.new()
	for g: Dictionary in datos["generadores"]:
		var b := _boton(g["id"], _elegir_sincronizar.bind(g["id"]))
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["sincronizar"] == g["id"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.add_child(b)
	# Los mandos junto a la aguja: se cierra mirándola, sin tener que desplazarse.
	var junto: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	junto.add_theme_constant_override("separation", 10)
	columna.add_child(junto)
	_dial = DialSincronoscopio.new()
	junto.add_child(_dial)
	var lado := _columna(6)
	lado.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	junto.add_child(lado)
	_mandos_sincronizacion(lado)
	_textos["sincronismo"] = _etiqueta("", "Nota")
	columna.add_child(_textos["sincronismo"])
	columna.add_child(_etiqueta("A mano: suba la velocidad hasta que la aguja gire despacio hacia RÁPIDO y cierre justo antes de las doce. En automático, el sincronizador ajusta la velocidad y cierra dentro de la ventana.", "Nota"))
	columna.add_child(_rotulo("Monitor de aislamiento"))
	columna.add_child(_luz_con_texto("aislamiento", "", LuzPiloto.AMBAR_APAGADO, LuzPiloto.AMBAR_ENCENDIDO))
	columna.add_child(_rotulo("Gestión de potencia (PMS)"))
	var pms: SimPMS = sim.componente("PMS")
	columna.add_child(_boton("Pasar a manual" if pms.automatico() else "Pasar a automático", _alternar_pms))
	_textos["pms"] = _etiqueta("", "Nota")
	columna.add_child(_textos["pms"])
	columna.add_child(_rotulo("Salidas"))
	for c: Dictionary in datos["cargas"]:
		var carga: SimCargaTrifasica = sim.componente(c["id"])
		var linea := HBoxContainer.new()
		linea.add_theme_constant_override("separation", 8)
		columna.add_child(linea)
		var esencial := "esencial" if carga.params["esencial"] else "no esencial"
		var texto := _etiqueta("%s (%s): %s kW, %s" % [c["nombre"], esencial, TextoTecnico.numero(carga.params["p_kw"], 0), "conectada" if carga.estado["conectada"] else "desconectada"])
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linea.add_child(texto)
		var b := _boton("Desconectar" if carga.estado["conectada"] else "Conectar", _alternar_carga.bind(c["id"]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		linea.add_child(b)
	columna.add_child(_etiqueta(datos["nota"], "Nota"))
	columna.add_child(_boton("Reiniciar la práctica", _reiniciar))


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
	_textos["luz_" + clave] = etiqueta
	return fila


## Mandos del entrante en el propio panel: velocidad, cierre manual y sincronizador automático.
func _mandos_sincronizacion(columna: VBoxContainer) -> void:
	var entrante: String = args["sincronizar"]
	var q := _interruptor_de(entrante)
	var pms: SimPMS = sim.componente("PMS")
	var mandos := GridContainer.new()
	mandos.columns = 2 if raiz.vertical else 1
	mandos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mandos.add_theme_constant_override("h_separation", 6)
	mandos.add_theme_constant_override("v_separation", 6)
	columna.add_child(mandos)
	var lista: Array = [
		["Velocidad − %s" % entrante, _velocidad.bind(entrante, -1.0)],
		["Velocidad + %s" % entrante, _velocidad.bind(entrante, 1.0)],
		["Abrir %s" % q.id if q.cerrado() else "Cerrar %s" % q.id, _alternar_acb.bind(entrante)],
	]
	if pms.sincronizando() == entrante:
		lista.append(["Cancelar sincronización", _cancelar_sincronizacion])
	else:
		lista.append(["Sincronizar automáticamente", sincronizar_automaticamente])
	for m: Array in lista:
		var b := _boton(m[0], m[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mandos.add_child(b)


func sincronizar_automaticamente() -> void:
	var motivo := (sim.componente("PMS") as SimPMS).sincronizar(args["sincronizar"])
	if not motivo.is_empty():
		_mostrar_aviso("No se puede sincronizar", motivo)
	_comprobar_firma()


func _cancelar_sincronizacion() -> void:
	(sim.componente("PMS") as SimPMS).cancelar_sincronizacion()
	_comprobar_firma()


## El sincronoscopio se conecta al generador entrante elegido.
func _elegir_sincronizar(id: String) -> void:
	var anterior: String = args["sincronizar"]
	sim.desconectar("SY.G1", anterior + ".L1")
	sim.desconectar("SY.G2", anterior + ".L2")
	sim.conectar("SY.G1", id + ".L1")
	sim.conectar("SY.G2", id + ".L2")
	args["sincronizar"] = id
	_llenar()
	_actualizar()


func _alternar_pms() -> void:
	var pms: SimPMS = sim.componente("PMS")
	pms.fijar_automatico(not pms.automatico())
	_comprobar_firma()


func _alternar_carga(id: String) -> void:
	var c: SimCargaTrifasica = sim.componente(id)
	if c.estado["conectada"]:
		c.desconectar()
	else:
		c.conectar()
	_comprobar_firma()


func _reiniciar() -> void:
	for clave in ["sim", "pestana", "sincronizar", "eventos"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Panel de un generador ---

func _datos_generador(id: String) -> Dictionary:
	for g: Dictionary in datos["generadores"]:
		if g["id"] == id:
			return g
	return {}


func _panel_generador(columna: VBoxContainer, id: String) -> void:
	var d := _datos_generador(id)
	var g: SimGenerador = sim.componente(id)
	var q: SimInterruptorGenerador = sim.componente(d["interruptor"])
	columna.add_child(_rotulo(d["nombre"]))
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 8)
	fila.add_theme_constant_override("v_separation", 8)
	columna.add_child(fila)
	var i_n: float = q.params["in_a"]
	var p_n: float = g.params["p_kw"]
	var escalas := [
		["g_v", "Tensión", "V", 0.0, 600.0, 484.0, 0],
		["g_a", "Corriente", "A", 0.0, i_n * 1.4, i_n, 0],
		["g_kw", "Potencia", "kW", -p_n * 0.2, p_n * 1.3, p_n, 0],
		["g_hz", "Frecuencia", "Hz", 54.0, 66.0, 63.0, 2],
	]
	for e: Array in escalas:
		var instrumento := InstrumentoAguja.new().configurar(e[1], e[2], e[3], e[4], e[5], e[6])
		fila.add_child(instrumento)
		_instrumentos[e[0]] = instrumento
	var lcd := _tarjeta_base()
	lcd.add_theme_stylebox_override("panel", Tema.caja(COLOR_LCD, Tema.RADIO, 12, 10, BORDE_LCD))
	columna.add_child(lcd)
	var texto_lcd := _etiqueta("")
	texto_lcd.add_theme_color_override("font_color", TEXTO_LCD)
	texto_lcd.add_theme_font_size_override("font_size", 15)
	lcd.add_child(texto_lcd)
	_textos["lcd"] = texto_lcd
	columna.add_child(_luz_con_texto("marcha", "Diésel en marcha", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_luz_con_texto("acb", "Interruptor %s cerrado" % d["interruptor"], LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO))
	columna.add_child(_luz_con_texto("disparo", "Disparo", LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO))
	var mandos := GridContainer.new()
	mandos.columns = 2
	mandos.add_theme_constant_override("h_separation", 6)
	mandos.add_theme_constant_override("v_separation", 6)
	columna.add_child(mandos)
	var lista: Array = [
		["Parar el diésel" if g.en_marcha() else "Arrancar el diésel", _alternar_diesel.bind(id)],
		["Abrir %s" % d["interruptor"] if q.cerrado() else "Cerrar %s" % d["interruptor"], _alternar_acb.bind(id)],
		["Velocidad −", _velocidad.bind(id, -1.0)],
		["Velocidad +", _velocidad.bind(id, 1.0)],
		["Tensión −", _tension.bind(id, -1.0)],
		["Tensión +", _tension.bind(id, 1.0)],
	]
	if q.estado["disparado"]:
		lista.append(["Rearmar %s" % d["interruptor"], _rearmar.bind(id)])
	if g.estado["danado"]:
		lista.append(["Reparar el grupo", _reparar.bind(id)])
	for m: Array in lista:
		var b := _boton(m[0], m[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mandos.add_child(b)


func _interruptor_de(id: String) -> SimInterruptorGenerador:
	return sim.componente(_datos_generador(id)["interruptor"])


func _alternar_diesel(id: String) -> void:
	var g: SimGenerador = sim.componente(id)
	if g.en_marcha():
		g.parar()
	else:
		var motivo := g.arrancar()
		if not motivo.is_empty():
			_mostrar_aviso("No arranca", motivo)
	_comprobar_firma()


func _alternar_acb(id: String) -> void:
	var q := _interruptor_de(id)
	if q.cerrado():
		q.abrir()
	else:
		var motivo := q.cerrar()
		if not motivo.is_empty():
			_mostrar_aviso("No cierra", motivo)
	_comprobar_firma()


func _velocidad(id: String, signo: float) -> void:
	(sim.componente(id) as SimGenerador).ajustar_velocidad(signo * datos["paso_velocidad_hz"])


func _tension(id: String, signo: float) -> void:
	(sim.componente(id) as SimGenerador).ajustar_tension(signo * datos["paso_tension_v"])


func _rearmar(id: String) -> void:
	_interruptor_de(id).rearmar()
	_comprobar_firma()


func _reparar(id: String) -> void:
	var g: SimGenerador = sim.componente(id)
	g.estado["danado"] = false
	_comprobar_firma()


# --- Lecturas ---

func _frecuencia_barras() -> float:
	for d: Dictionary in datos["generadores"]:
		if (sim.componente(d["interruptor"]) as SimInterruptorGenerador).cerrado():
			return (sim.componente(d["id"]) as SimGenerador).frecuencia()
	return 0.0


func _actualizar() -> void:
	if sim.solucion == null:
		sim.paso()
	var sol := sim.solucion
	if _instrumentos.has("bp_v"):
		_instrumentos["bp_v"].valor = sol.entre("BP.L1", "BP.L2").modulo()
		_instrumentos["bp_f"].valor = _frecuencia_barras()
		_actualizar_sincronismo(sol)
		var ma: SimMonitorAislamiento = sim.componente("MA")
		_luces["aislamiento"].encendida = ma.estado["alarma"]
		var lectura := "> 999 MΩ" if ma.estado["mohm"] >= SimMonitorAislamiento.MOHM_MAX else "%s MΩ" % TextoTecnico.numero(ma.estado["mohm"], 2)
		_textos["luz_aislamiento"].text = "%s · alarma por debajo de %s MΩ" % [lectura, TextoTecnico.numero(ma.params["alarma_mohm"], 1)]
		var pms: SimPMS = sim.componente("PMS")
		_textos["pms"].text = "%s. %s" % ["Automático" if pms.automatico() else "Manual", pms.estado["mensaje"]]
	if _instrumentos.has("g_v"):
		_actualizar_generador(_zonas[-1][1])


func _actualizar_sincronismo(sol: SimSolver.Solucion) -> void:
	var sy: SimSincronoscopio = sim.componente("SY")
	var entrante: String = args["sincronizar"]
	var brillos: Array[float] = []
	var v_fase: float = 440.0 / sqrt(3.0)
	for fase in ["L1", "L2", "L3"]:
		brillos.append(sol.entre("%s.%s" % [entrante, fase], "BP.%s" % fase).modulo() / (2.0 * v_fase))
	_dial.actualizar(sy.estado["angulo"], sy.estado["valido"], brillos)
	if not sy.estado["valido"]:
		_textos["sincronismo"].text = "Sin tensión en el entrante o en las barras."
		return
	var desliz: float = sy.estado["deslizamiento_hz"]
	_textos["sincronismo"].text = "Ángulo %s° · deslizamiento %s Hz (%s) · ΔV %s %%" % [
		TextoTecnico.numero(sy.estado["angulo"], 0), TextoTecnico.numero(desliz, 2),
		"rápido" if desliz > 0.0 else "lento", TextoTecnico.numero(sy.estado["dv_pct"], 1)]


func _actualizar_generador(id: String) -> void:
	var g: SimGenerador = sim.componente(id)
	var q := _interruptor_de(id)
	var e := g.estado
	_instrumentos["g_v"].valor = e["v"]
	_instrumentos["g_a"].valor = e["i"]
	_instrumentos["g_kw"].valor = e["p_kw"]
	_instrumentos["g_hz"].valor = e["f"]
	_luces["marcha"].encendida = g.en_marcha()
	_luces["acb"].encendida = q.cerrado()
	_luces["disparo"].encendida = q.estado["disparado"] or e["danado"]
	var s := sqrt(e["p_kw"] * e["p_kw"] + e["q_kvar"] * e["q_kvar"])
	var cos_phi := absf(e["p_kw"]) / s if s > 1.0 else 0.0
	var pms: SimPMS = sim.componente("PMS")
	var lineas := PackedStringArray([
		"%s · MODO %s" % [id, "AUTOMÁTICO (PMS)" if pms.automatico() else "MANUAL"],
		"Estado: %s" % _estado_grupo(g),
		"f %s Hz   V %s V   I %s A" % [_n(e["f"], 2), _n(e["v"], 0), _n(e["i"], 0)],
		"P %s kW   Q %s kVAr   cos φ %s" % [_n(e["p_kw"], 0), _n(e["q_kvar"], 0), _n(cos_phi, 2)],
		"Consignas: %s Hz en vacío · %s V" % [TextoTecnico.numero(e["f_ref"], 2), TextoTecnico.numero(e.get("v_ref", g.params["v_linea"]), 0)],
		"Alarma: %s" % _alarma(g, q),
	])
	_textos["lcd"].text = "\n".join(lineas)


## Sin "-0": un valor que redondea a cero se muestra como cero.
func _n(valor: float, decimales: int) -> String:
	var limite := 0.5 * pow(10.0, -decimales)
	return TextoTecnico.numero(0.0 if absf(valor) < limite else valor, decimales)


func _estado_grupo(g: SimGenerador) -> String:
	if g.estado["danado"]:
		return "DAÑADO"
	if not g.en_marcha():
		return "PARADO"
	return "EN MARCHA" if g.frecuencia() > SimGenerador.F_NOMINAL * SimGenerador.F_EXCITACION else "ARRANCANDO"


func _alarma(g: SimGenerador, q: SimInterruptorGenerador) -> String:
	if g.estado["danado"]:
		return datos["consecuencias"]["generador_danado"]["titulo"]
	var causa: String = q.estado["causa"]
	if causa.is_empty():
		return "ninguna"
	return datos["consecuencias"].get(causa, {}).get("titulo", causa)


func _calcular_firma() -> String:
	var partes := PackedStringArray()
	for d: Dictionary in datos["generadores"]:
		var g: SimGenerador = sim.componente(d["id"])
		var q: SimInterruptorGenerador = sim.componente(d["interruptor"])
		partes.append("%s%s%s%s" % [g.en_marcha(), g.estado["danado"], q.cerrado(), q.estado["disparado"]])
	for c: Dictionary in datos["cargas"]:
		partes.append(str(sim.componente(c["id"]).estado["conectada"]))
	var pms: SimPMS = sim.componente("PMS")
	partes.append("%s%s" % [pms.automatico(), pms.sincronizando()])
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
		for _i in pasos:
			sim.paso()
		_revisar_eventos()
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / ACTUALIZACIONES_POR_SEGUNDO
		_comprobar_firma()
		_actualizar()


func _revisar_eventos() -> void:
	var textos: Dictionary = datos["consecuencias"]
	var eventos := sim.eventos
	for i in range(args["eventos"], eventos.size()):
		var e: Dictionary = eventos[i]
		var c: Dictionary = textos.get(e["tipo"], {})
		if not c.is_empty():
			_mostrar_aviso("%s (%s)" % [c["titulo"], e["componente"]], c["texto"])
	args["eventos"] = eventos.size()
