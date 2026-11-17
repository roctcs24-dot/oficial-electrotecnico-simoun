class_name Tema
extends RefCounted
## Colores y estilos de la interfaz: fondo oscuro, tarjetas redondeadas y un color por área
## (elegido por el usuario entre maquetas el 2026-11-15). Los márgenes de los botones
## garantizan 48 de alto.

const FONDO := Color("0f1419")
const PANEL := Color("1b232c")
const BOTON := Color("222c36")
const BORDE := Color("2b3642")
const SELECCION := Color("2c6e9e")
const ACENTO := Color("ffd166")
const ACENTO_FUERTE := Color("ffb020")
const TEXTO := Color("eef2f5")
const TEXTO_SUAVE := Color("a3b1bd")
const APAGADO := Color("6b7a87")
const PAPEL := Color("e9ebe8")
const TINTA := Color("20242a")
const AVISO := Color("6b3a1f")
const ACIERTO := Color("2f6f4a")
const HECHO := Color("4fae7a")
const FALLO := Color("8c3b30")
const RADIO := 10
const RADIO_TARJETA := 16
## Color de un área sin color propio en sistemas.json.
const COLOR_AREA := Color("2c6e9e")
const RUTA_FUENTE := "res://art/fuentes/IBMPlexSans.ttf"
const RUTA_FUENTE_CURSIVA := "res://art/fuentes/IBMPlexSans-Italic.ttf"
const PESO_NORMAL := 400
const PESO_MEDIO := 500
const PESO_FUERTE := 600
const PESO_NEGRITA := 700

## Marco de simulador (Guardia y Taller, rediseño del 2026-11-16): azul degradado, botones con
## brillo y lecturas verdes sobre negro, como en los simuladores de sala de máquinas.
const ARI_FONDO := [Color("2a6aa0"), Color("1a4b78"), Color("0e2c4a")]
const ARI_BOTON := [Color("57b0ef"), Color("2b83cc"), Color("2173bb"), Color("1b609f")]
const ARI_AMBAR := [Color("ffe7a0"), Color("ffc94a"), Color("f2b02b"), Color("d99614")]
const ARI_ROJO := [Color("ff7a6e"), Color("e2392d"), Color("cc2a20"), Color("a51d15")]
const ARI_BARRA := [Color("3a86c4"), Color("22639c"), Color("18527f"), Color("123f63")]
const ARI_CABECERA := [Color("7fb0db"), Color("3f74a6"), Color("356897"), Color("2a5a87")]
const ARI_CABECERA_ROJA := [Color("ff8b80"), Color("d8372c"), Color("c62d22"), Color("9f1e16")]
const ARI_PANEL := [Color("20527f"), Color("183f63")]
const ARI_PIE := [Color("123a5e"), Color("0a2440")]
const ARI_BORDE := Color("0d3558")
const ARI_LINEA := Color("4d86b8")
const ARI_PANTALLA := Color("0c2238")
const ARI_TEXTO := Color("eaf3fb")
const ARI_TEXTO_SUAVE := Color("a9c3da")
const ARI_TEXTO_OSCURO := Color("241700")
const ARI_LCD_VERDE := Color("45ff82")
const ARI_LCD_CIAN := Color("7fd8ff")
const ARI_LCD_AMBAR := Color("ffb020")
const ARI_LCD_FONDO := Color("030806")
const ARI_ALARMA := Color("ff5a4f")
const ARI_NORMAL := Color("57f08b")
const ARI_EVENTO := Color("ffd166")
const ARI_LISTA := Color("0b0f12")

static var _fuentes := {}
## Tamaño del texto elegido en Mi progreso: 1 normal, 1,15 grande, 1,3 muy grande.
static var escala_texto := 1.0
const TAMANOS_TEXTO := [["Normal", 1.0], ["Grande", 1.15], ["Muy grande", 1.3]]


## Un tamaño de letra con la escala elegida.
static func tam(puntos: float) -> int:
	return roundi(puntos * escala_texto)


## La fuente es variable: un solo archivo da todos los pesos. Si le falta un carácter,
## recurre a la fuente de Godot.
static func fuente(peso: int, ruta := RUTA_FUENTE) -> Font:
	var clave := "%s_%d" % [ruta, peso]
	if not _fuentes.has(clave):
		var base: FontFile = load(ruta)
		if base.fallbacks.is_empty():
			base.fallbacks = [ThemeDB.fallback_font]
		var f := FontVariation.new()
		f.base_font = base
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): peso}
		_fuentes[clave] = f
	return _fuentes[clave]


