extends Animacion
## Transistor NPN que manda la bobina de un relé de 24 V (640 Ω) desde una orden de 24 V por la
## resistencia de base RB, como transistor_servicio. Con base de sobra satura (0,2 V); con una RB
## grande trabaja en activa, el relé no entra y el transistor se calienta. Al quitar la orden, la
## bobina da un pico: con el diodo supresor no pasa nada; sin él, el transistor se perfora.

const ANCHO := 400.0
const ALTO := 260.0
const V := 24.0
const VBE := 0.7
const VCE_SAT := 0.2
const BETA := 100.0
const R_BOBINA := 640.0
const ENTRA := 0.7
const RB := [[10000.0, "10 kΩ"], [100000.0, "100 kΩ"], [470000.0, "470 kΩ"]]
const PICO_S := 1.5

var orden := false
var indice := 0
var supresor := true
var quemado := false
var _desde_pico := 99.0
var _interruptor: Interruptor
var _botones: Array[Button] = []
var _supresor: Button
var _valores: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_orden)
	tarjeta_control("Orden de la tarjeta (S1)", "Toque para dar o quitar la orden", _interruptor)
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for i in RB.size():
		var b := boton_mando(fila, elegir_rb.bind(i))
		b.text = "RB " + RB[i][1]
		_botones.append(b)
	_supresor = boton_mando(c, func() -> void:
		if quemado:
			cambiar()
		else:
			poner_supresor(not supresor))
	_valores = fila_valor(c, "C-E / bobina")
	_nota = nota_mandos(c)
	_actualizar()


func poner_orden(si: bool) -> void:
	if orden and not si:
		_desde_pico = 0.0
		if not supresor and not quemado and saturado_o_activa():
			quemado = true
	orden = si
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(si)
		_interruptor.queue_redraw()
	_actualizar()


func elegir_rb(i: int) -> void:
	indice = clampi(i, 0, RB.size() - 1)
	_actualizar()


func poner_supresor(si: bool) -> void:
	supresor = si
	_actualizar()


func cambiar() -> void:
	quemado = false
	_actualizar()


func corriente_base() -> float:
	return (V - VBE) / float(RB[indice][0]) if orden else 0.0


func _ic_carga() -> float:
	return (V - VCE_SAT) / R_BOBINA


func saturado() -> bool:
	return orden and BETA * corriente_base() >= _ic_carga()


func saturado_o_activa() -> bool:
	return corriente_colector() > 0.001


func corriente_colector() -> float:
	if quemado:
		return V / R_BOBINA
	return minf(BETA * corriente_base(), _ic_carga()) if orden else 0.0


func vce() -> float:
	if quemado:
		return 0.0
	if saturado():
		return VCE_SAT
	return V - corriente_colector() * R_BOBINA


func rele_entra() -> bool:
	return corriente_colector() * R_BOBINA >= ENTRA * V


## 1 sin orden; 2 con orden; 3 el pico de la bobina al quitarla.
func fase() -> int:
	if _desde_pico < PICO_S:
		return 3
	return 2 if orden else 1


