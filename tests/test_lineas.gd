extends RefCounted
## Etapa 44: seguir líneas. Esquema de la purificadora bien formado, colores ISO 14726, lógica de
## seguir y aislar, la vista que se toca, el minijuego «Siga la línea», la pantalla de colores y
## las lecciones li1 a li4 con su bloque «linea».

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_lineas.json"
const LECCIONES := ["li1_planos_pid", "li2_colores_tuberia", "li3_seguir_linea", "li4_aislar_equipo"]


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


func _esquema() -> Dictionary:
	return JuegoLineas.leer(Contenido.new(), "purificadora")


func test_esquema_bien_formado() -> String:
	var e := _esquema()
	var colores: Dictionary = Contenido.new().leer("tuberias.json").get("colores", {})
	var tramos := {}
	var valvulas := {}
	var fallos: Array[String] = []
	var area := Rect2(0, 0, float(e["ancho"]), float(e["alto"]))
	for t: Dictionary in e.get("tramos", []):
		tramos[t["id"]] = true
		if not colores.has(t["servicio"]):
			fallos.append("%s: servicio sin color %s" % [t["id"], t["servicio"]])
		for p in JuegoLineas.puntos(t):
			if not area.has_point(p):
				fallos.append("%s: punto fuera %s" % [t["id"], p])
	for v: Dictionary in e.get("valvulas", []):
		valvulas[v["id"]] = true
		var c := Vector2(float(v["x"]), float(v["y"]))
		if e["tramos"].all(func(t: Dictionary) -> bool: return JuegoLineas.distancia_a_tramo(t, c) > 1.0):
			fallos.append("%s no está sobre ninguna línea" % v["id"])
	for j: Dictionary in e.get("ejercicios", []):
		match str(j["tipo"]):
			"seguir":
				for id in j["ruta"]:
					if not tramos.has(id):
						fallos.append("%s: tramo %s" % [j["id"], id])
			"aislar":
				for id in j["valvulas"]:
					if not valvulas.has(id):
						fallos.append("%s: válvula %s" % [j["id"], id])
			"servicio":
				if not tramos.has(j["tramo"]) or int(j["correcta"]) >= j["opciones"].size():
					fallos.append("%s mal formado" % j["id"])
			_:
				fallos.append("%s: tipo raro" % j["id"])
		if str(j.get("explicacion", "")).is_empty():
			fallos.append("%s sin explicación" % j["id"])
	return A.primero([
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(e.get("ejercicios", []).size() >= 5, "al menos 5 ejercicios"),
		A.cierto(str(e.get("nota", "")).contains("verificar a bordo"), "el esquema avisa de verificar a bordo"),
		A.cierto(str(Contenido.new().leer("tuberias.json").get("nota", "")).contains("verificar a bordo"), "los colores avisan de verificar a bordo"),
		A.cierto(colores.get("combustible", {}).get("iso", "") == "Marrón" and colores.get("agua_salada", {}).get("iso", "") == "Verde", "ISO 14726: combustible marrón, agua salada verde"),
	])


func test_logica_seguir_y_aislar() -> String:
	var ruta := ["t1", "t2", "t3"]
	var hechos := []
	var r1 := JuegoLineas.paso_seguir(ruta, hechos, "t1")
	var r_salto := JuegoLineas.paso_seguir(ruta, hechos, "t3")
	var r_mal := JuegoLineas.paso_seguir(ruta, hechos, "t8")
	var r_repite := JuegoLineas.paso_seguir(ruta, hechos, "t1")
	var e := _esquema()
	var en_t4 := JuegoLineas.tramo_en(e, JuegoLineas.centro_tramo(JuegoLineas.tramo(e, "t4")) + Vector2(0, 2))
	var lejos := JuegoLineas.tramo_en(e, Vector2(200, 250))
	return A.primero([
		A.cierto(r1 == "avanza" and hechos == ["t1"], "el primer tramo avanza"),
		A.cierto(r_salto == "", "saltarse un tramo de la ruta no avanza ni es error"),
		A.cierto(r_mal == "error", "un tramo fuera de la ruta es error"),
		A.cierto(r_repite == "", "repasar un tramo hecho no cuenta"),
		A.cierto(en_t4 == "t4" and lejos == "", "el dedo cerca de un tramo lo encuentra: %s, %s" % [en_t4, lejos]),
		A.cierto(JuegoLineas.aislar_correcto(["v5", "v3", "v4"], ["v3", "v4", "v5"]), "aislar: el orden no importa"),
		A.cierto(not JuegoLineas.aislar_correcto(["v3", "v4"], ["v3", "v4", "v5"]), "aislar: falta una"),
		A.cierto(not JuegoLineas.aislar_correcto(["v1", "v3", "v4", "v5"], ["v3", "v4", "v5"]), "aislar: sobra una"),
	])


func test_bloque_seguir_con_el_dedo() -> String:
	var e := _esquema()
	var b := BloqueLinea.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	var estado := {}
	b.iniciar(e, Contenido.new().leer("tuberias.json")["colores"], JuegoLineas.ejercicio(e, "seguir_alimentacion"), estado, {}, false)
	var resultados := []
	b.respondido.connect(func(ok: bool) -> void: resultados.append(ok))
	# Un tramo equivocado primero (la recirculación) y luego la ruta.
	b.vista.pulsar(b.vista.a_control(JuegoLineas.centro_tramo(JuegoLineas.tramo(e, "t8"))))
	var errores := int(estado["errores"])
	b.vista._ultimo = ""
	b.resolver_bien()
	var iluminados := b.vista.iluminados.size()
	b.free()
	return A.primero([
		A.cierto(errores == 1, "tocar una línea que no es cuenta un error: %d" % errores),
		A.cierto(resultados == [false], "terminar con un error responde mal: %s" % str(resultados)),
		A.cierto(iluminados == 4, "los cuatro tramos quedan iluminados: %d" % iluminados),
	])


