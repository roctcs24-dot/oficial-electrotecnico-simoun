extends RefCounted
## Etapa 42: herramientas del pañol, tabla de llaves en milímetros y pulgadas, minijuego
## «Identifique la herramienta» y lecciones del módulo 11.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_herramientas.json"
const LECCIONES := ["he1_familias_llaves", "he2_mm_pulgadas", "he3_tornilleria", "he4_destornilladores", "he5_alicates_crimpado",
	"he6_calibre_micrometro", "he7_par_apriete", "he8_tuberia", "he9_cuidado_seguridad"]


func _raiz(tam := Vector2i(960, 432)) -> Raiz:
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


func test_conversion_de_pulgadas() -> String:
	return A.primero([
		A.cerca(TablaLlaves.a_mm("3/4"), 19.05, 0.001, "3/4\""),
		A.cerca(TablaLlaves.a_mm("5/16\""), 7.9375, 0.0001, "5/16\""),
		A.cerca(TablaLlaves.a_mm("1-1/16"), 26.9875, 0.0001, "1-1/16\""),
		A.cerca(TablaLlaves.a_mm("1"), 25.4, 0.0001, "1\""),
	])


func test_criterio_de_las_llaves() -> String:
	var m := range(6, 33)
	return A.primero([
		A.cierto(TablaLlaves.estado(19.0, TablaLlaves.a_mm("3/4")) == "entra", "19 mm entra en 3/4\""),
		A.cierto(TablaLlaves.estado(13.0, TablaLlaves.a_mm("1/2")) == "holgada", "13 mm queda holgada en 1/2\""),
		A.cierto(TablaLlaves.estado(11.0, TablaLlaves.a_mm("7/16")) == "no_entra", "11 mm no entra en 7/16\""),
		A.cierto(TablaLlaves.estado(20.0, TablaLlaves.a_mm("3/4")) == "redondea", "20 mm redondea una de 3/4\""),
		A.cierto(TablaLlaves.mejor_metrica(TablaLlaves.a_mm("5/8"), m) == 16, "para 5/8\", la de 16 mm"),
		A.cierto(TablaLlaves.mejor_metrica(TablaLlaves.a_mm("9/16"), m) == 15, "para 9/16\", la menor que no se queda corta es la de 15 mm"),
	])


func test_catalogo_y_dibujos() -> String:
	var c := Contenido.new()
	var lista: Array = c.leer("catalogos/herramientas.json").get("herramientas", [])
	var fallos: Array[String] = []
	var ids := {}
	for h: Dictionary in lista:
		ids[h["id"]] = true
		for campo in ["nombre", "en", "familia", "dibujo", "para_que", "como_usar", "no_hacer", "cuidado"]:
			if str(h.get(campo, "")).is_empty():
				fallos.append("%s sin %s" % [h["id"], campo])
		if not DibujoHerramienta.TIPOS.has(h["dibujo"]):
			fallos.append("%s: dibujo desconocido" % h["id"])
	for h: Dictionary in lista:
		for s: String in h.get("similares", []):
			if not ids.has(s):
				fallos.append("%s: similar desconocido %s" % [h["id"], s])
	var arbol := Engine.get_main_loop() as SceneTree
	for t: String in DibujoHerramienta.TIPOS:
		var d := DibujoHerramienta.new()
		d.tipo = t
		d.size = Vector2(360, 200)
		arbol.root.add_child(d)
		d.free()
	return A.primero([
		A.cierto(lista.size() == 16, "16 herramientas: %d" % lista.size()),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
	])


func test_rondas_del_minijuego() -> String:
	var c := Contenido.new()
	var azar := RandomNumberGenerator.new()
	azar.seed = 5
	var rondas := JuegoHerramientas.crear_rondas(c.leer("catalogos/herramientas.json"), c.leer("tablas/llaves.json"), 10, azar)
	var de_llaves := 0
	var fallos: Array[String] = []
	for r: Dictionary in rondas:
		if r["tipo"] == "llave":
			de_llaves += 1
		var opciones: Array = r["opciones"]
		if int(r["correcta"]) < 0 or int(r["correcta"]) >= opciones.size():
			fallos.append("%s sin respuesta" % r["id"])
		var unicas := {}
		for o in opciones:
			unicas[o] = true
		if unicas.size() != opciones.size():
			fallos.append("%s con opciones repetidas" % r["id"])
	return A.primero([
		A.cierto(rondas.size() == 10, "10 rondas: %d" % rondas.size()),
		A.cierto(de_llaves == JuegoHerramientas.RONDAS_LLAVES, "%d rondas de llaves" % de_llaves),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
	])


