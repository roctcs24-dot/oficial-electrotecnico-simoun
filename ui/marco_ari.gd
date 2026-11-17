class_name MarcoAri
extends Control
## Marco de simulador de las pantallas de Guardia y Taller, al estilo de los simuladores de sala
## de máquinas: barra superior con el código del panel, columna de accesos por grupo, panel
## derecho con la generación, los consejos y las alarmas, y barra de eventos con el reloj.
## En vertical, los accesos van en una tira y el panel derecho sube como hoja desde el pie.

const ANCHO_IZQ := 120.0
const ANCHO_DER := 280.0
const ANCHO_PLIEGUE := 40.0
const SEP := 6.0
const MARGEN := 6.0
const MARGEN_CUERPO := 8.0
const ALTO_BARRA := 48.0
const ALTO_TIRA := 56.0
const ALTO_PIE := 30.0
const ALTO_PIE_RETRATO := 34.0
const ALTO_ESTADO := 52.0
## Por debajo de este ancho, aunque la pantalla esté apaisada, se usa la disposición vertical.
const ANCHO_MIN_APAISADO := 640.0
const PERIODO_LECTURA := 0.5
const CIAN_RELOJ := Tema.ARI_LCD_CIAN

var raiz: Raiz
var pantalla: Pantalla
## Donde se monta la pantalla del juego.
var cuerpo: MarginContainer
var retrato := false
var codigo := ""
var titulo := ""
var nota := ""
var _placa_codigo: Label
var _placa_titulo: Label
var _placa_nota: Label
var _botones_grupo := {}
var _filas_gen: Array[Array] = []
var _caja_gen: VBoxContainer
var _lcd_total: LecturaLcd
var _texto_red: Label
var _caja_consejos: VBoxContainer
var _cabecera_alarmas: Label
var _lista_alarmas: VBoxContainer
var _parpadeantes: Array[Control] = []
var _reloj: LecturaLcd
var _evento: Label
var _escenario: Label
var _estado_total: LecturaLcd
var _estado_grupos: Label
var _boton_alarmas: BotonAri
var _insignia: Label
var _hoja: Control
var _ayuda: Control
var _t := 0.0
var _encendido := true
var _reconocidas_pantalla := false
var _segundo := -1


## Ancho que queda para la pantalla dentro del marco, para decidir su disposición.
static func ancho_util(ancho_total: float, en_retrato: bool, plegado: bool) -> float:
	if en_retrato:
		return ancho_total - MARGEN * 2.0 - MARGEN_CUERPO * 2.0
	var resto := ancho_total - MARGEN * 2.0 - ANCHO_IZQ - SEP - ANCHO_PLIEGUE - SEP - MARGEN_CUERPO * 2.0
	if not plegado:
		resto -= ANCHO_DER + SEP
	return resto


static func es_retrato(tamano: Vector2) -> bool:
	return tamano.x < tamano.y or tamano.x < ANCHO_MIN_APAISADO


func preparar(raiz_juego: Raiz) -> void:
	raiz = raiz_juego
	retrato = raiz.retrato
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(FondoAri.new())
	if retrato:
		_construir_retrato()
	else:
		_construir_apaisado()
	raiz.eventos.cambiado.connect(_al_cambiar_eventos)


## Se llama cuando la pantalla ya se construyó: su título llegó por poner_titulo().
func montar(p: Pantalla) -> void:
	pantalla = p
	codigo = p.codigo_marco()
	var info := raiz.paneles.panel(codigo)
	var etiqueta: String = codigo if not codigo.is_empty() else raiz.paneles.pantalla(raiz.nombre_actual()).get("codigo", "")
	_placa_codigo.text = etiqueta
	_placa_codigo.get_parent().visible = not etiqueta.is_empty()
	if titulo.is_empty() and not info.is_empty():
		titulo = info["titulo"]
	_placa_titulo.text = titulo if retrato else titulo.to_upper()
	if nota.is_empty() and not info.is_empty():
		nota = info.get("lugar", "")
	_placa_nota.text = nota
	_placa_nota.visible = not nota.is_empty()
	_marcar_grupo(str(info.get("grupo", "")))
	_poner_consejos(_consejos())
	_leer_generacion()
	_actualizar_alarmas()
	_actualizar_pie()
	_actualizar_reloj()


func poner_titulo(t: String, n := "") -> void:
	titulo = t
	nota = n


func _consejos() -> Array:
	var propios := pantalla.consejos_marco()
	if not propios.is_empty():
		return propios
	var info := raiz.paneles.panel(codigo)
	if not info.is_empty() and not info.get("consejos", []).is_empty():
		return info["consejos"]
	return raiz.paneles.pantalla(raiz.nombre_actual()).get("consejos", [])


# --- Construcción ---

