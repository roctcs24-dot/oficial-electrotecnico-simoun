extends Animacion
## Lazo de 4–20 mA de una válvula de control con SimNeumatica.posicionador: un calibrador da la
## señal, el posicionador la compara con la posición que lee por su eje y manda aire al actuador
## de cuarto de vuelta (simple efecto, el muelle cierra). Se ven la señal, la presión de salida y
## la mariposa girando. Fallas: sin aire de alimentación, membrana o junta con fuga y lazo cortado.
## Parámetros: "senal" (mA), "foco" ("posicionador" o "actuador").

const ANCHO := 460.0
const ALTO := 230.0

var senal := 12.0
var sin_aire := false
var membrana_fuga := false
var foco := "posicionador"
## Posición mostrada (0 a 1), que sigue a la del modelo con algo de retraso, como el aire real.
var giro := 0.0
var resultado := {}
var _salida: Label
var _posicion: Label
var _boton_aire: Button
var _boton_membrana: Button


func preparar() -> void:
	senal = float(params.get("senal", senal))
	foco = str(params.get("foco", foco))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var v := fila_valor(c, "Señal del calibrador")
	barra(c, 0.0, 20.0, 0.5, senal, func(n: float) -> void:
		senal = n
		v.text = "%s mA" % coma(n, 1))
	v.text = "%s mA" % coma(senal, 1)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_boton_aire = boton_mando(fila, func() -> void:
		sin_aire = not sin_aire
		_actualizar())
	_boton_membrana = boton_mando(fila, func() -> void:
		membrana_fuga = not membrana_fuga
		_actualizar())
	_salida = fila_valor(c, "Presión al actuador")
	_posicion = fila_valor(c, "Posición de la válvula")
	_actualizar()
	resolver()
	giro = float(resultado.get("posicion", 0.0)) / 100.0


func _actualizar() -> void:
	_boton_aire.text = "Abrir el aire" if sin_aire else "Cortar el aire"
	_boton_membrana.text = "Cambiar la junta" if membrana_fuga else ("Fuga en la junta" if foco == "actuador" else "Fuga en la membrana")


func resolver() -> Dictionary:
	resultado = SimNeumatica.posicionador({"posicionador": {"senal": senal, "sin_aire": sin_aire, "membrana_fuga": membrana_fuga}})
	return resultado


## 1 cerrada; 2 regulando; 3 en falla (sin aire, sin señal o sin llegar a la posición pedida).
func fase() -> int:
	var pedida := clampf((senal - 4.0) / 16.0, 0.0, 1.0) * 100.0
	if sin_aire or senal < SimNeumatica.MA_MINIMO or absf(float(resultado.get("posicion", 0.0)) - pedida) > 1.0:
		return 3
	return 2 if float(resultado.get("posicion", 0.0)) > 0.5 else 1


