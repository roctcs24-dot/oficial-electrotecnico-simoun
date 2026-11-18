extends Animacion
## Una o varias herramientas del catálogo (params «tipos») dibujadas con relieve. Con varias, una
## tecla por herramienta; debajo, su nombre en español e inglés y para qué sirve.

const ALTO := 190.0

var dibujo: DibujoHerramienta
var tipos: Array = []
var _datos := {}
var _botones: Array[Button] = []
var _nombre: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	tipos = params.get("tipos", ["combinada"])
	if contenido != null:
		for h: Dictionary in contenido.leer("catalogos/herramientas.json").get("herramientas", []):
			_datos[h["dibujo"]] = h
	dibujo = DibujoHerramienta.new()
	dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
	lienzo.add_child(dibujo)
	var c := tarjeta_mandos()
	if tipos.size() > 1:
		var fila := GridContainer.new()
		fila.columns = mini(tipos.size(), 4)
		fila.add_theme_constant_override("h_separation", 6)
		fila.add_theme_constant_override("v_separation", 6)
		c.add_child(fila)
		for t: String in tipos:
			var b := boton_mando(fila, elegir.bind(t))
			b.text = _corto(t)
			_botones.append(b)
	_nombre = Label.new()
	_nombre.theme_type_variation = "Fuerte"
	_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_child(_nombre)
	_nota = nota_mandos(c)
	elegir(tipos[0])


func _corto(t: String) -> String:
	var n := str(_datos.get(t, {}).get("nombre", t))
	for p in ["Llave de ", "Llave "]:
		if n.begins_with(p):
			var r := n.substr(p.length())
			return r.left(1).to_upper() + r.substr(1)
	return n


func elegir(t: String) -> void:
	dibujo.tipo = t
	dibujo.medida = str(_datos.get(t, {}).get("medida", ""))
	for i in _botones.size():
		_botones[i].modulate = Color(1, 1, 1, 1.0 if tipos[i] == t else 0.55)
	var d: Dictionary = _datos.get(t, {})
	if _nombre != null:
		_nombre.text = "%s · %s" % [d.get("nombre", t), d.get("en", "")]
		_nota.text = str(d.get("para_que", ""))


func dibujar() -> void:
	DibujoAri.degradado(lienzo, Rect2(Vector2.ZERO, lienzo.size), 10.0, [Color("26313c"), Color("141b22")])
