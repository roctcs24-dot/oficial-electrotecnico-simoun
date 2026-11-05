extends Pantalla
## Glosario español-inglés con búsqueda en ambos idiomas.

var _lista: VBoxContainer
var _terminos: Array = []


## Sin mayúsculas ni tildes, para que "tension" encuentre "tensión".
static func normalizar(texto: String) -> String:
	var t := texto.to_lower()
	var con_tilde := "áéíóúüñ"
	var sin_tilde := "aeiouun"
	for i in con_tilde.length():
		t = t.replace(con_tilde[i], sin_tilde[i])
	return t


static func coincide(termino: Dictionary, busqueda: String) -> bool:
	var b := normalizar(busqueda.strip_edges())
	return b.is_empty() or normalizar(termino["es"]).contains(b) or normalizar(termino["en"]).contains(b)


func construir() -> void:
	_cabecera("Glosario", "Español e inglés, como aparecen en manuales y placas")
	_terminos = raiz.contenido.glosario().values()
	_terminos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return normalizar(a["es"]) < normalizar(b["es"]))
	var buscador := LineEdit.new()
	buscador.placeholder_text = "Buscar en español o en inglés"
	buscador.custom_minimum_size.y = 48.0
	buscador.clear_button_enabled = true
	buscador.text_changed.connect(_filtrar)
	add_child(buscador)
	var desplazable := _desplazable()
	add_child(desplazable)
	_lista = _columna(10)
	desplazable.add_child(_lista)
	_filtrar("")


func _filtrar(busqueda: String) -> void:
	for hijo in _lista.get_children():
		_lista.remove_child(hijo)
		hijo.queue_free()
	var encontrados := 0
	for t: Dictionary in _terminos:
		if coincide(t, busqueda):
			encontrados += 1
			_lista.add_child(_texto_rico("[b]%s[/b] — [i]%s[/i]\n%s" % [t["es"], t["en"], t["def"]]))
	if encontrados == 0:
		_lista.add_child(_etiqueta("No se encontró ningún término.", "Nota"))
