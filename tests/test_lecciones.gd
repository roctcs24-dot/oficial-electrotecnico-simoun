extends RefCounted
## Lecciones y glosario: estructura del contenido, cálculos de las animaciones y recorrido.

const A := preload("res://tests/ayuda_sim.gd")
const TIPOS := ["texto", "animacion", "imagen", "quiz", "ordenar"]
const RUTA_PARTIDA := "user://pruebas_lecciones.json"
const Ohm := preload("res://ui/animaciones/circuito_ohm.gd")
const Onda := preload("res://ui/animaciones/onda_alterna.gd")
const Fasores := preload("res://ui/animaciones/fasores.gd")
const Estrella := preload("res://ui/animaciones/estrella.gd")
const Escala := preload("res://ui/animaciones/escala_corriente.gd")
const Glosario := preload("res://ui/screens/glosario.gd")


func _lecciones() -> Array[Dictionary]:
	var c := Contenido.new()
	var lista: Array[Dictionary] = []
	for f in DirAccess.get_files_at("res://data/lecciones"):
		if f.ends_with(".json"):
			lista.append(c.leccion(f.get_basename()))
	return lista


func _validar_bloque(id: String, b: Dictionary, glosario: Dictionary, temas: Dictionary) -> String:
	if not b["tipo"] in TIPOS:
		return "%s: tipo desconocido %s" % [id, b["tipo"]]
	match b["tipo"]:
		"texto":
			for t in TextoTecnico.terminos(b["texto"]):
				if not glosario.has(t):
					return "%s usa un término fuera del glosario: %s" % [id, t]
		"animacion":
			if not FileAccess.file_exists("res://ui/animaciones/%s.gd" % b["id"]):
				return "%s: no existe la animación %s" % [id, b["id"]]
		"imagen":
			if VistaSvg.rasterizar(b["svg"], 0.5) == null:
				return "%s: no se puede dibujar %s" % [id, b["svg"]]
		"quiz", "ordenar":
			if temas.has(b["tema"]):
				return "tema repetido, el repaso los mezclaría: %s" % b["tema"]
			temas[b["tema"]] = true
			if b["explicacion"].is_empty():
				return "%s: la pregunta %s no explica la respuesta" % [id, b["tema"]]
			if JSON.stringify(b).contains("{{"):
				return "%s: los términos {{ }} solo se usan en los textos" % id
			if b["tipo"] == "quiz" and not (int(b["correcta"]) >= 0 and int(b["correcta"]) < b["opciones"].size()):
				return "%s: la respuesta de %s no existe" % [id, b["tema"]]
			if b["tipo"] == "quiz" and b["opciones"].size() < 2:
				return "%s: %s necesita al menos dos opciones" % [id, b["tema"]]
			if b["tipo"] == "ordenar" and b["pasos"].size() < 3:
				return "%s: %s necesita al menos tres pasos" % [id, b["tema"]]
	return ""


func test_lecciones_bien_formadas() -> String:
	var c := Contenido.new()
	var glosario := c.glosario()
	var temas := {}
	var lista := _lecciones()
	if lista.size() < 6:
		return "deben existir las 6 lecciones de fundamentos: hay %d" % lista.size()
	for l in lista:
		if l.get("para_saber_mas", []).is_empty():
			return "%s no tiene Para saber más" % l["id"]
		if int(l["minutos"]) < 3 or int(l["minutos"]) > 5:
			return "%s debe durar de 3 a 5 minutos" % l["id"]
		var preguntas := 0
		for p: Dictionary in l["paginas"]:
			for b: Dictionary in p["bloques"]:
				var motivo := _validar_bloque(l["id"], b, glosario, temas)
				if not motivo.is_empty():
					return motivo
				if b["tipo"] in ["quiz", "ordenar"]:
					preguntas += 1
		if preguntas == 0:
			return "%s no comprueba nada: debe tener preguntas" % l["id"]
	return "; ".join(c.errores)


