class_name VistaLineas
extends Control
## Esquema de líneas con relieve (data/lineas): tuberías en el color de su servicio
## (data/tuberias.json), equipos como chapas, la bomba, flechas de sentido y válvulas en medallas
## numeradas. Al arrastrar el dedo emite «tramo_tocado» con el tramo bajo el dedo; al tocar una
## válvula, «valvula_tocada». Los tramos de «iluminados» brillan en ámbar; «marcado» late (el de
## una pregunta); «tramo_mal» parpadea en rojo un momento.

signal tramo_tocado(id: String)
signal valvula_tocada(id: String)

const AMBAR := Color("ffc23a")
const ROJO := Color("ff5a4f")
const VERDE := Color("45ff82")

var esquema := {}
var colores := {}
var iluminados: Array = []
var marcado := ""
## Estado de cada válvula: "cerrada", "abierta", "elegida", "falta" (debía cerrarse) o "sobra".
var estados := {}
var activo := true
var tramo_mal := ""
var _tiempo := 0.0
var _mal_hasta := 0.0
var _presionado := false
var _ultimo := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(260, 160)
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_tiempo += delta
	if not tramo_mal.is_empty() and _tiempo > _mal_hasta:
		tramo_mal = ""
	queue_redraw()


func espacio() -> Vector2:
	return Vector2(float(esquema.get("ancho", 440)), float(esquema.get("alto", 260)))


func escala() -> float:
	if size.x <= 0.0 or size.y <= 0.0:
		return 1.0
	var e := espacio()
	return minf(size.x / e.x, size.y / e.y)


func origen() -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ZERO
	return (size - espacio() * escala()) / 2.0


func a_esquema(p: Vector2) -> Vector2:
	return (p - origen()) / maxf(escala(), 0.001)


func a_control(p: Vector2) -> Vector2:
	return origen() + p * escala()


func marcar_mal(id: String) -> void:
	tramo_mal = id
	_mal_hasta = _tiempo + 0.7


# --- Entrada ---

func _gui_input(evento: InputEvent) -> void:
	if not activo:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		var b := evento as InputEventMouseButton
		_presionado = b.pressed
		_ultimo = ""
		if b.pressed:
			pulsar(b.position)
		accept_event()
	elif evento is InputEventMouseMotion and _presionado:
		arrastrar((evento as InputEventMouseMotion).position)
		accept_event()


## Toque en «p» (coordenadas del control): avisa de la válvula, si la hay, y del tramo bajo el
## dedo (las válvulas están sobre su línea, así que al seguirla también se tocan).
func pulsar(p: Vector2) -> void:
	var v := JuegoLineas.valvula_en(esquema, a_esquema(p))
	if not v.is_empty():
		valvula_tocada.emit(v)
	arrastrar(p)


## Paso del dedo por «p»: avisa del tramo bajo el dedo cuando cambia.
func arrastrar(p: Vector2) -> void:
	var t := JuegoLineas.tramo_en(esquema, a_esquema(p))
	if t != _ultimo:
		_ultimo = t
		if not t.is_empty():
			tramo_tocado.emit(t)


# --- Dibujo ---

func _draw() -> void:
	var k := escala()
	draw_set_transform(origen(), 0.0, Vector2(k, k))
	var latido := 0.6 + 0.4 * sin(_tiempo * 4.0)
	for t: Dictionary in esquema.get("tramos", []):
		_tramo(t, latido)
	for f: Array in esquema.get("flechas", []):
		_flecha(Vector2(float(f[0]), float(f[1])), deg_to_rad(float(f[2])))
	for e: Dictionary in esquema.get("equipos", []):
		if e.get("forma", "") == "bomba":
			_bomba(e)
		else:
			_equipo(e)
	for v: Dictionary in esquema.get("valvulas", []):
		_valvula(v, latido)


func _tramo(t: Dictionary, latido: float) -> void:
	var p := JuegoLineas.puntos(t)
	var ancho := float(t.get("ancho", 10.0))
	var c: Dictionary = colores.get(t["servicio"], {"color": "#888888", "claro": "#cccccc", "oscuro": "#444444"})
	var id: String = t["id"]
	if iluminados.has(id):
		draw_polyline(p, Color(1.0, 0.69, 0.0, 0.35), ancho + 12.0, true)
	if id == marcado:
		draw_polyline(p, Color(1.0, 0.69, 0.0, 0.25 + 0.35 * latido), ancho + 14.0, true)
	if id == tramo_mal:
		draw_polyline(p, Color(1.0, 0.3, 0.25, 0.55), ancho + 12.0, true)
	var sombra := PackedVector2Array()
	for q in p:
		sombra.append(q + Vector2(0, 3))
	draw_polyline(sombra, Color(0, 0, 0, 0.45), ancho + 3.0, true)
	draw_polyline(p, Color("0a0d10"), ancho + 3.0, true)
	draw_polyline(p, Color(str(c["color"])), ancho, true)
	var brillo := PackedVector2Array()
	for q in p:
		brillo.append(q + Vector2(0, -ancho * 0.22))
	draw_polyline(brillo, Color(str(c["claro"])).lerp(Color(1, 1, 1, 0), 0.25), ancho * 0.3, true)
	for q in p:
		draw_circle(q, ancho / 2.0, Color(str(c["color"])))
	if iluminados.has(id):
		for i in p.size() - 1:
			draw_dashed_line(p[i], p[i + 1], Color("ffd166"), 2.5, 8.0)


