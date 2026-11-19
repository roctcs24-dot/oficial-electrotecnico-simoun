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
const TOLERANCIA_CABLE_EXACTA := 6.0
const RADIO_MANGO := 10.0
const ALFA_ATENUADO := 0.3
## Marcadores de los cables: a qué distancia del borne van (unidades de mesa) y desde qué zoom se
## dibujan todos; más alejado taparían la vista, y solo se ven los del cable tocado.
const DISTANCIA_MARCADOR := 40.0
## Terminación del cable en el borne, en unidades de mesa: tubo metálico de la puntera, cuello de
## plástico (rojo 1 mm² en mando, azul 2,5 mm² en potencia, DIN 46228), silleta y tornillo.
const PUNTERA := 14.0
const CUELLO := 8.0
const ANCHO_PUNTERA := 4.6
const ANCHO_CUELLO := 8.0
const RECORTE_CABLE := PUNTERA + CUELLO - 2.0
const LADO_SILLETA := Vector2(18.0, 17.0)
const RADIO_TORNILLO := 7.0
const RADIO_BORNE_LIBRE := 13.0
const COLOR_CUELLO_MANDO := Color("d23a2f")
const COLOR_CUELLO_POTENCIA := Color("2f74c6")
const METAL := Color("c9cfd3")
## Radio de las esquinas de los cables ordenados y largo del desvío en S cuando casi no hay desvío.
const RADIO_ESQUINA := 12.0
const TRAMO_S := 14.0
const ZOOM_ETIQUETAS := 0.6
const ESCALA_TEXTURA := 1.5
const FONDO := Color("0b1824")
const CUADRICULA := Color("15283a")
const LADO_CUADRICULA := 100.0
## Consecuencias visibles: el arco es un destello breve; el humo y el disparo duran algo más.
const DURACION_EFECTO_S := {"arco": 0.7, "humo": 2.5, "disparo": 1.2}
const EFECTO_DE_EVENTO := {
	"arco_contactos_soldados": "arco", "disparo_barras": "arco", "disparo_magnetico": "arco",
	"motor_quemado": "humo", "bobina_quemada": "humo", "lampara_quemada": "humo", "fusible_fundido": "humo",
	"disparo_rele_termico": "disparo", "disparo_termico": "disparo",
}
## Por encima de esta temperatura el motor se tiñe de rojo, cada vez más hasta quemarse.
const T_TINTE := 90.0
const T_TINTE_MAX := 180.0

var mesa: MesaTaller
var origen := Vector2(20.0, 20.0)
var zoom := 0.5
## Cuántos cables llegan a cada borne, contado en cada dibujo.
var _por_borne := {}
## Primer borne de un cable en curso, o puntas del instrumento.
var borne_marcado := ""
var punta_roja := ""
var punta_negra := ""
var pieza_marcada := ""
var cable_marcado := -1
## Marcadores de destino en los dos extremos de cada cable (como los manguitos de un tablero).
var etiquetas := true
## Cables abrazados por la pinza amperimétrica.
var cables_pinza: Array = []

static var _texturas := {}

var _inicio_toque := Vector2.ZERO
var _pulsado := false
var _movido := false
var _pieza_arrastrada := ""
var _mango_arrastrado := false
var _desfase_pieza := Vector2.ZERO
var _toques := {}
var _distancia_pellizco := 0.0
var _en_pellizco := false
## {id, tipo, t}: efectos en curso.
var efectos: Array[Dictionary] = []


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


