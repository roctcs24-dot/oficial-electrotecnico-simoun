class_name VistaMesa
extends Control
## Mesa del Taller: dibuja piezas y cables. Un toque en un borne o una pieza avisa a la
## pantalla; arrastrar mueve la pieza o la vista; rueda, pellizco o botones hacen zoom.

signal borne_tocado(nodo: String)
signal pieza_tocada(id: String)
signal cable_tocado(indice: int)
signal fondo_tocado

const ZOOM_MIN := 0.15
const ZOOM_MAX := 2.5
const ZONA_MUERTA := 10.0
## Radio táctil en pantalla, para acertar con el dedo aunque la vista esté alejada.
const RADIO_TOQUE := 24.0
const TOLERANCIA_CABLE := 14.0
const ESCALA_TEXTURA := 1.5
const FONDO := Color("0b1824")
const CUADRICULA := Color("15283a")
const LADO_CUADRICULA := 100.0

var mesa: MesaTaller
var origen := Vector2(20.0, 20.0)
var zoom := 0.5
## Primer borne de un cable en curso, o puntas del instrumento.
var borne_marcado := ""
var punta_roja := ""
var punta_negra := ""
var pieza_marcada := ""
var cable_marcado := -1

static var _texturas := {}

var _inicio_toque := Vector2.ZERO
var _pulsado := false
var _movido := false
var _pieza_arrastrada := ""
var _desfase_pieza := Vector2.ZERO
var _toques := {}
var _distancia_pellizco := 0.0
var _en_pellizco := false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func a_mesa(p: Vector2) -> Vector2:
	return (p - origen) / zoom


func a_pantalla(p: Vector2) -> Vector2:
	return origen + p * zoom


## Cambia el zoom manteniendo fijo el punto de pantalla indicado.
func cambiar_zoom(factor: float, centro: Vector2) -> void:
	var fijo := a_mesa(centro)
	zoom = clampf(zoom * factor, ZOOM_MIN, ZOOM_MAX)
	origen = centro - fijo * zoom
	queue_redraw()


## Ajusta la vista para que se vean todas las piezas.
func encuadrar() -> void:
	if mesa.piezas.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		origen = Vector2(20.0, 20.0)
		queue_redraw()
		return
	var limites := Rect2()
	var primero := true
	for id: String in mesa.piezas:
		var r := Rect2(mesa.posicion_pieza(id), mesa.tamano_pieza(id))
		limites = r if primero else limites.merge(r)
		primero = false
	var margen := 24.0
	zoom = clampf(minf((size.x - margen * 2.0) / limites.size.x, (size.y - margen * 2.0) / limites.size.y), ZOOM_MIN, ZOOM_MAX)
	origen = (size - limites.size * zoom) / 2.0 - limites.position * zoom
	queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		_boton_raton(evento)
	elif evento is InputEventMouseMotion and _pulsado and not _en_pellizco:
		_arrastrar(evento)
	elif evento is InputEventMagnifyGesture:
		cambiar_zoom(evento.factor, evento.position)
	elif evento is InputEventPanGesture:
		origen -= evento.delta * 8.0
		queue_redraw()


func _boton_raton(evento: InputEventMouseButton) -> void:
	if evento.button_index == MOUSE_BUTTON_WHEEL_UP and evento.pressed:
		cambiar_zoom(1.1, evento.position)
	elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN and evento.pressed:
		cambiar_zoom(1.0 / 1.1, evento.position)
	elif evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_pulsado = true
			_movido = false
			_inicio_toque = evento.position
			var en_mesa := a_mesa(evento.position)
			_pieza_arrastrada = ""
			if mesa.borne_en(en_mesa, RADIO_TOQUE / zoom).is_empty():
				_pieza_arrastrada = mesa.pieza_en(en_mesa)
				if not _pieza_arrastrada.is_empty():
					_desfase_pieza = en_mesa - mesa.posicion_pieza(_pieza_arrastrada)
		else:
			if _pulsado and not _movido and not _en_pellizco:
				tocar(evento.position)
			_pulsado = false
			_pieza_arrastrada = ""


func _arrastrar(evento: InputEventMouseMotion) -> void:
	if not _movido and evento.position.distance_to(_inicio_toque) < ZONA_MUERTA:
		return
	_movido = true
	if _pieza_arrastrada.is_empty():
		origen += evento.relative
	else:
		mesa.mover(_pieza_arrastrada, a_mesa(evento.position) - _desfase_pieza)
	queue_redraw()


## Un toque, ya distinguido de un arrastre. Los bornes tienen prioridad.
func tocar(p: Vector2) -> void:
	var en_mesa := a_mesa(p)
	var nodo := mesa.borne_en(en_mesa, RADIO_TOQUE / zoom)
	if not nodo.is_empty():
		borne_tocado.emit(nodo)
		return
	var cable := mesa.cable_en(en_mesa, TOLERANCIA_CABLE / zoom)
	var pieza := mesa.pieza_en(en_mesa)
	if not pieza.is_empty():
		pieza_tocada.emit(pieza)
	elif cable >= 0:
		cable_tocado.emit(cable)
	else:
		fondo_tocado.emit()


