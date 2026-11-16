extends Pantalla
## Contenido disponible para aprender en un sistema: las lecciones en orden, con la siguiente
## recomendada resaltada y las hechas marcadas, y las fichas de equipos.


func construir() -> void:
	var c := raiz.contenido
	var s := c.sistema(args["id"])
	var color := Tema.color_area(s)
	_cabecera("Aprender", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(8)
	desplazable.add_child(_ancho_lectura(lista))
	var contenido_modo: Dictionary = s["modos"]["aprender"]
	var lecciones: Array = contenido_modo.get("lecciones", [])
	if not lecciones.is_empty():
		var parte := Avance.lecciones(s, raiz.partida)
		lista.add_child(_rotulo("Lecciones · %d de %d hechas" % parte))
		var barra := _barra_avance(Avance.fraccion(parte))
		barra.add_theme_stylebox_override("fill", Tema.caja(color, 3, 0, 0))
		lista.add_child(barra)
		var siguiente := Avance.siguiente_leccion(s, raiz.partida)
		for i in lecciones.size():
			lista.add_child(_fila_leccion(lecciones[i], i + 1, color, lecciones[i] == siguiente))
	var atlas: Array = contenido_modo.get("atlas", [])
	if not atlas.is_empty():
		var parte := Avance.atlas(s, raiz.partida)
		lista.add_child(_rotulo("Atlas de componentes · %d de %d vistos" % parte))
		lista.add_child(_etiqueta("Cada componente en cinco vistas: qué es, cómo funciona, cómo se conecta, cómo se mide, y fallas y mantenimiento.", "Nota"))
		for id: String in atlas:
			lista.add_child(_fila_atlas(id, color))
	var fichas: Array = contenido_modo.get("fichas", [])
	if not fichas.is_empty():
		lista.add_child(_rotulo("Fichas de equipos"))
		for id: String in fichas:
			lista.add_child(_fila_ficha(id, color))
	lista.add_child(_rotulo("Consulta"))
	lista.add_child(_fila("Glosario español-inglés", "", raiz.ir_a.bind("glosario"), "glosario", "", true, {"color": color}))


func _fila_leccion(id: String, numero: int, color: Color, es_siguiente: bool) -> FilaMenu:
	var l := raiz.contenido.leccion(id)
	var estado := "%d min" % l.get("minutos", 0)
	var hecha := raiz.partida.leccion_completada(id)
	if hecha:
		var r: Dictionary = raiz.partida.datos["lecciones"][id]
		estado = "%d / %d" % [r["aciertos"], r["total"]]
	elif es_siguiente:
		estado = "Siguiente"
	var titulo := "%d. %s" % [numero, l.get("titulo", id)]
	var opciones := {"color": color, "hecho": hecha, "siguiente": es_siguiente}
	return _fila(titulo, l.get("resumen", ""), raiz.ir_a.bind("leccion", {"id": id, "sistema": args["id"]}), "leccion", estado, true, opciones)


func _fila_atlas(id: String, color: Color) -> FilaMenu:
	var a := raiz.contenido.atlas(id)
	var vistas := raiz.partida.pestanas_atlas(id)
	var hecha := raiz.partida.atlas_completo(id)
	var estado := "" if vistas == 0 or hecha else "%d de 5" % mini(vistas, 5)
	return _fila(a.get("titulo", id), a.get("resumen", ""), raiz.ir_a.bind("atlas", {"id": id}), str(a.get("icono", "ficha")), estado, true, {"color": color, "hecho": hecha, "avance": minf(vistas / 5.0, 1.0)})


func _fila_ficha(id: String, color: Color) -> FilaMenu:
	var ficha := raiz.contenido.ficha(id)
	var vista := raiz.partida.ficha_vista(id)
	return _fila(ficha.get("titulo", id), ficha.get("resumen", ""), raiz.ir_a.bind("ficha", {"id": id}), "ficha", "", true, {"color": color, "hecho": vista})
