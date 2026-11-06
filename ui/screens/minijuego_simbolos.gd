extends Pantalla
## Identificación de símbolos. El estado vive en args para sobrevivir al giro del celular.

const RONDAS := 10
const ALTO_SIMBOLO := 190.0
const TITULOS := {"iec": "IEC 60617", "ansi": "ANSI/IEEE 315 (NEMA)"}
const OTRA_NORMA := {"iec": "ansi", "ansi": "iec"}


func construir() -> void:
	if not args.has("rondas"):
		_empezar()
	var rondas: Array = args["rondas"]
	var indice: int = args["indice"]
	if indice >= rondas.size():
		_construir_final()
		return
	var ronda: Dictionary = rondas[indice]
	_cabecera("Identificación de símbolos", "Símbolo %d de %d" % [indice + 1, rondas.size()])
	add_child(_barra_avance(float(indice + 1) / rondas.size()))
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(_ancho_lectura(columna))
	var datos := raiz.contenido.simbolo(ronda["id"])
	var respondida: bool = args["respuestas"].has(indice)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	columna.add_child(fila)
	fila.add_child(_tarjeta(datos, ronda["norma"]))
	if respondida and not raiz.vertical:
		fila.add_child(_tarjeta(datos, OTRA_NORMA[ronda["norma"]]))
	columna.add_child(_crear_pregunta(ronda, datos, indice))
	if respondida and raiz.vertical:
		columna.add_child(_tarjeta(datos, OTRA_NORMA[ronda["norma"]]))
	if respondida:
		# Fuera de la lista: siempre a la vista, sin tener que desplazarse hasta él.
		var ultima: bool = indice + 1 >= rondas.size()
		add_child(_boton("Ver resultado" if ultima else "Siguiente símbolo", _avanzar))


func _empezar() -> void:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	args["rondas"] = JuegoSimbolos.crear_rondas(raiz.contenido.simbolos(args.get("sistema", -1)), RONDAS, azar)
	args["indice"] = 0
	args["respuestas"] = {}


func _tarjeta(datos: Dictionary, norma: String) -> Control:
	var tarjeta := _tarjeta_base("Papel")
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var columna := _columna(2)
	tarjeta.add_child(columna)
	var titulo := _etiqueta(TITULOS[norma], "Nota")
	titulo.add_theme_color_override("font_color", Tema.TINTA)
	columna.add_child(titulo)
	var dibujo := VistaSvg.new()
	dibujo.color_etiquetas = Tema.TINTA
	dibujo.cargar(datos[norma])
	dibujo.custom_minimum_size.y = ALTO_SIMBOLO
	columna.add_child(dibujo)
	return tarjeta


func _crear_pregunta(ronda: Dictionary, datos: Dictionary, indice: int) -> Control:
	var nombres := []
	for id: String in ronda["opciones"]:
		nombres.append(raiz.contenido.simbolo(id)["nombre"])
	var otra: String = TITULOS[OTRA_NORMA[ronda["norma"]]]
	var quiz := BloqueQuiz.new()
	quiz.iniciar({
		"pregunta": "¿Qué representa este símbolo?",
		"opciones": nombres,
		"correcta": ronda["correcta"],
		"explicacion": "%s. Compárelo con su versión en %s." % [datos["nombre"], otra],
	}, args["respuestas"].get(indice, -1))
	if not args["respuestas"].has(indice):
		quiz.respondido.connect(_al_responder.bind(indice, ronda))
	return quiz


func _al_responder(acierto: bool, elegida: int, indice: int, ronda: Dictionary) -> void:
	args["respuestas"][indice] = elegida
	if not acierto:
		raiz.partida.registrar_error("simbolo_%s" % ronda["id"])
	raiz.reconstruir.call_deferred()


func _avanzar() -> void:
	args["indice"] += 1
	raiz.reconstruir()


func _construir_final() -> void:
	var rondas: Array = args["rondas"]
	var aciertos := 0
	var falladas := PackedStringArray()
	for i in rondas.size():
		if args["respuestas"].get(i, -1) == int(rondas[i]["correcta"]):
			aciertos += 1
		else:
			var nombre: String = raiz.contenido.simbolo(rondas[i]["id"])["nombre"]
			if not falladas.has("• %s" % nombre):
				falladas.append("• %s" % nombre)
	var estrellas := JuegoSimbolos.estrellas(aciertos, rondas.size())
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_minijuego(args.get("registro", "simbolos"), estrellas)
	_cabecera("Identificación de símbolos", "Resultado")
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(columna)
	columna.add_child(_etiqueta("Respuestas correctas: %d de %d" % [aciertos, rondas.size()], "Subtitulo"))
	columna.add_child(_etiqueta("Calificación: %d de 3 estrellas" % estrellas))
	var ganados: int = args["ganados"]
	if ganados > 0:
		columna.add_child(_etiqueta("Puntos obtenidos: %d." % ganados))
	if not falladas.is_empty():
		columna.add_child(_rotulo("Símbolos a repasar"))
		columna.add_child(_texto_rico("\n".join(falladas)))
	columna.add_child(_etiqueta(raiz.contenido.leer("simbolos.json").get("nota", ""), "Nota"))
	columna.add_child(_boton("Repetir con otros símbolos", _repetir))
	columna.add_child(_boton("Volver", raiz.volver))


func _repetir() -> void:
	for clave in ["rondas", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()
