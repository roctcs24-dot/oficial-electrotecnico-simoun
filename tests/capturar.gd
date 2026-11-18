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
	elif argumentos.size() > 1 and argumentos[1] == "sensores":
		await _capturar_sensores(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "red":
		await _capturar_red(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "instrumentos":
		await _capturar_instrumentos(carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "tablero":
		await _capturar_tablero(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "maquina":
		await _capturar_maquina(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "atlas":
		await _capturar_atlas(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "ari":
		await _capturar_ari(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "inicio":
		await _capturar_inicio(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "fichas_d":
		await _capturar_fichas_d(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "herramientas":
		await _capturar_herramientas(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "valvulas":
		await _capturar_valvulas(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "fotos":
		await _capturar_fotos(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "racores":
		await _capturar_racores(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "lineas":
		await _capturar_lineas(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "electronica":
		await _capturar_electronica(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "rediseno_e":
		await _capturar_rediseno_e(raiz, carpeta)
	elif argumentos.size() > 1 and argumentos[1] == "revision":
		await _capturar_revision(raiz, carpeta)
	else:
		await _capturar_general(raiz, carpeta)
	quit()


func _capturar_general(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		await _guardar(carpeta, "inicio", tam)
		raiz.ir_a_seccion("plano_barco")
		await _guardar(carpeta, "plano", tam)
		raiz.ir_a_seccion("inicio")
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


## Tablero de bombas de la máquina principal: frente en marcha y con falla, e interior.
func _capturar_tablero(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("tableros", {"id": 3})
		await _guardar(carpeta, "tableros_lista", tam)
		raiz.ir_a("tablero", {"tablero": "bombas_mp"})
		var p = raiz.pantalla_actual()
		var sim: SimSimulacion = p.mesa.sim
		sim.componente("SM1").estado["presionado"] = true
		sim.avanzar_tiempo(0.3)
		sim.componente("SM1").estado["presionado"] = false
		sim.componente("ORD4").poner("ORDEN")
		sim.componente("M1").params["aislamiento_mohm"] = [0.005, 300.0, 300.0]
		sim.componente("M2").params["bloqueado"] = true
		sim.componente("SM2").estado["presionado"] = true
		sim.avanzar_tiempo(0.3)
		sim.componente("SM2").estado["presionado"] = false
		sim.avanzar_tiempo(30.0)
		sim.componente("ST").estado["presionado"] = true
		sim.avanzar_tiempo(0.2)
		p._reconstruir_panel()
		await _guardar(carpeta, "tablero_frente", tam)
		p._alternar_puerta()
		await _guardar(carpeta, "tablero_interior", tam)
		raiz.volver()
		raiz.volver()
		for id: String in ["hidroforo_salada", "purificadora_1", "servotimon_1", "habitabilidad_110", "distribucion_220", "compresores_nh3"]:
			raiz.ir_a("tablero", {"tablero": id})
			var t = raiz.pantalla_actual()
			var s2: SimSimulacion = t.mesa.sim
			if id == "purificadora_1":
				(s2.componente("Q0") as SimSeccionador).accionar(true)
				(s2.componente("S1") as SimSelector).poner("1")
				s2.componente("K1").estado["energizada"] = true
			if id == "compresores_nh3":
				# El nº 3 en marcha tras su rampa, el nº 4 arrancando y la bomba nº 2 en marcha.
				(s2.componente("ORDC3") as SimSelector).poner("ORDEN")
				s2.componente("SM2").estado["presionado"] = true
				s2.avanzar_tiempo(0.3)
				s2.componente("SM2").estado["presionado"] = false
				s2.avanzar_tiempo(20.0)
				(s2.componente("ORDC4") as SimSelector).poner("ORDEN")
				s2.avanzar_tiempo(0.0)
			s2.avanzar_tiempo(6.0)
			await _guardar(carpeta, "tablero_" + id, tam)
			if id == "compresores_nh3":
				t._alternar_puerta()
				await _guardar(carpeta, "tablero_compresores_nh3_interior", tam)
			raiz.volver()
		await _guardar(carpeta, "plano_con_tableros", tam)


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
		# El Vilter de pistón, con sus solenoides de capacidad y la botella de baja.
		raiz.ir_a("planta", {"id": 4, "circuito": "planta_frio_vilter"})
		p = raiz.pantalla_actual()
		p._atender_orden(p.operador.alternar_guardamotor)
		p.sim.avanzar_tiempo(0.1)
		p._pulsar("S1", true)
		p.sim.avanzar_tiempo(0.3)
		p._pulsar("S1", false)
		for _i in 520:
			p.sim.paso(1.0)
		p.args["eventos"] = p.sim.eventos.size()
		p._comprobar_firma()
		for id: String in (["esquema", "mando"] if raiz.vertical else ["mando"]):
			p._elegir_pestana(id)
			await _guardar(carpeta, "planta_vilter_%s" % id, tam)
		p._desplazables[-1].scroll_vertical = 900
		await _guardar(carpeta, "planta_vilter_botella", tam)
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
					# Si la página tiene una animación, otra captura con ella a la vista.
					var anim := _buscar_animacion(raiz)
					if anim != null:
						var s := _scroll_de(anim)
						if s != null:
							s.ensure_control_visible(anim)
							await _esperar()
							await _guardar(carpeta, "%s_%d_animacion" % [id, n], tam)
					raiz.volver()


func _buscar_animacion(nodo: Node) -> Animacion:
	if nodo is Animacion:
		return nodo
	for hijo in nodo.get_children():
		var a := _buscar_animacion(hijo)
		if a != null:
			return a
	return null


func _scroll_de(nodo: Node) -> ScrollContainer:
	var padre := nodo.get_parent()
	while padre != null and not padre is ScrollContainer:
		padre = padre.get_parent()
	return padre


## Marco de simulador de Guardia y Taller: paneles, panel derecho plegado, hoja en vertical,
## ayuda, índice y leyenda. Por defecto, en el celular apaisado y en vertical.
## Etapa D del rediseño: la ficha con el dibujo grande, las marcas y las pestañas con iconos,
## con atlas y sin él, y el atlas en sus cinco vistas, con algunas ya vistas.
func _capturar_fichas_d(raiz: Raiz, carpeta: String) -> void:
	var p := raiz.partida
	p.datos = Partida.datos_nuevos()
	for pestana: String in ["que_es", "funciona", "conexion"]:
		p.marcar_pestana_atlas("contactor", pestana)
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		await _esperar()
		raiz.ir_a("ficha", {"id": "contactor", "parte": 2})
		await _guardar(carpeta, "d_ficha_contactor", tam)
		raiz.pantalla_actual().elegir_pestana("prueba")
		raiz.pantalla_actual().pulsar_banco(true)
		await _guardar(carpeta, "d_ficha_contactor_prueba", tam)
		raiz.pantalla_actual().pulsar_banco(false)
		raiz.volver()
		raiz.ir_a("ficha", {"id": "contactor", "vista": "simbolos", "pestana": "conexion"})
		await _guardar(carpeta, "d_ficha_contactor_simbolos", tam)
		raiz.volver()
		for id: String in ["alternador", "acb", "compresor_tornillo", "compresor_piston", "motor_trifasico"]:
			raiz.ir_a("ficha", {"id": id})
			await _guardar(carpeta, "d_ficha_%s" % id, tam)
			raiz.volver()
		raiz.ir_a("ficha", {"id": "alternador", "vista": "extra_0", "pestana": "fallas"})
		await _guardar(carpeta, "d_ficha_alternador_extra", tam)
		raiz.volver()
		for pestana: String in ["que_es", "funciona", "conexion", "medir", "fallas"]:
			raiz.ir_a("atlas", {"id": "contactor", "pestana": pestana, "parte": 2})
			await _guardar(carpeta, "d_atlas_contactor_%s" % pestana, tam)
			raiz.volver()
		raiz.ir_a("atlas", {"id": "motor_trifasico", "pestana": "que_es"})
		await _guardar(carpeta, "d_atlas_motor_que_es", tam)
		raiz.volver()


## Etapa C del rediseño: el inicio con el buque visto desde arriba y la Escuela con su camino,
## con una partida de ejemplo que tiene algo hecho, un equipo dañado y temas para repasar.
## Etapa 42: herramientas, tabla de llaves, minijuego «Identifique la herramienta» y lecciones.
func _capturar_herramientas(raiz: Raiz, carpeta: String) -> void:
	raiz.partida.datos = Partida.datos_nuevos()
	var c := raiz.contenido
	var azar := RandomNumberGenerator.new()
	azar.seed = 9
	var rondas := JuegoHerramientas.crear_rondas(c.leer("catalogos/herramientas.json"), c.leer("tablas/llaves.json"), 10, azar)
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a_seccion("panol")
		await _guardar(carpeta, "h_panol", tam)
		raiz.ir_a("tabla_llaves", {"pulgada": "3/4"})
		await _guardar(carpeta, "h_tabla_llaves", tam)
		raiz.volver()
		raiz.ir_a("catalogo", {"catalogo": "herramientas", "elegido": "combinada"})
		await _guardar(carpeta, "h_catalogo", tam)
		raiz.volver()
		raiz.ir_a("identifique_herramienta", {"items": rondas, "indice": 1, "respuestas": {0: {"acierto": true, "elegida": int(rondas[0]["correcta"])}, 1: {"acierto": false, "elegida": (int(rondas[1]["correcta"]) + 1) % 3}}})
		await _guardar(carpeta, "h_identifique", tam)
		raiz.volver()
		var i_llave := -1
		for i in rondas.size():
			if rondas[i]["tipo"] == "llave":
				i_llave = i
		if i_llave >= 0:
			raiz.ir_a("identifique_herramienta", {"items": rondas, "indice": i_llave, "respuestas": {}})
			await _guardar(carpeta, "h_identifique_llave", tam)
			raiz.volver()
		raiz.ir_a_seccion("escuela")
		raiz.pantalla_actual().elegir_modulo(11)
		await _guardar(carpeta, "h_escuela_11", tam)
		for par: Array in [["he1_familias_llaves", 0], ["he2_mm_pulgadas", 0], ["he6_calibre_micrometro", 0]]:
			raiz.ir_a("leccion", {"id": par[0], "sistema": 11, "pagina": par[1], "respuestas": {}})
			await _esperar()
			var anim := _buscar_animacion(raiz)
			if anim != null and raiz.vertical:
				var s := _scroll_de(anim)
				if s != null:
					s.ensure_control_visible(anim)
			await _guardar(carpeta, "h_%s_%d" % [par[0], par[1]], tam)
			raiz.volver()
		raiz.ir_a_seccion("inicio")


## Etapa 41: catálogo de válvulas, minijuego «¿Abierta o cerrada?», lecciones y Pañol.
func _capturar_valvulas(raiz: Raiz, carpeta: String) -> void:
	raiz.partida.datos = Partida.datos_nuevos()
	raiz.partida.datos["lecciones"]["va1_partes"] = {"aciertos": 3, "total": 3}
	var azar := RandomNumberGenerator.new()
	azar.seed = 4
	var rondas := JuegoValvulas.crear_rondas(raiz.contenido.leer("catalogos/valvulas.json"), 10, azar)
	for i in rondas.size():
		if rondas[i]["id"] == "compuerta":
			var r: Dictionary = rondas[i]
			rondas.remove_at(i)
			rondas.insert(3, r)
			break
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a_seccion("panol")
		await _guardar(carpeta, "g_panol", tam)
		raiz.ir_a("catalogo", {"catalogo": "valvulas", "elegido": "bola"})
		await _guardar(carpeta, "g_catalogo_bola", tam)
		raiz.volver()
		raiz.ir_a("catalogo", {"catalogo": "valvulas", "elegido": "actuada", "abierta": false})
		await _guardar(carpeta, "g_catalogo_actuada", tam)
		raiz.volver()
		raiz.ir_a("abierta_cerrada", {"items": rondas, "indice": 3, "respuestas": {0: {"acierto": true, "elegida": 0}, 1: {"acierto": true, "elegida": 0}, 2: {"acierto": false, "elegida": 1}, 3: {"acierto": true, "elegida": int(rondas[3]["correcta"])}}})
		await _guardar(carpeta, "g_abierta_cerrada", tam)
		raiz.volver()
		raiz.ir_a_seccion("escuela")
		raiz.pantalla_actual().elegir_modulo(10)
		await _guardar(carpeta, "g_escuela_10", tam)
		for par: Array in [["va2_cuarto_vuelta", 0], ["va3_multivuelta", 0], ["va5_tres_vias", 0], ["va6_actuadas", 0]]:
			raiz.ir_a("leccion", {"id": par[0], "sistema": 10, "pagina": par[1], "respuestas": {}})
			await _esperar()
			var anim := _buscar_animacion(raiz)
			if anim != null and raiz.vertical:
				var s := _scroll_de(anim)
				if s != null:
					s.ensure_control_visible(anim)
			await _guardar(carpeta, "g_%s_%d" % [par[0], par[1]], tam)
			raiz.volver()
		raiz.ir_a_seccion("inicio")


## Etapa 44: seguir líneas. Minijuego con la línea a medias, aislar con válvulas elegidas y ya
## comprobado, pregunta de servicio, colores de tubería y una lección.
func _capturar_lineas(raiz: Raiz, carpeta: String) -> void:
	var items := JuegoLineas.crear_items(JuegoLineas.leer(raiz.contenido, "purificadora"))
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a("seguir_lineas", {"items": items, "indice": 0, "respuestas": {}, "parcial": {0: {"hechos": ["t1", "t2"], "elegidas": [], "errores": 0}}})
		await _guardar(carpeta, "l_seguir", tam)
		raiz.volver()
		raiz.ir_a("seguir_lineas", {"items": items, "indice": 2, "respuestas": {0: {"acierto": true, "elegida": -1}, 1: {"acierto": true, "elegida": 0}}, "parcial": {2: {"hechos": [], "elegidas": ["v3", "v4"], "errores": 0}}})
		await _guardar(carpeta, "l_aislar", tam)
		raiz.pantalla_actual().bloque.comprobar()
		await _guardar(carpeta, "l_aislar_comprobado", tam)
		raiz.volver()
		raiz.ir_a("seguir_lineas", {"items": items, "indice": 1, "respuestas": {0: {"acierto": true, "elegida": -1}}})
		await _guardar(carpeta, "l_servicio", tam)
		raiz.volver()
		raiz.ir_a("colores_tuberia", {})
		await _guardar(carpeta, "l_colores", tam)
		raiz.volver()
		raiz.ir_a("leccion", {"id": "li4_aislar_equipo", "sistema": 10, "pagina": 0, "respuestas": {}})
		await _esperar()
		await _guardar(carpeta, "l_li4_0", tam)
		raiz.volver()
		raiz.ir_a_seccion("inicio")


## Etapa 43: racores. Catálogo (foto con partes y dibujo), roscas y DN, mangueras, minijuego con
## una ronda de racor, una de DN y una de foto, y dos lecciones.
func _capturar_racores(raiz: Raiz, carpeta: String) -> void:
	var catalogo := raiz.contenido.leer("catalogos/racores.json")
	var tabla := raiz.contenido.leer("tablas/roscas.json")
	var fotos := FotosPiezas.con_pregunta(raiz.contenido.leer(FotosPiezas.ARCHIVO))
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	var lista: Array = catalogo["racores"]
	var rondas := [JuegoRacores.ronda_racor(lista[2], lista, azar), JuegoRacores.ronda_dn(tabla["dn"][5], tabla["dn"], false, azar)]
	for f: Dictionary in fotos:
		if f["id"] == "rosca_teflon":
			rondas.append(JuegoRacores.ronda_foto(f))
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a_seccion("panol")
		await _guardar(carpeta, "r_panol", tam)
		for par: Array in [["latiguillo", 0], ["jic", -1], ["din24", -1], ["brida_sae", -1]]:
			raiz.ir_a("catalogo", {"catalogo": "racores", "elegido": par[0], "foto": par[1]})
			await _guardar(carpeta, "r_catalogo_%s" % par[0], tam)
			raiz.volver()
		raiz.ir_a("roscas_tuberia", {"dn": 50, "medida": "2"})
		await _guardar(carpeta, "r_roscas_dn", tam)
		raiz.volver()
		raiz.ir_a("mangueras", {})
		await _guardar(carpeta, "r_mangueras", tam)
		raiz.volver()
		for i in rondas.size():
			raiz.ir_a("elija_racor", {"items": rondas, "indice": i, "respuestas": {}})
			await _guardar(carpeta, "r_elija_%d" % i, tam)
			raiz.volver()
		for par: Array in [["ra1_familias_racores", 1], ["ra6_latiguillo", 0], ["ra3_dn_nps", 0]]:
			raiz.ir_a("leccion", {"id": par[0], "sistema": 11, "pagina": par[1], "respuestas": {}})
			await _esperar()
			await _guardar(carpeta, "r_%s_%d" % [par[0], par[1]], tam)
			raiz.volver()
		raiz.ir_a_seccion("inicio")


## Fotos a bordo: ronda con foto de «¿Abierta o cerrada?» y fichas del catálogo con foto.
func _capturar_fotos(raiz: Raiz, carpeta: String) -> void:
	var catalogo := raiz.contenido.leer("catalogos/valvulas.json")
	var fotos := FotosPiezas.con_estado(raiz.contenido.leer(FotosPiezas.ARCHIVO))
	var lista := JuegoValvulas.jugables(catalogo)
	var azar := RandomNumberGenerator.new()
	azar.seed = 4
	var rondas := JuegoValvulas.crear_rondas(catalogo, 10, azar)
	for f: Dictionary in fotos:
		if f["id"] == "bray_cerrada":
			rondas[3] = JuegoValvulas.ronda_foto(f, lista)
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a("abierta_cerrada", {"items": rondas, "indice": 3, "respuestas": {0: {"acierto": true, "elegida": 0}, 1: {"acierto": true, "elegida": 0}, 2: {"acierto": false, "elegida": 1}}})
		await _guardar(carpeta, "p_ronda_foto", tam)
		raiz.pantalla_actual()._al_responder(true, 1, 3)
		raiz.reconstruir()
		await _guardar(carpeta, "p_ronda_foto_respondida", tam)
		raiz.volver()
		for par: Array in [["bola", 0], ["bola", 1], ["mariposa", 2], ["globo", 0]]:
			raiz.ir_a("catalogo", {"catalogo": "valvulas", "elegido": par[0], "foto": par[1]})
			await _guardar(carpeta, "p_catalogo_%s_%d" % [par[0], par[1]], tam)
			raiz.volver()
		raiz.ir_a_seccion("inicio")


## Etapa 40: lecciones de electrónica desde cero con sus animaciones, y la Escuela en el módulo 8.
func _capturar_electronica(raiz: Raiz, carpeta: String) -> void:
	raiz.partida.datos = Partida.datos_nuevos()
	for id: String in ["el1_senal_potencia", "el2_resistencias"]:
		raiz.partida.datos["lecciones"][id] = {"aciertos": 2, "total": 2}
	var paginas := [["el2_resistencias", 1], ["el3_condensador", 1], ["el5_rectificador", 0], ["el6_transistor", 1], ["el8_senales_proceso", 0], ["el9_logica_digital", 0]]
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a_seccion("escuela")
		await _esperar()
		raiz.pantalla_actual().elegir_modulo(8)
		await _guardar(carpeta, "f_escuela_8", tam)
		for par: Array in paginas:
			raiz.ir_a("leccion", {"id": par[0], "sistema": 8, "pagina": par[1], "respuestas": {}})
			await _esperar()
			var anim := _buscar_animacion(raiz)
			if anim != null and raiz.vertical:
				var s := _scroll_de(anim)
				if s != null:
					s.ensure_control_visible(anim)
			await _guardar(carpeta, "f_%s_%d" % [par[0], par[1]], tam)
			raiz.volver()
		raiz.ir_a_seccion("inicio")


## Etapa E del rediseño: lección, resultado, examen, repaso y la pantalla «Buque».
func _capturar_rediseno_e(raiz: Raiz, carpeta: String) -> void:
	var p := raiz.partida
	p.datos = Partida.datos_nuevos()
	p.datos["puntos"] = 120
	var mision: String = raiz.contenido.sistema(3)["modos"]["guardia"]["misiones"][0]
	for m: String in raiz.contenido.sistema(3)["modos"]["guardia"]["misiones"]:
		if raiz.contenido.mision(m).has("tablero"):
			mision = m
			break
	p.datos["equipos_danados"][mision] = {"motor": "quemado"}
	for tema: String in ["ex_caso_placa_254", "ohm_corriente", "cortocircuito"]:
		p.registrar_error(tema)
	var banco: Dictionary = raiz.contenido.leer("examenes/v1.json")
	var caso: Dictionary = {}
	for q: Dictionary in banco["preguntas"]:
		if q["tipo"] == "caso" and caso.is_empty():
			caso = q
	var azar := RandomNumberGenerator.new()
	azar.seed = 3
	var simbolo := JuegoSimbolos.crear_ronda("contacto_na", raiz.contenido.simbolos(), azar)
	simbolo["tipo"] = "simbolo"
	simbolo["tema"] = "simbolo_contacto_na"
	var mal: int = (int(simbolo["correcta"]) + 1) % int(simbolo["opciones"].size())
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a_seccion("inicio")
		await _esperar()
		raiz.ir_a("leccion", {"id": "l0_ohm_potencia", "sistema": 0, "pagina": 1, "respuestas": {"0_2": {"acierto": true, "indice": 1}, "1_1": {"acierto": true, "indice": 1}}})
		await _guardar(carpeta, "e_leccion_respondida", tam)
		raiz.volver()
		raiz.ir_a("leccion", {"id": "l0_ohm_potencia", "sistema": 0, "pagina": 0, "respuestas": {}})
		await _guardar(carpeta, "e_leccion_animacion", tam)
		raiz.volver()
		raiz.ir_a("leccion", {"id": "l0_loto", "sistema": 0, "pagina": 1, "respuestas": {}})
		await _guardar(carpeta, "e_leccion_ordenar", tam)
		raiz.volver()
		raiz.ir_a("leccion", {"id": "l0_ohm_potencia", "sistema": 0, "pagina": 3, "respuestas": {"0_2": {"acierto": true, "indice": 1}, "1_1": {"acierto": false, "indice": 0}, "2_2": {"acierto": true, "indice": 2}}, "ganados": 25})
		await _guardar(carpeta, "e_leccion_final", tam)
		raiz.volver()
		var estados := {}
		for i in 6:
			estados[i] = {"acierto": i != 2, "elegida": 0}
		var items := []
		for i in 20:
			items.append(simbolo)
		estados[6] = {"acierto": false, "elegida": mal}
		raiz.ir_a("prueba_examen", {"id": "v1", "items": items, "indice": 6, "respuestas": estados})
		await _guardar(carpeta, "e_examen_simbolo", tam)
		raiz.volver()
		raiz.ir_a("prueba_examen", {"id": "v1", "items": [caso, caso, caso], "indice": 1, "respuestas": {0: {"acierto": true, "elegida": 1}}})
		await _guardar(carpeta, "e_examen_caso", tam)
		raiz.volver()
		var finales := {}
		for i in 20:
			finales[i] = {"acierto": i not in [2, 9, 14], "elegida": 0}
		raiz.ir_a("prueba_examen", {"id": "v1", "items": items.map(func(q: Dictionary) -> Dictionary: return caso), "indice": 20, "respuestas": finales, "ganados": 60})
		await _guardar(carpeta, "e_examen_final", tam)
		raiz.volver()
		raiz.ir_a("repaso", {"items": [caso, caso], "indice": 0, "respuestas": {0: {"acierto": true, "elegida": 1}}})
		await _guardar(carpeta, "e_repaso", tam)
		raiz.volver()
		raiz.ir_a("examen", {"id": 3})
		await _guardar(carpeta, "e_examen_lista", tam)
		raiz.volver()
		raiz.ir_a_seccion("plano_barco")
		await _guardar(carpeta, "e_buque_tableros", tam)
		raiz.pantalla_actual().elegir_capa("sistemas")
		await _guardar(carpeta, "e_buque_sistemas", tam)
		raiz.ir_a_seccion("inicio")


func _capturar_inicio(raiz: Raiz, carpeta: String) -> void:
	var p := raiz.partida
	p.datos = Partida.datos_nuevos()
	p.datos["puntos"] = 120
	for id: String in ["l0_electricidad", "ec1_unidades", "ec2_serie_paralelo", "ec3_caida_tension"]:
		p.datos["lecciones"][id] = {"aciertos": 3, "total": 3}
	for id: String in ["contactor", "rele_termico", "guardamotor", "interruptor_automatico"]:
		for pestana: String in ["que_es", "funciona", "conexion", "medir", "fallas"]:
			p.marcar_pestana_atlas(id, pestana)
	for pestana: String in ["que_es", "funciona", "conexion"]:
		p.marcar_pestana_atlas("diferencial", pestana)
	var mision: String = raiz.contenido.sistema(3)["modos"]["guardia"]["misiones"][0]
	p.datos["misiones"][raiz.contenido.sistema(4)["modos"]["guardia"]["misiones"][0]] = {"completada": true, "estrellas": 2, "intentos": 1, "accidentes": 0}
	p.datos["lecciones"]["d1_transformadores"] = {"aciertos": 2, "total": 2}
	p.datos["equipos_danados"][mision] = {"motor": "quemado"}
	for tema: String in ["loto", "ohm", "estrella_triangulo"]:
		p.registrar_error(tema)
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.ir_a_seccion("inicio")
		await _esperar()
		await _guardar(carpeta, "c_inicio", tam)
		raiz.ir_a_seccion("escuela")
		raiz.pantalla_actual().elegir_modulo(7)
		await _guardar(carpeta, "c_escuela_7", tam)
		raiz.pantalla_actual().elegir_modulo(0)
		await _guardar(carpeta, "c_escuela_0", tam)
		raiz.pantalla_actual().elegir_modulo(8)
		await _guardar(carpeta, "c_escuela_8", tam)
		raiz.pantalla_actual().elegir_modulo(9)
		await _guardar(carpeta, "c_escuela_9", tam)
	p.datos = Partida.datos_nuevos()
	raiz.ir_a_seccion("inicio")
	root.size = Vector2i(960, 432)
	await _esperar()
	await _guardar(carpeta, "c_inicio_nuevo", Vector2i(960, 432))


func _capturar_ari(raiz: Raiz, carpeta: String) -> void:
	var tamanos: Array = TAMANOS if not OS.get_environment("CAPTURA_TAMANOS").is_empty() else [Vector2i(960, 432), Vector2i(432, 960)]
	raiz.eventos.vaciar()
	for tam: Vector2i in tamanos:
		root.size = tam
		raiz.marco_plegado = false
		raiz.ir_a_seccion("plano_barco")
		await _esperar()
		raiz.ir_a("indice_paneles")
		await _guardar(carpeta, "ari_indice", tam)
		raiz.ir_a_panel("P-31")
		raiz.pantalla_actual()._mostrar_aviso("Disparo del térmico (bomba SW 2)", "Prueba de captura.", "alarma")
		await _guardar(carpeta, "ari_p31", tam)
		if raiz.marco.retrato:
			raiz.marco._abrir_hoja()
			await _guardar(carpeta, "ari_p31_hoja", tam)
			raiz.marco._cerrar_hoja()
		else:
			raiz.marco_plegado = true
			raiz.reconstruir()
			await _guardar(carpeta, "ari_p31_plegado", tam)
			raiz.marco_plegado = false
			raiz.reconstruir()
		raiz.marco._mostrar_ayuda()
		await _guardar(carpeta, "ari_p31_ayuda", tam)
		raiz.marco._cerrar_ayuda()
		raiz.ir_a_panel("C-21")
		await _guardar(carpeta, "ari_c21", tam)
		raiz.ir_a_panel("F-41")
		await _guardar(carpeta, "ari_f41", tam)
		raiz.ir_a("guardia", {"id": 3})
		await _guardar(carpeta, "ari_guardia", tam)
		raiz.ir_a("leyenda")
		await _guardar(carpeta, "ari_leyenda", tam)
		# Etapa B: otras vistas del tablero, el megóhmetro, la planta con recirculación, el PLC,
		# la red de alarmas y una misión.
		raiz.ir_a_panel("P-31")
		var t = raiz.pantalla_actual()
		var sim: SimSimulacion = t.mesa.sim
		(sim.componente("M1") as SimMotorTrifasico).params["aislamiento_mohm"] = [0.9, 300.0, 300.0]
		sim.componente("SM2").estado["presionado"] = true
		sim.avanzar_tiempo(0.3)
		sim.componente("SM2").estado["presionado"] = false
		sim.avanzar_tiempo(12.0)
		(sim.componente("Q3") as SimGuardamotor).estado["disparado"] = true
		var q0: SimSeccionador = sim.componente("Q0")
		t.medir_con_megger()
		await _guardar(carpeta, "ari_p31_megger_con_tension", tam)
		t.args["megohmetro"] = SimMegohmetro.new()
		q0.accionar(false)
		q0.poner_candado(true)
		sim.avanzar_tiempo(0.5)
		t.medir_con_megger()
		await _guardar(carpeta, "ari_p31_megger", tam)
		for hijo in t._avisos.get_children():
			t._cerrar_aviso(hijo)
		t.elegir_vista("frente")
		await _guardar(carpeta, "ari_p31_frente", tam)
		raiz.ir_a_panel("P-32")
		await _guardar(carpeta, "ari_p32", tam)
		raiz.ir_a_panel("F-42")
		await _guardar(carpeta, "ari_f42", tam)
		raiz.ir_a_panel("X-81")
		await _guardar(carpeta, "ari_x81", tam)
		raiz.pantalla_actual()._elegir_pestana("red")
		await _guardar(carpeta, "ari_x81_red", tam)
		raiz.pantalla_actual()._elegir_pestana("hmi")
		await _guardar(carpeta, "ari_x81_hmi", tam)
		raiz.ir_a_panel("F-41")
		raiz.pantalla_actual()._elegir_pestana("mando")
		await _guardar(carpeta, "ari_f41_mando", tam)
		raiz.ir_a_panel("X-82")
		await _guardar(carpeta, "ari_x82", tam)
		raiz.ir_a("mision", {"id": "t1_tierra_bombas_mp"})
		await _guardar(carpeta, "ari_mision_t1", tam)
		if not raiz.marco.retrato:
			raiz.marco._abrir_capa_derecha()
			await _guardar(carpeta, "ari_capa_derecha", tam)
		raiz.eventos.vaciar()


func _esperar() -> void:
	for _i in 12:
		await process_frame


## Banco de sensores y PLC del sistema 6 en la mesa del Taller, con la pieza delante.
func _capturar_sensores(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("tableros", {"id": 6})
		await _guardar(carpeta, "sensores_taller_sistema6", tam)
		raiz.ir_a("taller", {"plantilla": "banco_sensores"})
		var p = raiz.pantalla_actual()
		for id in ["B1", "B2"]:
			p.mesa.sim.componente(id).estado["objeto"] = true
		p.mesa.avanzar(6)
		p.args["pieza"] = "PLC"
		p._elegir_pestana("pieza")
		await _guardar(carpeta, "sensores_banco", tam)
		raiz.volver()
		raiz.volver()


## Puesto de alarmas, red RS-485 y pantalla del MYCOM con dos averías.
func _capturar_red(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("red_alarmas")
		var p = raiz.pantalla_actual()
		p.red.aplicar({"op": "ajuste", "equipo": "MY4", "clave": "direccion", "valor": 11})
		p.red.aplicar({"op": "valor", "equipo": "ES1", "registro": 0, "valor": 1})
		for _i in 60:
			p._avanzar(0.5)
		p.puesto.silenciar()
		p._rehacer()
		await _guardar(carpeta, "red_puesto", tam)
		p.args["seleccion"] = "MY4"
		p._elegir_pestana("red")
		p._medir()
		await _guardar(carpeta, "red_bus", tam)
		p._elegir_pestana("hmi")
		await _guardar(carpeta, "red_hmi", tam)
		p.args["pagina_hmi"] = "tendencia"
		p._rehacer()
		await _guardar(carpeta, "red_hmi_tendencia", tam)
		raiz.volver()
		raiz.ir_a("mision_red", {"id": "a3_sentina_sin_comunicacion"})
		await _guardar(carpeta, "red_mision", tam)
		raiz.volver()
		raiz.ir_a("minijuego_simbolos", {"sistema": 6, "registro": "simbolos_electronica"})
		await _guardar(carpeta, "red_simbolos", tam)
		raiz.volver()


## Panel local de la máquina principal: parado y listo, en marcha y por dentro.
func _capturar_maquina(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		raiz.ir_a("tablero", {"tablero": "maquina_principal"})
		var t = raiz.pantalla_actual()
		var sim: SimSimulacion = t.mesa.sim
		sim.avanzar_tiempo(10.0)
		t._reconstruir_panel()
		await _guardar(carpeta, "mp_listo", tam)
		(sim.componente("SRS") as SimSelector).poner("START")
		sim.avanzar_tiempo(0.3)
		(sim.componente("SRS") as SimSelector).soltar()
		sim.avanzar_tiempo(20.0)
		t._reconstruir_panel()
		await _guardar(carpeta, "mp_marcha", tam)
		t._alternar_puerta()
		t.args["pieza"] = "PLC"
		t._elegir_pestana("pieza")
		await _guardar(carpeta, "mp_interior", tam)
		raiz.volver()


## Recorrido por lo añadido en la v4 y la v5: sistemas, misiones de los tableros y el examen.
func _capturar_revision(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		await _guardar(carpeta, "plano", tam)
		for sis in [2, 5, 6]:
			raiz.ir_a("sistema", {"id": sis})
			await _guardar(carpeta, "sistema_%d" % sis, tam)
			raiz.volver()
		for sis in [2, 5]:
			raiz.ir_a("guardia", {"id": sis})
			await _guardar(carpeta, "guardia_%d" % sis, tam)
			raiz.volver()
			raiz.ir_a("examen", {"id": sis})
			await _guardar(carpeta, "examen_%d" % sis, tam)
			raiz.volver()
		for id: String in ["h1_corto_alumbrado", "h3_sobrecarga_cocina", "p1_power_block_no_vira", "p2_mando_se_apaga"]:
			raiz.ir_a("mision", {"id": id})
			var p = raiz.pantalla_actual()
			await _guardar(carpeta, id + "_reporte", tam)
			p._elegir_pestana("proceso")
			await _guardar(carpeta, id + "_proceso", tam)
			p._desplazable_panel.scroll_vertical = 900
			await _guardar(carpeta, id + "_proceso_abajo", tam)
			p._elegir_pestana("pieza")
			await _guardar(carpeta, id + "_equipo", tam)
			p._elegir_pestana("medir")
			await _guardar(carpeta, id + "_medir", tam)
			p._elegir_pestana("libro")
			await _guardar(carpeta, id + "_libro", tam)
			raiz.volver()
		raiz.ir_a("tablero", {"tablero": "power_block"})
		var t = raiz.pantalla_actual()
		var sim: SimSimulacion = t.mesa.sim
		(sim.componente("Q0") as SimSeccionador).accionar(true)
		(sim.componente("S1") as SimSelector).poner("VIRAR")
		sim.avanzar_tiempo(4.0)
		t._reconstruir_panel()
		await _guardar(carpeta, "tablero_power_block", tam)
		t._alternar_puerta()
		await _guardar(carpeta, "tablero_power_block_interior", tam)
		raiz.volver()
		raiz.ir_a("prueba_examen", {"id": "v5"})
		await _guardar(carpeta, "prueba_v5", tam)
		raiz.volver()


## Las fichas visuales del atlas de la Escuela: cada pestaña y los estados que se animan.
func _capturar_atlas(raiz: Raiz, carpeta: String) -> void:
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		# CAPTURA_MODULO elige el módulo de la Escuela (7 si no se dice).
		var modulo := int(OS.get_environment("CAPTURA_MODULO")) if not OS.get_environment("CAPTURA_MODULO").is_empty() else 7
		raiz.ir_a("sistema", {"id": modulo})
		await _guardar(carpeta, "modulo_%d" % modulo, tam)
		raiz.ir_a("aprender", {"id": modulo})
		await _guardar(carpeta, "modulo_%d_aprender" % modulo, tam)
		raiz.volver()
		raiz.volver()
		var ids: Array = raiz.contenido.sistema(modulo)["modos"]["aprender"]["atlas"]
		var solo := OS.get_environment("CAPTURA_ATLAS")
		if not solo.is_empty():
			ids = Array(solo.split(","))
		for id: String in ids:
			for pestana: String in ["que_es", "funciona", "conexion", "medir", "fallas"]:
				raiz.ir_a("atlas", {"id": id, "pestana": pestana})
				await _guardar(carpeta, "%s_%s" % [id, pestana], tam)
				var p = raiz.pantalla_actual()
				if pestana == "funciona":
					var a = p.animacion
					match id:
						"contactor":
							a.poner_tension(false)
							a.campo = 0.0
							a.posicion = 0.0
						"rele_termico", "guardamotor", "interruptor_automatico", "fusible":
							a.poner_corriente(7.2 if id == "rele_termico" else (3.0 if id == "fusible" else 1.5))
							a.avanzar(400.0)
						"diferencial":
							a.poner_fuga(45.0)
							a.avanzar(0.5)
						"seccionador":
							a.accionar(false)
							a.poner_candado(true)
							a.giro = 0.0
						"rele_control_fases":
							a.quitar_fase(true)
							a.avanzar(2.0)
						"monitor_aislamiento":
							a.poner_aislamiento(0.4)
						"rele_auxiliar":
							a.poner_bobina(true)
							a.avanzar(1.0)
						"pulsador":
							a.pulsar()
							a.avanzar(0.3)
						"seta":
							a.enclavar(true)
						"selector":
							a.girar(1)
						"final_carrera":
							a.poner_valor(0.8)
							a.avanzar(1.0)
						"presostato":
							a.poner_valor(17.0)
						"termostato":
							a.poner_valor(-15.0)
						"interruptor_nivel":
							a.poner_valor(0.85)
						"temporizador":
							a.poner_tension(true)
							a.avanzar(6.0)
						"luz_piloto":
							a.elegir(0)
							a.fundir(true)
						"transformador_intensidad":
							a.poner_amperimetro(false)
						"variador":
							a.consigna = 25.0
							a.poner_marcha(true)
							a.avanzar(4.0)
						"resistencia_caldeo":
							a.cortar(true)
						"condensadores":
							a.conectar(false)
						"horometro":
							a.poner_marcha(true)
							a.poner_60_hz(true)
						"bornera":
							a.poner("flojo")
						"resistor":
							a.poner_tension(24.0)
							a.elegir(0)
						"potenciometro":
							a.gastar(true)
							a.poner_posicion(0.5)
						"termistor":
							a.elegir_tipo("ptc")
							a.poner_temperatura(140.0)
						"varistor":
							for _i in 5:
								a.pico()
						"condensador_electrico":
							a.avanzar(30.0)
							a.poner_tension(false)
						"diodo":
							a.girar()
						"diodo_zener":
							a.poner_entrada(10.0)
						"led":
							a.elegir(3)
						"puente_rectificador":
							a.poner_filtro(false)
							a.abrir_diodo(true)
						"transistor":
							a.elegir_rb(1)
							a.poner_orden(true)
						"mosfet":
							a.poner_vgs(5.0)
						"tiristor":
							a.pulsar_puerta()
							a.avanzar(1.0)
						"triac":
							a.poner_puerta(true)
							a.avanzar(1.5)
						"optoacoplador":
							a.unir(true)
							a.pico()
						"rele_estado_solido":
							a.quitar_carga(true)
						"regulador":
							a.poner_disipador(false)
							for _i in 120:
								a.avanzar(0.1)
						"fuente_conmutada":
							a.elegir_carga(2)
							a.avanzar(0.2)
						"operacional":
							a.poner_temperatura(70.0)
						"puerta_logica":
							a.poner(1, 1)
							a.elegir_tipo("xor")
					await _guardar(carpeta, "%s_funciona_2" % id, tam)
				elif pestana == "conexion":
					p.tocar_borne(p.atlas["conexion"]["bornes_esquema"].keys()[0])
					await _guardar(carpeta, "%s_conexion_borne" % id, tam)
				raiz.volver()
			raiz.ir_a("atlas", {"id": id, "pestana": "medir", "grupo_medir": 2})
			await _guardar(carpeta, "%s_medir_3" % id, tam)
			raiz.volver()
			raiz.ir_a("atlas", {"id": id, "pestana": "fallas", "falla": 2})
			await _guardar(carpeta, "%s_fallas_3" % id, tam)
			raiz.volver()


## Hoja de muestra con todos los instrumentos dibujados, a tamaño normal y ampliado.
func _capturar_instrumentos(carpeta: String) -> void:
	for nodo in root.get_children():
		if nodo is Raiz:
			nodo.visible = false
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(fondo)
	var filas := VBoxContainer.new()
	filas.position = Vector2(16, 16)
	fondo.add_child(filas)
	var muestras := [
		["Tensión", "V", 0.0, 500.0, 418.0, 0, 381.0], ["Corriente", "A", 0.0, 1200.0, 860.0, 0, 596.0],
		["Potencia", "kW", -90.0, 588.0, 452.0, 0, 312.0], ["Frecuencia", "Hz", 45.0, 55.0, 52.5, 2, 50.02],
		["NH3", "ppm", 0.0, 300.0, 150.0, 0, 25.0], ["Succión", "bar", -1.0, 6.0, INF, 2, 1.17],
		["Descarga", "bar", 0.0, 25.0, 16.0, 1, 12.0], ["Aceite (dif.)", "bar", 0.0, 6.0, INF, 1, 2.8],
		["Salmuera", "°C", -25.0, 10.0, INF, 1, -18.5],
	]
	for escala_hoja: float in [1.0, 1.6]:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		filas.add_child(fila)
		for m: Array in muestras.slice(0, 9 if escala_hoja == 1.0 else 6):
			var instrumento := InstrumentoAguja.new().configurar(m[0], m[1], m[2], m[3], m[4], m[5])
			instrumento.custom_minimum_size *= escala_hoja
			instrumento.valor = m[6]
			fila.add_child(instrumento)
	var abajo := HBoxContainer.new()
	abajo.add_theme_constant_override("separation", 16)
	filas.add_child(abajo)
	var dial := DialSincronoscopio.new()
	var brillos: Array[float] = [0.1, 0.6, 1.0]
	dial.actualizar(-30.0, true, brillos)
	abajo.add_child(dial)
	for par: Array in [[LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO, true], [LuzPiloto.ROJO_APAGADO, LuzPiloto.ROJO_ENCENDIDO, true],
			[LuzPiloto.AMBAR_APAGADO, LuzPiloto.AMBAR_ENCENDIDO, true], [LuzPiloto.VERDE_APAGADO, LuzPiloto.VERDE_ENCENDIDO, false]]:
		var luz := LuzPiloto.new()
		luz.color_apagado = par[0]
		luz.color_encendido = par[1]
		luz.encendida = par[2]
		luz.custom_minimum_size = Vector2(64, 64)
		abajo.add_child(luz)
	var tam := Vector2i(1600, 900)
	root.size = tam
	await _guardar(carpeta, "instrumentos", tam)


func _guardar(carpeta: String, nombre: String, tam: Vector2i) -> void:
	await _esperar()
	await RenderingServer.frame_post_draw
	var ruta := carpeta.path_join("%s_%dx%d.png" % [nombre, tam.x, tam.y])
	root.get_texture().get_image().save_png(ruta)
	print(ruta)
