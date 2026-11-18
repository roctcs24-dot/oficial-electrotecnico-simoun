extends RefCounted
## Etapa 40: las 11 lecciones de electrónica desde cero del módulo 8, sus cinco animaciones con
## sus cálculos y las tres prácticas en el Taller.

const A := preload("res://tests/ayuda_sim.gd")
const Colores := preload("res://ui/animaciones/codigo_colores.gd")
const Carga := preload("res://ui/animaciones/carga_condensador.gd")
const Rect := preload("res://ui/animaciones/rectificador.gd")
const Llave := preload("res://ui/animaciones/transistor_llave.gd")
const Lazo := preload("res://ui/animaciones/lazo_4_20.gd")
const LECCIONES := ["el1_senal_potencia", "el2_resistencias", "el3_condensador", "el4_diodo_led", "el5_rectificador",
	"el6_transistor", "el7_conmutacion", "el8_senales_proceso", "el9_logica_digital", "el10_comparador", "el11_tarjetas"]
const ANIMACIONES := ["codigo_colores", "carga_condensador", "rectificador", "transistor_llave", "lazo_4_20"]
const PRACTICAS := ["led_servicio", "puente_servicio", "transistor_servicio"]


func _bloques(c: Contenido) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for id: String in LECCIONES:
		for p: Dictionary in c.leccion(id).get("paginas", []):
			for b: Dictionary in p["bloques"]:
				r.append(b)
	return r


func test_once_lecciones_publicadas_en_orden() -> String:
	var c := Contenido.new()
	var lista: Array = c.sistema(8)["modos"]["aprender"]["lecciones"]
	var fallos: Array[String] = []
	for id: String in LECCIONES:
		var l := c.leccion(id)
		if l.is_empty():
			fallos.append("%s no existe" % id)
			continue
		var preguntas := 0
		for p: Dictionary in l["paginas"]:
			for b: Dictionary in p["bloques"]:
				if b["tipo"] in ["quiz", "ordenar"]:
					preguntas += 1
		if preguntas < 2:
			fallos.append("%s tiene %d preguntas" % [id, preguntas])
		if l["paginas"].size() < 3:
			fallos.append("%s tiene %d páginas" % [id, l["paginas"].size()])
	return A.primero([
		A.cierto(Array(lista) == LECCIONES, "el módulo 8 publica las 11 lecciones en orden: %s" % str(lista)),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
	])


func test_cinco_animaciones_y_tres_practicas() -> String:
	var c := Contenido.new()
	var animaciones := []
	var practicas := []
	for b: Dictionary in _bloques(c):
		if b["tipo"] == "animacion":
			animaciones.append(b["id"])
		elif b["tipo"] == "taller":
			practicas.append(b["plantilla"])
	animaciones.sort()
	practicas.sort()
	var esperadas := ANIMACIONES.duplicate()
	esperadas.sort()
	var esperadas_p := PRACTICAS.duplicate()
	esperadas_p.sort()
	return A.primero([
		A.cierto(animaciones == esperadas, "animaciones: %s" % str(animaciones)),
		A.cierto(practicas == esperadas_p, "prácticas: %s" % str(practicas)),
	])


func test_terminos_nuevos_en_el_glosario() -> String:
	var g := Contenido.new().glosario()
	var faltan: Array[String] = []
	for t in ["senal", "constante_tiempo", "cruce_cero", "pt100", "termocupla", "union_fria", "bit", "binario", "histeresis", "esd", "pulsera_antiestatica"]:
		if not g.has(t):
			faltan.append(t)
	return "" if faltan.is_empty() else "faltan en el glosario: %s" % ", ".join(faltan)


func test_codigo_de_colores() -> String:
	return A.primero([
		A.cerca(Colores.valor(4, 7, 2), 4700.0, 0.01, "amarillo, violeta, rojo"),
		A.cerca(Colores.valor(1, 0, 3), 10000.0, 0.01, "marrón, negro, naranja"),
		A.cerca(Colores.valor(4, 7, -1), 4.7, 0.001, "con multiplicador oro"),
		A.cierto(Colores.texto_ohmios(4700.0) == "4,7 kΩ", "texto: %s" % Colores.texto_ohmios(4700.0)),
		A.cierto(not Colores.color_valido(0, 0), "la primera cifra no puede ser negra"),
		A.cierto(Colores.color_valido(3, 10) and not Colores.color_valido(3, 0), "la tolerancia acepta oro y no negro"),
	])


func test_carga_del_condensador() -> String:
	var tau := Carga.tau(10000.0, 470e-6)
	return A.primero([
		A.cerca(tau, 4.7, 0.001, "τ = 10 kΩ × 470 µF"),
		A.cerca(Carga.tension_carga(24.0, tau, tau), 24.0 * 0.632, 0.05, "en un τ, el 63 %"),
		A.cierto(Carga.tension_carga(24.0, 5.0 * tau, tau) > 23.8, "a las cinco τ, casi cargado"),
		A.cerca(Carga.tension_descarga(24.0, tau, tau), 24.0 * 0.368, 0.05, "al descargar, en un τ queda el 37 %"),
	])