## Color de un sistema o módulo, del campo "color" de sistemas.json.
static func color_area(datos: Dictionary) -> Color:
	return Color(str(datos.get("color", COLOR_AREA.to_html(false))))


## Relación de contraste WCAG entre dos colores: 4,5 o más para texto normal.
static func contraste(a: Color, b: Color) -> float:
	var la := _luminancia(a)
	var lb := _luminancia(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Luminancia relativa de WCAG, con los canales pasados a lineales.
static func _luminancia(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


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
	t.default_font = fuente(PESO_NORMAL)
	t.default_font_size = tam(18)

	t.set_color("font_color", "Label", TEXTO)
	t.set_type_variation("Titulo", "Label")
	t.set_font_size("font_size", "Titulo", tam(24))
	t.set_font("font", "Titulo", fuente(PESO_FUERTE))
	t.set_type_variation("Subtitulo", "Label")
	t.set_font_size("font_size", "Subtitulo", tam(19))
	t.set_font("font", "Subtitulo", fuente(PESO_FUERTE))
	t.set_type_variation("Fuerte", "Label")
	t.set_font("font", "Fuerte", fuente(PESO_MEDIO))
	t.set_type_variation("Nota", "Label")
	t.set_font_size("font_size", "Nota", tam(16))
	t.set_color("font_color", "Nota", TEXTO_SUAVE)
	t.set_font("font", "Button", fuente(PESO_MEDIO))
	t.set_font("normal_font", "RichTextLabel", fuente(PESO_NORMAL))
	t.set_font("bold_font", "RichTextLabel", fuente(PESO_NEGRITA))
	t.set_font("italics_font", "RichTextLabel", fuente(PESO_NORMAL, RUTA_FUENTE_CURSIVA))
	t.set_font("bold_italics_font", "RichTextLabel", fuente(PESO_NEGRITA, RUTA_FUENTE_CURSIVA))

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

	t.set_type_variation("Rotulo", "Label")
	t.set_font_size("font_size", "Rotulo", tam(13))
	t.set_font("font", "Rotulo", fuente(PESO_FUERTE))
	t.set_color("font_color", "Rotulo", ACENTO)

	var cabecera := caja(PANEL, RADIO_TARJETA, 12, 8)
	cabecera.border_color = BORDE
	cabecera.set_border_width_all(1)
	t.set_type_variation("Cabecera", "PanelContainer")
	t.set_stylebox("panel", "Cabecera", cabecera)

	t.set_stylebox("background", "ProgressBar", caja(Color(TEXTO_SUAVE, 0.16), 3, 0, 0))
	t.set_stylebox("fill", "ProgressBar", caja(ACENTO, 3, 0, 0))

	var pista := caja(Color(TEXTO_SUAVE, 0.12), 2, 0, 0)
	var asidero := caja(Color(TEXTO_SUAVE, 0.45), 2, 0, 0)
	asidero.content_margin_left = 3
	asidero.content_margin_right = 3
	for barra in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", barra, pista)
		t.set_stylebox("grabber", barra, asidero)
		t.set_stylebox("grabber_highlight", barra, asidero)
		t.set_stylebox("grabber_pressed", barra, asidero)

	var surco := caja(FONDO.lightened(0.14), 2, 0, 3)
	var recorrido := caja(ACENTO, 2, 0, 3)
	t.set_stylebox("slider", "HSlider", surco)
	t.set_stylebox("grabber_area", "HSlider", recorrido)
	t.set_stylebox("grabber_area_highlight", "HSlider", recorrido)

	t.set_stylebox("normal", "LineEdit", caja(FONDO.lightened(0.05), RADIO, 12, 11, BORDE))
	t.set_stylebox("focus", "LineEdit", caja(FONDO.lightened(0.05), RADIO, 12, 11, ACENTO))
	t.set_color("font_color", "LineEdit", TEXTO)
	t.set_color("font_placeholder_color", "LineEdit", APAGADO)

	t.set_stylebox("panel", "PanelContainer", caja(PANEL, RADIO_TARJETA, 12, 12, BORDE))
	t.set_type_variation("Papel", "PanelContainer")
	t.set_stylebox("panel", "Papel", caja(PAPEL, RADIO, 10, 10))
	t.set_type_variation("Aviso", "PanelContainer")
	t.set_stylebox("panel", "Aviso", caja(AVISO, RADIO, 12, 8))

	t.set_color("default_color", "RichTextLabel", TEXTO)
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		t.set_font_size(clave, "RichTextLabel", tam(18))
	return t
