extends Pantalla
## Reproductor de lecciones, con el relieve de la Escuela: cabecera con la medalla del área y una
## moneda por página, el texto en placas con las fórmulas en un visor, las animaciones dentro de
## un visor hundido y las preguntas con teclas. En apaisado, el texto va a la izquierda y lo que
## se toca (animación, imagen, pregunta o práctica) a la derecha.
## Las respuestas viven en args para sobrevivir al giro del celular.

const INTERACTIVOS := ["quiz", "ordenar"]
const CARPETA_ANIMACIONES := "res://ui/animaciones/%s.gd"
const ALTO_IMAGEN := 300.0
## Ancho a partir del cual la página se reparte en dos columnas.
const ANCHO_DOS_COLUMNAS := 720.0
const ANCHO_MAXIMO := 1240.0

var _leccion := {}
var _area := {}
var _siguiente: BotonAri
var _anterior: BotonAri
var _vistos := {}


func construir() -> void:
	_leccion = raiz.contenido.leccion(args["id"])
	if _leccion.is_empty():
		_cabecera("Lección no disponible")
		for error in raiz.contenido.errores:
			add_child(_aviso(error))
		return
	_area = _buscar_area()
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
	_poner_cabecera(_subtitulo(), pagina)
	var desplazable := _desplazable()
	add_child(desplazable)
	var bloques: Array = datos["bloques"]
	var lectura: Array[Control] = []
	var manejo: Array[Control] = []
	var primero_texto := true
	for i in bloques.size():
		var b: Dictionary = bloques[i]
		var c := _crear_bloque(b, "%d_%d" % [pagina, i], str(datos["titulo"]) if primero_texto and b["tipo"] == "texto" else "")
		if b["tipo"] == "texto":
			primero_texto = false
			lectura.append(c)
		else:
			manejo.append(c)
	if dos_columnas() and not lectura.is_empty() and not manejo.is_empty():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		fila.mouse_filter = Control.MOUSE_FILTER_PASS
		desplazable.add_child(_limitar(fila))
		for lado: Array in [lectura, manejo]:
			var col := _columna(12)
			col.name = "Lectura" if lado == lectura else "Manejo"
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for c: Control in lado:
				col.add_child(c)
			fila.add_child(col)
	else:
		var columna := _columna(12)
		desplazable.add_child(_ancho_lectura(columna))
		for i in bloques.size():
			columna.add_child(lectura.pop_front() if bloques[i]["tipo"] == "texto" else manejo.pop_front())
	_crear_navegacion(pagina)


func dos_columnas() -> bool:
	return not raiz.vertical and raiz.ancho_contenido() >= ANCHO_DOS_COLUMNAS


## Limita el ancho de las dos columnas en pantallas muy anchas.
func _limitar(contenido: Control) -> Control:
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.mouse_filter = Control.MOUSE_FILTER_PASS
	var sobrante := int(maxf(raiz.ancho_contenido() - ANCHO_MAXIMO, 0.0) / 2.0)
	margen.add_theme_constant_override("margin_left", sobrante)
	margen.add_theme_constant_override("margin_right", sobrante)
	margen.add_child(contenido)
	return margen


## Sistema del buque o módulo de la Escuela de la lección, para su color, su icono y su lista.
func _buscar_area() -> Dictionary:
	var s := raiz.contenido.sistema(int(args.get("sistema", -1)))
	if not s.is_empty():
		return s
	for a: Dictionary in raiz.contenido.todos():
		if a.get("modos", {}).get("aprender", {}).get("lecciones", []).has(args["id"]):
			return a
	return {}


func _lista_area() -> Array:
	return _area.get("modos", {}).get("aprender", {}).get("lecciones", [])


func _subtitulo() -> String:
	var partes := PackedStringArray()
	var lista := _lista_area()
	var i := lista.find(args["id"])
	if not raiz.vertical:
		if _area.has("nombre"):
			partes.append(str(_area["nombre"]))
		if i >= 0:
			partes.append("lección %d de %d" % [i + 1, lista.size()])
	elif i >= 0:
		partes.append("Lección %d de %d" % [i + 1, lista.size()])
	if _leccion.has("minutos"):
		partes.append("%d min" % int(_leccion["minutos"]))
	return " · ".join(partes)


