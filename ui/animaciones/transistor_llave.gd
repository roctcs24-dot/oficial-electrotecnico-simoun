extends Animacion
## Transistor NPN como interruptor: una salida de 24 V de una tarjeta da corriente a la base
## por RB y el transistor conecta a 0 V la bobina de un relé de 24 V y 640 Ω (37,5 mA). Con
## ganancia mínima de 100 (valor típico — verificar en la hoja de datos) satura si
## IB × 100 ≥ IC; si no, queda en zona activa y se calienta. Sin el diodo supresor, al cortar
## la bobina aparece un pico de tensión que perfora el transistor.

const ANCHO := 420.0
const ALTO := 230.0
const V := 24.0
const R_BOBINA := 640.0
const VBE := 0.7
const GANANCIA := 100.0
## Pico al cortar una bobina sin diodo, para el dibujo (orden de magnitud).
const PICO_SIN_DIODO := 300.0

var orden := true
var rb_kohm := 10.0
var con_diodo := true
## El transistor quedó perforado por el pico de la bobina.
var roto := false
var _estado: Label
var _nota: Label
var _boton_orden: Button
var _boton_diodo: Button


static func corriente_base(rb_ohm: float) -> float:
	return (V - VBE) / rb_ohm


static func corriente_bobina() -> float:
	return V / R_BOBINA


static func satura(rb_ohm: float) -> bool:
	return corriente_base(rb_ohm) * GANANCIA >= corriente_bobina()


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var rb := fila_valor(c, "Resistencia de base RB")
	barra(c, 1.0, 220.0, 1.0, rb_kohm, func(v: float) -> void:
		rb_kohm = v
		rb.text = "%d kΩ" % roundi(v)
		_actualizar())
	rb.text = "%d kΩ" % roundi(rb_kohm)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_boton_orden = boton_mando(fila, conmutar_orden)
	_boton_diodo = boton_mando(fila, conmutar_diodo)
	_estado = fila_valor(c, "Transistor")
	_nota = nota_mandos(c)
	_actualizar()


func conmutar_orden() -> void:
	if roto:
		roto = false
	elif orden and not con_diodo:
		# Al cortar sin diodo, la bobina dispara un pico que perfora el transistor.
		roto = true
	orden = not orden
	_actualizar()


func conmutar_diodo() -> void:
	con_diodo = not con_diodo
	_actualizar()


func estado() -> String:
	if roto:
		return "perforado"
	if not orden:
		return "cortado"
	return "saturado" if satura(rb_kohm * 1000.0) else "activo"


func rele_cerrado() -> bool:
	return estado() in ["saturado", "activo"] or roto


