extends RefCounted
## Etapa D del rediseño: la ficha de equipo y el atlas con el dibujo grande en un visor, marcas
## numeradas sobre el dibujo enlazadas con la lista de partes, bocadillo con la parte elegida y
## pestañas con iconos.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_rediseno_d.json"
const APAISADO := Vector2i(960, 432)
const VERTICAL := Vector2i(432, 960)
const HOJAS := ["partes", "funciona", "conexion", "prueba", "fallas"]


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


func _buscar(nodo: Node, clase: String) -> Array[Node]:
	return nodo.find_children("*", clase, true, false)


func _dibujo_contactor(tam: Vector2, lado: String) -> DibujoMarcas:
	var c := Contenido.new()
	var d := DibujoMarcas.new()
	d.cargar(c.ficha("contactor")["dibujo"])
	d.poner_partes(c.partes_ficha("contactor"), c.glosario(), 1)
	d.lado_bocadillo = lado
	d.size = tam
	return d


func test_marcas_de_las_fichas_sin_atlas_bien_formadas() -> String:
	var c := Contenido.new()
	var fichas: Dictionary = c.leer("marcas_fichas.json").get("fichas", {})
	var fallos: Array[String] = []
	for id: String in fichas:
		var ficha := c.ficha(id)
		if ficha.is_empty():
			fallos.append("%s: la ficha no existe" % id)
			continue
		if not c.atlas_de_ficha(id).is_empty():
			fallos.append("%s: ya tiene atlas, sus marcas salen de él" % id)
		var marcas: Array = fichas[id]
		if marcas.size() < 3 or marcas.size() > 5:
			fallos.append("%s: %d marcas (de 3 a 5)" % [id, marcas.size()])
		var tam: Array = ficha["dibujo"]["tamano"]
		for m: Dictionary in marcas:
			var p: Array = m.get("marca", [])
			if str(m.get("nombre", "")).is_empty() or str(m.get("texto", "")).is_empty():
				fallos.append("%s: marca sin nombre o sin texto" % id)
			if p.size() != 2 or p[0] < 0 or p[1] < 0 or p[0] > tam[0] or p[1] > tam[1]:
				fallos.append("%s: «%s» fuera del dibujo %s" % [id, m.get("nombre", ""), str(p)])
			if str(m.get("texto", "")).contains("{{"):
				fallos.append("%s: «%s» con marcas de glosario" % [id, m.get("nombre", "")])
	return A.primero([
		A.cierto(c.errores.is_empty(), "errores al leer: %s" % str(c.errores)),
		A.cierto(fichas.size() == 19, "deben ser las 19 fichas sin atlas: %d" % fichas.size()),
		"; ".join(fallos),
	])


func test_todas_las_fichas_tienen_marcas_numeradas() -> String:
	var c := Contenido.new()
	var sin: Array[String] = []
	var dir := DirAccess.open("res://data/fichas")
	for archivo in dir.get_files():
		if archivo.ends_with(".json") and c.partes_ficha(archivo.get_basename()).is_empty():
			sin.append(archivo.get_basename())
	var contactor := c.partes_ficha("contactor")
	var alternador := c.partes_ficha("alternador")
	return A.primero([
		A.cierto(sin.is_empty(), "fichas sin marcas: %s" % ", ".join(sin)),
		A.cierto(contactor.size() == 4 and str(contactor[0]["nombre"]).is_empty(), "el contactor toma las cuatro partes de su atlas: %s" % str(contactor)),
		A.cierto(c.atlas_de_ficha("contactor") == "contactor" and c.atlas_de_ficha("alternador").is_empty(), "atlas de cada ficha"),
		A.cierto(alternador.size() >= 3 and not str(alternador[0]["nombre"]).is_empty(), "el alternador toma las suyas de marcas_fichas.json"),
	])


