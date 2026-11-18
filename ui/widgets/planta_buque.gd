class_name PlantaBuque
extends ControlToque
## Buque visto desde arriba, el menú del inicio. Cada sistema es una zona del color de su área
## con su icono, su nombre y una lámpara de estado; la seguridad va aparte, como una medalla en
## el agua. En apaisado la proa queda a la derecha y en vertical, arriba.
##
## Las zonas vienen de data/sistemas.json («planta») en el espacio del buque: «u» de popa (0) a
## proa (1000) y «v» de babor (0) a estribor (300). El casco y los detalles se dibujan aquí.
##
## En la pantalla «Buque», la capa «tableros» deja las zonas como un tinte sin rótulos y pone una
## marca en cada lugar con paneles (data/sistemas.json, «planta.lugares»): una chapa ámbar con el
## rayo, el número de paneles y una lámpara roja si alguno tiene una avería pendiente.

signal sistema_tocado(id: int)
signal lugar_tocado(indice: int)

## Media manga del casco en el espacio del buque y su eje.
const MEDIA_MANGA := 128.0
const EJE := 150.0
const POPA := 30.0
const PROA := 988.0
const ARRANQUE_PROA := 640.0
## Mitad del área táctil mínima de 48 puntos.
const RADIO_TOQUE := 24.0
## Proporción máxima entre la escala de la manga y la de la eslora: el dibujo es esquemático,
## más ancho que el buque real para que quepan los nombres.
const ENSANCHE_MAX_APAISADO := 1.7
const ENSANCHE_MAX_VERTICAL := 2.6
const MARGEN := 12.0
const ALTO_LEYENDA := 22.0
const RADIO_MEDALLA := 22.0

const CASCO := [Color("e9eef2"), Color("9aa6b1"), Color("5d6a76"), Color("2c353e")]
const CUBIERTA := [Color("4b5966"), Color("3a4652"), Color("2b343e")]
const TECHO := [Color("f4f6f7"), Color("cfd6dc"), Color("97a3ad")]
const MAR := Color("0f2a3d")
const MAR_FONDO := Color("081a28")
const MAR_BORDE := Color("22394b")
const RED := Color("3d4a3a")
const HILO_RED := Color(0.49, 0.56, 0.47, 0.7)
const ESCARCHA := [Color(0.85, 0.96, 1.0, 0.6), Color(0.5, 0.83, 0.92, 0.55), Color(0.12, 0.44, 0.53, 0.6)]
const PARRILLA := Color("232d36")
const PARRILLA_HUECO := Color("10161b")
const AMARILLO_PLUMA := Color("e8bf27")
const PASTILLA := Color(0.05, 0.075, 0.094, 0.88)
## Medio lado de la marca de un lugar con tableros.
const MEDIO_MARCA := 15.0
const AMBAR_MARCA := [Color("ffd978"), Color("e8a524"), Color("a86a00")]

## [{sistema, nombre, u: [u0, u1], v: [v0, v1]}].
var zonas: Array = []
## {sistema, nombre} de la medalla de aparte.
var aparte := {}
## id del sistema -> color del área.
var colores := {}
## id del sistema -> «completo», «en_curso», «averia» o «sin_empezar».
var estados := {}
## id del sistema -> fracción de avance, para el anillo de la medalla.
var avances := {}
## «sistemas» (las zonas se tocan) o «tableros» (las marcas de los lugares se tocan).
var capa := "sistemas":
	set(valor):
		capa = valor
		queue_redraw()
## [{lugar, u, v, paneles: n.º de paneles, alarma: bool}].
var lugares: Array = []
var lugar_elegido := -1:
	set(valor):
		lugar_elegido = valor
		queue_redraw()
## Alto libre arriba para lo que la pantalla ponga encima, como el selector de capas.
var reserva_arriba := 0.0
## Nombre y datos del buque, arriba a la derecha en la capa de tableros.
var rotulo_buque := ""
var detalle_buque := ""