func _poner_cabecera(sub: String, pagina: int) -> void:
	var color := Tema.color_area(_area) if not _area.is_empty() else Tema.ACENTO
	var icono := str(_area.get("icono", "sistema_%d" % int(_area["id"]))) if _area.has("id") else "leccion"
	var lista := _lista_area()
	var hechas := 0
	for id: String in lista:
		if raiz.partida.leccion_completada(id):
			hechas += 1
	var cabecera := CabeceraFicha.new()
	var paginas: Array = _leccion["paginas"]
	cabecera.iniciar(raiz, _leccion["titulo"], sub, color, icono, float(hechas) / maxf(lista.size(), 1), PiezasLeccion.MonedasPaginas.new(paginas.size(), pagina))
	add_child(cabecera)


## Para que el inglés salga solo en la primera aparición de toda la lección.
func _marcar_terminos_previos(pagina: int) -> void:
	var glosario := raiz.contenido.glosario()
	for p in pagina:
		for b: Dictionary in _leccion["paginas"][p]["bloques"]:
			if b["tipo"] == "texto":
				TextoTecnico.expandir(b["texto"], glosario, _vistos)


func _crear_bloque(bloque: Dictionary, clave: String, rotulo := "") -> Control:
	match bloque["tipo"]:
		"texto":
			return _crear_texto(TextoTecnico.expandir(bloque["texto"], raiz.contenido.glosario(), _vistos), rotulo)
		"animacion":
			return _crear_animacion(bloque)
		"imagen":
			return _crear_imagen(bloque)
		"foto":
			return _crear_foto(bloque)
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
			ordenar.iniciar(bloque, resuelto, args["respuestas"].get(clave, {}).get("acierto", true))
			if not resuelto:
				ordenar.respondido.connect(_al_responder_ordenar.bind(clave, bloque))
			return ordenar
		"taller":
			return _crear_practica(bloque)
	return _aviso("Bloque desconocido: %s" % bloque["tipo"])


## Texto en una placa. Los párrafos que son solo una fórmula centrada en negrita
## («[center][b]V = I × R[/b][/center]») salen en un visor ámbar.
func _crear_texto(bbcode: String, rotulo: String) -> Control:
	var placa := PiezasLeccion.placa(16.0, 12.0)
	placa.name = "PlacaTexto"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	if not rotulo.is_empty():
		columna.add_child(PiezasLeccion.rotulo(rotulo))
	var pendiente := PackedStringArray()
	for parrafo in partir_formulas(bbcode):
		if parrafo.begins_with("=") and parrafo.length() > 1:
			if not pendiente.is_empty():
				columna.add_child(PiezasLeccion.texto_rico("\n\n".join(pendiente)))
				pendiente.clear()
			columna.add_child(PiezasLeccion.formula(parrafo.substr(1)))
		else:
			pendiente.append(parrafo)
	if not pendiente.is_empty():
		columna.add_child(PiezasLeccion.texto_rico("\n\n".join(pendiente)))
	return placa


## Párrafos del texto; las fórmulas destacadas vuelven con un «=» delante y sin sus etiquetas.
static func partir_formulas(bbcode: String) -> PackedStringArray:
	var r := PackedStringArray()
	var re := RegEx.create_from_string("^\\s*\\[center\\]\\[b\\](.+?)\\[/b\\]\\[/center\\]\\s*$")
	for parrafo in bbcode.split("\n\n"):
		var m := re.search(parrafo)
		if m != null and not m.get_string(1).contains("\n"):
			r.append("=" + m.get_string(1))
		else:
			r.append(parrafo)
	return r


## Práctica en el Taller: un texto y el botón que abre la plantilla de data/circuitos.
func _crear_practica(bloque: Dictionary) -> Control:
	var placa := PiezasLeccion.placa(16.0, 12.0)
	placa.name = "Practica"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Práctica en el Taller"))
	columna.add_child(PiezasLeccion.texto_rico(TextoTecnico.expandir(bloque.get("texto", ""), raiz.contenido.glosario(), _vistos)))
	var b := BotonAri.new(str(bloque.get("boton", "Practicarlo en el Taller")), raiz.ir_a.bind("taller", {"plantilla": bloque["plantilla"]}), "ambar", "taller")
	b.custom_minimum_size.y = 50.0
	columna.add_child(b)
	return placa


