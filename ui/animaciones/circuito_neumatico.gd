extends Animacion
## Circuito neumático animado con SimNeumatica: red de aire de control, secador, unidad de filtro y
## regulador, válvula 5/2 monoestable (o 5/3 de centro cerrado), reguladores de caudal en los
## escapes y cilindro de doble efecto con los detectores B1 y B2. Según «foco» cambia el mando que
## se ajusta: el regulador del escape, la presión regulada y el filtro, el secador o la segunda
## bobina.
## Parámetros: "foco" (cilindro, regulador, 52, 53, fr, secador), "apertura" (0 a 1), "regulado" (bar).

const ANCHO := 460.0
const ALTO := 236.0
const CARRERA := 200.0  # mm

var foco := "cilindro"
var y1 := false
var y2 := false
var apertura := 0.3
var regulado := 6.0
var filtro_sucio := false
var secador_averiado := false
## Posición del vástago: 0 dentro, 1 fuera.
var x := 0.0
## Agua en el vaso del filtro (0 a 1): sube con el secador averiado.
var agua := 0.1
var resultado := {}
var _flujo := 0.0
var _corredera := 0.0
var _botones := {}
var _presion: Label
var _velocidad: Label
var _detectores: Label
var _boton_falla: Button


func preparar() -> void:
	foco = str(params.get("foco", foco))
	apertura = float(params.get("apertura", apertura))
	regulado = float(params.get("regulado", regulado))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_botones["y1"] = boton_mando(fila, func() -> void:
		y1 = not y1
		if es_53() and y1:
			y2 = false
		_actualizar_botones())
	if es_53():
		_botones["y2"] = boton_mando(fila, func() -> void:
			y2 = not y2
			if y2:
				y1 = false
			_actualizar_botones())
	match foco:
		"fr":
			var v := fila_valor(c, "Presión regulada")
			barra(c, 2.0, 7.0, 0.5, regulado, func(n: float) -> void:
				regulado = n
				v.text = "%s bar" % coma(n, 1))
			v.text = "%s bar" % coma(regulado, 1)
			_boton_falla = boton_mando(c, func() -> void:
				filtro_sucio = not filtro_sucio
				_actualizar_botones())
		"secador":
			_boton_falla = boton_mando(c, func() -> void:
				secador_averiado = not secador_averiado
				_actualizar_botones())
		_:
			var v := fila_valor(c, "Regulador del escape")
			barra(c, 5.0, 100.0, 5.0, apertura * 100.0, func(n: float) -> void:
				apertura = n / 100.0
				v.text = "%d %%" % roundi(n))
			v.text = "%d %%" % roundi(apertura * 100.0)
	_presion = fila_valor(c, "Manómetro del regulador")
	_velocidad = fila_valor(c, "Velocidad del vástago" if foco != "secador" else "Punto de rocío a presión")
	_detectores = fila_valor(c, "Detectores")
	_actualizar_botones()
	resolver()


func es_53() -> bool:
	return foco == "53"


func _actualizar_botones() -> void:
	_botones["y1"].text = ("Y1 · avanza" if es_53() else "Bobina Y1") if not y1 else ("Quitar Y1")
	_botones["y1"].modulate = Color(1.0, 0.85, 0.4) if y1 else Color.WHITE
	if _botones.has("y2"):
		_botones["y2"].text = "Y2 · retrocede" if not y2 else "Quitar Y2"
		_botones["y2"].modulate = Color(1.0, 0.85, 0.4) if y2 else Color.WHITE
	if _boton_falla != null:
		if foco == "fr":
			_boton_falla.text = "Cambiar el cartucho" if filtro_sucio else "Ensuciar el cartucho del filtro"
		else:
			_boton_falla.text = "Reparar el secador" if secador_averiado else "Averiar el secador"


func parametros() -> Dictionary:
	return {
		"fr": {"regulado": regulado, "filtro_sucio": 1.0 if filtro_sucio else 0.0},
		"secador": {"averiado": secador_averiado},
		"valvula": {"tipo": "53" if es_53() else "52", "y1": y1, "y2": y2},
		"reguladores": {"avance": apertura, "retroceso": apertura},
	}


func resolver() -> Dictionary:
	resultado = SimNeumatica.resolver(parametros())
	resultado["rocio"] = SimNeumatica.red(parametros())["rocio"]
	return resultado


func b1() -> bool:
	return x <= 0.01


func b2() -> bool:
	return x >= 0.99


func fase() -> int:
	var estado := str(resultado.get("estado", ""))
	if estado in ["avanza", "retrocede"] and ((estado == "avanza" and not b2()) or (estado == "retrocede" and not b1())):
		return 2
	return 3 if b2() else 1


