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


func construir() -> void:
	pass


func _cabecera(titulo: String, nota := "") -> void:
	var barra := _tarjeta_base("Cabecera")
	add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	barra.add_child(fila)
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


func _fila(titulo: String, detalle: String, al_pulsar: Callable, icono := "", estado := "", activa := true) -> FilaMenu:
	var f := FilaMenu.new()
	f.iniciar(titulo, detalle, icono, estado, activa)
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
	var sobrante := maxf(raiz.size.x - ANCHO_LECTURA, 0.0) / 2.0
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
func _mostrar_aviso(titulo: String, texto: String) -> void:
	for hijo in _avisos.get_children():
		if hijo.get_meta("titulo", "") == titulo:
			return
	for pendiente: Array in _cola_avisos:
		if pendiente[0] == titulo:
			return
	if _avisos.get_child_count() > 0:
		_cola_avisos.append([titulo, texto])
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
		_mostrar_aviso(siguiente[0], siguiente[1])


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
