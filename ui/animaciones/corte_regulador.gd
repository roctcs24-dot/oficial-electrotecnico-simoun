extends Animacion
## Regulador 7812 con una carga de 24 Ω, con las cuentas y la protección térmica de SimRegulador:
## la salida es 12 V mientras la entrada pase de 14 V; el calor (Vin − Vout) × I sube la
## temperatura hacia 40 °C + P × Rth (5 K/W con disipador, 50 K/W sin él) con una constante de
## 20 s. A 150 °C corta la salida y vuelve a 120 °C.

const ANCHO := 400.0
const ALTO := 260.0
const R_CARGA := 24.0

var entrada := 24.0
var disipador := true
var temperatura := SimRegulador.AMBIENTE
var corte := false
var _p: Dictionary
var _disipador: Button
var _valores: Label
var _nota: Label


func preparar() -> void:
	_p = SimRegulador.new("U2").params
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var e := fila_valor(c, "Tensión de entrada")
	e.text = "%d V" % roundi(entrada)
	barra(c, 0.0, 30.0, 1.0, entrada, func(v: float) -> void:
		e.text = "%d V" % roundi(v)
		poner_entrada(v))
	_disipador = boton_mando(c, func() -> void: poner_disipador(not disipador))
	_valores = fila_valor(c, "Salida / calor / temperatura")
	_nota = nota_mandos(c)
	_actualizar()


func poner_entrada(v: float) -> void:
	entrada = maxf(v, 0.0)
	_actualizar()


func poner_disipador(si: bool) -> void:
	disipador = si
	_actualizar()


func salida() -> float:
	if corte:
		return 0.0
	return clampf(entrada - float(_p["caida_min"]), 0.0, float(_p["vout"]))


func corriente() -> float:
	return salida() / R_CARGA


func potencia() -> float:
	return maxf(entrada - salida(), 0.0) * corriente()


func avanzar(dt: float) -> void:
	var rth := float(_p["rth_disipador"]) if disipador else float(_p["rth_sin"])
	var final := SimRegulador.AMBIENTE + potencia() * rth
	temperatura = final + (temperatura - final) * exp(-dt / float(_p["tau_s"]))
	if not corte and temperatura >= SimRegulador.T_CORTE:
		corte = true
	elif corte and temperatura <= SimRegulador.T_REARME:
		corte = false
	_actualizar()


## 1 sin regular (entrada baja); 2 regulando; 3 corte térmico.
func fase() -> int:
	if corte:
		return 3
	return 2 if entrada - float(_p["caida_min"]) >= float(_p["vout"]) else 1


func _process(delta: float) -> void:
	avanzar(delta)
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_disipador.text = "Quitar el disipador" if disipador else "Poner el disipador"
	_valores.text = "%s V / %s W / %d °C" % [coma(salida(), 1), coma(potencia(), 1), roundi(temperatura)]
	match fase():
		1:
			_nota.text = "Con menos de 14 V de entrada no le queda su caída mínima de 2 V: la salida baja con la entrada."
		2:
			_nota.text = "Regula: 12 V fijos. Lo que sobra, (%s − 12) × %s A = %s W, se va en calor." % [coma(entrada, 0), coma(corriente(), 2), coma(potencia(), 1)]
		3:
			_nota.text = "Pasó de 150 °C: la protección térmica cortó la salida. Volverá al enfriarse a 120 °C, y así una y otra vez."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "REGULADOR 7812 Y SU CALOR", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	# Regulador con su disipador.
	if disipador:
		for k in 6:
			l.draw_rect(Rect2(150 + k * 18, 40, 8, 60), Color("9aa1a6"))
	var calor := clampf((temperatura - 40.0) / 110.0, 0.0, 1.0)
	l.draw_rect(Rect2(160, 96, 80, 50), Color("2a2e32").lerp(Color("e05a2b"), calor))
	texto(Vector2(200, 121), "7812", 13, Color.WHITE)
	l.draw_line(Vector2(40, 121), Vector2(160, 121), Color("c0392b"), 3.0)
	texto(Vector2(80, 108), "IN %s V" % coma(entrada, 0), 11, tinta)
	l.draw_line(Vector2(240, 121), Vector2(330, 121), Tema.ACENTO_FUERTE if salida() > 0.5 else Color("8a949b"), 3.0)
	texto(Vector2(290, 108), "OUT %s V" % coma(salida(), 1), 11, tinta)
	l.draw_rect(Rect2(330, 111, 40, 20), Color("fff2b0") if salida() > 0.5 else Color.WHITE)
	l.draw_rect(Rect2(330, 111, 40, 20), tinta, false, 2.0)
	texto(Vector2(350, 146), "24 Ω", 10, tinta)
	l.draw_line(Vector2(200, 146), Vector2(200, 170), tinta, 3.0)
	texto(Vector2(220, 162), "GND", 10, tinta)
	# Termómetro.
	var marco := Rect2(40, 190, 320, 16)
	l.draw_rect(marco, Color.WHITE)
	l.draw_rect(Rect2(marco.position, Vector2(marco.size.x * clampf((temperatura - 20.0) / 150.0, 0.0, 1.0), marco.size.y)), Color("2f9e4f").lerp(Tema.FALLO, calor))
	l.draw_rect(marco, Color("8a949b"), false, 1.5)
	var x_corte := marco.position.x + marco.size.x * (SimRegulador.T_CORTE - 20.0) / 150.0
	l.draw_line(Vector2(x_corte, 184), Vector2(x_corte, 212), Tema.FALLO, 2.0)
	texto(Vector2(x_corte, 222), "150 °C corta", 9, Tema.FALLO)
	texto(Vector2(80, 222), "%d °C" % roundi(temperatura), 12, tinta)
	var rotulo := "CORTE TÉRMICO" if corte else ("REGULA" if fase() == 2 else "SIN REGULAR")
	rotulo_estado(Vector2(200, 246), rotulo, Tema.FALLO if corte else (Tema.ACIERTO if fase() == 2 else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
