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


func sistemas() -> Array:
	return leer("sistemas.json").get("sistemas", [])


func sistema(id: int) -> Dictionary:
	for s: Dictionary in sistemas():
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
	var datos := leer("circuitos/%s.json" % nombre)
	if datos.is_empty():
		return null
	datos = datos.duplicate(true)
	for c: Dictionary in datos.get("componentes", []):
		var p: Dictionary = c.get("params", {})
		if p.has("programa_de"):
			var programa := plc(p["programa_de"])
			p["programa"] = programa.get("programa", [])
			p["etiquetas"] = programa.get("etiquetas", {})
	return SimSimulacion.desde_dict(datos)


func plc(id: String) -> Dictionary:
	return leer("plc/%s.json" % id)
