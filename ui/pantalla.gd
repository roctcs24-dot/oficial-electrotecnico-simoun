class_name Pantalla
extends VBoxContainer
## Base de las pantallas. Se construyen en código y se rehacen al girar el celular.

var raiz: Raiz
var args := {}


func iniciar(raiz_juego: Raiz, argumentos: Dictionary) -> void:
	raiz = raiz_juego
	args = argumentos
	add_theme_constant_override("separation", 10)
	construir()


func construir() -> void:
	pass


func _cabecera(titulo: String, nota := "") -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	add_child(fila)
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
	b.pressed.connect(al_pulsar)
	return b


func _desplazable() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s


func _columna(separacion := 10) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_constant_override("separation", separacion)
	return c


func _aviso(texto: String) -> Control:
	var caja := PanelContainer.new()
	caja.theme_type_variation = "Aviso"
	caja.add_child(_etiqueta(texto))
	return caja