func test_bloque_aislar_y_servicio() -> String:
	var e := _esquema()
	var colores: Dictionary = Contenido.new().leer("tuberias.json")["colores"]
	var b := BloqueLinea.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	var estado := {}
	b.iniciar(e, colores, JuegoLineas.ejercicio(e, "aislar_separadora"), estado, {}, true)
	var r := []
	b.respondido.connect(func(ok: bool) -> void: r.append(ok))
	b.vista.pulsar(b.vista.a_control(Vector2(70, 108)))
	b.vista.pulsar(b.vista.a_control(Vector2(70, 108)))
	var quitada: bool = estado["elegidas"].is_empty()
	for p in [Vector2(275, 134), Vector2(362, 95)]:
		b.vista.pulsar(b.vista.a_control(p))
	b.comprobar()
	var falta_v5: bool = b.vista.estados.get("v5", "") == "falta"
	b.free()
	var s := BloqueLinea.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(s)
	s.iniciar(e, colores, JuegoLineas.ejercicio(e, "servicio_lodos"), {}, {}, true)
	var r2 := []
	s.respondido.connect(func(ok: bool) -> void: r2.append(ok))
	var marcado := s.vista.marcado
	s.resolver_bien()
	s.free()
	return A.primero([
		A.cierto(quitada, "tocar dos veces una válvula la quita"),
		A.cierto(r == [false], "sin V5 la separadora no queda aislada: %s" % str(r)),
		A.cierto(falta_v5, "y la que faltaba se marca en ámbar"),
		A.cierto(marcado == "t8", "la pregunta de servicio marca su tramo"),
		A.cierto(r2 == [true], "la respuesta correcta se acepta: %s" % str(r2)),
	])


func test_minijuego_suma_estrellas_y_gira() -> String:
	var raiz := _raiz()
	raiz.ir_a("seguir_lineas", {})
	var p = raiz.pantalla_actual()
	var total: int = p.args["items"].size()
	# Medio ejercicio hecho y giro: lo hecho se conserva.
	p.bloque.vista.pulsar(p.bloque.vista.a_control(JuegoLineas.centro_tramo(JuegoLineas.tramo(p.bloque.esquema, "t1"))))
	raiz.vertical = true
	raiz.reconstruir()
	var conserva: bool = raiz.pantalla_actual().bloque.vista.iluminados == ["t1"]
	for i in total:
		var q = raiz.pantalla_actual()
		q.bloque.resolver_bien()
		q.avanzar()
	var estrellas := int(raiz.partida.datos["minijuegos"].get(JuegoLineas.REGISTRO, {}).get("estrellas", 0))
	var final_ok := raiz.pantalla_actual().find_child("Calificacion", true, false) != null
	raiz.free()
	return A.primero([
		A.cierto(total == 5, "5 ejercicios: %d" % total),
		A.cierto(conserva, "el tramo recorrido sobrevive al giro"),
		A.cierto(estrellas == 3, "todo bien da 3 estrellas: %d" % estrellas),
		A.cierto(final_ok, "el final muestra la calificación"),
	])


func test_panol_y_colores() -> String:
	var raiz := _raiz(Vector2i(432, 960))
	raiz.ir_a_seccion("panol")
	var destinos: Array[String] = []
	for f: FilaPlaca in raiz.pantalla_actual().filas:
		var antes := raiz.nombre_actual()
		f.pulsar()
		if raiz.nombre_actual() != antes:
			destinos.append(raiz.nombre_actual())
			raiz.volver()
	raiz.ir_a("colores_tuberia", {})
	var n: int = raiz.pantalla_actual().filas.size()
	raiz.free()
	return A.primero([
		A.cierto(destinos.has("colores_tuberia") and destinos.has("seguir_lineas"), "el Pañol abre colores y el minijuego: %s" % str(destinos)),
		A.cierto(n == 9, "9 colores: %d" % n),
	])


func test_modulo_10_con_lineas() -> String:
	var m := Contenido.new().sistema(10)
	var lecciones: Array = m["modos"]["aprender"]["lecciones"]
	return A.primero([
		A.cierto(lecciones.slice(lecciones.size() - LECCIONES.size()) == LECCIONES, "las 4 lecciones de líneas al final del módulo 10"),
		A.cierto(Array(m["modos"]["examen"]["minijuegos"]).has("seguir_lineas"), "su minijuego en la evaluación"),
	])


func test_lecciones_se_recorren() -> String:
	var raiz := _raiz()
	var fallos: Array[String] = []
	var bloques := 0
	for id: String in LECCIONES:
		raiz.ir_a("leccion", {"id": id, "sistema": 10})
		var p = raiz.pantalla_actual()
		for n in raiz.contenido.leccion(id)["paginas"].size():
			for l: BloqueLinea in p.find_children("*", "BloqueLinea", true, false):
				bloques += 1
				l.resolver_bien()
			for quiz: BloqueQuiz in p.find_children("*", "BloqueQuiz", true, false):
				if not quiz.get_parent().get_parent().get_parent() is BloqueLinea:
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
		A.cierto(bloques >= 5, "las lecciones traen ejercicios de líneas: %d" % bloques),
	])