func _flecha(c: Vector2, angulo: float) -> void:
	var d := Vector2.from_angle(angulo)
	var n := d.orthogonal()
	draw_polyline(PackedVector2Array([c - d * 4 + n * 5, c + d * 3, c - d * 4 - n * 5]), Color(1, 1, 1, 0.8), 2.0, true)


func _equipo(e: Dictionary) -> void:
	var r := Rect2(float(e["rect"][0]), float(e["rect"][1]), float(e["rect"][2]), float(e["rect"][3]))
	DibujoAri.relleno(self, Rect2(r.position + Vector2(0, 3), r.size), 8.0, Color(0, 0, 0, 0.5))
	DibujoAri.relleno(self, r.grow(1.5), 9.0, Color("0a0d10"))
	DibujoAri.degradado(self, r, 8.0, [Color("e9eef2"), Color("b6c0c8"), Color("7d8891")])
	DibujoAri.relleno(self, Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8.0, 4.0)), 2.0, Color(1, 1, 1, 0.45))
	var sub := str(e.get("sub", ""))
	var y := r.get_center().y + (0.0 if sub.is_empty() else -2.0)
	PiezasAri.texto(self, str(e["nombre"]), r.get_center().x, y + 4.0, 10.0, Color("20262c"))
	if not sub.is_empty():
		PiezasAri.texto(self, sub, r.get_center().x, y + 15.0, 8.0, Color("3b444c"), Tema.PESO_FUERTE)


func _bomba(e: Dictionary) -> void:
	var c := Vector2(float(e["centro"][0]), float(e["centro"][1]))
	var r := float(e.get("radio", 17.0))
	draw_circle(c + Vector2(0, 3), r + 1.5, Color(0, 0, 0, 0.5))
	draw_circle(c, r + 1.5, Color("0a0d10"))
	PiezasAri._disco(self, c, r, Color("eef2f4"), Color("7d8891"), Vector2(-0.3, -0.35), 8)
	draw_polyline(PackedVector2Array([c + Vector2(-9, -9), c + Vector2(12, 0), c + Vector2(-9, 9)]), Color("20262c"), 2.5, true)
	PiezasAri.texto(self, "%s %s" % [str(e["nombre"]), str(e.get("sub", ""))], c.x, c.y + r + 13.0, 8.0, Color("cfd8df"))


func _valvula(v: Dictionary, latido: float) -> void:
	var c := Vector2(float(v["x"]), float(v["y"]))
	var r := 13.0
	var estado: String = estados.get(v["id"], "")
	var color := Color("c9d3dc")
	match estado:
		"cerrada", "elegida":
			color = ROJO
		"abierta":
			color = VERDE
		"falta":
			color = AMBAR
		"sobra":
			color = ROJO
	if not estado.is_empty():
		Relieve.halo(self, c, r * 2.0, color, 0.7 if estado != "falta" else 0.4 + 0.6 * latido)
	draw_circle(c + Vector2(0, 3), r + 2.0, Color(0, 0, 0, 0.5))
	draw_circle(c, r + 2.0, Color("0a0d10"))
	PiezasAri._disco(self, c, r, Color("4a5560"), Color("151b21"), Vector2(-0.3, -0.35), 8)
	draw_arc(c, r, 0.0, TAU, 32, color, 2.0, true)
	var a := 8.0
	var b := 5.5
	var pts := [Vector2(-a, -b), Vector2(a, b), Vector2(a, -b), Vector2(-a, b)]
	if bool(v.get("vertical", false)):
		pts = pts.map(func(q: Vector2) -> Vector2: return Vector2(q.y, q.x))
	var cuerpo := PackedVector2Array()
	for q: Vector2 in pts:
		cuerpo.append(c + q)
	if estado in ["cerrada", "elegida", "sobra"]:
		draw_colored_polygon(PackedVector2Array([cuerpo[0], cuerpo[3], c]), color)
		draw_colored_polygon(PackedVector2Array([cuerpo[1], cuerpo[2], c]), color)
	var linea := cuerpo.duplicate()
	linea.append(cuerpo[0])
	draw_polyline(linea, color, 1.8, true)
	if estado == "sobra":
		draw_line(c + Vector2(-r, -r) * 0.8, c + Vector2(r, r) * 0.8, Color.WHITE, 2.0, true)
	var m := c + Vector2(r + 1.0, -r - 1.0)
	draw_circle(m, 8.5, Color("10141a"))
	PiezasAri._disco(self, m, 7.5, Color("fff3c4"), Color("d99614"), Vector2(-0.3, -0.35), 6)
	PiezasAri.texto(self, str(v["n"]), m.x, m.y + 3.8, 10.5, Color("2a1a00"))