func _actualizar() -> void:
	if _nota == null:
		return
	_boton_orden.text = "Quitar la orden" if orden else "Dar la orden (24 V)"
	_boton_diodo.text = "Quitar el diodo" if con_diodo else "Poner el diodo"
	var ib := corriente_base(rb_kohm * 1000.0) * 1000.0
	match estado():
		"saturado":
			_estado.text = "saturado · IB %s mA" % coma(ib, 2)
			_nota.text = "IB × 100 = %s mA, más de los 37,5 mA de la bobina: conduce del todo, con unos 0,2 V entre colector y emisor." % coma(ib * GANANCIA, 0)
		"activo":
			_estado.text = "zona activa · IB %s mA" % coma(ib, 2)
			_nota.text = "IB es poca: el transistor conduce a medias, cae tensión entre colector y emisor y se calienta. Baje RB."
		"cortado":
			_estado.text = "cortado"
			_nota.text = "Sin corriente de base no conduce: la bobina queda sin tensión." + (" El diodo absorbió el pico." if con_diodo else "")
		_:
			_estado.text = "perforado"
			_nota.text = "Sin diodo, la bobina dio un pico de cientos de voltios al cortar y perforó el transistor: el relé queda pegado. Ponga el diodo y vuelva a dar la orden."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	var tinta := Tema.TINTA
	var activo := rele_cerrado()
	var vivo := Color("d02a1e")
	var corriente := Color(Tema.ACENTO_FUERTE, 0.9)
	# Riel de +24 V y de 0 V.
	l.draw_line(Vector2(250, 20), Vector2(380, 20), vivo, 3.0)
	texto(Vector2(400, 20), "+24 V", 11, vivo)
	l.draw_line(Vector2(250, 214), Vector2(380, 214), Color("2565c4"), 3.0)
	texto(Vector2(400, 214), "0 V", 11, Color("2565c4"))
	# Bobina del relé y diodo en paralelo.
	l.draw_line(Vector2(300, 20), Vector2(300, 50), tinta, 2.0)
	l.draw_rect(Rect2(284, 50, 32, 46), Color("e4e7e9") if not activo else Color("ffe7a0"))
	l.draw_rect(Rect2(284, 50, 32, 46), tinta, false, 2.0)
	texto(Vector2(300, 73), "K1", 12, tinta)
	l.draw_line(Vector2(300, 96), Vector2(300, 130), tinta, 2.0)
	if con_diodo:
		l.draw_line(Vector2(300, 34), Vector2(350, 34), tinta, 1.5)
		l.draw_line(Vector2(350, 34), Vector2(350, 112), tinta, 1.5)
		l.draw_line(Vector2(350, 112), Vector2(300, 112), tinta, 1.5)
		l.draw_colored_polygon(PackedVector2Array([Vector2(340, 84), Vector2(360, 84), Vector2(350, 66)]), tinta)
		l.draw_line(Vector2(340, 64), Vector2(360, 64), tinta, 2.0)
	# Transistor NPN: colector arriba, emisor abajo.
	var c := Vector2(300, 160)
	l.draw_circle(c, 26.0, Color("cfd6dc") if not roto else Color("e8a39a"))
	l.draw_arc(c, 26.0, 0, TAU, 32, tinta, 2.0)
	l.draw_line(Vector2(290, 144), Vector2(290, 176), tinta, 3.0)
	l.draw_line(Vector2(290, 152), Vector2(300, 134), tinta, 2.0)
	l.draw_line(Vector2(300, 134), Vector2(300, 130), tinta, 2.0)
	l.draw_line(Vector2(290, 168), Vector2(300, 186), tinta, 2.0)
	flecha(Vector2(292, 170), Vector2(301, 186), tinta, 2.0)
	l.draw_line(Vector2(300, 186), Vector2(300, 214), tinta, 2.0)
	texto(Vector2(336, 160), "Q1", 12, tinta)
	# Base: salida de la tarjeta y RB.
	l.draw_line(Vector2(40, 160), Vector2(150, 160), vivo if orden else tinta, 2.0)
	l.draw_rect(Rect2(150, 150, 60, 20), Color("e4e7e9"))
	l.draw_rect(Rect2(150, 150, 60, 20), tinta, false, 2.0)
	texto(Vector2(180, 140), "RB %d kΩ" % roundi(rb_kohm), 11, tinta)
	l.draw_line(Vector2(210, 160), Vector2(290, 160), tinta, 2.0)
	l.draw_style_box(Tema.caja(Color("2b3640") if not orden else Color("2e9c3c"), 5, 0, 0), Rect2(14, 140, 52, 40))
	texto(Vector2(40, 153), "S1", 11, Color.WHITE)
	texto(Vector2(40, 168), "24 V" if orden else "0 V", 11, Color.WHITE)
	# Puntos de corriente por la bobina.
	if activo and not roto:
		var paso := fmod(t * 60.0, 24.0)
		var y := 24.0 + paso
		while y < 210.0:
			l.draw_circle(Vector2(300, y), 3.0, corriente)
			y += 24.0
	if roto:
		rotulo_estado(Vector2(150, 40), "pico sin diodo: Q1 perforado", Tema.FALLO)
	elif estado() == "activo":
		rotulo_estado(Vector2(150, 40), "zona activa: Q1 se calienta", Color("b06a00"))
	elif estado() == "saturado":
		rotulo_estado(Vector2(150, 40), "saturado: K1 cerrado", Tema.ACIERTO)
	else:
		rotulo_estado(Vector2(150, 40), "cortado: K1 abierto", Color("5b6267"))
	l.draw_set_transform(Vector2.ZERO)
