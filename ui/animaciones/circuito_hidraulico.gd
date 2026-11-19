extends Animacion
## Circuito hidráulico básico animado con SimHidraulica: bomba de engranajes, válvula de alivio,
## manómetro, direccional 4/3 de centro cerrado con bobinas Y1 e Y2 y un cilindro de doble
## efecto (o un motor hidráulico). Según «foco», añade la estranguladora con antirretorno en la
## salida del cilindro o la antirretorno pilotada que sostiene la carga, y cambia el mando que se
## ajusta: el tarado del alivio, la apertura de la estranguladora, la carga o el par.
## Parámetros: "foco" (alivio, cilindro, motor, estranguladora, pilotada), "carga" (kN), "par"
## (N·m), "tarado" (bar), "posicion" inicial (-1, 0, 1).

const ANCHO := 460.0
const ALTO := 232.0
const CARRERA := 250.0  # mm

var foco := "alivio"
var posicion := 0
var tarado := 160.0
var carga := 20.0
var par := 150.0
var apertura := 1.0
var asiento_danado := false
## Posición del vástago: 0 dentro, 1 fuera.
var x := 0.3
var resultado := {}
var _giro_bomba := 0.0
var _giro_motor := 0.0
var _flujo := 0.0
var _corredera := 0.0
var _botones := {}
var _presion: Label
var _movimiento: Label
var _alivio: Label
var _danado: Button


func preparar() -> void:
	foco = str(params.get("foco", foco))
	tarado = float(params.get("tarado", tarado))
	carga = float(params.get("carga", carga))
	par = float(params.get("par", par))
	posicion = int(params.get("posicion", 0))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for clave in [1, 0, -1]:
		_botones[clave] = boton_mando(fila, _mandar.bind(clave))
	match foco:
		"alivio":
			var v := fila_valor(c, "Tarado del alivio")
			barra(c, 40.0, 200.0, 5.0, tarado, func(n: float) -> void:
				tarado = n
				v.text = "%d bar" % roundi(n))
			v.text = "%d bar" % roundi(tarado)
		"estranguladora":
			var v := fila_valor(c, "Apertura de la estranguladora")
			barra(c, 5.0, 100.0, 5.0, apertura * 100.0, func(n: float) -> void:
				apertura = n / 100.0
				v.text = "%d %%" % roundi(n))
			v.text = "%d %%" % roundi(apertura * 100.0)
		"motor":
			var v := fila_valor(c, "Par que pide el winche")
			barra(c, 0.0, 400.0, 10.0, par, func(n: float) -> void:
				par = n
				v.text = "%d N·m" % roundi(n))
			v.text = "%d N·m" % roundi(par)
		_:
			var v := fila_valor(c, "Carga del cilindro")
			barra(c, 0.0, 60.0, 1.0, carga, func(n: float) -> void:
				carga = n
				v.text = "%d kN" % roundi(n))
			v.text = "%d kN" % roundi(carga)
	if foco == "pilotada":
		_danado = boton_mando(c, func() -> void:
			asiento_danado = not asiento_danado
			_actualizar_botones())
	_presion = fila_valor(c, "Manómetro de la bomba")
	_movimiento = fila_valor(c, "Velocidad" if foco != "motor" else "Giro del motor")
	_alivio = fila_valor(c, "Caudal por el alivio")
	_actualizar_botones()
	resolver()


func _mandar(p: int) -> void:
	posicion = p
	_actualizar_botones()


func _actualizar_botones() -> void:
	_botones[1].text = "Y1 · avanza" if foco != "motor" else "Y1 · vira"
	_botones[0].text = "Sin tensión"
	_botones[-1].text = "Y2 · retrocede" if foco != "motor" else "Y2 · arría"
	for clave: int in _botones:
		_botones[clave].modulate = Color(1.0, 0.85, 0.4) if clave == posicion else Color.WHITE
	if _danado != null:
		_danado.text = "Asiento reparado" if asiento_danado else "Dañar el asiento de la pilotada"


