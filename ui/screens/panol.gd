extends Pantalla
## Pañol: consulta rápida para usar a bordo, sin puntos. Las fichas de todos los equipos, el
## glosario, el catálogo de válvulas, las herramientas con la tabla de llaves y los racores con
## las roscas, el DN y las mangueras, cada uno con su minijuego. Las filas van en placas con
## relieve (FilaPlaca).

const COLOR := Color("d9534f")
const COLOR_VALVULAS := Color("2e9e6a")
const PROXIMAMENTE := []

var filas: Array[FilaPlaca] = []


func construir() -> void:
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, "Pañol", "Consulta rápida a bordo", COLOR, "herramientas")
	add_child(cabecera)
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(12)
	desplazable.add_child(_ancho_lectura(lista))
	var ids := {}
	for s: Dictionary in raiz.contenido.todos():
		for id: String in s.get("modos", {}).get("aprender", {}).get("fichas", []):
			ids[id] = true
	var valvulas: Array = raiz.contenido.leer("catalogos/valvulas.json").get("valvulas", [])
	var juego: Dictionary = raiz.partida.datos["minijuegos"].get(JuegoValvulas.REGISTRO, {})
	var estrellas := int(juego.get("estrellas", 0))
	var consultar := _placa("Consultar")
	lista.add_child(consultar[0])
	_fila_placa(consultar[1], "Fichas de equipos", "%d equipos: función, conexión, pruebas, fallas y mantenimiento" % ids.size(), "ficha", COLOR, 1.0, raiz.ir_a.bind("fichas_equipos"))
	_fila_placa(consultar[1], "Glosario español–inglés", "Los términos de las placas y los manuales", "glosario", COLOR, 1.0, raiz.ir_a.bind("glosario"))
	_fila_placa(consultar[1], "Válvulas", "%d tipos: cómo se reconocen y cómo saber si están abiertas" % valvulas.size(), "valvulas", COLOR_VALVULAS, 1.0, raiz.ir_a.bind("catalogo", {"catalogo": "valvulas"}))
	_fila_placa(consultar[1], "¿Abierta o cerrada?", "Minijuego · %s" % ("%d de 3 estrellas" % estrellas if not juego.is_empty() else "sin jugar"), "valvulas", COLOR_VALVULAS, estrellas / 3.0, func() -> void: raiz.ir_a("abierta_cerrada", {}))
	var herramientas: Array = raiz.contenido.leer("catalogos/herramientas.json").get("herramientas", [])
	var juego_h: Dictionary = raiz.partida.datos["minijuegos"].get(JuegoHerramientas.REGISTRO, {})
	var pan := _placa("Herramientas")
	lista.add_child(pan[0])
	_fila_placa(pan[1], "Herramientas", "%d herramientas: cómo se llaman, para qué sirven y cómo se usan" % herramientas.size(), "herramientas", COLOR, 1.0, raiz.ir_a.bind("catalogo", {"catalogo": "herramientas"}))
	_fila_placa(pan[1], "Llaves: milímetros y pulgadas", "Qué llave métrica entra en una tuerca en pulgadas", "herramientas", COLOR, 1.0, func() -> void: raiz.ir_a("tabla_llaves", {}))
	_fila_placa(pan[1], "Identifique la herramienta", "Minijuego · %s" % ("%d de 3 estrellas" % int(juego_h.get("estrellas", 0)) if not juego_h.is_empty() else "sin jugar"), "herramientas", COLOR, int(juego_h.get("estrellas", 0)) / 3.0, func() -> void: raiz.ir_a("identifique_herramienta", {}))
	var racores: Array = raiz.contenido.leer("catalogos/racores.json").get("racores", [])
	var juego_r: Dictionary = raiz.partida.datos["minijuegos"].get(JuegoRacores.REGISTRO, {})
	var rac := _placa("Racores y tubería")
	lista.add_child(rac[0])
	_fila_placa(rac[1], "Racores", "%d racores: cómo se reconocen, dónde sellan y qué no mezclar" % racores.size(), "herramientas", COLOR, 1.0, raiz.ir_a.bind("catalogo", {"catalogo": "racores"}))
	_fila_placa(rac[1], "Roscas, DN y NPS", "BSP y NPT, y qué medida en pulgadas es cada DN", "herramientas", COLOR, 1.0, func() -> void: raiz.ir_a("roscas_tuberia", {}))
	_fila_placa(rac[1], "Mangueras hidráulicas", "Cómo se lee el marcado SAE y EN", "herramientas", COLOR, 1.0, func() -> void: raiz.ir_a("mangueras", {}))
	_fila_placa(rac[1], "Elija el racor", "Minijuego · %s" % ("%d de 3 estrellas" % int(juego_r.get("estrellas", 0)) if not juego_r.is_empty() else "sin jugar"), "herramientas", COLOR, int(juego_r.get("estrellas", 0)) / 3.0, func() -> void: raiz.ir_a("elija_racor", {}))
	if PROXIMAMENTE.is_empty():
		return
	var pronto := _placa("En preparación")
	lista.add_child(pronto[0])
	for p: Array in PROXIMAMENTE:
		var f := _fila_placa(pronto[1], p[0], p[1], p[2], COLOR, 0.0, Callable())
		f.activa = false


func _placa(rotulo: String) -> Array:
	var placa := PiezasLeccion.placa(8.0, 10.0)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 2)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo(rotulo))
	return [placa, columna]


func _fila_placa(columna: VBoxContainer, titulo: String, nota: String, icono: String, color: Color, avance: float, al_tocar: Callable) -> FilaPlaca:
	var f := FilaPlaca.new(titulo, nota)
	f.name = "Fila_%d" % filas.size()
	f.tipo = "medalla"
	f.icono = icono
	f.color = color
	f.avance = avance
	if al_tocar.is_valid():
		f.tocada.connect(al_tocar)
	columna.add_child(f)
	filas.append(f)
	return f
