extends Animacion
## Potencia activa, reactiva y aparente de una salida de 380 V con 40 kW de motores.
## tipo "compensacion": se conectan los condensadores y se elige su potencia; el triángulo de
## potencias se acorta y la corriente baja, como en la simulación (compensacion_servicio).
## tipo "analizador": se elige el factor de potencia de la carga y se ven las ondas de tensión y
## de corriente desfasadas, con lo que muestra la pantalla del analizador.

const ANCHO := 420.0
const ALTO := 290.0
const V_LINEA := 380.0
const P_KW := 40.0
const Q_CARGA := 35.0

var con_bateria := true
var q_bateria := 25.0
var fp_carga := 0.8
var _interruptor: Interruptor
var _pantalla: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c: VBoxContainer
	if _analizador():
		c = tarjeta_mandos()
		var fp := fila_valor(c, "Factor de potencia de la carga")
		fp.text = ("%.2f" % fp_carga).replace(".", ",")
		barra(c, 0.5, 1.0, 0.05, fp_carga, func(v: float) -> void:
			fp_carga = v
			fp.text = ("%.2f" % v).replace(".", ",")
			_actualizar())
	else:
		_interruptor = Interruptor.new()
		_interruptor.button_pressed = con_bateria
		_interruptor.toggled.connect(conectar)
		tarjeta_control("Batería de condensadores", "Toque para conectarla o quitarla", _interruptor)
		c = tarjeta_mandos()
		var kvar := fila_valor(c, "Potencia de la batería")
		kvar.text = "%d kvar" % roundi(q_bateria)
		barra(c, 5.0, 45.0, 5.0, q_bateria, func(v: float) -> void:
			q_bateria = v
			kvar.text = "%d kvar" % roundi(v)
			_actualizar())
	_pantalla = fila_valor(c, "Analizador")
	_nota = nota_mandos(c)
	_actualizar()


func _analizador() -> bool:
	return params.get("tipo", "compensacion") == "analizador"


func conectar(si: bool) -> void:
	con_bateria = si
	_interruptor.set_pressed_no_signal(si)
	_interruptor.queue_redraw()
	_actualizar()


func p() -> float:
	return P_KW


## Reactiva neta: positiva inductiva, negativa capacitiva.
func q() -> float:
	if _analizador():
		return P_KW * tan(acos(fp_carga))
	return Q_CARGA - (q_bateria if con_bateria else 0.0)


func s() -> float:
	return sqrt(p() * p() + q() * q())


func fp() -> float:
	return p() / s()


func _fp_texto() -> String:
	return ("%.2f" % fp()).replace(".", ",")


func corriente() -> float:
	return s() * 1000.0 / (sqrt(3.0) * V_LINEA)


## Compensación: 1 sin la batería, 3 con ella. El analizador muestra todo: 3.
func fase() -> int:
	return 3 if _analizador() or con_bateria else 1


func _actualizar() -> void:
	if _nota == null:
		return
	_pantalla.text = "FP %s %s · %d A" % [_fp_texto(), "ind" if q() >= 0.0 else "cap", roundi(corriente())]
	if _analizador():
		_nota.text = "P %s kW · Q %s kvar · S %s kVA. La corriente se retrasa %d° de la tensión: cuanto más retraso, más corriente para la misma potencia." % [coma(p()), coma(q()), coma(s()), roundi(rad_to_deg(acos(fp())))]
	elif not con_bateria:
		_nota.text = "Sin compensar: los generadores dan %d kvar a los motores y la corriente es de %d A." % [roundi(q()), roundi(corriente())]
	elif q() < 0.0:
		_nota.text = "Sobrecompensado: el factor de potencia es capacitivo. Una batería mayor de lo necesario es tan mala como ninguna."
	else:
		_nota.text = "Compensado: la batería da %d kvar y la corriente baja a %d A para los mismos %d kW." % [roundi(q_bateria), roundi(corriente()), roundi(p())]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	if _analizador():
		_dibujar_ondas()
	else:
		_dibujar_triangulo()
	lienzo.draw_set_transform(Vector2.ZERO)