func test_todas_las_lecciones_estan_publicadas() -> String:
	var c := Contenido.new()
	var publicadas: Array = []
	for s: Dictionary in c.sistemas():
		publicadas.append_array(s["modos"].get("aprender", {}).get("lecciones", []))
	for l in _lecciones():
		if not publicadas.has(l["id"]):
			return "%s no aparece en ningún sistema" % l["id"]
	return ""


func test_glosario_completo() -> String:
	var terminos := Contenido.new().glosario()
	for id: String in terminos:
		for campo in ["es", "en", "def"]:
			if terminos[id].get(campo, "").is_empty():
				return "al término %s le falta %s" % [id, campo]
	return ""


func test_buscar_en_el_glosario() -> String:
	var t := {"es": "tensión de línea", "en": "line voltage"}
	return A.primero([
		A.cierto(Glosario.coincide(t, "tension"), "debe ignorar la tilde"),
		A.cierto(Glosario.coincide(t, "TENSIÓN"), "debe ignorar las mayúsculas"),
		A.cierto(Glosario.coincide(t, "voltage"), "debe buscar en inglés"),
		A.cierto(Glosario.coincide(t, "  "), "sin búsqueda debe mostrarlo"),
		A.cierto(not Glosario.coincide(t, "contactor"), "no debe coincidir con otro término"),
	])


func test_calculos_de_ley_de_ohm() -> String:
	return A.primero([
		A.cerca(Ohm.corriente(440.0, 22.0), 20.0, 0.001, "I = V / R"),
		A.cerca(Ohm.potencia(24.0, 4.8), 120.0, 0.001, "P = V * I"),
		A.cierto(Ohm.corriente(24.0, 0.0) == 0.0, "sin resistencia no debe dividir entre cero"),
	])


func test_valor_de_pico() -> String:
	return A.primero([
		A.cerca(Onda.valor_pico(110.0), 155.56, 0.001, "pico de 110 V"),
		A.cerca(Onda.valor_pico(440.0), 622.25, 0.001, "pico de 440 V"),
	])


func test_las_tres_fases_suman_cero() -> String:
	for grados in [0.0, 17.0, 90.0, 133.0, 250.0]:
		var a := deg_to_rad(grados)
		var suma := Fasores.valor_fase(0, a) + Fasores.valor_fase(1, a) + Fasores.valor_fase(2, a)
		if absf(suma) > 1e-9:
			return "a %s° suman %f" % [grados, suma]
	return ""


func test_estrella_lee_del_motor_de_simulacion() -> String:
	var e: Node = Estrella.new()
	e.iniciar({}, Contenido.new())
	var linea: float = e.lectura("L1", "L2")
	var fase: float = e.lectura("L1", "N")
	e.free()
	return A.primero([
		A.cerca(linea, 380.0, 0.001, "tensión de línea"),
		A.cerca(fase, 219.39, 0.001, "tensión de fase"),
	])


func test_escala_de_corriente_escoge_el_nivel() -> String:
	var niveles := [{"ma": 1, "texto": "a"}, {"ma": 50, "texto": "b"}, {"ma": 200, "texto": "c"}]
	return A.primero([
		A.cierto(Escala.efecto_de(niveles, 0.5) == "a", "por debajo del primer nivel"),
		A.cierto(Escala.efecto_de(niveles, 60.0) == "b", "entre niveles"),
		A.cierto(Escala.efecto_de(niveles, 440.0) == "c", "por encima del último"),
	])


func _ensayar(placa: String, conexion: String, segundos: float) -> EnsayoConexion:
	var ensayo := EnsayoConexion.new(placa, conexion)
	ensayo.avanzar(int(segundos / SimSimulacion.PASO_S))
	return ensayo


