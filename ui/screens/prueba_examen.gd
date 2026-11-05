extends PantallaPreguntas
## Examen de la versión: preguntas al azar de un banco, con calificación final.


func _datos() -> Dictionary:
	return raiz.contenido.leer("examenes/%s.json" % args["id"])


func _crear_items() -> Array:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	return ExamenTeorico.crear(_datos(), raiz.contenido.simbolos(), azar)


func _titulo() -> String:
	return _datos()["titulo"]


func _al_contestar(item: Dictionary, acierto: bool) -> void:
	if not acierto:
		raiz.partida.registrar_error(item["tema"])


func _construir_final() -> void:
	var datos := _datos()
	var total: int = args["items"].size()
	var correctas := aciertos()
	var minimo: float = datos["minimo"]
	var porcentaje := ExamenTeorico.porcentaje(correctas, total)
	var aprobado := ExamenTeorico.aprobado(correctas, total, minimo)
	var estrellas := ExamenTeorico.estrellas(correctas, total, minimo)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_examen(args["id"], porcentaje, estrellas, aprobado)
	_cabecera(datos["titulo"], "Resultado")
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	columna.add_child(_etiqueta("Aprobado" if aprobado else "No aprobado", "Titulo"))
	columna.add_child(_etiqueta("Respuestas correctas: %d de %d (%d %%). Mínimo para aprobar: %d %%." % [correctas, total, roundi(porcentaje), roundi(minimo)]))
	if aprobado:
		columna.add_child(_etiqueta("Calificación: %d de 3 estrellas" % estrellas))
	var ganados: int = args["ganados"]
	if ganados > 0:
		columna.add_child(_etiqueta("Puntos obtenidos: %d." % ganados))
	_agregar_falladas(columna)
	columna.add_child(_rotulo("Para saber más"))
	for fuente: String in datos.get("para_saber_mas", []):
		columna.add_child(_etiqueta("• %s" % fuente, "Nota"))
	if correctas < total:
		columna.add_child(_boton("Repasar mis errores", _ir_al_repaso))
	columna.add_child(_boton("Repetir con otras preguntas", _repetir))
	columna.add_child(_boton("Volver", raiz.volver))


func _agregar_falladas(columna: VBoxContainer) -> void:
	var items: Array = args["items"]
	var banco := BancoRepaso.new(raiz.contenido)
	var hay := false
	for i in items.size():
		if args["respuestas"][i]["acierto"]:
			continue
		if not hay:
			columna.add_child(_rotulo("Temas a repasar"))
			hay = true
		columna.add_child(_etiqueta("• %s" % banco.titulo(items[i]["tema"])))


func _ir_al_repaso() -> void:
	raiz.volver()
	raiz.ir_a("repaso")


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()
