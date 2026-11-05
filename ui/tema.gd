class_name Tema
extends RefCounted
## Colores y estilos de la interfaz. Los márgenes de los botones garantizan 48 de alto.

const FONDO := Color("12344d")
const PANEL := Color("1b4663")
const PANEL_CLARO := Color("2a5f83")
const ACENTO := Color("f2a93b")
const TEXTO := Color("f3f6f8")
const TEXTO_SUAVE := Color("c3d3de")
const APAGADO := Color("7e93a3")
const PAPEL := Color("eef1ec")
const TINTA := Color("20242a")
const AVISO := Color("7a2e22")


static func _caja(color: Color, radio := 8, margen_x := 14, margen_y := 13) -> StyleBoxFlat:
	var c := StyleBoxFlat.new()
	c.bg_color = color
	c.set_corner_radius_all(radio)
	c.content_margin_left = margen_x
	c.content_margin_right = margen_x
	c.content_margin_top = margen_y
	c.content_margin_bottom = margen_y
	return c


static func crear() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18

	t.set_color("font_color", "Label", TEXTO)
	t.set_type_variation("Titulo", "Label")
	t.set_font_size("font_size", "Titulo", 26)
	t.set_type_variation("Subtitulo", "Label")
	t.set_font_size("font_size", "Subtitulo", 20)
	t.set_type_variation("Nota", "Label")
	t.set_font_size("font_size", "Nota", 15)
	t.set_color("font_color", "Nota", TEXTO_SUAVE)

	t.set_stylebox("normal", "Button", _caja(PANEL_CLARO))
	t.set_stylebox("hover", "Button", _caja(PANEL_CLARO.lightened(0.12)))
	t.set_stylebox("pressed", "Button", _caja(ACENTO))
	t.set_stylebox("hover_pressed", "Button", _caja(ACENTO.lightened(0.1)))
	t.set_stylebox("disabled", "Button", _caja(PANEL))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", TEXTO)
	t.set_color("font_focus_color", "Button", TEXTO)
	t.set_color("font_pressed_color", "Button", FONDO)
	t.set_color("font_hover_pressed_color", "Button", FONDO)
	t.set_color("font_disabled_color", "Button", TEXTO_SUAVE.darkened(0.15))

	t.set_stylebox("panel", "PanelContainer", _caja(PANEL, 10, 12, 12))
	t.set_type_variation("Papel", "PanelContainer")
	t.set_stylebox("panel", "Papel", _caja(PAPEL, 10, 10, 10))
	t.set_type_variation("Aviso", "PanelContainer")
	t.set_stylebox("panel", "Aviso", _caja(AVISO, 8, 12, 8))

	t.set_color("default_color", "RichTextLabel", TEXTO)
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		t.set_font_size(clave, "RichTextLabel", 18)
	return t
