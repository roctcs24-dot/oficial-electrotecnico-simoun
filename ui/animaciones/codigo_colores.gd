extends Animacion
## Código de colores de una resistencia de cuatro bandas (IEC 60062): dos cifras, el
## multiplicador y la tolerancia. Se elige la banda y luego su color; el valor sale en ohmios
## con el margen que da la tolerancia.

const ANCHO := 420.0
const ALTO := 200.0
## Nombre, color y cifra de cada color; la cifra es también el exponente del multiplicador.
const COLORES := [
	["negro", Color("1a1a1a"), 0], ["marrón", Color("7a4a22"), 1], ["rojo", Color("d02a1e"), 2],
	["naranja", Color("ef7d16"), 3], ["amarillo", Color("f2cc1a"), 4], ["verde", Color("2e9c3c"), 5],
	["azul", Color("2565c4"), 6], ["violeta", Color("8a46c4"), 7], ["gris", Color("8a9096"), 8],
	["blanco", Color("f2f2f2"), 9], ["oro", Color("c9a227"), -1], ["plata", Color("b8bec4"), -2],
]
## Tolerancia en % de los colores que la llevan.
const TOLERANCIAS := {"marrón": 1.0, "rojo": 2.0, "verde": 0.5, "azul": 0.25, "violeta": 0.1, "oro": 5.0, "plata": 10.0}
const NOMBRES_BANDA := ["1.ª cifra", "2.ª cifra", "Multiplicador", "Tolerancia"]

## Índice en COLORES de cada banda: amarillo, violeta, rojo, oro = 4,7 kΩ ±5 %.
var bandas := [4, 7, 2, 10]
var banda := 0
var _botones_banda: Array[Button] = []
var _botones_color: Array[Button] = []
var _valor: Label
var _nota: Label


static func valor(b1: int, b2: int, exponente: int) -> float:
	return float(b1 * 10 + b2) * pow(10.0, exponente)


## «4,7 kΩ», «470 Ω» o «1 MΩ».
static func texto_ohmios(r: float) -> String:
	if r >= 1e6:
		return "%s MΩ" % coma(r / 1e6, 2)
	if r >= 1e3:
		return "%s kΩ" % coma(r / 1e3, 2)
	return "%s Ω" % coma(r, 2)


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var fila := GridContainer.new()
	fila.columns = 2
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	c.add_child(fila)
	for i in 4:
		var b := boton_mando(fila, elegir_banda.bind(i))
		b.text = NOMBRES_BANDA[i]
		_botones_banda.append(b)
	var rejilla := GridContainer.new()
	rejilla.columns = 4
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	c.add_child(rejilla)
	for k in COLORES.size():
		var b := boton_mando(rejilla, poner_color.bind(k))
		b.text = COLORES[k][0]
		b.add_theme_font_size_override("font_size", Tema.tam(12))
		var e := StyleBoxFlat.new()
		e.bg_color = COLORES[k][1]
		e.set_corner_radius_all(6)
		e.set_border_width_all(2)
		e.border_color = Color(0, 0, 0, 0.5)
		for estado in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(estado, e)
		var claro: bool = (COLORES[k][1] as Color).get_luminance() > 0.5
		for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(clave, Color.BLACK if claro else Color.WHITE)
		_botones_color.append(b)
	_valor = fila_valor(c, "Valor")
	_nota = nota_mandos(c)
	_actualizar()


func elegir_banda(i: int) -> void:
	banda = i
	_actualizar()


## Pone el color de la banda elegida, si ese color vale para ella.
func poner_color(k: int) -> void:
	if not color_valido(banda, k):
		return
	bandas[banda] = k
	if banda < 3:
		banda += 1
	_actualizar()


static func color_valido(b: int, k: int) -> bool:
	var cifra: int = COLORES[k][2]
	match b:
		0:
			return cifra >= 1
		1:
			return cifra >= 0
		2:
			return cifra >= -2 and cifra <= 6
		_:
			return TOLERANCIAS.has(COLORES[k][0])


func ohmios() -> float:
	return valor(COLORES[bandas[0]][2], COLORES[bandas[1]][2], COLORES[bandas[2]][2])


func tolerancia() -> float:
	return TOLERANCIAS.get(COLORES[bandas[3]][0], 20.0)


func _actualizar() -> void:
	if _nota == null:
		return
	for i in 4:
		_botones_banda[i].modulate = Color(1, 1, 1, 1.0 if i == banda else 0.55)
	for k in COLORES.size():
		_botones_color[k].disabled = not color_valido(banda, k)
		_botones_color[k].modulate = Color(1, 1, 1, 1.0 if _botones_color[k].disabled == false else 0.3)
	var r := ohmios()
	var tol := tolerancia()
	_valor.text = "%s ±%s %%" % [texto_ohmios(r), coma(tol, 2)]
	_nota.text = "Puede medir entre %s y %s. Elija una banda y después su color." % [texto_ohmios(r * (1.0 - tol / 100.0)), texto_ohmios(r * (1.0 + tol / 100.0))]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(210, 14), "RESISTENCIA DE CUATRO BANDAS", 12, Color("5b6267"))
	# Patas y cuerpo con sombra y brillo.
	l.draw_rect(Rect2(30, 87, 360, 6), Color("8a9399"))
	l.draw_rect(Rect2(30, 87, 360, 2), Color("dfe3e6"))
	var cuerpo := Rect2(110, 62, 200, 56)
	l.draw_style_box(Tema.caja(Color("d9bc84"), 26, 0, 0, Color("8a6a3c")), cuerpo.grow(1))
	l.draw_rect(Rect2(cuerpo.position.x + 14, cuerpo.position.y + 6, cuerpo.size.x - 28, 9), Color(1, 1, 1, 0.35))
	l.draw_rect(Rect2(cuerpo.position.x + 14, cuerpo.end.y - 12, cuerpo.size.x - 28, 9), Color(0, 0, 0, 0.12))
	var xs := [148.0, 176.0, 204.0, 270.0]
	for i in 4:
		var color: Color = COLORES[bandas[i]][1]
		var r := Rect2(xs[i] - 7.0, cuerpo.position.y, 14.0, cuerpo.size.y)
		l.draw_rect(r, color)
		l.draw_rect(Rect2(r.position, Vector2(r.size.x, 10)), Color(1, 1, 1, 0.25))
		if i == banda:
			var p := t * 4.0
			l.draw_rect(r.grow(3.0 + sin(p) * 1.5), Color(Tema.ACENTO_FUERTE, 0.9), false, 2.0)
			flecha(Vector2(xs[i], 150), Vector2(xs[i], 124), Color(Tema.ACENTO_FUERTE, 0.9), 2.5)
	for i in 4:
		texto(Vector2(xs[i], 162), ["1.ª", "2.ª", "mult.", "tol."][i], 11, Tema.TINTA)
	texto(Vector2(210, 186), "%s ±%s %%" % [texto_ohmios(ohmios()), coma(tolerancia(), 2)], 16, Tema.TINTA)
	l.draw_set_transform(Vector2.ZERO)
