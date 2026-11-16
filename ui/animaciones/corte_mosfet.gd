extends Animacion
## MOSFET de canal N que enciende un foco de 24 V y 48 W (12 Ω), con los niveles de SimMosfet:
## por debajo de 3 V de puerta no conduce; desde 8 V conduce pleno con 0,03 Ω; en medio, con
## 5 Ω, se calienta y por encima de 3 W se quema en corto.

const ANCHO := 400.0
const ALTO := 260.0
const V := 24.0
const R_FOCO := 12.0

var vgs := 0.0
var quemado := false
var _modelo: SimMosfet
var _cambiar: Button
var _valores: Label
var _nota: Label


func preparar() -> void:
	_modelo = SimMosfet.new("Q1")
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var g := fila_valor(c, "Tensión de puerta G-S")
	g.text = "0 V"
	barra(c, 0.0, 12.0, 0.5, vgs, func(v: float) -> void:
		g.text = "%s V" % coma(v, 1)
		poner_vgs(v))
	_valores = fila_valor(c, "Corriente / calor en Q1")
	_cambiar = boton_mando(c, cambiar)
	_cambiar.text = "Cambiar el MOSFET"
	_nota = nota_mandos(c)
	_actualizar()


func poner_vgs(v: float) -> void:
	vgs = clampf(v, 0.0, 12.0)
	if potencia() > float(_modelo.params["p_max"]):
		quemado = true
	_actualizar()


func cambiar() -> void:
	quemado = false
	poner_vgs(vgs)


func nivel() -> int:
	return _modelo._nivel(vgs)


func r_ds() -> float:
	if quemado:
		return SimMosfet.R_CORTO
	match nivel():
		2:
			return float(_modelo.params["r_on"])
		1:
			return float(_modelo.params["r_media"])
	return SimMosfet.R_OFF


func corriente() -> float:
	return V / (R_FOCO + r_ds())


func potencia() -> float:
	return corriente() * corriente() * r_ds()


## 1 apagado; 2 conduciendo pleno; 3 a medias (o quemado).
func fase() -> int:
	if quemado or nivel() == 1:
		return 3
	return 2 if nivel() == 2 else 1


func _actualizar() -> void:
	if _nota == null:
		return
	_cambiar.visible = quemado
	_valores.text = "%s A / %s W" % [coma(corriente(), 2), coma(potencia(), 2)]
	if quemado:
		_nota.text = "Conduciendo a medias disipaba más de 3 W: se quemó en corto y el foco ya no se apaga."
	elif nivel() == 0:
		_nota.text = "Por debajo de unos 3 V de puerta el canal está cerrado: foco apagado."
	elif nivel() == 1:
		_nota.text = "Conduce a medias, con unos 5 Ω: se calienta. Con esta tensión de puerta acabará quemándose."
	else:
		_nota.text = "Con la puerta plena conduce con 0,03 Ω: 2 A y apenas 0,1 W de calor."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "MOSFET DE CANAL N CON UN FOCO DE 24 V", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	var i := corriente()
	var luz := clampf(i / 2.0, 0.0, 1.0)
	# Foco.
	l.draw_line(Vector2(260, 30), Vector2(260, 60), Color("c0392b"), 3.0)
	texto(Vector2(300, 30), "+24 V", 10, tinta)
	if luz > 0.05:
		l.draw_circle(Vector2(260, 82), 28.0 + 8.0 * luz, Color(1.0, 0.85, 0.3, 0.35 * luz))
	l.draw_circle(Vector2(260, 82), 22.0, Color("fff2b0").lerp(Color("ffd84a"), luz) if luz > 0.05 else Color("e9ebe8"))
	l.draw_arc(Vector2(260, 82), 22.0, 0, TAU, 24, tinta, 2.0)
	l.draw_line(Vector2(260, 104), Vector2(260, 140), Tema.ACENTO_FUERTE if luz > 0.05 else Color("8a949b"), 3.0)
	# Canal del MOSFET: más ancho cuanto más conduce.
	var cuerpo := Rect2(220, 140, 80, 60)
	var calor := clampf(potencia() / 3.0, 0.0, 1.0)
	l.draw_rect(cuerpo, Color("4a5056").lerp(Color("d9541e"), calor if not quemado else 1.0))
	var ancho_canal := 0.0 if nivel() == 0 and not quemado else (6.0 if nivel() == 1 and not quemado else 22.0)
	if ancho_canal > 0.0:
		l.draw_rect(Rect2(260 - ancho_canal / 2.0, 140, ancho_canal, 60), Color("7fb3e8"))
	texto(Vector2(260, 212), "D arriba · S abajo", 9, tinta)
	l.draw_line(Vector2(260, 200), Vector2(260, 236), tinta, 3.0)
	l.draw_line(Vector2(60, 236), Vector2(340, 236), tinta, 3.0)
	texto(Vector2(40, 236), "0 V", 10, tinta)
	# Puerta.
	l.draw_line(Vector2(80, 170), Vector2(212, 170), Tema.ACENTO_FUERTE if vgs > 0.0 else Color("8a949b"), 3.0)
	l.draw_line(Vector2(212, 150), Vector2(212, 190), tinta, 4.0)
	texto(Vector2(120, 156), "G · %s V" % coma(vgs, 1), 12, tinta)
	if i > 0.05:
		for k in 4:
			var y := 106.0 + fmod(t * 60.0 * clampf(i, 0.3, 2.0) + k * 32.0, 128.0)
			l.draw_circle(Vector2(260, y), 3.0, Tema.ACENTO_FUERTE)
	var rotulo: String = "EN CORTO" if quemado else ["APAGADO", "A MEDIAS: CALIENTA", "CONDUCE PLENO"][nivel()]
	rotulo_estado(Vector2(110, 236), rotulo, Tema.FALLO if quemado or nivel() == 1 else (Tema.ACIERTO if nivel() == 2 else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