var _vertical := false
var _origen := Vector2.ZERO
var _ku := 1.0
var _kv := 1.0
var _casco: PackedVector2Array
var _borda: PackedVector2Array
var _tocada := -1


func _init() -> void:
	super()
	clip_contents = true
	custom_minimum_size = Vector2(300, 200)
	_casco = casco_puntos(0.0)
	_borda = casco_puntos(9.0)
	resized.connect(queue_redraw)


func cargar(planta: Dictionary, sistemas: Array) -> void:
	zonas = planta.get("zonas", [])
	aparte = planta.get("aparte", {})
	for s: Dictionary in sistemas:
		colores[int(s["id"])] = Tema.color_area(s)
	queue_redraw()


func es_vertical() -> bool:
	return size.y > size.x * 1.05


# --- Geometría ---

## Contorno del casco en el espacio del buque: espejo de popa con las esquinas redondeadas y
## proa llena, como la de un cerquero. «margen» lo estrecha para la cubierta dentro de la borda.
static func casco_puntos(margen: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	var mb := MEDIA_MANGA - margen
	var u0 := POPA + margen
	var ub := PROA - margen * 1.6
	var r := 22.0
	for i in 11:
		var a := PI / 2.0 * i / 10.0
		p.append(Vector2(u0 + r - r * sin(a), EJE + mb - r + r * cos(a)))
	for i in 11:
		var a := PI / 2.0 * i / 10.0
		p.append(Vector2(u0 + r - r * cos(a), EJE - mb + r - r * sin(a)))
	p.append(Vector2(ARRANQUE_PROA, EJE - mb))
	for i in range(1, 41):
		var t := i / 40.0
		p.append(Vector2(ARRANQUE_PROA + (ub - ARRANQUE_PROA) * t, EJE - mb * pow(1.0 - pow(t, 2.1), 0.62)))
	for i in range(39, -1, -1):
		var t := i / 40.0
		p.append(Vector2(ARRANQUE_PROA + (ub - ARRANQUE_PROA) * t, EJE + mb * pow(1.0 - pow(t, 2.1), 0.62)))
	return p


## Reparte el tamaño entre el buque, la medalla y la leyenda.
func _ajustar() -> void:
	_vertical = es_vertical()
	if _vertical:
		var arriba := MARGEN + 4.0 + reserva_arriba
		var abajo := MARGEN + 18.0
		_ku = maxf((size.y - arriba - abajo) / 1000.0, 0.05)
		_kv = minf((size.x - MARGEN * 2.0) / 300.0, _ku * ENSANCHE_MAX_VERTICAL)
		_origen = Vector2((size.x - 300.0 * _kv) / 2.0, arriba)
	else:
		_ku = maxf((size.x - MARGEN * 2.0) / 1000.0, 0.05)
		var alto := size.y - MARGEN - ALTO_LEYENDA - 6.0 - reserva_arriba
		_kv = minf(alto / 300.0, _ku * ENSANCHE_MAX_APAISADO)
		_origen = Vector2(MARGEN, MARGEN + reserva_arriba + (alto - 300.0 * _kv) / 2.0)


## Punto del espacio del buque en la pantalla.
func a_pantalla(u: float, v: float) -> Vector2:
	if _vertical:
		return _origen + Vector2(v * _kv, (1000.0 - u) * _ku)
	return _origen + Vector2(u * _ku, v * _kv)


func _rect(u0: float, u1: float, v0: float, v1: float) -> Rect2:
	var a := a_pantalla(u0, v0)
	var b := a_pantalla(u1, v1)
	return Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (a - b).abs())


func _poligono(puntos: PackedVector2Array, desplazamiento := Vector2.ZERO) -> PackedVector2Array:
	var r := PackedVector2Array()
	for q in puntos:
		r.append(a_pantalla(q.x, q.y) + desplazamiento)
	return r