func _construir_apaisado() -> void:
	var columna := _columna_principal()
	columna.add_child(_barra_superior())
	var margen := MarginContainer.new()
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top"]:
		margen.add_theme_constant_override("margin_" + lado, int(MARGEN))
	margen.add_theme_constant_override("margin_bottom", 4)
	columna.add_child(margen)
	var medio := HBoxContainer.new()
	medio.add_theme_constant_override("separation", int(SEP))
	medio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(medio)
	medio.add_child(_columna_accesos())
	medio.add_child(_crear_cuerpo())
	var pliegue := BotonAri.new("", _alternar_pliegue)
	pliegue.name = "Pliegue"
	pliegue.signo = "anterior" if raiz.marco_plegado else "siguiente"
	pliegue.tooltip_text = "Mostrar el panel de generación y alarmas" if raiz.marco_plegado else "Plegar el panel derecho"
	pliegue.custom_minimum_size = Vector2(ANCHO_PLIEGUE, 72)
	pliegue.hueco = Vector2(10, 0)
	pliegue.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	medio.add_child(pliegue)
	if not raiz.marco_plegado:
		var derecha := _desplazable_vertical()
		derecha.name = "PanelDerecho"
		derecha.custom_minimum_size.x = ANCHO_DER
		medio.add_child(derecha)
		var caja := VBoxContainer.new()
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.add_theme_constant_override("separation", int(SEP))
		derecha.add_child(caja)
		for p in _paneles_estado():
			caja.add_child(p)
	columna.add_child(_pie())


func _construir_retrato() -> void:
	var columna := _columna_principal()
	columna.add_child(_barra_superior())
	columna.add_child(_tira_accesos())
	var margen := MarginContainer.new()
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, int(MARGEN))
	columna.add_child(margen)
	margen.add_child(_crear_cuerpo())
	columna.add_child(_fila_estado())
	columna.add_child(_pie())
	_hoja = _crear_hoja()
	add_child(_hoja)
	_ayuda = null


func _columna_principal() -> VBoxContainer:
	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.add_theme_constant_override("separation", 0)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(columna)
	return columna


func _crear_cuerpo() -> Control:
	var marco_cuerpo := PanelContainer.new()
	marco_cuerpo.name = "Cuerpo"
	marco_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marco_cuerpo.mouse_filter = Control.MOUSE_FILTER_PASS
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(Tema.ARI_PANTALLA, 0.82)
	caja.set_corner_radius_all(6)
	caja.border_color = Color("071a2c")
	caja.set_border_width_all(1)
	caja.border_width_top = 2
	marco_cuerpo.add_theme_stylebox_override("panel", caja)
	# Un Control sin contenedor no pasa hacia arriba el tamaño mínimo de la pantalla: un tablero
	# alto no empuja el pie fuera de la pantalla, se recorta y se desplaza dentro.
	var recorte := Control.new()
	recorte.name = "Recorte"
	recorte.clip_contents = true
	recorte.mouse_filter = Control.MOUSE_FILTER_PASS
	marco_cuerpo.add_child(recorte)
	cuerpo = MarginContainer.new()
	cuerpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	cuerpo.mouse_filter = Control.MOUSE_FILTER_PASS
	for lado in ["left", "right", "top", "bottom"]:
		cuerpo.add_theme_constant_override("margin_" + lado, int(MARGEN_CUERPO))
	recorte.add_child(cuerpo)
	return marco_cuerpo


func _barra_superior() -> Control:
	var barra := Lamina.new(Tema.ARI_BARRA, 0.0)
	barra.name = "BarraSuperior"
	barra.linea_abajo = true
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.add_child(fila)
	if not retrato:
		fila.add_child(_logo())
	if raiz.nivel() > 1:
		var volver := BotonAri.new("", raiz.volver)
		volver.name = "Volver"
		volver.signo = "atras"
		volver.tooltip_text = "Volver"
		fila.add_child(volver)
	fila.add_child(_placa())
	if not retrato:
		var hueco := Control.new()
		hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(hueco)
	var ayuda := BotonAri.new("", _mostrar_ayuda)
	ayuda.name = "Ayuda"
	ayuda.signo = "ayuda"
	ayuda.redondo = true
	ayuda.tooltip_text = "Ayuda"
	fila.add_child(ayuda)
	if not retrato:
		fila.add_child(_boton_vecino(-1))
		fila.add_child(_boton_vecino(1))
	var inicio := BotonAri.new("", raiz.ir_a_seccion.bind("inicio"), "azul", "inicio")
	inicio.name = "Inicio"
	inicio.tooltip_text = "Inicio"
	inicio.add_theme_constant_override("icon_max_width", 20)
	fila.add_child(inicio)
	return barra


