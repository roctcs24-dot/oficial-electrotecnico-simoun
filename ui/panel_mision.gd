class_name PanelMision
extends RefCounted
## La pestaña Misión de las pantallas de Guardia del cuadro y de la planta: reporte, pistas,
## procedimiento, diagnóstico, trabajo, prueba en servicio y libro. La misión puede ser una
## MisionCuadro o una MisionPlanta: las dos ofrecen los mismos métodos de procedimiento.
## Las órdenes pasan por pantalla._atender, que muestra el aviso y rehace los mandos.

## La pantalla que contiene el panel: pone los controles, args, _atender y _nombre_equipo.
var pantalla
## MisionCuadro o MisionPlanta.
var mision
var marcas_objetivos: Array[Label] = []
var barra_observacion: ProgressBar
var texto_objetivos: Label
var _vistos := {}


func _init(pantalla_mision: Pantalla, mision_actual: MisionBase) -> void:
	pantalla = pantalla_mision
	mision = mision_actual


func construir(columna: VBoxContainer, repetir: Callable) -> void:
	marcas_objetivos = []
	barra_observacion = null
	texto_objetivos = null
	_vistos = {}
	_seccion_reporte(columna)
	_seccion_procedimiento(columna)
	_seccion_diagnostico(columna)
	_seccion_trabajo(columna)
	_seccion_prueba(columna)
	_seccion_libro(columna)
	columna.add_child(pantalla._boton("Repetir la misión desde el principio", repetir))


func _texto(texto: String) -> String:
	return TextoTecnico.expandir(texto, pantalla.raiz.contenido.glosario(), _vistos)


func _marca(hecho: bool, texto: String) -> String:
	return "✓ %s" % texto if hecho else texto


func _boton_izquierda(texto: String, accion: Callable) -> Button:
	var b: Button = pantalla._boton(texto, accion)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b


func _seccion_reporte(columna: VBoxContainer) -> void:
	var r: Dictionary = mision.datos["reporte"]
	columna.add_child(pantalla._rotulo("Reporte de %s" % r["de"]))
	columna.add_child(pantalla._texto_rico(_texto(r["texto"])))
	columna.add_child(pantalla._etiqueta(r["nota"], "Nota"))
	var pistas: Array = mision.datos.get("pistas", [])
	for i in mision.pistas_usadas:
		columna.add_child(pantalla._etiqueta(TextoTecnico.unir_unidades("Pista %d. %s" % [i + 1, pistas[i]])))
	if mision.hay_pista():
		columna.add_child(pantalla._boton("Ver una pista (la calificación máxima baja a 2 estrellas)", pedir_pista))


func pedir_pista() -> void:
	mision.siguiente_pista()
	pantalla._comprobar_firma()


func _seccion_procedimiento(columna: VBoxContainer) -> void:
	var pasos: Array = mision.datos.get("pasos", [])
	if pasos.is_empty() and mision.bloqueables().is_empty():
		return
	columna.add_child(pantalla._rotulo("Procedimiento"))
	for p: Dictionary in pasos:
		var hecho: bool = mision.paso_hecho(p["id"])
		var b := _boton_izquierda(_marca(hecho, p["boton"]), dar_paso.bind(p["id"]))
		b.disabled = hecho
		columna.add_child(b)
	for id: String in mision.bloqueables():
		var nombre: String = pantalla._nombre_equipo(id)
		if mision.bloqueado(id):
			columna.add_child(pantalla._etiqueta("✓ Candado y tarjeta en %s." % nombre))
			var verificar_b := _boton_izquierda(_marca(mision.verificado(id), "Verificar ausencia de tensión en %s" % id), verificar.bind(id))
			verificar_b.disabled = mision.verificado(id)
			columna.add_child(verificar_b)
			columna.add_child(pantalla._boton("Quitar el candado y la tarjeta de %s" % id, desbloquear.bind(id)))
		else:
			columna.add_child(_boton_izquierda("Bloquear %s con candado y tarjeta" % nombre, bloquear.bind(id)))


func dar_paso(id: String) -> void:
	pantalla._atender(mision.dar_paso(id))


func bloquear(id: String) -> void:
	pantalla._atender(mision.bloquear(id))


func desbloquear(id: String) -> void:
	pantalla._atender(mision.desbloquear(id))


func verificar(id: String) -> void:
	pantalla._atender(mision.verificar(id))


func _seccion_diagnostico(columna: VBoxContainer) -> void:
	var d: Dictionary = mision.datos["diagnostico"]
	columna.add_child(pantalla._rotulo("Diagnóstico"))
	if mision.diagnostico_ok:
		for o: Dictionary in d["opciones"]:
			if o.get("correcta", false):
				columna.add_child(pantalla._etiqueta("✓ %s" % o["texto"]))
		return
	columna.add_child(pantalla._etiqueta(d["pregunta"], "Nota"))
	for i in d["opciones"].size():
		columna.add_child(_boton_izquierda(TextoTecnico.unir_unidades(d["opciones"][i]["texto"]), diagnosticar.bind(i)))


func diagnosticar(indice: int) -> void:
	pantalla._atender(mision.diagnosticar(indice))