func _process(delta: float) -> void:
	_desde_pico += delta
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if k == indice else 0.6)
	_supresor.text = "Cambiar el transistor" if quemado else ("Quitar el diodo supresor" if supresor else "Poner el diodo supresor")
	_valores.text = "%s V / %s V" % [coma(vce(), 1), coma(V - vce(), 1)]
	if quemado:
		_nota.text = "Sin diodo supresor, el pico de la bobina perforó el transistor: C-E en corto y el relé no suelta."
	elif not orden:
		_nota.text = "Sin corriente de base no conduce: toda la tensión queda entre C y E y el relé está suelto."
	elif saturado():
		_nota.text = "Ib = %s mA: β · Ib supera los 37 mA de la bobina y se satura con 0,2 V. El relé entra." % coma(corriente_base() * 1000.0, 2)
	else:
		_nota.text = "Ib = %s mA no basta: el colector solo lleva %s mA, quedan %s V entre C y E y el relé %s. El transistor se calienta." % [coma(corriente_base() * 1000.0, 3), coma(corriente_colector() * 1000.0, 1), coma(vce(), 1), "entra justo" if rele_entra() else "no entra"]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "TRANSISTOR NPN QUE MANDA UN RELÉ", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	var vivo := Tema.ACENTO_FUERTE
	var ic := corriente_colector()
	# Bobina y diodo supresor.
	l.draw_line(Vector2(60, 30), Vector2(320, 30), Color("c0392b"), 3.0)
	texto(Vector2(36, 30), "+24 V", 10, tinta)
	l.draw_line(Vector2(240, 30), Vector2(240, 60), Color("c0392b"), 3.0)
	l.draw_rect(Rect2(222, 60, 36, 40), Color("ffe08a") if rele_entra() else Color.WHITE)
	l.draw_rect(Rect2(222, 60, 36, 40), tinta, false, 2.5)
	texto(Vector2(286, 80), "K1", 12, tinta)
	l.draw_line(Vector2(240, 100), Vector2(240, 130), vivo if ic > 0.001 else Color("8a949b"), 3.0)
	if supresor:
		l.draw_polyline(PackedVector2Array([Vector2(240, 44), Vector2(320, 44), Vector2(320, 70)]), tinta, 2.0)
		l.draw_colored_polygon(PackedVector2Array([Vector2(310, 92), Vector2(330, 92), Vector2(320, 72)]), tinta)
		l.draw_line(Vector2(310, 72), Vector2(330, 72), tinta, 3.0)
		l.draw_polyline(PackedVector2Array([Vector2(320, 92), Vector2(320, 116), Vector2(240, 116)]), tinta, 2.0)
		texto(Vector2(352, 82), "D1", 10, tinta)
	# Transistor.
	l.draw_line(Vector2(222, 140), Vector2(222, 180), tinta, 4.0)
	l.draw_line(Vector2(222, 150), Vector2(240, 130), vivo if ic > 0.001 else tinta, 3.0)
	l.draw_line(Vector2(222, 170), Vector2(240, 190), vivo if ic > 0.001 else tinta, 3.0)
	l.draw_line(Vector2(240, 190), Vector2(240, 230), tinta, 3.0)
	texto(Vector2(262, 160), "Q1", 12, tinta)
	# Base.
	var color_base := vivo if orden else Color("8a949b")
	l.draw_line(Vector2(60, 160), Vector2(110, 160), color_base, 3.0)
	l.draw_rect(Rect2(110, 152, 50, 16), Color.WHITE)
	l.draw_rect(Rect2(110, 152, 50, 16), tinta, false, 2.0)
	texto(Vector2(135, 182), "RB " + RB[indice][1], 10, tinta)
	l.draw_line(Vector2(160, 160), Vector2(222, 160), color_base, 3.0)
	texto(Vector2(40, 160), "orden" if orden else "0 V", 10, tinta)
	l.draw_line(Vector2(60, 230), Vector2(320, 230), tinta, 3.0)
	texto(Vector2(36, 230), "0 V", 10, tinta)
	if _desde_pico < PICO_S and not supresor:
		var brillo := 1.0 - _desde_pico / PICO_S
		l.draw_circle(Vector2(240, 130), 16.0, Color(1.0, 0.8, 0.1, 0.7 * brillo))
		texto(Vector2(330, 140), "pico", 12, Tema.FALLO)
	if ic > 0.001:
		for k in 4:
			var y := 104.0 + fmod(t * 50.0 + k * 30.0, 120.0)
			l.draw_circle(Vector2(240, y), 3.0, vivo)
	texto(Vector2(120, 212), "C-E %s V" % coma(vce(), 1), 12, tinta)
	var rotulo := "EN CORTO" if quemado else ("SATURADO" if saturado() else ("NO SATURA" if orden else "EN CORTE"))
	rotulo_estado(Vector2(330, 248), rotulo, Tema.FALLO if quemado or (orden and not saturado()) else (Tema.ACIERTO if orden else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
