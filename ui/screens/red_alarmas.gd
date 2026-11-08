extends Pantalla
## Puesto de alarmas de sala de máquinas, su red Modbus RTU por RS-485 y la pantalla local
## Omron de un MYCOM. Se practica a reconocer alarmas, leer el diagnóstico de la red, medir
## los terminadores, ajustar direcciones y velocidades y usar la HMI. La red, el puesto y la
## pantalla viven en args para sobrevivir al giro del celular.
## Las misiones de Guardia de la red extienden esta pantalla.

const PESTANAS := [["puesto", "Puesto de alarmas"], ["red", "Red RS-485"], ["hmi", "Pantalla MYCOM"], ["averias", "Averías"]]
const PAGINAS_HMI := [["principal", "Principal"], ["alarmas", "Alarmas"], ["tendencia", "Tendencia"], ["ajustes", "Ajustes"]]
const ACTUALIZACIONES_POR_SEGUNDO := 8.0
const PRUEBA_LAMPARAS_S := 3.0
const TEXTOS_ESTADO := {"activa": "SIN RECONOCER", "reconocida": "RECONOCIDA", "retorno": "NORMAL, SIN RECONOCER"}
const TEXTOS_COMUNICACION := {"ok": "comunica", "intermitente": "errores intermitentes", "falla": "SIN COMUNICACIÓN"}
const PANTALLA_FONDO := Color("0f1a22")
const PANTALLA_TEXTO := Color("dfe8ee")
const ROJO_TEXTO := Color("ff6b5e")
const AMBAR_TEXTO := Color("ffc24a")

var red: SimRedModbus
var puesto: SimSistemaAlarmas
var hmi: SimPantallaHMI
var _zona: VBoxContainer
var _desplazable_zona: ScrollContainer
var _botones_pestana := {}
var _textos := {}
var _luces := {}
## Luces que parpadean: [LuzPiloto, rápido (sin reconocer) o lento (retorno)].
var _parpadeantes: Array[Array] = []
var _vista: VistaRed
var _grafico: GraficoTendencia
var _firma := ""
var _t := 0.0
var _hasta_lectura := 0.0


func construir() -> void:
	_preparar()
	_cabecera(_titulo(), "Práctica libre · arquitectura y valores típicos: verificar a bordo")
	_avisos = _columna(6)
	add_child(_avisos)
	_construir_extra()
	add_child(_fila_pestanas())
	_desplazable_zona = _desplazable()
	add_child(_desplazable_zona)
	_zona = _columna(8)
	_desplazable_zona.add_child(_zona)
	_llenar()


func _titulo() -> String:
	return red.datos.get("nombre", "Red Modbus")


## Para las misiones: lo que va entre la cabecera y las pestañas.
func _construir_extra() -> void:
	pass


func _preparar() -> void:
	if not args.has("red"):
		args["red"] = raiz.contenido.red(args.get("red_id", "sala_maquinas"))
		args["puesto"] = SimSistemaAlarmas.desde_red(args["red"])
		args["hmi"] = SimPantallaHMI.new(args["red"])
		args["pestana"] = args.get("pestana", "puesto")
		args["seleccion"] = "PA"
		args["pagina_hmi"] = args.get("pagina_hmi_inicial", "principal")
		args["medida"] = ""
		args["prueba_hasta"] = -1.0
		args["oculta"] = ""
		_preparar_extra()
	red = args["red"]
	puesto = args["puesto"]
	hmi = args["hmi"]


func _preparar_extra() -> void:
	pass


## Para las misiones: se llama después de cada acción del jugador sobre la red o el puesto.
func _al_actuar(_accion: String, _detalle := {}) -> void:
	pass


func _pestanas() -> Array:
	return PESTANAS


