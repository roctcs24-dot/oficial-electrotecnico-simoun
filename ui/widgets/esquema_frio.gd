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
## Recirculación por bombas, como en el buque: botella de baja y bomba de amoníaco en lugar de la
## válvula de expansión.
var recirculacion := false
var nivel_botella := 0.5
var bomba_amoniaco := true
var punto_marcado := ""
var _fase := 0.0
var _giro := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(300.0, 200.0)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(delta: float) -> void:
	if en_marcha:
		_fase = fmod(_fase + delta * VELOCIDAD, SEPARACION_PUNTOS)
		_giro = fmod(_giro + delta, 100.0)
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
	var bomba := _p(Vector2(0.815, 0.80))
	var r := (b.y - a.y) * 0.12
	DibujoEquipos.motor(self, Rect2(bomba + Vector2(r, -r * 0.75), Vector2(r * 2.6, r * 1.5)), DibujoEquipos.PINTURA_MOTOR, false)
	DibujoEquipos.bomba(self, bomba, r, Color("6d7478"), _giro, en_marcha and bomba_salmuera, AGUA if bomba_salmuera else EQUIPO)
	_texto(fuente, "Bomba", bomba + Vector2(0.0, r + t), t - 1, TEXTO)


func _dibujar_agua_mar(grosor: float) -> void:
	var color := AGUA if bomba_agua_mar else EQUIPO
	for par in [[Vector2(0.99, 0.20), Vector2(0.88, 0.20)], [Vector2(0.88, 0.12), Vector2(0.99, 0.12)]]:
		draw_line(_p(par[0]), _p(par[1]), color, grosor, true)


func _dibujar_equipos(fuente: Font, t: int, escala: float) -> void:
	var m := _marco()
	# Compresor de pistón con su motor: la descarga sale por arriba del bloque y la succión entra
	# por abajo.
	var grupo := Rect2(_p(Vector2(0.025, 0.205)), _p(Vector2(0.225, 0.37)) - _p(Vector2(0.025, 0.205)))
	var bloque := DibujoEquipos.compresor_piston(self, grupo, _giro, en_marcha)
	# Luz de marcha junto al nombre.
	var luz := Vector2(bloque.end.x + 10.0 * maxf(escala, 0.7), bloque.get_center().y)
	draw_circle(luz, 5.0 * maxf(escala, 0.7), Color("101315"))
	draw_circle(luz, 4.0 * maxf(escala, 0.7), Color("5fd36a") if en_marcha else Color("3a4a3e"))
	_texto(fuente, "Compresor", Vector2(luz.x + 9.0 * maxf(escala, 0.7), luz.y + 4.0), t, TEXTO, HORIZONTAL_ALIGNMENT_LEFT)
	# Separador de aceite: recipiente vertical sobre patas.
	var s := Rect2(_p(Vector2(0.36, 0.055)), _p(Vector2(0.42, 0.185)) - _p(Vector2(0.36, 0.055)))
	var suelo_s := _p(Vector2(0.0, 0.205)).y
	for x: float in [s.position.x + s.size.x * 0.2, s.end.x - s.size.x * 0.2]:
		draw_line(Vector2(x, s.end.y - 3.0), Vector2(x, suelo_s), Color("3a3f43"), 3.0)
	DibujoEquipos.recipiente(self, s, DibujoEquipos.ACERO, false)
	_texto(fuente, "Separador", Vector2(s.get_center().x, suelo_s + t), t - 1, TEXTO)
	# Condensador multitubular: carcasa con silletas y cajas de agua en los extremos.
	var k := Rect2(_p(Vector2(0.63, 0.065)), _p(Vector2(0.87, 0.195)) - _p(Vector2(0.63, 0.065)))
	draw_line(_p(Vector2(0.80, 0.19)), _p(Vector2(0.80, 0.24)), LIQUIDO.darkened(0.2), maxf(4.0 * escala, 2.0))
	var alto_silleta := _p(Vector2(0.0, 0.235)).y - k.end.y
	for x: float in [0.68, 0.84]:
		DibujoEquipos.silleta(self, Vector2(_p(Vector2(x, 0.0)).x, k.end.y - 2.0), m.size.x * 0.04, alto_silleta + 2.0)
	DibujoEquipos.cilindro(self, k, DibujoEquipos.ACERO)
	var caja := m.size.x * 0.025
	for x: float in [k.position.x - caja, k.end.x]:
		var cr := Rect2(Vector2(x, k.position.y - 2.0), Vector2(caja, k.size.y + 4.0))
		DibujoEquipos.cilindro(self, cr, Color("2f6f73"))
		var brida := cr.end.x if x < k.position.x else cr.position.x
		draw_line(Vector2(brida, cr.position.y - 1.0), Vector2(brida, cr.end.y + 1.0), Color("101315"), 3.0)
	_texto(fuente, "Condensador", Vector2(k.get_center().x, k.position.y - 6.0), t, TEXTO)
	# Recibidor de líquido: recipiente horizontal con mirilla de nivel.
	var rec := Rect2(_p(Vector2(0.70, 0.36)), _p(Vector2(0.90, 0.44)) - _p(Vector2(0.70, 0.36)))
	var suelo_r := _p(Vector2(0.0, 0.465)).y
	for x: float in [0.74, 0.86]:
		DibujoEquipos.silleta(self, Vector2(_p(Vector2(x, 0.0)).x, rec.end.y - 2.0), m.size.x * 0.03, suelo_r - rec.end.y + 2.0)
	DibujoEquipos.recipiente(self, rec, DibujoEquipos.ACERO)
	DibujoEquipos.mirilla(self, Rect2(rec.position + Vector2(rec.size.x * 0.6, rec.size.y * 0.2), Vector2(maxf(rec.size.x * 0.04, 4.0), rec.size.y * 0.6)), 0.5, LIQUIDO)
	_texto(fuente, "Recibidor", Vector2(rec.get_center().x, suelo_r + t), t - 1, TEXTO)
	if recirculacion:
		_dibujar_botella(fuente, t, escala)
		return
	# Válvula de expansión con su bonete y su volante.
	var v := _p(Vector2(0.60, 0.62))
	var lado := 10.0 * maxf(escala, 1.0)
	draw_colored_polygon(PackedVector2Array([v + Vector2(-lado, -lado), v + Vector2(lado, -lado), v]), EQUIPO)
	draw_colored_polygon(PackedVector2Array([v + Vector2(-lado, lado), v + Vector2(lado, lado), v]), EQUIPO)
	draw_rect(Rect2(v + Vector2(-lado * 0.2, -lado * 2.0), Vector2(lado * 0.4, lado)), EQUIPO.darkened(0.2))
	draw_rect(Rect2(v + Vector2(-lado * 0.8, -lado * 2.3), Vector2(lado * 1.6, lado * 0.4)), EQUIPO)
	_texto(fuente, "Válvula de expansión", v + Vector2(lado + 4.0, 4.0), t - 1, TEXTO, HORIZONTAL_ALIGNMENT_LEFT)


