extends Pantalla
## Misiones de avería disponibles en un sistema.


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera("Guardia", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(6)
	desplazable.add_child(_ancho_lectura(lista))
	lista.add_child(_etiqueta("Cada misión empieza con un reporte de avería. Aplique el procedimiento real: bloqueo y etiquetado, medición, diagnóstico, reparación, prueba y libro de registro.", "Nota"))
	for id: String in s["modos"]["guardia"].get("misiones", []):
		var m := raiz.contenido.mision(id)
		var pantalla := "mision_cuadro" if m.get("tipo", "") == "cuadro" else "mision"
		lista.add_child(_fila(m.get("titulo", id), m.get("resumen", ""), raiz.ir_a.bind(pantalla, {"id": id}), "guardia", _estado_mision(id)))


func _estado_mision(id: String) -> String:
	var r: Dictionary = raiz.partida.datos["misiones"].get(id, {})
	if r.is_empty():
		return ""
	if r.get("completada", false):
		return "%d de 3 estrellas" % int(r["estrellas"])
	return "Pendiente"
