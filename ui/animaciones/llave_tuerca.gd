extends Animacion
## Una llave de boca métrica sobre una tuerca en pulgadas: se elige la tuerca y la llave, y se ve
## la holgura entre la boca y las caras. El estado sale de TablaLlaves (criterio de enseñanza
## basado en ISO 691 — verificar con la llave y la tuerca reales).

const ANCHO := 420.0
const ALTO := 210.0
const PULGADAS := ["5/16", "3/8", "1/2", "9/16", "5/8", "3/4", "7/8", "15/16"]

var pulgada := "3/4"
var llave := 19
var _botones: Array[Button] = []
var _tuerca: Label
var _llave: Label
var _estado: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var rejilla := GridContainer.new()
	rejilla.columns = 4
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	c.add_child(rejilla)
	for p: String in PULGADAS:
		var b := boton_mando(rejilla, elegir_tuerca.bind(p))
		b.text = "%s\"" % p
		_botones.append(b)
	_llave = fila_valor(c, "Llave")
	barra(c, 6.0, 32.0, 1.0, llave, func(v: float) -> void:
		llave = roundi(v)
		_actualizar())
	_tuerca = fila_valor(c, "Tuerca")
	_estado = fila_valor(c, "Estado")
	_nota = nota_mandos(c)
	_actualizar()


func elegir_tuerca(p: String) -> void:
	pulgada = p
	llave = TablaLlaves.mejor_metrica(TablaLlaves.a_mm(p), range(6, 33))
	_actualizar()


func tuerca_mm() -> float:
	return TablaLlaves.a_mm(pulgada)


func estado() -> String:
	return TablaLlaves.estado(float(llave), tuerca_mm())


func _actualizar() -> void:
	if _nota == null:
		return
	for i in PULGADAS.size():
		_botones[i].modulate = Color(1, 1, 1, 1.0 if PULGADAS[i] == pulgada else 0.55)
	_llave.text = "%d mm" % llave
	_tuerca.text = "%s\" = %s mm" % [pulgada, TablaLlaves.numero(tuerca_mm())]
	_estado.text = TablaLlaves.NOMBRES[estado()]
	var d := float(llave) - tuerca_mm()
	match estado():
		"entra":
			if d < 0.0:
				_nota.text = "Le faltan %s mm, pero la boca se fabrica algo mayor que su medida: entra justa." % TablaLlaves.numero(-d)
			else:
				_nota.text = "Le sobran %s mm: la boca abraza las caras sin bailar." % TablaLlaves.numero(d)
		"holgada":
			_nota.text = "Le sobran %s mm: baila y, al apretar, carga solo en las esquinas." % TablaLlaves.numero(d)
		"redondea":
			_nota.text = "Le sobran %s mm: redondea la tuerca. Use la de pulgadas." % TablaLlaves.numero(d)
		_:
			_nota.text = "Le faltan %s mm: no entra. No la meta a golpes." % TablaLlaves.numero(-d)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, [Color("26313c"), Color("141b22")])
	var c := Vector2(140, 105)
	# Escala: la tuerca se dibuja grande para que se vea la holgura (aumentada × 4).
	var k := 3.6
	var s := tuerca_mm() * k
	var hexagono := PackedVector2Array()
	for i in 6:
		var a := PI / 3.0 * i + PI / 6.0
		hexagono.append(c + Vector2(cos(a), sin(a)) * s / sqrt(3.0))
	var sombra := PackedVector2Array()
	for q in hexagono:
		sombra.append(q + Vector2(0, 4))
	l.draw_colored_polygon(sombra, Color(0, 0, 0, 0.45))
	Relieve.poligono_degradado(l, hexagono, [Color("e8d9a0"), Color("c9a24a"), Color("6a5016")], c - Vector2(0, s), c + Vector2(0, s))
	l.draw_circle(c, s * 0.28, Color("2b3238"))
	# Boca de la llave: dos mordazas paralelas a las caras verticales, separadas por la llave.
	var dif := float(llave) - tuerca_mm()
	# La holgura real es de décimas de mm: se exagera para que se vea.
	var visible := s + clampf(dif, -1.0, 1.0) * 12.0
	var col := Color("c9d1d7")
	var est := estado()
	if est == "no_entra":
		visible = s - 6.0
	var xi := c.x - visible / 2.0
	var xd := c.x + visible / 2.0
	var mordaza_i := Rect2(xi - 26.0, c.y - s * 0.75, 26.0, s * 1.5)
	var mordaza_d := Rect2(xd, c.y - s * 0.75, 26.0, s * 1.5)
	if est == "no_entra":
		mordaza_i.position.y -= s * 0.9
		mordaza_d.position.y -= s * 0.9
	for m: Rect2 in [mordaza_i, mordaza_d]:
		DibujoAri.relleno(l, Rect2(m.position + Vector2(0, 4), m.size), 4.0, Color(0, 0, 0, 0.45))
		DibujoAri.degradado(l, m, 4.0, [Color("ffffff"), col, Color("5b6670")])
	var cuello := Rect2(xi - 26.0, mordaza_i.position.y - 22.0, xd - xi + 52.0, 24.0)
	DibujoAri.degradado(l, cuello, 6.0, [Color("ffffff"), col, Color("5b6670")])
	DibujoAri.degradado(l, Rect2(c.x - 14.0, cuello.position.y - 60.0, 28.0, 62.0), 6.0, [Color("ffffff"), col, Color("5b6670")])
	texto(Vector2(c.x, cuello.get_center().y), "%d mm" % llave, 12, Color("3b444c"))
	var color: Color = {"entra": Color("2e9c3c"), "holgada": Color("b06a00"), "redondea": Tema.FALLO, "no_entra": Tema.FALLO}[est]
	rotulo_estado(Vector2(330, 60), TablaLlaves.NOMBRES[est], color)
	texto(Vector2(330, 100), "tuerca %s\"" % pulgada, 13, Color("e8eef3"))
	texto(Vector2(330, 122), "%s mm entre caras" % TablaLlaves.numero(tuerca_mm()), 12, Color("a9b6c1"))
	texto(Vector2(330, 172), "holgura exagerada para verla", 10, Color("7f8c97"))
	l.draw_set_transform(Vector2.ZERO)
