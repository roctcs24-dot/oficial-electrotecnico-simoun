extends RefCounted
## Etapa E del rediseño: la lección, el examen, el repaso y la pantalla «Buque» con relieve:
## placas, fórmulas en un visor, teclas con letra, monedas de las páginas, tira de preguntas,
## cajas del repaso, calificación y las marcas de los lugares con tableros.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_rediseno_e.json"
const APAISADO := Vector2i(960, 432)
const VERTICAL := Vector2i(432, 960)


func _raiz(tam := APAISADO) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.set_anchors_preset(Control.PRESET_TOP_LEFT)
	raiz.size = Vector2(tam)
	raiz._al_cambiar_tamano()
	raiz.reconstruir()
	return raiz


func _buscar(nodo: Node, clase: String) -> Array[Node]:
	return nodo.find_children("*", clase, true, false)


func _nombre(nodo: Node, nombre: String) -> Node:
	return nodo.find_child(nombre, true, false)


func test_formulas_centradas_salen_aparte() -> String:
	var guion: GDScript = load("res://ui/screens/leccion.gd")
	var partes: PackedStringArray = guion.partir_formulas("Texto.\n\n[center][b]V = I × R[/b][/center]\n\n• Tensión")
	var sin: PackedStringArray = guion.partir_formulas("Un [b]texto[/b] normal.")
	return A.primero([
		A.cierto(partes.size() == 3 and partes[1] == "=V = I × R", "la fórmula sale con «=»: %s" % str(partes)),
		A.cierto(sin.size() == 1 and not sin[0].begins_with("="), "un texto sin fórmula queda igual"),
	])


func test_leccion_en_dos_columnas_en_apaisado_y_una_en_vertical() -> String:
	var raiz := _raiz()
	raiz.ir_a("leccion", {"id": "l0_ohm_potencia", "sistema": 0})
	var p := raiz.pantalla_actual()
	var lectura := _nombre(p, "Lectura") != null and _nombre(p, "Manejo") != null
	var formula := _nombre(p, "Formula") != null
	var visor := _nombre(p, "VisorAnimacion") is VisorFicha
	var monedas := _nombre(p, "MonedasPaginas")
	var cabecera := _nombre(p, "CabeceraFicha") is CabeceraFicha
	raiz.vertical = true
	raiz.reconstruir()
	var q := raiz.pantalla_actual()
	var una := _nombre(q, "Lectura") == null and _nombre(q, "VisorAnimacion") != null
	raiz.free()
	return A.primero([
		A.cierto(cabecera, "la lección lleva la cabecera de la ficha"),
		A.cierto(monedas != null and monedas.total == 3 and monedas.actual == 0, "una moneda por página"),
		A.cierto(lectura, "en apaisado, el texto a la izquierda y lo que se toca a la derecha"),
		A.cierto(formula, "V = I × R sale en el visor de fórmulas"),
		A.cierto(visor, "la animación va dentro de un visor"),
		A.cierto(una, "en vertical, una sola columna"),
	])


func test_teclas_con_letra_y_explicacion() -> String:
	var quiz := BloqueQuiz.new()
	quiz.iniciar({"pregunta": "¿?", "opciones": ["a", "b", "c"], "correcta": 1, "explicacion": "Porque sí."})
	var letras := quiz._botones.map(func(b: Button) -> String: return (b as TeclaOpcion).letra)
	var alto := (quiz._botones[0] as TeclaOpcion).custom_minimum_size.y
	quiz.elegir(2)
	var estados := quiz._botones.map(func(b: Button) -> String: return (b as TeclaOpcion).estado)
	var caja := quiz.find_child("Explicacion", true, false) != null
	var texto := quiz._explicacion.text if quiz._explicacion != null else ""
	quiz.free()
	return A.primero([
		A.cierto(letras == ["A", "B", "C"], "letras: %s" % str(letras)),
		A.cierto(alto >= 48.0, "la tecla mide al menos 48: %.0f" % alto),
		A.cierto(estados == ["apagada", "ok", "mal"], "estados: %s" % str(estados)),
		A.cierto(caja and texto == "Porque sí.", "la explicación sale en su caja: «%s»" % texto),
	])