## ‹ y › recorren los paneles del índice; fuera de un panel no se muestran.
func _boton_vecino(paso: int) -> BotonAri:
	var b := BotonAri.new("", _ir_vecino.bind(paso))
	b.name = "Anterior" if paso < 0 else "Siguiente"
	b.signo = "anterior" if paso < 0 else "siguiente"
	b.tooltip_text = "Panel anterior" if paso < 0 else "Panel siguiente"
	b.visible = not raiz.paneles.codigo_de(raiz.nombre_actual(), raiz.args_actuales()).is_empty()
	return b


func _logo() -> Control:
	var placa := PanelContainer.new()
	placa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("0b1a28")
	caja.border_color = Color("6b8fae")
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(4)
	caja.content_margin_left = 6
	caja.content_margin_right = 8
	caja.content_margin_top = 4
	caja.content_margin_bottom = 4
	placa.add_theme_stylebox_override("panel", caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 5)
	placa.add_child(fila)
	var ic := TextureRect.new()
	ic.texture = VistaSvg.rasterizar("res://art/iconos/buque.svg", 16.0 / 64.0 * 2.0)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(16, 16)
	fila.add_child(ic)
	var t := PanelAri.texto("VÍA SIMOUN", 11, Color("dfe9f2"), Tema.PESO_NEGRITA)
	t.add_theme_font_override("font", PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 2))
	fila.add_child(t)
	return placa


## Placa del panel: el código en ámbar y, al lado, el título con su lugar o su nota.
func _placa() -> Control:
	var placa := PanelContainer.new()
	placa.name = "Placa"
	placa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL if retrato else Control.SIZE_SHRINK_BEGIN
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("0c1f31")
	caja.border_color = Color("061322")
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(4)
	caja.shadow_color = Color(1, 1, 1, 0.12)
	caja.shadow_offset = Vector2(0, 1)
	caja.shadow_size = 1
	placa.add_theme_stylebox_override("panel", caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 0)
	placa.add_child(fila)
	var cod := PanelContainer.new()
	cod.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ambar := StyleBoxFlat.new()
	ambar.bg_color = Color("f6bd3a")
	ambar.border_color = Color("ffe39a")
	ambar.border_width_top = 1
	ambar.corner_radius_top_left = 4
	ambar.corner_radius_bottom_left = 4
	ambar.content_margin_left = 8
	ambar.content_margin_right = 8
	cod.add_theme_stylebox_override("panel", ambar)
	fila.add_child(cod)
	_placa_codigo = PanelAri.texto("", 15 if not retrato else 14, Tema.ARI_TEXTO_OSCURO, 800)
	_placa_codigo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cod.add_child(_placa_codigo)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", -2)
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 9)
	margen.add_theme_constant_override("margin_right", 9)
	margen.add_theme_constant_override("margin_top", 3)
	margen.add_theme_constant_override("margin_bottom", 3)
	margen.add_child(textos)
	fila.add_child(margen)
	_placa_titulo = PanelAri.texto("", 13 if not retrato else 12.5, Tema.ARI_TEXTO, Tema.PESO_NEGRITA)
	if not retrato:
		_placa_titulo.add_theme_font_override("font", PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 1))
	_placa_nota = PanelAri.texto("", 10.5, Tema.ARI_TEXTO_SUAVE, Tema.PESO_MEDIO)
	for e: Label in [_placa_titulo, _placa_nota]:
		if retrato:
			e.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			e.clip_text = true
			e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.add_child(e)
	if not retrato:
		# Sin recorte, la nota larga de una práctica empujaría los botones fuera de la barra.
		_placa_nota.clip_text = true
		_placa_nota.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return placa


func _datos_accesos() -> Array:
	var r := [["indice_paneles", "Índice", "buque", ""]]
	for g: Dictionary in raiz.paneles.grupos():
		if not raiz.paneles.de_grupo(g["id"]).filter(Paneles.disponible).is_empty():
			r.append(["grupo", g["corto"], g["icono"], g["id"]])
	r.append(["leyenda", "Leyenda", "simbolos", ""])
	return r


func _boton_acceso(d: Array) -> BotonAri:
	var b := BotonAri.new(d[1], _abrir_acceso.bind(d[0], d[3]), "azul", d[2])
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", Tema.tam(11.5))
	b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var margenes := StyleBoxEmpty.new()
	margenes.content_margin_left = 8
	margenes.content_margin_right = 6
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(estado, margenes)
	if not retrato:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_constant_override("line_spacing", -3)
	var activo: bool = d[0] != "grupo" and raiz.nombre_actual() == d[0]
	b.estilo = "ambar" if activo else "azul"
	_botones_grupo[d[3] if d[0] == "grupo" else d[0]] = b
	return b


func _columna_accesos() -> Control:
	var desplazable := _desplazable_vertical()
	desplazable.name = "Accesos"
	desplazable.custom_minimum_size.x = ANCHO_IZQ
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 2)
	desplazable.add_child(caja)
	for d in _datos_accesos():
		caja.add_child(_boton_acceso(d))
	return desplazable