## Muestra la consecuencia de un evento sobre su pieza. Devuelve false si no tiene efecto.
func mostrar_evento(tipo_evento: String, id: String) -> bool:
	if not EFECTO_DE_EVENTO.has(tipo_evento) or mesa == null or not mesa.piezas.has(id):
		return false
	efectos.append({"id": id, "tipo": EFECTO_DE_EVENTO[tipo_evento], "t": 0.0})
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if efectos.is_empty():
		return
	for e in efectos:
		e["t"] += delta
	efectos = efectos.filter(func(e: Dictionary) -> bool: return e["t"] < DURACION_EFECTO_S[e["tipo"]])
	queue_redraw()


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
			_mango_arrastrado = _mango_en(evento.position)
			if _mango_arrastrado:
				return
			if mesa.borne_en(en_mesa, RADIO_TOQUE / zoom).is_empty():
				_pieza_arrastrada = mesa.pieza_en(en_mesa)
				if not _pieza_arrastrada.is_empty():
					_desfase_pieza = en_mesa - mesa.posicion_pieza(_pieza_arrastrada)
		else:
			if _pulsado and not _movido and not _en_pellizco:
				tocar(evento.position)
			_pulsado = false
			_pieza_arrastrada = ""
			_mango_arrastrado = false


## El mango solo existe en el cable seleccionado.
func _mango_en(p: Vector2) -> bool:
	if cable_marcado < 0 or cable_marcado >= mesa.sim.cables.size() or not mesa.tiene_mango(cable_marcado):
		return false
	return a_pantalla(mesa.mango_cable(cable_marcado)).distance_to(p) <= RADIO_TOQUE


func _arrastrar(evento: InputEventMouseMotion) -> void:
	if not _movido and evento.position.distance_to(_inicio_toque) < ZONA_MUERTA:
		return
	_movido = true
	if _mango_arrastrado:
		mesa.mover_mango(cable_marcado, a_mesa(evento.position))
	elif _pieza_arrastrada.is_empty():
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
	# Un cable sobre una pieza se puede tocar si el dedo cae justo encima de él.
	var cable_exacto := mesa.cable_en(en_mesa, TOLERANCIA_CABLE_EXACTA / zoom)
	var cable := mesa.cable_en(en_mesa, TOLERANCIA_CABLE / zoom)
	var pieza := mesa.pieza_en(en_mesa)
	if cable_exacto >= 0:
		cable_tocado.emit(cable_exacto)
	elif not pieza.is_empty():
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


## Imagen de una pieza: la realista de art/realista si existe (tools/dibujos_realistas) y, si no,
## el SVG rasterizado.
func _textura(ruta: String) -> Texture2D:
	if not _texturas.has(ruta):
		var realista := VistaSvg.ruta_realista(ruta)
		if not realista.is_empty() and ResourceLoader.exists(realista):
			_texturas[ruta] = load(realista)
			# Con mipmaps, la pieza alejada no parpadea ni se ve granulada.
			texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		else:
			_texturas[ruta] = VistaSvg.rasterizar(ruta, ESCALA_TEXTURA)
	return _texturas[ruta]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	_dibujar_cuadricula()
	if mesa == null:
		return
	for id: String in mesa.piezas:
		_dibujar_pieza(id)
	_contar_por_borne()
	# El cable seleccionado va al final, sobre los demás.
	for i in mesa.sim.cables.size():
		if i != cable_marcado:
			_dibujar_cable(i)
	if cable_marcado >= 0 and cable_marcado < mesa.sim.cables.size():
		_dibujar_cable(cable_marcado)
	for id: String in mesa.piezas:
		_dibujar_bornes(id)
	if etiquetas and zoom >= ZOOM_ETIQUETAS:
		for i in mesa.sim.cables.size():
			if i != cable_marcado:
				_dibujar_marcadores(i)
	if cable_marcado >= 0 and cable_marcado < mesa.sim.cables.size():
		_dibujar_marcadores(cable_marcado)
	if cable_marcado >= 0 and cable_marcado < mesa.sim.cables.size() and mesa.tiene_mango(cable_marcado):
		var mango := a_pantalla(mesa.mango_cable(cable_marcado))
		draw_circle(mango, RADIO_MANGO, Tema.ACENTO)
		draw_arc(mango, RADIO_MANGO, 0.0, TAU, 24, Color.WHITE, 2.0, true)
	for i: int in cables_pinza:
		if i < mesa.sim.cables.size():
			_dibujar_pinza(i)
	_dibujar_punta(punta_roja, Color("d8322a"))
	_dibujar_punta(punta_negra, Color("111214"))
	for e: Dictionary in efectos:
		_dibujar_efecto(e)


