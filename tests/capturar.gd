extends SceneTree
## Guarda imágenes de las pantallas tal como las dibuja el juego, para revisarlas:
##   godot --path . --script res://tests/capturar.gd -- <carpeta de salida> [lecciones]
## No usa --headless porque necesita dibujar. Se excluye de las versiones exportadas.

const TAMANOS := [Vector2i(1280, 720), Vector2i(432, 960), Vector2i(960, 432)]
const TAMANOS_LECCIONES := [Vector2i(432, 960), Vector2i(1280, 720)]

var _empezado := false


func _process(_delta: float) -> bool:
	if not _empezado:
		_empezado = true
		_capturar()
	return false


func _capturar() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var carpeta: String = argumentos[0] if argumentos.size() > 0 else OS.get_user_data_dir()
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = "user://pruebas_capturas.json"
	root.add_child(raiz)
	if argumentos.size() > 1 and argumentos[1] == "lecciones":
		await _capturar_lecciones(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "fichas":
		await _capturar_fichas(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "taller":
		await _capturar_taller(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "guardia":
		await _capturar_guardia(raiz, carpeta)
	else:
		await _capturar_general(raiz, carpeta)
	quit()


func _capturar_general(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		await _guardar(carpeta, "plano", tam)
		raiz.ir_a("sistema", {"id": 3})
		await _guardar(carpeta, "sistema", tam)
		raiz.volver()
		raiz.ir_a("ficha", {"id": "contactor"})
		await _guardar(carpeta, "ficha", tam)
		raiz.pantalla_actual().pulsar_banco(true)
		await _guardar(carpeta, "ficha_pulsado", tam)
		raiz.pantalla_actual().pulsar_banco(false)
		raiz.volver()
		raiz.ir_a("ficha", {"id": "contactor", "vista": "simbolos"})
		await _guardar(carpeta, "simbolos", tam)
		raiz.volver()


func _capturar_fichas(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS_LECCIONES:
		root.size = tam
		await _esperar()
		for id: String in raiz.contenido.sistema(3)["modos"]["aprender"]["fichas"]:
			var vistas := ["real", "simbolos"]
			for n in raiz.contenido.ficha(id).get("dibujos_extra", []).size():
				vistas.append("extra_%d" % n)
			for vista: String in vistas:
				raiz.ir_a("ficha", {"id": id, "vista": vista})
				await _guardar(carpeta, "%s_%s" % [id, vista], tam)
				raiz.volver()
		raiz.ir_a("minijuego_simbolos")
		await _guardar(carpeta, "minijuego", tam)
		var p = raiz.pantalla_actual()
		p._al_responder(true, int(p.args["rondas"][0]["correcta"]), 0, p.args["rondas"][0])
		await _guardar(carpeta, "minijuego_respondido", tam)
		raiz.volver()
		for s: Dictionary in raiz.contenido.simbolos():
			var r := {"id": s["id"], "norma": "iec", "opciones": [s["id"]], "correcta": 0}
			raiz.ir_a("minijuego_simbolos", {"rondas": [r], "indice": 0, "respuestas": {0: 0}})
			await _guardar(carpeta, "simbolo_%s" % s["id"], tam)
			raiz.volver()


func _capturar_taller(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("taller")
		var p = raiz.pantalla_actual()
		p.mesa.vaciar()
		await _guardar(carpeta, "taller_vacio", tam)
		p._cargar_plantilla("arranque_directo")
		await _guardar(carpeta, "taller_directo", tam)
		p.mesa.sim.componente("Q1").accionar(true)
		p.mesa.avanzar(2)
		p.mesa.sim.componente("S1").estado["presionado"] = true
		p.mesa.avanzar(4)
		p.mesa.sim.componente("S1").estado["presionado"] = false
		p.mesa.avanzar(100)
		p._elegir_pestana("medir")
		p._elegir_instrumento("multimetro")
		p._al_tocar_borne("B.L1")
		p._al_tocar_borne("B.L2")
		await _guardar(carpeta, "taller_multimetro", tam)
		p._al_tocar_pieza("M1")
		await _esperar()
		p = raiz.pantalla_actual()
		await _guardar(carpeta, "taller_pieza", tam)
		p.ordenar_cables()
		await _guardar(carpeta, "taller_ordenado", tam)
		p._al_tocar_cable(10)
		await _guardar(carpeta, "taller_cable", tam)
		p._elegir_pestana("archivo")
		await _guardar(carpeta, "taller_archivo", tam)
		p._mostrar_aviso("Motor quemado", "Ejemplo de explicación tras una consecuencia.")
		await _guardar(carpeta, "taller_aviso", tam)
		p.mesa.vaciar()
		raiz.volver()


func _capturar_guardia(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("guardia", {"id": 3})
		await _guardar(carpeta, "guardia_lista", tam)
		raiz.volver()
		raiz.ir_a("mision", {"id": "g3_bajo_aislamiento"})
		var p = raiz.pantalla_actual()
		await _guardar(carpeta, "mision_reporte", tam)
		p._elegir_pestana("proceso")
		await _guardar(carpeta, "mision_proceso", tam)
		p._desplazable_panel.scroll_vertical = 800
		await _guardar(carpeta, "mision_proceso_abajo", tam)
		p._al_tocar_pieza("M1")
		await _guardar(carpeta, "mision_equipo", tam)
		p._elegir_pestana("medir")
		p._al_tocar_borne("B.L1")
		p._al_tocar_borne("B.L2")
		await _guardar(carpeta, "mision_medir", tam)
		p._elegir_pestana("libro")
		await _guardar(carpeta, "mision_libro_pendiente", tam)
		p.mision.diagnostico_ok = true
		p.mision.prueba_ok = true
		p._reconstruir_panel()
		await _guardar(carpeta, "mision_libro", tam)
		p.mision.fin = "completada"
		p.mision.faltas.append({"tema": "x", "titulo": "Ejemplo de falta", "texto": "Explicación de la falta."})
		raiz.reconstruir()
		await _guardar(carpeta, "mision_resultado", tam)
		raiz.volver()
		raiz.ir_a("mision", {"id": "g3_bajo_aislamiento"})
		p = raiz.pantalla_actual()
		p._ejecutar("retirar_puentes")
		await _guardar(carpeta, "mision_accidente", tam)
		raiz.volver()


func _capturar_lecciones(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS_LECCIONES:
		root.size = tam
		await _esperar()
		raiz.ir_a("aprender", {"id": 0})
		await _guardar(carpeta, "aprender", tam)
		raiz.volver()
		raiz.ir_a("glosario")
		await _guardar(carpeta, "glosario", tam)
		raiz.volver()
		for sistema in [0, 3]:
			for id: String in raiz.contenido.sistema(sistema)["modos"]["aprender"]["lecciones"]:
				for n in raiz.contenido.leccion(id)["paginas"].size():
					raiz.ir_a("leccion", {"id": id, "sistema": sistema, "pagina": n, "respuestas": {}})
					await _guardar(carpeta, "%s_%d" % [id, n], tam)
					raiz.volver()


func _esperar() -> void:
	for _i in 12:
		await process_frame


func _guardar(carpeta: String, nombre: String, tam: Vector2i) -> void:
	await _esperar()
	await RenderingServer.frame_post_draw
	var ruta := carpeta.path_join("%s_%dx%d.png" % [nombre, tam.x, tam.y])
	root.get_texture().get_image().save_png(ruta)
	print(ruta)
