extends Pantalla
## Leyenda de los paneles: colores de las tuberías, estado de bombas y luces, mandos, lecturas
## digitales y grupos de códigos. Igual en todos los paneles del marco.

const TUBERIAS := [
	["Descarga: gas caliente a alta presión", "ff5a5a", ""],
	["Líquido de alta, del condensador a la expansión", "ffd23d", "discontinua"],
	["Aspiración: gas frío a baja presión", "5fe7ff", ""],
	["Amoníaco líquido bombeado a los serpentines", "4f9dff", ""],
	["Agua de mar de refrigeración", "4fe08a", ""],
	["Salmuera de las cubas", "d58cff", ""],
]
const BOMBAS := [
	["En marcha", "3dff74"],
	["Parada", "ff3b30"],
	["En reserva: arranca sola en AUTO", "ffd23d"],
	["Sin tensión", "7d8a96"],
]
const LUCES := [
	["START · en marcha", LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO],
	["STOP · parado", LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO],
	["Alarma o disparo", LuzPiloto.AMBAR_APAGADO, LuzPiloto.AMBAR_ENCENDIDO],
]


func construir() -> void:
	_cabecera("Colores, luces y mandos", "Iguales en todos los paneles")
	var desplazable := _desplazable()
	add_child(desplazable)
	var rejilla := GridContainer.new()
	rejilla.columns = 1 if raiz.vertical else 2
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", 8)
	rejilla.add_theme_constant_override("v_separation", 8)
	desplazable.add_child(rejilla)

	var tuberias := _seccion(rejilla, "Tuberías", "valvulas")
	for t: Array in TUBERIAS:
		tuberias.add_child(_muestra(MuestraLeyenda.new("tuberia", Color(t[1]), t[2]), t[0]))

	var bombas := _seccion(rejilla, "Bombas y motores", "motor")
	for b: Array in BOMBAS:
		bombas.add_child(_muestra(MuestraLeyenda.new("bomba", Color(b[1])), b[0]))

	var luces := _seccion(rejilla, "Luces piloto", "piloto")
	for l: Array in LUCES:
		var luz := LuzPiloto.new()
		luz.custom_minimum_size = Vector2(34, 34)
		luz.color_apagado = l[1]
		luz.color_encendido = l[2]
		luz.encendida = true
		luces.add_child(_muestra(luz, l[0]))
	var apagada := LuzPiloto.new()
	apagada.custom_minimum_size = Vector2(34, 34)
	luces.add_child(_muestra(apagada, "Apagada: se distingue el color, pero sin brillo"))

	var mandos := _seccion(rejilla, "Mandos", "selector")
	mandos.add_child(_muestra(MuestraLeyenda.new("selector", Color.WHITE, "man"), "MAN: se arranca y se para a mano"))
	mandos.add_child(_muestra(MuestraLeyenda.new("selector", Color.WHITE, "auto"), "AUTO: manda el presostato, el PLC o el PMS"))
	mandos.add_child(_muestra(MuestraLeyenda.new("interruptor", Color.WHITE, "on"), "ON: interruptor cerrado, con tensión a la salida"))
	mandos.add_child(_muestra(MuestraLeyenda.new("interruptor", Color.WHITE, "trip"), "TRIP: disparó; se rearma después de hallar la causa"))

	var lecturas := _seccion(rejilla, "Lecturas digitales", "voltimetro")
	lecturas.add_child(_muestra(LecturaLcd.new("12,6", "bar", 13.0), "Valor medido"))
	var alto := LecturaLcd.new("18,9", "bar", 13.0)
	alto.color = Tema.ARI_LCD_AMBAR
	lecturas.add_child(_muestra(alto, "Valor fuera de rango"))
	var reloj := LecturaLcd.new("13:09", "", 13.0)
	reloj.color = Tema.ARI_LCD_CIAN
	lecturas.add_child(_muestra(reloj, "Hora de a bordo"))

	var codigos := _seccion(rejilla, "Códigos de panel", "buque")
	for g: Dictionary in raiz.paneles.grupos():
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.custom_minimum_size.x = 40
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(g["color"])
		caja.set_corner_radius_all(4)
		caja.content_margin_left = 6
		caja.content_margin_right = 6
		chip.add_theme_stylebox_override("panel", caja)
		var t := PanelAri.texto("%s-" % g["id"], 12, Color.WHITE, 800)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(t)
		codigos.add_child(_muestra(chip, g["nombre"]))


func _seccion(padre: Control, titulo: String, icono: String) -> VBoxContainer:
	var panel := PanelAri.new(titulo, icono, false, 8)
	panel.name = titulo
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	padre.add_child(panel)
	panel.contenido.add_theme_constant_override("separation", 6)
	return panel.contenido


func _muestra(muestra: Control, texto: String) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hueco := CenterContainer.new()
	hueco.custom_minimum_size.x = 70
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hueco.add_child(muestra)
	muestra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(hueco)
	var e := PanelAri.texto(texto, 13)
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(e)
	return fila