## Botella de baja: recipiente horizontal con su mirilla de nivel, y la bomba de amoníaco que
## envía el líquido al evaporador.
func _dibujar_botella(fuente: Font, t: int, escala: float) -> void:
	var caja := Rect2(_p(Vector2(0.53, 0.555)), _p(Vector2(0.665, 0.635)) - _p(Vector2(0.53, 0.555)))
	var suelo := _p(Vector2(0.0, 0.655)).y
	for x: float in [0.555, 0.64]:
		DibujoEquipos.silleta(self, Vector2(_p(Vector2(x, 0.0)).x, caja.end.y - 2.0), caja.size.x * 0.12, suelo - caja.end.y + 2.0)
	DibujoEquipos.recipiente(self, caja, Color("8a4b3c"))
	var mir := Rect2(Vector2(caja.end.x + 4.0, caja.position.y - caja.size.y * 0.1), Vector2(maxf(caja.size.x * 0.06, 4.0), caja.size.y * 1.2))
	for y: float in [mir.position.y + 2.0, mir.end.y - 2.0]:
		draw_line(Vector2(caja.end.x - caja.size.x * 0.12, y), Vector2(mir.end.x, y), Color("3a3f43"), 2.0)
	DibujoEquipos.mirilla(self, mir, nivel_botella, BAJA)
	_texto(fuente, "Botella de baja %d %%" % roundi(nivel_botella * 100.0), Vector2(mir.end.x + 5.0, caja.position.y + t), t - 1, TEXTO, HORIZONTAL_ALIGNMENT_LEFT)
	var bomba := _p(Vector2(0.60, 0.71))
	var r := 9.0 * maxf(escala, 0.8)
	DibujoEquipos.motor(self, Rect2(bomba + Vector2(r, -r * 0.75), Vector2(r * 2.6, r * 1.5)), DibujoEquipos.PINTURA_MOTOR, false)
	DibujoEquipos.bomba(self, bomba, r, Color("6d7478"), _giro, en_marcha and bomba_amoniaco, BAJA if bomba_amoniaco else EQUIPO)
	_texto(fuente, "Bomba NH3", bomba + Vector2(r * 3.8, 4.0), t - 1, TEXTO, HORIZONTAL_ALIGNMENT_LEFT)


func _texto(fuente: Font, texto: String, posicion: Vector2, t: int, color: Color, alineacion := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
	var x := posicion.x
	if alineacion == HORIZONTAL_ALIGNMENT_CENTER:
		x -= ancho / 2.0
	elif alineacion == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= ancho
	draw_string(fuente, Vector2(x, posicion.y), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, color)
