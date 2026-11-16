extends Animacion
## Relé de estado sólido con una resistencia de 230 V, con los valores de SimReleEstadoSolido:
## con orden en 3-4, el optoacoplador interno manda el triac y la carga recibe 230 V; sin orden,
## la fuga de unos 40 kΩ deja poco más de 1 V en la carga. Sin la carga conectada, el multímetro
## (10 MΩ) mide casi 230 V en la salida aunque el relé esté apagado: la tensión fantasma.

const ANCHO := 400.0
const ALTO := 260.0
const V := 230.0
const R_CARGA := 230.0
const R_MULTIMETRO := 1e7

var orden := false
var sin_carga := false
var quemado := false
var _r_off := 40000.0
var _r_on := 0.05
var _interruptor: Interruptor
var _carga: Button
var _quemar: Button
var _lectura: Label
var _nota: Label


func preparar() -> void:
	var modelo := SimReleEstadoSolido.new("K1")
	_r_off = float(modelo.params["r_off"])
	_r_on = float(modelo.params["r_on"])
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.toggled.connect(poner_orden)
	tarjeta_control("Orden de 24 V en 3-4", "Toque para dar o quitar la orden", _interruptor)
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_carga = boton_mando(fila, func() -> void: quitar_carga(not sin_carga))
	_quemar = boton_mando(fila, func() -> void:
		if quemado:
			cambiar()
		else:
			quemar())
	_lectura = fila_valor(c, "Multímetro en la salida")
	_nota = nota_mandos(c)
	_actualizar()


func poner_orden(si: bool) -> void:
	orden = si
	if _interruptor != null:
		_interruptor.set_pressed_no_signal(si)
		_interruptor.queue_redraw()
	_actualizar()


func quitar_carga(si: bool) -> void:
	sin_carga = si
	_actualizar()


func quemar() -> void:
	quemado = true
	_actualizar()


func cambiar() -> void:
	quemado = false
	_actualizar()


func _r_rele() -> float:
	return _r_on if orden or quemado else _r_off


## Lo que marca el multímetro entre la salida 2 y X2.
func tension_salida() -> float:
	var r_abajo := R_MULTIMETRO if sin_carga else R_CARGA * R_MULTIMETRO / (R_CARGA + R_MULTIMETRO)
	return V * r_abajo / (r_abajo + _r_rele())


func calienta() -> bool:
	return not sin_carga and (orden or quemado)


## 1 apagado; 2 conduciendo; 3 tensión fantasma sin carga.
func fase() -> int:
	if sin_carga and not orden and not quemado:
		return 3
	return 2 if orden or quemado else 1


func _actualizar() -> void:
	if _nota == null:
		return
	_carga.text = "Conectar la carga" if sin_carga else "Quitar la carga"
	_quemar.text = "Cambiar el relé" if quemado else "Sobrecorriente"
	_lectura.text = "%s V" % coma(tension_salida(), 0 if tension_salida() >= 20.0 else 1)
	if quemado:
		_nota.text = "Una sobrecorriente lo dejó en corto: la carga queda conectada con o sin orden."
	elif fase() == 3:
		_nota.text = "Sin carga, la fuga del relé y los 10 MΩ del multímetro hacen marcar casi 230 V con el relé apagado: no es una avería. Mida con la carga puesta."
	elif orden:
		_nota.text = "La orden enciende el LED interno; el triac conduce y la resistencia recibe 230 V."
	else:
		_nota.text = "Sin orden bloquea, pero deja pasar unos miliamperios de fuga: en la carga queda poco más de 1 V."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "RELÉ DE ESTADO SÓLIDO", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	l.draw_style_box(Tema.caja(Color("dfe2e4"), 8, 0, 0, Color("5b6267")), Rect2(130, 40, 140, 150))
	texto(Vector2(200, 176), "SSR", 12, tinta)
	# Mando con el LED interno.
	var mando := Color("c0392b") if orden else Color("8a949b")
	l.draw_line(Vector2(40, 80), Vector2(130, 80), mando, 3.0)
	l.draw_line(Vector2(40, 150), Vector2(130, 150), tinta, 3.0)
	texto(Vector2(60, 68), "3 (+)", 10, tinta)
	texto(Vector2(60, 164), "4 (−)", 10, tinta)
	l.draw_colored_polygon(PackedVector2Array([Vector2(150, 100), Vector2(170, 100), Vector2(160, 118)]), Color("ff5a45") if orden else Color("8a949b"))
	l.draw_line(Vector2(150, 119), Vector2(170, 119), tinta, 2.5)
	if orden:
		for k in 2:
			var x := 176.0 + fmod(t * 30.0 + k * 8.0, 18.0)
			l.draw_line(Vector2(x, 104 + k * 8), Vector2(x + 5, 104 + k * 8), Color("ff9a8a"), 2.0)
	# Triac de salida.
	var conduce := orden or quemado
	var color := Tema.ACENTO_FUERTE if conduce else tinta
	l.draw_colored_polygon(PackedVector2Array([Vector2(214, 96), Vector2(236, 96), Vector2(225, 112)]), color)
	l.draw_colored_polygon(PackedVector2Array([Vector2(214, 128), Vector2(236, 128), Vector2(225, 112)]), color)
	l.draw_line(Vector2(225, 70), Vector2(225, 96), tinta, 2.0)
	l.draw_line(Vector2(225, 128), Vector2(225, 160), tinta, 2.0)
	# Carga.
	l.draw_line(Vector2(270, 70), Vector2(340, 70), Color("c0392b"), 3.0)
	texto(Vector2(296, 58), "1 · 230 V", 10, tinta)
	l.draw_line(Vector2(270, 160), Vector2(310, 160), tinta, 3.0)
	texto(Vector2(290, 176), "2", 10, tinta)
	if not sin_carga:
		l.draw_rect(Rect2(310, 150, 50, 20), Color("ffb08a") if calienta() else Color.WHITE)
		l.draw_rect(Rect2(310, 150, 50, 20), tinta, false, 2.0)
		texto(Vector2(335, 186), "RL", 10, tinta)
	else:
		texto(Vector2(340, 160), "suelta", 10, Tema.FALLO)
	# El multímetro en la salida.
	l.draw_style_box(Tema.caja(Color("e8c43a"), 6, 0, 0, Color("7a6416")), Rect2(300, 200, 80, 44))
	texto(Vector2(340, 222), "%s V" % coma(tension_salida(), 0), 14, tinta)
	var rotulo := "EN CORTO" if quemado else ("CONDUCE" if orden else ("TENSIÓN FANTASMA" if sin_carga else "APAGADO"))
	rotulo_estado(Vector2(150, 230), rotulo, Tema.FALLO if quemado or fase() == 3 else (Tema.ACIERTO if orden else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