func test_cada_seccion_de_ficha_va_a_una_pestana() -> String:
	var Ficha: GDScript = load("res://ui/screens/ficha.gd")
	var esperado := {
		"Para qué sirve": "partes", "Cómo funciona por dentro": "funciona", "Cómo se conecta": "conexion",
		"Cómo se ajusta y se elige": "conexion", "Estrella o delta: cómo se conecta": "conexion", "Cómo leer la placa": "conexion",
		"Cómo se prueba": "prueba", "Fallas típicas": "fallas", "Mantenimiento": "fallas",
	}
	var mal: Array[String] = []
	for titulo: String in esperado:
		if Ficha.pestana_de_seccion(titulo) != esperado[titulo]:
			mal.append("%s → %s" % [titulo, Ficha.pestana_de_seccion(titulo)])
	return A.cierto(mal.is_empty(), "secciones mal repartidas: %s" % ", ".join(mal))


func test_ficha_con_visor_marcas_y_pestanas_en_ambas_orientaciones() -> String:
	var fallos: Array[String] = []
	for tam in [APAISADO, VERTICAL]:
		var raiz := _raiz(tam)
		raiz.ir_a("ficha", {"id": "contactor"})
		var p = raiz.pantalla_actual()
		var etiqueta := "%dx%d" % [tam.x, tam.y]
		if _buscar(p, "VisorFicha").size() != 1:
			fallos.append("%s: falta el visor" % etiqueta)
		var dibujos := _buscar(p, "DibujoMarcas")
		if dibujos.size() != 1 or (dibujos[0] as DibujoMarcas).marcas.size() != 4:
			fallos.append("%s: el dibujo debe llevar cuatro marcas" % etiqueta)
		elif (dibujos[0] as DibujoMarcas).lado_bocadillo != ("abajo" if tam == VERTICAL else "derecha"):
			fallos.append("%s: bocadillo en el lado %s" % [etiqueta, (dibujos[0] as DibujoMarcas).lado_bocadillo])
		var pestanas := PestanaIcono.de_tira(p.tira)
		if pestanas.size() != 5 or pestanas.filter(func(t: PestanaIcono) -> bool: return t.elegida).size() != 1 or not pestanas[0].elegida:
			fallos.append("%s: cinco pestañas con Partes elegida" % etiqueta)
		for t in pestanas:
			if t.icono.is_empty() or Relieve.icono(t.icono, 20.0) == null:
				fallos.append("%s: la pestaña %s no tiene icono" % [etiqueta, t.clave])
		for clave: String in HOJAS:
			if p.paginas[clave].get_child_count() == 0:
				fallos.append("%s: la hoja %s está vacía" % [etiqueta, clave])
			if p.paginas[clave].visible != (clave == "partes"):
				fallos.append("%s: solo debe verse la hoja Partes" % etiqueta)
		if p.filas.size() != 4 or not p.filas[0].elegida:
			fallos.append("%s: la lista de partes empieza con la 1 elegida" % etiqueta)
		if not _buscar(p, "BotonAri").any(func(b: Node) -> bool: return b.name == "VerAtlas"):
			fallos.append("%s: falta el acceso al atlas" % etiqueta)
		raiz.free()
	return "; ".join(fallos)


func test_tocar_una_marca_o_su_fila_elige_la_misma_parte() -> String:
	var raiz := _raiz()
	raiz.ir_a("ficha", {"id": "contactor"})
	var p = raiz.pantalla_actual()
	var dibujo: DibujoMarcas = _buscar(p, "DibujoMarcas")[0]
	dibujo.marca_tocada.emit(3)
	var desde_marca: bool = p.filas[2].elegida and not p.filas[0].elegida and dibujo.marca_elegida == 3 and int(p.args["parte"]) == 3
	p.filas[3].tocar()
	var desde_fila: bool = dibujo.marca_elegida == 4 and p.filas[3].elegida
	# Desde la vista de símbolos, tocar una parte vuelve al dibujo con la marca encendida.
	p._mostrar_vista("simbolos")
	p.filas[1].tocar()
	var vuelve: bool = p.args["vista"] == "real"
	var nuevo: Array = _buscar(p, "DibujoMarcas").filter(func(d: Node) -> bool: return not d.is_queued_for_deletion())
	var encendida: bool = not nuevo.is_empty() and (nuevo[0] as DibujoMarcas).marca_elegida == 2
	raiz.free()
	return A.primero([
		A.cierto(desde_marca, "tocar la marca 3 enciende su fila"),
		A.cierto(desde_fila, "tocar la fila 4 enciende su marca"),
		A.cierto(vuelve and encendida, "desde los símbolos vuelve al dibujo con la marca 2"),
	])