func parametros() -> Dictionary:
	var a_tope := (posicion > 0 and x >= 1.0) or (posicion < 0 and x <= 0.0)
	var p := {
		"alivio": {"tarado": tarado},
		"direccional": {"posicion": posicion},
		"actuador": {"tipo": "motor" if foco == "motor" else "cilindro", "carga": carga, "par": par, "a_tope": a_tope and foco != "motor"},
		"estrangulador": {"presente": foco == "estranguladora", "apertura": apertura},
		"pilotada": {"presente": foco == "pilotada", "asiento_danado": asiento_danado},
	}
	return p


func resolver() -> Dictionary:
	resultado = SimHidraulica.resolver(parametros())
	return resultado


func fase() -> int:
	var estado := str(resultado.get("estado", ""))
	if estado in ["tope", "atascado"]:
		return 3
	if estado in ["avanza", "retrocede", "gira"]:
		return 2
	return 1


func _process(delta: float) -> void:
	resolver()
	var v := float(resultado.get("velocidad", 0.0))
	if resultado.get("estado", "") == "avanza":
		x = minf(x + v / CARRERA * delta, 1.0)
	elif resultado.get("estado", "") == "retrocede":
		x = maxf(x - v / CARRERA * delta, 0.0)
	elif resultado.get("estado", "") == "centro":
		# La deriva real es de milímetros por minuto: se acelera ×30 para que se vea.
		x = maxf(x - float(resultado.get("deriva", 0.0)) * 30.0 / 60.0 / CARRERA * delta, 0.0)
	_giro_bomba += delta * 6.0
	_giro_motor += float(resultado.get("rpm", 0.0)) / 60.0 * TAU * delta * 0.15 * signf(posicion)
	_flujo += delta * 40.0
	_corredera = move_toward(_corredera, float(posicion), delta * 4.0)
	if _presion != null:
		_presion.text = "%d bar" % roundi(resultado.get("P", 0.0))
		if foco == "motor":
			_movimiento.text = "%d rpm" % roundi(resultado.get("rpm", 0.0))
		elif resultado.get("estado", "") == "centro":
			_movimiento.text = "deriva %s mm/min" % coma(resultado.get("deriva", 0.0), 1)
		else:
			_movimiento.text = "%d mm/s" % roundi(v)
		_alivio.text = "%s L/min" % coma(resultado.get("Q_alivio", 0.0), 1)
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoHidraulico.FONDO)
	var r := resultado
	var q_alivio := float(r.get("Q_alivio", 0.0))
	var moviendo := str(r.get("estado", "")) in ["avanza", "retrocede", "gira"]
	var f := _flujo
	# Líneas: presión de la bomba a P, alivio a tanque, A y B, T a tanque.
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(80, 108), Vector2(80, 64), Vector2(232, 64), Vector2(232, 196), Vector2(283, 196), Vector2(283, 166)]), "presion", f)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(150, 150), Vector2(150, 190)]), "retorno" if q_alivio > 0.05 else "", f)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(317, 166), Vector2(317, 180), Vector2(196, 180), Vector2(196, 190)]), "retorno" if moviendo else "", f)
	var papel_a := ""
	var papel_b := ""
	if posicion > 0:
		papel_a = "trabajo" if moviendo else "presion"
		papel_b = "retorno" if moviendo else ""
	elif posicion < 0:
		papel_a = "retorno" if moviendo else ""
		papel_b = "trabajo" if moviendo else "presion"
	var ya := 58.0 if foco != "motor" else 46.0
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(283, 134), Vector2(283, ya)]), papel_a, f if moviendo and posicion > 0 else (-f if moviendo else -1.0))
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(317, 134), Vector2(317, 104), Vector2(396, 104), Vector2(396, ya)]), papel_b, f if moviendo and posicion < 0 else (-f if moviendo else -1.0))
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(210, 64), Vector2(210, 52)]), "presion", -1.0, 6.0)
	# Tanque, motor eléctrico y bomba.
	DibujoHidraulico.tanque(l, fuente, Rect2(14, 190, 210, 34))
	DibujoHidraulico.pieza(l, Rect2(18, 116, 30, 28), 5.0, [Color("6fae7c"), Color("2f7a43"), Color("174024")])
	texto(Vector2(33, 130), "M", 13, Color.WHITE)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(80, 190), Vector2(80, 152)]), "retorno", f, 10.0)
	DibujoHidraulico.bomba(l, Vector2(80, 130), _giro_bomba, 0.9)
	# Alivio: muelle y asiento; brilla cuando abre.
	_alivio_dibujo(l, Vector2(150, 108), q_alivio > 0.05)
	DibujoHidraulico.manometro(l, fuente, Vector2(210, 30), 20.0, float(r.get("P", 0.0)), 250.0)
	_direccional(l, Vector2(300, 150))
	if foco == "motor":
		_motor(l, fuente)
	else:
		_cilindro(l, fuente)
	if foco == "estranguladora":
		_estranguladora(l, Vector2(356, 104))
	if foco == "pilotada":
		_pilotada(l, Vector2(283, 112))
	var estado := str(r.get("estado", ""))
	var aviso := {"tope": "A TOPE: TODO EL CAUDAL SALE POR EL ALIVIO", "atascado": "LA CARGA PIDE MÁS DEL TARADO: NO SE MUEVE", "centro": "CENTRO CERRADO: EL ALIVIO DESCARGA LA BOMBA"}
	if aviso.has(estado):
		DibujoHidraulico.rotulo(l, fuente, Vector2(ANCHO / 2.0 + 20.0, 218.0), aviso[estado], 10, Color("ffb020"))


