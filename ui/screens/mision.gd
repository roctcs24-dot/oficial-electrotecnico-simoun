extends PantallaBanco
## Una misión de Guardia: la mesa no se puede recablear, y el procedimiento se sigue desde la
## pestaña Proceso. El estado vive en args para sobrevivir al giro del celular.

const PESTANAS := [["reporte", "Reporte"], ["proceso", "Proceso"], ["pieza", "Equipo"], ["medir", "Medir"], ["libro", "Libro"]]
const LIMITE_OBSERVACION_MS := 6
const MINUTO_S := 60.0
const INSTRUMENTOS := [["multimetro", "Multímetro"], ["megohmetro", "Megóhmetro"]]
## En vertical, el procedimiento necesita más alto que la mesa.
const PROPORCION_VISTA_VERTICAL := 0.8

var mision: MisionGuardia
var _vistos := {}
var _faltas_mostradas := 0
var _barra_observacion: ProgressBar


func construir() -> void:
	if not args.has("mision"):
		_empezar()
	mision = args["mision"]
	_faltas_mostradas = args.get("faltas_mostradas", 0)
	if mision.fin == "accidente":
		_construir_informe()
		return
	if mision.fin == "completada":
		_construir_resultado()
		return
	_cabecera(mision.datos["titulo"], mision.datos["equipo"])
	_montar_banco()


func _empezar() -> void:
	var nueva := MisionGuardia.new(raiz.contenido, args["id"], raiz.partida.danos_mision(args["id"]))
	args["mision"] = nueva
	_iniciar_banco(nueva.mesa, args.get("pestana_inicial", "reporte"), "multimetro")


func _pestanas() -> Array:
	return PESTANAS


func _opciones_instrumento() -> Array:
	return INSTRUMENTOS


func _al_salir() -> void:
	super()
	args["faltas_mostradas"] = _faltas_mostradas
	if mision.fin.is_empty():
		raiz.partida.guardar_danos_mision(args["id"], mision.danos())


func _tras_medir(instrumento: String, modo: String, a: String, b: String, resultado: Dictionary) -> void:
	mision.registrar_medicion(instrumento, modo, a, b, resultado)


## En una misión la mesa no se recablea: un cable tocado no abre ninguna opción.
func _al_tocar_cable(_indice: int) -> void:
	pass


## La lectura se ve en la pestaña Medir: se abre al colocar una punta desde otra.
func _colocar_punta(nodo: String) -> void:
	super(nodo)
	if args["pestana"] != "medir":
		_elegir_pestana("medir")


func _proporcion_vista() -> float:
	return PROPORCION_VISTA_VERTICAL if raiz.vertical else super()


func _mostrar_panel(id: String) -> void:
	match id:
		"reporte":
			_panel_reporte()
		"proceso":
			_panel_proceso()
		"pieza":
			_panel_equipo()
		"medir":
			_panel_medir()
		"libro":
			_panel_libro()


func _texto(texto: String) -> String:
	return TextoTecnico.expandir(texto, raiz.contenido.glosario(), _vistos)


# --- Pestaña Reporte ---

func _panel_reporte() -> void:
	var r: Dictionary = mision.datos["reporte"]
	_panel.add_child(_rotulo("De: %s" % r["de"]))
	_panel.add_child(_texto_rico(_texto(r["texto"])))
	_panel.add_child(_etiqueta(r["nota"], "Nota"))
	var danadas := PackedStringArray()
	for pieza: String in mision.danos():
		if mesa.danada(pieza):
			danadas.append(pieza)
	if not danadas.is_empty():
		_panel.add_child(_aviso("Equipo dañado: %s. Sigue así hasta que cambie el repuesto, con el equipo bloqueado." % ", ".join(danadas)))
	_panel.add_child(_rotulo("Pistas"))
	var usadas: int = mision.pistas_usadas
	var pistas: Array = mision.datos.get("pistas", [])
	for i in usadas:
		_panel.add_child(_etiqueta("%d. %s" % [i + 1, pistas[i]]))
	if mision.hay_pista():
		_panel.add_child(_boton("Ver una pista (la calificación máxima baja a 2 estrellas)", _pedir_pista))
	_panel.add_child(_boton("Ir al procedimiento", _elegir_pestana.bind("proceso")))


func _pedir_pista() -> void:
	mision.siguiente_pista()
	_reconstruir_panel()


# --- Pestaña Proceso ---

func _panel_proceso() -> void:
	if mision.observando():
		_panel.add_child(_etiqueta("Observando el equipo en servicio…", "Subtitulo"))
		_barra_observacion = _barra_avance(mision.avance_observacion())
		_panel.add_child(_barra_observacion)
		return
	_seccion_mando()
	_seccion_aislamiento()
	_seccion_verificacion()
	_seccion_diagnostico()
	_seccion_trabajo()
	_seccion_servicio()


