extends Animacion
## Potenciómetro de 10 kΩ como consigna de velocidad de un variador: el extremo 1 a 0 V, el 3 a
## la referencia de +10 V y el cursor 2 a la entrada AI1. El cursor da 10 V × posición, y el
## variador lo lee como 0-50 Hz. Con la pista gastada en el centro, el cursor pierde el contacto
## al pasar por ahí y la consigna cae a 0, como SimPotenciometro con cursor_sin_contacto.

const ANCHO := 400.0
const ALTO := 260.0
const V_REF := 10.0
const F_MAX := 50.0
const OHM := 10000.0
## Tramo gastado de la pista, en fracción de giro.
const GASTADO := [0.45, 0.58]
## Arco de la pista: de 1 (abajo a la izquierda) a 3 (abajo a la derecha), en grados.
const ANGULO_1 := 225.0
const ANGULO_3 := -45.0

var posicion := 0.5
var gastada := false
var _gastar: Button
var _consigna: Label
var _nota: Label
var _giro_motor := 0.0


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var g := fila_valor(c, "Giro del mando")
	g.text = "%d %%" % roundi(posicion * 100.0)
	barra(c, 0.0, 1.0, 0.01, posicion, func(v: float) -> void:
		g.text = "%d %%" % roundi(v * 100.0)
		poner_posicion(v))
	_consigna = fila_valor(c, "Cursor 2-1 / variador")
	_gastar = boton_mando(c, func() -> void: gastar(not gastada))
	_nota = nota_mandos(c)
	_actualizar()


func poner_posicion(p: float) -> void:
	posicion = clampf(p, 0.0, 1.0)
	_actualizar()


func gastar(si: bool) -> void:
	gastada = si
	_actualizar()


func sin_contacto() -> bool:
	return gastada and posicion >= GASTADO[0] and posicion <= GASTADO[1]


func tension_cursor() -> float:
	return 0.0 if sin_contacto() else V_REF * posicion


func frecuencia() -> float:
	return F_MAX * tension_cursor() / V_REF


## 1 al mínimo; 2 con el cursor sin contacto; 3 dando consigna.
func fase() -> int:
	if sin_contacto():
		return 2
	return 1 if tension_cursor() <= 0.0 else 3


func _actualizar() -> void:
	if _nota == null:
		return
	_consigna.text = "%s V · %s Hz" % [coma(tension_cursor(), 1), coma(frecuencia(), 0)]
	_gastar.text = "Cambiar el potenciómetro" if gastada else "Gastar la pista en el centro"
	if sin_contacto():
		_nota.text = "El cursor pasa por la zona gastada y pierde el contacto: AI1 queda al aire, la consigna cae a 0 y el motor da un tirón."
	elif posicion <= 0.0:
		_nota.text = "Cursor junto al extremo 1 (0 V): consigna 0 V y el variador parado a 0 Hz."
	else:
		_nota.text = "R 1-2 = %s kΩ y R 2-3 = %s kΩ: el cursor da %s V de los 10 V." % [coma(OHM * posicion / 1000.0, 1), coma(OHM * (1.0 - posicion) / 1000.0, 1), coma(tension_cursor(), 1)]


func _process(delta: float) -> void:
	_giro_motor += delta * frecuencia() * 0.25
	super._process(delta)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "POTENCIÓMETRO COMO CONSIGNA DE VELOCIDAD", 12, Color("5b6267"))
	var centro := Vector2(120, 120)
	var radio := 66.0
	# Pista: un arco de carbón; el tramo gastado, más claro.
	l.draw_arc(centro, radio, deg_to_rad(-ANGULO_1), deg_to_rad(-ANGULO_3), 48, Color("3a2a1e"), 12.0)
	if gastada:
		l.draw_arc(centro, radio, deg_to_rad(-_angulo(GASTADO[0])), deg_to_rad(-_angulo(GASTADO[1])), 12, Color("b9a58c"), 12.0)
	# Extremos 1 y 3, con su tensión.
	var p1 := centro + Vector2.from_angle(deg_to_rad(-ANGULO_1)) * radio
	var p3 := centro + Vector2.from_angle(deg_to_rad(-ANGULO_3)) * radio
	l.draw_line(p1, p1 + Vector2(0, 40), Color("20242a"), 3.0)
	l.draw_line(p3, p3 + Vector2(0, 40), Color("c0392b"), 3.0)
	texto(p1 + Vector2(0, 50), "1 · 0 V", 11, Tema.TINTA)
	texto(p3 + Vector2(0, 50), "3 · +10 V", 11, Color("c0392b"))
	# Cursor: el brazo gira con el eje.
	var punta := centro + Vector2.from_angle(deg_to_rad(-_angulo(posicion))) * (radio - 2.0)
	l.draw_line(centro, punta, Color("6b7176"), 6.0)
	l.draw_circle(punta, 6.0, Color("e05a2b") if sin_contacto() else Color("c8a03a"))
	l.draw_circle(centro, 14.0, Color("9aa1a6"))
	l.draw_circle(centro, 6.0, Color("5b6267"))
	texto(centro + Vector2(0, 36), "2", 12, Tema.TINTA)
	# Cable del cursor al variador.
	var color_cursor := Color("8a949b") if tension_cursor() <= 0.0 else Tema.ACENTO_FUERTE
	l.draw_polyline(PackedVector2Array([centro, Vector2(230, 120)]), color_cursor, 3.0)
	l.draw_style_box(Tema.caja(Color.WHITE, 6, 0, 0, Color("20242a")), Rect2(230, 70, 140, 100))
	texto(Vector2(300, 88), "VARIADOR", 11, Color("5b6267"))
	texto(Vector2(300, 112), "AI1 %s V" % coma(tension_cursor(), 1), 13, Tema.TINTA)
	texto(Vector2(300, 140), "%s Hz" % coma(frecuencia(), 0), 20, Tema.TINTA)
	# Motor que gira según la frecuencia.
	var m := Vector2(300, 212)
	l.draw_circle(m, 24.0, Color("9aa1a6"))
	for k in 3:
		var a := _giro_motor * TAU + k * TAU / 3.0
		l.draw_line(m, m + Vector2.from_angle(a) * 20.0, Color("3b444b"), 4.0)
	texto(Vector2(370, 212), "M", 14, Tema.TINTA)
	l.draw_set_transform(Vector2.ZERO)


## Ángulo del cursor para una posición de 0 (en 1) a 1 (en 3).
func _angulo(p: float) -> float:
	return lerpf(ANGULO_1, ANGULO_3, clampf(p, 0.0, 1.0))
