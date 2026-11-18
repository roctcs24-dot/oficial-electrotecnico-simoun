extends PantallaPreguntas
## Minijuego «¿Abierta o cerrada?»: diez válvulas del catálogo dibujadas en un estado al azar,
## con la chapa de su servicio. Se contesta mirando la maneta, el vástago o el indicador, como a
## bordo. Algunas rondas son fotos tomadas a bordo, con un halo sobre la válvula que se pregunta.
## Las estrellas quedan en la partida (registro «abierta_cerrada»).

const RONDAS := 10
const COLOR := Color("2e9e6a")
const Examen := preload("res://ui/screens/prueba_examen.gd")


func _catalogo() -> Dictionary:
	return raiz.contenido.leer("catalogos/valvulas.json")


func _crear_items() -> Array:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	return JuegoValvulas.crear_rondas(_catalogo(), RONDAS, azar, FotosPiezas.con_estado(_fotos()))


func _fotos() -> Dictionary:
	return raiz.contenido.leer(FotosPiezas.ARCHIVO)


func _foto(id: String) -> Dictionary:
	for f: Dictionary in _fotos().get("fotos", []):
		if f["id"] == id:
			return f
	return {}


func _titulo() -> String:
	return "¿Abierta o cerrada?"


func _subtitulo() -> String:
	return "Válvulas · %d rondas" % args.get("items", []).size()


func _color() -> Color:
	return COLOR


func _icono() -> String:
	return "valvulas"


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	if item.get("tipo", "") != "valvula":
		super(columna, item, indice)
		return
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	disposicion.add_theme_constant_override("separation", 12)
	disposicion.mouse_filter = Control.MOUSE_FILTER_PASS
	columna.add_child(disposicion)
	var visor := VisorFicha.new(12.0)
	visor.name = "VisorValvula"
	visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disposicion.add_child(visor)
	var dentro := VBoxContainer.new()
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(dentro)
	var foto := _foto(str(item.get("foto", "")))
	if not foto.is_empty() and FotosPiezas.existe(foto):
		dentro.add_child(PiezasLeccion.rotulo("Mire la maneta marcada · %s" % item.get("servicio", "")))
		var f := FotoPieza.desde(foto, str(_fotos().get("credito", "")))
		f.rotulo = ""
		f.custom_minimum_size.y = 330.0 if raiz.vertical else 230.0
		f.size_flags_vertical = Control.SIZE_EXPAND_FILL
		dentro.add_child(f)
	else:
		dentro.add_child(PiezasLeccion.rotulo("Mire la maneta, el vástago o el indicador"))
		var d := DibujoValvula.new()
		d.name = "Dibujo"
		d.tipo = item["dibujo"]
		d.apertura = float(item["apertura"])
		d.via = str(item.get("via", "b"))
		d.rotulo = str(item.get("servicio", ""))
		d.custom_minimum_size.y = 250.0 if raiz.vertical else 230.0
		dentro.add_child(d)
	var lado := _columna()
	lado.size_flags_stretch_ratio = 1.0
	disposicion.add_child(lado)
	var nombre := ""
	for v: Dictionary in _catalogo().get("valvulas", []):
		if v["id"] == item["id"]:
			nombre = str(v["nombre"])
	_agregar_quiz(lado, item, respuesta, indice, nombre)


func _construir_final() -> void:
	var total: int = args["items"].size()
	var correctas := aciertos()
	var estrellas := JuegoValvulas.estrellas(correctas, total)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_minijuego(JuegoValvulas.REGISTRO, estrellas)
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
			for v: Dictionary in _catalogo().get("valvulas", []):
				if v["id"] == args["items"][i]["id"] and not falladas.has(str(v["nombre"])):
					falladas.append(str(v["nombre"]))
	if not falladas.is_empty():
		var temas: Array = _placa_con("Válvulas a repasar", "ARepasar")
		for t in falladas:
			temas[1].add_child(PiezasLeccion.fila_lampara("rojo", t, 14))
		derecha.append(temas[0])
	_disponer(izquierda, derecha)
	_botones_pie([["JUGAR OTRA VEZ", _repetir, "Repetir"], ["CATÁLOGO", raiz.ir_a.bind("catalogo", {"catalogo": "valvulas"}), "Catalogo"], ["VOLVER", raiz.volver, "Volver"]])


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()
