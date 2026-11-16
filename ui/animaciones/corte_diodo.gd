extends Animacion
## Diodo de silicio entre una fuente de 24 V y una carga de 240 Ω, como el diodo de desacople del
## panel de alarmas (diodo_servicio). En directa la unión conduce, el diodo se queda con unos
## 0,7 V y la carga con el resto; al revés, la zona de la unión se ensancha y no pasa corriente.

const ANCHO := 400.0
const ALTO := 260.0
const V_FUENTE := 24.0
const VF := 0.7
const R_CARGA := 240.0

var directa := true
var _girar: Button
var _valores: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	_girar = boton_mando(c, girar)
	_valores = fila_valor(c, "Diodo / carga")
	_nota = nota_mandos(c)
	_actualizar()


func girar() -> void:
	directa = not directa
	_actualizar()


func corriente() -> float:
	return (V_FUENTE - VF) / R_CARGA if directa else 0.0


func tension_diodo() -> float:
	return VF if directa else V_FUENTE


func tension_carga() -> float:
	return corriente() * R_CARGA


## 2 en directa (conduce y cae 0,7 V); 3 al revés (bloquea).
func fase() -> int:
	return 2 if directa else 3


func _actualizar() -> void:
	if _nota == null:
		return
	_girar.text = "Darle la vuelta al diodo"
	_valores.text = "%s V / %s V" % [coma(tension_diodo(), 1), coma(tension_carga(), 1)]
	if directa:
		_nota.text = "Ánodo hacia el +: la unión conduce, pasan %d mA y en el diodo quedan 0,7 V." % roundi(corriente() * 1000.0)
	else:
		_nota.text = "Cátodo hacia el +: la zona de la unión se ensancha, no pasa corriente y el diodo aguanta los 24 V."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "DIODO EN DIRECTA" if directa else "DIODO EN INVERSA", 12, Color("5b6267"))
	# La unión PN, ampliada: P a la izquierda (huecos), N a la derecha (electrones).
	var p := Rect2(110, 40, 90, 90)
	var nn := Rect2(200, 40, 90, 90)
	l.draw_rect(p, Color("f2c6c0"))
	l.draw_rect(nn, Color("c4d8f0"))
	var ancho_zona := 10.0 if directa else 46.0
	l.draw_rect(Rect2(200 - ancho_zona / 2.0, 40, ancho_zona, 90), Color("e9ebe8"))
	l.draw_rect(Rect2(110, 40, 180, 90), Color("20242a"), false, 2.0)
	var paso := t * 30.0 if directa else 0.0
	for fila in 3:
		for k in 4:
			var xp := fmod(118.0 + k * 22.0 + paso, 200.0 - ancho_zona / 2.0 - 118.0) + 118.0 if directa else 118.0 + k * 20.0
			if not directa and xp > 200.0 - ancho_zona / 2.0 - 6.0:
				continue
			texto(Vector2(xp, 58 + fila * 28), "+", 12, Color("c0392b"))
			var xn := 282.0 - fmod(k * 22.0 + paso, 282.0 - (200.0 + ancho_zona / 2.0)) if directa else 282.0 - k * 20.0
			if not directa and xn < 200.0 + ancho_zona / 2.0 + 6.0:
				continue
			texto(Vector2(xn, 58 + fila * 28), "−", 13, Color("2c6e9e"))
	texto(Vector2(155, 142), "P · ánodo" if directa else "P", 11, Tema.TINTA)
	texto(Vector2(245, 142), "N · cátodo" if directa else "N", 11, Tema.TINTA)
	if not directa:
		texto(Vector2(200, 30), "la zona sin portadores se ensancha", 10, Color("5b6267"))
	# Circuito: fuente, diodo y carga.
	var hay := directa
	var cable := Tema.ACENTO_FUERTE if hay else Color("8a949b")
	l.draw_line(Vector2(40, 200), Vector2(40, 170), Color("c0392b"), 3.0)
	l.draw_line(Vector2(28, 186), Vector2(52, 186), Tema.TINTA, 4.0)
	l.draw_line(Vector2(34, 196), Vector2(46, 196), Tema.TINTA, 4.0)
	l.draw_polyline(PackedVector2Array([Vector2(40, 170), Vector2(40, 160), Vector2(150, 160)]), Color("c0392b"), 3.0)
	# Símbolo del diodo en el sentido elegido.
	var punta := 1.0 if directa else -1.0
	var c := Vector2(170, 160)
	l.draw_colored_polygon(PackedVector2Array([c + Vector2(-12 * punta, -10), c + Vector2(-12 * punta, 10), c + Vector2(10 * punta, 0)]), Tema.TINTA)
	l.draw_line(c + Vector2(11 * punta, -11), c + Vector2(11 * punta, 11), Tema.TINTA, 3.5)
	l.draw_line(Vector2(150, 160), Vector2(158, 160), Tema.TINTA, 3.0)
	l.draw_line(Vector2(182, 160), Vector2(260, 160), cable, 3.0)
	l.draw_circle(Vector2(280, 175), 18.0, Color("ffe08a") if hay else Color("cfd3d6"))
	l.draw_arc(Vector2(280, 175), 18.0, 0.0, TAU, 24, Tema.TINTA, 2.0)
	texto(Vector2(280, 175), "RL", 10, Tema.TINTA)
	l.draw_polyline(PackedVector2Array([Vector2(260, 160), Vector2(280, 160), Vector2(280, 157)]), cable, 3.0)
	l.draw_polyline(PackedVector2Array([Vector2(280, 193), Vector2(280, 215), Vector2(40, 215), Vector2(40, 200)]), Color("20242a"), 3.0)
	if hay:
		for k in 6:
			var x := 50.0 + fmod(t * 60.0 + k * 40.0, 220.0)
			l.draw_circle(Vector2(x, 160), 3.0, Tema.ACENTO_FUERTE)
	texto(Vector2(170, 188), "%s V" % coma(tension_diodo(), 1), 12, Tema.TINTA)
	texto(Vector2(340, 175), "%s V" % coma(tension_carga(), 1), 12, Tema.TINTA)
	rotulo_estado(Vector2(200, 242), "CONDUCE" if directa else "BLOQUEA", Tema.ACIERTO if directa else Color("5b6267"))
	l.draw_set_transform(Vector2.ZERO)
