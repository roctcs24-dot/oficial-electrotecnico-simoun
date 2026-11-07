extends Pantalla
## Taller de un sistema: el banco libre y los tableros reales del buque que se pueden manejar.


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera("Taller", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(8)
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazable.add_child(columna)
	columna.add_child(_fila("Banco libre", "Monte sus propios circuitos pieza a pieza y pruébelos", raiz.ir_a.bind("taller", {}), "taller"))
	var ids: Array = s.get("modos", {}).get("taller", {}).get("tableros", [])
	if ids.is_empty():
		return
	columna.add_child(_rotulo("Tableros del buque"))
	for id: String in ids:
		var t := raiz.contenido.tablero(id)
		columna.add_child(_fila(t.get("titulo", id), t.get("ubicacion", ""), raiz.ir_a.bind("tablero", {"tablero": id}), "taller"))
