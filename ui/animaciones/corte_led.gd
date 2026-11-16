extends Animacion
## LED rojo desde 24 V con su resistencia en serie, como led_servicio: I = (24 − Vf) / (R + r).
## Luce con unos 20 mA; por encima de 30 mA se funde y queda abierto, como SimLed, hasta que se
## cambia. Al revés no conduce.

const ANCHO := 400.0
const ALTO := 260.0
const V_FUENTE := 24.0
const VF := 1.9
const R_INTERNA := 20.0
const I_NOMINAL := 0.02
const RESISTENCIAS := [[2200.0, "2,2 kΩ"], [1100.0, "1,1 kΩ"], [470.0, "470 Ω"], [0.0, "Sin R"]]

var indice := 1
var directo := true
var fundido := false
var _botones: Array[Button] = []
var _girar: Button
var _cambiar: Button
var _corriente: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for i in RESISTENCIAS.size():
		var b := boton_mando(fila, elegir.bind(i))
		b.text = RESISTENCIAS[i][1]
		_botones.append(b)
	var otra := HBoxContainer.new()
	otra.add_theme_constant_override("separation", 6)
	c.add_child(otra)
	_girar = boton_mando(otra, girar)
	_girar.text = "Darle la vuelta"
	_cambiar = boton_mando(otra, cambiar)
	_cambiar.text = "Cambiar el LED"
	_corriente = fila_valor(c, "Corriente del LED")
	_nota = nota_mandos(c)
	_comprobar()


func elegir(i: int) -> void:
	indice = clampi(i, 0, RESISTENCIAS.size() - 1)
	_comprobar()


func girar() -> void:
	directo = not directo
	_comprobar()


func cambiar() -> void:
	fundido = false
	_comprobar()


## Corriente que pasaría con el LED sano.
func corriente_posible() -> float:
	if not directo:
		return 0.0
	return (V_FUENTE - VF) / (float(RESISTENCIAS[indice][0]) + R_INTERNA)


func corriente() -> float:
	return 0.0 if fundido else corriente_posible()


func luce() -> bool:
	return corriente() >= SimLed.I_ENCIENDE


## 1 apagado; 2 luciendo; 3 fundido.
func fase() -> int:
	if fundido:
		return 3
	return 2 if luce() else 1


func _comprobar() -> void:
	if corriente_posible() > SimLed.new("x").params["i_max"]:
		fundido = true
	_actualizar()


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if k == indice else 0.6)
	_corriente.text = "%s mA" % coma(corriente() * 1000.0, 1)
	if fundido:
		_nota.text = "Pasaban %d mA: el LED se fundió y quedó abierto. Ponga una resistencia mayor y cambie el LED." % roundi(corriente_posible() * 1000.0)
	elif not directo:
		_nota.text = "Al revés no conduce: el LED no luce y aguanta los 24 V entre sus patas."
	else:
		var r: float = RESISTENCIAS[indice][0]
		_nota.text = "I = (24 − 1,9) / %s = %s mA; la resistencia disipa %s W." % [RESISTENCIAS[indice][1], coma(corriente() * 1000.0, 1), coma(corriente() * corriente() * r, 2)]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "LED CON SU RESISTENCIA EN 24 V", 12, Color("5b6267"))
	var hay := corriente() > 0.0
	var cable := Tema.ACENTO_FUERTE if hay else Color("8a949b")
	l.draw_line(Vector2(50, 200), Vector2(50, 170), Color("c0392b"), 3.0)
	l.draw_line(Vector2(38, 186), Vector2(62, 186), Tema.TINTA, 4.0)
	l.draw_line(Vector2(44, 196), Vector2(56, 196), Tema.TINTA, 4.0)
	texto(Vector2(24, 186), "24 V", 10, Tema.TINTA)
	l.draw_polyline(PackedVector2Array([Vector2(50, 170), Vector2(50, 60), Vector2(110, 60)]), Color("c0392b"), 3.0)
	if RESISTENCIAS[indice][0] > 0.0:
		l.draw_style_box(Tema.caja(Color.WHITE, 2, 0, 0, Color("20242a")), Rect2(110, 52, 60, 16))
		texto(Vector2(140, 82), RESISTENCIAS[indice][1], 10, Tema.TINTA)
	else:
		l.draw_line(Vector2(110, 60), Vector2(170, 60), Color("c0392b"), 3.0)
	l.draw_polyline(PackedVector2Array([Vector2(170, 60), Vector2(250, 60), Vector2(250, 92)]), cable, 3.0)
	# LED grande, con la cápsula que luce según la corriente.
	var brillo := clampf(corriente() / I_NOMINAL, 0.0, 1.3)
	var centro := Vector2(250, 120)
	if brillo > 0.0:
		l.draw_circle(centro, 34.0 + 8.0 * brillo, Color(1.0, 0.25, 0.15, 0.25 * brillo))
	l.draw_circle(centro, 26.0, Color("8e1c15").lerp(Color("ff5a45"), clampf(brillo, 0.0, 1.0)))
	var s := 1.0 if directo else -1.0
	l.draw_colored_polygon(PackedVector2Array([centro + Vector2(-10, -10 * s), centro + Vector2(10, -10 * s), centro + Vector2(0, 8 * s)]), Color.WHITE)
	l.draw_line(centro + Vector2(-10, 9 * s), centro + Vector2(10, 9 * s), Color.WHITE, 3.0)
	if fundido:
		l.draw_line(centro + Vector2(-18, -18), centro + Vector2(18, 18), Color("20242a"), 3.0)
		l.draw_line(centro + Vector2(18, -18), centro + Vector2(-18, 18), Color("20242a"), 3.0)
	l.draw_polyline(PackedVector2Array([Vector2(250, 148), Vector2(250, 215), Vector2(50, 215), Vector2(50, 200)]), Color("20242a"), 3.0)
	texto(Vector2(300, 120), "A arriba" if directo else "K arriba", 10, Tema.TINTA, false)
	if hay:
		for k in 6:
			var x := 60.0 + fmod(t * clampf(corriente() * 3000.0, 20.0, 160.0) + k * 34.0, 180.0)
			l.draw_circle(Vector2(x, 60), 3.0, Tema.ACENTO_FUERTE)
	texto(Vector2(200, 236), "%s mA" % coma(corriente() * 1000.0, 1), 14, Tema.TINTA)
	var rotulo := "FUNDIDO" if fundido else ("LUCE" if luce() else "APAGADO")
	rotulo_estado(Vector2(330, 236), rotulo, Tema.FALLO if fundido else (Tema.ACIERTO if luce() else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