func test_modulo_11_activo() -> String:
	var m := Contenido.new().sistema(11)
	return A.primero([
		A.cierto(m.get("estado", "") == "activo", "el módulo 11 está activo"),
		A.cierto(Array(m["modos"]["aprender"]["lecciones"]).slice(0, LECCIONES.size()) == LECCIONES, "lecciones de herramientas al principio del módulo 11"),
		A.cierto(Array(m["modos"]["examen"]["minijuegos"]).has("identifique_herramienta"), "su minijuego"),
	])


func test_lecciones_se_recorren() -> String:
	var raiz := _raiz()
	var fallos: Array[String] = []
	for id: String in LECCIONES:
		raiz.ir_a("leccion", {"id": id, "sistema": 11})
		var p = raiz.pantalla_actual()
		for n in raiz.contenido.leccion(id)["paginas"].size():
			for quiz: BloqueQuiz in p.find_children("*", "BloqueQuiz", true, false):
				quiz.elegir(int(quiz._datos["correcta"]))
			for o: BloqueOrdenar in p.find_children("*", "BloqueOrdenar", true, false):
				for k in o._datos["pasos"].size():
					for b: Node in o._pendientes.get_children():
						if b is Button and b.text == TextoTecnico.unir_unidades(o._datos["pasos"][o._siguiente]):
							(b as Button).pressed.emit()
							break
			if not p.pagina_resuelta():
				fallos.append("%s, página %d" % [id, n + 1])
				break
			p.ir_a_pagina(n + 1)
			p = raiz.pantalla_actual()
		if not raiz.partida.leccion_completada(id):
			fallos.append("%s sin completar" % id)
		raiz.volver()
	raiz.free()
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_panol_abre_herramientas_tabla_y_minijuego() -> String:
	var raiz := _raiz()
	raiz.ir_a_seccion("panol")
	var titulos := []
	for f: FilaPlaca in raiz.pantalla_actual().filas:
		titulos.append(f.titulo)
	var destinos := {}
	for t: String in ["Herramientas", "Llaves: milímetros y pulgadas", "Identifique la herramienta"]:
		raiz.ir_a_seccion("panol")
		for f: FilaPlaca in raiz.pantalla_actual().filas:
			if f.titulo == t:
				f.pulsar()
				break
		destinos[t] = raiz.nombre_actual()
	raiz.free()
	return A.primero([
		A.cierto(destinos.get("Herramientas", "") == "catalogo", "Herramientas abre el catálogo: %s" % str(destinos)),
		A.cierto(destinos.get("Llaves: milímetros y pulgadas", "") == "tabla_llaves", "la tabla de llaves"),
		A.cierto(destinos.get("Identifique la herramienta", "") == "identifique_herramienta", "el minijuego"),
		A.cierto(not titulos.has("Llaves: milímetros y pulgadas") or titulos.count("Llaves: milímetros y pulgadas") == 1, "la tabla ya no sale en preparación"),
	])


func test_tabla_y_catalogo_en_pantalla() -> String:
	var raiz := _raiz(Vector2i(432, 960))
	raiz.ir_a("tabla_llaves", {})
	var p = raiz.pantalla_actual()
	var filas: int = p.filas.size()
	p.elegir("5/8")
	var q = raiz.pantalla_actual()
	var dibujo_16: bool = q.dibujo.medida == "16 mm"
	raiz.ir_a("catalogo", {"catalogo": "herramientas", "elegido": "dinamometrica"})
	var c = raiz.pantalla_actual()
	var herr: bool = c.dibujo is DibujoHerramienta and c.dibujo.tipo == "dinamometrica" and c.filas.size() == 16
	raiz.free()
	return A.primero([
		A.cierto(filas == 16, "una fila por medida en pulgadas: %d" % filas),
		A.cierto(dibujo_16, "con 5/8\" el conversor dibuja la llave de 16 mm"),
		A.cierto(herr, "el catálogo de herramientas dibuja la elegida"),
	])


func test_minijuego_suma_estrellas() -> String:
	var raiz := _raiz()
	raiz.ir_a("identifique_herramienta", {})
	var total: int = raiz.pantalla_actual().args["items"].size()
	for i in total:
		var q = raiz.pantalla_actual()
		var item: Dictionary = q.args["items"][q.args["indice"]]
		q._al_responder(true, int(item["correcta"]), q.args["indice"])
		q.avanzar()
	var estrellas := int(raiz.partida.datos["minijuegos"].get(JuegoHerramientas.REGISTRO, {}).get("estrellas", 0))
	raiz.free()
	return A.cierto(estrellas == 3, "todo acertado da 3 estrellas: %d" % estrellas)
