class_name VistaBornes
extends VistaEquipo
## Dibujo de un equipo o de un esquema con sus bornes tocables: un toque elige el borne más
## cercano, los bornes elegidos se resaltan con un halo y las marcas numeradas señalan las partes.
## Las posiciones van en coordenadas del dibujo, como las etiquetas.

signal borne_tocado(id: String)

## Un toque que se mueve más que esto es un arrastre de la lista, no un toque.
const TOLERANCIA_TOQUE := 14.0
const RADIO_TOQUE_PX := 30.0
const AMARILLO := Color("f2b705")

## id -> Vector2 en coordenadas del dibujo.
var bornes := {}
## id -> color del halo.
var resaltados := {}
## [[número, x, y], ...]
var marcas: Array = []
var _inicio_toque := Vector2.INF


func poner_bornes(lista: Dictionary) -> void:
	bornes = {}
	for id: String in lista:
		var p: Array = lista[id]
		bornes[id] = Vector2(p[0], p[1])
	queue_redraw()


func resaltar(ids: Array, color := AMARILLO) -> void:
	resaltados = {}
	for id: String in ids:
		if bornes.has(id):
			resaltados[id] = color
	queue_redraw()


## Borne más cercano a un punto local dentro del radio de toque, o "".
func borne_en(punto: Vector2) -> String:
	var mejor := ""
	var distancia := RADIO_TOQUE_PX
	for id: String in bornes:
		var d := a_local(bornes[id].x, bornes[id].y).distance_to(punto)
		if d < distancia:
			distancia = d
			mejor = id
	return mejor


func _gui_input(evento: InputEvent) -> void:
	if not evento is InputEventMouseButton or evento.button_index != MOUSE_BUTTON_LEFT:
		return
	if evento.pressed:
		_inicio_toque = evento.position
		return
	if _inicio_toque != Vector2.INF and evento.position.distance_to(_inicio_toque) < TOLERANCIA_TOQUE:
		var id := borne_en(evento.position)
		if not id.is_empty():
			borne_tocado.emit(id)
	_inicio_toque = Vector2.INF


func _draw() -> void:
	super()
	var factor := rect_imagen().size.x / tamano_svg.x
	var radio := maxf(14.0 * factor, 9.0)
	for id: String in resaltados:
		var c := a_local(bornes[id].x, bornes[id].y)
		var color: Color = resaltados[id]
		draw_circle(c, radio * 1.6, Color(color, 0.28))
		draw_arc(c, radio * 1.15, 0.0, TAU, 32, color, maxf(3.0 * factor, 2.0), true)
	var fuente := get_theme_default_font()
	for m: Array in marcas:
		var c := a_local(float(m[1]), float(m[2]))
		var r := maxf(13.0 * factor, 10.0)
		draw_circle(c, r, AMARILLO)
		draw_arc(c, r, 0.0, TAU, 32, Tema.TINTA, 1.5, true)
		var cifra := str(m[0])
		var tam := int(r * 1.2)
		var ancho := fuente.get_string_size(cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(fuente, c + Vector2(-ancho / 2.0, tam * 0.36), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Tema.TINTA)
