class_name CasillaAri
extends Control
## Casilla del mímico de un tablero, como en los simuladores de sala de máquinas: una chapa con
## relieve por arrancador, con su amperímetro, su visor, las lámparas STOP y START, el selector y
## el interruptor ON/TRIP. Lee el estado de la simulación y, al tocarla, emite «accion» para que
## la pantalla maniobre el componente. Los datos vienen del bloque «mimico» del tablero:
##
##   tipo "motor" (por defecto): titulo, franja, motor, proteccion, termico, arrancador,
##     corriente, marcha, paro, luz_marcha, luz_paro, luz_falla, selector, escala.
##   tipo "alimentacion": componente (seccionador), tierra [lámparas], test, medida [nodo, nodo].
##   tipo "mando": elementos [{tipo: selector|pulsador|luz|lectura|seta, componente, texto, ...}].
##   tipo "megohmetro": el instrumento; su estado lo pone la pantalla en «megger».
##
## Se dibuja en una rejilla de diseño de 104 × 182 y se escala al tamaño de la casilla.

signal accion(casilla: CasillaAri, que: String, valor: Variant)

const DISENO := Vector2(104, 182)
## Un toque que se mueve más que esto es un arrastre de la lista, no un mando.
const ZONA_MUERTA := 12.0
## Un pulsador se aprieta al mantener el dedo este tiempo, para no arrancar un motor al arrastrar.
const ESPERA_PULSAR := 0.12
## Un toque corto mantiene el pulsador este tiempo, para que la simulación lo vea.
const DURACION_TOQUE := 0.25
const RADIO_TOQUE := 24.0

var datos := {}
var sim: SimSimulacion
var indice := 0
## Estado del megóhmetro que pone la pantalla: {motor, fase, tension, lectura, veredicto, color}.
var megger := {}
## La casilla elegida para el megóhmetro se resalta.
var marcada := false
var _zona := ""
var _inicio := Vector2.ZERO
var _tiempo := 0.0
var _mantenido := false
var _soltar_en := -1.0
var _refresco := 0.0
## Refrescos por segundo del dibujo: las agujas y las luces no necesitan más.
const REFRESCO_S := 0.12


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = DISENO


func tipo() -> String:
	return str(datos.get("tipo", "motor"))


func escala() -> float:
	return minf(size.x / DISENO.x, size.y / DISENO.y)


func _origen() -> Vector2:
	return (size - DISENO * escala()) / 2.0


func _p(x: float, y: float) -> Vector2:
	return _origen() + Vector2(x, y) * escala()


func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_p(x, y), Vector2(w, h) * escala())


func _comp(clave: String) -> SimComponente:
	var id := str(datos.get(clave, ""))
	if sim == null or id.is_empty() or not sim.componentes.has(id):
		return null
	return sim.componente(id)


func _comp_id(id: String) -> SimComponente:
	if sim == null or id.is_empty() or not sim.componentes.has(id):
		return null
	return sim.componente(id)


# --- Lecturas de la simulación ---

## Brillo de 0 a 1 de una lámpara de la simulación, como en el frente del tablero.
func brillo(id: String) -> float:
	var c := _comp_id(id)
	if c == null or c.estado.get("quemada", false):
		return 0.0
	var r: float = c.estado.get("relacion", 1.0 if c.estado.get("encendida", false) else 0.0)
	return clampf(r, 0.0, 1.0) if r >= 0.15 else 0.0


## Corriente media de las fases, de la protección, el arrancador suave o el relé térmico.
func corriente() -> float:
	var c := _comp("corriente") if datos.has("corriente") else null
	if c == null:
		c = _comp("arrancador")
	if c == null:
		c = _comp("proteccion")
	if c == null or sim.solucion == null:
		return 0.0
	if c is SimArrancadorSuave:
		return (c as SimArrancadorSuave).corriente()
	if c is SimReleTermico or c is SimGuardamotor:
		var polos := int(c.params.get("polos", 3))
		var suma := 0.0
		for i in polos:
			suma += float(c.call("corriente", sim.solucion, i))
		return suma / maxf(polos, 1)
	return 0.0