func test_marcas_tocables_y_bocadillo_sin_tapar_el_dibujo() -> String:
	var fallos: Array[String] = []
	for caso: Array in [[Vector2(430, 300), "derecha"], [Vector2(390, 420), "abajo"]]:
		var d := _dibujo_contactor(caso[0], caso[1])
		var imagen := d.rect_imagen()
		var bocadillo := d.rect_bocadillo()
		if imagen.intersects(bocadillo):
			fallos.append("%s: el bocadillo tapa el dibujo" % caso[1])
		if not Rect2(Vector2.ZERO, d.size).encloses(bocadillo):
			fallos.append("%s: el bocadillo se sale" % caso[1])
		for m: Array in d.marcas:
			var punto := d.a_local(float(m[1]), float(m[2]))
			if d.marca_en(punto) != int(m[0]):
				fallos.append("%s: la marca %d no responde al toque" % [caso[1], int(m[0])])
		if d.marca_en(bocadillo.get_center()) != 0:
			fallos.append("%s: el bocadillo no es una marca" % caso[1])
		d.free()
	return "; ".join(fallos)


func test_bocadillo_con_texto_plano_y_nombre_en_negrita() -> String:
	var glosario := {"contactor": {"es": "contactor", "en": "contactor"}, "bobina": {"es": "bobina", "en": "coil"}}
	var plano := TextoTecnico.plano("El {{Contactor}} tiene una {{bobina}} de 110 V.", glosario)
	var separado := DibujoMarcas.separar_nombre("", "Bornes de potencia: entra la línea por arriba.")
	var sin_dos_puntos := DibujoMarcas.separar_nombre("", "Bornes de la bobina A1-A2, a la tensión de mando.")
	var con_nombre := DibujoMarcas.separar_nombre("Testigo", "Muestra si está cerrado: I u O.")
	return A.primero([
		A.cierto(plano == "El Contactor tiene una bobina de 110" + TextoTecnico.ESPACIO_FIJO + "V.", "texto plano: %s" % plano),
		A.cierto(separado == ["Bornes de potencia", "Entra la línea por arriba."], "separa el nombre: %s" % str(separado)),
		A.cierto(sin_dos_puntos[0].is_empty(), "sin dos puntos no hay nombre: %s" % str(sin_dos_puntos)),
		A.cierto(con_nombre[0] == "Testigo", "un nombre propio se respeta: %s" % str(con_nombre)),
	])


func test_pestana_prueba_con_el_banco_sin_reconstruir() -> String:
	var raiz := _raiz(VERTICAL)
	raiz.ir_a("ficha", {"id": "contactor", "parte": 2})
	var p = raiz.pantalla_actual()
	var antes = p
	p.elegir_pestana("prueba")
	var misma: bool = raiz.pantalla_actual() == antes
	var visible: bool = p.paginas["prueba"].visible and not p.paginas["partes"].visible
	var con_banco: bool = not _buscar(p.paginas["prueba"], "LuzPiloto").is_empty()
	p.pulsar_banco(true)
	var enciende: bool = p._luz.encendida
	var elegida := PestanaIcono.de_tira(p.tira)[3].elegida
	var parte: int = _buscar(p, "DibujoMarcas")[0].marca_elegida
	p.pulsar_banco(false)
	raiz.free()
	return A.primero([
		A.cierto(misma and visible, "cambiar de pestaña no reconstruye la ficha"),
		A.cierto(elegida, "la pestaña Prueba queda encendida"),
		A.cierto(con_banco and enciende, "el banco de prueba sigue funcionando en su pestaña"),
		A.cierto(parte == 2, "la parte de los argumentos queda elegida: %d" % parte),
	])


