extends Pantalla
## Índice de paneles del buque, por grupos de color, como en un simulador de sala de máquinas.
## Cada código abre su panel; los que aún no existen salen en gris como «próximamente».

const ALTO_FILA := 54.0


func construir() -> void:
	_cabecera("Índice de paneles", "Toque un código para abrir su panel")
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(8)
	desplazable.add_child(columna)
	var perfil := PerfilBuque.new(raiz.paneles)
	perfil.name = "Perfil"
	perfil.custom_minimum_size.y = 120.0 if raiz.vertical else 100.0
	columna.add_child(perfil)
	var rejilla := GridContainer.new()
	rejilla.columns = 1 if raiz.vertical else 2
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", 8)
	rejilla.add_theme_constant_override("v_separation", 8)
	columna.add_child(rejilla)
	for g: Dictionary in raiz.paneles.grupos():
		var lista := raiz.paneles.de_grupo(g["id"])
		if lista.is_empty():
			continue
		var color := Color(g["color"])
		var tonos := [color.lightened(0.35), color, color.darkened(0.08), color.darkened(0.3)]
		var panel := PanelAri.new(g["nombre"], g["icono"], false, 5, tonos)
		panel.name = "Grupo" + g["id"]
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		rejilla.add_child(panel)
		for p: Dictionary in lista:
			panel.contenido.add_child(_fila_panel(p, color))


func _fila_panel(p: Dictionary, color: Color) -> Control:
	var disponible := Paneles.disponible(p)
	var b := BotonAri.new("", raiz.ir_a_panel.bind(p["codigo"]), "claro")
	b.name = p["codigo"]
	b.custom_minimum_size.y = ALTO_FILA
	b.hueco = Vector2(0, 2)
	b.disabled = not disponible
	b.tooltip_text = p["titulo"]
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 8
	fila.offset_right = -8
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(fila)
	var chip := PanelContainer.new()
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := StyleBoxFlat.new()
	caja.bg_color = color if disponible else Color("8796a4")
	caja.set_corner_radius_all(4)
	caja.content_margin_left = 7
	caja.content_margin_right = 7
	caja.content_margin_top = 2
	caja.content_margin_bottom = 2
	caja.border_color = Color(1, 1, 1, 0.35)
	caja.border_width_top = 1
	chip.add_theme_stylebox_override("panel", caja)
	var cod := PanelAri.texto(p["codigo"], 12, Color.WHITE, 800)
	cod.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	cod.add_theme_constant_override("shadow_offset_y", 1)
	chip.add_child(cod)
	fila.add_child(chip)
	var textos := VBoxContainer.new()
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", -2)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	var tinta := Color("1d2a36") if disponible else Color("5d6b78")
	var t := PanelAri.texto(p["titulo"], 13.5, tinta, Tema.PESO_NEGRITA)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textos.add_child(t)
	var lugar := PanelAri.texto(p.get("lugar", "") if disponible else "Próximamente", 10.5, Color("4b5b6a"))
	lugar.clip_text = true
	lugar.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textos.add_child(lugar)
	return b
