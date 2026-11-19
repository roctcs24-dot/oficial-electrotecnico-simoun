extends Animacion
## Prensa hidráulica (principio de Pascal): la fuerza sobre el émbolo pequeño crea una presión que
## llega igual a todo el aceite; sobre el émbolo grande, la misma presión da una fuerza tantas
## veces mayor como su área. A cambio, el émbolo grande sube mucho menos.
## Parámetros: "pequeno" y "grande" (diámetros en mm), "fuerza" inicial (N).

const ANCHO := 440.0
const ALTO := 210.0

var d_pequeno := 20.0
var d_grande := 100.0
var fuerza := 200.0
## Recorrido del émbolo pequeño (0 a 1), que se anima solo.
var _bajada := 0.0
var _presion: Label
var _salida: Label
var _recorrido: Label


## Presión en bar que da una fuerza en N sobre un émbolo de diámetro en mm.
static func presion_bar(fuerza_n: float, diametro_mm: float) -> float:
	return fuerza_n / (PI * diametro_mm * diametro_mm / 4.0) * 10.0


## Fuerza en N que da una presión en bar sobre un émbolo de diámetro en mm.
static func fuerza_n(presion: float, diametro_mm: float) -> float:
	return presion / 10.0 * PI * diametro_mm * diametro_mm / 4.0


func preparar() -> void:
	d_pequeno = float(params.get("pequeno", d_pequeno))
	d_grande = float(params.get("grande", d_grande))
	fuerza = float(params.get("fuerza", fuerza))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var f := fila_valor(c, "Fuerza en el pequeño")
	barra(c, 0.0, 400.0, 10.0, fuerza, func(v: float) -> void:
		fuerza = v
		f.text = "%d N" % roundi(v)
		_actualizar())
	f.text = "%d N" % roundi(fuerza)
	_presion = fila_valor(c, "Presión del aceite")
	_salida = fila_valor(c, "Fuerza en el grande")
	_recorrido = fila_valor(c, "Sube el grande por 100 mm")
	_actualizar()


func _actualizar() -> void:
	if _presion == null:
		return
	var p := presion_bar(fuerza, d_pequeno)
	_presion.text = "%s bar" % coma(p, 1)
	var f2 := fuerza_n(p, d_grande)
	_salida.text = "%s kN · %d kg" % [coma(f2 / 1000.0, 1), roundi(f2 / 9.81)]
	_recorrido.text = "%s mm" % coma(100.0 * pow(d_pequeno / d_grande, 2.0), 1)


func fase() -> int:
	return 1 if fuerza <= 0.0 else (3 if _bajada > 0.6 else 2)


func _process(delta: float) -> void:
	var objetivo := clampf(fuerza / 400.0, 0.0, 1.0)
	_bajada = move_toward(_bajada, objetivo, delta * 0.6)
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoHidraulico.FONDO)
	var area := pow(d_grande / d_pequeno, 2.0)
	# Cilindros: el pequeño a la izquierda, el grande a la derecha, unidos por abajo.
	var peq := Rect2(70, 52, 34, 120)
	var gra := Rect2(250, 70, 150, 102)
	var fondo_y := 182.0
	DibujoHidraulico.pieza(l, Rect2(60, fondo_y - 10, 350, 22), 6.0)
	for r: Rect2 in [peq, gra]:
		DibujoHidraulico.pieza(l, r.grow(6.0), 5.0)
		DibujoAri.relleno(l, r, 3.0, Color("1a1f24"))
	# Aceite: el pequeño baja, el grande sube área veces menos.
	var baja := _bajada * 70.0
	var sube := baja / area * 8.0  # exagerado ×8 para que se vea
	var nivel_p := peq.position.y + 30.0 + baja
	var nivel_g := gra.position.y + 40.0 - sube
	l.draw_rect(Rect2(peq.position.x, nivel_p, peq.size.x, peq.end.y - nivel_p), DibujoHidraulico.ACEITE)
	l.draw_rect(Rect2(gra.position.x, nivel_g, gra.size.x, gra.end.y - nivel_g), DibujoHidraulico.ACEITE)
	l.draw_rect(Rect2(peq.position.x, fondo_y - 8.0, gra.end.x - peq.position.x, 12.0), DibujoHidraulico.ACEITE)
	# Émbolos.
	DibujoHidraulico.pieza(l, Rect2(peq.position.x - 2, nivel_p - 14.0, peq.size.x + 4, 14.0), 2.0)
	DibujoHidraulico.pieza(l, Rect2(gra.position.x - 2, nivel_g - 18.0, gra.size.x + 4, 18.0), 3.0)
	# Fuerza que empuja abajo y carga que sube.
	var largo := 14.0 + 40.0 * clampf(fuerza / 400.0, 0.0, 1.0)
	flecha(Vector2(peq.get_center().x, nivel_p - 18.0 - largo), Vector2(peq.get_center().x, nivel_p - 18.0), Color("ff7a5a"), 4.0)
	var carga := Rect2(gra.get_center().x - 40, nivel_g - 18.0 - 36.0, 80, 36)
	DibujoAri.pieza(l, carga, 4.0, [Color("8a949b"), Color("4a5257"), Color("2a2f33")], [], DibujoHidraulico.CONTORNO)
	var p := presion_bar(fuerza, d_pequeno)
	var f2 := fuerza_n(p, d_grande)
	texto(carga.get_center(), "%s kN" % coma(f2 / 1000.0, 1), 13, Color.WHITE)
	texto(Vector2(peq.get_center().x, 22.0), "%d N" % roundi(fuerza), 13, Color("ffb09a"))
	texto(Vector2(peq.get_center().x, 196.0), "Ø %d mm" % roundi(d_pequeno), 11, Color("cfd8df"))
	texto(Vector2(gra.get_center().x, 196.0), "Ø %d mm · área ×%d" % [roundi(d_grande), roundi(area)], 11, Color("cfd8df"))
	l.draw_line(Vector2(170, 138), Vector2(170, fondo_y - 8.0), DibujoHidraulico.CONTORNO, 7.0)
	l.draw_line(Vector2(170, 138), Vector2(170, fondo_y - 8.0), DibujoHidraulico.ACEITE, 4.0)
	DibujoHidraulico.manometro(l, fuente, Vector2(170, 112), 26.0, p, 40.0)
	texto(Vector2(170, 152), "%s bar" % coma(p, 1), 12, Color("ffd08a"))
