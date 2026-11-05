extends Pantalla
## Evaluaciones disponibles en un sistema.

const NOMBRES := {
	"simbolos": ["minijuego_simbolos", "Identificación de símbolos", "IEC 60617 y ANSI/IEEE 315"],
}


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera("Examen", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(8)
	desplazable.add_child(lista)
	for id: String in s["modos"]["examen"].get("minijuegos", []):
		var datos: Array = NOMBRES[id]
		var resultado: Dictionary = raiz.partida.datos["minijuegos"].get(id, {})
		var estado := "  ·  mejor resultado: %d de 3 estrellas" % resultado["estrellas"] if resultado.has("estrellas") else ""
		var b := _boton("%s%s\n%s" % [datos[1], estado, datos[2]], raiz.ir_a.bind(datos[0]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		lista.add_child(b)