func test_ensayo_conexion_correcta_no_dispara() -> String:
	var a := _ensayar("220_380", "estrella", 60.0)
	var b := _ensayar("380_660", "delta", 60.0)
	return A.primero([
		A.cierto(not a.disparo(), "220Δ/380Y en estrella no debe disparar"),
		A.cierto(not b.disparo(), "380Δ/660Y en delta no debe disparar"),
		A.cerca(a.v_devanado, 219.4, 0.02, "tensión de devanado en estrella"),
		A.cerca(b.v_devanado, 380.0, 0.02, "tensión de devanado en delta"),
		A.cierto(EnsayoConexion.diagnostico("220_380", "estrella") == "correcto", "diagnóstico estrella"),
		A.cierto(EnsayoConexion.diagnostico("380_660", "delta") == "correcto", "diagnóstico delta"),
	])


func test_ensayo_conexion_incorrecta_dispara() -> String:
	var exceso := _ensayar("220_380", "delta", 60.0)
	# DURACION_MAXIMA_S de la práctica: debe disparar antes de que esta termine.
	var defecto := _ensayar("380_660", "estrella", 900.0)
	return A.primero([
		A.cierto(exceso.disparo(), "220Δ/380Y en delta debe disparar en 60 s"),
		A.cierto(defecto.disparo(), "380Δ/660Y en estrella a plena carga debe disparar"),
		A.cierto(EnsayoConexion.diagnostico("220_380", "delta") == "exceso", "diagnóstico de exceso"),
		A.cierto(EnsayoConexion.diagnostico("380_660", "estrella") == "defecto", "diagnóstico de defecto"),
	])


func _banco(circuito: String, contactores: Array) -> Node:
	var b: Node = load("res://ui/animaciones/banco_arranque.gd").new()
	b.iniciar({"circuito": circuito, "contactores": contactores}, Contenido.new())
	return b


func test_banco_directo_arranca_con_pico() -> String:
	var b := _banco("arranque_directo", ["K1"])
	b.alternar_q1()
	b.avanzar_pasos(2)
	b.pulsar("S1", true)
	b.avanzar_pasos(4)
	b.pulsar("S1", false)
	b.avanzar_pasos(200)
	var enclavado: bool = b.sim.componente("K1").cerrado()
	var rpm: float = b.sim.componente("M1").rpm()
	var pico: float = b.corriente_maxima()
	b.free()
	return A.primero([
		A.cierto(enclavado, "K1 debe quedar enclavado"),
		A.cierto(rpm > 1400.0, "debe llegar a su velocidad: %.0f" % rpm),
		A.cerca(pico, 29.5 * 6.5, 0.2, "pico de arranque"),
	])


func test_banco_estrella_triangulo_reduce_el_pico() -> String:
	var b := _banco("estrella_triangulo", ["K1", "K2", "K3"])
	b.alternar_q1()
	b.avanzar_pasos(2)
	b.pulsar("S1", true)
	b.avanzar_pasos(4)
	b.pulsar("S1", false)
	b.avanzar_pasos(20)
	var pico_estrella: float = b.corriente_maxima()
	b.avanzar_pasos(180)
	var delta: bool = b.sim.componente("K2").cerrado() and not b.sim.componente("K3").cerrado()
	var rpm: float = b.sim.componente("M1").rpm()
	var disparo: bool = b.sim.hubo_evento("disparo_rele_termico") or b.sim.hubo_evento("disparo_termico")
	b.free()
	return A.primero([
		A.cerca(pico_estrella, 29.5 * 6.5 / 3.0, 0.2, "pico en estrella"),
		A.cierto(delta, "tras el retardo debe quedar en delta"),
		A.cierto(rpm > 1400.0, "debe llegar a su velocidad: %.0f" % rpm),
		A.cierto(not disparo, "un arranque normal no debe disparar protecciones"),
	])


func _banco_generadores(escenario: String) -> Node:
	var b: Node = load("res://ui/animaciones/banco_generadores.gd").new()
	b.iniciar({"escenario": escenario}, Contenido.new())
	return b


