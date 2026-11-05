extends RefCounted
## Examen, repaso espaciado, rangos y traspaso de la partida.

const A := preload("res://tests/ayuda_sim.gd")
const CARPETA := "user://pruebas_progresion/"
const DIA := 86400.0
const RUTA_RAIZ := "user://pruebas_progresion_raiz.json"


func _partida(nombre: String) -> Partida:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var ruta := CARPETA + nombre
	for sufijo in ["", ".bak", ".tmp", ".danada"]:
		if FileAccess.file_exists(ruta + sufijo):
			DirAccess.remove_absolute(ruta + sufijo)
	return Partida.new(ruta)


func _raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_RAIZ + sufijo):
			DirAccess.remove_absolute(RUTA_RAIZ + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_RAIZ
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	return raiz


func _azar(semilla: int) -> RandomNumberGenerator:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	return azar


func test_banco_del_examen_bien_formado() -> String:
	var datos: Dictionary = Contenido.new().leer("examenes/v1.json")
	var temas := {}
	var por_tipo := {}
	for p: Dictionary in datos["preguntas"]:
		if temas.has(p["tema"]):
			return "tema repetido: %s" % p["tema"]
		temas[p["tema"]] = true
		por_tipo[p["tipo"]] = por_tipo.get(p["tipo"], 0) + 1
		if p.get("explicacion", "").is_empty():
			return "%s no explica la respuesta" % p["tema"]
		if p["tipo"] == "ordenar":
			if p["pasos"].size() < 3:
				return "%s necesita al menos tres pasos" % p["tema"]
		elif int(p["correcta"]) >= p["opciones"].size() or p["opciones"].size() < 3:
			return "%s tiene opciones no válidas" % p["tema"]
		if p["tipo"] == "caso" and p.get("caso", "").is_empty():
			return "%s no describe el caso" % p["tema"]
	var composicion: Dictionary = datos["composicion"]
	for tipo: String in ["quiz", "caso", "ordenar"]:
		if por_tipo.get(tipo, 0) < int(composicion[tipo]) * 2:
			return "el banco de %s debe duplicar lo que se pregunta, para variar: %d" % [tipo, por_tipo.get(tipo, 0)]
	return ""


func test_el_banco_no_repite_temas_de_las_lecciones() -> String:
	var c := Contenido.new()
	var lecciones := {}
	for s: Dictionary in c.sistemas():
		for id: String in s.get("modos", {}).get("aprender", {}).get("lecciones", []):
			for pagina: Dictionary in c.leccion(id)["paginas"]:
				for b: Dictionary in pagina["bloques"]:
					if b.has("tema"):
						lecciones[b["tema"]] = true
	for p: Dictionary in c.leer("examenes/v1.json")["preguntas"]:
		if lecciones.has(p["tema"]):
			return "el tema %s ya está en una lección" % p["tema"]
	return ""


func test_examen_respeta_la_composicion_y_no_repite() -> String:
	var c := Contenido.new()
	var datos: Dictionary = c.leer("examenes/v1.json")
	var azar := _azar(7)
	for _i in 20:
		var items := ExamenTeorico.crear(datos, c.simbolos(), azar)
		var cuenta := {}
		var temas := {}
		for item: Dictionary in items:
			cuenta[item["tipo"]] = cuenta.get(item["tipo"], 0) + 1
			if temas.has(item["tema"]):
				return "pregunta repetida: %s" % item["tema"]
			temas[item["tema"]] = true
		for tipo: String in datos["composicion"]:
			if cuenta.get(tipo, 0) != int(datos["composicion"][tipo]):
				return "%s: %d, se esperaba %d" % [tipo, cuenta.get(tipo, 0), int(datos["composicion"][tipo])]
	return ""


func test_calificacion_del_examen() -> String:
	return A.primero([
		A.cierto(ExamenTeorico.estrellas(20, 20, 80.0) == 3, "20 de 20"),
		A.cierto(ExamenTeorico.estrellas(18, 20, 80.0) == 2, "18 de 20"),
		A.cierto(ExamenTeorico.estrellas(16, 20, 80.0) == 1, "16 de 20"),
		A.cierto(ExamenTeorico.estrellas(15, 20, 80.0) == 0, "15 de 20"),
		A.cierto(ExamenTeorico.aprobado(16, 20, 80.0), "16 de 20 aprueba"),
		A.cierto(not ExamenTeorico.aprobado(15, 20, 80.0), "15 de 20 no aprueba"),
		A.cierto(not ExamenTeorico.aprobado(0, 0, 80.0), "sin preguntas no aprueba"),
	])


func test_registrar_examen() -> String:
	var p := _partida("examen.json")
	var suspenso := p.registrar_examen("v1", 50.0, 0, false)
	var primero := p.registrar_examen("v1", 80.0, 1, true)
	var peor := p.registrar_examen("v1", 60.0, 0, false)
	var mejor := p.registrar_examen("v1", 100.0, 3, true)
	var d: Dictionary = p.datos["examenes"]["v1"]
	return A.primero([
		A.cierto(suspenso == 0, "suspender no suma: %d" % suspenso),
		A.cierto(primero == Partida.PUNTOS_EXAMEN + Partida.PUNTOS_ESTRELLA, "primer aprobado: %d" % primero),
		A.cierto(peor == 0, "bajar no suma: %d" % peor),
		A.cierto(mejor == 2 * Partida.PUNTOS_ESTRELLA, "solo suman las estrellas nuevas: %d" % mejor),
		A.cierto(d["aprobado"] and int(d["estrellas"]) == 3 and int(d["intentos"]) == 4, "datos: %s" % str(d)),
		A.cierto(is_equal_approx(d["mejor"], 100.0), "debe conservar la mejor nota"),
	])


func test_intervalos_del_repaso() -> String:
	var p := _partida("repaso.json")
	var t := 1000000.0
	p.registrar_error("a", t)
	var al_fallar := p.temas_pendientes(t)
	p.registrar_repaso("a", true, t)
	var tras_acierto := p.temas_pendientes(t)
	var antes_de_tiempo := p.temas_pendientes(t + DIA - 1.0)
	var al_dia := p.temas_pendientes(t + DIA)
	p.registrar_repaso("a", true, t + DIA)
	var a_los_dos := p.temas_pendientes(t + DIA + 2.0 * DIA)
	var a_los_tres := p.temas_pendientes(t + DIA + 3.0 * DIA)
	return A.primero([
		A.cierto(Array(al_fallar) == ["a"], "al fallar debe quedar pendiente"),
		A.cierto(tras_acierto.is_empty(), "un acierto debe aplazarlo"),
		A.cierto(antes_de_tiempo.is_empty(), "no debe volver antes de un día"),
		A.cierto(al_dia.size() == 1, "debe volver al día siguiente"),
		A.cierto(a_los_dos.is_empty(), "el segundo intervalo es de 3 días"),
		A.cierto(a_los_tres.size() == 1, "debe volver a los 3 días"),
	])


func test_un_fallo_reinicia_el_repaso() -> String:
	var p := _partida("repaso_fallo.json")
	var t := 1000000.0
	p.registrar_error("a", t)
	p.registrar_repaso("a", true, t)
	p.registrar_repaso("a", true, t + DIA)
	p.registrar_repaso("a", false, t + 4.0 * DIA)
	var e: Dictionary = p.datos["errores"]["a"]
	var hoy := p.temas_pendientes(t + 4.0 * DIA)
	var manana := p.temas_pendientes(t + 5.0 * DIA)
	return A.primero([
		A.cierto(int(e["fallos"]) == 2, "debe sumar el fallo: %d" % e["fallos"]),
		A.cierto(int(e["caja"]) == 0, "debe volver al principio"),
		A.cierto(hoy.is_empty(), "no debe repetirse en la misma sesión"),
		A.cierto(manana.size() == 1, "debe volver mañana"),
	])


func test_tema_superado_queda_resuelto_con_sus_fallos() -> String:
	var p := _partida("repaso_fin.json")
	var t := 1000000.0
	p.registrar_error("a", t)
	for i in Partida.INTERVALOS_REPASO_DIAS.size() + 1:
		p.registrar_repaso("a", true, t + float(i) * 100.0 * DIA)
	return A.primero([
		A.cierto(p.temas_pendientes(t + 100000.0 * DIA).is_empty(), "no debe volver"),
		A.cierto(Array(p.temas_mas_fallados(5)) == ["a"], "debe seguir en las estadísticas"),
		A.cierto(p.total_fallos() == 1, "debe conservar sus fallos"),
	])


func test_pendientes_ordenados_por_fallos() -> String:
	var p := _partida("repaso_orden.json")
	p.registrar_error("poco", 10.0)
	p.registrar_error("mucho", 10.0)
	p.registrar_error("mucho", 10.0)
	p.registrar_error("mucho", 10.0)
	return A.cierto(Array(p.temas_pendientes(20.0)) == ["mucho", "poco"], "%s" % str(p.temas_pendientes(20.0)))


func test_partida_antigua_conserva_sus_errores_para_repasar() -> String:
	var p := _partida("antigua.json")
	var f := FileAccess.open(p.ruta, FileAccess.WRITE)
	f.store_string('{"juego":"%s","version":1,"puntos":40,"errores":{"ohm_corriente":{"fallos":2,"ultimo":100.0}}}' % Partida.ID_JUEGO)
	f.close()
	p.cargar()
	var pendientes := p.temas_pendientes(200.0)
	p.registrar_repaso("ohm_corriente", true, 200.0)
	return A.primero([
		A.cierto(pendientes.size() == 1, "un tema antiguo debe quedar pendiente: %s" % str(pendientes)),
		A.cierto(p.temas_pendientes(200.0).is_empty(), "debe poder repasarse"),
		A.cierto(p.datos["examenes"] is Dictionary, "debe recibir el apartado de exámenes"),
	])


func test_todos_los_temas_tienen_pregunta_de_repaso() -> String:
	var c := Contenido.new()
	var banco := BancoRepaso.new(c)
	var guardia := c.leer("guardia.json")
	for tema: String in guardia["faltas"]:
		if not banco.tiene(tema):
			return "la falta %s no tiene pregunta" % tema
	for tipo: String in guardia["accidentes"]:
		if not banco.tiene("accidente_%s" % tipo):
			return "el accidente %s no tiene pregunta" % tipo
	for id: String in c.sistema(3)["modos"]["guardia"]["misiones"]:
		for tema in ["diagnostico_%s" % id, "libro_%s" % id]:
			if not banco.tiene(tema):
				return "falta la pregunta de %s" % tema
	for s: Dictionary in c.simbolos():
		if not banco.tiene("simbolo_%s" % s["id"]):
			return "falta el símbolo %s" % s["id"]
	for p: Dictionary in c.leer("examenes/v1.json")["preguntas"]:
		if not banco.tiene(p["tema"]):
			return "falta el tema del examen %s" % p["tema"]
	return A.cierto(not banco.tiene("no_existe"), "un tema desconocido no debe tener pregunta")


func test_las_preguntas_de_repaso_tienen_respuesta_valida() -> String:
	var c := Contenido.new()
	var banco := BancoRepaso.new(c)
	for tema: String in banco._indice:
		var q := banco.pregunta(tema, _azar(1))
		if q["tipo"] == "ordenar":
			continue
		if int(q["correcta"]) >= q["opciones"].size():
			return "%s: la respuesta no existe" % tema
		if q["explicacion"].is_empty():
			return "%s no explica la respuesta" % tema
	var r := banco.pregunta("simbolo_contacto_na", _azar(2))
	return A.primero([
		A.cierto(r["tipo"] == "simbolo", "debe ser una ronda de símbolo"),
		A.cierto(r["opciones"][r["correcta"]] == "contacto_na", "la respuesta debe ser el símbolo"),
		A.cierto(banco.titulo("simbolo_contacto_na").begins_with("Símbolo:"), "debe tener nombre legible"),
	])


func _puntos_maximos(c: Contenido) -> Dictionary:
	var lecciones := 0
	var misiones := 0
	for s: Dictionary in c.sistemas():
		var modos: Dictionary = s.get("modos", {})
		for id: String in modos.get("aprender", {}).get("lecciones", []):
			lecciones += Partida.PUNTOS_LECCION
			for pagina: Dictionary in c.leccion(id)["paginas"]:
				for b: Dictionary in pagina["bloques"]:
					if b["tipo"] == "quiz" or b["tipo"] == "ordenar":
						lecciones += Partida.PUNTOS_ACIERTO
		for _id: String in modos.get("guardia", {}).get("misiones", []):
			misiones += Partida.PUNTOS_MISION + 3 * Partida.PUNTOS_ESTRELLA
	var evaluaciones := Partida.PUNTOS_EXAMEN + 6 * Partida.PUNTOS_ESTRELLA
	return {"lecciones": lecciones, "misiones": misiones, "evaluaciones": evaluaciones, "total": lecciones + misiones + evaluaciones}


## Con todo el contenido de la v1 debe alcanzarse el rango más alto, pero solo con las lecciones no.
func test_rangos_calibrados_con_el_contenido() -> String:
	var c := Contenido.new()
	var maximos := _puntos_maximos(c)
	var rangos := c.rangos()
	var nombres := []
	var anterior := -1
	for r: Dictionary in rangos:
		nombres.append(r["nombre"])
		if int(r["puntos"]) <= anterior:
			return "los rangos deben ir de menor a mayor"
		anterior = int(r["puntos"])
	var jefe := int(rangos[-1]["puntos"])
	var primera := int(rangos[-2]["puntos"])
	return A.primero([
		A.cierto(nombres == ["Cadete", "Oficial Electrotécnico de 3ra", "Oficial Electrotécnico de 2da", "Oficial Electrotécnico de 1ra", "Jefe Electrotécnico"], "nombres: %s" % str(nombres)),
		A.cierto(maximos["total"] >= jefe, "el rango más alto debe poder alcanzarse: %s, faltan para %d" % [str(maximos), jefe]),
		A.cierto(maximos["lecciones"] < primera, "las lecciones no deben bastar para Oficial de 1ra: %s" % str(maximos)),
		A.cierto(maximos["total"] - maximos["misiones"] < jefe, "sin misiones no debe alcanzarse el rango más alto: %s" % str(maximos)),
		A.cierto(maximos["total"] - maximos["evaluaciones"] < jefe, "sin examen no debe alcanzarse el rango más alto: %s" % str(maximos)),
	])


func test_siguiente_rango() -> String:
	var rangos := [{"nombre": "A", "puntos": 0}, {"nombre": "B", "puntos": 100}]
	var p := _partida("siguiente.json")
	p.datos["puntos"] = 40
	var falta := p.siguiente_rango(rangos)
	p.datos["puntos"] = 100
	return A.primero([
		A.cierto(falta["nombre"] == "B" and int(falta["faltan"]) == 60, "%s" % str(falta)),
		A.cierto(p.siguiente_rango(rangos).is_empty(), "en el último rango no hay siguiente"),
	])


func test_examinar_no_cambia_nada() -> String:
	var bien := Partida.examinar('{"juego":"%s","version":1,"puntos":70}' % Partida.ID_JUEGO)
	var otro := Partida.examinar('{"juego":"otro","version":1}')
	var roto := Partida.examinar("no es json")
	return A.primero([
		A.cierto(bien["motivo"].is_empty() and int(bien["puntos"]) == 70, "%s" % str(bien)),
		A.cierto(not otro["motivo"].is_empty(), "otro juego debe rechazarse"),
		A.cierto(not roto["motivo"].is_empty(), "un texto roto debe rechazarse"),
	])


func _responder_todo(p, acertar: int) -> void:
	var items: Array = p.args["items"]
	for i in items.size():
		var bien := i < acertar
		if items[i]["tipo"] == "ordenar":
			p._al_ordenar(0 if bien else 1, i)
		else:
			var correcta := int(items[i]["correcta"])
			p._al_responder(bien, correcta if bien else (correcta + 1) % items[i]["opciones"].size(), i)
		p.avanzar()
		p = p.raiz.pantalla_actual()


func test_examen_completo_en_pantalla() -> String:
	var raiz := _raiz()
	raiz.ir_a("prueba_examen", {"id": "v1"})
	var p = raiz.pantalla_actual()
	var total: int = p.args["items"].size()
	_responder_todo(p, total)
	var d: Dictionary = raiz.partida.datos["examenes"].get("v1", {})
	var puntos: int = raiz.partida.datos["puntos"]
	var errores: int = raiz.partida.datos["errores"].size()
	raiz.free()
	return A.primero([
		A.cierto(total == 20, "deben ser 20 preguntas: %d" % total),
		A.cierto(d.get("aprobado", false), "debe aprobar: %s" % str(d)),
		A.cierto(puntos == Partida.PUNTOS_EXAMEN + 3 * Partida.PUNTOS_ESTRELLA, "puntos: %d" % puntos),
		A.cierto(errores == 0, "sin fallos no debe haber errores"),
	])


func test_examen_suspendido_alimenta_el_repaso() -> String:
	var raiz := _raiz()
	raiz.ir_a("prueba_examen", {"id": "v1"})
	var p = raiz.pantalla_actual()
	_responder_todo(p, 10)
	var d: Dictionary = raiz.partida.datos["examenes"].get("v1", {})
	var errores: int = raiz.partida.datos["errores"].size()
	var puntos: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.primero([
		A.cierto(not d.get("aprobado", true), "no debe aprobar: %s" % str(d)),
		A.cierto(errores == 10, "los temas fallados deben ir al repaso: %d" % errores),
		A.cierto(puntos == 0, "suspender no suma: %d" % puntos),
	])


func test_contestar_no_se_repite_al_girar() -> String:
	var raiz := _raiz()
	raiz.ir_a("prueba_examen", {"id": "v1"})
	var p = raiz.pantalla_actual()
	var items: Array = p.args["items"]
	var primero: Dictionary = items[0]
	if primero["tipo"] == "ordenar":
		p._al_ordenar(1, 0)
	else:
		p._al_responder(false, (int(primero["correcta"]) + 1) % primero["opciones"].size(), 0)
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var mismo: bool = q.args["items"] == items
	var habilitado: bool = not q._siguiente.disabled
	var fallos: int = raiz.partida.total_fallos()
	raiz.free()
	return A.primero([
		A.cierto(mismo, "girar no debe cambiar las preguntas"),
		A.cierto(habilitado, "debe conservar la respuesta"),
		A.cierto(fallos == 1, "debe contar un solo fallo: %d" % fallos),
	])


func test_repaso_en_pantalla() -> String:
	var raiz := _raiz()
	raiz.partida.registrar_error("ohm_corriente")
	raiz.partida.registrar_error("sin_epp")
	raiz.partida.registrar_error("tema_ya_inexistente")
	raiz.ir_a("repaso")
	var p = raiz.pantalla_actual()
	var cantidad: int = p.args["items"].size()
	_responder_todo(p, 1)
	var fin = raiz.pantalla_actual()
	var pendientes := raiz.partida.temas_pendientes()
	var termino: bool = fin.args["indice"] >= cantidad
	raiz.free()
	return A.primero([
		A.cierto(cantidad == 2, "el tema sin pregunta no debe ofrecerse: %d" % cantidad),
		A.cierto(termino, "debe llegar al final"),
		A.cierto(Array(pendientes) == ["tema_ya_inexistente"], "los repasados deben aplazarse: %s" % str(pendientes)),
	])


func test_repaso_sin_temas_no_falla() -> String:
	var raiz := _raiz()
	raiz.ir_a("repaso")
	var sin_items: bool = not raiz.pantalla_actual().args.has("items")
	raiz.free()
	return A.cierto(sin_items, "sin temas no debe empezar una sesión")


func test_accidente_queda_para_el_repaso() -> String:
	var raiz := _raiz()
	raiz.ir_a("mision", {"id": "g1_no_arranca"})
	raiz.pantalla_actual()._ejecutar("cambiar_k1")
	var hay: bool = raiz.partida.datos["errores"].has("accidente_sin_bloqueo")
	raiz.free()
	return A.cierto(hay, "el accidente debe repasarse")


func test_importar_pide_confirmacion_antes_de_reemplazar() -> String:
	var raiz := _raiz()
	raiz.partida.datos["puntos"] = 200
	raiz.ir_a("progreso")
	var p = raiz.pantalla_actual()
	var texto := '{"juego":"%s","version":1,"puntos":777}' % Partida.ID_JUEGO
	p.recibir_texto(texto)
	var sin_confirmar: int = raiz.partida.datos["puntos"]
	var pendiente: bool = p.args.has("texto_importado")
	p.confirmar_importacion()
	var confirmado: int = raiz.partida.datos["puntos"]
	var q := Partida.new(RUTA_RAIZ)
	q.cargar()
	raiz.free()
	return A.primero([
		A.cierto(sin_confirmar == 200, "no debe cambiar antes de confirmar: %d" % sin_confirmar),
		A.cierto(pendiente, "debe esperar la confirmación"),
		A.cierto(confirmado == 777, "debe reemplazar al confirmar: %d" % confirmado),
		A.cierto(q.datos["puntos"] == 777, "debe quedar guardado"),
	])


func test_importar_un_texto_malo_no_cambia_nada() -> String:
	var raiz := _raiz()
	raiz.partida.datos["puntos"] = 200
	raiz.ir_a("progreso")
	var p = raiz.pantalla_actual()
	p.recibir_texto("esto no es una partida")
	var puntos: int = raiz.partida.datos["puntos"]
	var pendiente: bool = p.args.has("texto_importado")
	var mensaje: String = p.args.get("mensaje", "")
	raiz.free()
	return A.primero([
		A.cierto(puntos == 200, "no debe cambiar la partida"),
		A.cierto(not pendiente, "no debe quedar pendiente"),
		A.cierto(mensaje.begins_with("No se importó"), "debe explicarlo: %s" % mensaje),
	])


func test_exportar_e_importar_desde_la_pantalla() -> String:
	var raiz := _raiz()
	raiz.partida.datos["puntos"] = 321
	raiz.ir_a("progreso")
	var p = raiz.pantalla_actual()
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var archivo := CARPETA + "traspaso.json"
	p.exportar_a(archivo)
	raiz.partida.datos["puntos"] = 5
	p.importar_de(archivo)
	p.confirmar_importacion()
	var puntos: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.cierto(puntos == 321, "debe recuperar la partida del archivo: %d" % puntos)
