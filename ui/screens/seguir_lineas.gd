extends PantallaPreguntas
## Minijuego «Siga la línea»: los ejercicios de un esquema de data/lineas (args «esquema», por
## defecto la purificadora), uno por página: seguir una línea con el dedo, aislar un equipo
## tocando sus válvulas o decir qué lleva un tramo por su color. Lo hecho a medias vive en
## args «parcial» para sobrevivir al giro. Registro «seguir_lineas».

const COLOR := Color("2e9e6a")
const Examen := preload("res://ui/screens/prueba_examen.gd")

var bloque: BloqueLinea


func _esquema() -> Dictionary:
	return JuegoLineas.leer(raiz.contenido, str(args.get("esquema", "purificadora")))


func _crear_items() -> Array:
	return JuegoLineas.crear_items(_esquema())


func _titulo() -> String:
	return "Siga la línea"


func _subtitulo() -> String:
	return "%s · %d ejercicios" % [_esquema().get("titulo", "Líneas"), args.get("items", []).size()]


func _color() -> Color:
	return COLOR


func _icono() -> String:
	return "valvulas"


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	if item.get("tipo", "") != "linea":
		super(columna, item, indice)
		return
	if not args.has("parcial"):
		args["parcial"] = {}
	if not args["parcial"].has(indice):
		args["parcial"][indice] = {}
	var esquema := _esquema()
	bloque = BloqueLinea.new()
	bloque.name = "BloqueLinea"
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	bloque.iniciar(esquema, raiz.contenido.leer("tuberias.json").get("colores", {}), JuegoLineas.ejercicio(esquema, item["ejercicio"]), args["parcial"][indice], respuesta, raiz.vertical, 300.0 if raiz.vertical else 196.0)
	if respuesta.is_empty():
		bloque.respondido.connect(func(ok: bool) -> void: _resolver(indice, ok, -1))
	columna.add_child(bloque)


func _construir_final() -> void:
	var total: int = args["items"].size()
	var correctas := aciertos()
	var estrellas := JuegoLineas.estrellas(correctas, total)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_minijuego(JuegoLineas.REGISTRO, estrellas)
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
	var esquema := _esquema()
	for i in total:
		if not args["respuestas"].get(i, {}).get("acierto", false):
			falladas.append(str(JuegoLineas.ejercicio(esquema, args["items"][i]["ejercicio"]).get("pregunta", "")))
	if not falladas.is_empty():
		var temas: Array = _placa_con("A repasar", "ARepasar")
		for t in falladas:
			temas[1].add_child(PiezasLeccion.fila_lampara("rojo", t, 13))
		derecha.append(temas[0])
	var nota: Array = _placa_con("El esquema", "NotaEsquema")
	nota[1].add_child(PiezasLeccion.etiqueta(str(esquema.get("nota", "")), 13, Tema.TEXTO_SUAVE))
	derecha.append(nota[0])
	_disponer(izquierda, derecha)
	_botones_pie([["JUGAR OTRA VEZ", _repetir, "Repetir"], ["VOLVER", raiz.volver, "Volver"]])


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados", "parcial"]:
		args.erase(clave)
	raiz.reconstruir()
