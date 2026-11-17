class_name CasillaGenerador
extends Control
## Casilla de un grupo electrógeno en el cuadro principal, como en los simuladores de sala de
## máquinas: vatímetro de aguja, visores de tensión, frecuencia y corriente, lámparas STOP y
## START, alarma, modo del PMS e interruptor del generador (GCB) con sus botones I y O.
## Tocar START/STOP arranca o para el diésel; los botones I/O cierran o abren el interruptor (o
## lo rearman tras un disparo); el resto de la casilla abre el detalle del grupo.

signal accion(id: String, que: String)

const DISENO := Vector2(104, 182)
const ZONA_MUERTA := 12.0
const RADIO_TOQUE := 24.0
const REFRESCO_S := 0.12

var id := ""
var titulo := ""
var sim: SimSimulacion
var interruptor := ""
var pms := ""
var elegida := false
var _inicio := Vector2.ZERO
var _zona := ""
var _refresco := 0.0


func _init(p_id := "", p_titulo := "", p_sim: SimSimulacion = null, p_interruptor := "", p_pms := "PMS") -> void:
	id = p_id
	titulo = p_titulo
	sim = p_sim
	interruptor = p_interruptor
	pms = p_pms
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = DISENO


func escala() -> float:
	return minf(size.x / DISENO.x, size.y / DISENO.y)


func _p(x: float, y: float) -> Vector2:
	return (size - DISENO * escala()) / 2.0 + Vector2(x, y) * escala()


func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_p(x, y), Vector2(w, h) * escala())


func generador() -> SimGenerador:
	return sim.componente(id) as SimGenerador if sim != null and sim.componentes.has(id) else null


func gcb() -> SimInterruptorGenerador:
	return sim.componente(interruptor) as SimInterruptorGenerador if sim != null and sim.componentes.has(interruptor) else null


## Alarma del grupo: dañado, parado por una protección o interruptor disparado.
func en_alarma() -> bool:
	var g := generador()
	var q := gcb()
	if g == null or q == null:
		return false
	return g.estado["danado"] or not str(g.estado["parada"]).is_empty() or q.estado["disparado"]


## «on», «off» o «trip», para el dibujo del interruptor.
func estado_gcb() -> String:
	var q := gcb()
	if q == null:
		return "off"
	if q.estado["disparado"]:
		return "trip"
	return "on" if q.cerrado() else "off"