## Avanza hasta que la aguja del sincronoscopio entre en [desde, hasta] grados.
func _esperar_angulo(b: Node, desde: float, hasta: float) -> bool:
	for _i in 2000:
		b.avanzar_pasos(1)
		var a: float = absf(b.sim.componente("SY").estado["angulo"])
		if a >= desde and a <= hasta:
			return true
	return false


func test_practica_sincronizar_bien() -> String:
	var b := _banco_generadores("sincronizar")
	var abierto_al_empezar: bool = not b.sim.componente("Q2").cerrado()
	var f_barras: float = b.sim.componente("G1").frecuencia()
	b.velocidad(-1.0)
	b.velocidad(-1.0)
	b.avanzar_pasos(100)
	var desliz: float = b.sim.componente("SY").estado["deslizamiento_hz"]
	var llego := _esperar_angulo(b, 0.0, 5.0)
	b.alternar_q2()
	var cerrado: bool = b.sim.componente("Q2").cerrado()
	var bien: bool = b.sim.hubo_evento("cierre_sincronizado")
	var mensaje: String = b._mensaje.text
	b.free()
	return A.primero([
		A.cierto(abierto_al_empezar, "G2 debe empezar fuera de barras"),
		A.cerca(f_barras, 50.0, 0.005, "las barras deben quedar a 50 Hz"),
		A.cerca(desliz, 0.1, 0.3, "dos toques dejan 0,1 Hz de deslizamiento"),
		A.cierto(llego, "la aguja debe pasar por las doce"),
		A.cierto(cerrado and bien, "cerrar en la ventana debe ser un cierre sincronizado"),
		A.cierto(mensaje.begins_with("Cierre sincronizado"), "debe explicar el resultado: %s" % mensaje),
	])


func test_practica_sincronizar_fuera_de_fase() -> String:
	var b := _banco_generadores("sincronizar")
	var llego := _esperar_angulo(b, 150.0, 180.0)
	b.alternar_q2()
	var disparo: bool = b.sim.hubo_evento("cierre_fuera_de_fase")
	var abierto: bool = not b.sim.componente("Q2").cerrado()
	b.free()
	return A.primero([
		A.cierto(llego, "la aguja debe pasar por las seis"),
		A.cierto(disparo and abierto, "cerrar en oposición debe disparar Q2"),
	])


func test_practica_reparto_de_carga() -> String:
	var b := _banco_generadores("reparto")
	var g1: SimGenerador = b.sim.componente("G1")
	var g2: SimGenerador = b.sim.componente("G2")
	var en_paralelo: bool = b.sim.componente("Q2").cerrado()
	var g2_antes: float = g2.estado["p_kw"]
	var q2_antes: float = g2.estado["q_kvar"]
	for _i in 8:
		b.velocidad(1.0)
		b.velocidad(-1.0, "G1")
	b.avanzar_pasos(300)
	var f: float = g1.frecuencia()
	var g1_kw: float = g1.estado["p_kw"]
	var g2_kw: float = g2.estado["p_kw"]
	for _i in 3:
		b.tension(1.0)
	b.avanzar_pasos(200)
	var q2_despues: float = g2.estado["q_kvar"]
	b.free()
	return A.primero([
		A.cierto(en_paralelo, "G2 debe quedar en paralelo al empezar"),
		A.cierto(absf(g2_antes) < 40.0, "G2 debe empezar casi sin carga: %.0f kW" % g2_antes),
		A.cierto(g2_kw > 100.0 and g1_kw < 250.0, "subir la velocidad de G2 debe pasarle carga: G1 %.0f, G2 %.0f kW" % [g1_kw, g2_kw]),
		A.cerca(g1_kw + g2_kw, 320.0, 0.08, "la carga total no cambia"),
		A.cerca(f, 50.0, 0.005, "subir uno y bajar el otro no cambia la frecuencia"),
		A.cierto(q2_despues > q2_antes + 30.0, "subir la tensión de G2 debe pasarle kVAr: %.0f → %.0f" % [q2_antes, q2_despues]),
	])


