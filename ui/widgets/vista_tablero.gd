class_name VistaTablero
extends Control
## Frente de un tablero del buque, dibujado como se ve a bordo: placa de acero inoxidable o
## pintada, rótulos, luces piloto, pulsadores, selectores, setas, interruptor general y horómetros.
## Cada elemento lee su componente de la simulación. Al tocar uno se emite elemento_tocado con el
## lado (-1 izquierda, +1 derecha), para girar los selectores, y al soltar, elemento_soltado.

signal elemento_tocado(indice: int, lado: int)
signal elemento_soltado(indice: int)

## Radio de toque mínimo en píxeles: un dedo necesita unos 48 px de diámetro.
const RADIO_TOQUE_PX := 26.0
const RADIO_TOQUE := 62.0
const TIPOS_ACTIVOS := ["pulsador", "selector", "seta", "seccionador"]
const COLORES_LUZ := {
	"verde": [Color("12301d"), Color("54ff8a")],
	"rojo": [Color("3a1212"), Color("ff4a3a")],
	"ambar": [Color("3d2a0c"), Color("ffbf3a")],
	"blanco": [Color("4a4c4e"), Color("fffbea")],
	"azul": [Color("102438"), Color("4ab4ff")],
}
const ACABADOS := {
	"inox": [Color("c3c8cb"), Color("a9afb3"), Color("7d8488")],
	"gris": [Color("c9cbc6"), Color("b9bbb6"), Color("8c8e8a")],
	"blanco": [Color("e6e4dc"), Color("d8d6ce"), Color("a6a49c")],
}

const ZOOM_MAXIMO := 4.0
const TAM_BASE := 16

var datos := {}
var sim: SimSimulacion
## 1 encaja el tablero entero; más, lo amplía. desplazamiento mueve la vista en píxeles.
var zoom := 1.0
var desplazamiento := Vector2.ZERO
var _activo := -1
var _arrastrando := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(240.0, 240.0)


func elementos() -> Array:
	return datos.get("elementos", [])


func _tamano_panel() -> Vector2:
	var t: Array = datos.get("tamano", [1000, 1000])
	return Vector2(float(t[0]), float(t[1]))


func escala() -> float:
	var t := _tamano_panel()
	return minf(size.x / t.x, size.y / t.y) * zoom


func _origen() -> Vector2:
	return (size - _tamano_panel() * escala()) / 2.0 + desplazamiento


## Amplía o reduce manteniendo quieto el punto de pantalla indicado.
func cambiar_zoom(factor: float, punto: Vector2) -> void:
	var antes := a_panel(punto)
	zoom = clampf(zoom * factor, 1.0, ZOOM_MAXIMO)
	desplazamiento += punto - a_pantalla(antes)
	_limitar()
	queue_redraw()


func encuadrar() -> void:
	zoom = 1.0
	desplazamiento = Vector2.ZERO
	queue_redraw()


## Sin zoom el tablero queda centrado; ampliado, no se puede sacar del todo de la vista.
func _limitar() -> void:
	if zoom <= 1.0:
		desplazamiento = Vector2.ZERO
		return
	var medida := _tamano_panel() * escala()
	var holgura := (medida - size).max(Vector2.ZERO) / 2.0
	desplazamiento = desplazamiento.clamp(-holgura, holgura)


func a_pantalla(p: Vector2) -> Vector2:
	return _origen() + p * escala()


func a_panel(p: Vector2) -> Vector2:
	return (p - _origen()) / escala()


func centro(indice: int) -> Vector2:
	var e: Dictionary = elementos()[indice]
	return Vector2(float(e["x"]), float(e["y"]))


