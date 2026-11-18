extends Animacion
## Carga y descarga de un condensador a través de una resistencia, con 24 V DC:
## u(t) = V × (1 − e^(−t/τ)) al cargar y u(t) = V × e^(−t/τ) al descargar, con τ = R × C.
## A las 5 τ se considera cargado (99 %). El tiempo de la animación va escalado.

const ANCHO := 420.0
const ALTO := 220.0
const V := 24.0
const CAPACIDADES := [100e-6, 470e-6, 1000e-6]

var r_kohm := 10.0
var c_faradios := 470e-6
var cargando := true
## Segundos simulados desde el último cambio.
var _ts := 0.0
var _u0 := 0.0
var _tau_lbl: Label
var _u_lbl: Label
var _boton: Button
var _botones_c: Array[Button] = []


static func tau(r_ohm: float, c: float) -> float:
	return r_ohm * c


static func tension_carga(v: float, t_s: float, tau_s: float) -> float:
	return v * (1.0 - exp(-t_s / tau_s))


static func tension_descarga(v0: float, t_s: float, tau_s: float) -> float:
	return v0 * exp(-t_s / tau_s)


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var r_lbl := fila_valor(c, "Resistencia R")
	barra(c, 1.0, 47.0, 1.0, r_kohm, func(v: float) -> void:
		r_kohm = v
		r_lbl.text = "%d kΩ" % roundi(v)
		_reiniciar())
	r_lbl.text = "%d kΩ" % roundi(r_kohm)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for cap: float in CAPACIDADES:
		var b := boton_mando(fila, poner_capacidad.bind(cap))
		b.text = "%d µF" % roundi(cap * 1e6)
		_botones_c.append(b)
	_boton = boton_mando(c, conmutar)
	_tau_lbl = fila_valor(c, "τ = R × C")
	_u_lbl = fila_valor(c, "Tensión en C")
	_actualizar()


func poner_capacidad(cap: float) -> void:
	c_faradios = cap
	_reiniciar()


func conmutar() -> void:
	_u0 = tension_actual()
	cargando = not cargando
	_ts = 0.0
	_actualizar()


func _reiniciar() -> void:
	_u0 = 0.0
	cargando = true
	_ts = 0.0
	_actualizar()


func tau_s() -> float:
	return tau(r_kohm * 1000.0, c_faradios)


func tension_actual() -> float:
	if cargando:
		return _u0 + (V - _u0) * (1.0 - exp(-_ts / tau_s()))
	return tension_descarga(_u0, _ts, tau_s())


func _process(delta: float) -> void:
	# Cinco constantes de tiempo pasan en unos 4 segundos de pantalla.
	_ts += delta * tau_s() * 5.0 / 4.0
	if _u_lbl != null:
		_u_lbl.text = "%s V" % coma(tension_actual())
	super(delta)


func _actualizar() -> void:
	if _boton == null:
		return
	_boton.text = "Descargar sobre R" if cargando else "Cargar desde 24 V"
	for k in CAPACIDADES.size():
		_botones_c[k].modulate = Color(1, 1, 1, 1.0 if is_equal_approx(CAPACIDADES[k], c_faradios) else 0.55)
	_tau_lbl.text = "%s s (5 τ: %s s)" % [coma(tau_s(), 2), coma(tau_s() * 5.0, 1)]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(210, 12), "CARGA DE UN CONDENSADOR CON 24 V" if cargando else "DESCARGA SOBRE LA RESISTENCIA", 12, Color("5b6267"))
	# Ejes de la curva.
	var o := Vector2(50, 180)
	var w := 340.0
	var h := 140.0
	l.draw_line(o, o + Vector2(w, 0), Tema.TINTA, 1.5)
	l.draw_line(o, o - Vector2(0, h), Tema.TINTA, 1.5)
	for k in range(1, 6):
		var x := o.x + w * k / 5.0
		l.draw_line(Vector2(x, o.y), Vector2(x, o.y - h), Color(0, 0, 0, 0.1), 1.0)
		texto(Vector2(x, o.y + 12), "%d τ" % k, 10, Tema.TINTA)
	texto_derecha(Vector2(o.x - 4, o.y - h), "24 V", 10, Tema.TINTA)
	texto_derecha(Vector2(o.x - 4, o.y - h * 0.632), "63 %", 10, Color("2565c4"))
	l.draw_line(Vector2(o.x, o.y - h * 0.632), Vector2(o.x + w / 5.0, o.y - h * 0.632), Color("2565c4", 0.5), 1.0)
	var puntos := PackedVector2Array()
	for i in 101:
		var x := float(i) / 100.0 * 5.0
		var u := (1.0 - exp(-x)) if cargando else exp(-x)
		if not cargando:
			u *= _u0 / V
		elif _u0 > 0.0:
			u = (_u0 + (V - _u0) * (1.0 - exp(-x))) / V
		puntos.append(o + Vector2(w * x / 5.0, -h * u))
	l.draw_polyline(puntos, Color("2e9c3c"), 3.0, true)
	var avance := clampf(_ts / tau_s() / 5.0, 0.0, 1.0)
	var p := o + Vector2(w * avance, -h * tension_actual() / V)
	l.draw_circle(p, 6.0, Tema.ACENTO_FUERTE)
	l.draw_circle(p, 3.0, Color.WHITE)
	l.draw_set_transform(Vector2.ZERO)