func test_botones_de_vista_y_grupos_muestran_su_texto_entero() -> String:
	var raiz := _raiz(VERTICAL)
	var cortos: Array[String] = []
	for destino: Array in [["ficha", {"id": "alternador"}], ["atlas", {"id": "contactor", "pestana": "medir"}], ["atlas", {"id": "contactor", "pestana": "conexion"}]]:
		raiz.ir_a(destino[0], destino[1])
		for b: Node in _buscar(raiz.pantalla_actual(), "BotonAri"):
			var boton := b as BotonAri
			# Solo los que van en fila a su ancho mínimo: en una columna o expandidos, se estiran.
			var en_fila := boton.get_parent() is HBoxContainer or boton.get_parent() is HFlowContainer
			if boton.text.is_empty() or not en_fila or boton.size_flags_horizontal & Control.SIZE_EXPAND:
				continue
			var tam := boton.get_theme_font_size("font_size")
			var ancho := Tema.fuente(Tema.PESO_NEGRITA).get_string_size(boton.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
			if boton.custom_minimum_size.x < ancho + 20.0:
				cortos.append("%s «%s»" % [destino[0], boton.text])
		raiz.volver()
	raiz.free()
	return A.cierto(cortos.is_empty(), "botones que cortarían su texto: %s" % ", ".join(cortos))


func test_atlas_con_pestanas_vistas_y_lamparas() -> String:
	var raiz := _raiz()
	for pestana: String in ["que_es", "funciona", "conexion"]:
		raiz.partida.marcar_pestana_atlas("contactor", pestana)
	raiz.ir_a("atlas", {"id": "contactor", "pestana": "medir"})
	var p = raiz.pantalla_actual()
	var pestanas := PestanaIcono.de_tira(p.tira)
	var vistas: Array = pestanas.filter(func(t: PestanaIcono) -> bool: return t.vista).map(func(t: PestanaIcono) -> String: return t.clave)
	var elegida: Array = pestanas.filter(func(t: PestanaIcono) -> bool: return t.elegida).map(func(t: PestanaIcono) -> String: return t.clave)
	var lamparas: Array = _buscar(p, "Control").filter(func(n: Node) -> bool: return n.name == "LamparasVistas")
	var encendidas: int = lamparas[0].vistas if not lamparas.is_empty() else -1
	var medalla: MedallaModulo = _buscar(p, "CabeceraFicha")[0].medalla
	pestanas[4].pressed.emit()
	var tras_tocar: String = raiz.pantalla_actual().args.get("pestana", "")
	raiz.free()
	return A.primero([
		A.cierto(vistas == ["que_es", "funciona", "conexion", "medir"], "pestañas con lámpara verde: %s" % str(vistas)),
		A.cierto(elegida == ["medir"], "pestaña encendida: %s" % str(elegida)),
		A.cierto(encendidas == 4, "lámparas de vistas encendidas: %d" % encendidas),
		A.cierto(is_equal_approx(medalla.avance, 0.8), "anillo de la medalla: %f" % medalla.avance),
		A.cierto(tras_tocar == "fallas", "tocar Fallas abre esa pestaña: %s" % tras_tocar),
	])


func test_atlas_que_es_con_marcas_enlazadas_y_placa() -> String:
	var fallos: Array[String] = []
	for tam in [APAISADO, VERTICAL]:
		var raiz := _raiz(tam)
		raiz.ir_a("atlas", {"id": "rele_termico", "pestana": "que_es"})
		var p = raiz.pantalla_actual()
		var con_marca := 0
		for parte: Dictionary in p.atlas["que_es"]["partes"]:
			if parte.has("marca"):
				con_marca += 1
		if p.dibujo_partes == null or p.dibujo_partes.marcas.size() != con_marca or p.filas.size() != con_marca:
			fallos.append("%dx%d: marcas y filas deben coincidir con las partes con marca" % [tam.x, tam.y])
		else:
			p.elegir_parte(con_marca)
			if p.dibujo_partes.marca_elegida != con_marca or not p.filas[con_marca - 1].elegida or p.filas[0].elegida:
				fallos.append("%dx%d: elegir la última parte no se enlaza" % [tam.x, tam.y])
			p.dibujo_partes.marca_tocada.emit(1)
			if not p.filas[0].elegida:
				fallos.append("%dx%d: tocar la marca 1 no enciende su fila" % [tam.x, tam.y])
		if not _buscar(p, "PanelContainer").any(func(n: Node) -> bool: return n.name == "PlacaDatos"):
			fallos.append("%dx%d: falta la placa de datos" % [tam.x, tam.y])
		if _buscar(p, "VisorFicha").is_empty():
			fallos.append("%dx%d: falta el visor" % [tam.x, tam.y])
		raiz.free()
	return "; ".join(fallos)


func test_atlas_fallas_y_medir_con_visores_de_lectura() -> String:
	var raiz := _raiz()
	raiz.ir_a("atlas", {"id": "contactor", "pestana": "fallas", "falla": 1})
	var p = raiz.pantalla_actual()
	var teclas: Array = _buscar(p, "BotonAri").filter(func(b: Node) -> bool: return str(b.name).begins_with("Falla_"))
	var encendidas: Array = teclas.filter(func(b: BotonAri) -> bool: return b.lampara_encendida)
	var bien_marcada: bool = encendidas.size() == 1 and encendidas[0].name == "Falla_1" and encendidas[0].estilo == "ambar"
	var con_lampara: bool = teclas.all(func(b: BotonAri) -> bool: return b.lampara == "rojo")
	var lecturas_falla: int = p.lecturas_falla(p.atlas["fallas"]["lista"][1]).size()
	var visores_falla := _buscar(p, "PanelContainer").filter(func(n: Node) -> bool: return n.has_meta("visor_lectura")).size()
	raiz.volver()
	raiz.ir_a("atlas", {"id": "contactor", "pestana": "medir"})
	p = raiz.pantalla_actual()
	var filas: int = p.filas_medir(0).size()
	var visores_medir := _buscar(p, "PanelContainer").filter(func(n: Node) -> bool: return n.has_meta("visor_lectura")).size()
	raiz.free()
	return A.primero([
		A.cierto(teclas.size() == 4 and con_lampara, "una tecla con lámpara roja por falla: %d" % teclas.size()),
		A.cierto(bien_marcada, "la falla elegida enciende su lámpara y su tecla"),
		A.cierto(visores_falla == lecturas_falla, "un visor por lectura de la falla: %d de %d" % [visores_falla, lecturas_falla]),
		A.cierto(visores_medir == filas, "un visor por fila de la tabla de medir: %d de %d" % [visores_medir, filas]),
	])


func test_atlas_funciona_enciende_los_pasos() -> String:
	var raiz := _raiz(VERTICAL)
	raiz.ir_a("atlas", {"id": "contactor", "pestana": "funciona"})
	var p = raiz.pantalla_actual()
	var a = p.animacion
	var en_visor := a.get_parent() is VisorFicha
	var t := 0.0
	while t < 3.0:
		a._process(0.05)
		t += 0.05
	p._actualizar_pasos()
	var fase: int = int(a.fase())
	var pasos: Array = p._chips_pasos
	var bien := true
	for i in pasos.size():
		var fila: FilaParte = pasos[i]
		if fila.marca.apagada != (i >= fase) or fila.elegida != (i == fase - 1):
			bien = false
	raiz.free()
	return A.primero([
		A.cierto(en_visor, "la animación va dentro del visor"),
		A.cierto(pasos.size() == 3 and bien, "pasos encendidos hasta la fase %d" % fase),
	])