func _process(delta: float) -> void:
	resolver()
	var v := float(resultado.get("velocidad", 0.0))
	match str(resultado.get("estado", "")):
		"avanza":
			x = minf(x + v / CARRERA * delta, 1.0)
		"retrocede":
			x = maxf(x - v / CARRERA * delta, 0.0)
	agua = move_toward(agua, 0.85 if secador_averiado else 0.1, delta * 0.08)
	_flujo += delta * 30.0
	var objetivo := 0.0
	if y1:
		objetivo = 1.0
	elif y2:
		objetivo = -1.0
	_corredera = move_toward(_corredera, objetivo, delta * 5.0)
	if _presion != null:
		_presion.text = "%s bar" % coma(resultado.get("P_reg", 0.0), 1)
		if foco == "secador":
			_velocidad.text = "%d °C" % roundi(resultado.get("rocio", 0.0))
		else:
			var moviendo: bool = (resultado.get("estado", "") == "avanza" and not b2()) or (resultado.get("estado", "") == "retrocede" and not b1())
			_velocidad.text = "%d mm/s" % roundi(v) if moviendo else "parado"
		_detectores.text = "B1 %s · B2 %s" % ["24 V" if b1() else "0 V", "24 V" if b2() else "0 V"]
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoNeumatico.FONDO)
	var r := resultado
	var estado := str(r.get("estado", ""))
	var moviendo := (estado == "avanza" and not b2()) or (estado == "retrocede" and not b1())
	var f := _flujo
	# Red, secador y unidad de filtro y regulador.
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(8, 196), Vector2(54, 196)]), "presion", f if moviendo else -1.0)
	_secador(l, fuente, Rect2(54, 168, 46, 52))
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(100, 196), Vector2(118, 196)]), "presion", f if moviendo else -1.0)
	_fr(l, fuente, Vector2(150, 196))
	var c_valvula := Vector2(312, 170)
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(182, 196), Vector2(240, 196), Vector2(240, 214), Vector2(c_valvula.x, 214), Vector2(c_valvula.x, c_valvula.y + 16)]), "presion", f if moviendo else -1.0)
	# Bocas 4 y 2 hacia el cilindro, con su regulador de caudal.
	var papel_4 := ""
	var papel_2 := ""
	var sentido := SimNeumatica.mando(SimNeumatica.completar(parametros()))
	if sentido > 0:
		papel_4 = "presion"
		papel_2 = "escape" if moviendo else ""
	elif sentido < 0:
		papel_4 = "escape" if moviendo else ""
		papel_2 = "presion"
	var x4 := c_valvula.x - 14.0
	var x2 := c_valvula.x + 14.0
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(x4, c_valvula.y - 16), Vector2(x4, 120), Vector2(244, 120), Vector2(244, 64)]), papel_4, (f if papel_4 == "presion" else -f) if moviendo or papel_4 == "presion" else -1.0)
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(x2, c_valvula.y - 16), Vector2(x2, 132), Vector2(392, 132), Vector2(392, 64)]), papel_2, (f if papel_2 == "presion" else -f) if moviendo or papel_2 == "presion" else -1.0)
	_regulador(l, Vector2(244, 92), sentido < 0 and moviendo)
	_regulador(l, Vector2(392, 92), sentido > 0 and moviendo)
	_valvula(l, fuente, c_valvula, sentido, moviendo)
	_cilindro(l, fuente)
	DibujoNeumatico.manometro(l, fuente, Vector2(150, 140), 17.0, float(r.get("P_reg", 0.0)), 10.0)
	if estado == "no_mueve":
		DibujoHidraulico.rotulo(l, fuente, Vector2(320, 222), "LA CARGA PIDE MÁS DE LA PRESIÓN: NO SE MUEVE", 9, Color("ffb020"))
	elif foco == "fr" and filtro_sucio and moviendo:
		DibujoHidraulico.rotulo(l, fuente, Vector2(150, 108), "FILTRO SUCIO: CAE LA PRESIÓN", 9, Color("ffb020"))
	elif secador_averiado:
		DibujoHidraulico.rotulo(l, fuente, Vector2(150, 108), "AGUA EN EL AIRE: PURGUE", 9, Color("ffb020"))


func _secador(l: Control, fuente: Font, r: Rect2) -> void:
	DibujoAri.pieza(l, r, 4.0, [Color("f4f1e8"), Color("d8d3c4"), Color("a9a393")], [], DibujoNeumatico.CONTORNO)
	for k in 4:
		DibujoAri.relleno(l, Rect2(r.position.x + 6, r.position.y + 24 + k * 6, 22, 3), 1.0, Color("3c454e"))
	DibujoAri.relleno(l, Rect2(r.end.x - 16, r.position.y + 6, 12, 9), 2.0, Color("0b1410"))
	l.draw_circle(Vector2(r.end.x - 10, r.position.y + 24), 2.6, Color("ff4a3a") if secador_averiado else Color("2fbf5a"))
	texto(Vector2(r.get_center().x, r.position.y - 7), "SECADOR", 8, Color("cfd8df"))


