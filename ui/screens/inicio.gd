extends Pantalla
## Pantalla de inicio: el buque visto desde arriba, con una zona tocable por sistema y su
## lámpara de estado; al lado (o debajo, en vertical), el rango, la lección para continuar, la
## avería pendiente de la Guardia y el repaso del día.

const ANCHO_LADO_MIN := 280.0
const ANCHO_LADO_MAX := 380.0
const ALTO_BUQUE_MIN := 340.0
const ALTO_BUQUE_MAX := 620.0
## Alto aproximado de lo que acompaña al buque en vertical: rango, continuar y botones.
const ALTO_RESTO_VERTICAL := 360.0
const LADO_MEDALLA_RANGO := 58.0
const ALTO_ACCIONES := 58.0
const ANCHO_REPASO := 112.0
## Márgenes de la raíz y separaciones de la pantalla, que no quedan para el buque.
const MARGEN_TOTAL := 48.0

var planta: PlantaBuque


func construir() -> void:
	var c := raiz.contenido
	var avisos := _columna(6)
	if not raiz.partida.aviso.is_empty():
		avisos.add_child(_aviso(raiz.partida.aviso))
	for error in c.errores:
		avisos.add_child(_aviso(error))
	planta = _crear_planta()
	if raiz.vertical:
		add_child(avisos)
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(_ancho_lectura(columna))
		columna.add_child(_crear_rango())
		var alto := raiz.size.y - BarraNavegacion.ALTO - MARGEN_TOTAL - ALTO_RESTO_VERTICAL
		planta.custom_minimum_size.y = clampf(alto, ALTO_BUQUE_MIN, ALTO_BUQUE_MAX)
		columna.add_child(planta)
		_anadir_acciones(columna)
	else:
		var cuerpo := HBoxContainer.new()
		cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_theme_constant_override("separation", 12)
		add_child(cuerpo)
		planta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		planta.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_child(planta)
		var lado := _desplazable()
		lado.size_flags_horizontal = Control.SIZE_FILL
		lado.custom_minimum_size.x = clampf(raiz.ancho_contenido() * 0.36, ANCHO_LADO_MIN, ANCHO_LADO_MAX)
		cuerpo.add_child(lado)
		var columna := _columna(10)
		lado.add_child(columna)
		if avisos.get_child_count() > 0:
			columna.add_child(avisos)
		columna.add_child(_crear_rango())
		_anadir_acciones(columna)


func _crear_planta() -> PlantaBuque:
	var c := raiz.contenido
	var p := PlantaBuque.new()
	p.name = "Planta"
	p.cargar(c.planta(), c.sistemas())
	for s: Dictionary in c.sistemas():
		var id := int(s["id"])
		p.estados[id] = Avance.estado(s, raiz.partida) if s.get("estado", "") == "activo" else "sin_empezar"
		p.avances[id] = Avance.fraccion(Avance.sistema(s, raiz.partida))
	p.sistema_tocado.connect(_abrir_sistema)
	return p


func _abrir_sistema(id: int) -> void:
	if raiz.contenido.sistema(id).get("estado", "") == "activo":
		raiz.ir_a("sistema", {"id": id})


func _anadir_acciones(columna: VBoxContainer) -> void:
	var siguiente := Ruta.siguiente(raiz.contenido, raiz.partida)
	if not siguiente.is_empty():
		columna.add_child(_crear_continuar(siguiente))
	var fila := HBoxContainer.new()
	fila.name = "Acciones"
	fila.add_theme_constant_override("separation", 10)
	fila.custom_minimum_size.y = ALTO_ACCIONES
	columna.add_child(fila)
	var averia := _averia()
	if not averia.is_empty():
		var s := raiz.contenido.sistema(averia["sistema"])
		var m := raiz.contenido.mision(averia["mision"])
		var b := BotonAri.new("%s\nEquipo dañado · Guardia" % m.get("equipo", m.get("titulo", "Avería")), raiz.ir_a.bind("guardia", {"id": int(s["id"])}), "rojo", "guardia")
		b.name = "Averia"
		b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", Tema.tam(12))
		b.radio = 10.0
		b.tooltip_text = "Atender la avería en la Guardia de %s" % s.get("nombre", "")
		fila.add_child(b)
	var pendientes := raiz.partida.temas_pendientes().size()
	var repaso := BotonAri.new("Repaso", raiz.ir_a.bind("repaso"), "oscuro", "repaso")
	repaso.name = "Repaso"
	repaso.custom_minimum_size.x = ANCHO_REPASO
	repaso.size_flags_horizontal = Control.SIZE_EXPAND_FILL if averia.is_empty() else Control.SIZE_FILL
	repaso.radio = 10.0
	repaso.insignia = str(pendientes) if pendientes > 0 else ""
	repaso.tooltip_text = "%d temas que conviene repasar" % pendientes if pendientes > 0 else "Sin temas pendientes"
	fila.add_child(repaso)


