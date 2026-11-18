extends RefCounted
## Etapa 43: racores. Catálogo, dibujo de cada tipo, tablas de roscas, DN y mangueras, minijuego
## «Elija el racor» con rondas de DN y de fotos, pantallas del Pañol y lecciones ra1 a ra8.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_racores.json"
const LECCIONES := ["ra1_familias_racores", "ra2_roscas_bsp_npt", "ra3_dn_nps", "ra4_jic_orfs_din", "ra5_mangueras", "ra6_latiguillo", "ra7_compresion_banjo_bridas", "ra8_fugas_seguridad"]


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


func _catalogo() -> Dictionary:
	return Contenido.new().leer("catalogos/racores.json")


func _tabla() -> Dictionary:
	return Contenido.new().leer("tablas/roscas.json")


func test_catalogo_bien_formado() -> String:
	var lista: Array = _catalogo().get("racores", [])
	var ids := lista.map(func(r: Dictionary) -> String: return r["id"])
	var fallos: Array[String] = []
	for r: Dictionary in lista:
		for campo in ["id", "corto", "nombre", "en", "familia", "norma", "dibujo", "como_reconocer", "sella", "a_bordo", "no_hacer", "fallas", "mantenimiento", "similares", "pista"]:
			if not r.has(campo) or str(r[campo]).is_empty():
				fallos.append("%s sin %s" % [r.get("id", "?"), campo])
		if not DibujoRacor.TIPOS.has(r.get("dibujo", "")):
			fallos.append("%s: dibujo desconocido" % r["id"])
		for s: String in r.get("similares", []):
			if not ids.has(s) or s == r["id"]:
				fallos.append("%s: similar raro %s" % [r["id"], s])
		if str(r.get("pista", "")).containsn(str(r.get("corto", "?"))):
			fallos.append("%s: la pista dice el nombre" % r["id"])
	return A.primero([
		A.cierto(lista.size() == 10, "10 racores: %d" % lista.size()),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(str(_catalogo().get("nota", "")).contains("verificar a bordo"), "el catálogo avisa de verificar a bordo"),
	])


func test_cada_racor_se_dibuja() -> String:
	var arbol := Engine.get_main_loop() as SceneTree
	for t: String in DibujoRacor.TIPOS:
		for con_rotulos in [true, false]:
			var d := DibujoRacor.new()
			d.tipo = t
			d.rotulos = con_rotulos
			arbol.root.add_child(d)
			d.size = Vector2(360, 200)
			d.queue_redraw()
			d.free()
	return ""


func test_tablas_de_roscas_y_dn() -> String:
	var t := _tabla()
	var roscas: Array = t.get("roscas", [])
	var dn: Array = t.get("dn", [])
	var fallos: Array[String] = []
	var media := {}
	for r: Dictionary in roscas:
		if r["medida"] == "1/2":
			media = r
	var dn50 := {}
	for i in dn.size():
		if i > 0 and float(dn[i]["exterior"]) <= float(dn[i - 1]["exterior"]):
			fallos.append("el exterior no crece en DN%d" % int(dn[i]["dn"]))
		if int(dn[i]["dn"]) == 50:
			dn50 = dn[i]
	for i in roscas.size():
		if i > 0 and float(roscas[i]["bsp_mm"]) <= float(roscas[i - 1]["bsp_mm"]):
			fallos.append("la BSP no crece en %s" % roscas[i]["medida"])
	return A.primero([
		A.cierto(roscas.size() >= 6, "al menos 6 medidas de rosca"),
		A.cierto(not media.is_empty() and int(media["bsp_hilos"]) == 14 and int(media["npt_hilos"]) == 14, "1/2\": 14 hilos en BSP y NPT"),
		A.cierto(not media.is_empty() and absf(float(media["bsp_mm"]) - 20.955) < 0.01 and absf(float(media["npt_mm"]) - 21.34) < 0.01, "1/2\": 20,955 mm BSP y 21,34 mm NPT"),
		A.cierto(not dn50.is_empty() and dn50["nps"] == "2" and absf(float(dn50["exterior"]) - 60.3) < 0.01, "DN50 = 2\" NPS, 60,3 mm"),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(str(t.get("nota_mangueras", "")).contains("verificar"), "las presiones de mangueras avisan de verificar"),
	])


func test_rondas_del_minijuego() -> String:
	var azar := RandomNumberGenerator.new()
	azar.seed = 43
	var fotos := FotosPiezas.con_pregunta(Contenido.new().leer(FotosPiezas.ARCHIVO))
	var rondas := JuegoRacores.crear_rondas(_catalogo(), _tabla(), 10, azar, fotos)
	var cuenta := {"racor": 0, "dn": 0, "foto": 0}
	var fallos: Array[String] = []
	for r: Dictionary in rondas:
		cuenta[r["tipo"]] += 1
		var opciones: Array = r["opciones"]
		if int(r["correcta"]) < 0 or int(r["correcta"]) >= opciones.size():
			fallos.append("%s: respuesta fuera" % r["id"])
		var unicas := {}
		for o in opciones:
			unicas[str(o)] = true
		if unicas.size() != opciones.size():
			fallos.append("%s: opciones repetidas" % r["id"])
		if r["tipo"] == "racor" and opciones.size() != 4:
			fallos.append("%s: debe tener 4 opciones" % r["id"])
		if r["tipo"] == "dn":
			var buena := str(opciones[int(r["correcta"])])
			var esperada := ("DN%d" % int(r["dn"])) if r["por_exterior"] else ("%s\" NPS" % r["nps"])
			if buena != esperada:
				fallos.append("DN%d: correcta %s" % [r["dn"], buena])
	return A.primero([
		A.cierto(rondas.size() == 10, "10 rondas: %d" % rondas.size()),
		A.cierto(cuenta["dn"] == JuegoRacores.RONDAS_DN, "%d rondas de DN: %d" % [JuegoRacores.RONDAS_DN, cuenta["dn"]]),
		A.cierto(cuenta["foto"] == mini(JuegoRacores.FOTOS_RONDAS, fotos.size()), "rondas con foto: %d" % cuenta["foto"]),
		A.cierto(fotos.size() >= 2, "hay al menos dos fotos con pregunta"),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
	])