func test_rectificador() -> String:
	var puente := Rect.lectura("puente")
	var media := Rect.lectura("media")
	var filtro := Rect.lectura("filtro")
	var vp := Rect.pico(24.0, 2)
	return A.primero([
		A.cerca(vp, 24.0 * sqrt(2.0) - 1.4, 0.001, "pico del puente"),
		A.cerca(filtro[1], 1.0 / (100.0 * 4700e-6), 0.001, "rizado con 1 A y 4 700 µF"),
		A.cierto(filtro[0] > puente[0] and puente[0] > media[0], "el filtro da más tensión media que el puente, y este más que la media onda"),
		A.cerca(Rect.filtrada(0.25, vp, filtro[1]), vp, 0.01, "en el pico, el condensador está a la tensión de pico"),
		A.cierto(Rect.filtrada(0.49, vp, filtro[1]) >= vp - filtro[1] - 0.01, "entre picos no baja más que el rizado"),
	])


func test_transistor_como_interruptor() -> String:
	var anim: Animacion = Llave.new()
	anim.iniciar({}, null)
	var satura_10k: bool = anim.estado() == "saturado"
	anim.rb_kohm = 220.0
	var activo: bool = anim.estado() == "activo"
	anim.rb_kohm = 10.0
	anim.con_diodo = false
	anim.conmutar_orden()
	var perforado: bool = anim.estado() == "perforado" and anim.rele_cerrado()
	anim.con_diodo = true
	anim.conmutar_orden()
	anim.conmutar_orden()
	var cortado: bool = anim.estado() == "cortado"
	anim.free()
	return A.primero([
		A.cierto(Llave.satura(10000.0) and not Llave.satura(220000.0), "con 10 kΩ satura y con 220 kΩ no"),
		A.cerca(Llave.corriente_bobina(), 0.0375, 0.0001, "la bobina de 640 Ω toma 37,5 mA"),
		A.cierto(satura_10k and activo, "la animación pasa de saturado a zona activa al subir RB"),
		A.cierto(perforado, "sin diodo, quitar la orden perfora el transistor y el relé queda pegado"),
		A.cierto(cortado, "con el diodo, quitar la orden corta"),
	])


func test_lazo_de_4_20_ma() -> String:
	var anim: Animacion = Lazo.new()
	anim.iniciar({}, null)
	anim.presion = 5.0
	var medio: float = anim.ma()
	anim.conmutar_cable()
	var cortado: float = anim.ma()
	anim.free()
	return A.primero([
		A.cerca(Lazo.corriente(0.0, 10.0), 4.0, 0.001, "0 bar son 4 mA"),
		A.cerca(Lazo.corriente(10.0, 10.0), 20.0, 0.001, "10 bar son 20 mA"),
		A.cerca(Lazo.presion_de(12.0, 10.0), 5.0, 0.001, "12 mA son 5 bar"),
		A.cerca(medio, 12.0, 0.001, "a 5 bar el lazo lleva 12 mA"),
		A.cierto(cortado == 0.0, "con el cable cortado, 0 mA"),
	])


func test_las_animaciones_se_dibujan() -> String:
	var arbol := Engine.get_main_loop() as SceneTree
	var fallos: Array[String] = []
	for id: String in ANIMACIONES:
		var guion: GDScript = load("res://ui/animaciones/%s.gd" % id)
		var anim: Animacion = guion.new()
		arbol.root.add_child(anim)
		anim.iniciar({}, Contenido.new())
		anim.size = Vector2(420, 480)
		anim._process(0.5)
		if anim.lienzo == null or anim.get_child_count() < 2:
			fallos.append("%s sin lienzo o sin mandos" % id)
		anim.free()
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_las_lecciones_se_recorren() -> String:
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = "user://pruebas_electronica.json"
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.partida.datos = Partida.datos_nuevos()
	var fallos: Array[String] = []
	for id: String in LECCIONES:
		raiz.ir_a("leccion", {"id": id, "sistema": 8})
		var p = raiz.pantalla_actual()
		var paginas: int = raiz.contenido.leccion(id)["paginas"].size()
		for n in paginas:
			for quiz: BloqueQuiz in p.find_children("*", "BloqueQuiz", true, false):
				quiz.elegir(int(quiz._datos["correcta"]))
			for o: BloqueOrdenar in p.find_children("*", "BloqueOrdenar", true, false):
				for k in o._datos["pasos"].size():
					for b: Node in o._pendientes.get_children():
						if b is Button and b.text == TextoTecnico.unir_unidades(o._datos["pasos"][o._siguiente]):
							(b as Button).pressed.emit()
							break
			if not p.pagina_resuelta():
				fallos.append("%s, página %d sin resolver" % [id, n + 1])
				break
			p.ir_a_pagina(n + 1)
			p = raiz.pantalla_actual()
		if not raiz.partida.leccion_completada(id):
			fallos.append("%s no queda completada" % id)
		raiz.volver()
	raiz.free()
	return "" if fallos.is_empty() else ", ".join(fallos)
