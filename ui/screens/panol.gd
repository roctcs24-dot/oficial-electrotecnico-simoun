extends Pantalla
## Pañol: consulta rápida para usar a bordo, sin puntos. Las fichas de todos los equipos, el
## glosario y, cuando estén listas, las tablas de llaves, válvulas, roscas y racores.

const PROXIMAMENTE := [
	["Llaves: milímetros y pulgadas", "Equivalencias, cuál sirve y cuál redondea la tuerca", "herramientas"],
	["Válvulas: abierta o cerrada", "Bola, mariposa, compuerta, globo y retención", "valvulas"],
	["Roscas, bridas y racores", "BSP, NPT, JIC, ORFS, DIN, DN y NPS", "herramientas"],
	["Mangueras hidráulicas", "Marcado SAE 100R y EN 853/856", "hidraulica"],
]


func construir() -> void:
	_cabecera("Pañol", "Consulta rápida a bordo")
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(10)
	desplazable.add_child(_ancho_lectura(lista))
	var color := Color("d9534f")
	lista.add_child(_rotulo("Consultar"))
	var ids := {}
	for s: Dictionary in raiz.contenido.todos():
		for id: String in s.get("modos", {}).get("aprender", {}).get("fichas", []):
			ids[id] = true
	var fichas := ids.size()
	lista.add_child(_fila("Fichas de equipos", "%d equipos: función, conexión, pruebas, fallas y mantenimiento" % fichas, raiz.ir_a.bind("fichas_equipos"), "ficha", "", true, {"color": color}))
	lista.add_child(_fila("Glosario español–inglés", "Los términos de las placas y los manuales", raiz.ir_a.bind("glosario"), "glosario", "", true, {"color": color}))
	lista.add_child(_rotulo("En preparación"))
	for p: Array in PROXIMAMENTE:
		lista.add_child(_fila(p[0], p[1], func() -> void: pass, p[2], "Pronto", false, {"color": color}))