func _fila_pestanas() -> Control:
	var rejilla := GridContainer.new()
	rejilla.columns = 2 if raiz.vertical else 4
	rejilla.add_theme_constant_override("h_separation", 4)
	rejilla.add_theme_constant_override("v_separation", 4)
	var grupo := ButtonGroup.new()
	for p: Array in _pestanas():
		var b := _boton(p[1], _elegir_pestana.bind(p[0]))
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["pestana"] == p[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(b)
		_botones_pestana[p[0]] = b
	return rejilla


func _elegir_pestana(id: String) -> void:
	args["pestana"] = id
	_al_actuar("pestana", {"pestana": id})
	for clave: String in _botones_pestana:
		_botones_pestana[clave].set_pressed_no_signal(clave == id)
	_desplazable_zona.scroll_vertical = 0
	_llenar()


func _llenar() -> void:
	_textos = {}
	_luces = {}
	_parpadeantes = []
	_vista = null
	_grafico = null
	for hijo in _zona.get_children():
		_zona.remove_child(hijo)
		hijo.queue_free()
	match args["pestana"]:
		"puesto":
			_panel_puesto(_zona)
		"red":
			_panel_red(_zona)
		"hmi":
			_panel_hmi(_zona)
		"averias":
			_panel_averias(_zona)
		_:
			_panel_extra(_zona, args["pestana"])
	_firma = _calcular_firma()
	_actualizar()


## Para las misiones: pestañas propias.
func _panel_extra(_columna_destino: VBoxContainer, _pestana: String) -> void:
	pass


func _rehacer() -> void:
	var desplazado := _desplazable_zona.scroll_vertical
	_llenar()
	_restaurar.call_deferred(desplazado)


func _restaurar(desplazado: int) -> void:
	if is_instance_valid(_desplazable_zona):
		_desplazable_zona.scroll_vertical = desplazado


func _rejilla(columnas := 2) -> GridContainer:
	var rejilla := GridContainer.new()
	rejilla.columns = columnas
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	return rejilla


func _agregar_a(padre: Control, b: Control) -> Control:
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(b)
	return b


func _texto_de(clave: String, texto := "", variante := "") -> Label:
	var e := _etiqueta(texto, variante)
	_textos[clave] = e
	return e


func _luz(clave: String, apagado: Color, encendido: Color, lado := 28.0) -> LuzPiloto:
	var luz := LuzPiloto.new()
	luz.color_apagado = apagado
	luz.color_encendido = encendido
	luz.custom_minimum_size = Vector2(lado, lado)
	if not clave.is_empty():
		_luces[clave] = luz
	return luz


func _fila_luz(luz: LuzPiloto, texto: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.add_child(luz)
	var e := _etiqueta(texto)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(e)
	return fila


func _caja_pantalla(fondo: Color, borde: Color, grosor := 10) -> PanelContainer:
	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 12 + grosor
	estilo.content_margin_right = 12 + grosor
	estilo.content_margin_top = 10 + grosor
	estilo.content_margin_bottom = 10 + grosor
	caja.add_theme_stylebox_override("panel", estilo)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.mouse_filter = Control.MOUSE_FILTER_PASS
	return caja


func _etiqueta_color(texto: String, color: Color, tam := 0) -> Label:
	var e := _etiqueta(texto)
	e.add_theme_color_override("font_color", color)
	if tam > 0:
		e.add_theme_font_size_override("font_size", tam)
	return e


# --- Puesto de alarmas ---

func _panel_puesto(columna: VBoxContainer) -> void:
	columna.add_child(_etiqueta("Pantalla del puesto de alarmas. Una alarma nueva parpadea y hace sonar la bocina. Silenciar solo apaga la bocina; reconocer confirma que usted ha visto la alarma.", "Nota"))
	var pantalla := _caja_pantalla(PANTALLA_FONDO, Color("3a4248"), 12)
	columna.add_child(pantalla)
	var interior := _columna(6)
	pantalla.add_child(interior)
	var cabeza := HBoxContainer.new()
	interior.add_child(cabeza)
	var titulo := _etiqueta_color("ALARMAS GENERALES", PANTALLA_TEXTO, 18)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabeza.add_child(titulo)
	var hora := _etiqueta_color("", PANTALLA_TEXTO)
	hora.autowrap_mode = TextServer.AUTOWRAP_OFF
	_textos["hora"] = hora
	cabeza.add_child(hora)
	var lista := puesto.visibles()
	if lista.is_empty():
		interior.add_child(_etiqueta_color("Sin alarmas activas.", Color("8fd9a8")))
	for p: Dictionary in lista:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		interior.add_child(fila)
		var luz := _luz("", LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO, 24.0)
		luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(luz)
		if p["estado"] == "reconocida":
			luz.encendida = true
		else:
			_parpadeantes.append([luz, p["estado"] == "activa"])
		var textos := _columna(0)
		fila.add_child(textos)
		var color := ROJO_TEXTO if p["estado"] == "activa" else (AMBAR_TEXTO if p["estado"] == "retorno" else PANTALLA_TEXTO)
		textos.add_child(_etiqueta_color("%s  %s" % [puesto.hora(p["desde"]), p["texto"]], color))
		textos.add_child(_etiqueta_color(TEXTOS_ESTADO[p["estado"]], Color("9fb0bb"), 13))
	var botones := _rejilla(3 if not raiz.vertical else 2)
	columna.add_child(botones)
	_agregar_a(botones, _boton("Silenciar bocina", _silenciar))
	_agregar_a(botones, _boton("Reconocer", _reconocer))
	_agregar_a(botones, _boton("Prueba de lámparas", _probar_lamparas))
	var indicadores := _rejilla(2)
	columna.add_child(indicadores)
	_agregar_a(indicadores, _fila_luz(_luz("bocina", LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO), "Bocina"))
	_agregar_a(indicadores, _fila_luz(_luz("extension", LuzPiloto.AMBAR_APAGADO, LuzPiloto.AMBAR_ENCENDIDO), "Extensión a camarotes"))
	columna.add_child(_rotulo("Valores medidos"))
	for s: Dictionary in red.sondeo:
		var d: Dictionary = s["datos"]
		columna.add_child(_texto_de("com_%d" % int(d["direccion"]), "", "Subtitulo"))
		var valores := _texto_de("val_%d" % int(d["direccion"]))
		columna.add_child(valores)
	columna.add_child(_rotulo("Historial"))
	columna.add_child(_texto_de("historial"))


func _silenciar() -> void:
	puesto.silenciar()
	_al_actuar("silenciar")
	_actualizar()


func _reconocer() -> void:
	puesto.reconocer()
	_al_actuar("reconocer")
	_comprobar_firma()


func _probar_lamparas() -> void:
	args["prueba_hasta"] = puesto.reloj + PRUEBA_LAMPARAS_S
	_al_actuar("prueba_lamparas")


func _texto_valor(v: float, decimales: int, unidad: String) -> String:
	if is_nan(v):
		return "####"
	return ("%s %s" % [TextoTecnico.numero(v, decimales), unidad]).strip_edges()


func _actualizar_puesto() -> void:
	_textos["hora"].text = puesto.hora()
	var prueba := puesto.reloj < float(args["prueba_hasta"])
	_luces["bocina"].encendida = puesto.bocina or prueba
	_luces["extension"].encendida = puesto.extension or prueba
	for par: Array in _parpadeantes:
		var rapido: bool = par[1]
		par[0].encendida = prueba or fmod(_t, 0.6 if rapido else 1.6) < (0.3 if rapido else 0.8)
	for s: Dictionary in red.sondeo:
		var d: Dictionary = s["datos"]
		var dir := int(d["direccion"])
		_textos["com_%d" % dir].text = "%s · dirección %d · %s" % [d["nombre"], dir, TEXTOS_COMUNICACION.get(s["estado"], "")]
		var partes: Array[String] = []
		for c: Dictionary in d.get("canales", []):
			var v := red.valor(dir, int(c["reg"]))
			if c.get("digital", false) and not is_nan(v):
				partes.append("%s: %s" % [c["tag"], "ALARMA" if v > 0.5 else "normal"])
			else:
				partes.append("%s: %s" % [c["tag"], _texto_valor(v, int(c.get("decimales", 0)), c.get("unidad", ""))])
		_textos["val_%d" % dir].text = "   ".join(partes)
	var lineas: Array[String] = []
	for h: Dictionary in puesto.historial.slice(0, 12):
		lineas.append("%s  %s  %s" % [h["hora"], h["evento"], h["texto"]])
	_textos["historial"].text = "\n".join(lineas) if not lineas.is_empty() else "Sin eventos."


# --- Red RS-485 ---

func _panel_red(columna: VBoxContainer) -> void:
	columna.add_child(_etiqueta("Bus RS-485 de dos hilos, A y B, con el maestro en un extremo. Toque un equipo para ver y cambiar sus ajustes. LED verde: comunica; ámbar: errores intermitentes; rojo: sin comunicación.", "Nota"))
	_vista = VistaRed.new()
	_vista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vista.preparar(red)
	_vista.seleccion = args["seleccion"]
	_vista.equipo_tocado.connect(_seleccionar)
	columna.add_child(_vista)
	if red.corte >= 0:
		columna.add_child(_boton("Empalmar el cable cortado antes de %s" % red.esclavos[red.corte]["nombre"], _empalmar))
	_panel_equipo(columna)
	columna.add_child(_rotulo("Medición con el multímetro"))
	columna.add_child(_etiqueta("Con los equipos de la red sin alimentación, la resistencia entre A y B en el conector del maestro indica los terminadores: unos 60 Ω con los dos, unos 120 Ω con uno solo.", "Nota"))
	columna.add_child(_boton("Medir Ω entre A y B en el conector del maestro", _medir))
	if not String(args["medida"]).is_empty():
		columna.add_child(_etiqueta(args["medida"]))
	columna.add_child(_rotulo("Diagnóstico del maestro"))
	columna.add_child(_texto_de("ciclo"))
	for s: Dictionary in red.sondeo:
		columna.add_child(_texto_de("diag_%d" % int(s["datos"]["direccion"])))
	columna.add_child(_boton("Poner a cero los contadores", _reponer_contadores))
	columna.add_child(_etiqueta(red.datos.get("nota", ""), "Nota"))


func _seleccionar(id: String) -> void:
	args["seleccion"] = id
	_al_actuar("seleccionar", {"equipo": id})
	_rehacer()


func _equipo_seleccionado() -> Dictionary:
	var id: String = args["seleccion"]
	return red.maestro if id == red.maestro["id"] else red.esclavo(id)


func _panel_equipo(columna: VBoxContainer) -> void:
	var e := _equipo_seleccionado()
	if e.is_empty():
		return
	var es_maestro: bool = e["id"] == red.maestro["id"]
	columna.add_child(_rotulo("Equipo seleccionado"))
	columna.add_child(_etiqueta("%s · %s" % [e["nombre"], e.get("equipo", "")], "Subtitulo"))
	var botones := _rejilla(2)
	columna.add_child(botones)
	if not es_maestro:
		_agregar_a(botones, _boton("Dirección − (%d)" % int(e["direccion"]), _cambiar.bind("direccion", -1)))
		_agregar_a(botones, _boton("Dirección + (%d)" % int(e["direccion"]), _cambiar.bind("direccion", 1)))
	_agregar_a(botones, _boton("Velocidad: %d baudios" % int(e["baudios"]), _cambiar.bind("baudios", 1)))
	_agregar_a(botones, _boton("Formato: %s" % e["formato"], _cambiar.bind("formato", 1)))
	_agregar_a(botones, _boton("Terminador: %s" % ("puesto" if e["terminacion"] else "quitado"), _cambiar.bind("terminacion", 0)))
	if es_maestro:
		_agregar_a(botones, _boton("Tiempo de espera: %d ms" % int(e["timeout_ms"]), _cambiar.bind("timeout_ms", 1)))
	else:
		_agregar_a(botones, _boton("A y B: %s" % ("invertidos" if e["invertido"] else "correctos"), _cambiar.bind("invertido", 0)))
		_agregar_a(botones, _boton("Alimentación: %s" % ("con 24 V" if e["alimentado"] else "sin tensión"), _cambiar.bind("alimentado", 0)))


## Cambia un ajuste del equipo seleccionado: suma pasos, o invierte un sí/no.
func _cambiar(clave: String, paso: int) -> void:
	var e := _equipo_seleccionado()
	var v: Variant
	match clave:
		"direccion":
			v = clampi(int(e["direccion"]) + paso, 1, SimRedModbus.DIRECCION_MAX)
		"baudios":
			v = SimRedModbus.siguiente(SimRedModbus.VELOCIDADES, int(e["baudios"]))
		"formato":
			v = SimRedModbus.siguiente(SimRedModbus.FORMATOS, e["formato"])
		"timeout_ms":
			v = SimRedModbus.siguiente([100, 200, 300, 500, 1000], int(e["timeout_ms"]))
		_:
			v = not bool(e[clave])
	red.ajustar(e["id"], clave, v)
	_al_actuar("ajuste", {"equipo": e["id"], "clave": clave, "valor": v})
	_rehacer()


func _empalmar() -> void:
	red.aplicar({"op": "corte", "antes_de": ""})
	_al_actuar("empalmar")
	_rehacer()


func _medir() -> void:
	var r := red.resistencia_a_b()
	var lectura := "OL (más de 2 kΩ)" if r > 2000.0 else "%s Ω" % TextoTecnico.numero(r * (1.0 + randf_range(-0.01, 0.01)), 1)
	args["medida"] = "Lectura entre A y B: %s" % lectura
	_al_actuar("medir_ab", {"ohmios": r})
	_rehacer()


func _reponer_contadores() -> void:
	red.reponer_contadores()
	_actualizar()


func _actualizar_red() -> void:
	_textos["ciclo"].text = "Tiempo de una vuelta a la tabla de sondeo: %s s" % TextoTecnico.numero(red.ciclo_s, 2)
	for s: Dictionary in red.sondeo:
		var d: Dictionary = s["datos"]
		_textos["diag_%d" % int(d["direccion"])].text = "Dir. %d %s · %s\n   peticiones %d · correctas %d · sin respuesta %d · CRC %d · excepción %d" % [
			int(d["direccion"]), d["nombre"], TEXTOS_COMUNICACION.get(s["estado"], ""),
			s["peticiones"], s["correctas"], s["sin_respuesta"], s["crc"], s["excepciones"]]


# --- Pantalla local Omron del MYCOM ---

func _estilo_boton_hmi(color: Color) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = color
	e.set_corner_radius_all(4)
	e.border_color = color.darkened(0.35)
	e.set_border_width_all(2)
	e.content_margin_left = 8
	e.content_margin_right = 8
	e.content_margin_top = 6
	e.content_margin_bottom = 6
	return e


func _boton_hmi(texto: String, al_pulsar: Callable, activo := false) -> Button:
	var b := _boton(texto, al_pulsar)
	var base := Color("2f6690") if not activo else Color("1b3f5c")
	b.add_theme_stylebox_override("normal", _estilo_boton_hmi(base))
	b.add_theme_stylebox_override("hover", _estilo_boton_hmi(base.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", _estilo_boton_hmi(base.darkened(0.25)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(clave, Color.WHITE)
	b.custom_minimum_size.y = 48.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _panel_hmi(columna: VBoxContainer) -> void:
	columna.add_child(_etiqueta("Pantalla táctil del compresor. Lee su propio controlador por un cable aparte de la red del puesto de alarmas: si el puesto pierde la comunicación con el MYCOM pero esta pantalla sigue dando valores, el problema está en la red, no en el compresor.", "Nota"))
	var marco := _caja_pantalla(Color("e9eff3"), Color("2b2f33"), 16)
	columna.add_child(marco)
	var interior := _columna(8)
	marco.add_child(interior)
	var cabeza := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("1f4e79")
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	cabeza.add_theme_stylebox_override("panel", estilo)
	cabeza.mouse_filter = Control.MOUSE_FILTER_PASS
	interior.add_child(cabeza)
	var fila_cabeza := HBoxContainer.new()
	cabeza.add_child(fila_cabeza)
	var pagina: String = args["pagina_hmi"]
	var nombre_pagina := ""
	for p: Array in PAGINAS_HMI:
		if p[0] == pagina:
			nombre_pagina = p[1]
	var t := _etiqueta_color("%s · %s" % [hmi.datos.get("titulo", ""), nombre_pagina.to_upper()], Color.WHITE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_cabeza.add_child(t)
	fila_cabeza.add_child(_texto_de("hmi_hora"))
	_textos["hmi_hora"].autowrap_mode = TextServer.AUTOWRAP_OFF
	_textos["hmi_hora"].add_theme_color_override("font_color", Color.WHITE)
	if not hmi.comunica():
		var error := _etiqueta_color("ERROR DE COMUNICACIÓN CON EL CONTROLADOR. Revise el cable de la pantalla y la alimentación del controlador.", Color("b3261e"))
		interior.add_child(error)
	match pagina:
		"principal":
			_hmi_principal(interior)
		"alarmas":
			_hmi_alarmas(interior)
		"tendencia":
			_grafico = GraficoTendencia.new()
			_grafico.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_grafico.trazas = hmi.datos.get("tendencia", [])
			_grafico.muestras = SimPantallaHMI.MUESTRAS
			interior.add_child(_grafico)
		"ajustes":
			_hmi_ajustes(interior)
	var navegacion := _rejilla(4 if not raiz.vertical else 2)
	interior.add_child(navegacion)
	for p: Array in PAGINAS_HMI:
		navegacion.add_child(_boton_hmi(p[1], _pagina_hmi.bind(p[0]), p[0] == pagina))


func _hmi_principal(interior: VBoxContainer) -> void:
	var rejilla := _rejilla(2 if raiz.vertical else 4)
	interior.add_child(rejilla)
	for c: Dictionary in hmi.datos.get("campos", []):
		var caja := PanelContainer.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("ffffff")
		estilo.border_color = Color("9fb3c2")
		estilo.set_border_width_all(1)
		estilo.set_content_margin_all(8)
		caja.add_theme_stylebox_override("panel", estilo)
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.mouse_filter = Control.MOUSE_FILTER_PASS
		rejilla.add_child(caja)
		var col := _columna(0)
		caja.add_child(col)
		col.add_child(_etiqueta_color("%s · %s" % [c["sigla"], c["nombre"]], Color("3b4a55"), 13))
		var valor := _etiqueta_color("", Color("12324d"), 22)
		_textos["hmi_%d" % int(c["reg"])] = valor
		col.add_child(valor)


func _hmi_alarmas(interior: VBoxContainer) -> void:
	var lista := hmi.alarmas.visibles()
	if lista.is_empty():
		interior.add_child(_etiqueta_color("Sin alarmas.", Color("2f6f4a")))
	for p: Dictionary in lista:
		var color := Color("b3261e") if p["estado"] == "activa" else Color("8a5a00") if p["estado"] == "retorno" else Color("3b4a55")
		interior.add_child(_etiqueta_color("%s  %s · %s" % [hmi.alarmas.hora(p["desde"]), p["texto"], TEXTOS_ESTADO[p["estado"]]], color))
	interior.add_child(_boton_hmi("Reconocer alarmas", _reconocer_hmi))
	var lineas: Array[String] = []
	for h: Dictionary in hmi.alarmas.historial.slice(0, 6):
		lineas.append("%s  %s  %s" % [h["hora"], h["evento"], h["texto"]])
	if not lineas.is_empty():
		interior.add_child(_etiqueta_color("\n".join(lineas), Color("3b4a55"), 13))


func _hmi_ajustes(interior: VBoxContainer) -> void:
	interior.add_child(_etiqueta_color("Nivel de acceso: %s" % ("técnico" if hmi.nivel_tecnico else "operador"), Color("12324d")))
	interior.add_child(_boton_hmi("Cerrar la sesión de técnico" if hmi.nivel_tecnico else "Iniciar sesión de técnico", _alternar_nivel))
	for a: Dictionary in hmi.datos.get("ajustes", []):
		interior.add_child(_etiqueta_color("%s: %s %s" % [a["texto"], TextoTecnico.numero(a["valor"], int(a.get("decimales", 0))), a["unidad"]], Color("12324d")))
		var fila := _rejilla(2)
		interior.add_child(fila)
		fila.add_child(_boton_hmi("− %s" % TextoTecnico.numero(a["paso"], int(a.get("decimales", 0))), _ajustar_hmi.bind(a["id"], -1)))
		fila.add_child(_boton_hmi("+ %s" % TextoTecnico.numero(a["paso"], int(a.get("decimales", 0))), _ajustar_hmi.bind(a["id"], 1)))
	interior.add_child(_etiqueta_color("Anote en el libro de máquinas cada cambio de ajuste, con el valor anterior y el nuevo. Los ajustes de seguridad del fabricante no se cambian sin autorización del jefe de máquinas.", Color("3b4a55"), 13))


func _pagina_hmi(id: String) -> void:
	args["pagina_hmi"] = id
	_al_actuar("pagina_hmi", {"pagina": id})
	_rehacer()


func _reconocer_hmi() -> void:
	hmi.alarmas.reconocer()
	_al_actuar("reconocer_hmi")
	_rehacer()


func _alternar_nivel() -> void:
	hmi.nivel_tecnico = not hmi.nivel_tecnico
	_rehacer()


func _ajustar_hmi(id: String, pasos: int) -> void:
	var motivo := hmi.cambiar_ajuste(id, pasos)
	if not motivo.is_empty():
		_mostrar_aviso("Ajuste no aceptado", motivo)
		return
	_al_actuar("ajuste_hmi", {"id": id, "pasos": pasos})
	_rehacer()


func _actualizar_hmi() -> void:
	_textos["hmi_hora"].text = hmi.alarmas.hora()
	for c: Dictionary in hmi.datos.get("campos", []):
		var clave := "hmi_%d" % int(c["reg"])
		if _textos.has(clave):
			_textos[clave].text = _texto_valor(hmi.valor(int(c["reg"])), int(c.get("decimales", 0)), c["unidad"])
	if _grafico != null:
		_grafico.series = hmi.tendencia
		_grafico.queue_redraw()


# --- Averías de práctica ---

func _panel_averias(columna: VBoxContainer) -> void:
	columna.add_child(_etiqueta("Provoque una avería y búsquela con el puesto de alarmas, el diagnóstico del maestro, la medición entre A y B y la pantalla local. Para practicar sin saber cuál es, pida una avería al azar.", "Nota"))
	if not String(args["oculta"]).is_empty():
		columna.add_child(_etiqueta("Hay una avería al azar en la red. Encuéntrela y corríjala desde la pestaña Red RS-485.", "Subtitulo"))
		columna.add_child(_boton("Mostrar cuál era la avería", _mostrar_oculta))
	else:
		columna.add_child(_boton("Provocar una avería al azar", _averia_al_azar))
	columna.add_child(_rotulo("Averías concretas"))
	for a: Dictionary in red.datos.get("averias", []):
		columna.add_child(_boton(a["texto"], _provocar.bind(a)))
	columna.add_child(_boton("Reponer la red y el proceso como estaban", _reponer_todo))


func _provocar(a: Dictionary) -> void:
	for op: Dictionary in a["ops"]:
		red.aplicar(op)
	_mostrar_aviso("Avería provocada", a["texto"])


## Solo las averías de la red: las del proceso no se buscan con el diagnóstico de la red.
func _averia_al_azar() -> void:
	var candidatas: Array = []
	for a: Dictionary in red.datos.get("averias", []):
		if a["ops"][0]["op"] in ["ajuste", "corte", "ruido"]:
			candidatas.append(a)
	var a: Dictionary = candidatas.pick_random()
	for op: Dictionary in a["ops"]:
		red.aplicar(op)
	args["oculta"] = a["texto"]
	_rehacer()


func _mostrar_oculta() -> void:
	_mostrar_aviso("La avería era", args["oculta"])
	args["oculta"] = ""
	_rehacer()


func _reponer_todo() -> void:
	for clave in ["red", "puesto", "hmi"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Tiempo y lecturas ---

func _calcular_firma() -> String:
	var partes: Array[String] = [args["pestana"]]
	match args["pestana"]:
		"puesto":
			for p in puesto.visibles():
				partes.append("%s:%s" % [p["id"], p["estado"]])
		"red":
			partes.append(str(red.corte))
		"hmi":
			partes.append(str(hmi.comunica()))
			if args["pagina_hmi"] == "alarmas":
				for p in hmi.alarmas.visibles():
					partes.append("%s:%s" % [p["id"], p["estado"]])
	return "|".join(partes)


func _comprobar_firma() -> void:
	if _calcular_firma() != _firma:
		_rehacer()
	else:
		_actualizar()


func _actualizar() -> void:
	match args["pestana"]:
		"puesto":
			_actualizar_puesto()
		"red":
			_actualizar_red()
		"hmi":
			_actualizar_hmi()


## Avanza la red, el puesto y la pantalla local. Las misiones la usan también.
func _avanzar(delta: float) -> void:
	red.avanzar(delta)
	puesto.actualizar(delta)
	hmi.avanzar(delta)


func _process(delta: float) -> void:
	if red == null:
		return
	_t += delta
	_avanzar(minf(delta, 0.25))
	if args["pestana"] == "puesto":
		var prueba := puesto.reloj < float(args["prueba_hasta"])
		for par: Array in _parpadeantes:
			par[0].encendida = prueba or fmod(_t, 0.6 if par[1] else 1.6) < (0.3 if par[1] else 0.8)
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / ACTUALIZACIONES_POR_SEGUNDO
		_comprobar_firma()
