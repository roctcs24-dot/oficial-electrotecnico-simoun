extends Animacion
## Puente rectificador de 24 V~ con su condensador de filtro, con las cuentas de
## SimPuenteRectificador. La onda va a cámara lenta (un ciclo cada 2 s) para ver qué pareja de
## diodos conduce en cada semiciclo. Con un diodo abierto queda media onda.

const ANCHO := 400.0
const ALTO := 260.0
const V_AC := 24.0
const VF := 0.7
const PERIODO_S := 2.0

var filtro := true
var diodo_abierto := false
var fase_onda := 0.0
var _filtro: Button
var _diodo: Button
var _media: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_filtro = boton_mando(fila, func() -> void: poner_filtro(not filtro))
	_diodo = boton_mando(fila, func() -> void: abrir_diodo(not diodo_abierto))
	_media = fila_valor(c, "Continua media")
	_nota = nota_mandos(c)
	_actualizar()


func poner_filtro(si: bool) -> void:
	filtro = si
	_actualizar()


func abrir_diodo(si: bool) -> void:
	diodo_abierto = si
	_actualizar()


func avanzar(dt: float) -> void:
	fase_onda = fmod(fase_onda + dt / PERIODO_S, 1.0)


func semiciclo_positivo() -> bool:
	return fase_onda < 0.5


## Continua media con las mismas cuentas que la simulación.
func tension_media() -> float:
	if diodo_abierto:
		var f := SimPuenteRectificador.PICO_MEDIA_ONDA if filtro else SimPuenteRectificador.MEDIA_ONDA
		return maxf(V_AC * f - VF, 0.0)
	var factor := SimPuenteRectificador.PICO if filtro else SimPuenteRectificador.MEDIA_SIN_FILTRO
	return maxf(V_AC * factor - 2.0 * VF, 0.0)


## Tensión instantánea de salida sin filtro.
func _rectificada(fase: float) -> float:
	var v := V_AC * SimPuenteRectificador.PICO * sin(fase * TAU)
	# Sin D1, el semiciclo positivo no tiene camino.
	if diodo_abierto and v > 0.0:
		return 0.0
	return maxf(absf(v) - (VF if diodo_abierto else 2.0 * VF), 0.0)


## 1 semiciclo positivo (D1 y D2); 2 negativo (D3 y D4); 3 con el filtro, que llena los huecos.
func fase() -> int:
	if filtro:
		return 3
	return 1 if semiciclo_positivo() else 2


