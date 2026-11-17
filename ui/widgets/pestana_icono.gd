class_name PestanaIcono
extends Button
## Pestaña de las fichas y del atlas: una tecla con relieve, el icono en un disco y el nombre
## debajo. La elegida se enciende en ámbar con una barra de luz arriba; las ya vistas llevan
## una lámpara verde pequeña en la esquina.

const ALTO := 58.0

var clave := ""
var nombre := ""
var icono := ""
var elegida := false
var vista := false


func _init(p_clave := "", p_nombre := "", p_icono := "", al_pulsar := Callable()) -> void:
	clave = p_clave
	nombre = p_nombre
	icono = p_icono
	text = ""
	tooltip_text = p_nombre
	name = "Pestana_%s" % p_clave
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(52, ALTO)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	for s in [button_down, button_up, mouse_entered, mouse_exited]:
		s.connect(queue_redraw)
	if al_pulsar.is_valid():
		pressed.connect(al_pulsar)


func poner(p_elegida: bool, p_vista := false) -> void:
	elegida = p_elegida
	vista = p_vista
	queue_redraw()


## Tira de pestañas en un hueco: items es [[clave, nombre, icono], ...]; al_elegir recibe la clave.
static func tira(items: Array, elegida_clave: String, vistas: Array, al_elegir: Callable) -> PanelContainer:
	var hueco := PanelContainer.new()
	hueco.name = "Pestanas"
	hueco.mouse_filter = Control.MOUSE_FILTER_PASS
	hueco.add_theme_stylebox_override("panel", Relieve.estilo_hueco(4.0, 12.0))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	hueco.add_child(fila)
	for item: Array in items:
		var p := PestanaIcono.new(item[0], item[1], item[2], al_elegir.bind(item[0]))
		p.poner(item[0] == elegida_clave, vistas.has(item[0]))
		fila.add_child(p)
	return hueco


## Las pestañas de una tira hecha con tira().
static func de_tira(hueco: Control) -> Array[PestanaIcono]:
	var lista: Array[PestanaIcono] = []
	for p in hueco.get_child(0).get_children():
		lista.append(p)
	return lista


func _draw() -> void:
	var r := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	var hundido := get_draw_mode() in [DRAW_PRESSED, DRAW_HOVER_PRESSED]
	if hundido:
		r.position.y += 1.0
	if elegida:
		for i in 3:
			DibujoAri.borde(self, r.grow(1.0 + i * 1.5), 9.0 + i * 1.5, Color(Relieve.AMBAR_HALO, 0.2 - i * 0.06), 1.5)
		var claro := Color("2f3a45").lerp(Relieve.AMBAR, 0.3)
		DibujoAri.pieza(self, r, 9.0, [claro, Color("2f3a45").lerp(Relieve.AMBAR, 0.12), Color("1d262f")], [], Color("a87810"), Color(1, 0.9, 0.6, 0.35), 0.45)
	else:
		var colores := [Color("323f4b"), Color("26313c"), Color("1d262f")]
		if hundido:
			colores = colores.map(func(c: Color) -> Color: return c.darkened(0.2))
		DibujoAri.pieza(self, r, 9.0, colores, [], Color("0b1015"), Color(1, 1, 1, 0.15), 0.0 if hundido else 0.45)
	var cx := r.get_center().x
	var tam_texto := float(Tema.tam(12))
	var lado := minf(r.size.y - tam_texto - 16.0, 30.0)
	var c := Vector2(cx, r.position.y + 6.0 + lado / 2.0)
	var radio := lado / 2.0
	if elegida:
		DibujoAri.relleno(self, Rect2(r.position.x + r.size.x * 0.18, r.position.y - 1.0, r.size.x * 0.64, 3.0), 1.5, Relieve.AMBAR)
		for i in 3:
			DibujoAri.borde(self, Rect2(r.position.x + r.size.x * 0.18, r.position.y - 1.0, r.size.x * 0.64, 3.0).grow(1.0 + i), 2.5 + i, Color(Relieve.AMBAR_HALO, 0.25 - i * 0.07), 1.5)
		Relieve.halo(self, c, radio * 1.9, Relieve.AMBAR_HALO, 1.1)
		ci_disco(c, radio, Color("fff4cf"), Color("a86500"))
		Relieve.dibujar_icono(self, icono, c, radio * 1.15, Color("2a1a00"))
	else:
		ci_disco(c, radio, Color("4a5865"), Color("1c242c"))
		Relieve.dibujar_icono(self, icono, c, radio * 1.15, Color("d6dde3"))
	while tam_texto > 8.0 and PiezasAri.ancho_texto(nombre, tam_texto) > r.size.x - 6.0:
		tam_texto -= 0.5
	var tinta := Color("ffe2a0") if elegida else Color("b9c5cf")
	PiezasAri.texto(self, nombre, cx, r.end.y - 7.0, tam_texto, tinta, Tema.PESO_NEGRITA)
	if vista and not elegida:
		PiezasAri.lampara(self, Vector2(r.end.x - 8.0, r.position.y + 8.0), 3.2, "verde", 1.0)


func ci_disco(c: Vector2, r: float, claro: Color, oscuro: Color) -> void:
	draw_circle(c + Vector2(0, 1.2), r + 1.5, Color(0, 0, 0, 0.55))
	draw_circle(c, r + 1.0, Color("0b1015"))
	PiezasAri._disco(self, c, r, claro, oscuro, Vector2(-0.24, -0.4), 10)
	draw_arc(c, r - 0.5, 0.0, TAU, 32, Color(1, 1, 1, 0.2), 1.0, true)
