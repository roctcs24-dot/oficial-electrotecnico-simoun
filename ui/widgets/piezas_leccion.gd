class_name PiezasLeccion
extends RefCounted
## Piezas con relieve de la lección, del examen, del repaso y de la pantalla «Buque»: placas,
## papel, fórmulas en un visor, lámparas, la caja de la explicación, las monedas de las páginas y
## la tira de preguntas. Siguen el tema oscuro con el color por área, como la Escuela y las fichas.

const VERDE := Color("7dffab")
const ROJO := Color("ff6a5a")
const TINTA_PAPEL := Color("20262c")


## Placa oscura con bisel que se deja arrastrar con el dedo.
static func placa(margen_x := 14.0, margen_y := 10.0, borde := Relieve.PLACA_BORDE) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", Relieve.estilo_placa(margen_x, margen_y, 12.0, borde))
	return p


## Hoja de papel crema, para las referencias, los símbolos y los casos prácticos.
static func papel(margen := 10.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", Relieve.estilo_papel(margen))
	return p


## Rótulo ámbar en mayúsculas espaciadas, como «PREGUNTA» o «PARA SABER MÁS».
static func rotulo(texto: String) -> Label:
	var e := Label.new()
	e.text = texto.to_upper()
	e.add_theme_font_override("font", PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 2))
	e.add_theme_font_size_override("font_size", Tema.tam(12))
	e.add_theme_color_override("font_color", Tema.ACENTO)
	e.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	e.add_theme_constant_override("shadow_offset_y", 1)
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e


static func etiqueta(texto: String, tam := 15, color := Tema.TEXTO, peso := Tema.PESO_MEDIO) -> Label:
	var e := Label.new()
	e.text = texto
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.add_theme_font_override("font", Tema.fuente(peso))
	e.add_theme_font_size_override("font_size", Tema.tam(tam))
	e.add_theme_color_override("font_color", color)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e


## Texto de lectura con negritas blancas, sobre la placa oscura.
static func texto_rico(bbcode: String, tam := 16, color := Color("dfe6ec")) -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		t.add_theme_font_size_override(clave, Tema.tam(tam))
	t.add_theme_color_override("default_color", color)
	t.add_theme_constant_override("line_separation", 3)
	t.text = bbcode
	return t


