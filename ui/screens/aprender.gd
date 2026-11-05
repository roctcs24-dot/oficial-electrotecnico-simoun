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
	lista.add_child(_etiqueta("Fichas de equipos", "Subtitulo"))
	for id: String in s["modos"]["aprender"].get("fichas", []):
		var ficha := c.ficha(id)
		var visto := "  ·  visto" if raiz.partida.ficha_vista(id) else ""
		var b := _boton("%s%s\n%s" % [ficha.get("titulo", id), visto, ficha.get("resumen", "")], _abrir_ficha.bind(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		lista.add_child(b)


func _abrir_ficha(id: String) -> void:
	raiz.ir_a("ficha", {"id": id})