func _process(delta: float) -> void:
	avanzar(delta)
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_filtro.text = "Quitar el filtro" if filtro else "Poner el filtro"
	_diodo.text = "Cambiar el puente" if diodo_abierto else "Abrir un diodo"
	_media.text = "%s V" % coma(tension_media(), 1)
	if diodo_abierto:
		_nota.text = "Con un diodo abierto solo se aprovecha un semiciclo: media onda, más rizado y menos tensión."
	elif filtro:
		_nota.text = "El condensador se carga en cada pico y entrega entre picos: unos 32 V con poco rizado."
	else:
		_nota.text = "Sin filtro, la salida es continua pulsante: 0,9 × 24 − 1,4 ≈ 20 V de media."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "PUENTE RECTIFICADOR DE 24 V~", 12, Color("5b6267"))
	# Rombo con los cuatro diodos; se ilumina la pareja que conduce.
	var arriba := Vector2(110, 50)
	var abajo := Vector2(110, 170)
	var izq := Vector2(50, 110)
	var der := Vector2(170, 110)
	var positivo := semiciclo_positivo()
	# D1 de ~ (arriba) a +, D2 de − a ~ (abajo), D3 de − a ~ (arriba) y D4 de ~ (abajo) a +.
	var d1 := positivo and not diodo_abierto
	var d2 := positivo and not diodo_abierto
	var d3 := not positivo
	var d4 := not positivo
	_diodo_en(arriba, der, d1)
	_diodo_en(izq, abajo, d2)
	_diodo_en(izq, arriba, d3)
	_diodo_en(abajo, der, d4)
	texto(Vector2(156, 70), "D1 abierto" if diodo_abierto else "D1", 9, Tema.FALLO if diodo_abierto else Tema.TINTA)
	texto(Vector2(62, 152), "D2", 9, Tema.TINTA)
	texto(Vector2(62, 70), "D3", 9, Tema.TINTA)
	texto(Vector2(158, 152), "D4", 9, Tema.TINTA)
	texto(arriba + Vector2(0, -14), "~", 16, Tema.TINTA)
	texto(abajo + Vector2(0, 16), "~", 16, Tema.TINTA)
	texto(der + Vector2(14, 0), "+", 16, Tema.TINTA)
	texto(izq + Vector2(-14, 0), "−", 18, Tema.TINTA)
	# Ondas: entrada y salida.
	var marco := Rect2(210, 34, 170, 80)
	var salida := Rect2(210, 130, 170, 80)
	for m: Rect2 in [marco, salida]:
		l.draw_rect(m, Color.WHITE)
		l.draw_rect(m, Color("8a949b"), false, 1.5)
	var pico := V_AC * SimPuenteRectificador.PICO
	var entrada := PackedVector2Array()
	var rect := PackedVector2Array()
	var media := tension_media()
	for k in 101:
		var f := k / 100.0
		var x := marco.position.x + f * marco.size.x
		entrada.append(Vector2(x, marco.position.y + marco.size.y / 2.0 - sin(f * TAU) * pico / pico * marco.size.y * 0.42))
		var v := _rectificada(f)
		if filtro:
			# Tras cada pico, el condensador se descarga poco a poco hasta el siguiente.
			var desde_pico := fmod(f + 0.25, 1.0) if diodo_abierto else fmod(f + 0.25, 0.5)
			v = maxf(v, _rectificada(0.75 if diodo_abierto else 0.25) - 4.0 * desde_pico)
		rect.append(Vector2(x, salida.end.y - 6.0 - v / pico * (salida.size.y - 12.0)))
	l.draw_polyline(entrada, Color("2c6e9e"), 2.0, true)
	l.draw_polyline(rect, Color("c0392b"), 2.5, true)
	var xa := marco.position.x + fase_onda * marco.size.x
	l.draw_line(Vector2(xa, marco.position.y), Vector2(xa, salida.end.y), Color(0.2, 0.2, 0.2, 0.35), 1.5)
	var y_media := salida.end.y - 6.0 - media / pico * (salida.size.y - 12.0)
	l.draw_dashed_line(Vector2(salida.position.x, y_media), Vector2(salida.end.x, y_media), Tema.ACIERTO, 1.0, 4.0)
	texto(Vector2(295, 26), "entrada 24 V~", 10, Color("5b6267"))
	texto(Vector2(295, 122), "salida en + −", 10, Color("5b6267"))
	texto(Vector2(110, 200), "%s V media" % coma(media, 1), 13, Tema.TINTA)
	var rotulo := "MEDIA ONDA" if diodo_abierto else ("CON FILTRO" if filtro else ("D1 Y D2" if positivo else "D3 Y D4"))
	rotulo_estado(Vector2(110, 236), rotulo, Tema.FALLO if diodo_abierto else Tema.ACIERTO)
	l.draw_set_transform(Vector2.ZERO)


## Diodo de desde a hasta (el triángulo apunta a hasta), iluminado si conduce.
func _diodo_en(desde: Vector2, hasta: Vector2, conduce: bool) -> void:
	var l := lienzo
	var color := Tema.ACENTO_FUERTE if conduce else Tema.TINTA
	l.draw_line(desde, hasta, color, 3.0 if conduce else 2.0)
	var c := desde.lerp(hasta, 0.5)
	var u := (hasta - desde).normalized()
	var n := u.orthogonal()
	l.draw_colored_polygon(PackedVector2Array([c - u * 9.0 + n * 9.0, c - u * 9.0 - n * 9.0, c + u * 9.0]), color)
	l.draw_line(c + u * 9.0 + n * 10.0, c + u * 9.0 - n * 10.0, color, 3.0)
