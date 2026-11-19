extends RefCounted
## Fotos de piezas tomadas a bordo (data/fotos_piezas.json): archivo bien formado, fotos
## preparadas en art/fotos, halo dentro del recorte, rondas con foto en «¿Abierta o cerrada?» y
## fotos en el catálogo de válvulas.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_fotos.json"


func _raiz(tam := Vector2i(960, 432)) -> Raiz:
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


func _datos() -> Dictionary:
	return Contenido.new().leer(FotosPiezas.ARCHIVO)


func test_archivo_de_fotos_bien_formado() -> String:
	var datos := _datos()
	var catalogo: Array = Contenido.new().leer("catalogos/valvulas.json").get("valvulas", []) + Contenido.new().leer("catalogos/racores.json").get("racores", [])
	var piezas := catalogo.map(func(v: Dictionary) -> String: return v["id"])
	var fallos: Array[String] = []
	var ids := {}
	for f: Dictionary in datos.get("fotos", []):
		for campo in ["id", "pieza", "origen", "recorte", "halo", "archivo", "rotulo", "lugar", "texto"]:
			if not f.has(campo) or str(f[campo]).is_empty():
				fallos.append("%s sin %s" % [f.get("id", "?"), campo])
		if ids.has(f.get("id", "")):
			fallos.append("id repetido %s" % f["id"])
		ids[f.get("id", "")] = true
		if not piezas.has(f.get("pieza", "")):
			fallos.append("%s: pieza desconocida %s" % [f.get("id", "?"), f.get("pieza", "")])
		if not str(f.get("estado", "")) in ["", "abierta", "cerrada"]:
			fallos.append("%s: estado raro" % f["id"])
		if str(f.get("estado", "")) != "" and str(f.get("tubo", "")) not in ["vertical", "horizontal"]:
			fallos.append("%s: con estado debe decir hacia dónde va el tubo" % f["id"])
		for p: Vector2 in FotosPiezas.partes_relativas(f):
			if p.x < 0.0 or p.y < 0.0 or p.x > 1.0 or p.y > 1.0:
				fallos.append("%s: parte fuera del recorte %s" % [f["id"], p])
		if f.has("pregunta") and not (int(f.get("correcta", -1)) >= 0 and int(f["correcta"]) < f.get("opciones", []).size()):
			fallos.append("%s: la respuesta de su pregunta no existe" % f["id"])
		var h := FotosPiezas.halo_relativo(f)
		if not h.has_area() or h.position.x < -0.01 or h.position.y < -0.01 or h.end.x > 1.01 or h.end.y > 1.01:
			fallos.append("%s: halo fuera del recorte %s" % [f["id"], h])
	return A.primero([
		A.cierto(ids.size() >= 10, "al menos 10 fotos: %d" % ids.size()),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(FotosPiezas.con_estado(datos).size() >= 4, "al menos 4 fotos con estado para el minijuego"),
		A.cierto(str(datos.get("credito", "")).contains("Vía Simoun"), "el crédito nombra el buque"),
	])


func test_fotos_preparadas_y_ligeras() -> String:
	var fallos: Array[String] = []
	for f: Dictionary in _datos().get("fotos", []):
		var t := FotosPiezas.textura(f)
		if t == null:
			fallos.append("%s no carga" % f["id"])
			continue
		if maxf(t.get_width(), t.get_height()) > 1024:
			fallos.append("%s mide más de 1024 px" % f["id"])
		var bytes := FileAccess.get_file_as_bytes("res://" + str(f["archivo"])).size()
		if bytes > 250 * 1024:
			fallos.append("%s pesa %d KB" % [f["id"], bytes / 1024])
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_foto_centrada_en_el_halo() -> String:
	var f: Dictionary = _datos()["fotos"].filter(func(x: Dictionary) -> bool: return x["id"] == "genebre_abierta")[0]
	var foto := FotoPieza.desde(f, "credito", true)
	(Engine.get_main_loop() as SceneTree).root.add_child(foto)
	foto.size = Vector2(300, 300)
	var region := foto.region_visible()
	var t := foto.textura.get_size()
	var halo_px := Rect2(foto.halo.position * t, foto.halo.size * t)
	var centro := halo_px.get_center()
	var dentro := region.has_point(centro)
	var cuadrada := is_equal_approx(region.size.x, region.size.y)
	var en_textura := region.position.x >= 0.0 and region.end.x <= t.x + 0.01
	foto.free()
	return A.primero([
		A.cierto(dentro, "el centro del halo se ve: %s en %s" % [centro, region]),
		A.cierto(cuadrada, "la parte visible tiene la forma del control: %s" % region),
		A.cierto(en_textura, "no se sale de la foto: %s" % region),
	])


func test_rondas_con_foto() -> String:
	var catalogo := Contenido.new().leer("catalogos/valvulas.json")
	var fotos := FotosPiezas.con_estado(_datos())
	var azar := RandomNumberGenerator.new()
	azar.seed = 41
	var rondas := JuegoValvulas.crear_rondas(catalogo, 10, azar, fotos)
	var con_foto := rondas.filter(func(r: Dictionary) -> bool: return r.has("foto"))
	var fallos: Array[String] = []
	var vistas := {}
	for r: Dictionary in con_foto:
		var f: Dictionary = fotos.filter(func(x: Dictionary) -> bool: return x["id"] == r["foto"])[0]
		var esperada := 0 if f["estado"] == "abierta" else 1
		if int(r["correcta"]) != esperada:
			fallos.append("%s: respuesta %d" % [r["foto"], r["correcta"]])
		if not str(r["pregunta"]).contains(str(f["tubo"])):
			fallos.append("%s: la pregunta no dice el tubo" % r["foto"])
		if vistas.has(r["foto"]):
			fallos.append("%s repetida" % r["foto"])
		vistas[r["foto"]] = true
	var sin_fotos := JuegoValvulas.crear_rondas(catalogo, 10, azar)
	return A.primero([
		A.cierto(rondas.size() == 10, "siguen siendo 10 rondas"),
		A.cierto(con_foto.size() == JuegoValvulas.FOTOS_RONDAS, "%d rondas con foto: %d" % [JuegoValvulas.FOTOS_RONDAS, con_foto.size()]),
		A.cierto(fallos.is_empty(), ", ".join(fallos)),
		A.cierto(sin_fotos.all(func(r: Dictionary) -> bool: return not r.has("foto")), "sin fotos, todo dibujado"),
	])


