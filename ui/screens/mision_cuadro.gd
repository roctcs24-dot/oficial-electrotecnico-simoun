extends "res://ui/screens/cuadro.gd"
## Una misión de Guardia en el cuadro principal: los paneles del cuadro y una pestaña Misión con
## el reporte, el procedimiento, el diagnóstico, el trabajo, la prueba en servicio y el libro.
## Los mandos pasan por la misión, que vigila el procedimiento. El estado vive en args para
## sobrevivir al giro del celular.

const LIMITE_OBSERVACION_MS := 6

var mision: MisionCuadro
var _vistos := {}
var _barra_observacion: ProgressBar
var _marcas_objetivos: Array[Label] = []


func construir() -> void:
	_preparar()
	if mision.fin == "accidente":
		_construir_informe_mision(mision, _repetir)
		return
	if mision.fin == "completada":
		_construir_resultado_mision(mision, _repetir)
		return
	super()


func _preparar() -> void:
	if not args.has("mision"):
		var nueva := MisionCuadro.new(raiz.contenido, args["id"])
		args["mision"] = nueva
		args["pestana"] = args.get("pestana_inicial", "mision")
		args["sincronizar"] = "G2"
		args["eventos"] = nueva.sim.eventos.size()
	mision = args["mision"]
	datos = mision.panel
	sim = mision.sim
	operador = mision


func _poner_cabecera() -> void:
	_cabecera(mision.datos["titulo"], mision.datos["equipo"])


func _pestanas_extra() -> Array:
	return [["mision", "Misión"]]


func _llenar_zona(columna: VBoxContainer, id: String) -> void:
	if id == "mision":
		_panel_mision(columna)
	else:
		super(columna, id)


## En una misión no se reinicia la práctica: se repite la misión desde su pestaña.
func _pie_barras(_columna: VBoxContainer) -> void:
	pass


func _permite_reparar() -> bool:
	return false


func _texto(texto: String) -> String:
	return TextoTecnico.expandir(texto, raiz.contenido.glosario(), _vistos)


func _marca(hecho: bool, texto: String) -> String:
	return "✓ %s" % texto if hecho else texto


## Lo que se bloquea: el arranque de un grupo, o el interruptor de una salida.
func _nombre_equipo(id: String) -> String:
	for c: Dictionary in datos["cargas"]:
		if c["id"] == id:
			var nombre: String = c["nombre"]
			return "%s (%s)" % [id, nombre.substr(0, 1).to_lower() + nombre.substr(1)]
	return "el arranque de %s" % id


# --- Pestaña Misión ---

func _panel_mision(columna: VBoxContainer) -> void:
	_marcas_objetivos = []
	_barra_observacion = null
	_vistos = {}
	_seccion_reporte(columna)
	_seccion_procedimiento(columna)
	_seccion_diagnostico(columna)
	_seccion_trabajo(columna)
	_seccion_prueba(columna)
	_seccion_libro(columna)
	columna.add_child(_boton("Repetir la misión desde el principio", _repetir))


func _seccion_reporte(columna: VBoxContainer) -> void:
	var r: Dictionary = mision.datos["reporte"]
	columna.add_child(_rotulo("Reporte de %s" % r["de"]))
	columna.add_child(_texto_rico(_texto(r["texto"])))
	columna.add_child(_etiqueta(r["nota"], "Nota"))
	var pistas: Array = mision.datos.get("pistas", [])
	for i in mision.pistas_usadas:
		columna.add_child(_etiqueta("Pista %d. %s" % [i + 1, pistas[i]]))
	if mision.hay_pista():
		columna.add_child(_boton("Ver una pista (la calificación máxima baja a 2 estrellas)", _pedir_pista))


func _pedir_pista() -> void:
	mision.siguiente_pista()
	_comprobar_firma()


