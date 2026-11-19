extends Pantalla
## Evaluaciones disponibles en un sistema.

## Pantalla, título, detalle, icono y sistema cuyos símbolos se preguntan.
const NOMBRES := {
	"simbolos": ["minijuego_simbolos", "Identificación de símbolos", "Motores y mando, IEC 60617 y ANSI/IEEE 315", "simbolos", 3],
	"simbolos_generacion": ["minijuego_simbolos", "Símbolos de generación", "Generadores, cuadro y protecciones, IEC 60617 y ANSI/IEEE 315", "simbolos", 1],
	"simbolos_frio": ["minijuego_simbolos", "Símbolos de refrigeración", "Planta de frío y presostatos, IEC 60617 e ISA 5.1", "simbolos", 4],
	"simbolos_distribucion": ["minijuego_simbolos", "Símbolos de distribución", "Transformadores, protecciones y alumbrado, IEC 60617 y ANSI/IEEE 315", "simbolos", 2],
	"simbolos_cubierta": ["minijuego_simbolos", "Símbolos de cubierta", "Mando electrohidráulico, seguridades y alumbrado, IEC 60617 y ANSI/IEEE 315", "simbolos", 5],
	"simbolos_electronica": ["minijuego_simbolos", "Símbolos de electrónica", "Componentes, sensores y sondas, IEC 60617 y ANSI/IEEE 315", "simbolos", 6],
	"identifique_herramienta": ["identifique_herramienta", "Identifique la herramienta", "Llaves, destornilladores, alicates, medida y tubería; milímetros y pulgadas", "herramientas", 11],
	"elija_racor": ["elija_racor", "Elija el racor", "Racores JIC, ORFS, DIN, BSP y NPT; DN y NPS; fotos a bordo", "herramientas", 11],
	"seguir_lineas": ["seguir_lineas", "Siga la línea", "Seguir una línea, aislar un equipo y colores de tubería en la purificadora", "valvulas", 10],
	"simbolos_iso1219": ["simbolos_iso1219", "Símbolos ISO 1219", "Bombas, cilindros, motores, válvulas y acumuladores de hidráulica", "hidraulica", 9],
	"simbolos_neumatica": ["simbolos_iso1219", "Símbolos de neumática", "Aire, secador, FRL, válvulas 3/2, 5/2 y 5/3, cilindros y actuadores, ISO 1219", "hidraulica", 9],
	"abierta_cerrada": ["abierta_cerrada", "¿Abierta o cerrada?", "Bola, mariposa, macho, compuerta, globo, aguja, tres vías y actuadas", "valvulas", 10],
}


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, "Examen", s.get("nombre", ""), Tema.color_area(s), str(s.get("icono", "sistema_%d" % int(s.get("id", 0)))))
	add_child(cabecera)
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(12)
	desplazable.add_child(_ancho_lectura(lista))
	var examenes: Array = s["modos"]["examen"].get("examenes", [])
	if not examenes.is_empty():
		var placa := _placa("Exámenes")
		for id: String in examenes:
			placa.get_child(0).add_child(_fila_examen(id))
		lista.add_child(placa)
	var minijuegos: Array = s["modos"]["examen"].get("minijuegos", [])
	if not minijuegos.is_empty():
		var placa := _placa("Minijuegos")
		for id: String in minijuegos:
			var datos: Array = NOMBRES[id]
			var resultado: Dictionary = raiz.partida.datos["minijuegos"].get(id, {})
			var estado := "%d de 3 estrellas" % resultado["estrellas"] if resultado.has("estrellas") else "Sin jugar"
			# Un diccionario nuevo en cada visita: el minijuego guarda sus rondas en él.
			var abrir := func() -> void: raiz.ir_a(datos[0], {"sistema": datos[4], "registro": id})
			var f := _fila_placa(datos[1], "%s · %s" % [datos[2], estado], datos[3], resultado.get("estrellas", 0) / 3.0, "verde" if resultado.get("estrellas", 0) > 0 else "apagada")
			f.tocada.connect(abrir)
			placa.get_child(0).add_child(f)
		lista.add_child(placa)


func _placa(rotulo: String) -> PanelContainer:
	var placa := PiezasLeccion.placa(10.0, 10.0)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	var r := PiezasLeccion.rotulo(rotulo)
	columna.add_child(r)
	return placa


func _fila_placa(titulo: String, nota: String, icono: String, avance: float, luz: String) -> FilaPlaca:
	var s := raiz.contenido.sistema(args["id"])
	var f := FilaPlaca.new(titulo, nota)
	f.tipo = "medalla"
	f.icono = icono
	f.color = Tema.color_area(s)
	f.avance = avance
	f.lampara = luz
	return f


func _fila_examen(id: String) -> FilaPlaca:
	var e := raiz.contenido.leer("examenes/%s.json" % id)
	var r: Dictionary = raiz.partida.datos["examenes"].get(id, {})
	var estado := "Sin hacer"
	var luz := "apagada"
	var avance := 0.0
	if not r.is_empty():
		estado = "%d de 3 estrellas" % int(r["estrellas"]) if r["aprobado"] else "No aprobado"
		luz = "verde" if r["aprobado"] else "rojo"
		avance = int(r["estrellas"]) / 3.0
	var f := _fila_placa(e.get("titulo", id), "%s · %s" % [e.get("resumen", ""), estado], "examen", avance, luz)
	f.name = "Examen_%s" % id
	f.tocada.connect(raiz.ir_a.bind("prueba_examen", {"id": id}))
	return f
