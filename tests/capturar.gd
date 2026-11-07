extends SceneTree
## Guarda imágenes de las pantallas tal como las dibuja el juego, para revisarlas:
##   godot --path . --script res://tests/capturar.gd -- <carpeta de salida> [lecciones|fichas] [sistema]
## No usa --headless porque necesita dibujar. Se excluye de las versiones exportadas.

## La variable CAPTURA_TAMANOS, como "800x1280,1280x800", cambia los tamaños de todas las capturas.
var TAMANOS := [Vector2i(1280, 720), Vector2i(432, 960), Vector2i(960, 432)]
var TAMANOS_LECCIONES := [Vector2i(432, 960), Vector2i(1280, 720)]

var _empezado := false


func _process(_delta: float) -> bool:
	if not _empezado:
		_empezado = true
		_capturar()
	return false


func _capturar() -> void:
	var pedidos := OS.get_environment("CAPTURA_TAMANOS")
	if not pedidos.is_empty():
		TAMANOS = []
		for par in pedidos.split(","):
			TAMANOS.append(Vector2i(par.get_slice("x", 0).to_int(), par.get_slice("x", 1).to_int()))
		TAMANOS_LECCIONES = TAMANOS
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
	elif argumentos.size() > 1 and argumentos[1] == "progresion":
		await _capturar_progresion(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "cuadro":
		await _capturar_cuadro(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "guardia_cuadro":
		await _capturar_guardia_cuadro(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "planta":
		await _capturar_planta(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "guardia_planta":
		await _capturar_guardia_planta(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "plc":
		await _capturar_plc(raiz, carpeta)
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


## El tercer argumento elige el sistema; sin él, los de la v1.
func _sistemas(por_defecto: Array) -> Array:
	var argumentos := OS.get_cmdline_user_args()
	return [int(argumentos[2])] if argumentos.size() > 2 else por_defecto


func _capturar_fichas(raiz: Raiz, carpeta: String) -> void:
	var sistema: int = _sistemas([3])[0]
	for tam: Vector2i in TAMANOS_LECCIONES:
		root.size = tam
		await _esperar()
		for id: String in raiz.contenido.sistema(sistema)["modos"]["aprender"]["fichas"]:
			var vistas := ["real", "simbolos"]
			for n in raiz.contenido.ficha(id).get("dibujos_extra", []).size():
				vistas.append("extra_%d" % n)
			for vista: String in vistas:
				raiz.ir_a("ficha", {"id": id, "vista": vista})
				await _guardar(carpeta, "%s_%s" % [id, vista], tam)
				raiz.volver()
		raiz.ir_a("minijuego_simbolos", {"sistema": sistema})
		await _guardar(carpeta, "minijuego", tam)
		var p = raiz.pantalla_actual()
		p._al_responder(true, int(p.args["rondas"][0]["correcta"]), 0, p.args["rondas"][0])
		await _guardar(carpeta, "minijuego_respondido", tam)
		raiz.volver()
		for s: Dictionary in raiz.contenido.simbolos(sistema):
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
		p._elegir_instrumento("pinza")
		p._al_tocar_cable(6)
		await _guardar(carpeta, "taller_pinza", tam)
		p._elegir_instrumento("multimetro")
		p._al_tocar_borne("B.L1")
		p._al_tocar_borne("B.L2")
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
		p.mesa.sim.componente("M1").estado["temperatura"] = 150.0
		p.vista.mostrar_evento("arco_contactos_soldados", "K1")
		p.vista.mostrar_evento("motor_quemado", "F2")
		p.vista.mostrar_evento("disparo_magnetico", "Q1")
		await RenderingServer.frame_post_draw
		var ruta_efecto := carpeta.path_join("taller_efecto_%dx%d.png" % [tam.x, tam.y])
		root.get_texture().get_image().save_png(ruta_efecto)
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


## G1 en barras y G2 arrancado, algo más rápido, a punto de sincronizar.
func _capturar_cuadro(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("cuadro", {"id": 1})
		var p = raiz.pantalla_actual()
		p._alternar_diesel("G1")
		p._alternar_diesel("G2")
		p.sim.avanzar_tiempo(10.0)
		p._alternar_acb("G1")
		p.sim.componente("G2").estado["f_ref"] = 48.9
		p.sim.avanzar_tiempo(6.0)
		p._revisar_eventos()
		for hijo in p._avisos.get_children():
			p._cerrar_aviso(hijo)
		p._comprobar_firma()
		p._actualizar()
		await _guardar(carpeta, "cuadro_barras", tam)
		for id in ["G1", "G2"]:
			p._elegir_pestana(id)
			await _guardar(carpeta, "cuadro_%s" % id, tam)
		raiz.volver()


## Misiones del cuadro: la pestaña Misión, las lámparas de tierra, el informe y el resultado.
func _capturar_guardia_cuadro(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS_LECCIONES:
		root.size = tam
		await _esperar()
		raiz.ir_a("guardia", {"id": 1})
		await _guardar(carpeta, "guardia_cuadro_lista", tam)
		raiz.volver()
		raiz.ir_a("mision_cuadro", {"id": "gen3_falla_tierra"})
		var p = raiz.pantalla_actual()
		await _guardar(carpeta, "mision_cuadro_reporte", tam)
		p._panel.dar_paso("aviso")
		p._alternar_carga("C4")
		p._panel.bloquear("C4")
		p._desplazables[-1].scroll_vertical = 600
		await _guardar(carpeta, "mision_cuadro_procedimiento", tam)
		p._desplazables[-1].scroll_vertical = 1400
		await _guardar(carpeta, "mision_cuadro_prueba", tam)
		p._alternar_carga("C4")
		if raiz.vertical:
			p._elegir_pestana("barras")
		p._desplazables[0].scroll_vertical = 700
		await _guardar(carpeta, "mision_cuadro_lamparas", tam)
		raiz.volver()
		raiz.ir_a("mision_cuadro", {"id": "gen2_blackout"})
		p = raiz.pantalla_actual()
		p._elegir_pestana("G1")
		await _guardar(carpeta, "mision_cuadro_alarma_g1", tam)
		if raiz.vertical:
			p._elegir_pestana("barras")
		await _esperar()
		p._desplazables[0].scroll_vertical = 2600
		await _guardar(carpeta, "mision_cuadro_emergencia", tam)
		raiz.volver()
		raiz.ir_a("examen", {"id": 1})
		await _guardar(carpeta, "examen_sistema_1", tam)
		raiz.volver()
		raiz.ir_a("ficha", {"id": "generador_emergencia"})
		await _guardar(carpeta, "ficha_generador_emergencia", tam)
		raiz.volver()
		raiz.ir_a("mision_cuadro", {"id": "gen1_paralelo"})
		p = raiz.pantalla_actual()
		p._alternar_acb("G1")
		p._avanzar(20)
		raiz.reconstruir()
		await _guardar(carpeta, "mision_cuadro_incidente", tam)
		raiz.volver()

## PLC de la bomba de achique: el equipo, y el programa con la bomba en marcha y un contacto
## seleccionado para editarlo.
func _capturar_plc(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("plc")
		var p = raiz.pantalla_actual()
		p._pulsar("S1", true)
		for _i in 8:
			p.sim.paso()
		p._pulsar("S1", false)
		p.sim.componente("PT1").params["valor"] = 8.5
		for _i in 4:
			p.sim.paso()
		p._comprobar_firma()
		await _guardar(carpeta, "plc_equipo", tam)
		if raiz.vertical:
			p._elegir_pestana("programa")
		await _guardar(carpeta, "plc_programa", tam)
		p._seleccionar([0, "logica", 1])
		await _esperar()
		p._desplazables[-1].scroll_vertical = 1400
		await _guardar(carpeta, "plc_edicion", tam)
		raiz.volver()


## Misiones de la planta de frío: la lista, la pestaña Misión, la sala con amoníaco y el informe.
func _capturar_guardia_planta(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS_LECCIONES:
		root.size = tam
		await _esperar()
		raiz.ir_a("guardia", {"id": 4})
		await _guardar(carpeta, "guardia_planta_lista", tam)
		raiz.volver()
		raiz.ir_a("mision_planta", {"id": "fr4_fuga_nh3"})
		var p = raiz.pantalla_actual()
		await _guardar(carpeta, "mision_planta_reporte", tam)
		p._panel.dar_paso("evacuar")
		p._panel.dar_paso("aviso")
		p._desplazables[-1].scroll_vertical = 700
		await _guardar(carpeta, "mision_planta_procedimiento", tam)
		p._desplazables[-1].scroll_vertical = 1500
		await _guardar(carpeta, "mision_planta_trabajo", tam)
		p._desplazables[-1].scroll_vertical = 2400
		await _guardar(carpeta, "mision_planta_prueba", tam)
		p._elegir_pestana("seguridad")
		await _guardar(carpeta, "mision_planta_seguridad", tam)
		p._panel.ejecutar("localizar")
		raiz.reconstruir()
		await _guardar(carpeta, "mision_planta_accidente", tam)
		raiz.volver()


## Planta de frío en marcha, con el termómetro en la descarga; después, un disparo por alta.
func _capturar_planta(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("planta", {"id": 4})
		var p = raiz.pantalla_actual()
		p._atender_orden(p.operador.alternar_guardamotor)
		p.sim.avanzar_tiempo(0.1)
		p._pulsar("S1", true)
		p.sim.avanzar_tiempo(0.3)
		p._pulsar("S1", false)
		p.sim.avanzar_tiempo(5.0)
		for _i in 150:
			p.sim.paso(1.0)
		p.args["eventos"] = p.sim.eventos.size()
		p._medir_tuberia("descarga")
		var pestanas: Array = ["esquema", "mando", "ph", "seguridad"] if raiz.vertical else ["mando", "ph", "seguridad"]
		for id: String in pestanas:
			p._elegir_pestana(id)
			await _guardar(carpeta, "planta_%s" % id, tam)
		p._atender_orden(p.operador.alternar_bomba.bind("bomba_agua_mar"))
		for _i in 90:
			p.sim.paso(1.0)
		p._revisar_eventos()
		p._elegir_pestana("mando")
		await _guardar(carpeta, "planta_disparo", tam)
		raiz.volver()


func _capturar_progresion(raiz: Raiz, carpeta: String) -> void:
	raiz.partida.registrar_error("ohm_corriente")
	raiz.partida.registrar_error("sin_epp")
	raiz.partida.registrar_error("simbolo_contacto_na")
	var banco: Dictionary = raiz.contenido.leer("examenes/v1.json")
	var por_tipo := {}
	for q: Dictionary in banco["preguntas"]:
		if not por_tipo.has(q["tipo"]):
			por_tipo[q["tipo"]] = q
	var azar := RandomNumberGenerator.new()
	azar.seed = 3
	var simbolo := JuegoSimbolos.crear_ronda("contacto_na", raiz.contenido.simbolos(), azar)
	simbolo["tipo"] = "simbolo"
	simbolo["tema"] = "simbolo_contacto_na"
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.reconstruir()
		await _guardar(carpeta, "plano", tam)
		for item: Dictionary in [por_tipo["quiz"], por_tipo["caso"], por_tipo["ordenar"], simbolo]:
			raiz.ir_a("prueba_examen", {"id": "v1", "items": [item], "indice": 0, "respuestas": {}})
			await _guardar(carpeta, "examen_%s" % item["tipo"], tam)
			raiz.volver()
		raiz.ir_a("prueba_examen", {"id": "v1", "items": [por_tipo["quiz"], por_tipo["caso"]], "indice": 2, "respuestas": {0: {"acierto": true, "elegida": 0}, 1: {"acierto": false, "elegida": 0}}, "ganados": 0})
		await _guardar(carpeta, "examen_final", tam)
		raiz.volver()
		raiz.ir_a("repaso", {"items": [por_tipo["quiz"]], "indice": 0, "respuestas": {}})
		await _guardar(carpeta, "repaso", tam)
		raiz.volver()
		raiz.ir_a("progreso")
		await _guardar(carpeta, "progreso", tam)
		raiz.pantalla_actual().recibir_texto('{"juego":"%s","version":1,"puntos":777}' % Partida.ID_JUEGO)
		await _guardar(carpeta, "progreso_importar", tam)
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
		for sistema: int in _sistemas([0, 3]):
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
