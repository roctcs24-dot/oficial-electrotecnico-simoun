class_name LecturaLcd
extends Control
## Lectura digital verde sobre negro, con dígitos de siete segmentos y el cristal del visor,
## como «310,4 kW» o «P 12,6 bar». El número va alineado a la derecha.

const MARGEN := 4.0
const RADIO := 2.5

var texto := "0":
	set(valor):
		if valor != texto:
			texto = valor
			_medir()
			queue_redraw()
var unidad := "":
	set(valor):
		unidad = valor
		_medir()
		queue_redraw()
var color := Tema.ARI_LCD_VERDE:
	set(valor):
		color = valor
		queue_redraw()
## Alto de los dígitos; el visor mide algo más.
var alto_cifra := 12.0:
	set(valor):
		alto_cifra = valor
		_medir()
## Cifras que caben siempre, para que el visor no cambie de ancho al variar el valor.
var cifras := 0:
	set(valor):
		cifras = valor
		_medir()


func _init(texto_inicial := "0", unidad_inicial := "", alto := 12.0, cifras_reservadas := 0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto = texto_inicial
	unidad = unidad_inicial
	alto_cifra = alto
	cifras = cifras_reservadas
	_medir()


## Un número con coma decimal, como en las placas y los visores a bordo.
static func numero(valor: float, decimales := 1) -> String:
	return (("%." + str(decimales) + "f") % valor).replace(".", ",")


func _fuente_unidad() -> Font:
	return Tema.fuente(Tema.PESO_NEGRITA)


func _tam_unidad() -> int:
	return maxi(roundi(alto_cifra * 0.7), 8)


func _ancho_unidad() -> float:
	if unidad.is_empty():
		return 0.0
	return _fuente_unidad().get_string_size(unidad, HORIZONTAL_ALIGNMENT_LEFT, -1, _tam_unidad()).x + 3.0


func _medir() -> void:
	var muestra := texto
	var visibles := texto.replace(",", "").replace(".", "").replace(":", "").length()
	if cifras > visibles:
		muestra = "8".repeat(cifras - visibles) + texto
	var ancho := DibujoAri.ancho_seg7(muestra, alto_cifra) + _ancho_unidad() + MARGEN * 2.0 + alto_cifra * DibujoAri.INCLINACION
	custom_minimum_size = Vector2(ceilf(ancho), ceilf(alto_cifra * 1.55))


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	DibujoAri.degradado(self, r, RADIO, [Color("05080a"), Color("3b5466")])
	var dentro := r.grow(-1.5)
	DibujoAri.degradado(self, dentro, RADIO - 1.0, [Tema.ARI_LCD_FONDO, Color("0b1510")])
	var ancho_u := _ancho_unidad()
	var ancho_t := DibujoAri.ancho_seg7(texto, alto_cifra)
	var x := size.x - MARGEN - ancho_u - ancho_t
	var y := (size.y - alto_cifra) / 2.0
	# Cifras apagadas a la izquierda, como las posiciones sin usar de un visor.
	var visibles := texto.replace(",", "").replace(".", "").replace(":", "").length()
	if cifras > visibles:
		var relleno := " ".repeat(cifras - visibles)
		var ancho_r := DibujoAri.ancho_seg7(relleno + "8", alto_cifra) - DibujoAri.ancho_seg7("8", alto_cifra)
		DibujoAri.seg7(self, relleno, Vector2(x - ancho_r, y), alto_cifra, color, DibujoAri.SEGMENTO_APAGADO, false)
	DibujoAri.seg7(self, texto, Vector2(x, y), alto_cifra, color)
	if not unidad.is_empty():
		var f := _fuente_unidad()
		var base := y + alto_cifra * 0.5 + f.get_ascent(_tam_unidad()) * 0.42
		draw_string(f, Vector2(size.x - MARGEN - ancho_u + 3.0, base), unidad, HORIZONTAL_ALIGNMENT_LEFT, -1, _tam_unidad(), Color(color, 0.85))
	DibujoAri.degradado(self, Rect2(dentro.position, Vector2(dentro.size.x, dentro.size.y * 0.42)), 1.0, [Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.0)])