## Corriente nominal del motor, para la zona roja del amperímetro.
func nominal() -> float:
	if datos.has("nominal"):
		return float(datos["nominal"])
	var m := _comp("motor")
	if m != null:
		var v_red := float(datos.get("tension", 380.0))
		return float(m.params["i_delta"]) if absf(float(m.params["v_delta"]) - v_red) < 1.0 else float(m.params["i_estrella"])
	var q := _comp("proteccion")
	if q != null:
		return float(q.params.get("in_a", q.params.get("ajuste_a", 10.0)))
	return 10.0


func fondo() -> float:
	return float(datos.get("escala", PiezasAri.fondo_escala(nominal())))


## Estado de la protección: «on», «off» o «trip». Un relé térmico disparado o un arrancador
## suave en fallo también cuentan como disparo.
func estado_proteccion() -> String:
	var t := _comp("termico")
	if t != null and t.estado.get("disparado", false):
		return "trip"
	var a := _comp("arrancador")
	if a != null and a.estado.get("fase", "") == "fallo":
		return "trip"
	var q := _comp("proteccion")
	if q == null:
		return "on"
	if q.estado.get("disparado", false):
		return "trip"
	return "on" if q.estado.get("encendido", false) else "off"


func en_marcha() -> bool:
	if datos.has("luz_marcha"):
		return brillo(str(datos["luz_marcha"])) > 0.0
	return corriente() > 0.2


func _falla() -> bool:
	if datos.has("luz_falla") and brillo(str(datos["luz_falla"])) > 0.0:
		return true
	return estado_proteccion() == "trip"


func _nombres_selector(sel: SimSelector) -> Array:
	var r: Array = []
	for p: String in sel.posiciones():
		var corto := p.replace("BOMBA #", "B").replace("1. ", "").replace("2. ", "").replace("3. ", "")
		if corto.length() > 5:
			corto = corto.substr(0, 4)
		r.append(corto)
	return r


func _posicion_selector(sel: SimSelector) -> int:
	return sel.posiciones().find(sel.nombre_posicion())


# --- Dibujo ---

func _draw() -> void:
	var s := escala()
	var cuerpo := _r(3, 3, 98, 176)
	var disparo := tipo() == "motor" and estado_proteccion() == "trip"
	var colores := PiezasAri.CHAPA_OSCURA if tipo() in ["alimentacion", "megohmetro", "mando"] else (PiezasAri.CHAPA_DISPARO if disparo else PiezasAri.CHAPA)
	PiezasAri.chapa(self, cuerpo, s, colores, disparo)
	if marcada:
		DibujoAri.borde(self, cuerpo.grow(2.0 * s), 7.0 * s, Color("38e0e8"), maxf(2.0 * s, 1.5))
	var franja: Color = PiezasAri.FRANJAS.get(str(datos.get("franja", "")), Color(str(datos.get("franja", "#ffd23d"))) if str(datos.get("franja", "")).begins_with("#") else Color("ffd23d"))
	PiezasAri.rotulo(self, _r(17, 6, 70, 15), str(datos.get("titulo", "")), s, franja, 9.5)
	match tipo():
		"alimentacion":
			_dibujar_alimentacion(s)
		"megohmetro":
			_dibujar_megohmetro(s)
		"mando":
			_dibujar_mando(s)
		_:
			_dibujar_motor(s)