## Primera misión con un equipo dañado, recorriendo los sistemas: {sistema, mision} o {}.
func _averia() -> Dictionary:
	for s: Dictionary in raiz.contenido.sistemas():
		var danadas := Avance.misiones_danadas(s, raiz.partida)
		if not danadas.is_empty():
			return {"sistema": int(s["id"]), "mision": danadas[0]}
	return {}


## Placa del rango: medalla con la inicial y el anillo de avance, el buque, el rango y los puntos
## en un visor ámbar de siete segmentos.
func _crear_rango() -> Control:
	var rangos := raiz.contenido.rangos()
	var placa := PanelContainer.new()
	placa.name = "Rango"
	placa.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_theme_stylebox_override("panel", Relieve.estilo_placa(12.0, 10.0))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	placa.add_child(fila)
	var rango := raiz.partida.rango(rangos)
	var medalla := MedallaModulo.new()
	medalla.custom_minimum_size = Vector2(LADO_MEDALLA_RANGO, LADO_MEDALLA_RANGO)
	medalla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	medalla.iniciar("sola", rango, "", Relieve.AMBAR, raiz.partida.progreso_rango(rangos), {"letra": rango.substr(0, 1)})
	fila.add_child(medalla)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 1)
	fila.add_child(textos)
	textos.add_child(_etiqueta(_resumen_barco(raiz.contenido.barco()).to_upper(), "Nota"))
	textos.add_child(_etiqueta(rango, "Titulo"))
	var puntos := HBoxContainer.new()
	puntos.add_theme_constant_override("separation", 8)
	textos.add_child(puntos)
	var visor := LecturaLcd.new(str(int(raiz.partida.datos["puntos"])), "", 12.0, 4)
	visor.name = "Puntos"
	visor.color = Tema.ARI_LCD_AMBAR
	visor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	puntos.add_child(visor)
	var proximo := raiz.partida.siguiente_rango(rangos)
	var texto := "pts"
	if not proximo.is_empty():
		texto += " · %d para %s" % [proximo["faltan"], _rango_corto(proximo["nombre"])]
	var e := _etiqueta(texto, "Nota")
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puntos.add_child(e)
	return placa


## Tarjeta con la lección recomendada y el botón redondo para abrirla.
func _crear_continuar(siguiente: Dictionary) -> Control:
	var s := raiz.contenido.sistema(siguiente["sistema"])
	var l := raiz.contenido.leccion(siguiente["leccion"])
	var color := Tema.color_area(s)
	var tarjeta := PanelContainer.new()
	tarjeta.name = "Continuar"
	tarjeta.mouse_filter = Control.MOUSE_FILTER_PASS
	tarjeta.add_theme_stylebox_override("panel", Relieve.estilo_placa(14.0, 8.0, 12.0, color.darkened(0.35)))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	tarjeta.add_child(fila)
	var franja := ColorRect.new()
	franja.color = color
	franja.custom_minimum_size = Vector2(4, 0)
	franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(franja)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	var rotulo := _etiqueta("CONTINUAR", "Rotulo")
	rotulo.add_theme_color_override("font_color", Tema.ACENTO)
	textos.add_child(rotulo)
	textos.add_child(_etiqueta(l.get("titulo", siguiente["leccion"]), "Subtitulo"))
	textos.add_child(_etiqueta("%s · lección %d de %d · %d min" % [s.get("nombre", ""), siguiente["numero"], siguiente["total"], int(l.get("minutos", 0))], "Nota"))
	var play := BotonPlay.new(_abrir_leccion.bind(siguiente), "Continuar la lección")
	play.name = "Play"
	fila.add_child(play)
	return tarjeta


func _abrir_leccion(siguiente: Dictionary) -> void:
	raiz.ir_a("sistema", {"id": siguiente["sistema"]})
	raiz.ir_a("leccion", {"id": siguiente["leccion"], "sistema": siguiente["sistema"]})


## En apaisado la columna es estrecha: «Oficial Electrotécnico» se abrevia como ETO
## (*Electro-Technical Officer*), como en el Convenio STCW, para que quepa en una línea.
func _rango_corto(nombre: String) -> String:
	return nombre if raiz.vertical else nombre.replace("Oficial Electrotécnico", "Oficial ETO")


func _resumen_barco(barco: Dictionary) -> String:
	if not barco.has("red_principal"):
		return barco.get("nombre", "")
	var red: Dictionary = barco["red_principal"]
	return "%s · %d V · %d Hz" % [barco.get("nombre", "B/P Vía Simoun"), red["tension_v"]["valor"], red["frecuencia_hz"]["valor"]]
