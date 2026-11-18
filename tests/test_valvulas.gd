extends RefCounted
## Etapa 41: válvulas. Catálogo del Pañol, dibujo de cada tipo en sus estados, minijuego
## «¿Abierta o cerrada?», corte de la válvula de bola y lecciones del módulo 10.

const A := preload("res://tests/ayuda_sim.gd")
const Corte := preload("res://ui/animaciones/corte_valvula.gd")
const RUTA_PARTIDA := "user://pruebas_valvulas.json"
const LECCIONES := ["va1_partes", "va2_cuarto_vuelta", "va3_multivuelta", "va4_retencion", "va5_tres_vias", "va6_actuadas", "va7_seguridad_reductoras", "va8_maniobra_segura"]


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
	return Contenido.new().leer("catalogos/valvulas.json")


func test_catalogo_bien_formado() -> String:
	var lista: Array = _catalogo().get("valvulas", [])
	var fallos: Array[String] = []
	var ids := {}
	for v: Dictionary in lista:
		for campo in ["id", "nombre", "en", "familia", "dibujo", "como_saber", "funciona", "a_bordo", "no_usar", "fallas", "mantenimiento"]:
			if not v.has(campo) or str(v[campo]).is_empty():
				fallos.append("%s sin %s" % [v.get("id", "?"), campo])
		if ids.has(v.get("id", "")):
			fallos.append("id repetido %s" % v["id"])
		ids[v.get("id", "")] = true
		if not DibujoValvula.TIPOS.has(v.get("dibujo", "")):
			fallos.append("%s: dibujo desconocido" % v["id"])
		if v.has("minijuego"):
			var j: Dictionary = v["minijuego"]
			for e: Dictionary in j["estados"]:
				if int(e["correcta"]) < 0 or int(e["correcta"]) >= j["opciones"].size():
					fallos.append("%s: estado con respuesta fuera de las opciones" % v["id"])
	return A.primero([
		A.cierto(lista.size() == 11, "el catálogo tiene 11 tipos: %d" % lista.size()),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(str(_catalogo().get("nota", "")).contains("verificar a bordo"), "el catálogo avisa de verificar a bordo"),
	])


func test_cada_tipo_se_dibuja_abierto_y_cerrado() -> String:
	var arbol := Engine.get_main_loop() as SceneTree
	for t: String in DibujoValvula.TIPOS:
		for ap in [0.0, 0.5, 1.0]:
			var d := DibujoValvula.new()
			d.tipo = t
			d.apertura = ap
			d.size = Vector2(360, 260)
			arbol.root.add_child(d)
			d.queue_redraw()
			d.free()
	return ""


func test_rondas_del_minijuego() -> String:
	var azar := RandomNumberGenerator.new()
	azar.seed = 11
	var rondas := JuegoValvulas.crear_rondas(_catalogo(), 10, azar)
	var fallos: Array[String] = []
	var tipos := {}
	for i in rondas.size():
		var r: Dictionary = rondas[i]
		tipos[r["id"]] = true
		if int(r["correcta"]) < 0 or int(r["correcta"]) >= r["opciones"].size():
			fallos.append("ronda %d sin respuesta válida" % i)
		if i > 0 and r["id"] == rondas[i - 1]["id"] and r["apertura"] == rondas[i - 1]["apertura"] and r["via"] == rondas[i - 1]["via"]:
			fallos.append("ronda %d repite la anterior" % i)
		if str(r.get("explicacion", "")).is_empty():
			fallos.append("ronda %d sin explicación" % i)
	return A.primero([
		A.cierto(rondas.size() == 10, "10 rondas: %d" % rondas.size()),
		A.cierto(tipos.size() >= 6, "reparte los tipos: %d distintos" % tipos.size()),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(JuegoValvulas.estrellas(10, 10) == 3 and JuegoValvulas.estrellas(4, 10) == 0, "estrellas como en los símbolos"),
	])


func test_corte_de_la_valvula_de_bola() -> String:
	return A.primero([
		A.cerca(Corte.paso(0.0), 1.0, 0.001, "con la maneta en línea, todo el paso"),
		A.cerca(Corte.paso(90.0), 0.0, 0.001, "cruzada, sin paso"),
		A.cierto(Corte.paso(45.0) > 0.0 and Corte.paso(45.0) < 1.0, "a 45°, a medias"),
		A.cierto(Corte.paso(85.0) == 0.0, "los asientos tapan el agujero antes de los 90°"),
		A.cierto(Corte.estado(0.0) == "abierta" and Corte.estado(90.0) == "cerrada" and Corte.estado(45.0) == "a medias", "estados"),
	])


