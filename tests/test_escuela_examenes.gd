extends RefCounted
## Etapa 47: exámenes de la Escuela técnica (v6 y v7, con símbolos ISO 1219), rango «Aspirante»,
## escala calibrada con todo el contenido y la escalera de rangos en «Mi progreso».

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_escuela_examenes.json"


func _raiz(tam := Vector2i(432, 960)) -> Raiz:
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


func test_examenes_publicados_en_los_modulos() -> String:
	var c := Contenido.new()
	var fallos: Array[String] = []
	for par: Array in [[7, "v6"], [8, "v6"], [9, "v7"], [10, "v7"], [11, "v7"]]:
		if not c.sistema(par[0]).get("modos", {}).get("examen", {}).get("examenes", []).has(par[1]):
			fallos.append("el módulo %d debe publicar %s" % par)
	var lista := c.examenes()
	return A.primero([
		A.cierto(lista.has("v6") and lista.has("v7"), "examenes() incluye los de la Escuela: %s" % str(lista)),
		A.cierto(c.examen("v6")["titulo"] == "Examen de la Escuela I" and c.examen("v7")["titulo"] == "Examen de la Escuela II", "títulos"),
		"; ".join(fallos),
	])


func test_el_camino_del_modulo_termina_en_su_examen() -> String:
	var raiz := _raiz()
	raiz.ir_a_seccion("escuela")
	var escuela = raiz.pantalla_actual()
	var pasos_7: Array = escuela._pasos(raiz.contenido.sistema(7))
	var pasos_9: Array = escuela._pasos(raiz.contenido.sistema(9))
	raiz.free()
	return A.primero([
		A.cierto(pasos_7[-1]["tipo"] == "examen" and pasos_7[-1]["id"] == "v6", "el módulo 7 acaba en el examen v6"),
		A.cierto(pasos_9[-1]["tipo"] == "examen" and pasos_9[-1]["id"] == "v7", "el módulo 9 acaba en el examen v7"),
	])


func test_v7_pregunta_simbolos_iso_de_su_familia() -> String:
	var c := Contenido.new()
	var lista := JuegoIso1219.leer(c)
	var azar := RandomNumberGenerator.new()
	azar.seed = 47
	var fallos: Array[String] = []
	for _i in 10:
		var items := ExamenTeorico.crear(c.examen("v7"), [], azar, lista)
		var iso := items.filter(func(x: Dictionary) -> bool: return x["tipo"] == "simbolo_iso")
		if iso.size() != 4 or items.size() != 20:
			fallos.append("composición: %d de 20, %d ISO" % [items.size(), iso.size()])
			break
		for item: Dictionary in iso:
			var s := JuegoIso1219.simbolo(lista, item["id"])
			if item["opciones"][item["correcta"]] != s["nombre"] or not str(item["tema"]).begins_with("iso1219_"):
				fallos.append("%s: la correcta no es su nombre" % item["id"])
			for nombre: String in item["opciones"]:
				var otro := lista.filter(func(o: Dictionary) -> bool: return o["nombre"] == nombre)
				if otro.is_empty() or otro[0]["familia"] != s["familia"]:
					fallos.append("%s ofrece %s, de otra familia" % [item["id"], nombre])
	return "; ".join(fallos)


