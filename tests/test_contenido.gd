extends RefCounted
## Validación del contenido de data/: una referencia rota debe detectarse aquí, no a bordo.

const A := preload("res://tests/ayuda_sim.gd")
const SECCIONES_FICHA := ["funcion", "partes", "conexion", "ajuste", "pruebas", "fallas", "mantenimiento"]


func _archivos_json(carpeta: String, lista: Array[String]) -> void:
	for f in DirAccess.get_files_at(carpeta):
		if f.ends_with(".json"):
			lista.append(carpeta.path_join(f))
	for d in DirAccess.get_directories_at(carpeta):
		_archivos_json(carpeta.path_join(d), lista)


func test_todos_los_json_son_validos() -> String:
	var lista: Array[String] = []
	_archivos_json("res://data", lista)
	if lista.is_empty():
		return "no se encontró contenido"
	for ruta in lista:
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(ruta)) != OK:
			return "%s, línea %d: %s" % [ruta, json.get_error_line(), json.get_error_message()]
	return ""


func test_todos_los_circuitos_cargan() -> String:
	var c := Contenido.new()
	for f in DirAccess.get_files_at("res://data/circuitos"):
		var sim := c.circuito(f.get_basename())
		if sim == null:
			return "no carga %s" % f
		sim.paso()
	return "; ".join(c.errores)


func test_sistemas_cubren_0_a_6_y_v1_activos() -> String:
	var c := Contenido.new()
	var ids := []
	for s: Dictionary in c.sistemas():
		ids.append(int(s["id"]))
		var z: Array = s["zona"]
		if z[0] < 0 or z[1] < 0 or z[0] + z[2] > 1000 or z[1] + z[3] > 420:
			return "la zona del sistema %d se sale del plano" % int(s["id"])
	return A.primero([
		A.cierto(ids == [0, 1, 2, 3, 4, 5, 6], "deben estar los sistemas 0 a 6: %s" % str(ids)),
		A.cierto(c.sistema(0)["estado"] == "activo", "el sistema 0 es de la v1"),
		A.cierto(c.sistema(3)["estado"] == "activo", "el sistema 3 es de la v1"),
	])


func test_referencias_de_los_sistemas_existen() -> String:
	var c := Contenido.new()
	for s: Dictionary in c.sistemas():
		for id: String in s["modos"].get("aprender", {}).get("fichas", []):
			if c.ficha(id).is_empty():
				return "el sistema %d apunta a una ficha que no existe: %s" % [int(s["id"]), id]
	return "; ".join(c.errores)


func test_fichas_completas_y_con_terminos_del_glosario() -> String:
	var c := Contenido.new()
	var glosario := c.glosario()
	for f in DirAccess.get_files_at("res://data/fichas"):
		var ficha := c.ficha(f.get_basename())
		var ids := []
		for seccion: Dictionary in ficha["secciones"]:
			ids.append(seccion["id"])
			for t in TextoTecnico.terminos(seccion["texto"]):
				if not glosario.has(t):
					return "%s usa un término fuera del glosario: %s" % [f, t]
		for requerida in SECCIONES_FICHA:
			if not ids.has(requerida):
				return "a %s le falta la sección %s" % [f, requerida]
		if ficha.get("para_saber_mas", []).is_empty():
			return "a %s le falta Para saber más" % f
	return "; ".join(c.errores)


func test_dibujos_de_las_fichas_se_pueden_rasterizar() -> String:
	var c := Contenido.new()
	var rutas: Array = [c.plano()["svg"]]
	for f in DirAccess.get_files_at("res://data/fichas"):
		var ficha := c.ficha(f.get_basename())
		rutas.append_array([ficha["dibujo"]["svg"], ficha["simbolos"]["iec"]["svg"], ficha["simbolos"]["ansi"]["svg"]])
	for ruta: String in rutas:
		var textura := VistaSvg.rasterizar(ruta, 0.5)
		if textura == null or textura.get_width() == 0:
			return "no se puede dibujar %s" % ruta
	return ""


## Sin importer="keep", Godot exporta solo la versión importada: los dibujos funcionarían
## en el editor pero faltarían en el APK y el .exe.
func test_los_svg_se_exportan_tal_cual() -> String:
	var lista: Array[String] = []
	_archivos_svg("res://art", lista)
	if lista.is_empty():
		return "no se encontraron dibujos"
	for ruta in lista:
		if not FileAccess.get_file_as_string(ruta + ".import").contains("importer=\"keep\""):
			return "%s.import debe contener importer=\"keep\"" % ruta
	return ""


func _archivos_svg(carpeta: String, lista: Array[String]) -> void:
	for f in DirAccess.get_files_at(carpeta):
		if f.ends_with(".svg"):
			lista.append(carpeta.path_join(f))
	for d in DirAccess.get_directories_at(carpeta):
		_archivos_svg(carpeta.path_join(d), lista)


func test_el_ingles_solo_aparece_la_primera_vez() -> String:
	var glosario := {"bobina": {"es": "bobina", "en": "coil"}}
	var vistos := {}
	var uno := TextoTecnico.expandir("La {{bobina}} y la {{bobina}}.", glosario, vistos)
	var dos := TextoTecnico.expandir("Otra {{bobina}}.", glosario, vistos)
	var nuevo := TextoTecnico.expandir("Otra {{bobina}}.", glosario, {})
	return A.primero([
		A.cierto(uno == "La bobina ([i]coil[/i]) y la bobina.", "primera aparición: %s" % uno),
		A.cierto(dos == "Otra bobina.", "misma ficha: %s" % dos),
		A.cierto(nuevo == "Otra bobina ([i]coil[/i]).", "otra ficha vuelve a mostrarlo: %s" % nuevo),
	])