func _banco_planta(escenario: String) -> Node:
	var b: Node = load("res://ui/animaciones/banco_planta.gd").new()
	b.iniciar({"escenario": escenario}, Contenido.new())
	return b


func test_practica_ciclo_de_frio() -> String:
	var b := _banco_planta("ciclo")
	var planta: SimPlantaFrio = b.sim.componente("PLANTA")
	var parado: bool = not b.en_marcha()
	var succion_0: float = planta.presion("succion")
	var descarga_0: float = planta.presion("descarga")
	var salmuera_0: float = planta.temperatura("salmuera")
	b.alternar_compresor()
	b.avanzar_segundos(240.0)
	var marcha: bool = b.en_marcha()
	var succion_1: float = planta.presion("succion")
	var descarga_1: float = planta.presion("descarga")
	var salmuera_1: float = planta.temperatura("salmuera")
	b.alternar_compresor()
	b.avanzar_segundos(240.0)
	var parado_al_final: bool = not b.en_marcha()
	var succion_2: float = planta.presion("succion")
	b.free()
	return A.primero([
		A.cierto(parado, "la práctica empieza con el compresor parado"),
		A.cierto(marcha, "arrancar debe dejar el compresor en marcha"),
		A.cierto(succion_1 < succion_0 - 0.5, "la succión debe bajar: %.2f → %.2f bar" % [succion_0, succion_1]),
		A.cierto(descarga_1 > descarga_0 + 2.0, "la descarga debe subir: %.1f → %.1f bar" % [descarga_0, descarga_1]),
		A.cierto(salmuera_1 < salmuera_0 - 3.0, "la salmuera debe enfriarse: %.1f → %.1f °C" % [salmuera_0, salmuera_1]),
		A.cierto(parado_al_final and succion_2 > succion_1, "al parar, la succión debe volver a subir: %.2f → %.2f bar" % [succion_1, succion_2]),
	])


func test_practica_presostato_de_alta() -> String:
	var b := _banco_planta("presostatos")
	var marcha: bool = b.en_marcha()
	b.alternar_bomba("bomba_agua_mar")
	b.avanzar_segundos(300.0)
	var disparo: bool = b.sim.hubo_evento("disparo_presostato")
	var parado: bool = not b.en_marcha()
	var mensaje: String = b._mensaje.text
	var rearme_pronto: bool = (b.sim.componente("PA") as SimPresostato).estado["disparado"]
	b.alternar_bomba("bomba_agua_mar")
	b.avanzar_segundos(300.0)
	b.rearmar_alta()
	var rearmado: bool = not (b.sim.componente("PA") as SimPresostato).estado["disparado"]
	b.free()
	return A.primero([
		A.cierto(marcha, "el escenario empieza con el compresor en marcha"),
		A.cierto(disparo and parado, "sin agua de mar debe disparar un presostato y parar el compresor"),
		A.cierto(mensaje.begins_with("Disparo por alta presión"), "debe explicar el disparo de alta: %s" % mensaje),
		A.cierto(rearme_pronto, "el de alta debe quedar disparado hasta rearmarlo a mano"),
		A.cierto(rearmado, "con el agua de mar de vuelta y la presión baja, debe rearmar"),
	])


func test_practica_presostato_de_baja() -> String:
	var b := _banco_planta("presostatos")
	b.alternar_bomba("bomba_salmuera")
	b.avanzar_segundos(600.0)
	var mensaje: String = b._mensaje.text
	var parado: bool = not b.en_marcha()
	b.free()
	return A.primero([
		A.cierto(parado, "sin salmuera el compresor debe pararse"),
		A.cierto(mensaje.begins_with("Disparo por baja presión"), "debe explicar el disparo de baja: %s" % mensaje),
	])