func test_minijuego_enseña_la_foto() -> String:
	var raiz := _raiz()
	raiz.ir_a("abierta_cerrada", {})
	var p = raiz.pantalla_actual()
	var indice := -1
	for i in p.args["items"].size():
		if p.args["items"][i].has("foto"):
			indice = i
			break
	p.args["indice"] = indice
	raiz.reconstruir()
	p = raiz.pantalla_actual()
	var fotos: Array = p.find_children("*", "FotoPieza", true, false)
	var halo := false
	var sin_pista := false
	if not fotos.is_empty():
		halo = (fotos[0] as FotoPieza).halo.has_area()
		sin_pista = (fotos[0] as FotoPieza).rotulo.is_empty() and (fotos[0] as FotoPieza).estado.is_empty()
	var item: Dictionary = p.args["items"][indice]
	p._al_responder(true, int(item["correcta"]), indice)
	var acierto: bool = p.args["respuestas"].get(indice, {}).get("acierto", false)
	raiz.free()
	return A.primero([
		A.cierto(indice >= 0, "hay una ronda con foto"),
		A.cierto(fotos.size() == 1, "la ronda enseña la foto: %d" % fotos.size()),
		A.cierto(halo, "la foto marca la válvula con el halo"),
		A.cierto(sin_pista, "la foto no chiva la respuesta (sin rótulo ni lámpara)"),
		A.cierto(acierto, "se responde como cualquier ronda"),
	])


func test_catalogo_enseña_fotos_y_dibujo() -> String:
	var raiz := _raiz(Vector2i(432, 960))
	raiz.ir_a("catalogo", {"catalogo": "valvulas", "elegido": "bola"})
	var c = raiz.pantalla_actual()
	var n_fotos: int = c.fotos.size()
	var primero_foto: bool = c.dibujo is FotoPieza
	var con_lampara: bool = primero_foto and (c.dibujo as FotoPieza).estado in ["abierta", "cerrada"]
	c.ver_foto(-1)
	var dibujo_ok: bool = raiz.pantalla_actual().dibujo is DibujoValvula
	raiz.pantalla_actual().elegir("compuerta")
	var compuerta_dibujo: bool = raiz.pantalla_actual().dibujo is DibujoValvula and raiz.pantalla_actual().fotos.is_empty()
	raiz.pantalla_actual().elegir("globo")
	var globo_foto: bool = raiz.pantalla_actual().dibujo is FotoPieza
	raiz.free()
	return A.primero([
		A.cierto(n_fotos >= 3, "la válvula de bola tiene sus fotos: %d" % n_fotos),
		A.cierto(primero_foto, "el visor empieza por la foto a bordo"),
		A.cierto(con_lampara, "en el catálogo la foto lleva la lámpara de su estado"),
		A.cierto(dibujo_ok, "el botón DIBUJO vuelve al dibujo"),
		A.cierto(compuerta_dibujo, "sin fotos, el dibujo de siempre"),
		A.cierto(globo_foto, "al elegir otra pieza con fotos, vuelve a la primera foto"),
	])


## Versión 4.23.1: las fotos del taller (acoplamiento Dixon, codo con niples, NIBCO suelta) se ven
## en su catálogo, y en vertical la fila de botones de cinco fotos cabe en la pantalla.
func test_fotos_del_taller_en_su_catalogo() -> String:
	var raiz := _raiz(Vector2i(432, 960))
	var vistas: Array[String] = []
	var anchos_ok := true
	for trio: Array in [["valvulas", "bola", "nibco_suelta"], ["racores", "enchufe_rapido", "camlock_dixon"], ["racores", "bspt_npt", "codo_niples"]]:
		raiz.ir_a("catalogo", {"catalogo": trio[0], "elegido": trio[1]})
		var c = raiz.pantalla_actual()
		var i := -1
		for k in c.fotos.size():
			if c.fotos[k]["id"] == trio[2]:
				i = k
		if i < 0:
			vistas.append("%s no está en %s" % [trio[2], trio[1]])
			raiz.volver()
			continue
		c.ver_foto(i)
		c = raiz.pantalla_actual()
		if not (c.dibujo is FotoPieza):
			vistas.append("%s no se enseña" % trio[2])
		var ultimo: Control = c.find_child("Vista_%d" % c.fotos.size(), true, false)
		# La fila de botones (rótulo, fotos y DIBUJO) debe caber en el visor: 432 menos márgenes.
		if ultimo == null or (ultimo.get_parent() as Control).get_combined_minimum_size().x > 380.0:
			anchos_ok = false
		raiz.volver()
	raiz.free()
	return A.primero([
		A.cierto(vistas.is_empty(), ", ".join(vistas)),
		A.cierto(anchos_ok, "en vertical el botón DIBUJO queda dentro de la pantalla"),
	])