func _marca(hecho: bool, texto: String) -> String:
	return "✓ %s" % texto if hecho else texto


func _seccion_mando() -> void:
	_panel.add_child(_rotulo("Mando local"))
	_agregar_pulsador("S1", "Marcha (S1): mantener pulsado")
	_agregar_pulsador("S0", "Parada (S0): mantener pulsado")
	_panel.add_child(_boton("Rearmar el relé térmico", _rearmar_rele.bind(mision.datos["prueba"]["rele"])))
	var epp := _boton(_marca(mision.hechos.has("epp"), "Colocarse el EPP para trabajar con tensión"), _colocar_epp)
	epp.disabled = mision.hechos.has("epp")
	_panel.add_child(epp)


func _colocar_epp() -> void:
	mision.colocar_epp()
	_reconstruir_panel()


func _seccion_aislamiento() -> void:
	_panel.add_child(_rotulo("Aislar y bloquear"))
	var aviso := _boton(_marca(mision.hechos.has("aviso"), "Avisar al oficial de guardia y obtener el permiso"), _dar_aviso)
	aviso.disabled = mision.hechos.has("aviso")
	_panel.add_child(aviso)
	for a: String in mision.aisladores():
		var cerrado := mision.aislador_cerrado(a)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_panel.add_child(fila)
		var accionar := _boton("Abrir %s" % a if cerrado else "Cerrar %s" % a, _accionar.bind(a, not cerrado))
		accionar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(accionar)
		var con_candado := mision.tiene_candado(a)
		var candado := _boton("Quitar candado" if con_candado else "Candado y tarjeta", _alternar_candado.bind(a))
		candado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(candado)


func _dar_aviso() -> void:
	mision.dar_aviso()
	_reconstruir_panel()


func _accionar(aislador: String, cerrar: bool) -> void:
	_atender(mision.accionar_aislador(aislador, cerrar))


func _alternar_candado(aislador: String) -> void:
	if mision.tiene_candado(aislador):
		_atender(mision.quitar_candado(aislador))
	else:
		_atender(mision.poner_candado(aislador))


func _seccion_verificacion() -> void:
	_panel.add_child(_rotulo("Verificar ausencia de tensión"))
	if mision.verificado():
		_panel.add_child(_etiqueta("✓ Ausencia de tensión verificada."))
	else:
		_panel.add_child(_etiqueta("En orden, con el multímetro en V~. Vale solo con el equipo bloqueado.", "Nota"))
	for p: Dictionary in mision.pasos_verificacion():
		var l := mision.lectura_verificacion(p["id"])
		var texto: String = p["texto"]
		if not l.is_empty():
			texto = "%s: %s V" % [texto, TextoTecnico.numero(l["valor"], 0)]
		var b := _boton(texto, _verificar.bind(p))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_panel.add_child(b)


func _verificar(paso: Dictionary) -> void:
	args["roja"] = paso["a"]
	args["negra"] = paso["b"]
	_actualizar_marcas()
	_atender(mision.verificar(paso, args["multimetro"]))