## Fórmula destacada en un visor oscuro con letras ámbar encendidas.
static func formula(texto: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Formula"
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", estilo_visor(8.0, 9.0))
	var e := RichTextLabel.new()
	e.bbcode_enabled = true
	e.fit_content = true
	e.scroll_active = false
	e.mouse_filter = Control.MOUSE_FILTER_PASS
	e.add_theme_color_override("default_color", Tema.ACENTO)
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		e.add_theme_font_size_override(clave, Tema.tam(20))
	e.add_theme_font_override("normal_font", Tema.fuente(Tema.PESO_NEGRITA))
	e.add_theme_font_override("bold_font", Tema.fuente(Tema.PESO_NEGRITA))
	e.text = "[center]%s[/center]" % texto
	p.add_child(e)
	return p


## Visor negro hundido: el fondo de la fórmula y de la explicación.
static func estilo_visor(margen_x := 10.0, margen_y := 8.0) -> EstiloAri:
	var e := EstiloAri.crear([Color("070b0e"), Color("0d141a"), Color("111a21")], margen_x, margen_y, 10.0)
	e.borde = Relieve.HUECO_BORDE
	e.luz = Color(0, 0, 0, 0.7)
	e.sombra = 0.0
	e.hueco = Vector2.ZERO
	return e


## Caja de la explicación: lámpara verde o roja, «CORRECTO» o «INCORRECTO» y el texto.
static func explicacion(acierto: bool, texto: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Explicacion"
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", estilo_visor(10.0, 8.0))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(fila)
	var luz := Lampara.new("verde" if acierto else "rojo", true, 6.0)
	luz.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	fila.add_child(luz)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 1)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	var titulo := rotulo("Correcto" if acierto else "Incorrecto")
	titulo.add_theme_color_override("font_color", VERDE if acierto else ROJO)
	textos.add_child(titulo)
	var cuerpo := etiqueta(texto, 14, Color("d6dde3"))
	cuerpo.name = "Texto"
	textos.add_child(cuerpo)
	return p


## Fila con una lámpara y un texto, como los temas que quedan para el repaso.
static func fila_lampara(color: String, texto: String, tam := 15) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.custom_minimum_size.y = 40.0
	var luz := Lampara.new(color, true, 6.0)
	luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(luz)
	var e := etiqueta(texto, tam, Color.WHITE, Tema.PESO_FUERTE)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(e)
	return fila


## Referencias de «Para saber más» en una hoja de papel, cada una con su icono de libro.
static func referencias(lista: Array) -> PanelContainer:
	var hoja := papel(10.0)
	hoja.name = "ParaSaberMas"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoja.add_child(columna)
	for r: String in lista:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icono := TextureRect.new()
		icono.texture = Relieve.icono("glosario", 18.0)
		icono.custom_minimum_size = Vector2(18, 18)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.modulate = Color(0.13, 0.15, 0.17, 0.65)
		icono.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		fila.add_child(icono)
		fila.add_child(texto_rico(_negrita_norma(r), 14, TINTA_PAPEL))
		columna.add_child(fila)
	return hoja


## La norma o fuente, hasta los dos puntos, en negrita: «IEC 60050: vocabulario…».
static func _negrita_norma(r: String) -> String:
	var i := r.find(":")
	var j := r.find(",")
	var corte := i if j < 0 or (i >= 0 and i < j) else j
	if corte <= 0 or corte > 40:
		return r
	return "[b]%s[/b]%s" % [r.substr(0, corte), r.substr(corte)]


## Lámpara piloto con aro cromado, encendida con su halo o apagada.
class Lampara:
	extends Control

	var color := "verde"
	var encendida := true
	var radio := 6.0

	func _init(p_color := "verde", p_encendida := true, p_radio := 6.0) -> void:
		color = p_color
		encendida = p_encendida
		radio = p_radio
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(radio * 4.0, radio * 4.0)

	func _draw() -> void:
		if color == "apagada":
			Relieve.lampara_estado(self, size / 2.0, radio * 0.85, "sin_empezar")
		else:
			PiezasAri.lampara(self, size / 2.0, radio, color, 1.0 if encendida else 0.0)


## Una moneda por página de la lección: verde con marca si está hecha, ámbar la actual y hundida
## la pendiente, unidas por un surco, con el rótulo «PÁGINA 2 DE 3» o «COMPLETADA» encima.
class MonedasPaginas:
	extends Control

	const SEP := 28.0
	const R := 9.5

	var total := 1
	var actual := 0

	func _init(p_total := 1, p_actual := 0) -> void:
		total = maxi(p_total, 1)
		actual = p_actual
		name = "MonedasPaginas"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(maxf(SEP * (total - 1) + R * 2.0 + 10.0, 92.0), 44)
		tooltip_text = rotulo_texto()

	func rotulo_texto() -> String:
		return "COMPLETADA" if actual >= total else "PÁGINA %d DE %d" % [actual + 1, total]

	func _draw() -> void:
		var tam := float(Tema.tam(9))
		PiezasAri.texto(self, rotulo_texto(), size.x - 2.0, 11.0, tam, Tema.ACENTO, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
		var y := 30.0
		var x0 := size.x - R - 4.0 - SEP * (total - 1)
		DibujoAri.relleno(self, Rect2(x0, y - 2.5, SEP * (total - 1), 5.0), 2.5, Color("05080b"))
		var hechas := mini(actual, total)
		if hechas > 0:
			DibujoAri.relleno(self, Rect2(x0, y - 1.5, SEP * mini(hechas, total - 1), 3.0), 1.5, Color(Relieve.VERDE_MARCA, 0.8))
		for i in total:
			var c := Vector2(x0 + i * SEP, y)
			if i < actual:
				Relieve.moneda(self, c, R, "hecha", i + 1, Relieve.VERDE_MARCA)
			elif i == actual:
				Relieve.halo(self, c, R * 2.0, Relieve.AMBAR_HALO, 1.3)
				Relieve.marca(self, c, R, i + 1, false, false, false)
			else:
				Relieve.marca(self, c, R, i + 1, false, true, false)


## Una lámpara por pregunta del examen: verde si se acertó, roja si se falló, ámbar la actual y
## apagadas las que faltan, sobre un surco.
class TiraPreguntas:
	extends Control

	var estados: Array = []
	var actual := 0
	var total := 1

	func _init(p_total := 1, p_estados: Array = [], p_actual := 0) -> void:
		total = maxi(p_total, 1)
		estados = p_estados
		actual = p_actual
		name = "TiraPreguntas"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(120, 26)

	func _draw() -> void:
		var x0 := 12.0
		var ancho := size.x - 24.0
		var y := size.y / 2.0
		DibujoAri.relleno(self, Rect2(x0, y - 2.0, ancho, 4.0), 2.0, Color("05080b"))
		var paso := ancho / maxf(total - 1, 1)
		var r := clampf(paso * 0.3, 2.6, 5.0)
		for i in total:
			var c := Vector2(x0 + i * paso, y)
			if i < estados.size() and estados[i] != "":
				PiezasAri.lampara(self, c, r, estados[i], 1.0)
			elif i == actual:
				PiezasAri.lampara(self, c, r * 1.15, "ambar", 1.0)
			else:
				Relieve.lampara_estado(self, c, r * 0.85, "sin_empezar")


## Cinco lámparas de la repetición espaciada (1, 3, 7, 14 y 30 días): verdes las superadas y
## ámbar el intervalo que toca si se acierta.
class CajasRepaso:
	extends Control

	var caja := 0

	func _init(p_caja := 0) -> void:
		caja = p_caja
		name = "CajasRepaso"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(220, 44)

	func _draw() -> void:
		var dias: Array = Partida.INTERVALOS_REPASO_DIAS
		var tam := float(Tema.tam(10))
		var rot_w := minf(size.x * 0.3, 104.0)
		PiezasAri.texto(self, "SI ACIERTA,", 2.0, size.y / 2.0 - 2.0, tam * 0.9, Tema.ACENTO, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
		PiezasAri.texto(self, "VUELVE EN", 2.0, size.y / 2.0 + tam, tam * 0.9, Tema.ACENTO, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
		var paso := (size.x - rot_w) / dias.size()
		for i in dias.size():
			var c := Vector2(rot_w + paso * (i + 0.5), 14.0)
			var color := Color("7f8c97")
			if i < caja:
				PiezasAri.lampara(self, c, 5.0, "verde", 1.0)
			elif i == caja:
				PiezasAri.lampara(self, c, 6.0, "ambar", 1.0)
				color = Tema.ACENTO
			else:
				Relieve.lampara_estado(self, c, 4.4, "sin_empezar")
			PiezasAri.texto(self, "%d d" % dias[i], c.x, 38.0, tam * 1.05, color, Tema.PESO_NEGRITA)


## Contador «PREGUNTA 07 de 20» con el número en un visor ámbar.
class Contador:
	extends Control

	var numero := 1
	var total := 1

	func _init(p_numero := 1, p_total := 1) -> void:
		numero = p_numero
		total = p_total
		name = "Contador"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(110, 44)

	func _draw() -> void:
		var tam := float(Tema.tam(9))
		PiezasAri.texto(self, "PREGUNTA", size.x - 2.0, 11.0, tam, Tema.ACENTO, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
		var de := "de %d" % total
		var t_de := float(Tema.tam(13))
		var w_de := PiezasAri.ancho_texto(de, t_de)
		PiezasAri.texto(self, de, size.x - 2.0, 37.0, t_de, Tema.TEXTO_SUAVE, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
		var texto := "%02d" % numero
		var w := maxf(DibujoAri.ancho_seg7(texto, 15.0) + 12.0, 34.0)
		PiezasAri.visor(self, Rect2(size.x - w_de - 10.0 - w, 18.0, w, 24.0), 1.0, texto, "", Tema.ARI_LCD_AMBAR, 15.0)