## Elemento activo bajo el punto de pantalla, o -1. El radio nunca baja del tamaño de un dedo.
func elemento_en(punto: Vector2) -> int:
	var p := a_panel(punto)
	var radio := maxf(RADIO_TOQUE, RADIO_TOQUE_PX / escala())
	var mejor := -1
	var distancia := radio
	for i in elementos().size():
		var e: Dictionary = elementos()[i]
		if not TIPOS_ACTIVOS.has(e["tipo"]) or str(e.get("componente", "")).is_empty():
			continue
		var d := p.distance_to(centro(i))
		if d <= distancia:
			distancia = d
			mejor = i
	return mejor


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP and evento.pressed:
			cambiar_zoom(1.15, evento.position)
			accept_event()
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN and evento.pressed:
			cambiar_zoom(1.0 / 1.15, evento.position)
			accept_event()
		elif evento.button_index == MOUSE_BUTTON_LEFT:
			if evento.pressed:
				_activo = elemento_en(evento.position)
				if _activo >= 0:
					var lado := -1 if a_panel(evento.position).x < centro(_activo).x else 1
					elemento_tocado.emit(_activo, lado)
				else:
					# Fuera de los mandos, arrastrar mueve la vista ampliada.
					_arrastrando = true
				accept_event()
			else:
				if _activo >= 0:
					elemento_soltado.emit(_activo)
					_activo = -1
				_arrastrando = false
				accept_event()
	elif evento is InputEventMouseMotion and _arrastrando:
		desplazamiento += evento.relative
		_limitar()
		queue_redraw()
		accept_event()
	elif evento is InputEventMagnifyGesture:
		cambiar_zoom(evento.factor, evento.position)
		accept_event()
	elif evento is InputEventPanGesture:
		desplazamiento -= evento.delta * 8.0
		_limitar()
		queue_redraw()
		accept_event()


func _notification(que: int) -> void:
	# Si el dedo sale de la pantalla sin soltar, el pulsador vuelve a reposo.
	if que == NOTIFICATION_MOUSE_EXIT and _activo >= 0:
		elemento_soltado.emit(_activo)
		_activo = -1
	if que == NOTIFICATION_RESIZED:
		_limitar()


# --- Lecturas de la simulación ---

func _componente(e: Dictionary) -> SimComponente:
	var id: String = str(e.get("componente", ""))
	if sim == null or id.is_empty() or not sim.componentes.has(id):
		return null
	return sim.componente(id)


## Brillo de 0 a 1 de una lámpara de la simulación. Las de tierra se comparan por su tensión.
func brillo(id: String) -> float:
	if sim == null or id.is_empty() or not sim.componentes.has(id):
		return 0.0
	var c := sim.componente(id)
	if c.estado.get("quemada", false):
		return 0.0
	var r: float = c.estado.get("relacion", 1.0 if c.estado.get("encendida", false) else 0.0)
	return clampf(r, 0.0, 1.0) if r >= 0.15 else 0.0


# --- Dibujo ---

