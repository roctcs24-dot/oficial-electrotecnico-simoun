extends Animacion
## Lazo de 4-20 mA: un transmisor de presión de dos hilos de 0 a 10 bar, la fuente de 24 V y la
## entrada analógica del PLC con su resistencia de 250 Ω (1 a 5 V). Se mueve la presión y se
## puede cortar el cable: 0 mA no es «presión cero» sino una avería. El umbral de alarma de
## 3,6 mA es un valor típico (NAMUR NE 43) — verificar a bordo.

const ANCHO := 420.0
const ALTO := 220.0
const RANGO := 10.0
const R_ENTRADA := 250.0
const UMBRAL_ROTURA := 3.6

var presion := 6.0
var cortado := false
var _ma: Label
var _pct: Label
var _nota: Label
var _boton: Button


static func corriente(p: float, rango: float) -> float:
	return 4.0 + 16.0 * clampf(p / rango, 0.0, 1.0)


static func presion_de(ma: float, rango: float) -> float:
	return (ma - 4.0) / 16.0 * rango


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var p := fila_valor(c, "Presión en el transmisor")
	barra(c, 0.0, RANGO, 0.5, presion, func(v: float) -> void:
		presion = v
		p.text = "%s bar" % coma(v)
		_actualizar())
	p.text = "%s bar" % coma(presion)
	_boton = boton_mando(c, conmutar_cable)
	_ma = fila_valor(c, "Corriente del lazo")
	_pct = fila_valor(c, "Lo que lee el PLC")
	_nota = nota_mandos(c)
	_actualizar()


func conmutar_cable() -> void:
	cortado = not cortado
	_actualizar()


func ma() -> float:
	return 0.0 if cortado else corriente(presion, RANGO)


func _actualizar() -> void:
	if _nota == null:
		return
	_boton.text = "Reparar el cable" if cortado else "Cortar el cable"
	_ma.text = "%s mA · %s V en 250 Ω" % [coma(ma()), coma(ma() * R_ENTRADA / 1000.0, 2)]
	if ma() < UMBRAL_ROTURA:
		_pct.text = "ALARMA: lazo abierto"
		_nota.text = "Por debajo de unos 3,6 mA el PLC no da «0 bar»: da alarma de cable cortado o de transmisor sin alimentación."
	else:
		_pct.text = "%s bar · %d %%" % [coma(presion_de(ma(), RANGO)), roundi((ma() - 4.0) / 16.0 * 100.0)]
		_nota.text = "La corriente es la misma en todo el lazo: la resistencia del cable no cambia la lectura."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	var tinta := Tema.TINTA
	var rojo := Color("d02a1e")
	var azul := Color("2565c4")
	# Transmisor.
	l.draw_style_box(Tema.caja(Color("c9d1d7"), 10, 0, 0, Color("5b6267")), Rect2(20, 60, 80, 90))
	l.draw_circle(Vector2(60, 95), 24.0, Color("1b2228"))
	texto(Vector2(60, 92), ("%.1f" % presion).replace(".", ",") if not cortado else "- -", 15, Color("45ff82"))
	texto(Vector2(60, 108), "bar", 9, Color("45ff82"))
	l.draw_rect(Rect2(48, 150, 24, 22), Color("8a9399"))
	texto(Vector2(60, 48), "PT 0-10 bar", 11, tinta)
	# Fuente y PLC.
	l.draw_style_box(Tema.caja(Color("2b3640"), 6, 0, 0), Rect2(170, 14, 70, 42))
	texto(Vector2(205, 28), "+24 V", 12, Color.WHITE)
	texto(Vector2(205, 44), "fuente", 10, Color("a9b6c1"))
	l.draw_style_box(Tema.caja(Color("d8dee3"), 6, 0, 0, Color("3b444c")), Rect2(310, 30, 96, 140))
	l.draw_style_box(Tema.caja(Color("2b3238"), 3, 0, 0), Rect2(320, 40, 76, 22))
	texto(Vector2(358, 51), "AI 0", 11, Tema.ACENTO)
	l.draw_rect(Rect2(336, 74, 44, 70), Color("f4f1e6"))
	l.draw_rect(Rect2(336, 74, 44, 70), tinta, false, 1.5)
	var zig := PackedVector2Array([Vector2(358, 80), Vector2(358, 88)])
	for k in 6:
		zig.append(Vector2(352 if k % 2 == 0 else 364, 92 + k * 7))
	zig.append(Vector2(358, 134))
	zig.append(Vector2(358, 140))
	l.draw_polyline(zig, tinta, 2.0)
	texto(Vector2(358, 158), "250 Ω", 11, tinta)
	# Cable del lazo: + de la fuente al transmisor; del transmisor al PLC; del PLC a 0 V.
	var corte := Vector2(140, 80)
	var tramo1 := [Vector2(100, 80), Vector2(205, 80), Vector2(205, 56)]
	var tramo2 := [Vector2(240, 35), Vector2(260, 35), Vector2(260, 100), Vector2(310, 100)]
	var tramo3 := [Vector2(100, 130), Vector2(310, 130)]
	if cortado:
		l.draw_line(tramo1[0], corte - Vector2(6, 0), rojo, 4.0)
		l.draw_line(corte + Vector2(6, 0), tramo1[1], rojo, 4.0)
		texto(corte + Vector2(0, -14), "corte", 11, Tema.FALLO)
	else:
		l.draw_line(tramo1[0], tramo1[1], rojo, 4.0)
	l.draw_line(tramo1[1], tramo1[2], rojo, 4.0)
	l.draw_polyline(PackedVector2Array(tramo2), rojo, 4.0)
	l.draw_line(tramo3[0], tramo3[1], azul, 4.0)
	# Puntos de corriente: más rápidos con más corriente.
	if not cortado:
		var paso := fmod(t * (10.0 + ma() * 3.0), 28.0)
		var x: float = tramo3[0].x + paso
		while x < 310.0:
			l.draw_circle(Vector2(x, 130), 3.2, Tema.ACENTO_FUERTE)
			if x < 205.0:
				l.draw_circle(Vector2(x, 80), 3.2, Tema.ACENTO_FUERTE)
			elif x > 262.0:
				l.draw_circle(Vector2(x, 100), 3.2, Tema.ACENTO_FUERTE)
			x += 28.0
	# Barra de la escala 4-20 mA.
	var x0 := 20.0
	var w := 380.0
	l.draw_rect(Rect2(x0, 198, w, 12), Color("dfe3e4"))
	l.draw_rect(Rect2(x0, 198, w * clampf(ma() / 20.0, 0.0, 1.0), 12), Tema.FALLO if ma() < UMBRAL_ROTURA else Tema.ACIERTO)
	for v: float in [0.0, 4.0, 12.0, 20.0]:
		var xv := x0 + w * v / 20.0
		l.draw_line(Vector2(xv, 192), Vector2(xv, 212), tinta, 1.5)
		texto(Vector2(xv, 186), "%d mA" % roundi(v), 10, tinta)
	l.draw_set_transform(Vector2.ZERO)
