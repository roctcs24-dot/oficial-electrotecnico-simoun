class_name VistaRed
extends Control
## Bus RS-485 dibujado de arriba abajo: el maestro arriba y los esclavos en el orden del cable,
## con los hilos A y B, los terminadores de 120 Ω, los cortes, la polaridad de cada equipo y
## el LED de comunicación. Tocar un equipo lo selecciona.

signal equipo_tocado(id: String)

const ALTO_EQUIPO := 78.0
const X_A := 22.0
const X_B := 40.0
const X_CAJA := 86.0
const A_COLOR := Color("c8a12a")
const B_COLOR := Color("2a7a3c")
const VERDE := Color("2fbf5a")
const AMBAR := Color("ffb020")
const ROJO := Color("e0463a")
const GRIS := Color("5a646b")

var red: SimRedModbus
var seleccion := ""
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func preparar(red_buque: SimRedModbus) -> void:
	red = red_buque
	custom_minimum_size.y = ALTO_EQUIPO * (red.esclavos.size() + 1) + 24.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	var pulsado: bool = (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT) or (evento is InputEventScreenTouch and evento.pressed)
	if not pulsado or red == null:
		return
	var i := int((evento.position.y - 6.0) / ALTO_EQUIPO)
	if i == 0:
		equipo_tocado.emit(red.maestro["id"])
	elif i >= 1 and i <= red.esclavos.size():
		equipo_tocado.emit(red.esclavos[i - 1]["id"])


func _y(i: int) -> float:
	return 6.0 + ALTO_EQUIPO * i + ALTO_EQUIPO * 0.5


func _draw() -> void:
	if red == null:
		return
	draw_style_box(Tema.caja(Tema.PAPEL, Tema.RADIO, 0, 0), Rect2(Vector2.ZERO, size))
	var n := red.esclavos.size()
	# Hilos A y B desde el maestro hasta el último equipo, con el corte si lo hay.
	for i in n:
		var y0 := _y(i)
		var y1 := _y(i + 1)
		if red.corte == i:
			var medio := (y0 + y1) * 0.5
			for x: float in [X_A, X_B]:
				var c := A_COLOR if x == X_A else B_COLOR
				draw_line(Vector2(x, y0), Vector2(x, medio - 7.0), c, 3.0)
				draw_line(Vector2(x, medio + 7.0), Vector2(x, y1), c, 3.0)
			draw_line(Vector2(X_A - 10.0, medio - 8.0), Vector2(X_B + 10.0, medio + 8.0), ROJO, 2.5)
			draw_line(Vector2(X_A - 10.0, medio + 8.0), Vector2(X_B + 10.0, medio - 8.0), ROJO, 2.5)
		else:
			draw_line(Vector2(X_A, y0), Vector2(X_A, y1), A_COLOR, 3.0)
			draw_line(Vector2(X_B, y0), Vector2(X_B, y1), B_COLOR, 3.0)
	_texto(Vector2(X_A, _y(n) + 26.0), "A", 12, A_COLOR)
	_texto(Vector2(X_B, _y(n) + 26.0), "B", 12, B_COLOR)
	_equipo(0, red.maestro, true)
	for i in n:
		_equipo(i + 1, red.esclavos[i], false)


func _equipo(i: int, e: Dictionary, es_maestro: bool) -> void:
	var y := _y(i)
	var caja := Rect2(X_CAJA, y - ALTO_EQUIPO * 0.5 + 5.0, size.x - X_CAJA - 8.0, ALTO_EQUIPO - 10.0)
	# Derivación de A y B hasta el equipo; cruzadas si están invertidas.
	var invertido: bool = e.get("invertido", false)
	var ya := y - 8.0
	var yb := y + 8.0
	if invertido:
		draw_polyline(PackedVector2Array([Vector2(X_A, ya), Vector2(62.0, ya), Vector2(72.0, yb), Vector2(X_CAJA, yb)]), A_COLOR, 2.0)
		draw_polyline(PackedVector2Array([Vector2(X_B, yb), Vector2(62.0, yb), Vector2(72.0, ya), Vector2(X_CAJA, ya)]), B_COLOR, 2.0)
	else:
		draw_line(Vector2(X_A, ya), Vector2(X_CAJA, ya), A_COLOR, 2.0)
		draw_line(Vector2(X_B, yb), Vector2(X_CAJA, yb), B_COLOR, 2.0)
	draw_circle(Vector2(X_A, ya), 3.0, A_COLOR)
	draw_circle(Vector2(X_B, yb), 3.0, B_COLOR)
	if e["terminacion"]:
		_terminador(Vector2(X_A, y - 30.0), Vector2(X_B, y - 30.0))
	var fondo := Color("f6f7f5") if e["id"] != seleccion else Color("d6e6f0")
	draw_rect(caja, fondo)
	draw_rect(caja, Tema.SELECCION if e["id"] == seleccion else Color("8a9298"), false, 2.0 if e["id"] == seleccion else 1.0)
	var x := caja.position.x + 34.0
	_texto(Vector2(x, caja.position.y + 14.0), e["nombre"], 14, Tema.TINTA, false)
	_texto(Vector2(x, caja.position.y + 32.0), e.get("equipo", ""), 12, Color("4c555b"), false)
	var linea := "%s baudios · %s" % [e["baudios"], e["formato"]]
	if not es_maestro:
		linea = "Dirección %d · %s" % [int(e["direccion"]), linea]
	else:
		linea = "Maestro · %s · espera %d ms" % [linea, int(e["timeout_ms"])]
	_texto(Vector2(x, caja.position.y + 50.0), linea, 12, Color("4c555b"), false)
	# LED de comunicación: parpadea con cada respuesta correcta.
	var centro := Vector2(caja.position.x + 17.0, y)
	var color := GRIS
	if es_maestro:
		color = VERDE if fmod(_t, 0.4) < 0.2 else VERDE.darkened(0.6)
	elif e.get("alimentado", true):
		var s := red.estado_de(e["id"])
		var estado: String = s.get("estado", "")
		color = {"ok": VERDE, "intermitente": AMBAR, "falla": ROJO}.get(estado, GRIS)
		if estado != "falla" and fmod(_t + i * 0.13, 0.5) < 0.18:
			color = color.lightened(0.35)
	draw_circle(centro, 8.0, color.darkened(0.5))
	draw_circle(centro, 6.0, color)


func _terminador(a: Vector2, b: Vector2) -> void:
	# Resistencia en zigzag entre A y B, rotulada.
	var puntos := PackedVector2Array([a])
	var pasos := 6
	for k in pasos:
		var x := a.x + (b.x - a.x) * (k + 0.5) / pasos
		puntos.append(Vector2(x, a.y + (-5.0 if k % 2 == 0 else 5.0)))
	puntos.append(b)
	draw_polyline(puntos, Color("8c3b30"), 2.0)
	draw_line(a, a + Vector2(0, 10.0), Color("8c3b30"), 1.5)
	draw_line(b, b + Vector2(0, 10.0), Color("8c3b30"), 1.5)
	_texto(Vector2(b.x + 8.0, a.y), "120 Ω", 11, Color("8c3b30"), false)


func _texto(p: Vector2, cadena: String, tam: int, color: Color, centrado := true) -> void:
	var fuente := get_theme_default_font()
	var ancho := size.x - p.x - 6.0
	var x := p.x
	if centrado:
		x -= fuente.get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x / 2.0
		ancho = -1
	draw_string(fuente, Vector2(x, p.y + tam * 0.35), cadena, HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, color, TextServer.JUSTIFICATION_NONE, TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)