func test_examen_v7_en_pantalla_y_repaso_de_simbolos() -> String:
	var fallos: Array[String] = []
	for tam in [Vector2i(432, 960), Vector2i(960, 432)]:
		var raiz := _raiz(tam)
		raiz.ir_a("prueba_examen", {"id": "v7"})
		var p = raiz.pantalla_actual()
		var items: Array = p.args["items"]
		var visto_iso := false
		var fallado := ""
		for i in items.size():
			p = raiz.pantalla_actual()
			if items[i]["tipo"] == "simbolo_iso":
				if p.find_child("VisorSimbolo", true, false) == null:
					fallos.append("%s: la pregunta ISO no enseña el símbolo" % str(tam))
				visto_iso = true
			var correcta := int(items[i].get("correcta", 0))
			if items[i]["tipo"] == "ordenar":
				p._al_ordenar(0, i)
			elif items[i]["tipo"] == "simbolo_iso" and fallado.is_empty():
				fallado = items[i]["tema"]
				p._al_responder(false, (correcta + 1) % items[i]["opciones"].size(), i)
			else:
				p._al_responder(true, correcta, i)
			p.avanzar()
		var d: Dictionary = raiz.partida.datos["examenes"].get("v7", {})
		if not visto_iso or not d.get("aprobado", false):
			fallos.append("%s: con 19 de 20 aprueba (%s)" % [str(tam), str(d)])
		if not raiz.partida.datos["errores"].has(fallado):
			fallos.append("el símbolo fallado debe ir al repaso: %s" % fallado)
		raiz.ir_a("repaso")
		var repaso = raiz.pantalla_actual()
		var temas: Array = repaso.args.get("items", []).map(func(x: Dictionary) -> String: return x.get("tema", ""))
		if not temas.has(fallado) or repaso.find_child("VisorSimbolo", true, false) == null:
			fallos.append("%s: el repaso pregunta el símbolo ISO fallado" % str(tam))
		var banco := BancoRepaso.new(raiz.contenido)
		if not banco.titulo(fallado).begins_with("Símbolo ISO 1219"):
			fallos.append("título del tema: %s" % banco.titulo(fallado))
		raiz.free()
	return "; ".join(fallos)


func test_rango_aspirante_y_escala_calibrada() -> String:
	var c := Contenido.new()
	var rangos := c.rangos()
	var m := PuntosJuego.maximos(c)
	var p := Partida.new(RUTA_PARTIDA + ".rango")
	p.datos["puntos"] = 0
	var inicio := p.rango(rangos)
	p.datos["puntos"] = 300
	var cadete := p.rango(rangos)
	var galones := rangos.map(func(r: Dictionary) -> int: return int(r.get("galones", -9)))
	var segunda := int(rangos[3]["puntos"])
	var primera := int(rangos[4]["puntos"])
	var jefe := int(rangos[5]["puntos"])
	return A.primero([
		A.cierto(inicio == "Aspirante" and cadete == "Cadete", "se empieza de Aspirante y a 300 se es Cadete: %s, %s" % [inicio, cadete]),
		A.cierto(galones == [-1, 0, 1, 2, 3, 4], "galones de cada rango: %s" % str(galones)),
		A.cierto(m["lecciones"] >= segunda and m["lecciones"] < primera, "solo con lecciones se llega a 2da y no a 1ra: %s" % str(m)),
		A.cierto(m["total"] >= jefe and m["total"] - m["misiones"] < jefe and m["total"] - m["evaluaciones"] < jefe, "Jefe pide misiones y exámenes: %s" % str(m)),
	])


func test_escalera_en_mi_progreso() -> String:
	var fallos: Array[String] = []
	for tam in [Vector2i(432, 960), Vector2i(960, 432)]:
		var raiz := _raiz(tam)
		raiz.partida.datos["puntos"] = 820
		raiz.ir_a("progreso")
		var vista := raiz.pantalla_actual()
		var filas := 0
		for i in raiz.contenido.rangos().size():
			if vista.find_child("Rango_%d" % i, true, false) != null:
				filas += 1
		var actual: PalaRango = vista.find_child("PalaActual", true, false)
		if filas != 6:
			fallos.append("%s: escalera con %d rangos" % [str(tam), filas])
		if actual == null or actual.galones != 0:
			fallos.append("%s: la pala del rango actual (Cadete) lleva el distintivo" % str(tam))
		if vista.find_child("Puntos_Todo_el_juego", true, false) == null:
			fallos.append("%s: faltan los puntos del juego" % str(tam))
		raiz.free()
	return "; ".join(fallos)