func test_minijuego_suma_estrellas() -> String:
	var raiz := _raiz(Vector2i(432, 960))
	raiz.ir_a("elija_racor", {})
	var p = raiz.pantalla_actual()
	var total: int = p.args["items"].size()
	var vistas := {}
	for i in total:
		var q = raiz.pantalla_actual()
		var item: Dictionary = q.args["items"][q.args["indice"]]
		var tiene: bool = q.find_child("Dibujo", true, false) != null or q.find_child("Tubo", true, false) != null or not q.find_children("*", "FotoPieza", true, false).is_empty()
		vistas[item["tipo"]] = vistas.get(item["tipo"], true) and tiene
		if item["tipo"] == "racor":
			var d: DibujoRacor = q.find_child("Dibujo", true, false)
			if d != null and d.rotulos:
				vistas["sin_rotulos"] = false
		q._al_responder(true, int(item["correcta"]), q.args["indice"])
		q.avanzar()
	var estrellas := int(raiz.partida.datos["minijuegos"].get(JuegoRacores.REGISTRO, {}).get("estrellas", 0))
	var final_ok := raiz.pantalla_actual().find_child("Calificacion", true, false) != null
	raiz.free()
	return A.primero([
		A.cierto(total == 10, "10 rondas"),
		A.cierto(not vistas.values().has(false), "cada ronda enseña su dibujo, tubo o foto, sin rótulos que chiven: %s" % vistas),
		A.cierto(estrellas == 3, "todo acertado da 3 estrellas: %d" % estrellas),
		A.cierto(final_ok, "el final muestra la calificación"),
	])


func test_pantallas_del_panol() -> String:
	var raiz := _raiz()
	raiz.ir_a_seccion("panol")
	var p = raiz.pantalla_actual()
	var destinos: Array[String] = []
	for f: FilaPlaca in p.filas:
		var antes := raiz.nombre_actual()
		f.pulsar()
		if raiz.nombre_actual() != antes:
			destinos.append(raiz.nombre_actual() + ":" + str(raiz.pantalla_actual().args.get("catalogo", "")))
			raiz.volver()
	raiz.ir_a("catalogo", {"catalogo": "racores"})
	var c = raiz.pantalla_actual()
	var n: int = c.filas.size()
	c.elegir("latiguillo")
	c = raiz.pantalla_actual()
	var foto_latiguillo: bool = c.dibujo is FotoPieza and not (c.dibujo as FotoPieza).partes.is_empty()
	var partes: int = c.find_children("Parte_*", "", true, false).size()
	c.elegir("jic")
	var jic_dibujo: bool = raiz.pantalla_actual().dibujo is DibujoRacor
	raiz.ir_a("roscas_tuberia", {})
	var r = raiz.pantalla_actual()
	r.elegir(80)
	var tubo_ok: bool = absf(raiz.pantalla_actual().tubo.exterior - 88.9) < 0.01
	raiz.vertical = true
	raiz.reconstruir()
	var gira: bool = int(raiz.pantalla_actual().args["dn"]) == 80
	raiz.ir_a("mangueras", {})
	var m = raiz.pantalla_actual()
	m.elegir(2)
	var tercero: bool = int(raiz.pantalla_actual().args["marcado"]) == 2 and raiz.pantalla_actual().filas.size() == 7
	raiz.free()
	return A.primero([
		A.cierto(destinos.has("catalogo:racores"), "el Pañol abre el catálogo de racores: %s" % str(destinos)),
		A.cierto(destinos.has("roscas_tuberia:") and destinos.has("mangueras:") and destinos.has("elija_racor:"), "y roscas, mangueras y el minijuego: %s" % str(destinos)),
		A.cierto(n == 10, "una fila por racor: %d" % n),
		A.cierto(foto_latiguillo, "el latiguillo empieza por su foto con las partes numeradas"),
		A.cierto(partes == 4, "y la lista de sus 4 partes: %d" % partes),
		A.cierto(jic_dibujo, "un racor sin foto se dibuja"),
		A.cierto(tubo_ok, "DN80 dibuja 88,9 mm de exterior"),
		A.cierto(gira, "el DN elegido sobrevive al giro"),
		A.cierto(tercero, "las mangueras cambian de ejemplo y listan 7 tipos"),
	])


func test_modulo_11_con_racores() -> String:
	var m := Contenido.new().sistema(11)
	var lecciones: Array = m["modos"]["aprender"]["lecciones"]
	return A.primero([
		A.cierto(lecciones.slice(lecciones.size() - LECCIONES.size()) == LECCIONES, "las 8 lecciones de racores al final del módulo 11"),
		A.cierto(Array(m["modos"]["examen"]["minijuegos"]).has("elija_racor"), "su minijuego en la evaluación"),
	])


func test_lecciones_se_recorren() -> String:
	var raiz := _raiz()
	var fallos: Array[String] = []
	var con_foto := 0
	for id: String in LECCIONES:
		raiz.ir_a("leccion", {"id": id, "sistema": 11})
		var p = raiz.pantalla_actual()
		for n in raiz.contenido.leccion(id)["paginas"].size():
			con_foto += p.find_children("*", "FotoPieza", true, false).size()
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
	return A.primero([
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(con_foto >= 5, "las lecciones enseñan fotos a bordo: %d" % con_foto),
	])