func _tira_accesos() -> Control:
	var tira := Lamina.new(Tema.ARI_PIE, 0.0)
	tira.name = "Accesos"
	tira.custom_minimum_size.y = ALTO_TIRA
	tira.linea_abajo = true
	var desplazable := ScrollContainer.new()
	desplazable.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	desplazable.scroll_deadzone = Pantalla.ZONA_MUERTA_ARRASTRE
	desplazable.scroll_started.connect(Pantalla.cancelar_pulsaciones.bind(desplazable))
	tira.add_child(desplazable)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 2)
	desplazable.add_child(fila)
	for d in _datos_accesos():
		var b := _boton_acceso(d)
		b.add_theme_font_size_override("font_size", Tema.tam(12.5))
		# Con el texto entero, el icono ajustable se quedaría sin sitio: se reserva a mano.
		var ancho_texto := Tema.fuente(Tema.PESO_NEGRITA).get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.tam(12.5)).x
		b.custom_minimum_size.x = ceilf(ancho_texto + BotonAri.LADO_ICONO + 30.0)
		fila.add_child(b)
	return tira


func _marcar_grupo(grupo: String) -> void:
	if grupo.is_empty():
		return
	if _botones_grupo.has(grupo):
		var b: BotonAri = _botones_grupo[grupo]
		b.estilo = "ambar"
		# En la tira, el grupo activo se trae a la vista.
		if retrato:
			_traer_a_la_vista.call_deferred(b)


func _traer_a_la_vista(b: Control) -> void:
	if not is_instance_valid(b):
		return
	var desplazable := b.get_parent().get_parent() as ScrollContainer
	if desplazable != null:
		desplazable.ensure_control_visible(b)


func _desplazable_vertical() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	s.scroll_deadzone = Pantalla.ZONA_MUERTA_ARRASTRE
	s.scroll_started.connect(Pantalla.cancelar_pulsaciones.bind(s))
	return s


## Generación, consejos y alarmas: a la derecha en horizontal y en la hoja en vertical.
func _paneles_estado() -> Array[Control]:
	var gen := PanelAri.new("Generación", "sistema_1")
	gen.name = "Generacion"
	_caja_gen = gen.contenido
	_caja_gen.add_theme_constant_override("separation", 1)
	var consejos := PanelAri.new("Consejos", "aprender")
	consejos.name = "Consejos"
	_caja_consejos = consejos.contenido
	_caja_consejos.add_theme_constant_override("separation", 4)
	var alarmas := PanelAri.new("Alarmas", "monitor", true, 0)
	alarmas.name = "Alarmas"
	_cabecera_alarmas = alarmas.cabecera
	var lista := PanelContainer.new()
	lista.mouse_filter = Control.MOUSE_FILTER_PASS
	var negro := StyleBoxFlat.new()
	negro.bg_color = Tema.ARI_LISTA
	negro.content_margin_top = 4
	negro.content_margin_bottom = 4
	lista.add_theme_stylebox_override("panel", negro)
	alarmas.contenido.add_child(lista)
	alarmas.contenido.add_theme_constant_override("separation", 0)
	_lista_alarmas = VBoxContainer.new()
	_lista_alarmas.add_theme_constant_override("separation", 1)
	lista.add_child(_lista_alarmas)
	var botones := HBoxContainer.new()
	var m := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 4)
	m.add_child(botones)
	alarmas.contenido.add_child(m)
	var ack := BotonAri.new("ACK · Reconocer", _reconocer)
	ack.name = "Reconocer"
	ack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ack.add_theme_font_size_override("font_size", Tema.tam(12))
	botones.add_child(ack)
	# Las alarmas antes que los consejos: en un celular apaisado no deben quedar fuera de la vista.
	return [gen, alarmas, consejos]


