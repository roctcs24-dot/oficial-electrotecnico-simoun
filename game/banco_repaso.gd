class_name BancoRepaso
extends RefCounted
## Encuentra la pregunta de repaso de cada tema fallado: lecciones, examen, faltas de las
## misiones y símbolos. Un tema sin pregunta no se ofrece, pero sigue en las estadísticas.

const EXAMEN := "examenes/v1.json"

var contenido: Contenido
var _indice := {}


func _init(contenido_juego: Contenido) -> void:
	contenido = contenido_juego
	for s: Dictionary in contenido.sistemas():
		var modos: Dictionary = s.get("modos", {})
		for id: String in modos.get("aprender", {}).get("lecciones", []):
			_agregar_leccion(contenido.leccion(id))
		for id: String in modos.get("guardia", {}).get("misiones", []):
			_agregar_mision(contenido.mision(id))
	for p: Dictionary in contenido.leer(EXAMEN).get("preguntas", []):
		_indice[p["tema"]] = p
	var preguntas: Dictionary = contenido.leer("guardia.json").get("preguntas", {})
	for tema: String in preguntas:
		var q: Dictionary = preguntas[tema].duplicate()
		q["tipo"] = "quiz"
		q["tema"] = tema
		_indice[tema] = q


func _agregar_leccion(leccion: Dictionary) -> void:
	for pagina: Dictionary in leccion.get("paginas", []):
		for b: Dictionary in pagina["bloques"]:
			if b["tipo"] == "quiz" or b["tipo"] == "ordenar":
				_indice[b["tema"]] = b


## Una misión fallada se repasa con su propio diagnóstico y con el primer dato de su libro.
func _agregar_mision(m: Dictionary) -> void:
	var d: Dictionary = m["diagnostico"]
	var opciones := []
	var correcta := 0
	var explicacion := ""
	for i in d["opciones"].size():
		var o: Dictionary = d["opciones"][i]
		opciones.append(o["texto"])
		if o.get("correcta", false):
			correcta = i
			explicacion = o["explicacion"]
	var tema_diagnostico := "diagnostico_%s" % m["id"]
	_indice[tema_diagnostico] = {
		"tipo": "quiz", "tema": tema_diagnostico,
		"caso": "%s. %s" % [m["equipo"], m["reporte"]["texto"]],
		"pregunta": d["pregunta"], "opciones": opciones, "correcta": correcta, "explicacion": explicacion,
	}
	var campo: Dictionary = m["libro"]["campos"][0]
	var tema_libro := "libro_%s" % m["id"]
	_indice[tema_libro] = {
		"tipo": "quiz", "tema": tema_libro,
		"caso": "%s. %s" % [m["equipo"], m["reporte"]["texto"]],
		"pregunta": "Libro de registro: %s" % campo["etiqueta"],
		"opciones": campo["opciones"], "correcta": campo["correcta"], "explicacion": campo["explicacion"],
	}


func tiene(tema: String) -> bool:
	if tema.begins_with("simbolo_"):
		return not contenido.simbolo(tema.trim_prefix("simbolo_")).is_empty()
	return _indice.has(tema)


## Devuelve un elemento listo para preguntar, con tipo y tema.
func pregunta(tema: String, azar: RandomNumberGenerator) -> Dictionary:
	if tema.begins_with("simbolo_"):
		var r := JuegoSimbolos.crear_ronda(tema.trim_prefix("simbolo_"), contenido.simbolos(), azar)
		r["tipo"] = "simbolo"
		r["tema"] = tema
		return r
	return _indice.get(tema, {})


## Nombre legible del tema, para las estadísticas.
func titulo(tema: String) -> String:
	if tema.begins_with("simbolo_"):
		var s := contenido.simbolo(tema.trim_prefix("simbolo_"))
		return "Símbolo: %s" % s.get("nombre", tema)
	return _indice.get(tema, {}).get("pregunta", tema)
