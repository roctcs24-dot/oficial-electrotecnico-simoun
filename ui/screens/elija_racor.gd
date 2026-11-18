extends PantallaPreguntas
## Minijuego «Elija el racor»: diez rondas. La mayoría enseña un racor dibujado sin rótulos con
## su descripción; dos son de DN y NPS, con el tubo dibujado y su diámetro exterior; y hasta dos
## son fotos tomadas a bordo con un halo sobre la pieza. Registro «elija_racor».

const RONDAS := 10
const COLOR := Color("d9534f")
const Examen := preload("res://ui/screens/prueba_examen.gd")


func _crear_items() -> Array:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	return JuegoRacores.crear_rondas(_catalogo(), raiz.contenido.leer("tablas/roscas.json"), RONDAS, azar, FotosPiezas.con_pregunta(_fotos()))


func _catalogo() -> Dictionary:
	return raiz.contenido.leer("catalogos/racores.json")


func _fotos() -> Dictionary:
	return raiz.contenido.leer(FotosPiezas.ARCHIVO)


func _titulo() -> String:
	return "Elija el racor"


func _subtitulo() -> String:
	return "Pañol · %d rondas" % args.get("items", []).size()


func _color() -> Color:
	return COLOR


func _icono() -> String:
	return "herramientas"


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	if not item.get("tipo", "") in ["racor", "dn", "foto"]:
		super(columna, item, indice)
		return
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	disposicion.add_theme_constant_override("separation", 12)
	disposicion.mouse_filter = Control.MOUSE_FILTER_PASS
	columna.add_child(disposicion)
	var visor := VisorFicha.new(12.0)
	visor.name = "VisorRacor"
	visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disposicion.add_child(visor)
	var dentro := VBoxContainer.new()
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(dentro)
	var alto := 250.0 if raiz.vertical else 210.0
	match str(item["tipo"]):
		"racor":
			dentro.add_child(PiezasLeccion.rotulo("Mire el asiento y la rosca"))
			var d := DibujoRacor.new()
			d.name = "Dibujo"
			d.tipo = item["dibujo"]
			d.rotulos = false
			d.custom_minimum_size.y = alto
			dentro.add_child(d)
		"dn":
			dentro.add_child(PiezasLeccion.rotulo("Tubo de acero · DN y NPS"))
			var tubo := TuboDN.new()
			tubo.name = "Tubo"
			tubo.exterior = float(item["exterior"])
			tubo.cota = "" if item.get("por_exterior", false) else "DN%d" % int(item["dn"])
			tubo.custom_minimum_size.y = alto
			dentro.add_child(tubo)
		"foto":
			var foto: Dictionary = {}
			for f: Dictionary in _fotos().get("fotos", []):
				if f["id"] == item["foto"]:
					foto = f
			dentro.add_child(PiezasLeccion.rotulo("Mire la pieza marcada · %s" % foto.get("lugar", "")))
			var fp := FotoPieza.desde(foto, str(_fotos().get("credito", "")))
			fp.rotulo = ""
			fp.partes = []
			fp.custom_minimum_size.y = alto + (60.0 if raiz.vertical else 0.0)
			fp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			dentro.add_child(fp)
	var lado := _columna()
	disposicion.add_child(lado)
	var rotulo := {"racor": "Racores", "dn": "Medidas de tubería", "foto": "Foto a bordo"}
	_agregar_quiz(lado, item, respuesta, indice, rotulo[item["tipo"]])


func _construir_final() -> void:
	var total: int = args["items"].size()
	var correctas := aciertos()
	var estrellas := JuegoSimbolos.estrellas(correctas, total)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_minijuego(JuegoRacores.REGISTRO, estrellas)
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
			if item["tipo"] == "dn":
				t = "DN%d = %s\" NPS" % [item["dn"], item["nps"]]
			if not falladas.has(t):
				falladas.append(t)
	if not falladas.is_empty():
		var temas: Array = _placa_con("A repasar", "ARepasar")
		for t in falladas:
			temas[1].add_child(PiezasLeccion.fila_lampara("rojo", t, 14))
		derecha.append(temas[0])
	_disponer(izquierda, derecha)
	_botones_pie([["JUGAR OTRA VEZ", _repetir, "Repetir"], ["RACORES", raiz.ir_a.bind("catalogo", {"catalogo": "racores"}), "Catalogo"], ["VOLVER", raiz.volver, "Volver"]])


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()