## Rectángulo de cada zona en la pantalla: [{sistema, rect}].
func zonas_pantalla() -> Array[Dictionary]:
	_ajustar()
	var r: Array[Dictionary] = []
	for z: Dictionary in zonas:
		r.append({"sistema": int(z["sistema"]), "rect": _rect(z["u"][0], z["u"][1], z["v"][0], z["v"][1])})
	return r


func centro_medalla() -> Vector2:
	if _vertical:
		return Vector2(MARGEN + RADIO_MEDALLA + 6.0, MARGEN + RADIO_MEDALLA + 4.0 + reserva_arriba)
	return Vector2(size.x - MARGEN - RADIO_MEDALLA - 14.0, MARGEN + RADIO_MEDALLA + reserva_arriba)


## Centro de la marca de cada lugar en la pantalla.
func centros_lugares() -> Array[Vector2]:
	_ajustar()
	var r: Array[Vector2] = []
	for l: Dictionary in lugares:
		r.append(a_pantalla(float(l["u"]), float(l["v"])))
	return r


## Lugar bajo el punto, o -1: la marca más cercana, con un área táctil de 48 puntos o más.
func lugar_en(punto: Vector2) -> int:
	var mejor := maxf(MEDIO_MARCA, RADIO_TOQUE) + 2.0
	var r := -1
	var centros := centros_lugares()
	for i in centros.size():
		var d := maxf(absf(punto.x - centros[i].x), absf(punto.y - centros[i].y))
		if d <= mejor:
			mejor = d
			r = i
	return r


## Sistema bajo el punto, o -1. La medalla va primero; fuera de las zonas vale la más cercana a
## menos de RADIO_TOQUE, para que el área tocable llegue a los 48 puntos.
func zona_en(punto: Vector2) -> int:
	if capa == "tableros":
		return -1
	var lista := zonas_pantalla()
	if not aparte.is_empty() and punto.distance_to(centro_medalla()) <= maxf(RADIO_MEDALLA * 1.3, RADIO_TOQUE):
		return int(aparte["sistema"])
	var cercana := -1
	var mejor := RADIO_TOQUE
	for z: Dictionary in lista:
		var r: Rect2 = z["rect"]
		if r.has_point(punto):
			return z["sistema"]
		var dentro := Vector2(clampf(punto.x, r.position.x, r.end.x), clampf(punto.y, r.position.y, r.end.y))
		var d := dentro.distance_to(punto)
		if d < mejor:
			mejor = d
			cercana = z["sistema"]
	return cercana


func _al_presionar(punto: Vector2) -> void:
	_tocada = zona_en(punto)
	queue_redraw()


func _al_soltar() -> void:
	_tocada = -1
	queue_redraw()


func _al_tocar(punto: Vector2) -> void:
	if capa == "tableros":
		var i := lugar_en(punto)
		if i >= 0:
			lugar_tocado.emit(i)
		return
	var id := zona_en(punto)
	if id >= 0:
		sistema_tocado.emit(id)


# --- Dibujo ---

func _draw() -> void:
	_ajustar()
	_dibujar_mar()
	_dibujar_casco()
	_dibujar_cubierta()
	_dibujar_superestructura()
	if capa == "tableros":
		for z: Dictionary in zonas:
			_dibujar_zona_tenue(z)
		var centros := centros_lugares()
		for i in lugares.size():
			if i != lugar_elegido:
				_dibujar_marca_lugar(centros[i], lugares[i], false)
		if lugar_elegido >= 0 and lugar_elegido < lugares.size():
			_dibujar_marca_lugar(centros[lugar_elegido], lugares[lugar_elegido], true)
		_dibujar_rotulo_buque()
		_dibujar_leyenda_tableros()
		return
	for z: Dictionary in zonas:
		_dibujar_zona(z)
	if not aparte.is_empty():
		_dibujar_medalla()
	_dibujar_leyenda()