func _fila_estado() -> Control:
	var m := MarginContainer.new()
	m.name = "Estado"
	m.add_theme_constant_override("margin_left", int(MARGEN))
	m.add_theme_constant_override("margin_right", int(MARGEN))
	m.add_theme_constant_override("margin_bottom", 4)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", int(SEP))
	m.add_child(fila)
	fila.add_child(_boton_vecino(-1))
	var gen := BotonAri.new("", _abrir_hoja)
	gen.name = "VerGeneracion"
	gen.custom_minimum_size.y = ALTO_ESTADO
	gen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(gen)
	var dentro := HBoxContainer.new()
	dentro.alignment = BoxContainer.ALIGNMENT_CENTER
	dentro.add_theme_constant_override("separation", 6)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
	gen.add_child(dentro)
	_estado_total = LecturaLcd.new("0,0", "", 12.0, 5)
	_estado_total.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dentro.add_child(_estado_total)
	_estado_grupos = PanelAri.texto("kW", 12, Tema.ARI_TEXTO, Tema.PESO_NEGRITA)
	_estado_grupos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dentro.add_child(_estado_grupos)
	_boton_alarmas = BotonAri.new("Alarmas", _abrir_hoja, "azul", "monitor")
	_boton_alarmas.name = "VerAlarmas"
	_boton_alarmas.custom_minimum_size.y = ALTO_ESTADO
	_boton_alarmas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boton_alarmas.add_theme_font_size_override("font_size", Tema.tam(13))
	fila.add_child(_boton_alarmas)
	_insignia = PanelAri.texto("", 12, Tema.ARI_ROJO[2], 800)
	var pastilla := StyleBoxFlat.new()
	pastilla.bg_color = Color.WHITE
	pastilla.set_corner_radius_all(10)
	pastilla.content_margin_left = 7
	pastilla.content_margin_right = 7
	_insignia.add_theme_stylebox_override("normal", pastilla)
	_insignia.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_insignia.position = Vector2(-34, -10)
	_boton_alarmas.add_child(_insignia)
	_insignia.anchor_left = 1.0
	_insignia.anchor_right = 1.0
	_insignia.anchor_top = 0.5
	_insignia.anchor_bottom = 0.5
	_insignia.offset_left = -38
	_insignia.offset_top = -11
	fila.add_child(_boton_vecino(1))
	return m


func _pie() -> Control:
	var pie := Lamina.new(Tema.ARI_PIE, 0.0)
	pie.name = "Pie"
	pie.linea_arriba = true
	pie.custom_minimum_size.y = ALTO_PIE_RETRATO if retrato else ALTO_PIE
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(fila)
	_reloj = LecturaLcd.new("00:00:00", "", 11.0)
	_reloj.color = CIAN_RELOJ
	_reloj.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_reloj)
	var triangulo := Triangulo.new()
	triangulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(triangulo)
	_evento = PanelAri.texto("", 12, Tema.ARI_EVENTO, Tema.PESO_NEGRITA)
	_evento.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_evento.clip_text = true
	_evento.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fila.add_child(_evento)
	var luz := LuzPiloto.new()
	luz.custom_minimum_size = Vector2(12, 12)
	luz.encendida = true
	luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(luz)
	_escenario = PanelAri.texto("", 10.5, Tema.ARI_TEXTO_SUAVE)
	fila.add_child(_escenario)
	return pie


func _crear_hoja() -> Control:
	var capa := VBoxContainer.new()
	capa.name = "Hoja"
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.offset_bottom = -ALTO_PIE_RETRATO
	capa.add_theme_constant_override("separation", 0)
	capa.visible = false
	var velo := Velo.new()
	velo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	velo.tocado.connect(_cerrar_hoja)
	capa.add_child(velo)
	var lamina := Lamina.new([Color("245d90"), Color("163f66")], 16.0)
	lamina.linea_arriba = true
	lamina.solo_arriba = true
	capa.add_child(lamina)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", int(SEP))
	lamina.add_child(columna)
	var asa := BotonAri.new("", _cerrar_hoja)
	asa.name = "Cerrar"
	asa.signo = ""
	asa.custom_minimum_size = Vector2(120, 48)
	asa.hueco = Vector2(36, 20)
	asa.radio = 3.0
	asa.tooltip_text = "Cerrar"
	asa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(asa)
	var desplazable := _desplazable_vertical()
	desplazable.name = "HojaDesplazable"
	columna.add_child(desplazable)
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", int(SEP))
	desplazable.add_child(caja)
	for p in _paneles_estado():
		caja.add_child(p)
	return capa


# --- Acciones ---

func _abrir_acceso(tipo: String, grupo: String) -> void:
	match tipo:
		"grupo":
			var lista := raiz.paneles.de_grupo(grupo).filter(Paneles.disponible)
			if not lista.is_empty():
				raiz.ir_a_panel(lista[0]["codigo"])
		_:
			if raiz.nombre_actual() != tipo:
				raiz.ir_a(tipo)


func _ir_vecino(paso: int) -> void:
	var siguiente := raiz.paneles.vecino(codigo, paso)
	if not siguiente.is_empty():
		raiz.ir_a_panel(siguiente)


func _alternar_pliegue() -> void:
	raiz.marco_plegado = not raiz.marco_plegado
	raiz.reconstruir.call_deferred()


func _abrir_hoja() -> void:
	if _hoja == null:
		return
	var desplazable := _hoja.find_child("HojaDesplazable", true, false) as ScrollContainer
	desplazable.custom_minimum_size.y = raiz.size.y * 0.68
	_hoja.visible = true
	_ajustar_hoja.call_deferred()