func _dibujar_motor(s: float) -> void:
	var i := corriente()
	PiezasAri.amperimetro(self, _r(20, 28, 64, 46), s, i, 0.0, fondo(), nominal())
	PiezasAri.visor(self, _r(48, 77, 38, 13), s, LecturaLcd.numero(i, 0 if fondo() >= 20.0 else 1), "A", Tema.ARI_LCD_AMBAR if i > nominal() * 1.05 else Tema.ARI_LCD_VERDE, 8.5 * s)
	PiezasAri.texto(self, "x̄ 3 fases", _p(18, 86).x, _p(18, 86).y, 5.0 * s, PiezasAri.TEXTO_SUAVE, Tema.PESO_MEDIO, HORIZONTAL_ALIGNMENT_LEFT)
	var marcha := en_marcha()
	if datos.has("marcha") or datos.has("paro"):
		var luz_paro := brillo(str(datos.get("luz_paro", ""))) if datos.has("luz_paro") else (0.0 if marcha else 1.0)
		var paro_pulsado := _pulsado("paro")
		var marcha_pulsada := _pulsado("marcha")
		_boton_luz(_p(20, 104), 7.0 * s, "rojo", luz_paro, paro_pulsado)
		_boton_luz(_p(43, 104), 7.0 * s, "verde", brillo(str(datos.get("luz_marcha", ""))) if datos.has("luz_marcha") else (1.0 if marcha else 0.0), marcha_pulsada)
		PiezasAri.placa(self, _r(9, 115, 22, 7.5), "STOP", s)
		PiezasAri.placa(self, _r(32, 115, 22, 7.5), "START", s)
		if datos.has("selector"):
			_dibujar_selector(_p(31, 153), s)
		else:
			PiezasAri.lampara(self, _p(31, 148), 5.0 * s, "ambar", 1.0 if _falla() else 0.0)
			PiezasAri.texto(self, "FALLA", _p(31, 163).x, _p(31, 163).y, 5.0 * s, PiezasAri.TEXTO_CHAPA)
	else:
		PiezasAri.lampara(self, _p(20, 104), 7.0 * s, "verde", 1.0 if marcha else 0.0)
		PiezasAri.lampara(self, _p(43, 104), 7.0 * s, "ambar", 1.0 if _falla() else 0.0)
		PiezasAri.placa(self, _r(9, 115, 22, 7.5), "MARCHA", s, 4.6)
		PiezasAri.placa(self, _r(32, 115, 22, 7.5), "FALLA", s)
		if datos.has("selector"):
			_dibujar_selector(_p(31, 153), s)
	if datos.has("proteccion"):
		var q := _comp("proteccion")
		var rotulo_caja := "%s · %s A" % [str(datos["proteccion"]), TextoTecnico.numero(float(q.params.get("in_a", q.params.get("ajuste_a", 0.0))), 0)] if q != null else ""
		PiezasAri.interruptor(self, _r(62, 95, 32, 70), s, estado_proteccion(), rotulo_caja)


func _boton_luz(c: Vector2, r: float, color: String, luz: float, pulsado: bool) -> void:
	PiezasAri.lampara(self, c + (Vector2(0, 0.8 * escala()) if pulsado else Vector2.ZERO), r, color, luz)
	if pulsado:
		draw_arc(c, r * 1.42, 0, TAU, 24, Color(1, 1, 1, 0.55), maxf(1.2 * escala(), 1.0), true)


func _pulsado(clave: String) -> bool:
	var c := _comp(clave)
	return c != null and c.estado.get("presionado", false)


func _dibujar_selector(c: Vector2, s: float) -> void:
	var sel := _comp("selector") as SimSelector
	if sel == null:
		return
	PiezasAri.selector(self, c, s, _nombres_selector(sel), _posicion_selector(sel))


