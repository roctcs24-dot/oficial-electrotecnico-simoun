extends Animacion
## Tres luces de 24 V y 1200 Ω con una fuente de 24 V DC, en serie, en paralelo o mixto (H1 y H2
## en serie, H3 en paralelo con ellas). Se puede fundir H1: en serie se apagan todas; en paralelo
## las demás siguen. Las tensiones y corrientes se calculan con la ley de Ohm.

const ANCHO := 420.0
const ALTO := 260.0
const V := 24.0
const R := 1200.0
const MODOS := ["serie", "paralelo", "mixto"]

var modo := "serie"
var h1_fundida := false
var _botones: Array[Button] = []
var _fundir: Button
var _total: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for m: String in MODOS:
		var b := boton_mando(fila, poner_modo.bind(m))
		b.text = m.capitalize()
		_botones.append(b)
	_fundir = boton_mando(c, func() -> void: fundir(not h1_fundida))
	_total = fila_valor(c, "Corriente de la fuente")
	_nota = nota_mandos(c)
	_actualizar()


func poner_modo(m: String) -> void:
	modo = m
	_actualizar()


func fundir(si: bool) -> void:
	h1_fundida = si
	_actualizar()


## Tensión en cada luz [H1, H2, H3].
func tensiones() -> Array[float]:
	match modo:
		"serie":
			if h1_fundida:
				return [V, 0.0, 0.0]
			return [V / 3.0, V / 3.0, V / 3.0]
		"paralelo":
			return [V, V, V]
	# Mixto: H1 y H2 en serie, y H3 en paralelo con las dos.
	if h1_fundida:
		return [V, 0.0, V]
	return [V / 2.0, V / 2.0, V]


## Corriente en cada luz, en mA.
func corrientes() -> Array[float]:
	var lista: Array[float] = []
	var v := tensiones()
	for i in 3:
		var fundida := i == 0 and h1_fundida
		if fundida:
			lista.append(0.0)
			continue
		if modo == "serie" and h1_fundida:
			lista.append(0.0)
		elif modo == "mixto" and h1_fundida and i == 1:
			lista.append(0.0)
		else:
			lista.append(v[i] / R * 1000.0)
	return lista


func corriente_total() -> float:
	var i := corrientes()
	match modo:
		"serie":
			return i[1] if not h1_fundida else 0.0
		"paralelo":
			return i[0] + i[1] + i[2]
	return i[1] + i[2]


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if MODOS[k] == modo else 0.6)
	_fundir.text = "Cambiar H1" if h1_fundida else "Fundir H1"
	_total.text = "%s mA" % coma(corriente_total())
	match modo:
		"serie":
			_nota.text = "En serie la misma corriente pasa por todas y la tensión se reparte: 8 V en cada una. Si una se funde, se apagan todas y toda la tensión queda en la fundida."
		"paralelo":
			_nota.text = "En paralelo todas tienen los 24 V y las corrientes se suman. Si una se funde, las demás siguen encendidas."
		_:
			_nota.text = "Mixto: H1 y H2 en serie se reparten los 24 V; H3, en paralelo con ellas, tiene los 24 V enteros."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(210, 12), "FUENTE DE 24 V Y TRES LUCES DE 24 V", 12, Color("5b6267"))
	var rojo := Color("c0392b")
	var azul := Color("2f7fd0")
	# Fuente.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 6, 0, 0, Color("5b6267")), Rect2(20, 90, 60, 80))
	texto(Vector2(50, 116), "+", 16, rojo)
	texto(Vector2(50, 150), "−", 16, azul)
	texto(Vector2(50, 184), "24 V", 11, Tema.TINTA)
	var posiciones: Array[Vector2]
	match modo:
		"serie":
			posiciones = [Vector2(150, 60), Vector2(250, 60), Vector2(350, 60)]
			_cable([Vector2(80, 110), Vector2(110, 110), Vector2(110, 60), Vector2(130, 60)], rojo)
			_cable([Vector2(170, 60), Vector2(230, 60)], rojo)
			_cable([Vector2(270, 60), Vector2(330, 60)], rojo)
			_cable([Vector2(370, 60), Vector2(400, 60), Vector2(400, 220), Vector2(110, 220), Vector2(110, 150), Vector2(80, 150)], azul)
		"paralelo":
			posiciones = [Vector2(170, 130), Vector2(260, 130), Vector2(350, 130)]
			_cable([Vector2(80, 110), Vector2(110, 110), Vector2(110, 60), Vector2(350, 60)], rojo)
			_cable([Vector2(80, 150), Vector2(110, 150), Vector2(110, 210), Vector2(350, 210)], azul)
			for p in posiciones:
				_cable([Vector2(p.x, 60), Vector2(p.x, 110)], rojo)
				_cable([Vector2(p.x, 150), Vector2(p.x, 210)], azul)
		_:
			posiciones = [Vector2(180, 80), Vector2(300, 80), Vector2(240, 180)]
			_cable([Vector2(80, 110), Vector2(120, 110), Vector2(120, 80), Vector2(160, 80)], rojo)
			_cable([Vector2(200, 80), Vector2(280, 80)], rojo)
			_cable([Vector2(320, 80), Vector2(380, 80), Vector2(380, 230), Vector2(120, 230), Vector2(120, 150), Vector2(80, 150)], azul)
			_cable([Vector2(120, 110), Vector2(120, 180), Vector2(220, 180)], rojo)
			_cable([Vector2(260, 180), Vector2(380, 180)], azul)
	var v := tensiones()
	var corr := corrientes()
	for i in 3:
		var p := posiciones[i]
		var brillo := clampf(corr[i] / 20.0, 0.0, 1.0)
		if brillo > 0.05:
			l.draw_circle(p, 26.0, Color(1.0, 0.82, 0.3, 0.25 * brillo))
		l.draw_circle(p, 16.0, Color("6c7276").lerp(Color("ffd166"), brillo))
		l.draw_arc(p, 16.0, 0.0, TAU, 24, Tema.TINTA, 2.0)
		if i == 0 and h1_fundida:
			l.draw_line(p + Vector2(-10, -10), p + Vector2(10, 10), Tema.FALLO, 3.0)
		texto(p + Vector2(0, -28), "H%d" % (i + 1), 11, Tema.TINTA)
		texto(p + Vector2(0, 30), "%s V · %s mA" % [coma(v[i]), coma(corr[i])], 10, Tema.TINTA)
	l.draw_set_transform(Vector2.ZERO)


func _cable(puntos: Array[Vector2], color: Color) -> void:
	for k in puntos.size() - 1:
		lienzo.draw_line(puntos[k], puntos[k + 1], color, 2.5)
