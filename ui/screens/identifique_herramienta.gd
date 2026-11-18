extends PantallaPreguntas
## Minijuego «Identifique la herramienta»: diez rondas con una herramienta del catálogo dibujada y
## cuatro nombres, y tres de ellas de llaves (qué llave métrica entra en una tuerca en pulgadas).
## Las estrellas quedan en la partida (registro «identifique_herramienta»).

const RONDAS := 10
const COLOR := Color("d9534f")
const Examen := preload("res://ui/screens/prueba_examen.gd")


func _crear_items() -> Array:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	return JuegoHerramientas.crear_rondas(raiz.contenido.leer("catalogos/herramientas.json"), raiz.contenido.leer("tablas/llaves.json"), RONDAS, azar)


func _titulo() -> String:
	return "Identifique la herramienta"


func _subtitulo() -> String:
	return "Pañol · %d rondas" % args.get("items", []).size()


func _color() -> Color:
	return COLOR


func _icono() -> String:
	return "herramientas"


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	if not item.get("tipo", "") in ["herramienta", "llave"]:
		super(columna, item, indice)
		return
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	disposicion.add_theme_constant_override("separation", 12)
	disposicion.mouse_filter = Control.MOUSE_FILTER_PASS
	columna.add_child(disposicion)
	var visor := VisorFicha.new(12.0)
	visor.name = "VisorHerramienta"
	visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disposicion.add_child(visor)
	var dentro := VBoxContainer.new()
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(dentro)
	dentro.add_child(PiezasLeccion.rotulo("¿Qué herramienta es?" if item["tipo"] == "herramienta" else "Tuerca de %s" % item["medida"]))
	var d := DibujoHerramienta.new()
	d.name = "Dibujo"
	d.tipo = item["dibujo"]
	# En las de identificar no se graba la medida: no debe dar pistas.
	d.medida = "" if item["tipo"] == "herramienta" else "?"
	d.custom_minimum_size.y = 220.0 if raiz.vertical else 200.0
	dentro.add_child(d)
	var lado := _columna()
	disposicion.add_child(lado)
	_agregar_quiz(lado, item, respuesta, indice, "Herramientas" if item["tipo"] == "herramienta" else "Milímetros y pulgadas")


func _construir_final() -> void:
	var total: int = args["items"].size()
	var correctas := aciertos()
	var estrellas := JuegoSimbolos.estrellas(correctas, total)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_minijuego(JuegoHerramientas.REGISTRO, estrellas)
	_poner_cabecera("Resultado")
	var calif: Array = _placa_con("Calificación", "PlacaCalificacion")
	var cal = Examen.Calificacion.new()
	cal.porcentaje = 100.0 * correctas / maxf(total, 1)
	cal.minimo = 50.0
	cal.estrellas = estrellas
	cal.aprobado = estrellas > 0
	cal.correctas = correctas
	cal.total = total
	cal.puntos = int(args["ganados"])
	calif[1].add_child(cal)
	var izquierda: Array[Control] = [calif[0]]
	var derecha: Array[Control] = []
	var falladas: Array[String] = []
	for i in total:
		if not args["respuestas"].get(i, {}).get("acierto", false):
			var item: Dictionary = args["items"][i]
			var t := str(item["opciones"][int(item["correcta"])])
			if item["tipo"] == "llave":
				t = "Tuerca de %s: llave de %s" % [item["medida"], t]
			if not falladas.has(t):
				falladas.append(t)
	if not falladas.is_empty():
		var temas: Array = _placa_con("A repasar", "ARepasar")
		for t in falladas:
			temas[1].add_child(PiezasLeccion.fila_lampara("rojo", t, 14))
		derecha.append(temas[0])
	_disponer(izquierda, derecha)
	_botones_pie([["JUGAR OTRA VEZ", _repetir, "Repetir"], ["HERRAMIENTAS", raiz.ir_a.bind("catalogo", {"catalogo": "herramientas"}), "Catalogo"], ["VOLVER", raiz.volver, "Volver"]])


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()