## La hoja mide lo que su contenido, sin pasar de dos tercios de la pantalla. Se calcula con la
## hoja ya abierta: antes, los textos con ajuste de línea no saben su ancho y piden de más.
func _ajustar_hoja() -> void:
	# Un fotograma para que los contenedores repartan el ancho a los textos.
	await get_tree().process_frame
	if _hoja == null or not is_instance_valid(_hoja) or not _hoja.visible:
		return
	var desplazable := _hoja.find_child("HojaDesplazable", true, false) as ScrollContainer
	var alto: float = (desplazable.get_child(0) as Control).get_combined_minimum_size().y
	desplazable.custom_minimum_size.y = minf(alto, raiz.size.y * 0.68)


func _cerrar_hoja() -> void:
	if _hoja != null:
		_hoja.visible = false


func hoja_abierta() -> bool:
	return _hoja != null and _hoja.visible


func _reconocer() -> void:
	_reconocidas_pantalla = true
	raiz.eventos.reconocer()


func _mostrar_ayuda() -> void:
	if _ayuda != null and is_instance_valid(_ayuda):
		_ayuda.queue_free()
	_ayuda = Control.new()
	_ayuda.name = "VentanaAyuda"
	_ayuda.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ayuda)
	var velo := Velo.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.tocado.connect(_cerrar_ayuda)
	_ayuda.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ayuda.add_child(centro)
	var panel := PanelAri.new("Ayuda", "aprender", false, 10)
	# Con el tamaño de la raíz: el marco recién hecho aún no tiene el suyo.
	panel.custom_minimum_size.x = minf(420.0, raiz.size.x - 32.0)
	centro.add_child(panel)
	var cab := PanelAri.texto(("%s · %s" % [_placa_codigo.text, titulo]) if not _placa_codigo.text.is_empty() else titulo, 15, Tema.ARI_TEXTO, Tema.PESO_NEGRITA)
	cab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.contenido.add_child(cab)
	if not nota.is_empty():
		var n := PanelAri.texto(nota, 13, Tema.ARI_TEXTO_SUAVE)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.contenido.add_child(n)
	for c: String in _consejos():
		var e := PanelAri.texto("• " + c, 13)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.contenido.add_child(e)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", int(SEP))
	panel.contenido.add_child(fila)
	if raiz.nombre_actual() != "leyenda":
		var ley := BotonAri.new("Leyenda", func() -> void: raiz.ir_a("leyenda"), "azul", "simbolos")
		ley.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(ley)
	var cerrar := BotonAri.new("Cerrar", _cerrar_ayuda)
	cerrar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(cerrar)


func _cerrar_ayuda() -> void:
	if _ayuda != null and is_instance_valid(_ayuda):
		_ayuda.queue_free()
	_ayuda = null


func ayuda_abierta() -> bool:
	return _ayuda != null and is_instance_valid(_ayuda) and not _ayuda.is_queued_for_deletion()


# --- Lecturas ---

func _process(delta: float) -> void:
	_t += delta
	_actualizar_reloj()
	if _t < PERIODO_LECTURA:
		return
	_t = 0.0
	_encendido = not _encendido
	for c in _parpadeantes:
		if is_instance_valid(c):
			c.modulate.a = 1.0 if _encendido else 0.35
	if _boton_alarmas != null and _boton_alarmas.estilo == "rojo":
		_boton_alarmas.modulate = Color(1, 1, 1) if _encendido else Color(0.82, 0.82, 0.82)
	_leer_generacion()


func _actualizar_reloj() -> void:
	var t := Time.get_time_dict_from_system()
	if t["second"] == _segundo:
		return
	_segundo = t["second"]
	_reloj.texto = "%02d:%02d:%02d" % [t["hour"], t["minute"], t["second"]]


## Generación de la pantalla, si tiene simulación propia, o la del escenario del buque.
func generacion() -> Dictionary:
	var g := pantalla.generacion_marco() if pantalla != null else {}
	if not g.is_empty():
		return g
	var e: Dictionary = raiz.contenido.barco().get("escenario_marco", {})
	var filas: Array = []
	for f: Dictionary in e.get("generacion_kw", []):
		filas.append({"nombre": f["nombre"], "kw": float(f["kw"]), "en_linea": float(f["kw"]) > 0.0})
	return {"filas": filas, "nominal": float(e.get("potencia_nominal_kw", 452)), "escenario": e.get("nombre", ""), "tension": e.get("tension", "")}


func _leer_generacion() -> void:
	var g := generacion()
	var filas: Array = g.get("filas", [])
	if _caja_gen != null and _filas_gen.size() != filas.size():
		_crear_filas_gen(filas.size())
	var total := 0.0
	var en_linea := 0
	var nominal: float = maxf(g.get("nominal", 452.0), 1.0)
	for i in filas.size():
		var f: Dictionary = filas[i]
		var kw: float = f["kw"]
		total += maxf(kw, 0.0)
		if f.get("en_linea", false):
			en_linea += 1
		if _caja_gen == null:
			continue
		var partes: Array = _filas_gen[i]
		(partes[0] as LuzPiloto).encendida = f.get("en_linea", false)
		(partes[1] as Label).text = f["nombre"]
		(partes[2] as BarraCarga).fraccion = clampf(kw / nominal, 0.0, 1.0)
		(partes[3] as LecturaLcd).texto = LecturaLcd.numero(kw, 1)
	if _lcd_total != null:
		_lcd_total.texto = LecturaLcd.numero(total, 1)
		_texto_red.text = g.get("tension", "")
	if _estado_total != null:
		_estado_total.texto = LecturaLcd.numero(total, 1)
		_estado_grupos.text = "kW · %d gen." % en_linea
	if _escenario != null:
		_escenario.text = g.get("escenario", "")