func test_caso_practico_en_hoja_del_libro() -> String:
	var quiz := BloqueQuiz.new()
	quiz.iniciar({"caso": "Una bomba…", "pregunta": "¿?", "opciones": ["a", "b"], "correcta": 0, "explicacion": "x"})
	var hoja := quiz.find_child("CasoPractico", true, false) is BloqueQuiz.HojaGuardia
	quiz.free()
	return A.cierto(hoja, "el caso práctico va en una hoja del libro de guardia")


func test_siguiente_apagado_hasta_contestar() -> String:
	var raiz := _raiz()
	raiz.ir_a("leccion", {"id": "l0_ohm_potencia", "sistema": 0})
	var p = raiz.pantalla_actual()
	var antes_estilo: String = p._siguiente.estilo
	var antes: bool = p._siguiente.disabled
	var anterior: bool = p._anterior.disabled
	var quiz: BloqueQuiz = _buscar(p, "BloqueQuiz")[0]
	quiz.elegir(int(quiz._datos["correcta"]))
	var despues: bool = p._siguiente.disabled
	var despues_estilo: String = p._siguiente.estilo
	raiz.free()
	return A.primero([
		A.cierto(antes and antes_estilo == "oscuro", "sin contestar, «Siguiente» va oscuro y apagado"),
		A.cierto(anterior, "en la primera página no hay «Anterior»"),
		A.cierto(not despues and despues_estilo == "ambar", "al contestar se enciende en ámbar"),
	])


func test_final_de_la_leccion_con_lamparas_y_camino() -> String:
	var raiz := _raiz()
	var respuestas := {"0_2": {"acierto": true, "indice": 1}, "1_1": {"acierto": false, "indice": 0}, "2_2": {"acierto": true, "indice": 2}}
	raiz.ir_a("leccion", {"id": "l0_ohm_potencia", "sistema": 0, "pagina": 3, "respuestas": respuestas})
	var p := raiz.pantalla_actual()
	var r = _nombre(p, "ResultadoLeccion")
	var estados: Array = r.estados if r != null else []
	var aciertos: int = r.aciertos if r != null else -1
	var refs := _nombre(p, "ParaSaberMas") != null
	var camino := _nombre(p, "SiguienteCamino") as FilaPlaca
	if camino != null:
		camino.pulsar()
	var abre: bool = raiz.nombre_actual() == "leccion" and raiz.args_actuales().get("id", "") == "l0_alterna"
	raiz.free()
	return A.primero([
		A.cierto(estados == ["verde", "rojo", "verde"], "una lámpara por pregunta: %s" % str(estados)),
		A.cierto(aciertos == 2, "aciertos: %d" % aciertos),
		A.cierto(refs, "«Para saber más» va en papel"),
		A.cierto(abre, "la moneda del camino abre la siguiente lección"),
	])


func test_examen_con_tira_contador_y_simbolo_en_papel() -> String:
	var raiz := _raiz()
	var c := raiz.contenido
	var azar := RandomNumberGenerator.new()
	azar.seed = 5
	var simbolo := JuegoSimbolos.crear_ronda("contacto_na", c.simbolos(), azar)
	simbolo["tipo"] = "simbolo"
	simbolo["tema"] = "simbolo_contacto_na"
	var items := [simbolo, simbolo, simbolo, simbolo]
	raiz.ir_a("prueba_examen", {"id": "v1", "items": items, "indice": 2, "respuestas": {0: {"acierto": true, "elegida": 0}, 1: {"acierto": false, "elegida": 1}}})
	var p := raiz.pantalla_actual()
	var tira = _nombre(p, "TiraPreguntas")
	var contador = _nombre(p, "Contador")
	var papel := _nombre(p, "VisorSimbolo") != null and _nombre(_nombre(p, "VisorSimbolo"), "Papel") != null
	var estados: Array = tira.estados if tira != null else []
	var actual: int = tira.actual if tira != null else -1
	var contador_ok: bool = contador != null and contador.numero == 3 and contador.total == 4
	raiz.free()
	return A.primero([
		A.cierto(estados == ["verde", "rojo", "", ""] and actual == 2, "la tira: %s" % str(estados)),
		A.cierto(contador_ok, "el contador dice 3 de 4"),
		A.cierto(papel, "el símbolo va en papel dentro de un visor"),
	])