func _rect_pieza(id: String) -> Rect2:
	return Rect2(a_pantalla(mesa.posicion_pieza(id)), mesa.tamano_pieza(id) * zoom)


func _dibujar_efecto(e: Dictionary) -> void:
	if not mesa.piezas.has(e["id"]):
		return
	var r := _rect_pieza(e["id"])
	var centro := r.get_center()
	var avance: float = e["t"] / DURACION_EFECTO_S[e["tipo"]]
	var radio := maxf(r.size.x, r.size.y) * 0.5
	match e["tipo"]:
		"arco":
			draw_circle(centro, radio * (0.6 + avance * 0.6), Color(0.85, 0.92, 1.0, 0.75 * (1.0 - avance)))
			# Trazos quebrados fijos por pieza: el destello no cambia de forma en cada cuadro.
			var azar := RandomNumberGenerator.new()
			azar.seed = hash(e["id"])
			for _rayo in 5:
				var puntos := PackedVector2Array([centro])
				var angulo := azar.randf() * TAU
				for paso in 4:
					angulo += azar.randf_range(-0.6, 0.6)
					puntos.append(puntos[-1] + Vector2.from_angle(angulo) * radio * 0.3)
				draw_polyline(puntos, Color(1.0, 1.0, 1.0, 1.0 - avance), maxf(3.0 * zoom, 1.5), true)
		"humo":
			for i in 4:
				var fase := fposmod(avance + i * 0.25, 1.0)
				var p := centro + Vector2((i - 1.5) * radio * 0.25, -fase * radio * 1.4)
				draw_circle(p, radio * (0.15 + fase * 0.25), Color(0.35, 0.36, 0.38, 0.55 * (1.0 - fase)))
		"disparo":
			draw_arc(centro, radio * (0.5 + avance * 0.5), 0.0, TAU, 40, Color(Tema.ACENTO, 1.0 - avance), maxf(6.0 * zoom, 2.0), true)


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


## LED de un equipo: un punto de color con su brillo, en coordenadas de la pieza.
func _led(r: Rect2, p: Vector2, color: Color, encendido: bool) -> void:
	var c := r.position + p * zoom
	var radio := maxf(6.0 * zoom, 2.0)
	if encendido:
		draw_circle(c, radio * 2.0, Color(color, 0.3))
	draw_circle(c, radio, color if encendido else color.darkened(0.75))


func _dibujar_leds(c: SimComponente, r: Rect2) -> void:
	match c.tipo():
		"sensor_proximidad":
			_led(r, Vector2(200.0, 65.5), Color("ffb020"), c.estado["activa"])
		"fuente_dc":
			_led(r, Vector2(60.0, 193.0), Color("5dff8f"), (c as SimFuenteDC).activa())
		"rele_dc":
			_led(r, Vector2(200.0, 92.0), Color("ff5a4a"), c.estado["energizado"])
		"plc":
			var plc := c as SimPLC
			_led(r, Vector2(78.0, 140.0), Color("5dff8f"), plc.en_marcha())
			_led(r, Vector2(78.0, 166.0), Color("ffb020"), plc.estado["alimentado"] and plc.estado["modo"] != "RUN")
			for i in SimPLC.ENTRADAS:
				_led(r, Vector2(190.0 + 54.0 * i, 96.0), Color("5dff8f"), plc.entrada_activa(i))
			for i in SimPLC.SALIDAS:
				_led(r, Vector2(120.0 + 64.0 * i, 214.0), Color("5dff8f"), plc.salida_activa(i))


