extends Pantalla
## Evaluaciones disponibles en un sistema.

## Pantalla, título, detalle, icono y sistema cuyos símbolos se preguntan.
const NOMBRES := {
	"simbolos": ["minijuego_simbolos", "Identificación de símbolos", "Motores y mando, IEC 60617 y ANSI/IEEE 315", "simbolos", 3],
	"simbolos_generacion": ["minijuego_simbolos", "Símbolos de generación", "Generadores, cuadro y protecciones, IEC 60617 y ANSI/IEEE 315", "simbolos", 1],
	"simbolos_frio": ["minijuego_simbolos", "Símbolos de refrigeración", "Planta de frío y presostatos, IEC 60617 e ISA 5.1", "simbolos", 4],
	"simbolos_distribucion": ["minijuego_simbolos", "Símbolos de distribución", "Transformadores, protecciones y alumbrado, IEC 60617 y ANSI/IEEE 315", "simbolos", 2],
	"simbolos_electronica": ["minijuego_simbolos", "Símbolos de electrónica", "Componentes, sensores y sondas, IEC 60617 y ANSI/IEEE 315", "simbolos", 6],
}


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera("Examen", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(6)
	desplazable.add_child(_ancho_lectura(lista))
	for id: String in s["modos"]["examen"].get("examenes", []):
		lista.add_child(_fila_examen(id))
	for id: String in s["modos"]["examen"].get("minijuegos", []):
		var datos: Array = NOMBRES[id]
		var resultado: Dictionary = raiz.partida.datos["minijuegos"].get(id, {})
		var estado := "%d de 3 estrellas" % resultado["estrellas"] if resultado.has("estrellas") else ""
		# Un diccionario nuevo en cada visita: el minijuego guarda sus rondas en él.
		var abrir := func() -> void: raiz.ir_a(datos[0], {"sistema": datos[4], "registro": id})
		lista.add_child(_fila(datos[1], datos[2], abrir, datos[3], estado))


func _fila_examen(id: String) -> FilaMenu:
	var e := raiz.contenido.leer("examenes/%s.json" % id)
	var r: Dictionary = raiz.partida.datos["examenes"].get(id, {})
	var estado := ""
	if not r.is_empty():
		estado = "%d de 3 estrellas" % int(r["estrellas"]) if r["aprobado"] else "No aprobado"
	return _fila(e.get("titulo", id), e.get("resumen", ""), raiz.ir_a.bind("prueba_examen", {"id": id}), "examen", estado)
