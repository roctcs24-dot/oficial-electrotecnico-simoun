extends RefCounted
## Dibujos realistas de los equipos (tools/dibujos_realistas): imágenes en art/realista/ con el mismo
## encuadre que su SVG, que VistaSvg muestra en su lugar. Si el encuadre cambiara, las etiquetas, los
## bornes y las marcas dejarían de caer en su sitio.

const A := preload("res://tests/ayuda_sim.gd")
const ESCALA := 2.0


## Imágenes de art/realista: ruta del SVG -> ruta de la imagen.
func _imagenes() -> Dictionary:
	var lista := {}
	for sub in ["equipos", "taller"]:
		var dir := DirAccess.open(VistaSvg.CARPETA_REALISTA + sub)
		if dir == null:
			continue
		for f in dir.get_files():
			if f.ends_with(".webp"):
				lista["res://art/%s/%s.svg" % [sub, f.get_basename()]] = VistaSvg.CARPETA_REALISTA + sub + "/" + f
	return lista


## Tamaño de cada SVG según las fichas que lo usan.
func _tamanos(c: Contenido) -> Dictionary:
	var tamanos := {}
	var dir := DirAccess.open("res://data/fichas")
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var ficha := c.ficha(f.get_basename())
		for d: Dictionary in [ficha.get("dibujo", {})] + ficha.get("dibujos_extra", []):
			if d.has("svg"):
				tamanos[d["svg"]] = Vector2(d["tamano"][0], d["tamano"][1])
	return tamanos


func test_cada_imagen_tiene_su_svg_y_su_encuadre() -> String:
	var c := Contenido.new()
	var tamanos := _tamanos(c)
	var fallos: Array[String] = []
	var imagenes := _imagenes()
	for svg: String in imagenes:
		if not FileAccess.file_exists(svg):
			fallos.append("%s no tiene SVG" % imagenes[svg])
			continue
		var t: Texture2D = load(imagenes[svg])
		if t == null:
			fallos.append("%s no carga" % imagenes[svg])
			continue
		if tamanos.has(svg):
			var esperado: Vector2 = tamanos[svg] * ESCALA
			if absf(t.get_width() - esperado.x) > 2.0 or absf(t.get_height() - esperado.y) > 2.0:
				fallos.append("%s mide %s y debe medir %s" % [imagenes[svg].get_file(), str(t.get_size()), str(esperado)])
	return A.primero([A.cierto(imagenes.size() >= 74, "faltan imágenes: %d" % imagenes.size()), "; ".join(fallos)])


func test_tanda_de_electricidad_industrial_completa() -> String:
	var c := Contenido.new()
	var faltan: Array[String] = []
	for id: String in c.sistema(7)["modos"]["aprender"]["atlas"]:
		var ficha := c.ficha(str(c.atlas(id).get("ficha", id)))
		for d: Dictionary in [ficha["dibujo"]] + ficha.get("dibujos_extra", []):
			if not ResourceLoader.exists(VistaSvg.ruta_realista(d["svg"])):
				faltan.append(d["svg"].get_file())
	return A.cierto(faltan.is_empty(), "dibujos sin versión realista: %s" % ", ".join(faltan))


func test_todas_las_fichas_tienen_dibujo_realista() -> String:
	var c := Contenido.new()
	var faltan: Array[String] = []
	for svg: String in _tamanos(c):
		if not ResourceLoader.exists(VistaSvg.ruta_realista(svg)):
			faltan.append(svg.get_file())
	return A.cierto(faltan.is_empty(), "dibujos de fichas sin versión realista: %s" % ", ".join(faltan))


func test_vista_usa_la_imagen_realista_o_el_svg() -> String:
	var c := Contenido.new()
	var contactor := VistaEquipo.new()
	contactor.cargar(c.ficha("contactor")["dibujo"])
	var con_imagen := contactor.realista != null and contactor.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var simbolo := VistaSvg.new()
	simbolo.cargar(c.ficha("contactor")["simbolos"]["iec"])
	var sin_imagen := simbolo.realista == null
	var ruta := VistaSvg.ruta_realista("res://art/equipos/contactor.svg")
	contactor.free()
	simbolo.free()
	return A.primero([
		A.cierto(con_imagen, "el contactor debe mostrarse con su imagen realista y mipmaps"),
		A.cierto(sin_imagen, "los símbolos siguen en SVG"),
		A.cierto(ruta == "res://art/realista/equipos/contactor.webp", "ruta realista: %s" % ruta),
		A.cierto(VistaSvg.ruta_realista("user://otro.svg").is_empty(), "fuera de art/ no hay versión realista"),
	])


func test_cada_tablero_tiene_su_fondo_realista_con_su_encuadre() -> String:
	var fallos: Array[String] = []
	var dir := DirAccess.open("res://data/tableros")
	var c := Contenido.new()
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var t := c.tablero(f.get_basename())
		var ruta := VistaSvg.CARPETA_REALISTA + "tableros/%s.webp" % t["id"]
		if not ResourceLoader.exists(ruta):
			fallos.append("%s sin fondo" % t["id"])
			continue
		var imagen: Texture2D = load(ruta)
		var esperado: Vector2 = Vector2(t["frente"]["tamano"][0], t["frente"]["tamano"][1]) * 1.25
		if absf(imagen.get_width() - esperado.x) > 2.0 or absf(imagen.get_height() - esperado.y) > 2.0:
			fallos.append("%s mide %s y debe medir %s" % [t["id"], str(imagen.get_size()), str(esperado)])
	var vista := VistaTablero.new()
	vista.datos = c.tablero("bombas_mp")["frente"]
	vista.id_tablero = "bombas_mp"
	var con_fondo := vista.fondo_realista != null
	vista.id_tablero = "no_existe"
	var sin_fondo := vista.fondo_realista == null
	vista.free()
	return A.primero([
		"; ".join(fallos),
		A.cierto(con_fondo and sin_fondo, "el frente usa su fondo realista solo si existe"),
	])


func test_mesa_del_taller_usa_las_piezas_realistas() -> String:
	var mesa := VistaMesa.new()
	var motor: Texture2D = mesa._textura("res://art/taller/motor.svg")
	var simbolo: Texture2D = mesa._textura("res://art/simbolos/iec/contactor.svg")
	var realista := motor != null and motor.resource_path.begins_with(VistaSvg.CARPETA_REALISTA)
	var svg := simbolo != null and not simbolo.resource_path.begins_with(VistaSvg.CARPETA_REALISTA)
	mesa.free()
	return A.primero([
		A.cierto(realista, "el motor de la mesa debe salir de art/realista"),
		A.cierto(svg, "lo que no tiene imagen realista sigue con su SVG"),
	])
