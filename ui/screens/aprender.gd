extends Pantalla
## Contenido disponible para aprender en un sistema.


func construir() -> void:
	var c := raiz.contenido
	var s := c.sistema(args["id"])
	_cabecera("Aprender", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(6)
	desplazable.add_child(_ancho_lectura(lista))
	var contenido_modo: Dictionary = s["modos"]["aprender"]
	var lecciones: Array = contenido_modo.get("lecciones", [])
	if not lecciones.is_empty():
		lista.add_child(_rotulo("Lecciones"))
		for i in lecciones.size():
			lista.add_child(_fila_leccion(lecciones[i], i + 1))
	var fichas: Array = contenido_modo.get("fichas", [])
	if not fichas.is_empty():
		lista.add_child(_rotulo("Fichas de equipos"))
		for id: String in fichas:
			lista.add_child(_fila_ficha(id))
	lista.add_child(_rotulo("Consulta"))
	lista.add_child(_fila("Glosario español-inglés", "", raiz.ir_a.bind("glosario"), "glosario"))


func _fila_leccion(id: String, numero: int) -> FilaMenu:
	var l := raiz.contenido.leccion(id)
	var estado := "%d min" % l.get("minutos", 0)
	if raiz.partida.leccion_completada(id):
		var r: Dictionary = raiz.partida.datos["lecciones"][id]
		estado = "%d / %d" % [r["aciertos"], r["total"]]
	var titulo := "%d. %s" % [numero, l.get("titulo", id)]
	return _fila(titulo, l.get("resumen", ""), raiz.ir_a.bind("leccion", {"id": id, "sistema": args["id"]}), "leccion", estado)


func _fila_ficha(id: String) -> FilaMenu:
	var ficha := raiz.contenido.ficha(id)
	var visto := "Vista" if raiz.partida.ficha_vista(id) else ""
	return _fila(ficha.get("titulo", id), ficha.get("resumen", ""), raiz.ir_a.bind("ficha", {"id": id}), "ficha", visto)
