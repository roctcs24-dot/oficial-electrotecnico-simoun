extends Pantalla
## Reproductor de lecciones. Las respuestas viven en args para sobrevivir al giro del celular.

const INTERACTIVOS := ["quiz", "ordenar"]
const CARPETA_ANIMACIONES := "res://ui/animaciones/%s.gd"
const ALTO_IMAGEN := 300.0

var _leccion := {}
var _siguiente: Button
var _vistos := {}


func construir() -> void:
	_leccion = raiz.contenido.leccion(args["id"])
	if _leccion.is_empty():
		_cabecera("Lección no disponible")
		for error in raiz.contenido.errores:
			add_child(_aviso(error))
		return
	if not args.has("pagina"):
		args["pagina"] = 0
		args["respuestas"] = {}
	var paginas: Array = _leccion["paginas"]
	var pagina: int = args["pagina"]
	if pagina >= paginas.size():
		_construir_final()
		return
	_marcar_terminos_previos(pagina)
	var datos: Dictionary = paginas[pagina]
	_cabecera(_leccion["titulo"], "Página %d de %d · %s" % [pagina + 1, paginas.size(), datos["titulo"]])
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(14)
	desplazable.add_child(columna)
	var bloques: Array = datos["bloques"]
	for i in bloques.size():
		columna.add_child(_crear_bloque(bloques[i], "%d_%d" % [pagina, i]))
	_crear_navegacion(pagina)


## Para que el inglés salga solo en la primera aparición de toda la lección.
func _marcar_terminos_previos(pagina: int) -> void:
	var glosario := raiz.contenido.glosario()
	for p in pagina:
		for b: Dictionary in _leccion["paginas"][p]["bloques"]:
			if b["tipo"] == "texto":
				TextoTecnico.expandir(b["texto"], glosario, _vistos)


func _crear_bloque(bloque: Dictionary, clave: String) -> Control:
	match bloque["tipo"]:
		"texto":
			return _texto_rico(TextoTecnico.expandir(bloque["texto"], raiz.contenido.glosario(), _vistos))
		"animacion":
			return _crear_animacion(bloque)
		"imagen":
			return _crear_imagen(bloque)
		"quiz":
			var quiz := BloqueQuiz.new()
			var previa: Dictionary = args["respuestas"].get(clave, {})
			quiz.iniciar(bloque, previa.get("indice", -1))
			if previa.is_empty():
				quiz.respondido.connect(_al_responder_quiz.bind(clave, bloque))
			return quiz
		"ordenar":
			var ordenar := BloqueOrdenar.new()
			var resuelto: bool = args["respuestas"].has(clave)
			ordenar.iniciar(bloque, resuelto)
			if not resuelto:
				ordenar.respondido.connect(_al_responder_ordenar.bind(clave, bloque))
			return ordenar
	return _aviso("Bloque desconocido: %s" % bloque["tipo"])


func _crear_animacion(bloque: Dictionary) -> Control:
	var columna := _columna(4)
	var guion: GDScript = load(CARPETA_ANIMACIONES % bloque["id"])
	var animacion: Animacion = guion.new()
	columna.add_child(animacion)
	animacion.iniciar(bloque.get("params", {}), raiz.contenido)
	if bloque.has("pie"):
		columna.add_child(_etiqueta(bloque["pie"], "Nota"))
	return columna


func _crear_imagen(bloque: Dictionary) -> Control:
	var columna := _columna(4)
	var tarjeta := _tarjeta_base("Papel")
	columna.add_child(tarjeta)
	var imagen := VistaSvg.new()
	imagen.cargar(bloque)
	imagen.custom_minimum_size.y = ALTO_IMAGEN
	tarjeta.add_child(imagen)
	if bloque.has("pie"):
		columna.add_child(_etiqueta(bloque["pie"], "Nota"))
	return columna


func _al_responder_quiz(acierto: bool, indice: int, clave: String, bloque: Dictionary) -> void:
	args["respuestas"][clave] = {"acierto": acierto, "indice": indice}
	if not acierto:
		raiz.partida.registrar_error(bloque["tema"])
	_actualizar_siguiente()


func _al_responder_ordenar(errores: int, clave: String, bloque: Dictionary) -> void:
	args["respuestas"][clave] = {"acierto": errores == 0}
	if errores > 0:
		raiz.partida.registrar_error(bloque["tema"])
	_actualizar_siguiente()


func _crear_navegacion(pagina: int) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	add_child(fila)
	var anterior := _boton("‹ Anterior", ir_a_pagina.bind(pagina - 1))
	anterior.autowrap_mode = TextServer.AUTOWRAP_OFF
	anterior.disabled = pagina == 0
	anterior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(anterior)
	_siguiente = _boton("Siguiente ›", ir_a_pagina.bind(pagina + 1))
	_siguiente.autowrap_mode = TextServer.AUTOWRAP_OFF
	_siguiente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_siguiente)
	_actualizar_siguiente()


## No se avanza sin contestar las preguntas de la página.
func pagina_resuelta() -> bool:
	var pagina: int = args["pagina"]
	var bloques: Array = _leccion["paginas"][pagina]["bloques"]
	for i in bloques.size():
		if bloques[i]["tipo"] in INTERACTIVOS and not args["respuestas"].has("%d_%d" % [pagina, i]):
			return false
	return true


func _actualizar_siguiente() -> void:
	_siguiente.disabled = not pagina_resuelta()


func ir_a_pagina(pagina: int) -> void:
	args["pagina"] = pagina
	raiz.reconstruir()


func _total_preguntas() -> int:
	var total := 0
	for p: Dictionary in _leccion["paginas"]:
		for b: Dictionary in p["bloques"]:
			if b["tipo"] in INTERACTIVOS:
				total += 1
	return total


func _construir_final() -> void:
	var aciertos := 0
	for r: Dictionary in args["respuestas"].values():
		if r["acierto"]:
			aciertos += 1
	var total := _total_preguntas()
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.completar_leccion(args["id"], aciertos, total)
	_cabecera(_leccion["titulo"], "Lección completada")
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(12)
	desplazable.add_child(columna)
	columna.add_child(_etiqueta("Respuestas correctas al primer intento: %d de %d" % [aciertos, total], "Subtitulo"))
	var ganados: int = args["ganados"]
	columna.add_child(_etiqueta("Puntos obtenidos: %d." % ganados if ganados > 0 else "Los puntos de esta lección ya estaban registrados."))
	if aciertos < total:
		columna.add_child(_etiqueta("Los temas con error quedan registrados para su repaso.", "Nota"))
	columna.add_child(_etiqueta("Para saber más", "Subtitulo"))
	var referencias := PackedStringArray()
	for r: String in _leccion.get("para_saber_mas", []):
		referencias.append("• %s" % r)
	columna.add_child(_texto_rico("\n".join(referencias)))
	var proxima := _proxima_leccion()
	if not proxima.is_empty():
		columna.add_child(_boton("Siguiente lección: %s" % raiz.contenido.leccion(proxima)["titulo"], _abrir_proxima.bind(proxima)))
	columna.add_child(_boton("Volver a la lista", raiz.volver))


func _proxima_leccion() -> String:
	var lista: Array = raiz.contenido.sistema(args.get("sistema", -1)).get("modos", {}).get("aprender", {}).get("lecciones", [])
	var i := lista.find(args["id"])
	return "" if i < 0 or i + 1 >= lista.size() else lista[i + 1]


func _abrir_proxima(id: String) -> void:
	var sistema: int = args["sistema"]
	raiz.volver()
	raiz.ir_a("leccion", {"id": id, "sistema": sistema})
