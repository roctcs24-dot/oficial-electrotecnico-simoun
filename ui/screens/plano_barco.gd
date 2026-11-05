extends Pantalla
## Menú principal: el plano del barco dividido por sistemas.

const ALTO_PLANO_POR_ANCHO := 0.42


func construir() -> void:
	var c := raiz.contenido
	var barco := c.barco()
	var cabecera := HBoxContainer.new()
	add_child(cabecera)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	cabecera.add_child(textos)
	textos.add_child(_etiqueta(barco.get("nombre", "Oficial Electrotécnico"), "Titulo"))
	textos.add_child(_etiqueta(_resumen_barco(barco), "Nota"))
	var rango := _etiqueta("%s · %d pts" % [raiz.partida.rango(c.rangos()), raiz.partida.datos["puntos"]], "Nota")
	rango.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rango.autowrap_mode = TextServer.AUTOWRAP_OFF
	cabecera.add_child(rango)

	if not raiz.partida.aviso.is_empty():
		add_child(_aviso(raiz.partida.aviso))
	for error in c.errores:
		add_child(_aviso(error))

	var cuerpo: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 12)
	add_child(cuerpo)

	var plano_datos := c.plano()
	if not plano_datos.is_empty():
		var plano := PlanoInteractivo.new()
		plano.sistemas = c.sistemas()
		plano.cargar(plano_datos)
		plano.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plano.size_flags_stretch_ratio = 1.6
		plano.sistema_tocado.connect(_abrir_sistema)
		if raiz.vertical:
			plano.custom_minimum_size.y = maxf(170.0, raiz.size.x * ALTO_PLANO_POR_ANCHO)
		else:
			plano.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_child(plano)

	var lista := _desplazable()
	cuerpo.add_child(lista)
	var botones := _columna(8)
	lista.add_child(botones)
	for s: Dictionary in c.sistemas():
		var id := int(s["id"])
		var activo: bool = s["estado"] == "activo"
		var texto: String = "%d · %s" % [id, s["nombre"]]
		var b := _boton(texto if activo else "%s (próximamente)" % texto, _abrir_sistema.bind(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not activo
		botones.add_child(b)


func _resumen_barco(barco: Dictionary) -> String:
	if not barco.has("red_principal"):
		return ""
	var red: Dictionary = barco["red_principal"]
	return "%d V · %d Hz · trifásica · %d generadores" % [
		red["tension_v"]["valor"],
		red["frecuencia_hz"]["valor"],
		barco["generacion"]["cantidad"]["valor"],
	]


func _abrir_sistema(id: int) -> void:
	raiz.ir_a("sistema", {"id": id})
