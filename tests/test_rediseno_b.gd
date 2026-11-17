extends RefCounted
## Etapa B del rediseño: mímico de los tableros con sus casillas, megóhmetro del mímico, avisos
## con el estilo del marco, alarmas que se tocan y averías de la Guardia como alarmas.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_rediseno_b.json"
const APAISADO := Vector2i(960, 432)
const CLAVES_COMPONENTE := ["motor", "proteccion", "termico", "arrancador", "corriente", "marcha", "paro", "luz_marcha", "luz_paro", "luz_falla", "selector"]


func _raiz(tam := APAISADO) -> Raiz:
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


func _casilla(p, titulo: String) -> CasillaAri:
	for c: CasillaAri in p.mimico.casillas:
		if c.datos.get("titulo", "") == titulo:
			return c
	return null


func test_mimicos_coherentes_con_su_circuito() -> String:
	var c := Contenido.new()
	var con_mimico := 0
	for archivo: String in DirAccess.get_files_at("res://data/tableros"):
		if not archivo.ends_with(".json"):
			continue
		var t := c.tablero(archivo.get_basename())
		if not t.has("mimico"):
			continue
		con_mimico += 1
		var sim := c.circuito(t["circuito"])
		var m: Dictionary = t["mimico"]
		var a: Dictionary = m.get("alimentacion", {})
		if not a.is_empty() and sim.componente(a["componente"]).tipo() != "seccionador":
			return "%s: la casilla de alimentación debe ser un interruptor con candado" % t["id"]
		for id: String in a.get("tierra", []) + ([a["test"]] if a.has("test") else []):
			if not sim.componentes.has(id):
				return "%s: la alimentación usa %s, que no existe" % [t["id"], id]
		for casilla: Dictionary in m.get("casillas", []):
			for clave: String in CLAVES_COMPONENTE:
				if casilla.has(clave) and not sim.componentes.has(str(casilla[clave])):
					return "%s: la casilla %s usa %s, que no existe" % [t["id"], casilla.get("titulo", ""), casilla[clave]]
			for e: Dictionary in casilla.get("elementos", []):
				if not sim.componentes.has(str(e["componente"])):
					return "%s: el mando usa %s, que no existe" % [t["id"], e["componente"]]
			if casilla.has("motor") and sim.componente(casilla["motor"]).tipo() != "motor_trifasico":
				return "%s: %s no es un motor" % [t["id"], casilla["motor"]]
	return A.cierto(con_mimico >= 6, "los tableros con motores llevan mímico: %d" % con_mimico)


func test_el_tablero_se_abre_en_el_mimico() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var p = raiz.pantalla_actual()
	var en_mimico: bool = p.mimico != null and p.mimico.visible and not p.frente.visible
	var casillas: int = p.mimico.casillas.size()
	p.elegir_vista("frente")
	var en_frente: bool = p.frente.visible and not p.mimico.visible
	p.elegir_vista("interior")
	var en_interior: bool = p._caja_mesa.visible and p.args["puerta"]
	p.elegir_vista("mimico")
	var vuelve: bool = p.mimico.visible and not p.args["puerta"]
	raiz.free()
	return A.primero([
		A.cierto(en_mimico, "el tablero empieza en el mímico"),
		A.cierto(casillas == 7, "alimentación, cinco arrancadores y el megóhmetro: %d" % casillas),
		A.cierto(en_frente and en_interior and vuelve, "la barra cambia entre mímico, frente e interior"),
	])


func test_start_en_la_casilla_arranca_la_bomba_y_marca_corriente() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var p = raiz.pantalla_actual()
	var sim: SimSimulacion = p.mesa.sim
	var c := _casilla(p, "ENFRIAM. 1")
	var parada := not c.en_marcha()
	p._al_accionar_casilla(c, "pulsar", ["marcha", 1])
	sim.avanzar_tiempo(0.3)
	p._al_accionar_casilla(c, "soltar", ["marcha", 0])
	sim.avanzar_tiempo(12.0)
	var en_marcha := c.en_marcha()
	var corriente := c.corriente()
	var suelto: bool = not sim.componente("SM1").estado["presionado"]
	p._al_accionar_casilla(c, "pulsar", ["paro", 1])
	sim.avanzar_tiempo(0.3)
	p._al_accionar_casilla(c, "soltar", ["paro", 0])
	sim.avanzar_tiempo(1.0)
	var parada_otra_vez := not (sim.componente("AS1") as SimArrancadorSuave).en_marcha()
	var fondo := c.fondo()
	raiz.free()
	return A.primero([
		A.cierto(parada, "la bomba empieza parada"),
		A.cierto(en_marcha and suelto, "START la arranca y el pulsador vuelve"),
		A.cierto(corriente > 10.0 and corriente < fondo, "el amperímetro marca la corriente: %.1f A de %.0f" % [corriente, fondo]),
		A.cierto(parada_otra_vez, "STOP la para"),
	])


