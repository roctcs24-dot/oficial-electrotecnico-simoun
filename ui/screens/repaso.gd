extends PantallaPreguntas
## Repasar mis errores: repetición espaciada de lo que más se falla.

const POR_SESION := 10


func construir() -> void:
	if not args.has("items") and _temas_disponibles().is_empty():
		_construir_vacio()
		return
	super()


func _banco() -> BancoRepaso:
	return BancoRepaso.new(raiz.contenido)


## Los temas cuya pregunta ya no existe se omiten: nunca podrían resolverse.
func _temas_disponibles() -> Array[String]:
	var banco := _banco()
	var lista: Array[String] = []
	for tema in raiz.partida.temas_pendientes():
		if banco.tiene(tema):
			lista.append(tema)
	return lista


func _crear_items() -> Array:
	var banco := _banco()
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var items := []
	for tema in _temas_disponibles().slice(0, POR_SESION):
		items.append(banco.pregunta(tema, azar))
	return items


func _titulo() -> String:
	return "Repasar mis errores"


func _al_contestar(item: Dictionary, acierto: bool) -> void:
	raiz.partida.registrar_repaso(item["tema"], acierto)


func _construir_vacio() -> void:
	_cabecera(_titulo())
	var columna := _columna(12)
	add_child(_ancho_lectura(columna))
	columna.add_child(_etiqueta("No hay temas pendientes", "Subtitulo"))
	var texto := "Cuando falle una pregunta o cometa una falta en una misión, el tema aparecerá aquí."
	if not raiz.partida.datos["errores"].is_empty():
		texto = "Cada tema vuelve a aparecer después de un tiempo: 1, 3, 7, 14 y 30 días con cada acierto."
	columna.add_child(_etiqueta(texto))
	columna.add_child(_boton("Volver", raiz.volver))


func _construir_final() -> void:
	var total: int = args["items"].size()
	_cabecera(_titulo(), "Sesión terminada")
	var columna := _columna(12)
	add_child(_ancho_lectura(columna))
	columna.add_child(_etiqueta("Respuestas correctas: %d de %d" % [aciertos(), total], "Subtitulo"))
	columna.add_child(_etiqueta("Los temas acertados volverán más adelante. Los fallados, mañana."))
	var pendientes := _temas_disponibles().size()
	if pendientes > 0:
		columna.add_child(_etiqueta("Quedan %d temas pendientes para hoy." % pendientes, "Nota"))
		columna.add_child(_boton("Continuar el repaso", _continuar))
	columna.add_child(_boton("Volver", raiz.volver))


func _continuar() -> void:
	for clave in ["items", "indice", "respuestas"]:
		args.erase(clave)
	raiz.reconstruir()
