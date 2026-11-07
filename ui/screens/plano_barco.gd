extends Pantalla
## Menú principal: el plano del barco dividido por sistemas.

const ALTO_PLANO_POR_ANCHO := 0.42
const ANCHO_RANGO := 240.0


func construir() -> void:
	var c := raiz.contenido
	var barco := c.barco()
	add_child(_crear_cabecera(barco))

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
		plano.tableros = plano_datos.get("tableros", [])
		plano.tablero_tocado.connect(func(id: String) -> void: raiz.ir_a("tablero", {"tablero": id}))
		if raiz.vertical:
			plano.custom_minimum_size.y = maxf(170.0, raiz.size.x * ALTO_PLANO_POR_ANCHO)
		else:
			plano.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_child(plano)

	var lista := _desplazable()
	cuerpo.add_child(lista)
	var filas := _columna(6)
	lista.add_child(filas)
	filas.add_child(_rotulo("Sistemas del buque"))
	for s: Dictionary in c.sistemas():
		filas.add_child(_fila_sistema(s))
	filas.add_child(_rotulo("Progreso"))
	for id: String in c.examenes():
		filas.add_child(_fila_examen(id))
	filas.add_child(_fila_repaso())
	filas.add_child(_fila("Mi progreso", "Rango, estadísticas y traspaso de la partida", raiz.ir_a.bind("progreso"), "progreso"))
	filas.add_child(_rotulo("Consulta"))
	filas.add_child(_fila("Glosario español-inglés", "", raiz.ir_a.bind("glosario"), "glosario"))


func _crear_cabecera(barco: Dictionary) -> Control:
	var barra := _tarjeta_base("Cabecera")
	var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	disposicion.add_theme_constant_override("separation", 8 if raiz.vertical else 12)
	barra.add_child(disposicion)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	disposicion.add_child(textos)
	textos.add_child(_etiqueta(barco.get("nombre", "Oficial Electrotécnico"), "Titulo"))
	textos.add_child(_etiqueta(_resumen_barco(barco), "Nota"))
	disposicion.add_child(_crear_rango())
	return barra


## En vertical ocupa todo el ancho; en horizontal, una columna a la derecha.
func _crear_rango() -> Control:
	var rangos := raiz.contenido.rangos()
	var rango := _columna(3)
	if not raiz.vertical:
		rango.size_flags_horizontal = Control.SIZE_SHRINK_END
		rango.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rango.custom_minimum_size.x = ANCHO_RANGO
	var textos := HBoxContainer.new()
	textos.add_theme_constant_override("separation", 12)
	rango.add_child(textos)
	var nombre := _etiqueta(raiz.partida.rango(rangos), "Nota")
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(nombre)
	var puntos := _etiqueta("%d pts" % raiz.partida.datos["puntos"], "Nota")
	puntos.autowrap_mode = TextServer.AUTOWRAP_OFF
	puntos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos.add_child(puntos)
	rango.add_child(_barra_avance(raiz.partida.progreso_rango(rangos)))
	return rango


func _fila_examen(id: String) -> FilaMenu:
	var e := raiz.contenido.examen(id)
	var r: Dictionary = raiz.partida.datos["examenes"].get(id, {})
	var estado := ""
	if not r.is_empty():
		estado = "%d de 3 estrellas" % int(r["estrellas"]) if r["aprobado"] else "No aprobado"
	return _fila(e.get("titulo", "Examen"), e.get("resumen", ""), raiz.ir_a.bind("prueba_examen", {"id": id}), "examen", estado)


func _fila_repaso() -> FilaMenu:
	var pendientes := raiz.partida.temas_pendientes().size()
	var detalle := "Sin temas pendientes" if pendientes == 0 else "%d temas pendientes" % pendientes
	return _fila("Repasar mis errores", detalle, raiz.ir_a.bind("repaso"), "repaso")


func _fila_sistema(s: Dictionary) -> FilaMenu:
	var id := int(s["id"])
	var activo: bool = s["estado"] == "activo"
	return _fila("%d · %s" % [id, s["nombre"]], "Próximamente" if not activo else _avance_sistema(s), _abrir_sistema.bind(id), "sistema_%d" % id, "", activo)


func _avance_sistema(s: Dictionary) -> String:
	var lecciones: Array = s["modos"].get("aprender", {}).get("lecciones", [])
	if lecciones.is_empty():
		return s.get("resumen", "")
	var hechas := 0
	for id: String in lecciones:
		if raiz.partida.leccion_completada(id):
			hechas += 1
	return "%d de %d lecciones completadas" % [hechas, lecciones.size()]


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