func test_trip_en_la_casilla_y_rearme() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var p = raiz.pantalla_actual()
	var c := _casilla(p, "PRELUB. RED.")
	var q: SimGuardamotor = p.mesa.sim.componente("Q3")
	var antes := c.estado_proteccion()
	q.estado["disparado"] = true
	var disparo := c.estado_proteccion()
	var falla_sin_luz := c.datos.has("luz_falla")
	p._al_accionar_casilla(c, "proteccion", 1)
	var rearmado := c.estado_proteccion()
	p._al_accionar_casilla(c, "proteccion", 1)
	var abierto := c.estado_proteccion()
	raiz.free()
	return A.primero([
		A.cierto(antes == "on" and disparo == "trip", "la casilla muestra ON y luego TRIP: %s, %s" % [antes, disparo]),
		A.cierto(falla_sin_luz, "la casilla tiene la luz de falla térmica del frente"),
		A.cierto(rearmado == "on", "tocar el interruptor tras el disparo lo rearma: %s" % rearmado),
		A.cierto(abierto == "off", "tocarlo otra vez lo abre: %s" % abierto),
	])


func test_toque_en_la_casilla_encuentra_el_mando() -> String:
	var c := CasillaAri.new()
	c.datos = {"titulo": "X", "motor": "M1", "proteccion": "Q1", "marcha": "SM1", "paro": "SP1"}
	c.size = CasillaAri.DISENO * 1.5
	var marcha := c.zona_en(c._p(43, 104))
	var paro := c.zona_en(c._p(20, 102))
	var proteccion := c.zona_en(c._p(78, 140))
	var nada := c.zona_en(c._p(52, 50))
	c.free()
	return A.primero([
		A.cierto(marcha == "marcha" and paro == "paro", "START y STOP bajo el dedo: %s, %s" % [marcha, paro]),
		A.cierto(proteccion == "proteccion", "el interruptor ON/TRIP: %s" % proteccion),
		A.cierto(nada.is_empty(), "el amperímetro no es un mando: %s" % nada),
	])


func test_megohmetro_del_mimico_mide_y_detecta_el_bajo_aislamiento() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var p = raiz.pantalla_actual()
	var sim: SimSimulacion = p.mesa.sim
	var meg: CasillaAri = p.mimico.casilla_megohmetro()
	var m1 := _casilla(p, "ENFRIAM. 1")
	var q0: SimSeccionador = sim.componente("Q0")
	q0.accionar(false)
	q0.poner_candado(true)
	sim.avanzar_tiempo(0.2)
	# Sin averías, la bomba nº 2 da aislamiento bueno.
	p._al_accionar_casilla(m1, "elegir", 1)
	p._al_accionar_casilla(meg, "siguiente", 1)
	var otro: String = meg.megger.get("motor", "")
	p.medir_con_megger()
	var bueno: String = meg.megger.get("veredicto", "")
	# Con el devanado U de la bomba nº 1 a masa, su prueba da aislamiento bajo.
	(sim.componente("M1") as SimMotorTrifasico).params["aislamiento_mohm"] = [0.005, 300.0, 300.0]
	p._al_accionar_casilla(m1, "elegir", 1)
	p._al_accionar_casilla(meg, "fase_U1", 1)
	var r: Dictionary = p.medir_con_megger()
	var bajo: String = meg.megger.get("veredicto", "")
	var marcada := m1.marcada
	p._al_accionar_casilla(meg, "tension", 1)
	var tension: int = p.args["v_prueba"]
	# Un megóhmetro averiado se cambia por uno nuevo al pulsar TEST.
	p.args["megohmetro"].destruido = true
	p.medir_con_megger()
	var nuevo: bool = not p.args["megohmetro"].destruido and meg.megger.get("veredicto", "") == "INSTRUMENTO NUEVO"
	raiz.free()
	return A.primero([
		A.cierto(not r.is_empty() and r["mohm"] < 1.0, "mide el devanado U a masa: %s" % str(r)),
		A.cierto(bajo == "AISLAM. BAJO" and marcada, "la lectura dice aislamiento bajo y marca el motor: %s" % bajo),
		A.cierto(otro == "ENFRIAM. 2" and bueno.contains("BUENO"), "el motor sano da aislamiento bueno: %s, %s" % [otro, bueno]),
		A.cierto(tension == 1000, "el selector pasa de 500 V a 1000 V: %d" % tension),
		A.cierto(nuevo, "un megóhmetro averiado se cambia al pulsar TEST"),
	])


func test_candado_desde_la_casilla_de_alimentacion() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var p = raiz.pantalla_actual()
	var alim: CasillaAri = p.mimico.casillas[0]
	var q0: SimSeccionador = p.mesa.sim.componente("Q0")
	p._al_accionar_casilla(alim, "candado", 1)
	var sin_candado_cerrado: bool = not q0.estado["candado"]
	p._al_accionar_casilla(alim, "seccionador", 1)
	p._al_accionar_casilla(alim, "candado", 1)
	p._al_accionar_casilla(alim, "seccionador", 1)
	var bloqueado: bool = not q0.cerrado() and q0.estado["candado"]
	var tipo := alim.tipo()
	raiz.free()
	return A.primero([
		A.cierto(tipo == "alimentacion", "la primera casilla es la alimentación"),
		A.cierto(sin_candado_cerrado, "con el interruptor cerrado no se pone el candado"),
		A.cierto(bloqueado, "abierto y con candado, no se vuelve a cerrar"),
	])


