class_name Tema
extends RefCounted
## Colores y estilos de la interfaz: sobrios, de manual técnico.
## Los márgenes de los botones garantizan 48 de alto.

const FONDO := Color("0e1e2c")
const PANEL := Color("142636")
const BOTON := Color("1a3247")
const BORDE := Color("3d5a72")
const SELECCION := Color("2f6b8f")
const ACENTO := Color("c2a25a")
const TEXTO := Color("eef3f7")
const TEXTO_SUAVE := Color("a9bccb")
const APAGADO := Color("6f8496")
const PAPEL := Color("e9ebe8")
const TINTA := Color("20242a")
const AVISO := Color("6b3a1f")
const ACIERTO := Color("2f6f4a")
const FALLO := Color("8c3b30")
const RADIO := 3


static func caja(color: Color, radio := RADIO, margen_x := 14, margen_y := 13, borde := Color.TRANSPARENT) -> StyleBoxFlat:
	var c := StyleBoxFlat.new()
	c.bg_color = color
	c.set_corner_radius_all(radio)
	c.content_margin_left = margen_x
	c.content_margin_right = margen_x
	c.content_margin_top = margen_y
	c.content_margin_bottom = margen_y
	if borde.a > 0.0:
		c.border_color = borde
		c.set_border_width_all(1)
	return c


## En pantallas táctiles no hay cursor: el dedo cuenta como ratón y el resaltado de "cursor
## encima" se quedaría sobre el botón mientras la lista se desplaza.
static func crear(tactil := OS.has_feature("mobile")) -> Theme:
	var t := Theme.new()
	t.default_font_size = 18

	t.set_color("font_color", "Label", TEXTO)
	t.set_type_variation("Titulo", "Label")
	t.set_font_size("font_size", "Titulo", 24)
	t.set_type_variation("Subtitulo", "Label")
	t.set_font_size("font_size", "Subtitulo", 19)
	t.set_type_variation("Nota", "Label")
	t.set_font_size("font_size", "Nota", 15)
	t.set_color("font_color", "Nota", TEXTO_SUAVE)

	t.set_stylebox("normal", "Button", caja(BOTON, RADIO, 14, 13, BORDE))
	var resaltado := 0.0 if tactil else 0.08
	t.set_stylebox("hover", "Button", caja(BOTON.lightened(resaltado), RADIO, 14, 13, BORDE.lightened(resaltado * 2.5)))
	t.set_stylebox("pressed", "Button", caja(SELECCION, RADIO, 14, 13, SELECCION.lightened(0.2)))
	t.set_stylebox("hover_pressed", "Button", caja(SELECCION.lightened(resaltado), RADIO, 14, 13, SELECCION.lightened(0.2)))
	t.set_stylebox("disabled", "Button", caja(PANEL, RADIO, 14, 13, PANEL.lightened(0.1)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", TEXTO)
	t.set_color("font_focus_color", "Button", TEXTO)
	t.set_color("font_pressed_color", "Button", TEXTO)
	t.set_color("font_hover_pressed_color", "Button", TEXTO)
	t.set_color("font_disabled_color", "Button", TEXTO_SUAVE.darkened(0.2))

	t.set_stylebox("panel", "PanelContainer", caja(PANEL, RADIO, 12, 12, PANEL.lightened(0.1)))
	t.set_type_variation("Papel", "PanelContainer")
	t.set_stylebox("panel", "Papel", caja(PAPEL, RADIO, 10, 10))
	t.set_type_variation("Aviso", "PanelContainer")
	t.set_stylebox("panel", "Aviso", caja(AVISO, RADIO, 12, 8))

	t.set_color("default_color", "RichTextLabel", TEXTO)
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		t.set_font_size(clave, "RichTextLabel", 18)
	return t
