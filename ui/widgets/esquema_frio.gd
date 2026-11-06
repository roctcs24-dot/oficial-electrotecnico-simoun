class_name EsquemaFrio
extends Control
## Esquema del ciclo de la planta de frío: compresor, separador de aceite, condensador, recibidor,
## válvula de expansión y evaporador en la cuba de salmuera. El color de cada tubería dice qué
## lleva, y unos puntos recorren el circuito mientras el compresor gira. Tocar un punto de medida
## coloca allí el termómetro.

signal punto_tocado(id: String)

const PROPORCION := 1.5
const FONDO := Color("14181b")
const TEXTO := Color("d8dcd8")
const DESCARGA := Color("d9534f")
const LIQUIDO := Color("e0a030")
const BAJA := Color("5aa0e0")
const AGUA := Color("3fb5a3")
const SALMUERA := Color("1e3a4c")
const EQUIPO := Color("8e9496")
const OSCURO := Color("2a2e31")
const RADIO_TOQUE := 28.0
const SEPARACION_PUNTOS := 0.06
const VELOCIDAD := 0.08

## Tramos del circuito en coordenadas del esquema (0 a 1 en ancho y alto), con su color.
const TRAMOS := [
	["descarga", [Vector2(0.18, 0.23), Vector2(0.18, 0.12), Vector2(0.36, 0.12)]],
	["descarga", [Vector2(0.42, 0.12), Vector2(0.62, 0.12)]],
	["liquido", [Vector2(0.80, 0.24), Vector2(0.80, 0.36)]],
	["liquido", [Vector2(0.70, 0.41), Vector2(0.60, 0.41), Vector2(0.60, 0.58)]],
	["baja", [Vector2(0.60, 0.66), Vector2(0.60, 0.76), Vector2(0.40, 0.76), Vector2(0.40, 0.81), Vector2(0.60, 0.81), Vector2(0.60, 0.86), Vector2(0.40, 0.86), Vector2(0.40, 0.91)]],
	["baja", [Vector2(0.40, 0.91), Vector2(0.26, 0.91), Vector2(0.26, 0.60), Vector2(0.18, 0.60), Vector2(0.18, 0.37)]],
]
const PUNTOS := {
	"descarga": Vector2(0.28, 0.12),
	"liquido": Vector2(0.60, 0.50),
	"succion": Vector2(0.18, 0.50),
	"salmuera": Vector2(0.74, 0.88),
	"agua_mar_entrada": Vector2(0.95, 0.20),
	"agua_mar_salida": Vector2(0.95, 0.12),
}

var en_marcha := false
var bomba_agua_mar := true
var bomba_salmuera := true
var presion_succion := 0.0
var presion_descarga := 0.0
var punto_marcado := ""
var _fase := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(300.0, 200.0)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(delta: float) -> void:
	if en_marcha:
		_fase = fmod(_fase + delta * VELOCIDAD, SEPARACION_PUNTOS)
		queue_redraw()


## Rectángulo del esquema dentro del control, con su proporción fija.
func _marco() -> Rect2:
	var ancho := minf(size.x, size.y * PROPORCION)
	var alto := ancho / PROPORCION
	return Rect2(Vector2((size.x - ancho) / 2.0, (size.y - alto) / 2.0), Vector2(ancho, alto))


func _p(v: Vector2) -> Vector2:
	var m := _marco()
	return m.position + v * m.size


## El alto sigue al ancho, para que el esquema conserve su proporción.
func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED and size.x > 0.0:
		var alto := maxf(size.x / PROPORCION, 200.0)
		if not is_equal_approx(custom_minimum_size.y, alto):
			custom_minimum_size.y = alto


func _gui_input(evento: InputEvent) -> void:
	var pulsado: bool = (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT) or (evento is InputEventScreenTouch and evento.pressed)
	if not pulsado:
		return
	var mejor := ""
	var distancia := RADIO_TOQUE
	for id: String in PUNTOS:
		var d := _p(PUNTOS[id]).distance_to(evento.position)
		if d <= distancia:
			mejor = id
			distancia = d
	if not mejor.is_empty():
		punto_tocado.emit(mejor)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	var fuente := get_theme_default_font()
	var escala := _marco().size.x / 600.0
	var grosor := maxf(4.0 * escala, 2.0)
	var t := int(maxf(12.0 * escala, 11.0))
	_dibujar_cuba(fuente, t)
	_dibujar_agua_mar(grosor)
	for tramo: Array in TRAMOS:
		_dibujar_tubo(tramo[1], _color(tramo[0]), grosor)
	_dibujar_equipos(fuente, t, escala)
	if en_marcha:
		for tramo: Array in TRAMOS:
			_dibujar_flujo(tramo[1], _color(tramo[0]), grosor)
	for id: String in PUNTOS:
		var c := _p(PUNTOS[id])
		var marcado := id == punto_marcado
		draw_arc(c, 9.0 * maxf(escala, 1.0), 0.0, TAU, 20, Color.WHITE if marcado else TEXTO, 3.0 if marcado else 1.5, true)
		draw_circle(c, 3.0, Color.WHITE if marcado else TEXTO)
	_texto(fuente, "Descarga %s bar" % TextoTecnico.numero(presion_descarga, 1), _p(Vector2(0.40, 0.05)), t, DESCARGA)
	_texto(fuente, "Succión %s bar" % TextoTecnico.numero(presion_succion, 2), _p(Vector2(0.10, 0.70)), t, BAJA)


func _color(tipo: String) -> Color:
	match tipo:
		"descarga":
			return DESCARGA
		"liquido":
			return LIQUIDO
	return BAJA