func test_aviso_con_el_estilo_del_marco() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var p = raiz.pantalla_actual()
	p._mostrar_aviso("Disparo del térmico", "texto", "alarma")
	p._mostrar_aviso("Interruptor bloqueado", "texto")
	var capa: bool = p._avisos is AvisoAri.CapaAvisos
	var tarjeta: bool = p._avisos.get_child_count() == 1 and p._avisos.get_child(0) is AvisoAri
	var alarma: bool = tarjeta and (p._avisos.get_child(0) as AvisoAri).tipo == "alarma"
	var en_cola: int = p._cola_avisos.size()
	p._cerrar_aviso(p._avisos.get_child(0))
	var siguiente: AvisoAri = p._avisos.get_child(0) if p._avisos.get_child_count() > 0 else null
	var evento: bool = siguiente != null and siguiente.tipo == "evento" and siguiente.get_meta("titulo") == "Interruptor bloqueado"
	raiz.free()
	return A.primero([
		A.cierto(capa and tarjeta, "dentro del marco el aviso es una tarjeta ARI sobre una capa"),
		A.cierto(alarma and en_cola == 1, "de uno en uno, con la cabecera roja de alarma"),
		A.cierto(evento, "al reconocerlo sale el siguiente, con cabecera ámbar"),
	])


func test_guardia_muestra_las_averias_como_alarmas_y_tocar_abre_la_mision() -> String:
	var raiz := _raiz()
	raiz.eventos.vaciar()
	raiz.ir_a("guardia", {"id": 3})
	var misiones: Array = raiz.contenido.sistema(3)["modos"]["guardia"]["misiones"]
	var alarmas: Array[Dictionary] = raiz.marco.alarmas_visibles()
	var todas_abren := alarmas.all(func(a: Dictionary) -> bool: return a.has("abrir"))
	var cabecera: String = raiz.marco._cabecera_alarmas.text
	var filas := raiz.marco._lista_alarmas.get_child_count()
	var tocada := raiz.marco.tocar_alarma(0)
	var abierta: bool = raiz.nombre_actual() == "mision" and raiz.args_actuales().get("id", "") == misiones[0]
	raiz.free()
	return A.primero([
		A.cierto(alarmas.size() == misiones.size(), "cada avería pendiente es una alarma: %d de %d" % [alarmas.size(), misiones.size()]),
		A.cierto(todas_abren and filas >= mini(misiones.size(), 6), "las filas se pueden tocar: %d" % filas),
		A.cierto(cabecera == "ALARMAS · %d" % misiones.size(), "la cabecera cuenta las averías: %s" % cabecera),
		A.cierto(tocada and abierta, "tocar la alarma abre su misión"),
	])


func test_alarma_de_otro_panel_lleva_a_su_panel() -> String:
	var raiz := _raiz()
	raiz.eventos.vaciar()
	raiz.ir_a_panel("P-31")
	raiz.pantalla_actual()._mostrar_aviso("Disparo del térmico (Q2)", "texto", "alarma")
	var en_su_panel: bool = not raiz.marco.alarmas_visibles()[0].has("abrir")
	raiz.ir_a_panel("C-21")
	var lleva := false
	for a in raiz.marco.alarmas_visibles():
		if a["texto"] == "Disparo del térmico (Q2)":
			lleva = a.has("abrir")
	var indice := -1
	var lista := raiz.marco.alarmas_visibles()
	for i in lista.size():
		if lista[i]["texto"] == "Disparo del térmico (Q2)":
			indice = i
	raiz.marco.tocar_alarma(indice)
	var vuelve: bool = raiz.marco.codigo == "P-31" if raiz.marco != null else false
	raiz.eventos.vaciar()
	raiz.free()
	return A.primero([
		A.cierto(en_su_panel, "en su propio panel la alarma no lleva a otro sitio"),
		A.cierto(lleva and vuelve, "desde otro panel, tocarla vuelve a P-31"),
	])


func test_estilo_ari_se_duplica_con_sus_colores() -> String:
	var tema := Tema.crear_ari()
	var elegido: EstiloAri = tema.get_stylebox("pressed", "Button")
	var copia: EstiloAri = elegido.duplicate()
	var normal: EstiloAri = tema.get_stylebox("normal", "Button")
	# La altura de 48 la comprueba test_marco_ari con los botones ya en pantalla.
	return A.primero([
		A.cierto(copia.colores == Tema.ARI_AMBAR and copia.borde == elegido.borde, "la copia de la pestaña elegida sigue en ámbar"),
		A.cierto(normal.colores == Tema.ARI_BOTON, "el botón normal es azul"),
		A.cierto(is_equal_approx(copia.content_margin_top, elegido.content_margin_top), "la copia conserva los márgenes"),
	])