func _dibujar_alimentacion(s: float) -> void:
	var q := _comp("componente") as SimSeccionador
	var cerrado := q != null and q.cerrado()
	var placa := _r(25, 32, 54, 54)
	DibujoAri.relleno(self, Rect2(placa.position + Vector2(0, 2) * s, placa.size), 4.0 * s, Color(0, 0, 0, 0.4))
	DibujoAri.degradado(self, placa, 4.0 * s, [Color("ffe680"), Color("e3a800")])
	DibujoAri.borde(self, placa, 4.0 * s, Color("7a5000"), 1.0)
	PiezasAri.texto(self, "0", _p(32, 42).x, _p(32, 42).y, 6.5 * s, Color("2a1a00"))
	PiezasAri.texto(self, "I", _p(72, 42).x, _p(72, 42).y, 6.5 * s, Color("2a1a00"))
	var c := _p(52, 59)
	draw_circle(c, 15.0 * s, Color(0, 0, 0, 0.35))
	PiezasAri._disco(self, c, 13.5 * s, Color("ff8a7a"), Color("7a0f09"))
	var giro := 0.0 if cerrado else -PI / 2.0
	var mango := PackedVector2Array()
	for p: Vector2 in [Vector2(-4.5, -21), Vector2(4.5, -21), Vector2(4.5, 21), Vector2(-4.5, 21)]:
		mango.append(c + (p * s).rotated(giro))
	draw_colored_polygon(mango, Color("d1271b"))
	draw_polyline(mango + PackedVector2Array([mango[0]]), Color("4a0703"), 1.0, true)
	draw_line(c + (Vector2(0, -19) * s).rotated(giro), c + (Vector2(0, -12) * s).rotated(giro), Color.WHITE, maxf(1.6 * s, 1.0), true)
	if q != null and q.estado.get("candado", false):
		PiezasAri.candado(self, _p(70, 74), s)
	var medida: Array = datos.get("medida", [])
	var v := 0.0
	if medida.size() == 2 and sim != null and sim.solucion != null:
		v = sim.solucion.entre(str(medida[0]), str(medida[1])).modulo()
	PiezasAri.visor(self, _r(16, 92, 72, 14), s, LecturaLcd.numero(v, 0), "V", Tema.ARI_LCD_VERDE, 9.0 * s)
	var tierra: Array = datos.get("tierra", [])
	if not tierra.is_empty():
		PiezasAri.texto(self, "LÁMPARAS DE TIERRA", _p(52, 117).x, _p(52, 117).y, 5.0 * s, PiezasAri.TEXTO_SUAVE)
		var nombres := ["L1", "L2", "L3"]
		for i in tierra.size():
			var x := 52.0 + (i - (tierra.size() - 1) / 2.0) * 24.0
			PiezasAri.lampara(self, _p(x, 130), 5.5 * s, "blanco", brillo(str(tierra[i])))
			PiezasAri.texto(self, nombres[i] if i < 3 else "", _p(x, 144).x, _p(x, 144).y, 5.0 * s, PiezasAri.TEXTO_CHAPA)
	if datos.has("test"):
		PiezasAri.boton(self, _p(30, 162), 6.0 * s, s, Color("2fbf4f"), "", _pulsado("test"))
		PiezasAri.texto(self, "TEST", _p(40, 164).x, _p(40, 164).y, 5.0 * s, PiezasAri.TEXTO_CHAPA, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
	# Botón de bloqueo: con el interruptor abierto pone o quita el candado y la tarjeta.
	var loto := _r(62, 154, 30, 16)
	DibujoAri.pieza(self, loto, 3.0 * s, Tema.ARI_AMBAR if not cerrado else [Color("6d7d8c"), Color("4d5d6c"), Color("45556a"), Color("3a4a5c")], DibujoAri.BRILLO, Color("2a1a00"), Color(1, 1, 1, 0.4), 0.3)
	PiezasAri.texto(self, "LOTO", loto.get_center().x, loto.get_center().y + 2.2 * s, 6.0 * s, Tema.ARI_TEXTO_OSCURO if not cerrado else Color("c9d3dc"))


func _dibujar_megohmetro(s: float) -> void:
	var cuerpo := _r(11, 27, 82, 146)
	DibujoAri.relleno(self, Rect2(cuerpo.position + Vector2(0, 2) * s, cuerpo.size), 7.0 * s, Color(0, 0, 0, 0.45))
	DibujoAri.degradado(self, cuerpo, 7.0 * s, [Color("ffe066"), Color("f5c518"), Color("c79400")])
	DibujoAri.borde(self, cuerpo, 7.0 * s, Color("6b4e00"), 1.0)
	var frente := _r(16, 32, 72, 136)
	DibujoAri.degradado(self, frente, 4.0 * s, [Color("3a3f45"), Color("111417")])
	var lectura := str(megger.get("lectura", "----"))
	var color: Color = megger.get("color", Tema.ARI_LCD_AMBAR)
	PiezasAri.visor(self, _r(20, 36, 64, 22), s, lectura, "MΩ", color, 12.0 * s)
	PiezasAri.texto(self, str(megger.get("veredicto", "PULSE TEST")), _p(52, 67).x, _p(52, 67).y, 6.0 * s, color)
	# Motor elegido, con flechas para cambiarlo.
	var motor := str(megger.get("motor", ""))
	PiezasAri.texto(self, "‹", _p(23, 79).x, _p(23, 79).y, 9.0 * s, Color("ffd23d"))
	PiezasAri.texto(self, "›", _p(81, 79).x, _p(81, 79).y, 9.0 * s, Color("ffd23d"))
	PiezasAri.texto(self, motor if not motor.is_empty() else "—", _p(52, 78).x, _p(52, 78).y, 5.6 * s, Color("e8eef3"))
	PiezasAri.texto(self, "FASE → MASA", _p(52, 90).x, _p(52, 90).y, 4.8 * s, Color("ffd23d"))
	var fase := str(megger.get("fase", "U1"))
	for i in 3:
		var f: String = ["U1", "V1", "W1"][i]
		var r := _r(22 + i * 21, 93, 18, 14)
		var elegida := f == fase
		DibujoAri.pieza(self, r, 2.5 * s, Tema.ARI_AMBAR if elegida else Tema.ARI_BOTON, DibujoAri.BRILLO, Color("0d3558"), Color(1, 1, 1, 0.4), 0.3)
		PiezasAri.texto(self, ["R", "S", "T"][i], r.get_center().x, r.get_center().y + 3.0 * s, 8.0 * s, Tema.ARI_TEXTO_OSCURO if elegida else Color.WHITE)
	var tension := int(megger.get("tension", 500))
	var c := _p(36, 140)
	var tensiones := [250, 500, 1000]
	for i in 3:
		var a := deg_to_rad([140.0, 90.0, 40.0][i])
		var q := c + Vector2(cos(a), -sin(a)) * 17.0 * s
		PiezasAri.texto(self, str(tensiones[i]), q.x, q.y + 1.5 * s, 4.8 * s, Color("ffd23d") if tensiones[i] == tension else PiezasAri.TEXTO_CHAPA)
	PiezasAri._disco(self, c, 11.0 * s, Color("ffffff"), Color("2b3238"))
	PiezasAri._disco(self, c, 9.0 * s, Color("5b6168"), Color("050607"))
	var a_sel := deg_to_rad([140.0, 90.0, 40.0][maxi(tensiones.find(tension), 0)])
	draw_line(c, c + Vector2(cos(a_sel), -sin(a_sel)) * 8.0 * s, Color.WHITE, maxf(1.6 * s, 1.0), true)
	PiezasAri.texto(self, "V PRUEBA", c.x, _p(0, 161).y, 4.6 * s, Color("9fb3c4"))
	PiezasAri.boton(self, _p(72, 140), 10.0 * s, s, Color("e2392d"), "TEST", _zona == "test")


func _dibujar_mando(s: float) -> void:
	var elementos: Array = datos.get("elementos", [])
	var y := 30.0
	for e: Dictionary in elementos:
		var c := _comp_id(str(e.get("componente", "")))
		match str(e.get("tipo", "")):
			"selector":
				if c is SimSelector:
					PiezasAri.texto(self, str(e.get("texto", "")), _p(52, y + 6).x, _p(52, y + 6).y, 5.2 * s, PiezasAri.TEXTO_SUAVE)
					PiezasAri.selector(self, _p(52, y + 34), s, _nombres_selector(c as SimSelector), _posicion_selector(c as SimSelector))
				y += 50.0
			"pulsador":
				PiezasAri.boton(self, _p(26, y + 10), 8.0 * s, s, Color(str(e.get("color", "#2fbf4f"))), "", c != null and c.estado.get("presionado", false))
				PiezasAri.texto(self, str(e.get("texto", "")), _p(40, y + 12).x, _p(40, y + 12).y, 5.6 * s, PiezasAri.TEXTO_CHAPA, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
				y += 25.0
			"seta":
				var enclavada: bool = c != null and c.estado.get("enclavada", false)
				PiezasAri.boton(self, _p(26, y + 11), 10.0 * s, s, Color("d1271b"), "", enclavada)
				PiezasAri.texto(self, str(e.get("texto", "EMERGENCIA")), _p(42, y + 10).x, _p(42, y + 10).y, 5.4 * s, PiezasAri.TEXTO_CHAPA, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
				PiezasAri.texto(self, "ENCLAVADA" if enclavada else "LIBRE", _p(42, y + 17).x, _p(42, y + 17).y, 4.6 * s, Color("ff5a4f") if enclavada else PiezasAri.TEXTO_SUAVE, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
				y += 28.0
			"luz":
				PiezasAri.lampara(self, _p(22, y + 8), 5.5 * s, str(e.get("color", "verde")), brillo(str(e.get("componente", ""))))
				PiezasAri.texto(self, str(e.get("texto", "")), _p(34, y + 10).x, _p(34, y + 10).y, 5.6 * s, PiezasAri.TEXTO_CHAPA, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
				y += 18.0
			"lectura":
				var valor := 0.0
				if c != null:
					valor = float(c.estado.get(str(e.get("clave", "")), 0.0))
				PiezasAri.texto(self, str(e.get("texto", "")), _p(52, y + 6).x, _p(52, y + 6).y, 5.2 * s, PiezasAri.TEXTO_SUAVE)
				PiezasAri.visor(self, _r(16, y + 9, 72, 15), s, LecturaLcd.numero(valor, int(e.get("decimales", 1))), str(e.get("unidad", "")), Tema.ARI_LCD_VERDE, 9.5 * s)
				y += 30.0


# --- Toques ---

## Zonas táctiles en la rejilla de diseño: [nombre, centro, radio].
func _zonas() -> Array:
	var z: Array = []
	match tipo():
		"motor":
			if datos.has("paro"):
				z.append(["paro", Vector2(20, 104), 12.0])
			if datos.has("marcha"):
				z.append(["marcha", Vector2(43, 104), 12.0])
			if datos.has("selector"):
				z.append(["selector", Vector2(31, 153), 18.0])
			if datos.has("proteccion"):
				z.append(["proteccion", Vector2(78, 130), 22.0])
			z.append(["elegir", Vector2(52, 13), 14.0])
		"alimentacion":
			z.append(["seccionador", Vector2(52, 59), 26.0])
			if datos.has("test"):
				z.append(["test", Vector2(30, 162), 12.0])
			z.append(["candado", Vector2(77, 162), 14.0])
		"megohmetro":
			z.append(["anterior", Vector2(23, 77), 10.0])
			z.append(["siguiente", Vector2(81, 77), 10.0])
			for i in 3:
				z.append(["fase_" + ["U1", "V1", "W1"][i], Vector2(31 + i * 21, 100), 9.5])
			z.append(["tension", Vector2(36, 140), 16.0])
			z.append(["test", Vector2(72, 140), 14.0])
		"mando":
			var y := 30.0
			var elementos: Array = datos.get("elementos", [])
			for i in elementos.size():
				var e: Dictionary = elementos[i]
				match str(e.get("tipo", "")):
					"selector":
						z.append(["mando_%d" % i, Vector2(52, y + 34), 18.0])
						y += 50.0
					"pulsador":
						z.append(["mando_%d" % i, Vector2(26, y + 10), 12.0])
						y += 25.0
					"seta":
						z.append(["mando_%d" % i, Vector2(26, y + 11), 13.0])
						y += 28.0
					"luz":
						y += 18.0
					"lectura":
						y += 30.0
	return z


## Zona bajo el punto, o "". El radio nunca baja del de un dedo en la pantalla.
func zona_en(punto: Vector2) -> String:
	var mejor := ""
	var distancia := INF
	for z: Array in _zonas():
		var c := _p((z[1] as Vector2).x, (z[1] as Vector2).y)
		var radio := maxf(float(z[2]) * escala(), RADIO_TOQUE)
		var d := punto.distance_to(c)
		if d <= radio and d < distancia:
			distancia = d
			mejor = z[0]
	return mejor


## Las zonas que se mantienen pulsadas: pulsadores, selectores con retorno y el TEST.
func _se_mantiene(zona: String) -> bool:
	if zona in ["marcha", "paro", "test"] and tipo() != "megohmetro":
		return true
	if zona == "selector":
		return true
	if zona.begins_with("mando_"):
		var e: Dictionary = datos.get("elementos", [])[int(zona.trim_prefix("mando_"))]
		return str(e.get("tipo", "")) in ["pulsador", "selector"]
	return false


func _lado(zona: String, punto: Vector2) -> int:
	for z: Array in _zonas():
		if z[0] == zona:
			return -1 if punto.x < _p((z[1] as Vector2).x, 0).x else 1
	return 1


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_zona = zona_en(evento.position)
			_inicio = evento.position
			_tiempo = 0.0
			_mantenido = false
		elif not _zona.is_empty():
			var quieto: bool = evento.position.distance_to(_inicio) <= ZONA_MUERTA
			if _mantenido:
				_emitir_soltar()
			elif quieto:
				if _se_mantiene(_zona):
					_mantenido = true
					accion.emit(self, "pulsar", [_zona, _lado(_zona, _inicio)])
					_soltar_en = DURACION_TOQUE
				else:
					accion.emit(self, _zona, _lado(_zona, _inicio))
			if _soltar_en < 0.0:
				_zona = ""
		queue_redraw()
	elif evento is InputEventMouseMotion and not _zona.is_empty() and not _mantenido:
		if evento.position.distance_to(_inicio) > ZONA_MUERTA:
			_zona = ""


func _emitir_soltar() -> void:
	if _mantenido:
		accion.emit(self, "soltar", [_zona, 0])
	_mantenido = false
	_zona = ""
	_soltar_en = -1.0


## La lista la llama al empezar a desplazarse: el mando no se acciona.
func cancelar_toque() -> void:
	if _mantenido:
		_emitir_soltar()
	_zona = ""


func _process(delta: float) -> void:
	if _soltar_en >= 0.0:
		_soltar_en -= delta
		if _soltar_en < 0.0:
			_soltar_en = -1.0
			_emitir_soltar()
	elif not _zona.is_empty() and not _mantenido and _se_mantiene(_zona):
		_tiempo += delta
		if _tiempo >= ESPERA_PULSAR:
			_mantenido = true
			accion.emit(self, "pulsar", [_zona, _lado(_zona, _inicio)])
	_refresco += delta
	if _refresco >= REFRESCO_S or not _zona.is_empty():
		_refresco = 0.0
		queue_redraw()


func _notification(que: int) -> void:
	if que == NOTIFICATION_MOUSE_EXIT and _mantenido and _soltar_en < 0.0:
		_emitir_soltar()