func _crear_animacion(bloque: Dictionary) -> Control:
	var columna := _columna(6)
	var visor := VisorFicha.new(14.0)
	visor.name = "VisorAnimacion"
	columna.add_child(visor)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 6)
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(dentro)
	dentro.add_child(PiezasLeccion.rotulo("Animación · use los controles"))
	var guion: GDScript = load(CARPETA_ANIMACIONES % bloque["id"])
	var animacion: Animacion = guion.new()
	dentro.add_child(animacion)
	animacion.iniciar(bloque.get("params", {}), raiz.contenido)
	if bloque.has("pie"):
		columna.add_child(_pie(bloque["pie"]))
	return columna


func _crear_imagen(bloque: Dictionary) -> Control:
	var columna := _columna(6)
	var visor := VisorFicha.new(14.0)
	visor.name = "VisorImagen"
	columna.add_child(visor)
	var hoja := PiezasLeccion.papel(8.0)
	visor.add_child(hoja)
	var imagen := VistaSvg.new()
	imagen.color_etiquetas = Tema.TINTA
	imagen.cargar(bloque)
	imagen.custom_minimum_size.y = bloque.get("alto", ALTO_IMAGEN)
	hoja.add_child(imagen)
	if bloque.has("pie"):
		columna.add_child(_pie(bloque["pie"]))
	return columna


## Foto tomada a bordo (data/fotos_piezas.json, por «id»), con su halo y sus partes numeradas.
func _crear_foto(bloque: Dictionary) -> Control:
	var columna := _columna(6)
	var datos := raiz.contenido.leer(FotosPiezas.ARCHIVO)
	var foto: Dictionary = {}
	for f: Dictionary in datos.get("fotos", []):
		if f["id"] == bloque.get("id", ""):
			foto = f
	if foto.is_empty() or not FotosPiezas.existe(foto):
		return _aviso("Falta la foto %s" % bloque.get("id", ""))
	var visor := VisorFicha.new(10.0)
	visor.name = "VisorFoto"
	columna.add_child(visor)
	var f := FotoPieza.desde(foto, str(datos.get("credito", "")), bool(bloque.get("estado", false)))
	f.custom_minimum_size.y = float(bloque.get("alto", 220.0))
	visor.add_child(f)
	var partes: Array = foto.get("partes", [])
	for i in partes.size():
		columna.add_child(PiezasLeccion.fila_lampara("ambar", "%d · %s" % [i + 1, partes[i]["titulo"]], 13))
	columna.add_child(_pie(str(bloque.get("pie", foto.get("texto", "")))))
	return columna


func _pie(texto: String) -> Label:
	var e := PiezasLeccion.etiqueta(texto, 13, Color("93a1ad"))
	e.name = "Pie"
	return e


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
	fila.name = "Navegacion"
	fila.add_theme_constant_override("separation", 10)
	add_child(fila)
	_anterior = BotonAri.new("‹  ANTERIOR", ir_a_pagina.bind(pagina - 1), "oscuro")
	_anterior.disabled = pagina == 0
	_anterior.custom_minimum_size.y = 50.0
	_anterior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_anterior)
	_siguiente = BotonAri.new("SIGUIENTE  ›", ir_a_pagina.bind(pagina + 1), "ambar")
	_siguiente.custom_minimum_size.y = 50.0
	_siguiente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_siguiente.size_flags_stretch_ratio = 1.3
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


## Mientras falte contestar, «Siguiente» queda oscuro con su lámpara apagada.
func _actualizar_siguiente() -> void:
	var listo := pagina_resuelta()
	_siguiente.disabled = not listo
	_siguiente.estilo = "ambar" if listo else "oscuro"
	_siguiente.lampara = "" if listo else "ambar"


func ir_a_pagina(pagina: int) -> void:
	args["pagina"] = pagina
	raiz.reconstruir()


## Las preguntas de la lección en orden, con su clave en las respuestas y su tema.
func _preguntas() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	var paginas: Array = _leccion["paginas"]
	for p in paginas.size():
		var bloques: Array = paginas[p]["bloques"]
		for i in bloques.size():
			if bloques[i]["tipo"] in INTERACTIVOS:
				r.append({"clave": "%d_%d" % [p, i], "tema": str(bloques[i].get("tema", ""))})
	return r


