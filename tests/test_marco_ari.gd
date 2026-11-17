extends RefCounted
## Marco de simulador de Guardia y Taller: índice de paneles, navegación por códigos, panel
## derecho plegable, hoja en vertical, generación, eventos y alarmas, leyenda y contraste.

const A := preload("res://tests/ayuda_sim.gd")
const P := preload("res://tests/test_pantallas.gd")
const RUTA_PARTIDA := "user://pruebas_marco.json"
const APAISADO := Vector2i(960, 432)
const VERTICAL := Vector2i(432, 960)


func _raiz(tam := APAISADO) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	_tamano(raiz, tam)
	return raiz


## Fija el tamaño sin depender de la ventana: así la prueba es igual en cualquier equipo.
func _tamano(raiz: Raiz, tam: Vector2i) -> void:
	raiz.set_anchors_preset(Control.PRESET_TOP_LEFT)
	raiz.size = Vector2(tam)
	raiz._al_cambiar_tamano()
	raiz.reconstruir()


func _buscar(nodo: Node, nombre: String) -> Node:
	if nodo.name == nombre:
		return nodo
	for hijo in nodo.get_children():
		var r := _buscar(hijo, nombre)
		if r != null:
			return r
	return null


func _contar(nodo: Node, clase: Script) -> int:
	var n := 1 if is_instance_of(nodo, clase) else 0
	for hijo in nodo.get_children():
		n += _contar(hijo, clase)
	return n


func test_marco_solo_en_guardia_y_taller() -> String:
	var raiz := _raiz()
	var en_inicio := raiz.marco != null
	raiz.ir_a("tablero", {"tablero": "bombas_mp"})
	var en_tablero := raiz.marco != null
	var codigo := raiz.marco.codigo if raiz.marco != null else ""
	raiz.ir_a("guardia", {"id": 3})
	var en_guardia := raiz.marco != null
	raiz.ir_a_seccion("escuela")
	var en_escuela := raiz.marco != null
	raiz.ir_a("atlas", {"id": "contactor", "pestana": "que_es"})
	var en_ficha := raiz.marco != null
	raiz.free()
	return A.primero([
		A.cierto(not en_inicio and not en_escuela and not en_ficha, "el inicio, la Escuela y las fichas no llevan el marco"),
		A.cierto(en_tablero and en_guardia, "los tableros y la Guardia van dentro del marco"),
		A.cierto(codigo == "P-31", "el tablero de bombas es el P-31: %s" % codigo),
	])


func test_paneles_con_codigo_unico_y_pantalla_existente() -> String:
	var raiz := _raiz()
	var vistos := {}
	var errores: Array[String] = []
	for p: Dictionary in raiz.paneles.lista():
		var c: String = p["codigo"]
		if vistos.has(c):
			errores.append("código repetido %s" % c)
		vistos[c] = true
		if raiz.paneles.grupo(p["grupo"]).is_empty():
			errores.append("%s sin grupo" % c)
		if not c.begins_with(str(p["grupo"]) + "-"):
			errores.append("%s no empieza por su grupo" % c)
		if p.get("consejos", []).size() > 3:
			errores.append("%s con más de tres consejos" % c)
		if not Paneles.disponible(p):
			continue
		if not ResourceLoader.exists(Raiz.CARPETA_PANTALLAS % p["pantalla"]):
			errores.append("%s abre una pantalla que no existe" % c)
		if not Raiz.usa_marco(p["pantalla"]):
			errores.append("%s abre una pantalla sin marco" % c)
		var tablero: String = p.get("args", {}).get("tablero", "")
		if not tablero.is_empty() and raiz.contenido.tablero(tablero).is_empty():
			errores.append("%s pide un tablero que no existe" % c)
		# Al abrirlo, el marco muestra su propio código.
		raiz.ir_a_panel(c)
		if raiz.marco == null or raiz.marco.codigo != c:
			errores.append("%s no muestra su código al abrirse" % c)
		raiz.ir_a_seccion("plano_barco")
	for g: Dictionary in raiz.paneles.grupos():
		if Color.html_is_valid(str(g["color"])) == false:
			errores.append("grupo %s sin color" % g["id"])
	raiz.free()
	return "" if errores.is_empty() else ", ".join(errores)