func _process(delta: float) -> void:
	resolver()
	giro = move_toward(giro, float(resultado.get("posicion", 0.0)) / 100.0, delta * 0.8)
	if _salida != null:
		_salida.text = "%s bar" % coma(resultado.get("P_salida", 0.0), 1)
		_posicion.text = "%d %%" % roundi(resultado.get("posicion", 0.0))
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoNeumatico.FONDO)
	var r := resultado
	# Calibrador de lazo a la izquierda con su pantalla.
	var cal := Rect2(12, 30, 86, 120)
	DibujoAri.pieza(l, cal, 8.0, [Color("ffe27a"), Color("e8b21f"), Color("8a6400")], [], DibujoNeumatico.CONTORNO)
	DibujoAri.relleno(l, Rect2(cal.position.x + 8, cal.position.y + 12, cal.size.x - 16, 30), 3.0, Color("10140f"))
	texto(Vector2(cal.get_center().x, cal.position.y + 32), "%s mA" % coma(senal, 2), 13, Color("ffc23a"))
	texto(Vector2(cal.get_center().x, cal.position.y + 64), "CALIBRADOR", 8, Color("3a2a00"))
	texto(Vector2(cal.get_center().x, cal.position.y + 76), "4–20 mA", 8, Color("3a2a00"))
	# Cables del lazo: rojo + y negro −.
	var hay_senal := senal >= SimNeumatica.MA_MINIMO
	l.draw_line(Vector2(cal.end.x, 110), Vector2(150, 110), DibujoNeumatico.CONTORNO, 5.0, true)
	l.draw_line(Vector2(cal.end.x, 110), Vector2(150, 110), Color("d9302b"), 3.0, true)
	l.draw_line(Vector2(cal.end.x, 124), Vector2(150, 124), DibujoNeumatico.CONTORNO, 5.0, true)
	l.draw_line(Vector2(cal.end.x, 124), Vector2(150, 124), Color("2a2f33"), 3.0, true)
	if hay_senal:
		for k in 4:
			var px := cal.end.x + fposmod(t * 40.0 + k * 13.0, 150.0 - cal.end.x)
			l.draw_circle(Vector2(px, 110), 1.8, Color(1, 0.85, 0.5, 0.9))
	# Posicionador con su pantalla.
	var pos := Rect2(150, 74, 118, 80)
	DibujoAri.pieza(l, pos, 8.0, [Color("5a6570"), Color("2c343c"), Color("171c21")], [], DibujoNeumatico.CONTORNO)
	DibujoAri.relleno(l, Rect2(pos.position.x + 12, pos.position.y + 12, 70, 26), 3.0, Color("0b1410"))
	texto(Vector2(pos.position.x + 47, pos.position.y + 30), ("%s %%" % coma(r.get("posicion", 0.0), 1)) if hay_senal else "", 12, Color("9fffb0"))
	texto(Vector2(pos.get_center().x, pos.end.y - 12), "POSICIONADOR", 8, Color("cfd8df"))
	# Alimentación y salida con manómetros.
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(452, 50), Vector2(300, 50), Vector2(300, 92), Vector2(pos.end.x, 92)]), "" if sin_aire else "presion", t * 30.0)
	var salida := float(r.get("P_salida", 0.0))
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(pos.end.x, 132), Vector2(330, 132), Vector2(330, 168)]), "presion" if salida > 0.05 else "", t * 30.0 if absf(giro * 100.0 - float(r.get("posicion", 0.0))) > 0.5 else -1.0)
	DibujoNeumatico.manometro(l, fuente, Vector2(300, 28), 15.0, float(r.get("P_alim", 0.0)), 10.0)
	DibujoNeumatico.manometro(l, fuente, Vector2(372, 132), 15.0, salida, 10.0)
	texto(Vector2(372, 158), "SALIDA", 8, Color("cfd8df"))
	texto(Vector2(338, 30), "ALIM.", 8, Color("cfd8df"))
	# Actuador de piñón y cremallera sobre la tubería, con el indicador y la mariposa.
	var act := Rect2(250, 168, 160, 34)
	DibujoAri.pieza(l, act, 6.0, [Color("f2f5f7"), Color("c3ccd3"), Color("a7b1b9"), Color("6c767e")], [], DibujoNeumatico.CONTORNO)
	for cx: float in [act.position.x - 12.0, act.end.x - 2.0]:
		DibujoAri.pieza(l, Rect2(cx, act.position.y - 3, 14, act.size.y + 6), 3.0, [Color("5a6570"), Color("2c343c"), Color("171c21")], [], DibujoNeumatico.CONTORNO)
	var eje := Vector2(act.get_center().x, act.position.y - 2)
	l.draw_line(eje, Vector2(eje.x, pos.end.y), Color("aab4bb"), 4.0)  # eje de realimentación
	var indicador := Vector2(eje.x, 164)
	l.draw_circle(indicador, 9.0, Color("141a1f"))
	var u := Vector2.from_angle(giro * PI / 2.0)
	l.draw_line(indicador - u * 8.0, indicador + u * 8.0, Color("f2b81f"), 4.0, true)
	# Tubería y mariposa, a la izquierda abajo.
	var tubo := Rect2(110, 196, 130, 26)
	DibujoAri.pieza(l, tubo, 3.0, [Color("6f9fd0"), Color("3a6ea6"), Color("1f4675"), Color("132c4b")], [], DibujoNeumatico.CONTORNO)
	var c_mar := Vector2(175, 209)
	var largo := 11.0 * absf(cos(giro * PI / 2.0)) + 2.0
	DibujoAri.relleno(l, Rect2(c_mar.x - largo / 2.0, tubo.position.y + 2, largo, tubo.size.y - 4), 2.0, Color("dfe5e9"))
	texto(Vector2(175, 186), "abierta %d %%" % roundi(giro * 100.0), 9, Color("cfd8df"))
	if sin_aire:
		DibujoHidraulico.rotulo(l, fuente, Vector2(212, 60), "SIN AIRE: EL MUELLE CIERRA", 9, Color("ffb020"))
	elif not hay_senal:
		DibujoHidraulico.rotulo(l, fuente, Vector2(212, 60), "SIN SEÑAL: POSICIÓN DE FALLA", 9, Color("ffb020"))
	elif membrana_fuga and fase() == 3:
		DibujoHidraulico.rotulo(l, fuente, Vector2(212, 60), "FUGA: NO LLEGA A LA POSICIÓN", 9, Color("ffb020"))
