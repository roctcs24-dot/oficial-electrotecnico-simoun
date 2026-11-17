class_name AvisoAri
extends PanelContainer
## Aviso del marco de simulador: tarjeta azul con cabecera roja (alarma, como un disparo) o
## ámbar (evento de manejo), triángulo de aviso, panel y hora, el texto y el botón ACK. Va en
## una CapaAvisos que oscurece el resto de la pantalla hasta que se reconoce.

const ANCHO_MAXIMO := 460.0
const ALTO_CABECERA := 34.0

var tipo := "evento"
var boton: BotonAri
var _cabecera: Control


class Cabecera:
	extends Control
	var colores: Array
	var titulo := ""

	func _init(c: Array, t: String) -> void:
		colores = c
		titulo = t
		custom_minimum_size.y = AvisoAri.ALTO_CABECERA
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DibujoAri.degradado(self, Rect2(r.position, r.size + Vector2(0, 20)), 9.0, colores, DibujoAri.BRILLO, r)
		draw_line(Vector2(0, size.y - 0.5), Vector2(size.x, size.y - 0.5), Color(0, 0, 0, 0.45), 1.0)
		var lado := size.y * 0.56
		var t := Rect2(Vector2(12, (size.y - lado) / 2.0), Vector2(lado * 1.1, lado))
		DibujoAri.triangulo_aviso(self, t, Tema.ARI_EVENTO)
		var f := PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 1)
		var tam := Tema.tam(13)
		var x := t.end.x + 9.0
		var base := size.y / 2.0 + f.get_ascent(tam) * 0.36
		var ancho := size.x - x - 10.0
		draw_string(f, Vector2(x, base + 1.0), titulo.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, Color(0, 0, 0, 0.45))
		draw_string(f, Vector2(x, base), titulo.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, Color.WHITE)


func _init(titulo: String, texto: String, p_tipo := "evento", meta := "", al_cerrar := Callable()) -> void:
	tipo = p_tipo
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var vacia := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", vacia)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(columna)
	_cabecera = Cabecera.new(Tema.ARI_CABECERA_ROJA if tipo == "alarma" else Tema.ARI_AMBAR, titulo)
	columna.add_child(_cabecera)
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 14)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 10)
	columna.add_child(m)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 8)
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(dentro)
	if not meta.is_empty():
		var linea := PanelAri.texto(meta, 11.5, Color("8fb3d3"), Tema.PESO_NEGRITA)
		linea.add_theme_font_override("font", PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 1))
		dentro.add_child(linea)
	var cuerpo := PanelAri.texto(texto, 14, Color("e8f1f9"), Tema.PESO_NORMAL)
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cuerpo.custom_minimum_size.x = 200
	dentro.add_child(cuerpo)
	boton = BotonAri.new("ACK · Entendido", al_cerrar)
	boton.name = "Entendido"
	boton.add_theme_font_size_override("font_size", Tema.tam(14))
	dentro.add_child(boton)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var halo := Color(Tema.ARI_ROJO[1], 0.22) if tipo == "alarma" else Color(Tema.ARI_AMBAR[1], 0.16)
	for i in 4:
		DibujoAri.relleno(self, r.grow(4.0 + i * 3.0), 12.0 + i * 3.0, Color(halo, halo.a / (i + 1)))
	DibujoAri.sombra(self, r, 10.0, 0.6, Vector2(0, 8), 5)
	DibujoAri.degradado(self, r, 10.0, [Color("245d90"), Color("163f66")])
	DibujoAri.borde(self, r, 10.0, Tema.ARI_BORDE)


## Capa que pone los avisos en el centro de la pantalla, sobre todo el marco, con un velo
## oscuro detrás. Se dibuja aparte del recorte del cuerpo y se oculta cuando no hay avisos.
class CapaAvisos:
	extends VBoxContainer

	func _init() -> void:
		top_level = true
		z_index = 50
		alignment = BoxContainer.ALIGNMENT_CENTER
		mouse_filter = Control.MOUSE_FILTER_STOP
		add_theme_constant_override("separation", 8)
		visible = false
		child_entered_tree.connect(func(_n: Node) -> void: _actualizar.call_deferred())
		child_exiting_tree.connect(func(_n: Node) -> void: _actualizar.call_deferred())

	func _actualizar() -> void:
		if not is_inside_tree():
			return
		var hay := false
		for hijo in get_children():
			if not hijo.is_queued_for_deletion():
				hay = true
		visible = hay
		_encajar()

	func _encajar() -> void:
		var vista := get_viewport_rect()
		position = Vector2.ZERO
		size = vista.size
		var ancho := minf(AvisoAri.ANCHO_MAXIMO, vista.size.x - 32.0)
		for hijo in get_children():
			(hijo as Control).custom_minimum_size.x = ancho
		queue_redraw()

	func _notification(que: int) -> void:
		if que == NOTIFICATION_ENTER_TREE:
			get_viewport().size_changed.connect(_encajar)
		elif que == NOTIFICATION_EXIT_TREE:
			if get_viewport().size_changed.is_connected(_encajar):
				get_viewport().size_changed.disconnect(_encajar)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.04, 0.07, 0.58))
