extends Animacion
## Resistencia de 1/4 W con su código de colores en un circuito de continua. Se elige el valor y
## la tensión: la corriente es V / R y la potencia V² / R. Por encima de 1,5 veces su potencia
## nominal se calienta de más y se quema, como SimResistencia.

const ANCHO := 400.0
const ALTO := 260.0
const POTENCIA_W := 0.25
## Valor, bandas (cifra, cifra, multiplicador) y nombre de cada resistencia que se puede elegir.
const VALORES := [
	[470.0, ["amarillo", "violeta", "marrón"], "470 Ω"],
	[1000.0, ["marrón", "negro", "rojo"], "1 kΩ"],
	[4700.0, ["amarillo", "violeta", "rojo"], "4,7 kΩ"],
]
const COLORES := {
	"negro": Color("1c1f22"), "marrón": Color("7a4a24"), "rojo": Color("c0392b"), "naranja": Color("e67e22"),
	"amarillo": Color("e8c20c"), "verde": Color("2f9e4f"), "azul": Color("2c6eb5"), "violeta": Color("7b3fa0"),
	"gris": Color("8a949b"), "blanco": Color("f4f4f0"), "oro": Color("c8a03a"),
}

var tension := 12.0
var indice := 2
var _botones: Array[Button] = []
var _corriente: Label
var _potencia: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for i in VALORES.size():
		var b := boton_mando(fila, elegir.bind(i))
		b.text = VALORES[i][2]
		_botones.append(b)
	var v := fila_valor(c, "Tensión de la fuente")
	v.text = "%d V" % roundi(tension)
	barra(c, 0.0, 24.0, 1.0, tension, func(x: float) -> void:
		v.text = "%d V" % roundi(x)
		poner_tension(x))
	_corriente = fila_valor(c, "Corriente I = V / R")
	_potencia = fila_valor(c, "Potencia P = V² / R")
	_nota = nota_mandos(c)
	_actualizar()


func elegir(i: int) -> void:
	indice = clampi(i, 0, VALORES.size() - 1)
	_actualizar()


func poner_tension(v: float) -> void:
	tension = maxf(v, 0.0)
	_actualizar()


func ohmios() -> float:
	return VALORES[indice][0]


func corriente() -> float:
	return tension / ohmios()


func potencia() -> float:
	return tension * tension / ohmios()


func se_quema() -> bool:
	return potencia() > POTENCIA_W * SimResistencia.MARGEN