func _crear_filas_gen(n: int) -> void:
	for hijo in _caja_gen.get_children():
		_caja_gen.remove_child(hijo)
		hijo.queue_free()
	_filas_gen.clear()
	var tam := 12.5 if retrato else 11.5
	for i in n:
		var fila := HBoxContainer.new()
		fila.name = "Gen%d" % i
		fila.add_theme_constant_override("separation", 6)
		_caja_gen.add_child(fila)
		var luz := LuzPiloto.new()
		luz.custom_minimum_size = Vector2(13, 13)
		luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(luz)
		var nombre := PanelAri.texto("", tam, Color("d6e5f2"))
		nombre.custom_minimum_size.x = 92 if retrato else 82
		nombre.clip_text = true
		fila.add_child(nombre)
		var barra := BarraCarga.new()
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(barra)
		var lcd := LecturaLcd.new("0,0", "", 11.0, 5)
		lcd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(lcd)
		fila.add_child(PanelAri.texto("kW", 10, Tema.ARI_TEXTO_SUAVE))
		_filas_gen.append([luz, nombre, barra, lcd])
	var separador := HSeparator.new()
	separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var linea := StyleBoxLine.new()
	linea.color = Tema.ARI_BORDE
	separador.add_theme_stylebox_override("separator", linea)
	_caja_gen.add_child(separador)
	var total := HBoxContainer.new()
	total.name = "Total"
	total.add_theme_constant_override("separation", 6)
	_caja_gen.add_child(total)
	total.add_child(PanelAri.texto("Total barras", tam, Tema.ARI_TEXTO, Tema.PESO_NEGRITA))
	_texto_red = PanelAri.texto("", 10, Tema.ARI_TEXTO_SUAVE)
	_texto_red.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto_red.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_texto_red.clip_text = true
	total.add_child(_texto_red)
	_lcd_total = LecturaLcd.new("0,0", "", 12.0 if retrato else 11.0, 5)
	_lcd_total.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	total.add_child(_lcd_total)
	total.add_child(PanelAri.texto("kW", 10, Tema.ARI_TEXTO_SUAVE))


func _poner_consejos(lista: Array) -> void:
	if _caja_consejos == null:
		return
	for hijo in _caja_consejos.get_children():
		hijo.queue_free()
	if lista.is_empty():
		_caja_consejos.get_parent().get_parent().get_parent().visible = false
		return
	for i in lista.size():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 7)
		_caja_consejos.add_child(fila)
		var numero := Numero.new(i + 1)
		numero.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		fila.add_child(numero)
		var t := PanelAri.texto(str(lista[i]), 12.5 if retrato else 11.5, Color("e4eef7"))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(t)


func _al_cambiar_eventos() -> void:
	_actualizar_alarmas()
	_actualizar_pie()


## Alarmas activas: las de la pantalla (una avería en curso) y las del registro de la sesión.
func alarmas_visibles() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	if pantalla != null:
		for t: String in pantalla.alarmas_marco():
			r.append({"hora": "", "texto": t, "tipo": "alarma", "reconocida": _reconocidas_pantalla})
	r.append_array(raiz.eventos.alarmas())
	return r


func pendientes() -> int:
	var n := 0
	for a in alarmas_visibles():
		if a["tipo"] == "alarma" and not a["reconocida"]:
			n += 1
	return n


func _actualizar_alarmas() -> void:
	var lista := alarmas_visibles()
	var activas := lista.filter(func(a: Dictionary) -> bool: return a["tipo"] == "alarma").size()
	if _cabecera_alarmas != null:
		_cabecera_alarmas.text = "ALARMAS · %d" % activas if activas > 0 else "ALARMAS"
	if _lista_alarmas != null:
		for hijo in _lista_alarmas.get_children():
			hijo.queue_free()
		_parpadeantes.clear()
		if lista.is_empty():
			_lista_alarmas.add_child(_fila_alarma({"hora": "", "texto": "Sin alarmas", "tipo": "normal", "reconocida": true}))
		for a in lista.slice(0, 6):
			var fila := _fila_alarma(a)
			_lista_alarmas.add_child(fila)
			if a["tipo"] == "alarma" and not a["reconocida"]:
				_parpadeantes.append(fila)
	if _boton_alarmas != null:
		var sin_reconocer := pendientes()
		_boton_alarmas.estilo = "rojo" if activas > 0 else "azul"
		_boton_alarmas.modulate = Color.WHITE
		_insignia.text = str(activas)
		_insignia.visible = activas > 0
		_boton_alarmas.text = "Alarmas" if activas > 0 else "Sin alarmas"
		if sin_reconocer == 0:
			_boton_alarmas.modulate = Color.WHITE