func test_curva_de_saturacion_del_amoniaco() -> String:
	var s: Node = load("res://ui/animaciones/saturacion_nh3.gd").new()
	s.iniciar({"temperatura": -15.0}, Contenido.new())
	var frio: float = s.presion_relativa()
	s._al_cambiar(35.0)
	var caliente: float = s.presion_relativa()
	var lectura: String = s._lectura.text
	s.free()
	return A.primero([
		A.cerca(frio, 1.35, 0.05, "a −15 °C el amoníaco satura a unos 1,35 bar relativos"),
		A.cerca(caliente, 12.5, 0.05, "a 35 °C satura a unos 12,5 bar relativos"),
		A.cierto(lectura == "35 °C", "el deslizador debe mostrar la temperatura: %s" % lectura),
	])


func test_practica_potencia_inversa() -> String:
	var b := _banco_generadores("reparto")
	for _i in 8:
		b.velocidad(-1.0)
	b.avanzar_pasos(400)
	var disparo: bool = b.sim.hubo_evento("disparo_potencia_inversa")
	var mensaje: String = b._mensaje.text
	b.free()
	return A.primero([
		A.cierto(disparo, "bajar mucho la velocidad de G2 en paralelo debe disparar por potencia inversa"),
		A.cierto(mensaje.begins_with("Disparo por potencia inversa"), "debe explicarlo: %s" % mensaje),
	])


func test_numero_con_coma_decimal() -> String:
	return A.primero([
		A.cierto(TextoTecnico.numero(2.5, 2) == "2,50", "2,50: %s" % TextoTecnico.numero(2.5, 2)),
		A.cierto(TextoTecnico.numero(254.03, 0) == "254", "254: %s" % TextoTecnico.numero(254.03, 0)),
	])


## El número y su unidad no se separan al partir la línea; las palabras normales sí.
func test_numero_y_unidad_no_se_separan() -> String:
	var fijo := TextoTecnico.ESPACIO_FIJO
	var texto := TextoTecnico.expandir("del 10 % al 100 %. Unos −21 °C, 16 bar, 440 V y 5 de ellos.", {}, {})
	return A.cierto(texto == "del 10%s%% al 100%s%%. Unos −21%s°C, 16%sbar, 440%sV y 5 de ellos." % [fijo, fijo, fijo, fijo, fijo], "debe unir solo las unidades: %s" % texto.replace(fijo, "~"))


func _crear_raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	return raiz


func _buscar(nodo: Node, clase: Variant) -> Array:
	var lista := []
	if is_instance_of(nodo, clase):
		lista.append(nodo)
	for hijo in nodo.get_children():
		lista.append_array(_buscar(hijo, clase))
	return lista


## Completa la lección entera. fallar responde mal todas las preguntas tipo test.
func _completar(raiz: Raiz, id: String, fallar: bool) -> void:
	raiz.ir_a("leccion", {"id": id, "sistema": 0})
	var datos := raiz.contenido.leccion(id)
	for n in datos["paginas"].size():
		var p = raiz.pantalla_actual()
		for quiz: BloqueQuiz in _buscar(p, BloqueQuiz):
			var correcta := int(quiz._datos["correcta"])
			quiz.elegir((correcta + 1) % quiz._botones.size() if fallar else correcta)
		for ordenar: BloqueOrdenar in _buscar(p, BloqueOrdenar):
			for paso: String in ordenar._datos["pasos"]:
				for b: Button in ordenar._pendientes.get_children():
					if b.text == paso:
						b.pressed.emit()
						break
		p.ir_a_pagina(n + 1)


