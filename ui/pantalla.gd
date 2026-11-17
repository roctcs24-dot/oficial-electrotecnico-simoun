class_name Pantalla
extends VBoxContainer
## Base de las pantallas. Se construyen en código y se rehacen al girar el celular.

const ZONA_MUERTA_ARRASTRE := 14
const ANCHO_LECTURA := 900.0

var raiz: Raiz
var args := {}
## Contenedor de avisos de las pantallas que los usan, y los que esperan su turno.
var _avisos: VBoxContainer
var _cola_avisos: Array[Array] = []


func iniciar(raiz_juego: Raiz, argumentos: Dictionary) -> void:
	raiz = raiz_juego
	args = argumentos
	add_theme_constant_override("separation", 10)
	construir()
	if raiz.es_seccion():
		# Empuja la barra al pie aunque la pantalla no tenga nada que se estire; con una
		# proporción ínfima no le quita sitio a la lista desplazable.
		var hueco := Control.new()
		hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hueco.size_flags_stretch_ratio = 0.0001
		hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hueco)
		var barra := BarraNavegacion.new()
		barra.iniciar(raiz, raiz.nombre_actual())
		add_child(barra)


func construir() -> void:
	pass


# --- Marco de simulador (Guardia y Taller) ---

## Dentro del marco, el título va en la placa de la barra superior.
func en_marco() -> bool:
	return raiz != null and raiz.marco != null and raiz.marco.is_ancestor_of(self)


## Potencia de los generadores para el panel derecho del marco: {filas: [{nombre, kw,
## en_linea}], nominal, escenario, tension}. Vacío: el marco usa el escenario del buque.
func generacion_marco() -> Dictionary:
	return {}


## Alarmas activas de la pantalla, como la avería de una misión en curso.
func alarmas_marco() -> Array[String]:
	var r: Array[String] = []
	var m = get("mision")
	if m is MisionBase and m.fin.is_empty():
		r.append(str(m.datos.get("titulo", "")))
	return r


## Las mismas alarmas con sus datos para la lista del marco: {hora, texto, tipo, reconocida} y,
## si tocar la fila lleva a algún sitio, «abrir» con lo que hay que llamar.
func alarmas_marco_detalle() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for t: String in alarmas_marco():
		r.append({"hora": "", "texto": t, "tipo": "alarma"})
	return r


## Consejos propios de la pantalla; vacío: los del panel en data/paneles.json.
func consejos_marco() -> Array:
	return []


func codigo_marco() -> String:
	return raiz.paneles.codigo_de(raiz.nombre_actual(), args)


func _cabecera(titulo: String, nota := "") -> void:
	if en_marco():
		raiz.marco.poner_titulo(titulo, nota)
		return
	var barra := _tarjeta_base("Cabecera")
	add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	barra.add_child(fila)
	# En las secciones de la barra de navegación no hay a dónde volver.
	if raiz.nivel() > 1:
		var volver := _boton("‹ Volver", raiz.volver)
		# Con ajuste de línea, el contenedor lo aplastaría hasta dejarlo sin ancho.
		volver.autowrap_mode = TextServer.AUTOWRAP_OFF
		volver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(volver)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	textos.add_child(_etiqueta(titulo, "Titulo"))
	if not nota.is_empty():
		textos.add_child(_etiqueta(nota, "Nota"))
	# Desde el tercer nivel, un atajo de vuelta al inicio.
	if raiz.nivel() >= 3:
		var inicio := _boton("", raiz.ir_a_seccion.bind("inicio"))
		inicio.icon = VistaSvg.rasterizar("res://art/iconos/inicio.svg", 0.75)
		inicio.expand_icon = true
		inicio.tooltip_text = "Inicio"
		inicio.custom_minimum_size = Vector2(48, 48)
		inicio.add_theme_constant_override("icon_max_width", 24)
		inicio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(inicio)


func _etiqueta(texto: String, variante := "") -> Label:
	var e := Label.new()
	e.text = texto
	e.theme_type_variation = variante
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return e


func _texto_rico(bbcode: String) -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Con el filtro por defecto, el texto no dejaría arrastrar la lista con el dedo.
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	t.text = bbcode
	return t


