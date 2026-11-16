extends Animacion
## Caída de tensión en el cable trifásico de un motor de la red de 380 V: ΔU = √3 × I × L × ρ ÷ S,
## con cobre a 70 °C (ρ = 0,0225 Ω·mm²/m) y sin la reactancia del cable. Se eligen la longitud,
## la sección y la corriente; la caída se compara con el 6 % que admite IEC 60092-352 desde el
## cuadro hasta el consumidor (verificar el criterio del buque).

const ANCHO := 420.0
const ALTO := 240.0
const V_RED := 380.0
const RHO := 0.0225
const LIMITE := 6.0
const SECCIONES := [1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0]

var longitud := 60.0
var seccion := 2.5
var corriente := 30.0
var _caida: Label
var _botones: Array[Button] = []
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var largo := fila_valor(c, "Longitud del cable")
	barra(c, 5.0, 120.0, 5.0, longitud, func(v: float) -> void:
		longitud = v
		largo.text = "%d m" % roundi(v)
		_actualizar())
	largo.text = "%d m" % roundi(longitud)
	var corr := fila_valor(c, "Corriente del motor")
	barra(c, 5.0, 60.0, 1.0, corriente, func(v: float) -> void:
		corriente = v
		corr.text = "%d A" % roundi(v)
		_actualizar())
	corr.text = "%d A" % roundi(corriente)
	var fila := GridContainer.new()
	fila.columns = 4
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	c.add_child(fila)
	for s: float in SECCIONES:
		var b := boton_mando(fila, poner_seccion.bind(s))
		b.text = "%s mm²" % coma(s)
		_botones.append(b)
	_caida = fila_valor(c, "Caída de tensión")
	_nota = nota_mandos(c)
	_actualizar()


func poner_seccion(s: float) -> void:
	seccion = s
	_actualizar()


func caida_v() -> float:
	return sqrt(3.0) * corriente * longitud * RHO / seccion


func caida_pct() -> float:
	return caida_v() / V_RED * 100.0


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if is_equal_approx(SECCIONES[k], seccion) else 0.6)
	_caida.text = "%s V · %s %%" % [coma(caida_v()), coma(caida_pct())]
	if caida_pct() > LIMITE:
		_nota.text = "Demasiada caída: el motor recibe %d V, arranca peor y se calienta. Aumente la sección." % roundi(V_RED - caida_v())
	else:
		_nota.text = "Caída admisible: el motor recibe %d V. Doble longitud, doble caída; doble sección, la mitad." % roundi(V_RED - caida_v())


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(210, 12), "CABLE DESDE EL CUADRO HASTA EL MOTOR", 12, Color("5b6267"))
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 6, 0, 0, Color("5b6267")), Rect2(16, 50, 70, 90))
	texto(Vector2(51, 80), "Cuadro", 11, Tema.TINTA)
	texto(Vector2(51, 104), "380 V", 13, Tema.TINTA)
	var grosor := 2.0 + seccion * 0.5
	var malo := caida_pct() > LIMITE
	var color := Color("8a4b1f")
	var ancho := 60.0 + longitud / 120.0 * 230.0
	for k in 3:
		l.draw_line(Vector2(86, 72 + k * 16), Vector2(86 + ancho, 72 + k * 16), [color, Color("1a1a1a"), Color("8a8f93")][k], grosor)
	var m := Vector2(86 + ancho + 34, 96)
	l.draw_circle(m, 30.0, Color("6c7276"))
	texto(m, "M", 18, Color.WHITE)
	texto(Vector2(86 + ancho / 2.0, 140), "%d m · %s mm²" % [roundi(longitud), coma(seccion)], 12, Tema.TINTA)
	# Barra de la caída frente al límite.
	var x0 := 40.0
	var w := 340.0
	l.draw_rect(Rect2(x0, 176, w, 18), Color("dfe3e4"))
	var lleno := clampf(caida_pct() / 12.0, 0.0, 1.0) * w
	l.draw_rect(Rect2(x0, 176, lleno, 18), Tema.FALLO if malo else Tema.ACIERTO)
	var xl := x0 + LIMITE / 12.0 * w
	l.draw_line(Vector2(xl, 168), Vector2(xl, 202), Tema.TINTA, 2.0)
	texto(Vector2(xl, 212), "6 %", 10, Tema.TINTA)
	texto(Vector2(x0, 212), "0 %", 10, Tema.TINTA)
	texto(Vector2(x0 + w, 212), "12 %", 10, Tema.TINTA)
	l.draw_set_transform(Vector2.ZERO)