func _draw() -> void:
	var t := _tamano_panel()
	var s := escala()
	var o := _origen()
	var colores: Array = ACABADOS.get(datos.get("acabado", "inox"), ACABADOS["inox"])
	# Sombra, chapa y bordes doblados.
	draw_rect(Rect2(o + Vector2(6, 8) * s, t * s), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(o, t * s), colores[2])
	var interior := Rect2(o + Vector2(14, 14) * s, (t - Vector2(28, 28)) * s)
	draw_rect(interior, colores[0])
	if datos.get("acabado", "inox") == "inox":
		# Cepillado del acero: rayas finas verticales con un ruido fijo.
		var semilla := 7
		var x := 18.0
		while x < t.x - 18.0:
			semilla = (semilla * 1103515245 + 12345) % 2147483648
			var tono: float = float(semilla % 100) / 100.0
			var c: Color = colores[1].lerp(colores[0], tono)
			c.a = 0.55
			draw_line(o + Vector2(x, 16) * s, o + Vector2(x, t.y - 16) * s, c, maxf(1.0, 2.0 * s))
			x += 5.0 + float(semilla % 7)
		draw_rect(Rect2(o + Vector2(14, 14) * s, Vector2(t.x - 28, t.y * 0.18) * s), Color(1, 1, 1, 0.08))
	# Bisagras a la izquierda y tornillos en las esquinas.
	for y in [0.18, 0.82]:
		draw_rect(Rect2(o + Vector2(-8, t.y * y - 40) * s, Vector2(16, 80) * s), Color("6c7276"))
	for p: Vector2 in [Vector2(34, 34), Vector2(t.x - 34, 34), Vector2(34, t.y - 34), Vector2(t.x - 34, t.y - 34)]:
		_tornillo(o + p * s, 9.0 * s)
	for i in elementos().size():
		var e: Dictionary = elementos()[i]
		var c := a_pantalla(centro(i))
		match e["tipo"]:
			"recuadro":
				var medida := Vector2(float(e["ancho"]), float(e["alto"])) * s
				draw_rect(Rect2(c - medida / 2.0, medida), Color(str(e.get("color", "#1b1d1f"))))
			"rotulo":
				_rotulo(c, str(e["texto"]), float(e.get("tam", 16)) * s, Color(str(e.get("fondo", "#f4f4f0"))), Color(str(e.get("tinta", "#15171a"))))
			"luz":
				_luz(c, s, str(e.get("color", "verde")), brillo(str(e.get("componente", ""))), str(e.get("estilo", "plana")))
				if e.has("texto"):
					# Rótulo grabado en la lente, como RUN PUMP o HEATING ON.
					var lineas := str(e["texto"]).split("\n")
					for j in lineas.size():
						_texto(c + Vector2(-26.0, (-4.0 + 12.0 * j) * (1.0 if lineas.size() > 1 else 0.0) + 4.0) * s, lineas[j], 9.0 * s, Color(0, 0, 0, 0.55), 52.0 * s, HORIZONTAL_ALIGNMENT_CENTER)
			"pantalla_vlt":
				_pantalla_vlt(c, s, e)
			"pulsador":
				var comp := _componente(e)
				var pulsado: bool = comp != null and comp.estado.get("presionado", false)
				var luz := brillo(str(e.get("luz", "")))
				_pulsador(c, s, str(e.get("color", "verde")), pulsado, luz, e.has("luz"))
			"selector":
				_selector(c, s, _componente(e) as SimSelector, str(e.get("color", "negro")))
			"seta":
				var comp := _componente(e)
				_seta(c, s, comp != null and comp.estado.get("enclavada", false))
			"seccionador":
				var comp := _componente(e)
				_seccionador(c, s, comp != null and comp.estado.get("cerrado", false), comp != null and comp.estado.get("candado", false), str(e.get("estilo", "rojo")))
			"horometro":
				var comp := _componente(e)
				_horometro(c, s, float(comp.estado.get("horas", 0.0)) if comp != null else 0.0)
			"amperimetro":
				_amperimetro(c, s, e)
			"cerradura":
				_cerradura(c, s)


func _fuente() -> Font:
	return get_theme_default_font()