func test_calificacion_del_examen() -> String:
	var raiz := _raiz(VERTICAL)
	var banco: Dictionary = raiz.contenido.leer("examenes/v1.json")
	var q: Dictionary = banco["preguntas"][0]
	var items := []
	var respuestas := {}
	for i in 10:
		items.append(q)
		respuestas[i] = {"acierto": i != 3, "elegida": 0}
	raiz.ir_a("prueba_examen", {"id": "v1", "items": items, "indice": 10, "respuestas": respuestas})
	var p := raiz.pantalla_actual()
	var cal = _nombre(p, "Calificacion")
	var repasar_b := _nombre(p, "Repasar") as BotonAri
	var repasar_ok := repasar_b != null and repasar_b.estilo == "ambar"
	var temas := _nombre(p, "TemasARepasar") != null
	var ok: bool = cal != null and cal.correctas == 9 and cal.total == 10 and is_equal_approx(cal.porcentaje, 90.0)
	var aprobado: bool = cal != null and cal.aprobado
	raiz.free()
	return A.primero([
		A.cierto(ok, "la calificación cuenta 9 de 10 y el 90 %"),
		A.cierto(aprobado, "90 % aprueba con el mínimo del v1"),
		A.cierto(repasar_ok, "«Repasar mis errores» va primero, en ámbar"),
		A.cierto(temas, "los temas fallados salen con su lámpara roja"),
	])


func test_repaso_muestra_las_cajas_del_tema() -> String:
	var raiz := _raiz()
	var banco := BancoRepaso.new(raiz.contenido)
	raiz.partida.registrar_error("ohm_corriente")
	raiz.partida.datos["errores"]["ohm_corriente"]["caja"] = 2
	var azar := RandomNumberGenerator.new()
	azar.seed = 1
	raiz.ir_a("repaso", {"items": [banco.pregunta("ohm_corriente", azar)], "indice": 0, "respuestas": {}})
	var cajas = _nombre(raiz.pantalla_actual(), "CajasRepaso")
	var caja: int = cajas.caja if cajas != null else -1
	raiz.free()
	var vacia := _raiz()
	vacia.ir_a("repaso")
	var volver := _nombre(vacia.pantalla_actual(), "Volver") is BotonAri
	vacia.free()
	return A.primero([
		A.cierto(caja == 2, "la lámpara ámbar es la caja del tema: %d" % caja),
		A.cierto(volver, "sin temas, la pantalla ofrece volver"),
	])