func _alivio_dibujo(l: Control, c: Vector2, abierta: bool) -> void:
	if abierta:
		l.draw_circle(c + Vector2(0, 14), 26.0, Color(1.0, 0.69, 0.0, 0.25))
	DibujoHidraulico.pieza(l, Rect2(c.x - 4, c.y - 44, 8, 10), 2.0)
	DibujoHidraulico.pieza(l, Rect2(c.x - 12, c.y - 34, 24, 44), 4.0)
	DibujoAri.relleno(l, Rect2(c.x - 7, c.y - 30, 14, 30), 2.0, Color("20262c"))
	var sube := 5.0 if abierta else 0.0
	var muelle := PackedVector2Array()
	for i in 9:
		muelle.append(Vector2(c.x + (6.0 if i % 2 else -6.0), c.y - 28.0 + i * (26.0 - sube) / 8.0))
	l.draw_polyline(muelle, Color("e8c43a"), 2.0, true)
	DibujoHidraulico.pieza(l, Rect2(c.x - 18, c.y + 10, 36, 32), 4.0)
	l.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 6, c.y + 2 - sube), Vector2(c.x + 6, c.y + 2 - sube), Vector2(c.x, c.y + 10 - sube)]), Color("c9d1d6"))
	texto(Vector2(c.x - 34, c.y - 20), "ALIVIO", 9, Color("ffd08a"))
	texto(Vector2(c.x - 34, c.y - 8), "%d bar" % roundi(tarado), 9, Color("cfd8df"))


func _direccional(l: Control, c: Vector2) -> void:
	var cuerpo := Rect2(c.x - 50, c.y - 16, 100, 32)
	DibujoHidraulico.pieza(l, cuerpo, 4.0)
	# Ventana con la corredera, que se desplaza hacia la bobina que tira.
	DibujoAri.relleno(l, Rect2(c.x - 40, c.y - 5, 80, 10), 3.0, Color("20262c"))
	var dx := -_corredera * 12.0
	for k in 3:
		DibujoAri.relleno(l, Rect2(c.x - 34 + k * 26 + dx, c.y - 4, 16, 8), 2.0, Color("dfe5e9"))
	for lado in [-1, 1]:
		var activa: bool = (lado < 0 and posicion > 0) or (lado > 0 and posicion < 0)
		var b := Rect2(c.x + (-50 - 34 if lado < 0 else 50), c.y - 13, 34, 26)
		if activa:
			l.draw_rect(b.grow(5.0), Color(1.0, 0.69, 0.0, 0.3))
		DibujoAri.pieza(l, b, 4.0, [Color("3a3f44"), Color("1c2024"), Color("0b0d0f")], [], DibujoHidraulico.CONTORNO)
		texto(b.get_center(), "Y1" if lado < 0 else "Y2", 11, Color("ffc23a") if activa else Color("cfd8df"))


