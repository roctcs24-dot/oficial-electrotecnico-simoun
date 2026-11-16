extends Pantalla
## Todas las fichas de equipos, agrupadas por el sistema o módulo que las publica, con su
## color y una marca en las ya vistas.


func construir() -> void:
	_cabecera("Fichas de equipos", "Del Pañol: todas las fichas del juego")
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(8)
	desplazable.add_child(_ancho_lectura(lista))
	var vistas := {}
	for s: Dictionary in raiz.contenido.todos():
		var ids: Array = s.get("modos", {}).get("aprender", {}).get("fichas", [])
		if ids.is_empty():
			continue
		lista.add_child(_rotulo(s.get("nombre", "")))
		var color := Tema.color_area(s)
		for id: String in ids:
			if vistas.has(id):
				continue
			vistas[id] = true
			var f := raiz.contenido.ficha(id)
			lista.add_child(_fila(f.get("titulo", id), f.get("resumen", ""), raiz.ir_a.bind("ficha", {"id": id}), "ficha", "", true, {"color": color, "hecho": raiz.partida.ficha_vista(id)}))