func _boton(texto: String, al_pulsar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Con el filtro por defecto, un botón impediría arrastrar la lista con el dedo.
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(al_pulsar)
	return b


## opciones: color del área, avance (0 a 1), hecho y siguiente; ver FilaMenu.
func _fila(titulo: String, detalle: String, al_pulsar: Callable, icono := "", estado := "", activa := true, opciones := {}) -> FilaMenu:
	var f := FilaMenu.new()
	f.iniciar(titulo, detalle, icono, estado, activa, opciones)
	f.pulsada.connect(al_pulsar)
	return f


## Rótulo de sección, en mayúsculas pequeñas.
func _rotulo(texto: String) -> Label:
	var e := _etiqueta(texto.to_upper(), "Rotulo")
	return e


func _barra_avance(fraccion: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = fraccion
	b.show_percentage = false
	b.custom_minimum_size.y = 6.0
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Limita el ancho del texto en pantallas grandes: las líneas muy largas cansan al leer.
func _ancho_lectura(contenido_columna: Control) -> Control:
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sobrante := maxf(raiz.ancho_contenido() - ANCHO_LECTURA, 0.0) / 2.0
	margen.add_theme_constant_override("margin_left", int(sobrante))
	margen.add_theme_constant_override("margin_right", int(sobrante))
	margen.add_child(contenido_columna)
	return margen


func _desplazable() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.scroll_deadzone = ZONA_MUERTA_ARRASTRE
	s.scroll_started.connect(cancelar_pulsaciones.bind(s))
	return s


## Al empezar a arrastrar se anula el botón bajo el dedo, para que no se active al soltar.
## Deshabilitar un botón es lo único que borra su pulsación en curso.
static func cancelar_pulsaciones(nodo: Node) -> void:
	if nodo is BaseButton and not nodo.disabled:
		nodo.disabled = true
		nodo.disabled = false
	elif nodo is FilaMenu:
		nodo.cancelar()
	elif nodo.has_method("cancelar_toque"):
		nodo.cancelar_toque()
	for hijo in nodo.get_children():
		cancelar_pulsaciones(hijo)


func _columna(separacion := 10) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_constant_override("separation", separacion)
	return c


func _aviso(texto: String) -> Control:
	var caja := _tarjeta_base("Aviso")
	caja.add_child(_etiqueta(texto))
	return caja


## De uno en uno: varios a la vez dejarían los botones fuera de una pantalla apaisada.
## «tipo» va al registro de eventos del marco: «alarma» para las consecuencias de la simulación,
## como un disparo, y «evento» para los avisos de manejo.
func _mostrar_aviso(titulo: String, texto: String, tipo := "evento") -> void:
	if raiz != null:
		raiz.eventos.registrar(titulo, tipo, codigo_marco() if en_marco() else "")
	_poner_aviso(titulo, texto, tipo)


## Contenedor de los avisos: dentro del marco, una capa centrada sobre toda la pantalla; fuera,
## una columna al principio de la pantalla.
func _capa_avisos() -> VBoxContainer:
	if en_marco():
		return AvisoAri.CapaAvisos.new()
	return _columna(6)


func _poner_aviso(titulo: String, texto: String, tipo := "evento") -> void:
	for hijo in _avisos.get_children():
		if hijo.get_meta("titulo", "") == titulo:
			return
	for pendiente: Array in _cola_avisos:
		if pendiente[0] == titulo:
			return
	if _avisos.get_child_count() > 0:
		_cola_avisos.append([titulo, texto, tipo])
		return
	if _avisos is AvisoAri.CapaAvisos:
		var hora := Time.get_time_string_from_system()
		var codigo := codigo_marco()
		var aviso := AvisoAri.new(titulo, texto, tipo, ("%s  ·  %s" % [codigo, hora]) if not codigo.is_empty() else hora)
		aviso.set_meta("titulo", titulo)
		aviso.boton.pressed.connect(_cerrar_aviso.bind(aviso))
		_avisos.add_child(aviso)
		return
	var caja := _tarjeta_base("Aviso")
	caja.set_meta("titulo", titulo)
	_avisos.add_child(caja)
	var columna := _columna(4)
	caja.add_child(columna)
	columna.add_child(_etiqueta(titulo, "Subtitulo"))
	columna.add_child(_etiqueta(texto))
	columna.add_child(_boton("Entendido", _cerrar_aviso.bind(caja)))


func _cerrar_aviso(caja: Control) -> void:
	_avisos.remove_child(caja)
	caja.queue_free()
	if not _cola_avisos.is_empty():
		var siguiente: Array = _cola_avisos.pop_front()
		_poner_aviso(siguiente[0], siguiente[1], siguiente[2] if siguiente.size() > 2 else "evento")


# --- Final de las misiones de Guardia ---

## Suma la misión al progreso una sola vez, con sus faltas y su accidente para repasarlos.
func _registrar_final_mision(m: MisionBase) -> void:
	if args.has("ganados"):
		return
	var completada := m.fin == "completada"
	args["ganados"] = raiz.partida.registrar_mision(m.id(), m.estrellas(), completada)
	for f: Dictionary in m.faltas:
		raiz.partida.registrar_error(f["tema"])
	if not completada:
		raiz.partida.registrar_error(m.accidente["tema"])
	raiz.partida.guardar_danos_mision(m.id(), m.danos() if not completada else {})


func _construir_informe_mision(m: MisionBase, repetir: Callable) -> void:
	var a: Dictionary = m.accidente
	_cabecera(a.get("cabecera", "Informe de accidente"), m.datos["equipo"])
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
	columna.add_child(_etiqueta("Misión terminada sin puntos. %s" % a.get("repasar", "Repase la lección de bloqueo y etiquetado antes de volver a intentarlo."), "Nota"))
	columna.add_child(_boton("Repetir la misión", repetir))
	columna.add_child(_boton("Volver a la lista", raiz.volver))


func _construir_resultado_mision(m: MisionBase, repetir: Callable) -> void:
	_cabecera("Misión completada", m.datos["equipo"])
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	columna.add_child(_etiqueta("Calificación: %d de 3 estrellas" % m.estrellas(), "Subtitulo"))
	var ganados: int = args.get("ganados", 0)
	if ganados > 0:
		columna.add_child(_etiqueta("Puntos obtenidos: %d." % ganados))
	if m.pistas_usadas > 0:
		columna.add_child(_etiqueta("Pistas usadas: %d." % m.pistas_usadas))
	if not m.faltas.is_empty():
		columna.add_child(_rotulo("Faltas del procedimiento"))
		for f: Dictionary in m.faltas:
			columna.add_child(_etiqueta(f["titulo"], "Fuerte"))
			columna.add_child(_etiqueta(f["texto"], "Nota"))
	columna.add_child(_rotulo("Para saber más"))
	for fuente: String in m.datos.get("para_saber_mas", []):
		columna.add_child(_etiqueta("• %s" % fuente, "Nota"))
	columna.add_child(_boton("Repetir la misión", repetir))
	columna.add_child(_boton("Volver a la lista", raiz.volver))


## Con el filtro por defecto, una tarjeta impediría arrastrar la lista con el dedo.
func _tarjeta_base(variante := "") -> PanelContainer:
	var caja := PanelContainer.new()
	caja.theme_type_variation = variante
	caja.mouse_filter = Control.MOUSE_FILTER_PASS
	return caja