func _seccion_diagnostico() -> void:
	var d: Dictionary = mision.datos["diagnostico"]
	_panel.add_child(_rotulo("Diagnóstico"))
	if mision.diagnostico_ok:
		for o: Dictionary in d["opciones"]:
			if o.get("correcta", false):
				_panel.add_child(_etiqueta("✓ %s" % o["texto"]))
		return
	_panel.add_child(_etiqueta(d["pregunta"], "Nota"))
	for i in d["opciones"].size():
		var b := _boton(d["opciones"][i]["texto"], _diagnosticar.bind(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_panel.add_child(b)


func _diagnosticar(indice: int) -> void:
	_atender(mision.diagnosticar(indice))


func _seccion_trabajo() -> void:
	_panel.add_child(_rotulo("Trabajo sobre el equipo"))
	_panel.add_child(_etiqueta("Solo con el equipo bloqueado y la ausencia de tensión verificada.", "Nota"))
	for a: Dictionary in mision.datos["acciones"]:
		var b := _boton(_marca(mision.acciones_hechas.has(a["id"]), a["boton"]), _ejecutar.bind(a["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_panel.add_child(b)


func _ejecutar(id: String) -> void:
	_atender(mision.ejecutar(id))


func _seccion_servicio() -> void:
	_panel.add_child(_rotulo("Puesta en servicio"))
	var aviso := _boton(_marca(mision.hechos.has("aviso_energizar"), "Avisar antes de energizar"), _avisar_energizado)
	aviso.disabled = mision.hechos.has("aviso_energizar")
	_panel.add_child(aviso)
	if mision.prueba_ok:
		_panel.add_child(_etiqueta("✓ Prueba en servicio superada."))
		_panel.add_child(_boton("Ir al libro de registro", _elegir_pestana.bind("libro")))
		return
	_panel.add_child(_etiqueta("Con el equipo en marcha, observe durante el tiempo de la prueba.", "Nota"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_panel.add_child(fila)
	for s: float in [MINUTO_S, mision.tiempo_de_prueba()]:
		var b := _boton("Observar %d min" % roundi(s / MINUTO_S), _observar.bind(s))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)


func _avisar_energizado() -> void:
	mision.avisar_energizado()
	_reconstruir_panel()


func _observar(segundos: float) -> void:
	mision.observar(segundos)
	_reconstruir_panel()


# --- Pestaña Equipo ---

func _panel_equipo() -> void:
	var id: String = args["pieza"]
	if id.is_empty() or not mesa.piezas.has(id):
		_panel.add_child(_etiqueta("Toque una pieza en la mesa para ver sus datos.", "Nota"))
		return
	var e := mesa.entrada(mesa.piezas[id]["tipo"])
	_panel.add_child(_etiqueta("%s: %s" % [id, e["nombre"]], "Subtitulo"))
	_panel.add_child(_etiqueta(mesa.estado_pieza(id)))
	var c := mesa.sim.componente(id)
	match c.tipo():
		"guardamotor":
			_panel.add_child(_etiqueta("Se abre y se bloquea desde la pestaña Proceso. Ajuste térmico: %s A." % TextoTecnico.numero(c.params["ajuste_a"], 1), "Nota"))
		"rele_termico":
			_panel.add_child(_boton("Rearmar", _rearmar_rele.bind(id)))
			_agregar_ajuste(c, "Ajuste", 6.0, 50.0)
		"pulsador":
			_agregar_pulsador(id)
		"motor_trifasico":
			_panel.add_child(_etiqueta("Placa: %s kW · %s V Δ · %s A · %s rpm" % [
				TextoTecnico.numero(c.params["p_kw"], 0), TextoTecnico.numero(c.params["v_delta"], 0),
				TextoTecnico.numero(c.params["i_delta"], 0), TextoTecnico.numero(c.params["rpm"], 0)]))
	if mesa.danada(id):
		_panel.add_child(_boton("Cambiar el repuesto", _cambiar_repuesto.bind(id)))


func _cambiar_repuesto(id: String) -> void:
	_atender(mision.cambiar_repuesto(id))


# --- Pestaña Libro ---

func _panel_libro() -> void:
	_panel.add_child(_rotulo("Libro de registro"))
	_panel.add_child(_etiqueta(mision.datos["equipo"], "Nota"))
	_panel.add_child(_rotulo("Mediciones tomadas"))
	if mision.mediciones.is_empty():
		_panel.add_child(_etiqueta("Sin mediciones todavía.", "Nota"))
	for m: Dictionary in mision.mediciones:
		_panel.add_child(_etiqueta(_linea_medicion(m), "Nota"))
	if not mision.puede_firmar():
		_panel.add_child(_aviso("Podrá firmar después de confirmar el diagnóstico y superar la prueba en servicio."))
		return
	if not args.has("respuestas"):
		args["respuestas"] = {}
	var campos := mision.campos_libro()
	for i in campos.size():
		_panel.add_child(_rotulo(campos[i]["etiqueta"]))
		var grupo := ButtonGroup.new()
		for j in campos[i]["opciones"].size():
			var b := _boton(campos[i]["opciones"][j], _elegir_campo.bind(i, j))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.toggle_mode = true
			b.button_group = grupo
			b.set_pressed_no_signal(args["respuestas"].get(i, -1) == j)
			_panel.add_child(b)
	_panel.add_child(_boton("Firmar el libro", _firmar))


func _linea_medicion(m: Dictionary) -> String:
	var r: Dictionary = m["resultado"]
	var lectura := ""
	if m["instrumento"] == "megohmetro":
		lectura = "> 999 MΩ" if r["fuera_de_rango"] else "%s MΩ a %s V" % [TextoTecnico.numero(r["mohm"], 2), m["modo"]]
	elif r["fuera_de_rango"]:
		lectura = "fuera de rango"
	else:
		lectura = "%s %s" % [TextoTecnico.numero(r["valor"], 1), r["unidad"]]
	return "%s — %s: %s" % [m["a"], m["b"], lectura]


func _elegir_campo(campo: int, opcion: int) -> void:
	args["respuestas"][campo] = opcion


func _firmar() -> void:
	_atender(mision.firmar(args.get("respuestas", {})))


# --- Resultados ---

## Muestra el resultado de una acción. Un final de misión rehace la pantalla entera.
func _atender(aviso: Dictionary) -> void:
	if mision.fin == "accidente" or mision.fin == "completada":
		_registrar_final()
		raiz.reconstruir.call_deferred()
		return
	if aviso["tipo"] != "hecho" or not aviso["titulo"].is_empty():
		_mostrar_aviso(aviso["titulo"], aviso["texto"])
	vista.queue_redraw()
	_actualizar_marcas()
	_reconstruir_panel()


func _registrar_final() -> void:
	if args.has("ganados"):
		return
	var completada := mision.fin == "completada"
	args["ganados"] = raiz.partida.registrar_mision(mision.id(), mision.estrellas(), completada)
	for f: Dictionary in mision.faltas:
		raiz.partida.registrar_error(f["tema"])
	raiz.partida.guardar_danos_mision(mision.id(), mision.danos() if not completada else {})


func _construir_informe() -> void:
	var a: Dictionary = mision.accidente
	_cabecera("Informe de accidente", mision.datos["equipo"])
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	columna.add_child(_etiqueta(a["titulo"], "Subtitulo"))
	columna.add_child(_rotulo("Qué ocurrió"))
	columna.add_child(_texto_rico(a["que_ocurrio"]))
	columna.add_child(_rotulo("Causa"))
	columna.add_child(_texto_rico(a["causa"]))
	columna.add_child(_rotulo("Cómo se evita"))
	columna.add_child(_texto_rico(a["como_evitar"]))
	columna.add_child(_etiqueta("Misión terminada sin puntos. Repase la lección de bloqueo y etiquetado antes de volver a intentarlo.", "Nota"))
	columna.add_child(_boton("Repetir la misión", _repetir))
	columna.add_child(_boton("Volver a la lista", raiz.volver))


func _construir_resultado() -> void:
	_cabecera("Misión completada", mision.datos["equipo"])
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	columna.add_child(_etiqueta("Calificación: %d de 3 estrellas" % mision.estrellas(), "Subtitulo"))
	var ganados: int = args.get("ganados", 0)
	if ganados > 0:
		columna.add_child(_etiqueta("Puntos obtenidos: %d." % ganados))
	if mision.pistas_usadas > 0:
		columna.add_child(_etiqueta("Pistas usadas: %d." % mision.pistas_usadas))
	if not mision.faltas.is_empty():
		columna.add_child(_rotulo("Faltas del procedimiento"))
		for f: Dictionary in mision.faltas:
			columna.add_child(_etiqueta(f["titulo"], "Fuerte"))
			columna.add_child(_etiqueta(f["texto"], "Nota"))
	columna.add_child(_rotulo("Para saber más"))
	for fuente: String in mision.datos.get("para_saber_mas", []):
		columna.add_child(_etiqueta("• %s" % fuente, "Nota"))
	columna.add_child(_boton("Repetir la misión", _repetir))
	columna.add_child(_boton("Volver a la lista", raiz.volver))


func _repetir() -> void:
	for clave in ["mision", "mesa", "ganados", "respuestas", "faltas_mostradas", "vista_zoom", "vista_origen"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Tiempo ---

func _avanzar_simulacion(delta: float) -> void:
	if mision.fin != "":
		return
	if mision.observando():
		var aviso := mision.procesar_observacion(LIMITE_OBSERVACION_MS)
		vista.queue_redraw()
		if not aviso.is_empty():
			_revisar_eventos()
			_atender(aviso)
		elif is_instance_valid(_barra_observacion):
			_barra_observacion.value = mision.avance_observacion()
	else:
		super(delta)
	_revisar_faltas()
	_actualizar_panel_puerta()


func _revisar_faltas() -> void:
	mision.anotar_eventos()
	while _faltas_mostradas < mision.faltas.size():
		var f: Dictionary = mision.faltas[_faltas_mostradas]
		_mostrar_aviso(f["titulo"], f["texto"])
		_faltas_mostradas += 1


func _actualizar_panel_puerta() -> void:
	if _estado == null:
		return
	var i := mision.corrientes()
	var linea := "Amperímetro %s / %s / %s A" % [TextoTecnico.numero(i[0], 1), TextoTecnico.numero(i[1], 1), TextoTecnico.numero(i[2], 1)]
	if mision.tiene_monitor():
		linea += " · Monitor %s MΩ" % TextoTecnico.numero(mision.monitor_mohm(), 1)
	_estado.text = linea
