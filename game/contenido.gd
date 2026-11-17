class_name Contenido
extends RefCounted
## Lee el contenido de data/. Un JSON con errores no cierra el juego: el motivo queda en
## errores para mostrarlo, porque estos archivos se corrigen a mano.

const CARPETA := "res://data/"

var errores: Array[String] = []
var _cache := {}


func leer(archivo: String) -> Dictionary:
	if _cache.has(archivo):
		return _cache[archivo]
	var datos := {}
	var ruta := CARPETA + archivo
	if not FileAccess.file_exists(ruta):
		errores.append("Falta %s" % archivo)
	else:
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(ruta)) != OK:
			errores.append("%s, línea %d: %s" % [archivo, json.get_error_line(), json.get_error_message()])
		elif not json.data is Dictionary:
			errores.append("%s debe ser un objeto JSON" % archivo)
		else:
			datos = json.data
	_cache[archivo] = datos
	return datos


func barco() -> Dictionary:
	return leer("barco_via_simoun.json")


func plano() -> Dictionary:
	return leer("sistemas.json").get("plano", {})


## Zonas del buque visto desde arriba, en el inicio: {zonas: [{sistema, nombre, u, v}], aparte}.
func planta() -> Dictionary:
	return leer("sistemas.json").get("planta", {})


## Los sistemas del buque, del 0 al 6, con su zona en el plano.
func sistemas() -> Array:
	return leer("sistemas.json").get("sistemas", [])


## Los módulos de la Escuela técnica, del 7 en adelante: sin zona en el plano.
func modulos_escuela() -> Array:
	return leer("sistemas.json").get("escuela", [])


## Sistemas del buque y módulos de la Escuela, para lo que recorre todo el contenido.
func todos() -> Array:
	return sistemas() + modulos_escuela()


func sistema(id: int) -> Dictionary:
	for s: Dictionary in todos():
		if int(s["id"]) == id:
			return s
	return {}


func rangos() -> Array:
	return leer("rangos.json").get("rangos", [])


## Diccionario id -> {es, en}.
func glosario() -> Dictionary:
	return leer("glosario.json").get("terminos", {})


func ficha(id: String) -> Dictionary:
	return leer("fichas/%s.json" % id)


## Ficha visual del atlas de la Escuela: data/atlas/<id>.json. Toma el dibujo y los símbolos
## de data/fichas/<ficha>.json para no repetirlos.
func atlas(id: String) -> Dictionary:
	if not FileAccess.file_exists(CARPETA + "atlas/%s.json" % id):
		return {}
	return leer("atlas/%s.json" % id)


## Id de la pieza del atlas que usa el dibujo de una ficha, o "" si no tiene.
func atlas_de_ficha(id_ficha: String) -> String:
	for s: Dictionary in todos():
		for id: String in s.get("modos", {}).get("aprender", {}).get("atlas", []):
			if str(atlas(id).get("ficha", id)) == id_ficha:
				return id
	return ""


## Partes numeradas de un atlas, las que llevan marca: [{nombre, texto, x, y}].
static func partes_atlas(datos_atlas: Dictionary) -> Array:
	var lista: Array = []
	for p: Dictionary in datos_atlas.get("que_es", {}).get("partes", []):
		if p.has("marca"):
			lista.append({"nombre": "", "texto": p.get("texto", ""), "x": float(p["marca"][0]), "y": float(p["marca"][1])})
	return lista


## Marcas numeradas sobre el dibujo de una ficha: las del atlas que usa ese dibujo o, si no
## tiene atlas, las de data/marcas_fichas.json. Lista de {nombre, texto, x, y}.
func partes_ficha(id_ficha: String) -> Array:
	var id_atlas := atlas_de_ficha(id_ficha)
	if not id_atlas.is_empty():
		var del_atlas := partes_atlas(atlas(id_atlas))
		if not del_atlas.is_empty():
			return del_atlas
	var lista: Array = []
	for p: Dictionary in leer("marcas_fichas.json").get("fichas", {}).get(id_ficha, []):
		var m: Array = p.get("marca", [0, 0])
		lista.append({"nombre": p.get("nombre", ""), "texto": p.get("texto", ""), "x": float(m[0]), "y": float(m[1])})
	return lista


## Con sistema >= 0, solo los símbolos de ese sistema del buque.
func simbolos(sistema := -1) -> Array:
	var todos: Array = leer("simbolos.json").get("simbolos", [])
	if sistema < 0:
		return todos
	return todos.filter(func(s: Dictionary) -> bool: return int(s.get("sistema", -1)) == sistema)


func simbolo(id: String) -> Dictionary:
	for s: Dictionary in simbolos():
		if s["id"] == id:
			return s
	return {}


func leccion(id: String) -> Dictionary:
	return leer("lecciones/%s.json" % id)


## Ids de los exámenes publicados en algún sistema, sin repetir y en orden.
func examenes() -> Array[String]:
	var lista: Array[String] = []
	for s: Dictionary in sistemas():
		for id: String in s.get("modos", {}).get("examen", {}).get("examenes", []):
			if not lista.has(id):
				lista.append(id)
	return lista


func examen(id: String) -> Dictionary:
	return leer("examenes/%s.json" % id)


func mision(id: String) -> Dictionary:
	return leer("misiones/%s.json" % id)


## Un PLC del circuito con "programa_de" carga el programa de data/plc/<id>.json.
func circuito(nombre: String) -> SimSimulacion:
	var datos := circuito_datos(nombre)
	if datos.is_empty():
		return null
	return SimSimulacion.desde_dict(datos)


## Los datos de un circuito, copiados y con los programas de sus PLC ya cargados.
func circuito_datos(nombre: String) -> Dictionary:
	var datos := leer("circuitos/%s.json" % nombre)
	if datos.is_empty():
		return {}
	datos = datos.duplicate(true)
	for c: Dictionary in datos.get("componentes", []):
		var p: Dictionary = c.get("params", {})
		if p.has("programa_de"):
			var programa := plc(p["programa_de"])
			p["programa"] = programa.get("programa", [])
			p["etiquetas"] = programa.get("etiquetas", {})
	return datos


## Un tablero del buque: frente, circuito, posiciones del interior, señales y averías.
func tablero(id: String) -> Dictionary:
	return leer("tableros/%s.json" % id)


func plc(id: String) -> Dictionary:
	return leer("plc/%s.json" % id)


## Una red Modbus del buque, con su maestro, sus esclavos, la pantalla local y sus averías.
func red(id: String) -> SimRedModbus:
	var datos := leer("redes/%s.json" % id)
	return null if datos.is_empty() else SimRedModbus.desde_dict(datos)