func test_anterior_y_siguiente_recorren_el_indice() -> String:
	var raiz := _raiz()
	var lista := raiz.paneles.disponibles()
	var primero: String = lista[0]["codigo"]
	var segundo: String = lista[1]["codigo"]
	var ultimo: String = lista[-1]["codigo"]
	var r := [
		A.cierto(raiz.paneles.vecino(primero, 1) == segundo, "› lleva al segundo panel"),
		A.cierto(raiz.paneles.vecino(primero, -1) == ultimo, "‹ desde el primero da la vuelta al último"),
		A.cierto(raiz.paneles.vecino(ultimo, 1) == primero, "› desde el último vuelve al primero"),
		A.cierto(not lista.any(func(p: Dictionary) -> bool: return p["codigo"] == "X-83"), "un panel próximamente no entra en el recorrido"),
	]
	raiz.ir_a("indice_paneles")
	raiz.ir_a_panel("P-31")
	var siguiente := _buscar(raiz.marco, "Siguiente") as BotonAri
	var visible := siguiente != null and siguiente.visible
	siguiente.pressed.emit()
	r.append(A.cierto(visible and raiz.marco.codigo == raiz.paneles.vecino("P-31", 1), "el botón › abre el panel siguiente: %s" % raiz.marco.codigo))
	raiz.free()
	return A.primero(r)


func test_cambiar_de_panel_sustituye_y_conserva_la_simulacion() -> String:
	var raiz := _raiz()
	raiz.ir_a("indice_paneles")
	var base := raiz.nivel()
	raiz.ir_a_panel("G-11")
	var sim = raiz.args_actuales()["sim"]
	raiz.ir_a_panel("G-12")
	var misma: bool = raiz.args_actuales()["sim"] == sim
	var pestana: String = raiz.args_actuales()["pestana"]
	var codigo := raiz.marco.codigo
	raiz.ir_a_panel("P-31")
	var nivel := raiz.nivel()
	raiz.volver()
	var de_vuelta := raiz.nombre_actual()
	raiz.free()
	return A.primero([
		A.cierto(misma, "entre generadores el cuadro conserva su simulación"),
		A.cierto(pestana == "G2" and codigo == "G-12", "abre la pestaña del generador 2: %s %s" % [pestana, codigo]),
		A.cierto(nivel == base + 1, "un panel sustituye al anterior en la pila: %d" % nivel),
		A.cierto(de_vuelta == "indice_paneles", "«Volver» regresa al índice: %s" % de_vuelta),
	])


func test_pestana_del_cuadro_cambia_el_codigo() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("G-11")
	raiz.pantalla_actual()._elegir_pestana("G3")
	var codigo := raiz.marco.codigo
	raiz.free()
	return A.cierto(codigo == "G-13", "elegir el generador 3 pone el código G-13: %s" % codigo)


func test_panel_derecho_se_pliega_y_da_ancho() -> String:
	# En una pantalla apaisada alta (PC o tableta) el panel derecho ocupa su ancho y se pliega.
	var raiz := _raiz(Vector2i(1280, 720))
	raiz.ir_a_panel("P-31")
	var abierto := _buscar(raiz.marco, "PanelDerecho") != null
	var ancho_abierto := raiz.ancho_contenido()
	var boton := _buscar(raiz.marco, "Pliegue") as BotonAri
	# Lo mismo que hace el botón, sin esperar al fotograma siguiente.
	raiz.marco_plegado = boton != null
	raiz.reconstruir()
	var plegado := _buscar(raiz.marco, "PanelDerecho") == null
	var ancho_plegado := raiz.ancho_contenido()
	raiz.marco_plegado = false
	raiz.free()
	return A.primero([
		A.cierto(abierto and plegado, "el panel derecho se muestra y se pliega"),
		A.cierto(ancho_plegado > ancho_abierto + MarcoAri.ANCHO_DER, "plegado, el tablero gana el ancho del panel: %.0f y %.0f" % [ancho_abierto, ancho_plegado]),
	])


func test_en_celular_apaisado_el_panel_derecho_flota() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("P-31")
	var capa := _buscar(raiz.marco, "CapaDerecha") as Control
	var empieza_plegado := capa != null and not capa.visible
	var ancho := raiz.ancho_contenido()
	var dos_columnas := not raiz.vertical
	(_buscar(raiz.marco, "Pliegue") as BotonAri).pressed.emit()
	var abierta := raiz.marco.capa_derecha_abierta()
	var mismo_ancho := is_equal_approx(raiz.ancho_contenido(), ancho)
	var con_paneles := _buscar(capa, "Generacion") != null and _buscar(capa, "Alarmas") != null
	(_buscar(raiz.marco, "PlegarCapa") as BotonAri).pressed.emit()
	var cerrada := not raiz.marco.capa_derecha_abierta()
	raiz.free()
	return A.primero([
		A.cierto(empieza_plegado, "en un celular apaisado el panel derecho empieza plegado"),
		A.cierto(dos_columnas and ancho > 700.0, "el tablero tiene todo el ancho y dos columnas: %.0f" % ancho),
		A.cierto(abierta and mismo_ancho and con_paneles, "al abrirlo flota sobre el contenido, con la generación y las alarmas"),
		A.cierto(cerrada, "el botón lo vuelve a plegar"),
	])