func _cilindro(l: Control, fuente: Font) -> void:
	var cuerpo := Rect2(268, 34, 140, 26)
	var vastago := 14.0 + x * 34.0
	DibujoAri.pieza(l, Rect2(cuerpo.end.x - 4, cuerpo.position.y + 8, vastago, 10), 3.0, [Color("ffffff"), Color("cfd6db"), Color("7d868d")], [], DibujoHidraulico.CONTORNO)
	DibujoHidraulico.pieza(l, cuerpo, 5.0, DibujoHidraulico.PINTURA)
	# Pistón dentro, visto por una ventana.
	var px := cuerpo.position.x + 14.0 + x * (cuerpo.size.x - 34.0)
	DibujoAri.relleno(l, Rect2(px, cuerpo.position.y + 4, 6, cuerpo.size.y - 8), 1.0, Color("dfe5e9"))
	var bloque := Rect2(cuerpo.end.x + vastago - 4, cuerpo.position.y - 6, 26, 38)
	DibujoAri.pieza(l, bloque, 3.0, [Color("8a949b"), Color("4a5257"), Color("2a2f33")], [], DibujoHidraulico.CONTORNO)
	texto(bloque.get_center(), "%d kN" % roundi(carga), 9, Color.WHITE)
	texto(Vector2(cuerpo.position.x + 40, 22), "A", 11, Color("ffc23a"))
	texto(Vector2(396 + 12, 72), "B", 11, Color("ffc23a"))


func _motor(l: Control, fuente: Font) -> void:
	var c := Vector2(340, 40)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(283, 46), Vector2(316, 46)]), "", -1.0)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(396, 46), Vector2(364, 46)]), "", -1.0)
	DibujoHidraulico.pieza(l, Rect2(c.x - 26, c.y - 26, 52, 52), 10.0, DibujoHidraulico.PINTURA)
	l.draw_circle(c, 16.0, Color("2a2f33"))
	for k in 6:
		var a := _giro_motor + k * TAU / 6.0
		l.draw_line(c, c + Vector2.from_angle(a) * 14.0, Color("c9d1d6"), 3.0, true)
	# Tambor del winche al lado.
	DibujoAri.pieza(l, Rect2(c.x + 54, c.y - 22, 40, 44), 4.0, [Color("8a949b"), Color("4a5257"), Color("2a2f33")], [], DibujoHidraulico.CONTORNO)
	for k in 4:
		var y := c.y - 16 + fposmod(_giro_motor * 6.0 + k * 9.0, 36.0)
		l.draw_line(Vector2(c.x + 56, y), Vector2(c.x + 92, y), Color("c9a13a"), 2.0)
	texto(Vector2(c.x, c.y + 38), "%d rpm · %d N·m" % [roundi(resultado.get("rpm", 0.0)), roundi(par)], 10, Color("cfd8df"))


func _estranguladora(l: Control, c: Vector2) -> void:
	DibujoHidraulico.pieza(l, Rect2(c.x - 22, c.y - 10, 44, 20), 4.0)
	DibujoAri.pieza(l, Rect2(c.x - 10, c.y - 26, 20, 16), 3.0, [Color("545a5f"), Color("2a2e32"), Color("101214")], [], DibujoHidraulico.CONTORNO)
	var hueco := 2.0 + 6.0 * apertura
	DibujoAri.relleno(l, Rect2(c.x - 3, c.y - hueco / 2.0, 6, hueco), 1.0, DibujoHidraulico.ACEITE)
	texto(Vector2(c.x, c.y + 20), "estranguladora %d %%" % roundi(apertura * 100.0), 9, Color("ffd08a"))


func _pilotada(l: Control, c: Vector2) -> void:
	DibujoHidraulico.pieza(l, Rect2(c.x - 14, c.y - 14, 28, 28), 4.0)
	l.draw_circle(c, 6.0, Color("ff7a5a") if asiento_danado else Color("dfe5e9"))
	# Piloto de trazos desde la línea B.
	var p0 := Vector2(c.x + 14, c.y)
	var p1 := Vector2(317, c.y)
	var n := 6
	for i in n:
		l.draw_line(p0.lerp(p1, float(i) / n), p0.lerp(p1, (i + 0.5) / n), Color("ffd08a"), 2.0)
	texto(Vector2(c.x - 34, c.y), "pilotada", 9, Color("ffd08a"))