func _dibujar_estado(id: String, r: Rect2) -> void:
	var c := mesa.sim.componente(id)
	_dibujar_leds(c, r)
	if c.tipo() == "lampara" and c.estado["encendida"]:
		draw_circle(r.position + Vector2(100.0, 66.0) * zoom, 40.0 * zoom, Color("5dff8f"))
	if c.tipo() == "motor_trifasico":
		var calor := clampf((c.estado["temperatura"] - T_TINTE) / (T_TINTE_MAX - T_TINTE), 0.0, 1.0)
		if c.estado["quemado"]:
			draw_rect(r, Color(0.05, 0.04, 0.03, 0.5))
		elif calor > 0.0:
			draw_rect(r, Color(0.9, 0.2, 0.1, 0.45 * calor))
	var fuente := get_theme_default_font()
	var t := clampi(int(22.0 * zoom), 11, 20)
	var texto := "%s  %s" % [id, mesa.estado_pieza(id)]
	# Con la vista alejada, el estado completo pisaría el rótulo de la pieza vecina.
	if fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x > r.size.x:
		texto = id
	var color := Color("ff8a7a") if mesa.danada(id) else Tema.TEXTO
	draw_string(fuente, r.position + Vector2(0.0, -6.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, color)


## Las mordazas de la pinza, cerradas sobre el punto medio del cable.
func _dibujar_pinza(i: int) -> void:
	var puntos := mesa.puntos_cable(i)
	var centro := a_pantalla(puntos[puntos.size() / 2] if puntos.size() % 2 == 1 else (puntos[puntos.size() / 2 - 1] + puntos[puntos.size() / 2]) / 2.0)
	var radio := RADIO_MANGO + 4.0
	draw_arc(centro, radio, 0.0, TAU, 32, Color("1f2326"), 9.0, true)
	draw_arc(centro, radio, 0.0, TAU, 32, Color("e0b324"), 5.0, true)
	draw_line(centro + Vector2(radio, 0.0), centro + Vector2(radio * 2.2, radio * 1.2), Color("e0b324"), 6.0, true)


func _dibujar_cable(i: int) -> void:
	var puntos := trazado_cable(i)
	var cuerpo := _recortar(puntos, minf(RECORTE_CABLE, _largo(puntos) * 0.3))
	var pantalla := PackedVector2Array()
	for p in cuerpo:
		pantalla.append(a_pantalla(p))
	var ancho := maxf(5.0 * zoom, 2.0)
	# Con un cable seleccionado, los demás se atenúan para poder seguirlo.
	var alfa := ALFA_ATENUADO if cable_marcado >= 0 and i != cable_marcado else 1.0
	var base := mesa.color_cable(i)
	# Sombra sobre la placa, borde oscuro, color y brillo: el cable se ve redondo.
	draw_polyline(_desplazar(pantalla, Vector2(1.5, 3.0) * clampf(zoom, 0.4, 1.2)), Color(0.0, 0.0, 0.0, 0.35 * alfa), ancho + 3.0, true)
	if i == cable_marcado:
		draw_polyline(pantalla, Color(Tema.ACENTO, 0.6), ancho + 8.0, true)
	draw_polyline(pantalla, Color(base.darkened(0.6), alfa), ancho + maxf(1.6 * zoom, 1.0), true)
	draw_polyline(pantalla, Color(base, alfa), ancho, true)
	if ancho >= 3.0:
		draw_polyline(_desplazar(pantalla, Vector2(-0.18, -0.24) * ancho), Color(base.lightened(0.45), 0.9 * alfa), ancho * 0.35, true)
		draw_polyline(_desplazar(pantalla, Vector2(-0.22, -0.3) * ancho), Color(1.0, 1.0, 1.0, 0.5 * alfa), maxf(ancho * 0.12, 1.0), true)
	for extremo in 2:
		_dibujar_puntera(i, puntos if extremo == 0 else _al_reves(puntos), extremo, alfa)


## Puntera de un extremo del cable: tubo metálico desde el borne y cuello de color donde entra
## el aislante. Con dos cables en el mismo borne, puntera doble (más ancha).
func _dibujar_puntera(i: int, lista: PackedVector2Array, extremo: int, alfa: float) -> void:
	var nodo: String = mesa.sim.cables[i][extremo]
	var p0 := lista[0]
	var dir := _punto_a_distancia(lista, RECORTE_CABLE) - p0
	dir = dir.normalized() if dir.length() > 0.01 else mesa.salida_borne(nodo)
	var doble: bool = _por_borne.get(nodo, 0) >= 2
	var w := ANCHO_PUNTERA * (1.9 if doble else 1.0)
	var cw := ANCHO_CUELLO * (1.8 if doble else 1.0)
	var cuello := COLOR_CUELLO_POTENCIA if mesa.cable_de_potencia(i) else COLOR_CUELLO_MANDO
	draw_set_transform(a_pantalla(p0), dir.angle() - PI / 2.0, Vector2(zoom, zoom))
	draw_rect(Rect2(-w / 2.0, 0.0, w, PUNTERA), Color(METAL, alfa))
	draw_rect(Rect2(-w / 2.0, 0.0, w * 0.35, PUNTERA), Color(1.0, 1.0, 1.0, 0.4 * alfa))
	draw_rect(Rect2(w / 4.0, 0.0, w / 4.0, PUNTERA), Color(0.0, 0.0, 0.0, 0.25 * alfa))
	for k in 3:
		var y := 5.0 + k * 3.0
		draw_line(Vector2(-w / 2.0, y), Vector2(w / 2.0, y), Color(0.35, 0.38, 0.4, alfa), 0.7)
	var forma := PackedVector2Array([Vector2(-cw / 2.0 + 0.8, PUNTERA), Vector2(cw / 2.0 - 0.8, PUNTERA),
			Vector2(cw / 2.0, PUNTERA + CUELLO), Vector2(-cw / 2.0, PUNTERA + CUELLO)])
	draw_colored_polygon(forma, Color(cuello, alfa))
	forma.append(forma[0])
	draw_polyline(forma, Color(0.08, 0.09, 0.11, alfa), 0.8, true)
	draw_rect(Rect2(-cw / 2.0 + 1.3, PUNTERA + 1.0, 1.6, CUELLO - 2.0), Color(1.0, 1.0, 1.0, 0.3 * alfa))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Recorrido dibujado del cable: el del modelo y, en los ordenados, con las esquinas redondeadas
## (o un desvío suave en S cuando los dos bornes casi están alineados).
func trazado_cable(i: int) -> PackedVector2Array:
	var p := mesa.puntos_cable(i)
	if p.size() != 4 or mesa.ruta_cable(i)["estilo"] != "angulos":
		return p
	var y := p[1].y
	var baja := signf(y - p[0].y)
	var sube := signf(p[3].y - y)
	if absf(p[3].x - p[0].x) < 2.0 * RADIO_ESQUINA + 4.0 and baja == sube and baja != 0.0:
		var t := minf(TRAMO_S, minf(absf(y - p[0].y), absf(p[3].y - y)))
		var e1 := Vector2(p[0].x, y - baja * t)
		var e2 := Vector2(p[3].x, y + sube * t)
		var r := PackedVector2Array([p[0]])
		for k in 9:
			r.append(_cubica(e1, Vector2(p[0].x, y), Vector2(p[3].x, y), e2, k / 8.0))
		r.append(p[3])
		return r
	return redondear(p, RADIO_ESQUINA)


static func redondear(p: PackedVector2Array, radio: float) -> PackedVector2Array:
	var r := PackedVector2Array([p[0]])
	for k in range(1, p.size() - 1):
		var esquina := p[k]
		var rr := minf(radio, minf(esquina.distance_to(p[k - 1]), esquina.distance_to(p[k + 1])) / 2.0)
		if rr < 0.5:
			r.append(esquina)
			continue
		var e1 := esquina + (p[k - 1] - esquina).normalized() * rr
		var e2 := esquina + (p[k + 1] - esquina).normalized() * rr
		for n in 7:
			var t := n / 6.0
			r.append(e1.lerp(esquina, t).lerp(esquina.lerp(e2, t), t))
	r.append(p[-1])
	return r


static func _cubica(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return a * u * u * u + c1 * 3.0 * u * u * t + c2 * 3.0 * u * t * t + b * t * t * t


static func _desplazar(puntos: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for p in puntos:
		r.append(p + d)
	return r


static func _largo(puntos: PackedVector2Array) -> float:
	var total := 0.0
	for k in puntos.size() - 1:
		total += puntos[k].distance_to(puntos[k + 1])
	return total


## La polilínea sin sus primeras y últimas «d» unidades: ahí van las punteras.
static func _recortar(puntos: PackedVector2Array, d: float) -> PackedVector2Array:
	if d <= 0.0 or puntos.size() < 2:
		return puntos
	return _al_reves(_quitar_inicio(_al_reves(_quitar_inicio(puntos, d)), d))


static func _quitar_inicio(puntos: PackedVector2Array, d: float) -> PackedVector2Array:
	var resto := d
	for k in puntos.size() - 1:
		var tramo := puntos[k].distance_to(puntos[k + 1])
		if resto < tramo:
			var r := PackedVector2Array([puntos[k].lerp(puntos[k + 1], resto / tramo)])
			r.append_array(puntos.slice(k + 1))
			return r
		resto -= tramo
	return PackedVector2Array([puntos[-1], puntos[-1]])


func _contar_por_borne() -> void:
	_por_borne = {}
	for c: Array in mesa.sim.cables:
		for nodo: String in c:
			_por_borne[nodo] = _por_borne.get(nodo, 0) + 1


## Los dos manguitos de un cable, pasada la puntera, girados a lo largo del cable y con su
## número de hilo. Los del hilo tocado (todos sus cables) van en ámbar; los demás se atenúan.
func _dibujar_marcadores(i: int) -> void:
	var puntos := trazado_cable(i)
	if puntos.size() < 2:
		return
	var marcado := i == cable_marcado or (cable_marcado >= 0 and cable_marcado < mesa.sim.cables.size() and mesa.numero_hilo(i) == mesa.numero_hilo(cable_marcado))
	var alfa := ALFA_ATENUADO if cable_marcado >= 0 and not marcado else 1.0
	var fuente := get_theme_default_font()
	var t := int(clampf(9.0 * zoom, 8.0, 13.0))
	for extremo in 2:
		var lista := puntos if extremo == 0 else _al_reves(puntos)
		var texto := mesa.marcador(i, extremo)
		var w := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x + 8.0
		var d := maxf(DISTANCIA_MARCADOR, RECORTE_CABLE + (w / 2.0 + 3.0) / zoom)
		var p := _punto_a_distancia(lista, d)
		var tangente := _punto_a_distancia(lista, d + 4.0) - _punto_a_distancia(lista, d - 4.0)
		var angulo := tangente.angle() if tangente.length() > 0.01 else 0.0
		# Que el número se lea de izquierda a derecha, o de arriba abajo en los tramos verticales.
		if cos(angulo) < -0.05 or (absf(cos(angulo)) <= 0.05 and sin(angulo) < 0.0):
			angulo += PI
		draw_set_transform(a_pantalla(p), angulo, Vector2.ONE)
		var r := Rect2(Vector2(-w / 2.0, -t * 0.75), Vector2(w, t * 1.5))
		if marcado:
			draw_rect(r.grow(3.0), Color(1.0, 0.69, 0.0, 0.45))
		draw_rect(Rect2(r.position + Vector2(0, 1.5), r.size), Color(0, 0, 0, 0.45 * alfa))
		draw_rect(r, Color("ffd26a") if marcado else Color(0.95, 0.95, 0.91, alfa))
		draw_line(r.position + Vector2(1.5, 1.0), Vector2(r.position.x + 1.5, r.end.y - 1.0), Color(0.6, 0.61, 0.57, alfa), 1.0)
		draw_line(Vector2(r.end.x - 1.5, r.position.y + 1.0), r.end - Vector2(1.5, 1.0), Color(0.6, 0.61, 0.57, alfa), 1.0)
		draw_rect(r, Color(0.29, 0.3, 0.27, alfa), false, 1.0)
		draw_string(fuente, Vector2(r.position.x + 4.0, t * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, Color(0.08, 0.09, 0.11, alfa))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _al_reves(puntos: PackedVector2Array) -> PackedVector2Array:
	var r := PackedVector2Array()
	for k in range(puntos.size() - 1, -1, -1):
		r.append(puntos[k])
	return r


## El punto de la polilínea a «d» unidades de mesa de su inicio (o su mitad, si es más corta).
static func _punto_a_distancia(puntos: PackedVector2Array, d: float) -> Vector2:
	var total := 0.0
	for k in puntos.size() - 1:
		total += puntos[k].distance_to(puntos[k + 1])
	var objetivo := minf(d, total * 0.35)
	for k in puntos.size() - 1:
		var tramo := puntos[k].distance_to(puntos[k + 1])
		if objetivo <= tramo and tramo > 0.0:
			return puntos[k].lerp(puntos[k + 1], objetivo / tramo)
		objetivo -= tramo
	return puntos[-1]


## Bornes: con cable, la silleta de apriete sobre las punteras y el tornillo encima; libres, el
## tornillo suelto y un aro ámbar discontinuo que invita a cablear.
func _dibujar_bornes(id: String) -> void:
	for b: String in mesa.bornes(id):
		var nodo := "%s.%s" % [id, b]
		var p := a_pantalla(mesa.posicion_borne(nodo))
		var conectado: bool = _por_borne.get(nodo, 0) > 0
		var radio := maxf(RADIO_TORNILLO * zoom, 3.0)
		if nodo == borne_marcado:
			draw_circle(p, maxf(RADIO_BORNE_LIBRE * zoom, 7.0) + 4.0, Tema.ACENTO)
		if conectado:
			var lado := LADO_SILLETA * zoom
			var r := Rect2(p - lado / 2.0, lado)
			draw_rect(Rect2(r.position + Vector2(1.0, 2.0), r.size), Color(0.0, 0.0, 0.0, 0.4))
			draw_rect(r, Color("9aa3a9"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.45)), Color("dfe4e7"))
			draw_rect(r, Color("3a4248"), false, maxf(0.8 * zoom, 1.0))
		else:
			var anillo := maxf(RADIO_BORNE_LIBRE * zoom, 7.0)
			for k in 12:
				var desde := k * TAU / 12.0
				draw_arc(p, anillo, desde, desde + TAU / 20.0, 4, Color(Tema.ACENTO, 0.85 if zoom >= ZOOM_ETIQUETAS else 0.5), maxf(1.8 * zoom, 1.5), true)
			draw_circle(p + Vector2(1.0, 2.0) * maxf(zoom, 0.5), radio + 1.5, Color(0.0, 0.0, 0.0, 0.45))
		_tornillo(p, radio)


## Tornillo combinado (ranura y pozidriv) niquelado, visto de frente.
func _tornillo(p: Vector2, r: float) -> void:
	draw_circle(p, r + maxf(zoom, 0.8), Color("2a3036"))
	draw_circle(p, r, Color("8d969c"))
	draw_circle(p + Vector2(-0.12, -0.12) * r, r * 0.78, Color("c3cacf"))
	draw_circle(p + Vector2(-0.22, -0.24) * r, r * 0.45, Color("e4e8eb"))
	var k := r * 0.62
	var oscuro := Color("3a4146")
	draw_line(p - Vector2(k, 0.0), p + Vector2(k, 0.0), oscuro, maxf(r * 0.26, 1.0), true)
	draw_line(p - Vector2(0.0, k), p + Vector2(0.0, k), oscuro, maxf(r * 0.26, 1.0), true)
	if r >= 5.0:
		var q := r * 0.3
		draw_line(p + Vector2(-q, -q), p + Vector2(q, q), Color("4f575d"), maxf(r * 0.1, 0.8), true)
		draw_line(p + Vector2(-q, q), p + Vector2(q, -q), Color("4f575d"), maxf(r * 0.1, 0.8), true)
	draw_circle(p + Vector2(-0.38, -0.45) * r, r * 0.16, Color(1.0, 1.0, 1.0, 0.8))


func _dibujar_punta(nodo: String, color: Color) -> void:
	if nodo.is_empty() or not mesa.piezas.has(nodo.get_slice(".", 0)):
		return
	var p := a_pantalla(mesa.posicion_borne(nodo))
	draw_circle(p, 10.0, color)
	draw_arc(p, 10.0, 0.0, TAU, 24, Color.WHITE, 2.0, true)