func _dibujar_triangulo() -> void:
	texto(Vector2(210, 12), "TRIÁNGULO DE POTENCIAS", 12, Color("5b6267"))
	var escala := 4.0
	var o := Vector2(60, 200)
	var fin_p := o + Vector2(p() * escala, 0)
	flecha(o, fin_p, Color("2f7fd0"), 4.0)
	texto(o + Vector2(p() * escala / 2.0, 16), "P %d kW" % roundi(p()), 12, Color("2f7fd0"))
	var fin_ql := fin_p + Vector2(0, -Q_CARGA * escala)
	flecha(fin_p, fin_ql, Color("c0392b"), 4.0)
	texto_derecha(fin_ql + Vector2(-8, 8), "QL %d kvar" % roundi(Q_CARGA), 11, Color("c0392b"))
	var punta := fin_ql
	if con_bateria:
		punta = fin_ql + Vector2(0, q_bateria * escala)
		flecha(fin_ql + Vector2(14, 0), punta + Vector2(14, 0), Color("23804a"), 4.0)
		texto(punta + Vector2(66, -6), "QC %d kvar" % roundi(q_bateria), 11, Color("23804a"))
	flecha(o, punta, Tema.TINTA, 3.0)
	texto(o + (punta - o) * 0.5 + Vector2(-34, -10), "S %d kVA" % roundi(s()), 12, Tema.TINTA)
	lienzo.draw_arc(o, 40.0, 0.0, -atan2(q(), p()), 16, Color("8a949b"), 2.0)
	texto(o + Vector2(54, -12), "φ", 13, Tema.TINTA)
	var bien := fp() >= 0.9 and q() >= 0.0
	rotulo_estado(Vector2(320, 250), "FP %s · %d A" % [_fp_texto(), roundi(corriente())], Tema.ACIERTO if bien else Tema.FALLO)


func _dibujar_ondas() -> void:
	texto(Vector2(210, 12), "TENSIÓN Y CORRIENTE DE UNA FASE", 12, Color("5b6267"))
	var o := Vector2(20, 120)
	lienzo.draw_line(o, o + Vector2(380, 0), Color("8a949b"), 1.0)
	var desfase := acos(fp())
	var v_ant := o
	var i_ant := o
	for k in 191:
		var x := k * 2.0
		var a := x / 380.0 * TAU * 2.0 - t * 1.5
		var v := sin(a) * 70.0
		var i := sin(a - desfase) * 50.0
		var pv := o + Vector2(x, -v)
		var pi := o + Vector2(x, -i)
		if k % 4 == 0:
			var prod := v * i / 3500.0
			lienzo.draw_line(o + Vector2(x, 0), o + Vector2(x, -prod * 40.0), Color(0.18, 0.5, 0.82, 0.25) if prod >= 0.0 else Color(0.75, 0.22, 0.17, 0.3), 3.0)
		if k > 0:
			lienzo.draw_line(v_ant, pv, Color("c0392b"), 2.5)
			lienzo.draw_line(i_ant, pi, Color("2f7fd0"), 2.5)
		v_ant = pv
		i_ant = pi
	texto(Vector2(30, 40), "U", 13, Color("c0392b"), false)
	texto(Vector2(50, 40), "I", 13, Color("2f7fd0"), false)
	texto(Vector2(70, 40), "U × I: azul suma potencia, rojo la devuelve", 10, Tema.TINTA, false)
	# Pantalla del analizador.
	lienzo.draw_style_box(Tema.caja(Color("cfe0c8"), 4, 0, 0, Color("5b6267")), Rect2(60, 206, 300, 72))
	texto(Vector2(80, 222), "U12 %d V    I1 %d A" % [roundi(V_LINEA), roundi(corriente())], 13, Tema.TINTA, false)
	texto(Vector2(80, 244), "P %s kW    Q %s kvar" % [coma(p()), coma(q())], 13, Tema.TINTA, false)
	texto(Vector2(80, 266), "S %s kVA    FP %s ind" % [coma(s()), _fp_texto()], 13, Tema.TINTA, false)
