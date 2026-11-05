class_name TextoTecnico
extends RefCounted
## Los términos se escriben {{id}} en el contenido. La primera vez que aparece cada uno
## en una lección o ficha muestra también el inglés, como viene en manuales y placas.

static var _patron: RegEx


static func _regex() -> RegEx:
	if _patron == null:
		_patron = RegEx.create_from_string("\\{\\{([^}]+)\\}\\}")
	return _patron


## vistos guarda los términos ya mostrados y se comparte entre los textos de una misma ficha.
static func expandir(texto: String, glosario: Dictionary, vistos: Dictionary) -> String:
	var resultado := ""
	var cursor := 0
	for m in _regex().search_all(texto):
		resultado += texto.substr(cursor, m.get_start() - cursor)
		cursor = m.get_end()
		var id := m.get_string(1)
		if not glosario.has(id):
			resultado += id
			continue
		var termino: Dictionary = glosario[id]
		if vistos.has(id):
			resultado += termino["es"]
		else:
			vistos[id] = true
			resultado += "%s ([i]%s[/i])" % [termino["es"], termino["en"]]
	return resultado + texto.substr(cursor)


## Número con coma decimal, como se escribe en español.
static func numero(valor: float, decimales := 0) -> String:
	return String.num(valor, decimales).pad_decimals(decimales).replace(".", ",")


## Ids usados en un texto, para validar que todos existen en el glosario.
static func terminos(texto: String) -> Array[String]:
	var lista: Array[String] = []
	for m in _regex().search_all(texto):
		lista.append(m.get_string(1))
	return lista