func _dibujar_mar() -> void:
	# Agua en un hueco con el borde en sombra, como una ventana del mímico.
	var r := Rect2(Vector2.ZERO, size)
	DibujoAri.degradado(self, r, 14.0, [MAR, MAR_FONDO])
	DibujoAri.borde(self, r, 14.0, MAR_BORDE, 1.0)
	for i in 3:
		DibujoAri.borde(self, r.grow(-1.0 - i * 1.5), 13.0, Color(0, 0, 0, 0.3 - i * 0.08), 2.0)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 7
	for i in 18:
		var p := Vector2(rnd.randf() * size.x, rnd.randf() * size.y)
		var ola := PackedVector2Array()
		for k in 9:
			ola.append(p + Vector2(k * 4.0, sin(k * PI / 4.0) * 2.5))
		draw_polyline(ola, Color(0.44, 0.71, 0.87, 0.16), 1.6, true)
	# Estela de la popa.
	var popa := a_pantalla(POPA - 20.0, EJE)
	for k in 4:
		var fin := a_pantalla(-60.0 - k * 20.0, EJE + (k - 1.5) * 30.0)
		draw_line(popa, fin, Color(0.75, 0.9, 1.0, 0.3 - k * 0.06), 5.0 - k, true)


## La luz viene de babor: de arriba de la pantalla en apaisado y de la izquierda en vertical.
func _eje_luz() -> Array[Vector2]:
	return [a_pantalla(500, 0), a_pantalla(500, 300)]


func _dibujar_casco() -> void:
	var casco := _poligono(_casco)
	for i in 4:
		draw_colored_polygon(_poligono(_casco, Vector2(0, 3.0 + i * 2.0)), Color(0, 0, 0, 0.16))
	var eje := _eje_luz()
	Relieve.poligono_degradado(self, casco, CASCO, eje[0], eje[1])
	var linea := casco.duplicate()
	linea.append(casco[0])
	draw_polyline(linea, Color("11171c"), 1.5, true)


