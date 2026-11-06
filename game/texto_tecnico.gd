class_name TextoTecnico
extends RefCounted
## Los términos se escriben {{id}} en el contenido. La primera vez que aparece cada uno
## en una lección o ficha muestra también el inglés, como viene en manuales y placas.

static var _patron: RegEx
static var _patron_unidad: RegEx

## Espacio que no se parte: el número y su unidad quedan siempre en la misma línea.
const ESPACIO_FIJO := " "


static func _regex() -> RegEx:
	if _patron == null:
		_patron = RegEx.create_from_string("\\{\\{([^}]+)\\}\\}")
	return _patron


static func unir_unidades(texto: String) -> String:
	if _patron_unidad == null:
		_patron_unidad = RegEx.create_from_string("(\\d) (%|°C|MΩ|Ω|(?:kVAr|kVA|kW|bar|psi|ppm|mA|Hz|min|K|V|A|s)\\b)")
	return _patron_unidad.sub(texto, "$1" + ESPACIO_FIJO + "$2", true)


## vistos guarda los términos ya mostrados y se comparte entre los textos de una misma ficha.
static func expandir(texto: String, glosario: Dictionary, vistos: Dictionary) -> String:
	var resultado := ""
	var cursor := 0
	for m in _regex().search_all(texto):
		resultado += texto.substr(cursor, m.get_start() - cursor)
		cursor = m.get_end()
		var escrito := m.get_string(1)
		var id := escrito.to_lower()
		if not glosario.has(id):
			resultado += escrito
			continue
		var termino: Dictionary = glosario[id]
		var nombre: String = termino["es"]
		# {{Estator}} con mayúscula inicial sirve para empezar una frase.
		if escrito != id:
			nombre = nombre.substr(0, 1).to_upper() + nombre.substr(1)
		if vistos.has(id):
			resultado += nombre
		else:
			vistos[id] = true
			resultado += "%s ([i]%s[/i])" % [nombre, termino["en"]]
	return unir_unidades(resultado + texto.substr(cursor))


## Número con coma decimal, como se escribe en español.
static func numero(valor: float, decimales := 0) -> String:
	return String.num(valor, decimales).pad_decimals(decimales).replace(".", ",")


## Ids usados en un texto, para validar que todos existen en el glosario.
static func terminos(texto: String) -> Array[String]:
	var lista: Array[String] = []
	for m in _regex().search_all(texto):
		lista.append(m.get_string(1).to_lower())
	return lista