func _total_preguntas() -> int:
	return _preguntas().size()


func _construir_final() -> void:
	var preguntas := _preguntas()
	var estados: Array = []
	var aciertos := 0
	var fallados: Array[String] = []
	for q: Dictionary in preguntas:
		var r: Dictionary = args["respuestas"].get(q["clave"], {})
		var ok: bool = r.get("acierto", false)
		estados.append("verde" if ok else ("rojo" if not r.is_empty() else ""))
		if ok:
			aciertos += 1
		elif not str(q["tema"]).is_empty():
			fallados.append(q["tema"])
	var total := preguntas.size()
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.completar_leccion(args["id"], aciertos, total)
	var sub := "Lección completada"
	if _area.has("nombre") and not raiz.vertical:
		sub += " · %s" % _area["nombre"]
	_poner_cabecera(sub, _leccion["paginas"].size())
	var desplazable := _desplazable()
	add_child(desplazable)
	var resultado := PiezasLeccion.placa(16.0, 12.0)
	resultado.name = "Resultado"
	var col_r := VBoxContainer.new()
	col_r.add_theme_constant_override("separation", 10)
	col_r.mouse_filter = Control.MOUSE_FILTER_PASS
	resultado.add_child(col_r)
	col_r.add_child(PiezasLeccion.rotulo("Resultado"))
	var tablero := ResultadoLeccion.new()
	tablero.color = Tema.color_area(_area) if not _area.is_empty() else Tema.ACENTO
	tablero.icono = str(_area.get("icono", "sistema_%d" % int(_area["id"]))) if _area.has("id") else "leccion"
	tablero.estados = estados
	tablero.aciertos = aciertos
	tablero.total = total
	tablero.puntos = int(args["ganados"])
	col_r.add_child(tablero)
	var ganados: int = args["ganados"]
	if ganados <= 0:
		col_r.add_child(PiezasLeccion.etiqueta("Los puntos de esta lección ya estaban registrados.", 13, Tema.TEXTO_SUAVE))
	var banco := BancoRepaso.new(raiz.contenido)
	for tema in fallados:
		col_r.add_child(PiezasLeccion.fila_lampara("rojo", banco.titulo(tema) if banco.tiene(tema) else tema, 14))
	if not fallados.is_empty():
		col_r.add_child(PiezasLeccion.etiqueta("Los temas con error quedan registrados para su repaso: vuelven mañana.", 13, Tema.TEXTO_SUAVE))
	var mas := PiezasLeccion.placa(16.0, 12.0)
	mas.name = "Mas"
	var col_m := VBoxContainer.new()
	col_m.add_theme_constant_override("separation", 10)
	col_m.mouse_filter = Control.MOUSE_FILTER_PASS
	mas.add_child(col_m)
	col_m.add_child(PiezasLeccion.rotulo("Para saber más"))
	col_m.add_child(PiezasLeccion.referencias(_leccion.get("para_saber_mas", [])))
	var proxima := _proxima_leccion()
	if not proxima.is_empty():
		col_m.add_child(PiezasLeccion.rotulo("Siguiente en el camino"))
		var datos := raiz.contenido.leccion(proxima)
		var lista := _lista_area()
		var fila := FilaPlaca.new(str(datos.get("titulo", proxima)), "Lección %d de %d · %d min" % [lista.find(proxima) + 1, lista.size(), int(datos.get("minutos", 5))])
		fila.name = "SiguienteCamino"
		fila.tipo = "moneda"
		fila.numero = lista.find(proxima) + 1
		fila.color = Tema.color_area(_area) if not _area.is_empty() else Tema.ACENTO
		fila.tocada.connect(_abrir_proxima.bind(proxima))
		col_m.add_child(fila)
	if dos_columnas():
		var fila_h := HBoxContainer.new()
		fila_h.add_theme_constant_override("separation", 12)
		fila_h.mouse_filter = Control.MOUSE_FILTER_PASS
		desplazable.add_child(_limitar(fila_h))
		for p: Control in [resultado, mas]:
			p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p.size_flags_vertical = Control.SIZE_FILL
			fila_h.add_child(p)
	else:
		var columna := _columna(12)
		desplazable.add_child(_ancho_lectura(columna))
		columna.add_child(resultado)
		columna.add_child(mas)
	var botones := HBoxContainer.new()
	botones.name = "Navegacion"
	botones.add_theme_constant_override("separation", 10)
	add_child(botones)
	var volver := BotonAri.new("VOLVER A LA LISTA", raiz.volver, "oscuro")
	volver.custom_minimum_size.y = 50.0
	volver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(volver)
	if not proxima.is_empty():
		var texto := "SIGUIENTE LECCIÓN"
		if dos_columnas():
			texto = "Siguiente lección: %s" % raiz.contenido.leccion(proxima)["titulo"]
		var seguir := BotonAri.new(texto, _abrir_proxima.bind(proxima), "ambar")
		seguir.name = "SiguienteLeccion"
		seguir.custom_minimum_size.y = 50.0
		seguir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seguir.size_flags_stretch_ratio = 1.6
		botones.add_child(seguir)


