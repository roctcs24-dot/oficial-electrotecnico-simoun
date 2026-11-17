class_name CabeceraFicha
extends PanelContainer
## Cabecera de la ficha y del atlas: placa con bisel, botón de volver, la medalla del área, el
## título con su subtítulo y, a la derecha, lo que la pantalla quiera añadir (las lámparas de
## las vistas del atlas) y el atajo al inicio.

var medalla: MedallaModulo
var subtitulo: RichTextLabel


func iniciar(raiz: Raiz, titulo: String, sub_bbcode: String, color: Color, icono: String, avance := 0.0, extra: Control = null) -> void:
	name = "CabeceraFicha"
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", Relieve.estilo_placa(8.0, 4.0))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)
	if raiz.nivel() > 1:
		var volver := BotonAri.new("", raiz.volver, "oscuro")
		volver.name = "Volver"
		volver.signo = "atras"
		volver.tooltip_text = "Volver"
		volver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(volver)
	medalla = MedallaModulo.new()
	medalla.custom_minimum_size = Vector2(46, 46)
	medalla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	medalla.iniciar("sola", titulo, icono, color, avance)
	fila.add_child(medalla)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 0)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	var t := Label.new()
	t.text = titulo
	t.theme_type_variation = "Subtitulo"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", Tema.tam(20))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 1)
	textos.add_child(t)
	subtitulo = RichTextLabel.new()
	subtitulo.bbcode_enabled = true
	subtitulo.fit_content = true
	subtitulo.scroll_active = false
	subtitulo.mouse_filter = Control.MOUSE_FILTER_PASS
	subtitulo.add_theme_color_override("default_color", Tema.TEXTO_SUAVE)
	for clave in ["normal_font_size", "italics_font_size", "bold_font_size"]:
		subtitulo.add_theme_font_size_override(clave, Tema.tam(14))
	subtitulo.text = sub_bbcode
	subtitulo.visible = not sub_bbcode.is_empty()
	textos.add_child(subtitulo)
	if extra != null:
		extra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(extra)
	if raiz.nivel() >= 3:
		var inicio := BotonAri.new("", raiz.ir_a_seccion.bind("inicio"), "oscuro", "inicio")
		inicio.name = "Inicio"
		inicio.tooltip_text = "Inicio"
		inicio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(inicio)


## Lámparas de las vistas del atlas ya vistas, con el rótulo VISTAS encima.
class LamparasVistas:
	extends Control

	var vistas := 0
	var total := 5

	func _init(p_vistas := 0, p_total := 5) -> void:
		vistas = p_vistas
		total = p_total
		name = "LamparasVistas"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(16.0 * p_total + 6.0, 36)
		tooltip_text = "%d de %d vistas" % [p_vistas, p_total]

	func _draw() -> void:
		var tam := float(Tema.tam(9))
		PiezasAri.texto(self, "VISTAS", size.x - 2.0, 11.0, tam, Tema.ACENTO, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
		for i in total:
			var c := Vector2(size.x - 8.0 - (total - 1 - i) * 16.0, 25.0)
			Relieve.lampara_estado(self, c, 4.2, "completo" if i < vistas else "sin_empezar")