func _dibujar_cubierta() -> void:
	var borda := _poligono(_borda)
	var eje := _eje_luz()
	Relieve.poligono_degradado(self, borda, CUBIERTA, eje[0], eje[1])
	# Costuras de las planchas.
	for u in range(80, 960, 50):
		_linea_recortada(a_pantalla(u, 0), a_pantalla(u, 300), borda, Color(0, 0, 0, 0.28))
	for v in [100.0, 200.0]:
		_linea_recortada(a_pantalla(0, v), a_pantalla(1000, v), borda, Color(0, 0, 0, 0.22))
	# Montón de red en la popa y la panga sobre la rampa.
	var red := _rect(70, 300, 70, 230)
	var radio := minf(red.size.x, red.size.y) * 0.22
	DibujoAri.relleno(self, red, radio, RED)
	var forma := DibujoAri.contorno(red, radio)
	var y := red.position.y + 4.0
	while y < red.end.y - 2.0:
		var ola := PackedVector2Array()
		var x := red.position.x
		while x <= red.end.x:
			ola.append(Vector2(x, y + sin((x - red.position.x) / 9.0 * TAU) * 1.8))
			x += 1.5
		for trozo in Geometry2D.intersect_polyline_with_polygon(ola, forma):
			draw_polyline(trozo, HILO_RED, 0.8, true)
		y += 7.0
	var panga := _poligono(PackedVector2Array([Vector2(22, 124), Vector2(95, 124), Vector2(128, 150), Vector2(95, 176), Vector2(22, 176)]))
	draw_colored_polygon(_poligono(PackedVector2Array([Vector2(22, 124), Vector2(95, 124), Vector2(128, 150), Vector2(95, 176), Vector2(22, 176)]), Vector2(0, 3)), Color(0, 0, 0, 0.4))
	draw_colored_polygon(panga, Color("d8dee3"))
	draw_colored_polygon(_poligono(PackedVector2Array([Vector2(30, 132), Vector2(92, 132), Vector2(115, 150), Vector2(92, 168), Vector2(30, 168)])), Color("8e9aa4"))
	# Cubas de salmuera con escarcha.
	for i in 3:
		for j in 2:
			var cuba := _rect(345 + i * 58, 391 + i * 58, 62 + j * 92, 140 + j * 92)
			DibujoAri.relleno(self, cuba.grow(1.5), 5.0, Color(0, 0, 0, 0.55))
			DibujoAri.degradado(self, cuba, 4.0, ESCARCHA)
			DibujoAri.borde(self, cuba.grow(-3.0), 3.0, Color(0.9, 0.98, 1.0, 0.35))
			draw_line(cuba.position + Vector2(4, 2), Vector2(cuba.end.x - 4, cuba.position.y + 2), Color(0, 0, 0, 0.5), 2.0)
	# Cámara de máquinas: la parrilla vista a través de la cubierta.
	var maquinas := _rect(530, 690, 38, 262)
	DibujoAri.relleno(self, maquinas, 0.0, PARRILLA)
	var paso := 6.0
	var gx := maquinas.position.x
	while gx < maquinas.end.x:
		draw_line(Vector2(gx, maquinas.position.y), Vector2(gx, maquinas.end.y), PARRILLA_HUECO, 1.6)
		gx += paso
	var gy := maquinas.position.y
	while gy < maquinas.end.y:
		draw_line(Vector2(maquinas.position.x, gy), Vector2(maquinas.end.x, gy), PARRILLA_HUECO, 1.6)
		gy += paso
	# Sombra interior al pie de la borda.
	var linea := borda.duplicate()
	linea.append(borda[0])
	draw_polyline(linea, Color(0, 0, 0, 0.45), 6.0, true)
	# Pluma del power block.
	var pie := a_pantalla(330, EJE)
	var punta := a_pantalla(190, EJE)
	var grueso := maxf(5.0 * minf(_ku, _kv) * 1.4, 3.0)
	draw_line(pie + Vector2(0, 3), punta + Vector2(0, 3), Color(0, 0, 0, 0.45), grueso, true)
	draw_line(pie, punta, AMARILLO_PLUMA, grueso, true)
	draw_circle(punta, grueso * 1.4, Color("5a4400"))
	draw_circle(punta, grueso * 1.2, AMARILLO_PLUMA)
	PiezasAri._disco(self, pie, grueso * 1.2, Color.WHITE, Color("2b3238"))


func _linea_recortada(a: Vector2, b: Vector2, forma: PackedVector2Array, color: Color) -> void:
	for trozo in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), forma):
		draw_polyline(trozo, color, 1.0)


func _dibujar_superestructura() -> void:
	var puntos := PackedVector2Array([Vector2(700, 46), Vector2(870, 52), Vector2(892, 80), Vector2(892, 220), Vector2(870, 248), Vector2(700, 254)])
	draw_colored_polygon(_poligono(puntos, Vector2(3, 6)), Color(0, 0, 0, 0.5))
	var techo := _poligono(puntos)
	var eje := _eje_luz()
	Relieve.poligono_degradado(self, techo, TECHO, eje[0], eje[1])
	var linea := techo.duplicate()
	linea.append(techo[0])
	draw_polyline(linea, Color("59646e"), 1.2, true)
	# Ventanas del puente, mirando a proa.
	for k in 7:
		var ventana := _rect(884, 890, 70 + k * 23, 88 + k * 23)
		draw_rect(ventana, Color("16364d"))
	# Castillo de proa: bitas y molinete.
	for v in [110.0, 190.0]:
		PiezasAri.tornillo(self, a_pantalla(935, v), 4.0)
	var molinete := a_pantalla(905, EJE)
	PiezasAri._disco(self, molinete, 6.0, Color.WHITE, Color("2b3238"))
	draw_circle(molinete, 2.6, Color("2a3138"))


