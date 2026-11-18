class_name FilaPlaca
extends ControlToque
## Fila que se toca dentro de una placa con relieve: a la izquierda un código en un visor ámbar
## (un panel, como «P-31»), una medalla del área (un sistema) o una moneda del camino (la
## siguiente lección); en medio el título y una nota; a la derecha una lámpara y un galón. La
## elegida se ilumina en ámbar. Una fila inactiva sale apagada y no responde.

signal tocada

const ALTO := 52.0

var titulo := ""
var nota := ""
## «codigo», «medalla» o «moneda».
var tipo := "codigo"
var codigo := ""
var color := Tema.ACENTO
var icono := ""
var avance := 0.0
var numero := 0
## Lámpara de la derecha: «verde», «ambar», «rojo», «apagada» o vacío para ninguna.
var lampara := ""
var elegida := false:
	set(valor):
		elegida = valor
		queue_redraw()
var activa := true
var _encima := false


func _init(p_titulo := "", p_nota := "") -> void:
	super()
	titulo = p_titulo
	nota = p_nota
	custom_minimum_size = Vector2(160, ALTO)
	resized.connect(_ajustar_alto)


func _ajustar_alto() -> void:
	var alto := maxf(ALTO, _alto_textos() + 14.0)
	if absf(custom_minimum_size.y - alto) > 0.5:
		custom_minimum_size.y = alto
	queue_redraw()


func _x_texto() -> float:
	return 76.0 if tipo == "codigo" else 58.0


func _ancho_texto() -> float:
	return maxf(size.x - _x_texto() - (52.0 if not lampara.is_empty() else 30.0), 40.0)


func _lineas(t: String, tam: float, peso: int) -> PackedStringArray:
	var palabras := t.split(" ")
	var lineas := PackedStringArray()
	var actual := ""
	for p in palabras:
		var prueba := p if actual.is_empty() else actual + " " + p
		if PiezasAri.ancho_texto(prueba, tam, peso) > _ancho_texto() and not actual.is_empty():
			lineas.append(actual)
			actual = p
		else:
			actual = prueba
	if not actual.is_empty():
		lineas.append(actual)
	return lineas


func _alto_textos() -> float:
	var t1 := float(Tema.tam(14))
	var t2 := float(Tema.tam(11.5))
	var alto := _lineas(titulo, t1, Tema.PESO_NEGRITA).size() * (t1 + 3.0)
	if not nota.is_empty():
		alto += _lineas(nota, t2, Tema.PESO_MEDIO).size() * (t2 + 3.0)
	return alto


func _al_presionar(_punto: Vector2) -> void:
	_encima = true
	queue_redraw()


func _al_soltar() -> void:
	_encima = false
	queue_redraw()


func cancelar_toque() -> void:
	super()
	_encima = false
	queue_redraw()


func _al_tocar(_punto: Vector2) -> void:
	if activa:
		tocada.emit()


## Para las pruebas: un toque completo.
func pulsar() -> void:
	_al_tocar(Vector2.ZERO)


func _draw() -> void:
	var caja := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	if elegida:
		for i in 3:
			DibujoAri.borde(self, caja.grow(1.0 + i * 1.5), 10.0 + i * 1.5, Color(Relieve.AMBAR_HALO, 0.14 - i * 0.04), 1.5)
		DibujoAri.degradado(self, caja, 10.0, [Color(1.0, 0.76, 0.23, 0.18), Color(1.0, 0.76, 0.23, 0.03)])
		DibujoAri.borde(self, caja, 10.0, Color(Relieve.AMBAR, 0.6), 1.2)
	elif _encima and activa:
		DibujoAri.relleno(self, caja, 10.0, Color(1, 1, 1, 0.06))
	var cy := size.y / 2.0
	var apagado := 1.0 if activa else 0.45
	match tipo:
		"codigo":
			var r := Rect2(8.0, cy - 14.0, 60.0, 28.0)
			DibujoAri.sombra(self, r, 5.0, 0.5, Vector2(0, 2))
			DibujoAri.degradado(self, r, 5.0, [Color("05080a"), Color("1b2833")])
			var dentro := r.grow(-2.0)
			DibujoAri.degradado(self, dentro, 3.0, [Color("030806"), Color("0b1510")])
			var tam := float(Tema.tam(14))
			var tinta := Color(Tema.ARI_LCD_AMBAR, apagado)
			Relieve.halo(self, dentro.get_center(), 18.0, Tema.ARI_LCD_AMBAR, 0.5 * apagado)
			PiezasAri.texto(self, codigo, dentro.get_center().x, cy + tam * 0.36, tam, tinta, Tema.PESO_NEGRITA)
			DibujoAri.degradado(self, Rect2(dentro.position, Vector2(dentro.size.x, dentro.size.y * 0.42)), 2.0, [Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.0)])
		"medalla":
			Relieve.medalla(self, Vector2(28, cy), 14.0, color, icono, avance, false, not activa)
		"moneda":
			Relieve.moneda(self, Vector2(28, cy), 15.0, "actual", numero, color)
	var x := _x_texto()
	var t1 := float(Tema.tam(14))
	var t2 := float(Tema.tam(11.5))
	var y := cy - _alto_textos() / 2.0
	for linea in _lineas(titulo, t1, Tema.PESO_NEGRITA):
		y += t1 + 1.0
		PiezasAri.texto(self, linea, x, y, t1, Color(1, 1, 1, apagado), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
		y += 2.0
	for linea in _lineas(nota, t2, Tema.PESO_MEDIO):
		y += t2 + 1.0
		PiezasAri.texto(self, linea, x, y, t2, Color(Tema.TEXTO_SUAVE, apagado), Tema.PESO_MEDIO, HORIZONTAL_ALIGNMENT_LEFT)
		y += 2.0
	var xd := size.x - 14.0
	if activa:
		DibujoAri.galon(self, Vector2(xd, cy), 9.0, 1, Color("8a97a2"), 2.2)
	if not lampara.is_empty():
		var c := Vector2(xd - 26.0, cy)
		if lampara == "apagada":
			Relieve.lampara_estado(self, c, 4.6, "sin_empezar")
		else:
			PiezasAri.lampara(self, c, 5.5, lampara, 1.0)