## Texto escalado como el resto del tablero: se dibuja a un tamaño base y se reduce con la
## transformación, así conserva su proporción aunque mida pocos píxeles.
func _texto(pos: Vector2, texto: String, tam: float, color: Color, ancho := -1.0, alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var k := maxf(tam, 0.5) / float(TAM_BASE)
	# Se centra a mano: si la caja es más estrecha que el texto, draw_string no lo dibujaría.
	if alineacion == HORIZONTAL_ALIGNMENT_CENTER and ancho > 0.0:
		pos.x += (ancho - _ancho_texto(texto, tam)) / 2.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	draw_string(_fuente(), pos / k, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TAM_BASE, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ancho_texto(texto: String, tam: float) -> float:
	return _fuente().get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_BASE).x * tam / float(TAM_BASE)


func _tornillo(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color("2c2f31"))
	draw_circle(c, r * 0.85, Color("a7acaf"))
	draw_line(c - Vector2(r * 0.55, 0), c + Vector2(r * 0.55, 0), Color("3a3e41"), maxf(1.0, r * 0.25))
	draw_line(c - Vector2(0, r * 0.55), c + Vector2(0, r * 0.55), Color("3a3e41"), maxf(1.0, r * 0.25))


## Placa blanca de rótulo con letras negras, centrada en c.
func _rotulo(c: Vector2, texto: String, tam: float, fondo := Color("f4f4f0"), tinta := Color("15171a")) -> void:
	var fuente := _fuente()
	var lineas := texto.split("\n")
	var ancho := 0.0
	for l: String in lineas:
		ancho = maxf(ancho, _ancho_texto(l, tam))
	var k := tam / float(TAM_BASE)
	var alto_linea := fuente.get_height(TAM_BASE) * k
	var caja := Vector2(ancho + tam * 0.8, alto_linea * lineas.size() + tam * 0.3)
	var r := Rect2(c - caja / 2.0, caja)
	draw_rect(Rect2(r.position + Vector2(1, 2), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, fondo)
	draw_rect(r, Color("2a2c2e"), false, maxf(1.0, tam * 0.06))
	for j in lineas.size():
		var y := r.position.y + tam * 0.15 + alto_linea * j + fuente.get_ascent(TAM_BASE) * k
		_texto(Vector2(r.position.x, y), lineas[j], tam, tinta, caja.x, HORIZONTAL_ALIGNMENT_CENTER)


func _bisel(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(r * 0.06, r * 0.1), r * 1.04, Color(0, 0, 0, 0.3))
	draw_circle(c, r, Color("8d9396"))
	draw_circle(c, r * 0.92, Color("dfe3e5"))
	draw_circle(c + Vector2(r * 0.06, r * 0.06), r * 0.86, Color("9aa0a3"))


func _colores_luz(nombre: String) -> Array:
	return COLORES_LUZ.get(nombre, COLORES_LUZ["verde"])


func _luz(c: Vector2, s: float, color: String, luz: float, estilo: String) -> void:
	var r := 36.0 * s
	var cs := _colores_luz(color)
	if luz > 0.0:
		var halo: Color = cs[1]
		halo.a = 0.28 * luz
		draw_circle(c, r * (1.25 + 0.35 * luz), halo)
	_bisel(c, r)
	var lente: Color = cs[0].lerp(cs[1], luz)
	draw_circle(c, r * 0.74, lente.darkened(0.25))
	draw_circle(c - Vector2(r, r) * 0.04, r * (0.66 if estilo == "domo" else 0.7), lente)
	if estilo == "domo":
		draw_circle(c - Vector2(r, r) * 0.18, r * 0.3, lente.lightened(0.25))
	draw_circle(c - Vector2(r, r) * 0.3, r * 0.14, Color(1, 1, 1, 0.25 + 0.45 * luz))


func _pulsador(c: Vector2, s: float, color: String, pulsado: bool, luz: float, luminoso: bool) -> void:
	var r := 36.0 * s
	var cs := _colores_luz(color)
	if luminoso and luz > 0.0:
		var halo: Color = cs[1]
		halo.a = 0.25 * luz
		draw_circle(c, r * (1.2 + 0.3 * luz), halo)
	_bisel(c, r)
	var base: Color = cs[0].lerp(cs[1], 0.55)
	if luminoso:
		base = cs[0].lerp(cs[1], 0.35 + 0.65 * luz)
	var hundido := 0.04 if pulsado else 0.0
	var cuerpo := r * (0.72 - hundido)
	draw_circle(c, cuerpo, base.darkened(0.35 + hundido * 4.0))
	draw_circle(c - Vector2(r, r) * 0.03, cuerpo * 0.9, base.darkened(hundido * 4.0))
	draw_arc(c, cuerpo * 0.9, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.35), maxf(1.0, r * 0.08))


func _selector(c: Vector2, s: float, sel: SimSelector, color: String) -> void:
	var r := 36.0 * s
	_bisel(c, r)
	var cuerpo := Color("1c6b35") if color == "verde" else Color("1b1d1f")
	draw_circle(c, r * 0.74, cuerpo.darkened(0.3))
	draw_circle(c, r * 0.68, cuerpo)
	var n := 2
	var posicion := 0
	if sel != null:
		n = sel.posiciones().size()
		posicion = sel.estado["posicion"]
	# Posiciones repartidas entre -45° y +45° respecto a la vertical.
	var angulo := 0.0 if n <= 1 else deg_to_rad(-45.0 + 90.0 * float(posicion) / float(n - 1))
	var eje := Vector2(sin(angulo), -cos(angulo))
	var normal := Vector2(eje.y, -eje.x)
	var largo := r * 0.62
	var ancho := r * 0.2
	var puntos := PackedVector2Array([c + eje * largo + normal * ancho, c + eje * largo - normal * ancho,
		c - eje * largo - normal * ancho, c - eje * largo + normal * ancho])
	draw_colored_polygon(puntos, cuerpo.lightened(0.15))
	draw_polyline(puntos + PackedVector2Array([puntos[0]]), cuerpo.darkened(0.5), maxf(1.0, r * 0.05))
	draw_line(c + eje * largo * 0.35, c + eje * largo * 0.9, Color("f2f2ee"), maxf(1.5, r * 0.1))
	for i in n:
		var a := 0.0 if n <= 1 else deg_to_rad(-45.0 + 90.0 * float(i) / float(n - 1))
		var d := Vector2(sin(a), -cos(a))
		draw_line(c + d * r * 1.05, c + d * r * 1.2, Color("2a2c2e"), maxf(1.0, r * 0.06))


func _seta(c: Vector2, s: float, enclavada: bool) -> void:
	var r := 46.0 * s
	draw_circle(c, r * 1.25, Color("d8a91c"))
	draw_circle(c, r * 1.15, Color("f2c932"))
	draw_circle(c + Vector2(0, r * 0.08), r * (0.86 if enclavada else 0.92), Color("5e100a"))
	draw_circle(c, r * (0.8 if enclavada else 0.86), Color("c62a1e"))
	draw_circle(c - Vector2(r, r) * 0.22, r * 0.25, Color(1, 1, 1, 0.22))
	if enclavada:
		_texto(c + Vector2(-r * 1.2, r * 1.6), "ENCLAVADA", r * 0.32, Color("15171a"), r * 2.4, HORIZONTAL_ALIGNMENT_CENTER)


func _seccionador(c: Vector2, s: float, cerrado: bool, candado: bool, estilo := "rojo") -> void:
	var lado := 120.0 * s
	if estilo == "negro":
		_seccionador_negro(c, s, cerrado, candado)
		return
	var r := Rect2(c - Vector2(lado, lado) / 2.0, Vector2(lado, lado))
	draw_rect(Rect2(r.position + Vector2(3, 4) * s, r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, Color("e8bf27"))
	draw_rect(r, Color("8a6a08"), false, maxf(1.0, 3.0 * s))
	var tam := 16.0 * s
	_texto(r.position + Vector2(6 * s, 22 * s), "0 OFF", tam, Color("15171a"))
	_texto(r.position + Vector2(lado * 0.58, 22 * s), "I ON", tam, Color("15171a"))
	draw_circle(c, lado * 0.36, Color("7a0f08"))
	draw_circle(c, lado * 0.33, Color("c62a1e"))
	# Mango: horizontal en 0-OFF, vertical en I-ON.
	var eje := Vector2(0, -1) if cerrado else Vector2(1, 0)
	var normal := Vector2(eje.y, -eje.x)
	var puntos := PackedVector2Array([c + eje * lado * 0.46 + normal * lado * 0.08, c + eje * lado * 0.46 - normal * lado * 0.08,
		c - eje * lado * 0.46 - normal * lado * 0.08, c - eje * lado * 0.46 + normal * lado * 0.08])
	draw_colored_polygon(puntos, Color("b3221a"))
	draw_circle(c, lado * 0.06, Color("5e100a"))
	if candado:
		# Candado rojo de bloqueo con su tarjeta.
		var p := c + Vector2(lado * 0.36, lado * 0.3)
		draw_arc(p - Vector2(0, lado * 0.08), lado * 0.08, PI, TAU, 12, Color("5a5e61"), maxf(2.0, 5.0 * s))
		draw_rect(Rect2(p - Vector2(lado * 0.11, lado * 0.08), Vector2(lado * 0.22, lado * 0.18)), Color("d0281c"))
		draw_rect(Rect2(p + Vector2(lado * 0.14, -lado * 0.02), Vector2(lado * 0.3, lado * 0.42)), Color("f4f4f0"))
		_texto(p + Vector2(lado * 0.16, lado * 0.2), "NO", tam, Color("c62a1e"))


func _horometro(c: Vector2, s: float, horas: float) -> void:
	var caja := Vector2(170, 64) * s
	var r := Rect2(c - caja / 2.0, caja)
	draw_rect(r, Color("1b1d1f"))
	draw_rect(r, Color("8e9496"), false, maxf(1.0, 3.0 * s))
	var cifras := "%07d" % int(floor(horas * 10.0))
	var tam := 28.0 * s
	var ancho := caja.x * 0.84 / 7.0
	for i in 7:
		var celda := Rect2(r.position + Vector2(caja.x * 0.08 + ancho * i + 1, caja.y * 0.2), Vector2(ancho - 2, caja.y * 0.6))
		draw_rect(celda, Color("c8231a") if i == 6 else Color("f0f0ee"))
		# Centrado a mano: con un ancho de caja menor que la cifra, el texto no se dibujaría.
		var x := celda.get_center().x - _ancho_texto(cifras[i], tam) / 2.0
		_texto(Vector2(x, celda.position.y + celda.size.y * 0.8), cifras[i], tam, Color("f0f0ee") if i == 6 else Color("15171a"))
	_texto(r.position + Vector2(caja.x - 18 * s, caja.y - 4 * s), "h", 14.0 * s, Color("f0f0ee"))


## Amperímetro de cuadro de 240°, en marco DIN, con la línea roja desde la corriente nominal. Lee
## la corriente del arrancador suave o del relé térmico que indique el elemento.
func _amperimetro(c: Vector2, s: float, e: Dictionary) -> void:
	var lado := float(e.get("lado", 180.0)) * s
	var cara := DibujoInstrumentos.marco_cuadrado(self, Rect2(c - Vector2(lado, lado) / 2.0, Vector2(lado, lado)))
	var h := cara.size.y
	var centro := Vector2(cara.get_center().x, cara.position.y + h * 0.5)
	var radio := h * 0.4
	var fondo := float(e.get("fondo", 100.0))
	var tam := maxi(int(radio * 0.24), 6)
	DibujoInstrumentos.escala(self, _fuente(), centro, radio, 0.0, fondo, 240.0, float(e.get("nominal", INF)), DibujoInstrumentos.TINTA, tam)
	var t_unidad := maxi(int(h * 0.14), 7)
	var ancho := _fuente().get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, t_unidad).x
	draw_string(_fuente(), Vector2(centro.x - ancho / 2.0, cara.end.y - h * 0.1), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, t_unidad, DibujoInstrumentos.TINTA)
	var a := DibujoInstrumentos.angulo_escala(_corriente(e), 0.0, fondo, 240.0)
	DibujoInstrumentos.aguja(self, centro, a, radio * 0.98, Color("15171a"))
	DibujoInstrumentos.reflejo(self, cara.get_center(), h * 0.5)


func _corriente(e: Dictionary) -> float:
	var comp := _componente(e)
	if comp is SimArrancadorSuave:
		return (comp as SimArrancadorSuave).corriente()
	if comp is SimReleTermico and sim.solucion != null:
		return (comp as SimReleTermico).corriente(sim.solucion, 0)
	return 0.0


func _cerradura(c: Vector2, s: float) -> void:
	var r := 30.0 * s
	draw_circle(c, r, Color("1b1d1f"))
	draw_circle(c, r * 0.8, Color("9aa0a3"))
	draw_circle(c, r * 0.6, Color("50565a"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.2), c + Vector2(r * 0.25, -r * 0.2), c + Vector2(0, r * 0.3)]), Color("1b1d1f"))


