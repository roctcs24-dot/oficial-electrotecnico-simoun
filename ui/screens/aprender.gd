extends Pantalla
## Contenido disponible para aprender en un sistema.


func construir() -> void:
	var c := raiz.contenido
	var s := c.sistema(args["id"])
	_cabecera("Aprender", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(8)
	desplazable.add_child(lista)
	var contenido_modo: Dictionary = s["modos"]["aprender"]
	var lecciones: Array = contenido_modo.get("lecciones", [])
	if not lecciones.is_empty():
		lista.add_child(_etiqueta("Lecciones", "Subtitulo"))
		for i in lecciones.size():
			lista.add_child(_boton_leccion(lecciones[i], i + 1))
	var fichas: Array = contenido_modo.get("fichas", [])
	if not fichas.is_empty():
		lista.add_child(_etiqueta("Fichas de equipos", "Subtitulo"))
		for id: String in fichas:
			lista.add_child(_boton_ficha(id))
	lista.add_child(_etiqueta("Consulta", "Subtitulo"))
	lista.add_child(_boton("Glosario español-inglés", raiz.ir_a.bind("glosario")))


func _boton_leccion(id: String, numero: int) -> Button:
	var l := raiz.contenido.leccion(id)
	var estado := ""
	if raiz.partida.leccion_completada(id):
		var r: Dictionary = raiz.partida.datos["lecciones"][id]
		estado = "  ·  completada, %d de %d" % [r["aciertos"], r["total"]]
	var texto := "%d. %s%s\n%s  ·  %d min" % [numero, l.get("titulo", id), estado, l.get("resumen", ""), l.get("minutos", 0)]
	var b := _boton(texto, raiz.ir_a.bind("leccion", {"id": id, "sistema": args["id"]}))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b


func _boton_ficha(id: String) -> Button:
	var ficha := raiz.contenido.ficha(id)
	var visto := "  ·  visto" if raiz.partida.ficha_vista(id) else ""
	var b := _boton("%s%s\n%s" % [ficha.get("titulo", id), visto, ficha.get("resumen", "")], raiz.ir_a.bind("ficha", {"id": id}))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b