func test_no_se_avanza_sin_responder() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("leccion", {"id": "l0_electricidad", "sistema": 0})
	var p = raiz.pantalla_actual()
	var sin_preguntas: bool = p.pagina_resuelta()
	p.ir_a_pagina(1)
	p = raiz.pantalla_actual()
	var antes: bool = p.pagina_resuelta()
	var quiz: BloqueQuiz = _buscar(p, BloqueQuiz)[0]
	quiz.elegir(int(quiz._datos["correcta"]))
	var despues: bool = p.pagina_resuelta()
	raiz.free()
	return A.primero([
		A.cierto(sin_preguntas, "una página sin preguntas no debe bloquear"),
		A.cierto(not antes, "no debe avanzar sin responder"),
		A.cierto(despues, "debe avanzar al responder"),
	])


func test_respuesta_se_conserva_al_girar() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("leccion", {"id": "l0_electricidad", "sistema": 0})
	raiz.pantalla_actual().ir_a_pagina(1)
	var quiz: BloqueQuiz = _buscar(raiz.pantalla_actual(), BloqueQuiz)[0]
	quiz.elegir(0)
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var rehecho: BloqueQuiz = _buscar(raiz.pantalla_actual(), BloqueQuiz)[0]
	var resuelta: bool = raiz.pantalla_actual().pagina_resuelta()
	var bloqueado := rehecho._botones[0].disabled
	raiz.free()
	return A.primero([
		A.cierto(resuelta, "debe seguir contestada"),
		A.cierto(bloqueado, "no debe poder responderse de nuevo"),
	])


func test_completar_suma_puntos_una_sola_vez() -> String:
	var raiz := _crear_raiz()
	_completar(raiz, "l0_electricidad", false)
	var puntos: int = raiz.partida.datos["puntos"]
	var completada := raiz.partida.leccion_completada("l0_electricidad")
	raiz.volver()
	_completar(raiz, "l0_electricidad", false)
	var segunda: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.primero([
		A.cierto(completada, "debe quedar completada"),
		A.cierto(puntos == 30, "20 de la lección y 5 por cada uno de los 2 aciertos: %d" % puntos),
		A.cierto(segunda == puntos, "repetirla no debe sumar más: %d" % segunda),
	])


func test_los_fallos_quedan_para_el_repaso() -> String:
	var raiz := _crear_raiz()
	_completar(raiz, "l0_electricidad", true)
	var errores: Dictionary = raiz.partida.datos["errores"]
	var resultado: Dictionary = raiz.partida.datos["lecciones"]["l0_electricidad"]
	var p := Partida.new(RUTA_PARTIDA)
	p.cargar()
	raiz.free()
	return A.primero([
		A.cierto(errores.has("voltaje_sin_corriente"), "debe anotar el tema fallado"),
		A.cierto(int(resultado["aciertos"]) == 0, "no debe contar aciertos"),
		A.cierto(p.datos["errores"].has("circuito_abierto"), "debe quedar guardado en disco"),
	])


func test_ordenar_cuenta_los_errores() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("leccion", {"id": "l0_loto", "sistema": 0})
	raiz.pantalla_actual().ir_a_pagina(1)
	var o: BloqueOrdenar = _buscar(raiz.pantalla_actual(), BloqueOrdenar)[0]
	var pasos: Array = o._datos["pasos"]
	for b: Button in o._pendientes.get_children():
		if b.text == pasos[4]:
			b.pressed.emit()
			break
	var aviso := not o._aviso.text.is_empty()
	var sin_avance := o._siguiente == 0
	for paso: String in pasos:
		for b: Button in o._pendientes.get_children():
			if b.text == paso:
				b.pressed.emit()
				break
	var fin: bool = raiz.pantalla_actual().pagina_resuelta()
	var anotado: bool = raiz.partida.datos["errores"].has("cinco_reglas")
	raiz.free()
	return A.primero([
		A.cierto(aviso and sin_avance, "un toque equivocado no debe avanzar"),
		A.cierto(fin, "debe poder terminarse"),
		A.cierto(anotado, "el error debe quedar para el repaso"),
	])