func test_en_vertical_la_hoja_sube_desde_el_pie() -> String:
	var raiz := _raiz(VERTICAL)
	raiz.ir_a_panel("P-31")
	var retrato := raiz.marco.retrato
	var tira := _buscar(raiz.marco, "Accesos") is MarcoAri.Lamina
	var sin_derecha := _buscar(raiz.marco, "PanelDerecho") == null
	var cerrada := not raiz.marco.hoja_abierta()
	(_buscar(raiz.marco, "VerGeneracion") as BotonAri).pressed.emit()
	var abierta := raiz.marco.hoja_abierta()
	var con_paneles := _buscar(raiz.marco, "Generacion") != null and _buscar(raiz.marco, "Alarmas") != null
	(_buscar(raiz.marco, "Cerrar") as BotonAri).pressed.emit()
	var cerrada_otra_vez := not raiz.marco.hoja_abierta()
	raiz.free()
	return A.primero([
		A.cierto(retrato and tira and sin_derecha, "en vertical, accesos en tira y sin panel derecho fijo"),
		A.cierto(cerrada and abierta and cerrada_otra_vez, "la hoja se abre con el botón de generación y se cierra"),
		A.cierto(con_paneles, "la hoja lleva la generación y las alarmas"),
	])


func test_generacion_del_cuadro_llega_a_las_lecturas() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("C-21")
	var p = raiz.pantalla_actual()
	var g1: SimGenerador = p.sim.componente("G1")
	g1.estado["p_kw"] = 287.4
	raiz.marco._leer_generacion()
	var filas: Array = raiz.marco.generacion()["filas"]
	var lcd: LecturaLcd = raiz.marco._filas_gen[0][3]
	var en_cuadro := lcd.texto
	raiz.ir_a_panel("P-31")
	var escenario: Array = raiz.marco.generacion()["filas"]
	var nombre: String = raiz.marco._escenario.text
	raiz.free()
	return A.primero([
		A.cierto(filas.size() == 5, "cuatro generadores y el de emergencia: %d" % filas.size()),
		A.cierto(en_cuadro == "287,4", "la lectura muestra la potencia de la simulación: %s" % en_cuadro),
		A.cierto(escenario.size() == 6 and is_equal_approx(float(escenario[0]["kw"]), 310.4), "fuera del cuadro, el escenario del buque"),
		A.cierto(nombre.contains("2 generadores"), "el pie nombra el escenario: %s" % nombre),
	])


func test_eventos_y_alarmas_llegan_al_marco() -> String:
	var raiz := _raiz()
	raiz.eventos.vaciar()
	raiz.ir_a_panel("P-31")
	var sin_alarmas := raiz.marco.pendientes() == 0
	raiz.pantalla_actual()._mostrar_aviso("Disparo térmico (SW 2)", "texto", "alarma")
	var pie: String = raiz.marco._evento.text
	var pendientes := raiz.marco.pendientes()
	var cabecera: String = raiz.marco._cabecera_alarmas.text
	(_buscar(raiz.marco, "Reconocer") as BotonAri).pressed.emit()
	var tras_ack := raiz.marco.pendientes()
	var sigue := raiz.marco.alarmas_visibles().size()
	raiz.pantalla_actual()._mostrar_aviso("Interruptor bloqueado", "texto")
	var evento: String = raiz.marco._evento.text
	var alarmas_tras_evento := raiz.marco.alarmas_visibles().size()
	raiz.eventos.vaciar()
	raiz.free()
	return A.primero([
		A.cierto(sin_alarmas, "sin avisos no hay alarmas"),
		A.cierto(pie == "Disparo térmico (SW 2)", "el pie muestra el último evento: %s" % pie),
		A.cierto(pendientes == 1 and cabecera == "ALARMAS · 1", "la alarma queda pendiente: %d, %s" % [pendientes, cabecera]),
		A.cierto(tras_ack == 0 and sigue == 1, "ACK la reconoce, pero sigue en la lista"),
		A.cierto(evento == "Interruptor bloqueado" and alarmas_tras_evento == 1, "un aviso de manejo va al pie, no a las alarmas"),
	])


func test_mision_en_curso_es_una_alarma() -> String:
	var raiz := _raiz()
	raiz.eventos.vaciar()
	var id: String = raiz.contenido.sistema(3)["modos"]["guardia"]["misiones"][0]
	raiz.ir_a("mision", {"id": id})
	var alarmas := raiz.pantalla_actual().alarmas_marco()
	var titulo: String = raiz.contenido.mision(id)["titulo"]
	var codigo: String = raiz.marco._placa_codigo.text
	raiz.free()
	return A.primero([
		A.cierto(alarmas.size() == 1 and alarmas[0] == titulo, "la avería en curso sale como alarma: %s" % str(alarmas)),
		A.cierto(codigo == "AVERÍA", "la placa de una misión dice AVERÍA: %s" % codigo),
	])