func _seccion_trabajo(columna: VBoxContainer) -> void:
	var acciones: Array = mision.datos.get("acciones", [])
	if acciones.is_empty():
		return
	columna.add_child(pantalla._rotulo("Trabajo sobre los equipos"))
	columna.add_child(pantalla._etiqueta(mision.datos.get("nota_trabajo", "Los trabajos sobre un equipo se hacen con él bloqueado y, si lo indica el procedimiento, con la ausencia de tensión verificada."), "Nota"))
	for a: Dictionary in acciones:
		columna.add_child(_boton_izquierda(_marca(mision.acciones_hechas.has(a["id"]), TextoTecnico.unir_unidades(a["boton"])), ejecutar.bind(a["id"])))


func ejecutar(id: String) -> void:
	pantalla._atender(mision.ejecutar(id))


func _seccion_prueba(columna: VBoxContainer) -> void:
	columna.add_child(pantalla._rotulo("Prueba en servicio"))
	if mision.prueba_ok:
		columna.add_child(pantalla._etiqueta("✓ Prueba en servicio superada."))
		return
	var instruccion := "Deje la planta así durante %d s seguidos:" if mision is MisionPlanta else "Deje el cuadro así durante %d s seguidos:"
	for o: Dictionary in mision.objetivos():
		var marca: Label = pantalla._etiqueta("")
		marca.set_meta("objetivo", o)
		columna.add_child(marca)
		marcas_objetivos.append(marca)
	texto_objetivos = pantalla._etiqueta("", "Nota")
	columna.add_child(texto_objetivos)
	if mision.observando():
		barra_observacion = pantalla._barra_avance(mision.avance_observacion())
		columna.add_child(barra_observacion)
		return
	columna.add_child(pantalla._boton("Observar %d s con el tiempo acelerado" % roundi(mision.tiempo_de_prueba()), observar))


func observar() -> void:
	mision.observar(mision.tiempo_de_prueba())
	pantalla._comprobar_firma()


func _seccion_libro(columna: VBoxContainer) -> void:
	columna.add_child(pantalla._rotulo("Libro de registro"))
	for m: String in mision.mediciones:
		columna.add_child(pantalla._etiqueta("• %s" % m, "Nota"))
	if not mision.puede_firmar():
		columna.add_child(pantalla._etiqueta("Podrá firmar después de confirmar el diagnóstico y superar la prueba en servicio.", "Nota"))
		return
	var args: Dictionary = pantalla.args
	if not args.has("respuestas"):
		args["respuestas"] = {}
	var campos: Array = mision.campos_libro()
	for i in campos.size():
		columna.add_child(pantalla._etiqueta(campos[i]["etiqueta"], "Fuerte"))
		var grupo := ButtonGroup.new()
		for j in campos[i]["opciones"].size():
			var b := _boton_izquierda(TextoTecnico.unir_unidades(campos[i]["opciones"][j]), elegir_campo.bind(i, j))
			b.toggle_mode = true
			b.button_group = grupo
			b.set_pressed_no_signal(args["respuestas"].get(i, -1) == j)
			columna.add_child(b)
	columna.add_child(pantalla._boton("Firmar el libro", firmar))


func elegir_campo(campo: int, opcion: int) -> void:
	pantalla.args["respuestas"][campo] = opcion


func firmar() -> void:
	pantalla._atender(mision.firmar(pantalla.args.get("respuestas", {})))


## Lo que cambia el estado del panel y obliga a rehacerlo.
func firma() -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s" % [mision.hechos.keys(), mision.bloqueos.keys(), mision.verificados.keys(),
		mision.acciones_hechas.size(), mision.diagnostico_ok, mision.prueba_ok, mision.pistas_usadas, mision.observando()]


func actualizar() -> void:
	for marca in marcas_objetivos:
		if is_instance_valid(marca):
			var o: Dictionary = marca.get_meta("objetivo")
			marca.text = "%s %s" % ["✓" if mision.condicion(o) else "·", TextoTecnico.unir_unidades(o["texto"])]
	if is_instance_valid(texto_objetivos):
		texto_objetivos.text = "Cumplidas todas durante %d de %d s." % [floori(mision.objetivos_s), roundi(mision.tiempo_de_prueba())]
	if is_instance_valid(barra_observacion):
		barra_observacion.value = mision.avance_observacion()


## Un paso de tiempo de la pantalla: la observación acelerada o el tiempo normal. Devuelve el
## aviso con que terminó la observación, o {}.
func avanzar(limite_observacion_ms: int, segundos: float, paso: float) -> Dictionary:
	if not mision.fin.is_empty():
		return {}
	var aviso := {}
	if mision.observando():
		aviso = mision.procesar_observacion(limite_observacion_ms)
		if is_instance_valid(barra_observacion):
			barra_observacion.value = mision.avance_observacion()
	elif mision is MisionPlanta:
		(mision as MisionPlanta).avanzar(segundos, paso)
	else:
		mision.avanzar(segundos)
	while not mision.avisos_pendientes.is_empty():
		var a: Dictionary = mision.avisos_pendientes.pop_front()
		pantalla._mostrar_aviso(a["titulo"], a["texto"])
	return aviso