func test_modulo_10_activo_con_sus_lecciones() -> String:
	var c := Contenido.new()
	var m := c.sistema(10)
	var lecciones: Array = m.get("modos", {}).get("aprender", {}).get("lecciones", [])
	var minijuegos: Array = m.get("modos", {}).get("examen", {}).get("minijuegos", [])
	return A.primero([
		A.cierto(m.get("estado", "") == "activo", "el módulo 10 está activo"),
		A.cierto(Array(lecciones) == LECCIONES, "lecciones: %s" % str(lecciones)),
		A.cierto(minijuegos == ["abierta_cerrada"], "evaluación: %s" % str(minijuegos)),
	])


func test_lecciones_se_recorren() -> String:
	var raiz := _raiz()
	var fallos: Array[String] = []
	for id: String in LECCIONES:
		raiz.ir_a("leccion", {"id": id, "sistema": 10})
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


func test_catalogo_en_pantalla() -> String:
	var raiz := _raiz()
	raiz.ir_a_seccion("panol")
	var p = raiz.pantalla_actual()
	var fila_v: FilaPlaca = p.filas[2]
	fila_v.pulsar()
	var abre: bool = raiz.nombre_actual() == "catalogo"
	var c = raiz.pantalla_actual()
	var tipos: int = c.filas.size()
	(c.filas[3] as FilaPlaca).pulsar()
	var c2 = raiz.pantalla_actual()
	var elegido: String = c2.args["elegido"]
	c2.poner_estado(false)
	var cerrada: bool = c2.dibujo.apertura == 0.0 and c2.dibujo.tipo == "compuerta"
	raiz.vertical = true
	raiz.reconstruir()
	var gira: bool = raiz.pantalla_actual().args["elegido"] == "compuerta" and not raiz.pantalla_actual().args["abierta"]
	raiz.free()
	return A.primero([
		A.cierto(abre, "la fila Válvulas del Pañol abre el catálogo"),
		A.cierto(tipos == 11, "una fila por tipo: %d" % tipos),
		A.cierto(elegido == "compuerta", "tocar una fila la elige: %s" % elegido),
		A.cierto(cerrada, "el botón CERRADA cierra el dibujo"),
		A.cierto(gira, "el elegido y su estado sobreviven al giro"),
	])


func test_minijuego_suma_estrellas() -> String:
	var raiz := _raiz(Vector2i(432, 960))
	raiz.ir_a("abierta_cerrada", {})
	var p = raiz.pantalla_actual()
	var total: int = p.args["items"].size()
	var dibujo_ok: bool = p.find_child("Dibujo", true, false) is DibujoValvula or not p.find_children("*", "FotoPieza", true, false).is_empty()
	for i in total:
		var q = raiz.pantalla_actual()
		var item: Dictionary = q.args["items"][q.args["indice"]]
		q._al_responder(true, int(item["correcta"]), q.args["indice"])
		q.avanzar()
	var estrellas := int(raiz.partida.datos["minijuegos"].get(JuegoValvulas.REGISTRO, {}).get("estrellas", 0))
	var final_ok := raiz.pantalla_actual().find_child("Calificacion", true, false) != null
	raiz.free()
	return A.primero([
		A.cierto(total == 10, "10 rondas: %d" % total),
		A.cierto(dibujo_ok, "cada ronda dibuja la válvula o enseña su foto"),
		A.cierto(estrellas == 3, "todo acertado da 3 estrellas: %d" % estrellas),
		A.cierto(final_ok, "el final muestra la calificación"),
	])


func test_minijuego_en_la_evaluacion_del_modulo() -> String:
	var raiz := _raiz()
	raiz.ir_a("examen", {"id": 10})
	var hay := false
	for f: FilaPlaca in raiz.pantalla_actual().find_children("*", "FilaPlaca", true, false):
		if f.titulo == "¿Abierta o cerrada?":
			hay = true
			f.pulsar()
	var abre := raiz.nombre_actual() == "abierta_cerrada"
	raiz.free()
	return A.primero([
		A.cierto(hay, "el módulo 10 ofrece el minijuego"),
		A.cierto(abre, "y lo abre"),
	])