func test_ayuda_muestra_la_nota_y_se_cierra() -> String:
	var raiz := _raiz()
	raiz.ir_a_panel("F-41")
	(_buscar(raiz.marco, "Ayuda") as BotonAri).pressed.emit()
	var abierta := raiz.marco.ayuda_abierta()
	raiz.marco._cerrar_ayuda()
	var cerrada := not raiz.marco.ayuda_abierta()
	raiz.free()
	return A.cierto(abierta and cerrada, "el botón ? abre la ayuda del panel y se cierra")


func test_indice_y_leyenda_en_ambas_orientaciones() -> String:
	var pruebas := P.new()
	for tam: Vector2i in [APAISADO, VERTICAL]:
		var raiz := _raiz(tam)
		raiz.ir_a("indice_paneles")
		var filas := 0
		var grises := 0
		for p: Dictionary in raiz.paneles.lista():
			var b := _buscar(raiz.pantalla_actual(), p["codigo"]) as BotonAri
			if b != null:
				filas += 1
				if b.disabled:
					grises += 1
		var pequenos: Array[String] = []
		pruebas._botones_pequenos(raiz, pequenos)
		var bloquean: Array[String] = []
		pruebas._botones_que_bloquean(raiz, false, bloquean)
		raiz.ir_a("leyenda")
		var muestras := _contar(raiz.pantalla_actual(), MuestraLeyenda)
		var secciones := _contar(raiz.pantalla_actual(), PanelAri)
		pruebas._botones_pequenos(raiz, pequenos)
		pruebas._botones_que_bloquean(raiz, false, bloquean)
		var total := raiz.paneles.lista().size()
		raiz.free()
		var r := A.primero([
			A.cierto(filas == total and grises == 1, "el índice muestra los %d paneles, uno en gris: %d, %d" % [total, filas, grises]),
			A.cierto(muestras == 14 and secciones == 6, "la leyenda tiene seis secciones y catorce muestras: %d, %d" % [secciones, muestras]),
			A.cierto(pequenos.is_empty(), "botones bajo 48: %s" % ", ".join(pequenos)),
			A.cierto(bloquean.is_empty(), "controles que impiden arrastrar: %s" % ", ".join(bloquean)),
		])
		if not r.is_empty():
			return "%s en %s" % [r, str(tam)]
	return ""


func test_marco_con_botones_de_48_en_ambas_orientaciones() -> String:
	var pruebas := P.new()
	for tam: Vector2i in [APAISADO, VERTICAL]:
		var raiz := _raiz(tam)
		for c in ["P-31", "G-12", "F-41", "X-81", "T-92"]:
			raiz.ir_a_panel(c)
			var pequenos: Array[String] = []
			pruebas._botones_pequenos(raiz.marco, pequenos)
			if not pequenos.is_empty():
				raiz.free()
				return "botones bajo 48 en %s %s: %s" % [c, str(tam), ", ".join(pequenos)]
		raiz.free()
	return ""


func test_lecturas_con_coma_y_textos_con_contraste() -> String:
	var pares := [
		["texto sobre panel", Tema.ARI_TEXTO, Tema.ARI_PANEL[1], 4.5],
		["nota sobre panel", Tema.ARI_TEXTO_SUAVE, Tema.ARI_PANEL[1], 4.5],
		["evento sobre pie", Tema.ARI_EVENTO, Tema.ARI_PIE[1], 4.5],
		["alarma sobre lista", Tema.ARI_ALARMA, Tema.ARI_LISTA, 4.5],
		["normal sobre lista", Tema.ARI_NORMAL, Tema.ARI_LISTA, 4.5],
		["botón ámbar", Tema.ARI_TEXTO_OSCURO, Tema.ARI_AMBAR[2], 4.5],
		["botón azul", Color.WHITE, Tema.ARI_BOTON[3], 4.5],
		["lectura verde", Tema.ARI_LCD_VERDE, Tema.ARI_LCD_FONDO, 7.0],
	]
	var r: Array = [
		A.cierto(LecturaLcd.numero(310.44, 1) == "310,4", "coma decimal en las lecturas"),
		A.cierto(is_equal_approx(DibujoAri.ancho_seg7("12,6", 10.0), DibujoAri.ancho_seg7("126", 10.0)), "la coma no ocupa una cifra"),
	]
	for p: Array in pares:
		var c := Tema.contraste(p[1], p[2])
		r.append(A.cierto(c >= p[3], "contraste de %s: %.2f" % [p[0], c]))
	return A.primero(r)
