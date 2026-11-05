extends Pantalla
## Evaluaciones disponibles en un sistema.

const NOMBRES := {
	"simbolos": ["minijuego_simbolos", "Identificación de símbolos", "IEC 60617 y ANSI/IEEE 315", "simbolos"],
}


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera("Examen", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(6)
	desplazable.add_child(_ancho_lectura(lista))
	for id: String in s["modos"]["examen"].get("minijuegos", []):
		var datos: Array = NOMBRES[id]
		var resultado: Dictionary = raiz.partida.datos["minijuegos"].get(id, {})
		var estado := "%d de 3 estrellas" % resultado["estrellas"] if resultado.has("estrellas") else ""
		lista.add_child(_fila(datos[1], datos[2], raiz.ir_a.bind(datos[0]), datos[3], estado))