func _draw() -> void:
	var g := generador()
	if g == null:
		return
	var s := escala()
	var e := g.estado
	var alarma := en_alarma()
	PiezasAri.chapa(self, _r(3, 3, 98, 176), s, PiezasAri.CHAPA_DISPARO if alarma else PiezasAri.CHAPA, alarma)
	if elegida:
		DibujoAri.borde(self, _r(3, 3, 98, 176).grow(2.0 * s), 7.0 * s, Color("38e0e8"), maxf(2.0 * s, 1.5))
	var franja := Color("c9d3dc")
	if alarma:
		franja = Color("ff4d4d")
	elif estado_gcb() == "on":
		franja = Color("3dff74")
	elif g.en_marcha():
		franja = Color("ffd23d")
	PiezasAri.rotulo(self, _r(17, 6, 70, 15), titulo, s, franja, 9.5)
	var p_n: float = g.params["p_kw"]
	PiezasAri.amperimetro(self, _r(20, 28, 64, 46), s, float(e["p_kw"]), 0.0, PiezasAri.fondo_escala(p_n), p_n, "kW")
	var filas := [[LecturaLcd.numero(float(e["v"]), 0), "V"], [LecturaLcd.numero(float(e["f"]), 1), "Hz"], [LecturaLcd.numero(float(e["i"]), 0), "A"]]
	for i in 3:
		PiezasAri.visor(self, _r(9, 78 + i * 14, 48, 12), s, filas[i][0], filas[i][1], Tema.ARI_LCD_VERDE, 7.6 * s)
	var marcha := g.en_marcha()
	PiezasAri.lampara(self, _p(17, 129), 6.0 * s, "rojo", 0.0 if marcha else 1.0)
	PiezasAri.lampara(self, _p(38, 129), 6.0 * s, "verde", 1.0 if marcha else 0.0)
	PiezasAri.placa(self, _r(7, 138, 20, 7), "STOP", s, 4.8)
	PiezasAri.placa(self, _r(28, 138, 20, 7), "START", s, 4.8)
	PiezasAri.lampara(self, _p(15, 155), 4.5 * s, "ambar", 1.0 if alarma else 0.0)
	PiezasAri.texto(self, "ALARMA", _p(23, 157).x, _p(23, 157).y, 4.8 * s, PiezasAri.TEXTO_CHAPA, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
	var automatico := false
	if sim.componentes.has(pms):
		automatico = (sim.componente(pms) as SimPMS).automatico()
	var placa := _r(7, 162, 44, 10)
	DibujoAri.degradado(self, placa, 2.0 * s, PiezasAri.ROTULO)
	DibujoAri.borde(self, placa, 2.0 * s, Color("5d7891"), 1.0)
	PiezasAri.texto(self, "PMS AUTO" if automatico else "PMS MAN", placa.get_center().x, placa.get_center().y + 2.0 * s, 5.4 * s, Color("57f08b") if automatico else Color("ffd23d"))
	_dibujar_gcb(s)


## Interruptor del generador: ventana de estado, botones I (verde) y O (rojo) y «CHARGED».
func _dibujar_gcb(s: float) -> void:
	var r := _r(60, 78, 36, 94)
	DibujoAri.relleno(self, Rect2(r.position + Vector2(-1, 2) * s, r.size + Vector2(2, 0)), 3.0 * s, Color(0, 0, 0, 0.45))
	DibujoAri.degradado(self, r, 3.0 * s, PiezasAri.CAJA)
	DibujoAri.borde(self, r, 3.0 * s, Color("0c0e10"), 1.0)
	PiezasAri.texto(self, interruptor, r.get_center().x, r.position.y + 8.0 * s, 5.0 * s, Color("9aa3ab"))
	PiezasAri.texto(self, "GCB", r.get_center().x, r.position.y + 14.0 * s, 4.2 * s, Color("9aa3ab"))
	var ventana := Rect2(r.position.x + 3.0 * s, r.position.y + 18.0 * s, r.size.x - 6.0 * s, 12.0 * s)
	var estado := estado_gcb()
	var fondo: Color = {"on": Color("c81b12"), "off": Color("2fbf4f"), "trip": Color("ffb020")}[estado]
	var tinta: Color = {"on": Color.WHITE, "off": Color("06210e"), "trip": Color("1b1200")}[estado]
	DibujoAri.relleno(self, ventana, 1.5 * s, fondo)
	PiezasAri.texto(self, {"on": "I  ON", "off": "O  OFF", "trip": "TRIP"}[estado], ventana.get_center().x, ventana.end.y - 3.3 * s, 6.2 * s, tinta)
	var boton_i := _r(64, 116, 28, 18)
	var boton_o := _r(64, 138, 28, 18)
	DibujoAri.pieza(self, boton_i, 2.0 * s, [Color("4fcf6e"), Color("1f7a37"), Color("196a2f"), Color("125223")], DibujoAri.BRILLO, Color.BLACK, Color(1, 1, 1, 0.4), 0.3)
	DibujoAri.pieza(self, boton_o, 2.0 * s, [Color("ff6e60"), Color("b3241a"), Color("9e1f16"), Color("7a160f")], DibujoAri.BRILLO, Color.BLACK, Color(1, 1, 1, 0.4), 0.3)
	PiezasAri.texto(self, "I", boton_i.get_center().x, boton_i.get_center().y + 3.0 * s, 8.0 * s, Color.WHITE)
	PiezasAri.texto(self, "O", boton_o.get_center().x, boton_o.get_center().y + 3.0 * s, 8.0 * s, Color.WHITE)
	var cargado := Rect2(r.position.x + 3.0 * s, r.end.y - 11.0 * s, r.size.x - 6.0 * s, 7.0 * s)
	DibujoAri.relleno(self, cargado, 1.0 * s, Color("15181b"))
	PiezasAri.texto(self, "CHARGED", cargado.get_center().x, cargado.end.y - 1.8 * s, 4.0 * s, Color("e8b10f"))


## «diesel» sobre STOP/START, «cerrar» o «abrir» sobre los botones I/O, y «elegir» en el resto.
func zona_en(punto: Vector2) -> String:
	var zonas := [["diesel", Vector2(27, 129), 16.0], ["cerrar", Vector2(78, 125), 11.0], ["abrir", Vector2(78, 147), 11.0]]
	var mejor := "elegir"
	var distancia := INF
	for z: Array in zonas:
		var c := _p((z[1] as Vector2).x, (z[1] as Vector2).y)
		var d := punto.distance_to(c)
		if d <= maxf(float(z[2]) * escala(), RADIO_TOQUE) and d < distancia:
			distancia = d
			mejor = z[0]
	return mejor


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_inicio = evento.position
			_zona = zona_en(evento.position)
		elif not _zona.is_empty():
			if evento.position.distance_to(_inicio) <= ZONA_MUERTA:
				accion.emit(id, _zona)
			_zona = ""
	elif evento is InputEventMouseMotion and not _zona.is_empty():
		if evento.position.distance_to(_inicio) > ZONA_MUERTA:
			_zona = ""


func cancelar_toque() -> void:
	_zona = ""


func _process(delta: float) -> void:
	_refresco += delta
	if _refresco >= REFRESCO_S:
		_refresco = 0.0
		queue_redraw()


## Rejilla de casillas que reparte las columnas según su ancho, en filas iguales.
class Rejilla:
	extends GridContainer
	const ANCHO_MIN := 88.0
	const ANCHO_MAX := 130.0
	const SEPARACION := 8.0
	var _ancho_previo := -1.0

	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_constant_override("h_separation", int(SEPARACION))
		add_theme_constant_override("v_separation", int(SEPARACION))
		resized.connect(repartir)

	func repartir() -> void:
		var ancho := size.x
		if ancho < ANCHO_MIN or is_equal_approx(ancho, _ancho_previo):
			return
		_ancho_previo = ancho
		var n := get_child_count()
		if n == 0:
			return
		var cols := clampi(floori((ancho + SEPARACION) / (ANCHO_MIN + SEPARACION)), 1, n)
		# Filas iguales: cuatro grupos van en una fila o en dos de dos, no en tres y uno.
		var filas := ceili(float(n) / cols)
		cols = ceili(float(n) / filas)
		var w := minf((ancho - SEPARACION * (cols - 1)) / cols, ANCHO_MAX)
		columns = cols
		for c in get_children():
			(c as Control).custom_minimum_size = Vector2(floorf(w), floorf(w * DISENO.y / DISENO.x))