func _dibujar_zona(z: Dictionary) -> void:
	var id := int(z["sistema"])
	var r := _rect(z["u"][0], z["u"][1], z["v"][0], z["v"][1])
	var color: Color = colores.get(id, Tema.ACENTO)
	var tocada := _tocada == id
	DibujoAri.sombra(self, r, 9.0, 0.5, Vector2(0, 3))
	DibujoAri.relleno(self, r, 9.0, Color(color, 0.42 if tocada else 0.27))
	DibujoAri.borde(self, r, 9.0, color.lightened(0.25) if tocada else color, 2.2)
	DibujoAri.borde(self, r.grow(-2.5), 7.5, Color(1, 1, 1, 0.16), 1.0)
	DibujoAri.relleno(self, Rect2(r.position + Vector2(2.5, 2.5), Vector2(r.size.x - 5.0, minf(r.size.y * 0.42, 26.0))), 7.0, Color(1, 1, 1, 0.07))
	_etiqueta(r, str(z.get("nombre", "")), "sistema_%d" % id, color)
	Relieve.lampara_estado(self, Vector2(r.end.x - 12.0, r.position.y + 12.0), 5.4, estados.get(id, "sin_empezar"))


## Nombre de la zona en una pastilla oscura con el icono. Si no cabe a lo ancho, el icono va en
## un círculo encima y el nombre debajo.
func _etiqueta(r: Rect2, nombre: String, icono: String, color: Color) -> void:
	var tam := float(Tema.tam(12))
	var ancho := PiezasAri.ancho_texto(nombre, tam) + 34.0
	var alto := tam + 14.0
	var c := r.get_center()
	if ancho <= r.size.x - 8.0:
		var p := Rect2(c - Vector2(ancho, alto) / 2.0, Vector2(ancho, alto))
		_pastilla(p, color)
		Relieve.dibujar_icono(self, icono, Vector2(p.position.x + 16.0, c.y), 16.0)
		PiezasAri.texto(self, nombre, p.position.x + 28.0, c.y + tam * 0.36, tam, Color.WHITE, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
		return
	tam -= 1.0
	while tam > 8.0 and PiezasAri.ancho_texto(nombre, tam) + 14.0 > r.size.x - 6.0:
		tam -= 0.5
	ancho = PiezasAri.ancho_texto(nombre, tam) + 14.0
	var circulo := c - Vector2(0, 10)
	draw_circle(circulo + Vector2(0, 2), 15.0, Color(0, 0, 0, 0.45))
	draw_circle(circulo, 15.0, PASTILLA)
	draw_arc(circulo, 15.0, 0, TAU, 32, color, 1.4, true)
	PiezasAri._elipse(self, circulo + Vector2(-3, -8), Vector2(9, 4), 0.0, Color(1, 1, 1, 0.1))
	Relieve.dibujar_icono(self, icono, circulo, 16.0)
	var p := Rect2(Vector2(c.x - ancho / 2.0, c.y + 9.0), Vector2(ancho, tam + 8.0))
	_pastilla(p, color)
	PiezasAri.texto(self, nombre, c.x, p.position.y + p.size.y / 2.0 + tam * 0.36, tam, Color.WHITE)


func _pastilla(p: Rect2, color: Color) -> void:
	DibujoAri.relleno(self, Rect2(p.position + Vector2(0, 1.5), p.size), p.size.y / 2.0, Color(0, 0, 0, 0.4))
	DibujoAri.relleno(self, p, p.size.y / 2.0, PASTILLA)
	DibujoAri.borde(self, p, p.size.y / 2.0, color, 1.2)
	DibujoAri.relleno(self, Rect2(p.position + Vector2(2, 1.5), Vector2(p.size.x - 4.0, p.size.y * 0.45)), p.size.y / 3.0, Color(1, 1, 1, 0.08))


func _dibujar_medalla() -> void:
	var id := int(aparte["sistema"])
	var c := centro_medalla()
	var color: Color = colores.get(id, Tema.ACENTO)
	if _tocada == id:
		color = color.lightened(0.2)
	Relieve.medalla(self, c, RADIO_MEDALLA, color, "sistema_%d" % id, avances.get(id, 0.0))
	Relieve.lampara_estado(self, c + Vector2(RADIO_MEDALLA * 0.82, -RADIO_MEDALLA * 0.82), 4.4, estados.get(id, "sin_empezar"))
	var tam := float(Tema.tam(11))
	var nombre := str(aparte.get("nombre", ""))
	var base := c.y + RADIO_MEDALLA * 1.22 + tam + 3.0
	PiezasAri.texto(self, nombre, c.x, base + 1.0, tam, Color(0, 0, 0, 0.7))
	PiezasAri.texto(self, nombre, c.x, base, tam, Color.WHITE)


func _dibujar_leyenda() -> void:
	var tam := float(Tema.tam(10.5))
	var origen := Vector2(MARGEN + 6.0, size.y - 11.0)
	if _vertical:
		origen = Vector2(size.x - 172.0, MARGEN + 8.0)
	var x := origen.x
	for i in Relieve.LEYENDA.size():
		var par: Array = Relieve.LEYENDA[i]
		var p := Vector2(x, origen.y)
		if _vertical:
			p = origen + Vector2((i % 2) * 86.0, floori(i / 2.0) * 18.0)
		Relieve.lampara_estado(self, p, 4.0, par[0])
		PiezasAri.texto(self, par[1], p.x + 10.0, p.y + tam * 0.36, tam, Color("b9c6d1"), Tema.PESO_FUERTE, HORIZONTAL_ALIGNMENT_LEFT)
		x += PiezasAri.ancho_texto(par[1], tam, Tema.PESO_FUERTE) + 30.0


# --- Capa de tableros ---

## La zona del sistema como un tinte con el borde a trazos, sin rótulo ni lámpara.
func _dibujar_zona_tenue(z: Dictionary) -> void:
	var r := _rect(z["u"][0], z["u"][1], z["v"][0], z["v"][1])
	var color: Color = colores.get(int(z["sistema"]), Tema.ACENTO)
	DibujoAri.relleno(self, r, 9.0, Color(color, 0.1))
	var c := Color(color, 0.5)
	var esquinas := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		draw_dashed_line(esquinas[k], esquinas[(k + 1) % 4], c, 1.4, 5.0)


## Marca de un lugar con tableros: chapa ámbar con aro cromado y el rayo, la insignia con el
## número de paneles y, si hay avería, la lámpara roja. La elegida brilla y lleva su nombre.
func _dibujar_marca_lugar(c: Vector2, l: Dictionary, elegida: bool) -> void:
	var m := MEDIO_MARCA
	if elegida:
		Relieve.halo(self, c, m * 2.4, Relieve.AMBAR_HALO, 1.8)
		var pasos := 28
		for i in pasos:
			if i % 2 == 0:
				var a0 := TAU * i / pasos
				draw_arc(c, m * 1.45, a0, a0 + TAU / pasos * 0.75, 3, Color(Tema.ACENTO, 0.85), 1.5, true)
	var caja := Rect2(c - Vector2(m, m), Vector2(m, m) * 2.0)
	DibujoAri.relleno(self, Rect2(caja.position + Vector2(0, 2.5), caja.size), 7.0, Color(0, 0, 0, 0.55))
	DibujoAri.degradado(self, caja, 7.0, [Color("ffffff"), Color("b9c2ca"), Color("5b646d"), Color("2b3238")])
	var dentro := caja.grow(-2.0)
	var colores_marca: Array = AMBAR_MARCA if not elegida else [Color("fff4cf"), Color("ffd166"), Color("f0a21a")]
	DibujoAri.degradado(self, dentro, 5.5, colores_marca)
	DibujoAri.relleno(self, Rect2(dentro.position + Vector2(1, 1), Vector2(dentro.size.x - 2.0, dentro.size.y * 0.45)), 4.5, Color(1, 1, 1, 0.28))
	var k := m / 12.0
	var rayo := PackedVector2Array()
	for q: Vector2 in [Vector2(1.5, -7), Vector2(-4.5, 1), Vector2(-0.5, 1), Vector2(-2, 7.5), Vector2(4.5, -1.5), Vector2(0.5, -1.5)]:
		rayo.append(c + q * k)
	draw_colored_polygon(rayo, Color("2a1a00"))
	var n := int(l.get("paneles", 0))
	if n > 0:
		var b := c + Vector2(m - 1.0, m - 1.0)
		draw_circle(b, 8.0, Color("0d1318"))
		draw_arc(b, 8.0, 0, TAU, 20, Tema.ACENTO, 1.2, true)
		PiezasAri.texto(self, str(n), b.x, b.y + 3.6, 10.0, Tema.ACENTO, Tema.PESO_NEGRITA)
	if l.get("alarma", false):
		PiezasAri.lampara(self, c + Vector2(m - 1.0, -m + 1.0), 4.5, "rojo", 1.0)
	if elegida:
		var nombre := str(l.get("nombre", l.get("lugar", "")))
		var tam := float(Tema.tam(11.5))
		var w := PiezasAri.ancho_texto(nombre, tam) + 20.0
		var y := c.y - m - 30.0 if c.y - m - 30.0 > 4.0 + reserva_arriba else c.y + m + 8.0
		var p := Rect2(Vector2(clampf(c.x - w / 2.0, 4.0, maxf(size.x - w - 4.0, 4.0)), y), Vector2(w, tam + 10.0))
		DibujoAri.relleno(self, Rect2(p.position + Vector2(0, 1.5), p.size), p.size.y / 2.0, Color(0, 0, 0, 0.45))
		DibujoAri.relleno(self, p, p.size.y / 2.0, PASTILLA)
		DibujoAri.borde(self, p, p.size.y / 2.0, Color(Relieve.AMBAR, 0.8), 1.2)
		PiezasAri.texto(self, nombre, p.get_center().x, p.get_center().y + tam * 0.36, tam, Tema.ACENTO, Tema.PESO_NEGRITA)


func _dibujar_rotulo_buque() -> void:
	if rotulo_buque.is_empty():
		return
	var tam := float(Tema.tam(13))
	var x := size.x - MARGEN - 6.0
	var y := MARGEN + 16.0
	PiezasAri.texto(self, rotulo_buque, x, y + 1.0, tam, Color(0, 0, 0, 0.6), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
	PiezasAri.texto(self, rotulo_buque, x, y, tam, Color.WHITE, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
	if not detalle_buque.is_empty() and not _vertical:
		PiezasAri.texto(self, detalle_buque, x, y + tam + 4.0, float(Tema.tam(10.5)), Color("a9b6c1"), Tema.PESO_MEDIO, HORIZONTAL_ALIGNMENT_RIGHT)


func _dibujar_leyenda_tableros() -> void:
	var tam := float(Tema.tam(10.5))
	var p := Vector2(MARGEN + 12.0, size.y - 12.0)
	DibujoAri.degradado(self, Rect2(p - Vector2(6, 6), Vector2(12, 12)), 3.0, AMBAR_MARCA)
	PiezasAri.texto(self, "lugar con tableros", p.x + 12.0, p.y + tam * 0.36, tam, Color("b9c6d1"), Tema.PESO_FUERTE, HORIZONTAL_ALIGNMENT_LEFT)
	var x := p.x + 28.0 + PiezasAri.ancho_texto("lugar con tableros", tam, Tema.PESO_FUERTE)
	PiezasAri.lampara(self, Vector2(x, p.y), 3.8, "rojo", 1.0)
	PiezasAri.texto(self, "avería pendiente", x + 10.0, p.y + tam * 0.36, tam, Color("b9c6d1"), Tema.PESO_FUERTE, HORIZONTAL_ALIGNMENT_LEFT)