func _seccion_procedimiento(columna: VBoxContainer) -> void:
	var pasos: Array = mision.datos.get("pasos", [])
	if pasos.is_empty() and mision.bloqueables().is_empty():
		return
	columna.add_child(_rotulo("Procedimiento"))
	for p: Dictionary in pasos:
		var hecho := mision.paso_hecho(p["id"])
		var b := _boton(_marca(hecho, p["boton"]), _dar_paso.bind(p["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = hecho
		columna.add_child(b)
	for id: String in mision.bloqueables():
		var nombre := _nombre_equipo(id)
		if mision.bloqueado(id):
			columna.add_child(_etiqueta("✓ Candado y tarjeta en %s." % nombre))
			var verificar := _boton(_marca(mision.verificado(id), "Verificar ausencia de tensión en %s" % id), _verificar.bind(id))
			verificar.alignment = HORIZONTAL_ALIGNMENT_LEFT
			verificar.disabled = mision.verificado(id)
			columna.add_child(verificar)
			columna.add_child(_boton("Quitar el candado y la tarjeta de %s" % id, _desbloquear.bind(id)))
		else:
			var b := _boton("Bloquear %s con candado y tarjeta" % nombre, _bloquear.bind(id))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			columna.add_child(b)


func _dar_paso(id: String) -> void:
	_atender(mision.dar_paso(id))


func _bloquear(id: String) -> void:
	_atender(mision.bloquear(id))


func _desbloquear(id: String) -> void:
	_atender(mision.desbloquear(id))


func _verificar(id: String) -> void:
	_atender(mision.verificar(id))


func _seccion_diagnostico(columna: VBoxContainer) -> void:
	var d: Dictionary = mision.datos["diagnostico"]
	columna.add_child(_rotulo("Diagnóstico"))
	if mision.diagnostico_ok:
		for o: Dictionary in d["opciones"]:
			if o.get("correcta", false):
				columna.add_child(_etiqueta("✓ %s" % o["texto"]))
		return
	columna.add_child(_etiqueta(d["pregunta"], "Nota"))
	for i in d["opciones"].size():
		var b := _boton(d["opciones"][i]["texto"], _diagnosticar.bind(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		columna.add_child(b)


func _diagnosticar(indice: int) -> void:
	_atender(mision.diagnosticar(indice))


func _seccion_trabajo(columna: VBoxContainer) -> void:
	var acciones: Array = mision.datos.get("acciones", [])
	if acciones.is_empty():
		return
	columna.add_child(_rotulo("Trabajo sobre los equipos"))
	columna.add_child(_etiqueta("Los trabajos sobre un equipo se hacen con él bloqueado y, si lo indica el procedimiento, con la ausencia de tensión verificada.", "Nota"))
	for a: Dictionary in acciones:
		var b := _boton(_marca(mision.acciones_hechas.has(a["id"]), a["boton"]), _ejecutar.bind(a["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		columna.add_child(b)


func _ejecutar(id: String) -> void:
	_atender(mision.ejecutar(id))


func _seccion_prueba(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Prueba en servicio"))
	if mision.prueba_ok:
		columna.add_child(_etiqueta("✓ Prueba en servicio superada."))
		return
	columna.add_child(_etiqueta("Deje el cuadro así durante %d s seguidos:" % roundi(mision.tiempo_de_prueba()), "Nota"))
	for o: Dictionary in mision.objetivos():
		var marca := _etiqueta("")
		marca.set_meta("objetivo", o)
		columna.add_child(marca)
		_marcas_objetivos.append(marca)
	_textos["objetivos"] = _etiqueta("", "Nota")
	columna.add_child(_textos["objetivos"])
	if mision.observando():
		_barra_observacion = _barra_avance(mision.avance_observacion())
		columna.add_child(_barra_observacion)
		return
	columna.add_child(_boton("Observar %d s con el tiempo acelerado" % roundi(mision.tiempo_de_prueba()), _observar))


func _observar() -> void:
	mision.observar(mision.tiempo_de_prueba())
	_comprobar_firma()


func _seccion_libro(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Libro de registro"))
	if not mision.mediciones.is_empty():
		for m: String in mision.mediciones:
			columna.add_child(_etiqueta("• %s" % m, "Nota"))
	if not mision.puede_firmar():
		columna.add_child(_etiqueta("Podrá firmar después de confirmar el diagnóstico y superar la prueba en servicio.", "Nota"))
		return
	if not args.has("respuestas"):
		args["respuestas"] = {}
	var campos := mision.campos_libro()
	for i in campos.size():
		columna.add_child(_etiqueta(campos[i]["etiqueta"], "Fuerte"))
		var grupo := ButtonGroup.new()
		for j in campos[i]["opciones"].size():
			var b := _boton(campos[i]["opciones"][j], _elegir_campo.bind(i, j))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.toggle_mode = true
			b.button_group = grupo
			b.set_pressed_no_signal(args["respuestas"].get(i, -1) == j)
			columna.add_child(b)
	columna.add_child(_boton("Firmar el libro", _firmar))


func _elegir_campo(campo: int, opcion: int) -> void:
	args["respuestas"][campo] = opcion


func _firmar() -> void:
	_atender(mision.firmar(args.get("respuestas", {})))


func _repetir() -> void:
	for clave in ["mision", "pestana", "sincronizar", "eventos", "ganados", "respuestas"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Resultados y tiempo ---

## Un final de misión rehace la pantalla entera para mostrar el informe o el resultado.
func _atender(aviso: Dictionary) -> void:
	if not mision.fin.is_empty():
		_registrar_final_mision(mision)
		raiz.reconstruir.call_deferred()
		return
	super(aviso)


func _calcular_firma() -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s" % [super(), mision.hechos.keys(), mision.bloqueos.keys(), mision.verificados.keys(),
		mision.acciones_hechas.size(), mision.diagnostico_ok, mision.prueba_ok, mision.pistas_usadas, mision.observando()]


func _avanzar(pasos: int) -> void:
	if not mision.fin.is_empty():
		return
	if mision.observando():
		var aviso := mision.procesar_observacion(LIMITE_OBSERVACION_MS)
		if is_instance_valid(_barra_observacion):
			_barra_observacion.value = mision.avance_observacion()
		if not aviso.is_empty():
			_atender(aviso)
	else:
		mision.avanzar(pasos * SimSimulacion.PASO_S)
	while not mision.avisos_pendientes.is_empty():
		var a: Dictionary = mision.avisos_pendientes.pop_front()
		_mostrar_aviso(a["titulo"], a["texto"])
	if not mision.fin.is_empty():
		_atender({})


func _actualizar() -> void:
	super()
	for marca in _marcas_objetivos:
		if is_instance_valid(marca):
			var o: Dictionary = marca.get_meta("objetivo")
			marca.text = "%s %s" % ["✓" if mision.condicion(o) else "·", o["texto"]]
	if _textos.has("objetivos") and is_instance_valid(_textos["objetivos"]):
		_textos["objetivos"].text = "Cumplidas todas durante %d de %d s." % [floori(mision.objetivos_s), roundi(mision.tiempo_de_prueba())]