func test_lugares_cubren_todos_los_paneles() -> String:
	var c := Contenido.new()
	var paneles := Paneles.new(c)
	var lugares := paneles.por_lugar(c.planta().get("lugares", []))
	var vistos := []
	var fallos: Array[String] = []
	for l: Dictionary in lugares:
		if float(l["u"]) < PlantaBuque.POPA or float(l["u"]) > PlantaBuque.PROA or float(l["v"]) < 20.0 or float(l["v"]) > 280.0:
			fallos.append("%s fuera del casco" % l["lugar"])
		vistos.append_array(l["paneles"])
	for p: Dictionary in paneles.lista():
		if vistos.count(p["codigo"]) != 1:
			fallos.append("%s aparece %d veces" % [p["codigo"], vistos.count(p["codigo"])])
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_marcas_de_los_lugares_se_tocan_sin_pisarse() -> String:
	var fallos: Array[String] = []
	var c := Contenido.new()
	for tam: Vector2 in [Vector2(600, 300), Vector2(408, 560)]:
		var planta := PlantaBuque.new()
		planta.cargar(c.planta(), c.sistemas())
		var lugares := []
		for l: Dictionary in Paneles.new(c).por_lugar(c.planta().get("lugares", [])):
			lugares.append({"lugar": l["lugar"], "u": l["u"], "v": l["v"], "paneles": l["paneles"].size()})
		planta.lugares = lugares
		planta.capa = "tableros"
		planta.reserva_arriba = 50.0
		planta.size = tam
		var centros := planta.centros_lugares()
		for i in centros.size():
			if planta.lugar_en(centros[i]) != i:
				fallos.append("%s en %s: su centro toca otra marca" % [lugares[i]["lugar"], str(tam)])
			if planta.lugar_en(centros[i] + Vector2(0, 20)) == -1:
				fallos.append("%s en %s: menos de 48 puntos táctiles" % [lugares[i]["lugar"], str(tam)])
		var zona := planta.zona_en(planta.zonas_pantalla()[0]["rect"].get_center())
		if zona != -1:
			fallos.append("en la capa de tableros las zonas no se tocan")
		planta.free()
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_buque_con_averia_y_paneles_que_se_abren() -> String:
	var raiz := _raiz()
	var mision := ""
	for m: String in raiz.contenido.sistema(3)["modos"]["guardia"]["misiones"]:
		if raiz.contenido.mision(m).has("tablero"):
			mision = m
			break
	raiz.partida.datos["equipos_danados"][mision] = {"motor": "quemado"}
	var codigo := raiz.paneles.codigo_mision(raiz.contenido.mision(mision))
	raiz.ir_a_seccion("plano_barco")
	var p = raiz.pantalla_actual()
	var elegido: Dictionary = p.lugares[p.args["lugar"]]
	var alarma: bool = bool(elegido["alarma"]) and elegido["paneles"].has(codigo)
	var fila := _nombre(p, "Panel_%s" % codigo) as FilaPlaca
	var roja := fila != null and fila.lampara == "rojo"
	var alto := fila.custom_minimum_size.y if fila != null else 0.0
	if fila != null:
		fila.pulsar()
	var abre := raiz.nombre_actual() == "tablero"
	raiz.free()
	return A.primero([
		A.cierto(alarma, "el buque abre en el lugar con la avería (%s)" % codigo),
		A.cierto(roja, "el panel con avería lleva la lámpara roja"),
		A.cierto(alto >= 48.0, "la fila mide al menos 48: %.0f" % alto),
		A.cierto(abre, "tocar el panel lo abre"),
	])


func test_capas_del_buque() -> String:
	var raiz := _raiz(VERTICAL)
	raiz.ir_a_seccion("plano_barco")
	var p = raiz.pantalla_actual()
	var empieza: bool = str(p.args["capa"]) == "tableros" and p.planta.capa == "tableros"
	p.elegir_capa("sistemas")
	var q = raiz.pantalla_actual()
	var cambia: bool = q.planta.capa == "sistemas" and _nombre(q, "TarjetaSistemas") != null
	var fila := _nombre(q, "Sistema_3") as FilaPlaca
	if fila != null:
		fila.pulsar()
	var abre := raiz.nombre_actual() == "sistema"
	raiz.free()
	return A.primero([
		A.cierto(empieza, "el Buque empieza en la capa de tableros"),
		A.cierto(cambia, "el selector pasa a la capa de sistemas"),
		A.cierto(abre, "una fila de sistema abre el sistema"),
	])


func test_lista_de_examenes_en_placas() -> String:
	var raiz := _raiz()
	raiz.ir_a("examen", {"id": 3})
	var fila := _nombre(raiz.pantalla_actual(), "Examen_v1") as FilaPlaca
	if fila != null:
		fila.pulsar()
	var abre := raiz.nombre_actual() == "prueba_examen"
	raiz.free()
	return A.cierto(abre, "la fila del examen abre la prueba")