## Interruptor general de mando negro, como el Schneider del servotimón: flecha blanca en el mango.
func _seccionador_negro(c: Vector2, s: float, cerrado: bool, candado: bool) -> void:
	var lado := 110.0 * s
	var r := Rect2(c - Vector2(lado, lado) / 2.0, Vector2(lado, lado))
	draw_rect(Rect2(r.position + Vector2(3, 4) * s, r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, Color("1b1d1f"))
	draw_circle(c, lado * 0.36, Color("2c2f31"))
	var eje := Vector2(0, -1) if cerrado else Vector2(-0.7, -0.7)
	var normal := Vector2(eje.y, -eje.x)
	var puntos := PackedVector2Array([c + eje * lado * 0.42 + normal * lado * 0.09, c + eje * lado * 0.42 - normal * lado * 0.09,
		c - eje * lado * 0.3 - normal * lado * 0.09, c - eje * lado * 0.3 + normal * lado * 0.09])
	draw_colored_polygon(puntos, Color("101112"))
	draw_line(c, c + eje * lado * 0.36, Color("f2f2ee"), maxf(1.5, 5.0 * s))
	_texto(r.position + Vector2(lado * 0.08, lado * 0.95), "0", 14.0 * s, Color("f2f2ee"))
	_texto(r.position + Vector2(lado * 0.46, lado * 0.16), "I", 14.0 * s, Color("f2f2ee"))
	if candado:
		draw_rect(Rect2(c + Vector2(lado * 0.2, lado * 0.15), Vector2(lado * 0.22, lado * 0.18)), Color("d0281c"))


## Teclado y pantalla de un variador Danfoss VLT, como los del servotimón. Lee el contactor que hace
## de variador, su motor y su horómetro.
func _pantalla_vlt(c: Vector2, s: float, e: Dictionary) -> void:
	var medida := Vector2(300, 330) * s
	var r := Rect2(c - medida / 2.0, medida)
	draw_rect(Rect2(r.position - Vector2(30, 40) * s, medida + Vector2(60, 70) * s), Color("aab0b4"))
	draw_rect(r, Color("2a2d30"))
	_rotulo(r.position + Vector2(medida.x / 2.0, 22 * s), "Danfoss", 14.0 * s, Color("c8231a"), Color("ffffff"))
	var pantalla := Rect2(r.position + Vector2(30, 44) * s, Vector2(240, 120) * s)
	var con_tension := sim != null and sim.componentes.has("Q0") and (sim.componente("Q0") as SimSeccionador).cerrado() \
		and str(sim.componente("Q0").params.get("polo_danado", "")).is_empty()
	draw_rect(pantalla, Color("ff9a2a") if con_tension else Color("3a2a1a"))
	if con_tension:
		var k := sim.componente(str(e.get("componente", ""))) if sim.componentes.has(str(e.get("componente", ""))) else null
		var m: SimMotorTrifasico = sim.componente(str(e.get("motor", ""))) if sim.componentes.has(str(e.get("motor", ""))) else null
		var p := sim.componente(str(e.get("horometro", ""))) if sim.componentes.has(str(e.get("horometro", ""))) else null
		var horas := int(p.estado["horas"]) if p != null else 0
		var lineas: Array[String] = []
		if k != null and (k as SimContactor).cerrado() and m != null and absf(m.rpm()) > 100.0:
			var hz := 50.0 * absf(m.rpm()) / float(m.params["rpm"])
			var amperios := m.corriente_devanado(0) * sqrt(3.0)
			lineas = ["Status", "%.1fHz        %.2fkW" % [hz, float(m.params["p_kw"]) * 0.6], "%dh" % horas, "%.2fA" % amperios, "Auto Remote Running"]
		else:
			lineas = ["Status", "0.0Hz -0.014  0.06kW", "%dh" % horas, "7.49A", "Auto Remote DC Stop"]
		for j in lineas.size():
			var tam := 15.0 * s if j in [2, 3] else 11.0 * s
			_texto(pantalla.position + Vector2(6 * s, (20 + 23 * j) * s), lineas[j], tam, Color("3a1a00"), pantalla.size.x - 12 * s, HORIZONTAL_ALIGNMENT_CENTER if j in [2, 3] else HORIZONTAL_ALIGNMENT_LEFT)
	var teclas := ["Status", "Quick", "Main", "Alarm"]
	for j in 4:
		var tecla := Rect2(r.position + Vector2(24 + 66 * j, 178) * s, Vector2(56, 30) * s)
		draw_rect(tecla, Color("c9ccce"))
		_texto(tecla.position + Vector2(0, 20 * s), teclas[j], 10.0 * s, Color("15171a"), tecla.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	draw_circle(r.position + Vector2(150, 250) * s, 34 * s, Color("c9ccce"))
	draw_circle(r.position + Vector2(150, 250) * s, 14 * s, Color("e3e5e6"))
	var abajo := ["Hand On", "Off", "Auto On", "Reset"]
	for j in 4:
		var centro_tecla := r.position + Vector2(48 + 68 * j, 308) * s
		draw_circle(centro_tecla, 16 * s, Color("c9ccce"))
		_texto(centro_tecla + Vector2(-20 * s, 4 * s), abajo[j], 8.0 * s, Color("15171a"), 40 * s, HORIZONTAL_ALIGNMENT_CENTER)
	if con_tension:
		draw_circle(r.position + Vector2(48 + 68 * 2, 288) * s, 3 * s, Color("ffb020"))