## 1 sin tensión; 2 con tensión y dentro de su potencia; 3 calentándose de más.
func fase() -> int:
	if tension <= 0.0:
		return 1
	return 3 if potencia() > POTENCIA_W else 2


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if k == indice else 0.6)
	_corriente.text = "%s mA" % coma(corriente() * 1000.0, 1)
	_potencia.text = "%s W de %s W" % [coma(potencia(), 2), coma(POTENCIA_W, 2)]
	var bandas: Array = VALORES[indice][1]
	if tension <= 0.0:
		_nota.text = "Bandas %s, %s y %s, y oro: %s ±5 %%. Sin tensión no pasa corriente." % [bandas[0], bandas[1], bandas[2], VALORES[indice][2]]
	elif se_quema():
		_nota.text = "Disipa %s veces su potencia nominal: se oscurece y se corta. Ponga una de más vatios o de más ohmios." % coma(potencia() / POTENCIA_W, 1)
	elif potencia() > POTENCIA_W:
		_nota.text = "Pasa de su potencia nominal: trabaja muy caliente y acabará cortándose."
	else:
		_nota.text = "Trabaja holgada: disipa menos de su potencia nominal de 1/4 W."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "RESISTENCIA DE 1/4 W EN CONTINUA", 12, Color("5b6267"))
	var carga := clampf(potencia() / POTENCIA_W, 0.0, 3.0)
	var hay := tension > 0.0
	var cable := Color("c0392b") if hay else Color("8a949b")
	# Circuito: fuente a la izquierda, resistencia arriba.
	l.draw_polyline(PackedVector2Array([Vector2(60, 150), Vector2(60, 70), Vector2(120, 70)]), cable, 3.0)
	l.draw_polyline(PackedVector2Array([Vector2(280, 70), Vector2(340, 70), Vector2(340, 200), Vector2(60, 200), Vector2(60, 170)]), Color("20242a"), 3.0)
	l.draw_line(Vector2(44, 150), Vector2(76, 150), Tema.TINTA, 4.0)
	l.draw_line(Vector2(52, 170), Vector2(68, 170), Tema.TINTA, 4.0)
	texto(Vector2(26, 160), "%d V" % roundi(tension), 12, Tema.TINTA)
	# Cuerpo con las bandas y el brillo del calor.
	var cuerpo := Color("d9bf8c").lerp(Color("5a3a1a"), clampf((carga - 1.0) / 2.0, 0.0, 1.0))
	l.draw_line(Vector2(120, 70), Vector2(140, 70), Color("9aa1a6"), 4.0)
	l.draw_line(Vector2(260, 70), Vector2(280, 70), Color("9aa1a6"), 4.0)
	l.draw_style_box(Tema.caja(cuerpo, 18, 0, 0, Color("8b7355")), Rect2(140, 48, 120, 44))
	var xs := [158, 178, 198]
	var bandas: Array = VALORES[indice][1]
	for k in 3:
		l.draw_rect(Rect2(xs[k], 49, 10, 42), COLORES[bandas[k]])
	l.draw_rect(Rect2(238, 49, 10, 42), COLORES["oro"])
	if carga > 1.0:
		var brillo := clampf((carga - 1.0) / 2.0, 0.0, 1.0) * (0.6 + 0.4 * sin(t * 6.0))
		l.draw_rect(Rect2(140, 48, 120, 44), Color(1.0, 0.35, 0.1, 0.35 * brillo))
		for k in 3:
			var y := 40.0 - fmod(t * 18.0 + k * 9.0, 26.0)
			l.draw_line(Vector2(170 + k * 30, y), Vector2(176 + k * 30, y - 8), Color(0.4, 0.4, 0.4, 0.6), 2.0)
	# Corriente: puntos que avanzan más deprisa cuanto mayor es.
	if hay:
		var camino := PackedVector2Array([Vector2(60, 150), Vector2(60, 70), Vector2(340, 70), Vector2(340, 200), Vector2(60, 200), Vector2(60, 170)])
		var largo := 0.0
		for k in camino.size() - 1:
			largo += camino[k].distance_to(camino[k + 1])
		var velocidad := clampf(corriente() * 4000.0, 15.0, 260.0)
		for k in 10:
			var d := fmod(t * velocidad + k * largo / 10.0, largo)
			l.draw_circle(_punto(camino, d), 3.5, Tema.ACENTO_FUERTE)
	texto(Vector2(200, 112), VALORES[indice][2] + " ±5 %", 12, Tema.TINTA)
	texto(Vector2(200, 226), "I = %s mA · P = %s W" % [coma(corriente() * 1000.0, 1), coma(potencia(), 2)], 13, Tema.TINTA)
	var rotulo := "SIN TENSIÓN" if not hay else ("SE QUEMA" if se_quema() else ("MUY CALIENTE" if potencia() > POTENCIA_W else "BIEN"))
	var color := Color("5b6267") if not hay else (Tema.FALLO if potencia() > POTENCIA_W else Tema.ACIERTO)
	rotulo_estado(Vector2(200, 248), rotulo, color)
	l.draw_set_transform(Vector2.ZERO)


func _punto(camino: PackedVector2Array, d: float) -> Vector2:
	for k in camino.size() - 1:
		var tramo := camino[k].distance_to(camino[k + 1])
		if d <= tramo:
			return camino[k].lerp(camino[k + 1], d / tramo)
		d -= tramo
	return camino[camino.size() - 1]