func _fr(l: Control, fuente: Font, c: Vector2) -> void:
	DibujoHidraulico.pieza(l, Rect2(c.x - 32, c.y - 12, 64, 24), 4.0)
	# Vaso del filtro con su cartucho y el agua; purga abajo.
	var vaso := Rect2(c.x - 30, c.y + 12, 24, 20)
	DibujoAri.relleno(l, vaso, 4.0, Color(0.75, 0.86, 0.93, 0.35))
	DibujoAri.relleno(l, Rect2(vaso.position.x + 2, vaso.end.y - vaso.size.y * agua, vaso.size.x - 4, vaso.size.y * agua), 3.0, Color(0.31, 0.62, 0.9, 0.85))
	DibujoAri.relleno(l, Rect2(c.x - 22, c.y + 13, 8, 12), 2.0, Color("8a6a3a") if filtro_sucio else Color("cfc6a8"))
	# Regulador: pomo arriba.
	DibujoAri.pieza(l, Rect2(c.x + 6, c.y - 30, 22, 18), 4.0, [Color("3a3f44"), Color("1c2024"), Color("0b0d0f")], [], DibujoNeumatico.CONTORNO)
	texto(Vector2(c.x, c.y + 44), "FILTRO · REGULADOR", 8, Color("cfd8df"))


func _regulador(l: Control, c: Vector2, frenando: bool) -> void:
	if frenando:
		l.draw_circle(c, 13.0, Color(1.0, 0.69, 0.0, 0.25))
	DibujoHidraulico.pieza(l, Rect2(c.x - 9, c.y - 6, 18, 12), 2.0)
	DibujoAri.pieza(l, Rect2(c.x - 5, c.y - 16, 10, 10), 2.0, [Color("3a3f44"), Color("1c2024"), Color("0b0d0f")], [], DibujoNeumatico.CONTORNO)
	var hueco := 1.0 + 5.0 * apertura
	DibujoAri.relleno(l, Rect2(c.x - hueco / 2.0, c.y - 3, hueco, 6), 1.0, Color("9fd0ff"))


func _valvula(l: Control, fuente: Font, c: Vector2, sentido: int, moviendo: bool) -> void:
	var cuerpo := Rect2(c.x - 46, c.y - 16, 92, 32)
	DibujoHidraulico.pieza(l, cuerpo, 4.0)
	DibujoAri.relleno(l, Rect2(c.x - 38, c.y - 5, 76, 10), 3.0, Color("20262c"))
	var dx := _corredera * 8.0
	for k in 3:
		DibujoAri.relleno(l, Rect2(c.x - 32 + k * 24 + dx, c.y - 4, 14, 8), 2.0, Color("dfe5e9"))
	DibujoNeumatico.bobina(l, fuente, Rect2(cuerpo.position.x - 32, c.y - 12, 32, 24), "Y1", y1)
	if es_53():
		DibujoNeumatico.bobina(l, fuente, Rect2(cuerpo.end.x, c.y - 12, 32, 24), "Y2", y2)
	else:
		DibujoHidraulico.pieza(l, Rect2(cuerpo.end.x, c.y - 10, 14, 20), 4.0)
	# Silenciadores 5 y 3: sopla el que recibe el escape.
	var soplo5 := 1.0 if sentido > 0 and moviendo else 0.0
	var soplo3 := 1.0 if sentido < 0 and moviendo else 0.0
	DibujoNeumatico.silenciador(l, Vector2(c.x - 30, cuerpo.end.y), soplo5, t)
	DibujoNeumatico.silenciador(l, Vector2(c.x + 30, cuerpo.end.y), soplo3, t)
	for par: Array in [[c.x - 14, c.y - 24, "4"], [c.x + 14, c.y - 24, "2"], [c.x - 42, c.y + 26, "5"], [c.x + 42, c.y + 26, "3"]]:
		texto(Vector2(par[0], par[1]), par[2], 9, Color("ffc23a"))


func _cilindro(l: Control, fuente: Font) -> void:
	var cuerpo := Rect2(236, 34, 166, 28)
	var vastago := 12.0 + x * 40.0
	DibujoAri.pieza(l, Rect2(cuerpo.end.x - 4, cuerpo.position.y + 9, vastago, 10), 3.0, [Color("ffffff"), Color("cfd6db"), Color("7d868d")], [], DibujoNeumatico.CONTORNO)
	DibujoAri.pieza(l, cuerpo, 3.0, [Color("f2f5f7"), Color("c3ccd3"), Color("a7b1b9"), Color("6c767e")], [], DibujoNeumatico.CONTORNO)
	for cx in [cuerpo.position.x - 8.0, cuerpo.end.x - 4.0]:
		DibujoAri.pieza(l, Rect2(cx, cuerpo.position.y - 4, 12, cuerpo.size.y + 8), 2.0, [Color("5a6570"), Color("2c343c"), Color("171c21")], [], DibujoNeumatico.CONTORNO)
	var px := cuerpo.position.x + 10.0 + x * (cuerpo.size.x - 30.0)
	DibujoAri.relleno(l, Rect2(px, cuerpo.position.y + 6, 8, cuerpo.size.y - 12), 1.0, Color("3c454e"))
	DibujoNeumatico.detector(l, fuente, Vector2(cuerpo.position.x + 22, cuerpo.position.y + 3), "B1", b1())
	DibujoNeumatico.detector(l, fuente, Vector2(cuerpo.end.x - 22, cuerpo.position.y + 3), "B2", b2())
	texto(Vector2(cuerpo.get_center().x, cuerpo.get_center().y + 4), "Ø 63 × 200", 9, Color("26303a"))