func _dibujar_tubo(puntos: Array, color: Color, grosor: float) -> void:
	var linea := PackedVector2Array()
	for v: Vector2 in puntos:
		linea.append(_p(v))
	draw_polyline(linea, color.darkened(0.45), grosor + 2.0, true)
	draw_polyline(linea, color, grosor, true)


## Puntos claros que avanzan por el tramo, separados por igual a lo largo de su longitud.
func _dibujar_flujo(puntos: Array, color: Color, grosor: float) -> void:
	var longitud := 0.0
	for i in puntos.size() - 1:
		longitud += (puntos[i + 1] - puntos[i]).length()
	var d := _fase
	while d < longitud:
		draw_circle(_p(_punto_en(puntos, d)), grosor * 0.55, color.lightened(0.6))
		d += SEPARACION_PUNTOS


func _punto_en(puntos: Array, distancia: float) -> Vector2:
	var resto := distancia
	for i in puntos.size() - 1:
		var tramo: Vector2 = puntos[i + 1] - puntos[i]
		if resto <= tramo.length():
			return puntos[i] + tramo.normalized() * resto
		resto -= tramo.length()
	return puntos[-1]


func _dibujar_cuba(fuente: Font, t: int) -> void:
	var a := _p(Vector2(0.32, 0.70))
	var b := _p(Vector2(0.90, 0.97))
	draw_rect(Rect2(a, b - a), SALMUERA)
	draw_rect(Rect2(a, b - a), EQUIPO, false, 2.0)
	_texto(fuente, "Cuba de salmuera y evaporador", _p(Vector2(0.61, 0.955)), t, TEXTO)
	var bomba := _p(Vector2(0.82, 0.80))
	var r := (b.y - a.y) * 0.14
	draw_circle(bomba, r, OSCURO)
	draw_arc(bomba, r, 0.0, TAU, 20, AGUA if bomba_salmuera else EQUIPO, 2.0, true)
	_texto(fuente, "Bomba", bomba + Vector2(0.0, r + t), t - 1, TEXTO)


func _dibujar_agua_mar(grosor: float) -> void:
	var color := AGUA if bomba_agua_mar else EQUIPO
	for par in [[Vector2(0.99, 0.20), Vector2(0.88, 0.20)], [Vector2(0.88, 0.12), Vector2(0.99, 0.12)]]:
		draw_line(_p(par[0]), _p(par[1]), color, grosor, true)


func _dibujar_equipos(fuente: Font, t: int, escala: float) -> void:
	# Compresor.
	var c := _p(Vector2(0.18, 0.30))
	var r := 0.07 * _marco().size.x * 0.66
	draw_circle(c, r, OSCURO)
	draw_arc(c, r, 0.0, TAU, 32, DESCARGA if en_marcha else EQUIPO, 3.0, true)
	draw_line(c + Vector2(-r * 0.5, r * 0.5), c + Vector2(r * 0.5, -r * 0.5), TEXTO, 2.0, true)
	_texto(fuente, "Compresor", c + Vector2(r + 6.0 * escala, 4.0), t, TEXTO, HORIZONTAL_ALIGNMENT_LEFT)
	# Separador de aceite.
	var s := Rect2(_p(Vector2(0.36, 0.06)), _p(Vector2(0.42, 0.20)) - _p(Vector2(0.36, 0.06)))
	draw_rect(s, OSCURO)
	draw_rect(s, EQUIPO, false, 2.0)
	_texto(fuente, "Separador", Vector2(s.get_center().x, s.end.y + t), t - 1, TEXTO)
	# Condensador con su haz de tubos.
	var k := Rect2(_p(Vector2(0.62, 0.06)), _p(Vector2(0.88, 0.24)) - _p(Vector2(0.62, 0.06)))
	draw_rect(k, OSCURO)
	draw_rect(k, EQUIPO, false, 2.0)
	for i in 4:
		var y := k.position.y + k.size.y * (0.2 + 0.2 * i)
		draw_line(Vector2(k.position.x + 6.0, y), Vector2(k.end.x - 6.0, y), AGUA.darkened(0.3), 1.5, true)
	_texto(fuente, "Condensador", Vector2(k.get_center().x, k.position.y - 4.0), t, TEXTO)
	# Recibidor de líquido.
	var rec := Rect2(_p(Vector2(0.70, 0.36)), _p(Vector2(0.90, 0.46)) - _p(Vector2(0.70, 0.36)))
	draw_rect(rec, OSCURO)
	draw_rect(rec, EQUIPO, false, 2.0)
	draw_rect(Rect2(rec.position + Vector2(0.0, rec.size.y * 0.5), Vector2(rec.size.x, rec.size.y * 0.5)), LIQUIDO.darkened(0.5))
	_texto(fuente, "Recibidor", Vector2(rec.get_center().x, rec.end.y + t), t - 1, TEXTO)
	# Válvula de expansión.
	var v := _p(Vector2(0.60, 0.62))
	var lado := 10.0 * maxf(escala, 1.0)
	draw_colored_polygon(PackedVector2Array([v + Vector2(-lado, -lado), v + Vector2(lado, -lado), v, ]), EQUIPO)
	draw_colored_polygon(PackedVector2Array([v + Vector2(-lado, lado), v + Vector2(lado, lado), v]), EQUIPO)
	_texto(fuente, "Válvula de expansión", v + Vector2(lado + 4.0, 4.0), t - 1, TEXTO, HORIZONTAL_ALIGNMENT_LEFT)


func _texto(fuente: Font, texto: String, posicion: Vector2, t: int, color: Color, alineacion := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
	var x := posicion.x
	if alineacion == HORIZONTAL_ALIGNMENT_CENTER:
		x -= ancho / 2.0
	elif alineacion == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= ancho
	draw_string(fuente, Vector2(x, posicion.y), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, color)