## El pellizco llega como dos toques: se atiende aquí, antes de que los botones lo reciban.
func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		if evento.pressed and get_global_rect().has_point(evento.position):
			_toques[evento.index] = evento.position
		else:
			_toques.erase(evento.index)
		if _toques.size() < 2:
			_distancia_pellizco = 0.0
			if _toques.is_empty():
				_en_pellizco = false
		else:
			_en_pellizco = true
	elif evento is InputEventScreenDrag and _toques.has(evento.index):
		var anterior: Vector2 = _toques[evento.index]
		_toques[evento.index] = evento.position
		if _toques.size() == 2:
			var valores: Array = _toques.values()
			var a: Vector2 = valores[0]
			var b: Vector2 = valores[1]
			var distancia := a.distance_to(b)
			if _distancia_pellizco > 0.0:
				cambiar_zoom(distancia / _distancia_pellizco, (a + b) / 2.0 - global_position)
				origen += (evento.position - anterior) / 2.0
			_distancia_pellizco = distancia


func _textura(ruta: String) -> Texture2D:
	if not _texturas.has(ruta):
		_texturas[ruta] = VistaSvg.rasterizar(ruta, ESCALA_TEXTURA)
	return _texturas[ruta]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	_dibujar_cuadricula()
	if mesa == null:
		return
	for id: String in mesa.piezas:
		_dibujar_pieza(id)
	for i in mesa.sim.cables.size():
		_dibujar_cable(i)
	for id: String in mesa.piezas:
		_dibujar_bornes(id)
	_dibujar_punta(punta_roja, Color("d8322a"))
	_dibujar_punta(punta_negra, Color("111214"))


func _dibujar_cuadricula() -> void:
	var paso := LADO_CUADRICULA * zoom
	if paso < 10.0:
		return
	var x := fposmod(origen.x, paso)
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), CUADRICULA, 1.0)
		x += paso
	var y := fposmod(origen.y, paso)
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), CUADRICULA, 1.0)
		y += paso


func _dibujar_pieza(id: String) -> void:
	var d := mesa.dibujo(mesa.piezas[id]["tipo"])
	var tam := mesa.tamano_pieza(id)
	var r := Rect2(a_pantalla(mesa.posicion_pieza(id)), tam * zoom)
	if not r.intersects(Rect2(Vector2.ZERO, size)):
		return
	var textura := _textura(d["svg"])
	if textura != null:
		draw_texture_rect(textura, r, false)
	var fuente := get_theme_default_font()
	for e: Dictionary in d.get("etiquetas", []):
		var t := int(float(e.get("tam", 14)) * zoom)
		if t < 7:
			continue
		var color: Color = Color(e["color"]) if e.has("color") else Color("eceee8")
		var ancho := fuente.get_string_size(e["texto"], HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
		var p := r.position + Vector2(e["x"], e["y"]) * zoom + Vector2(-ancho / 2.0, t * 0.35)
		draw_string(fuente, p, e["texto"], HORIZONTAL_ALIGNMENT_LEFT, -1, t, color)
	_dibujar_estado(id, r)
	if id == pieza_marcada:
		draw_rect(r.grow(3.0), Tema.ACENTO, false, 2.0)


func _dibujar_estado(id: String, r: Rect2) -> void:
	var c := mesa.sim.componente(id)
	if c.tipo() == "lampara" and c.estado["encendida"]:
		draw_circle(r.position + Vector2(100.0, 66.0) * zoom, 40.0 * zoom, Color("5dff8f"))
	var fuente := get_theme_default_font()
	var t := clampi(int(22.0 * zoom), 11, 20)
	var texto := "%s  %s" % [id, mesa.estado_pieza(id)]
	var color := Color("ff8a7a") if mesa.danada(id) else Tema.TEXTO
	draw_string(fuente, r.position + Vector2(0.0, -6.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, color)


func _dibujar_cable(i: int) -> void:
	var puntos := mesa.puntos_cable(i)
	var pantalla := PackedVector2Array()
	for p in puntos:
		pantalla.append(a_pantalla(p))
	var ancho := maxf(5.0 * zoom, 2.0)
	if i == cable_marcado:
		draw_polyline(pantalla, Tema.ACENTO, ancho + 4.0, true)
	else:
		draw_polyline(pantalla, Color(0.0, 0.0, 0.0, 0.5), ancho + 2.0, true)
	draw_polyline(pantalla, mesa.color_cable(i), ancho, true)


func _dibujar_bornes(id: String) -> void:
	for b: String in mesa.bornes(id):
		var nodo := "%s.%s" % [id, b]
		var p := a_pantalla(mesa.posicion_borne(nodo))
		var radio := maxf(8.0 * zoom, 4.0)
		if nodo == borne_marcado:
			draw_circle(p, radio + 5.0, Tema.ACENTO)
		else:
			draw_arc(p, radio + 2.0, 0.0, TAU, 20, Color(Tema.ACENTO, 0.7), 1.5, true)


func _dibujar_punta(nodo: String, color: Color) -> void:
	if nodo.is_empty() or not mesa.piezas.has(nodo.get_slice(".", 0)):
		return
	var p := a_pantalla(mesa.posicion_borne(nodo))
	draw_circle(p, 10.0, color)
	draw_arc(p, 10.0, 0.0, TAU, 24, Color.WHITE, 2.0, true)