func _proxima_leccion() -> String:
	var lista := _lista_area()
	var i := lista.find(args["id"])
	return "" if i < 0 or i + 1 >= lista.size() else lista[i + 1]


func _abrir_proxima(id: String) -> void:
	var sistema: int = int(_area.get("id", args.get("sistema", -1)))
	raiz.volver()
	raiz.ir_a("leccion", {"id": id, "sistema": sistema})


## Resultado de la lección: medalla del área con el anillo de aciertos, una lámpara por pregunta
## (verde acertada, roja fallada) y los visores de aciertos y puntos.
class ResultadoLeccion:
	extends Control

	var color := Tema.ACENTO
	var icono := "leccion"
	var estados: Array = []
	var aciertos := 0
	var total := 0
	var puntos := 0

	func _init() -> void:
		name = "ResultadoLeccion"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(280, 132)

	func _draw() -> void:
		var r := minf(42.0, size.y * 0.32)
		var c := Vector2(r * 1.3 + 4.0, size.y / 2.0)
		Relieve.medalla(self, c, r, color, icono, float(aciertos) / maxf(total, 1) if total > 0 else 1.0)
		var x := c.x + r * 1.5 + 12.0
		var ancho := size.x - x
		var tam := float(Tema.tam(12))
		PiezasAri.texto(self, "Respuestas correctas al primer intento" if total > 0 else "Lección sin preguntas", x, 14.0, tam, Tema.TEXTO_SUAVE, Tema.PESO_MEDIO, HORIZONTAL_ALIGNMENT_LEFT)
		var paso := minf(36.0, ancho / maxf(estados.size(), 1))
		for i in estados.size():
			var p := Vector2(x + 12.0 + i * paso, 36.0)
			if estados[i] == "":
				Relieve.lampara_estado(self, p, 6.0, "sin_empezar")
			else:
				PiezasAri.lampara(self, p, 7.5, estados[i], 1.0)
			if paso >= 26.0:
				PiezasAri.texto(self, "P%d" % (i + 1), p.x, 60.0, float(Tema.tam(10)), Color("8a97a2"), Tema.PESO_FUERTE)
		var w := minf((ancho - 10.0) / 2.0, 150.0)
		for k in 2:
			var caja := Rect2(x + k * (w + 10.0), 70.0, w, 58.0)
			DibujoAri.sombra(self, caja, 8.0, 0.5, Vector2(0, 2))
			DibujoAri.degradado(self, caja, 8.0, [Color("05080a"), Color("2a3b48")])
			var lcd := Rect2(caja.position + Vector2(6, 6), Vector2(caja.size.x - 12.0, 30.0))
			if k == 0:
				PiezasAri.visor(self, lcd, 1.0, str(aciertos), "DE %d" % total, Tema.ARI_LCD_VERDE, 20.0)
			else:
				PiezasAri.visor(self, lcd, 1.0, str(puntos), "PTS", Tema.ARI_LCD_AMBAR, 20.0)
			PiezasAri.texto(self, "ACIERTOS" if k == 0 else "PUNTOS", caja.get_center().x, caja.end.y - 7.0, float(Tema.tam(10)), Color("a9b6c1"), Tema.PESO_NEGRITA)