func _fila_alarma(a: Dictionary) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 8)
	m.add_theme_constant_override("margin_right", 6)
	m.add_child(fila)
	var color := Tema.ARI_ALARMA if a["tipo"] == "alarma" else Tema.ARI_NORMAL
	var punto := Punto.new(color)
	punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(punto)
	if not str(a["hora"]).is_empty():
		fila.add_child(PanelAri.texto(a["hora"], 11, Color("8aa0b2"), Tema.PESO_NORMAL))
	var t := PanelAri.texto(str(a["texto"]).to_upper(), 11 if not retrato else 12, color, Tema.PESO_NEGRITA)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(t)
	return m


func _actualizar_pie() -> void:
	if _evento == null:
		return
	var u := raiz.eventos.ultimo()
	if not u.is_empty():
		_evento.text = u["texto"]
	elif pantalla != null and not pantalla.alarmas_marco().is_empty():
		_evento.text = pantalla.alarmas_marco()[0]
	else:
		_evento.text = "Sin novedad"


# --- Piezas pequeñas ---

## Lámina con degradado, para las barras, el pie y la hoja.
class Lamina:
	extends PanelContainer
	var colores: Array
	var radio: float
	var linea_arriba := false
	var linea_abajo := false
	var solo_arriba := false

	func _init(c: Array, r: float) -> void:
		colores = c
		radio = r
		mouse_filter = Control.MOUSE_FILTER_PASS
		var vacia := StyleBoxEmpty.new()
		vacia.content_margin_left = 6
		vacia.content_margin_right = 6
		vacia.content_margin_top = 4
		vacia.content_margin_bottom = 4
		add_theme_stylebox_override("panel", vacia)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if solo_arriba:
			DibujoAri.degradado(self, Rect2(r.position, r.size + Vector2(0, radio * 2.0)), radio, colores, [], r)
		else:
			DibujoAri.degradado(self, r, radio, colores, DibujoAri.BRILLO if colores.size() == 4 else [])
		if linea_arriba:
			draw_line(Vector2(radio, 0.5), Vector2(size.x - radio, 0.5), Tema.ARI_LINEA if not solo_arriba else Color("8cc3ec"), 1.0)
		if linea_abajo:
			draw_line(Vector2(0, size.y - 0.5), Vector2(size.x, size.y - 0.5), Color("0a2238"), 1.0)
			draw_line(Vector2(0, 0.5), Vector2(size.x, 0.5), Color(1, 1, 1, 0.25), 1.0)


## Velo oscuro detrás de una hoja o de la ayuda: tocarlo la cierra.
class Velo:
	extends ColorRect
	signal tocado

	func _init() -> void:
		color = Color(0.01, 0.04, 0.07, 0.62)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(evento: InputEvent) -> void:
		if (evento is InputEventMouseButton and evento.pressed) or (evento is InputEventScreenTouch and evento.pressed):
			tocado.emit()
			accept_event()


class BarraCarga:
	extends Control
	var fraccion := 0.0:
		set(valor):
			if not is_equal_approx(valor, fraccion):
				fraccion = valor
				queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(24, 6)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DibujoAri.relleno(self, r, 3.0, Color("0b2238"))
		if fraccion > 0.01:
			var lleno := Rect2(r.position, Vector2(maxf(r.size.x * fraccion, 6.0), r.size.y))
			var color := Color("2fd96a") if fraccion < 0.9 else Tema.ARI_LCD_AMBAR
			DibujoAri.relleno(self, lleno, 3.0, color)
			draw_line(Vector2(3, 1), Vector2(lleno.end.x - 3, 1), Color(1, 1, 1, 0.35), 1.0)


class Numero:
	extends Control
	var n: int

	func _init(valor: int) -> void:
		n = valor
		custom_minimum_size = Vector2(17, 17)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 8.0, Tema.ARI_EVENTO)
		var f := Tema.fuente(Tema.PESO_NEGRITA)
		var t := str(n)
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(f, c + Vector2(-w / 2.0, 4.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.ARI_TEXTO_OSCURO)


class Punto:
	extends Control
	var color: Color

	func _init(c: Color) -> void:
		color = c
		custom_minimum_size = Vector2(9, 9)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size / 2.0, 4.5, Color(color, 0.3))
		draw_circle(size / 2.0, 3.2, color)


class Triangulo:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(17, 15)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		DibujoAri.triangulo_aviso(self, Rect2(Vector2.ZERO, size))
