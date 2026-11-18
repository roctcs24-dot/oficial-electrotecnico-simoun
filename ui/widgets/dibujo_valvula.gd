class_name DibujoValvula
extends Control
## Válvula dibujada con relieve, de lado y sobre su tubo, en el estado que se le pida: «apertura»
## de 0 (cerrada) a 1 (abierta). Lo que dice el estado se dibuja como a bordo: la maneta en línea
## con el tubo o cruzada, el vástago que asoma por encima del volante, el indicador del actuador
## o la clapeta de la retención. Se dibuja en un espacio de 360 × 260 escalado al tamaño.

const ANCHO := 360.0
const ALTO := 260.0
const Y_TUBO := 178.0
const R_TUBO := 20.0
const TIPOS := ["bola", "mariposa", "macho", "compuerta", "globo", "aguja", "retencion", "tres_vias", "actuada", "seguridad", "reductora"]

const TUBO := [Color("2b3238"), Color("7d8892"), Color("d6dde3"), Color("8a959e"), Color("2b3238")]
const BRONCE := [Color("f1d58a"), Color("c9a24a"), Color("8a6a26"), Color("4f3b12")]
const HIERRO := [Color("6a88a0"), Color("3b5468"), Color("24384a"), Color("142230")]
const ROJO := [Color("ff8a7a"), Color("d02a1e"), Color("8f120b"), Color("5e0f0a")]
const AMARILLO := [Color("fff0a0"), Color("f2cc1a"), Color("b8920a"), Color("6a5200")]
const ACERO := [Color("ffffff"), Color("c9d1d7"), Color("7d8892"), Color("3b444c")]

var tipo := "bola":
	set(valor):
		tipo = valor
		queue_redraw()
var apertura := 1.0:
	set(valor):
		apertura = clampf(valor, 0.0, 1.0)
		queue_redraw()
## En la de tres vías: «b» (de A a B) o «c» (de A a C). En la retención: el sentido del flujo,
## «b» hacia la derecha (la clapeta se abre) o «c» al revés (la clapeta asienta).
var via := "b":
	set(valor):
		via = valor
		queue_redraw()
## Rótulo del servicio en una chapa, como «SW · CHUMACERA»; vacío, sin chapa.
var rotulo := ""
## Mostrar el agua que pasa: en el catálogo y las animaciones, no en el minijuego.
var flujo := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 180)
	resized.connect(queue_redraw)


func _draw() -> void:
	var k := minf(size.x / ANCHO, size.y / ALTO)
	draw_set_transform((size - Vector2(ANCHO, ALTO) * k) / 2.0, 0.0, Vector2(k, k))
	match tipo:
		"seguridad":
			_seguridad()
		"reductora":
			_tubo()
			_reductora()
		_:
			_tubo()
			_cuerpo()
	if not rotulo.is_empty():
		var tam := 11.0
		var w := PiezasAri.ancho_texto(rotulo, tam) + 18.0
		var r := Rect2(ANCHO - w - 6.0, 6.0, w, 22.0)
		DibujoAri.sombra(self, r, 5.0, 0.5, Vector2(0, 2))
		DibujoAri.degradado(self, r, 5.0, [Color("f4f1e6"), Color("dedac9")])
		DibujoAri.borde(self, r, 5.0, Color("6f6a58"), 1.0)
		PiezasAri.texto(self, rotulo, r.get_center().x, r.get_center().y + 4.0, tam, Color("20262c"), Tema.PESO_NEGRITA)
	draw_set_transform(Vector2.ZERO)


# --- Piezas ---

func _barra(r: Rect2, colores: Array, radio := 3.0, horizontal := true) -> void:
	DibujoAri.relleno(self, Rect2(r.position + Vector2(0, 3), r.size), radio, Color(0, 0, 0, 0.35))
	if horizontal:
		DibujoAri.degradado(self, r, radio, colores)
	else:
		# Degradado de izquierda a derecha: se dibujan franjas verticales.
		var n := colores.size() - 1
		for i in n:
			var x0 := r.position.x + r.size.x * i / n
			var franja := Rect2(x0, r.position.y, r.size.x / n + 0.5, r.size.y)
			draw_rect(franja, (colores[i] as Color).lerp(colores[i + 1], 0.5))
		DibujoAri.borde(self, r, radio, Color(0, 0, 0, 0.5), 1.0)


func _tubo() -> void:
	var r := Rect2(0, Y_TUBO - R_TUBO, ANCHO, R_TUBO * 2.0)
	DibujoAri.degradado(self, r, 0.0, TUBO)
	if flujo:
		var paso := _paso()
		if paso > 0.02:
			var h := R_TUBO * 1.3 * paso
			var agua := Rect2(0, Y_TUBO - h / 2.0, ANCHO, h)
			draw_rect(agua, Color(0.18, 0.56, 0.84, 0.55))
			var t := fmod(Time.get_ticks_msec() / 1000.0 * 40.0, 30.0)
			var x := t
			while x < ANCHO:
				DibujoAri.galon(self, Vector2(x, Y_TUBO), 6.0, 1 if via == "b" or tipo != "retencion" else -1, Color(1, 1, 1, 0.75), 2.0)
				x += 30.0
			queue_redraw()


## Paso relativo para el agua: la apertura, o la retención según el sentido.
func _paso() -> float:
	if tipo == "retencion":
		return 1.0 if via == "b" else 0.0
	if tipo == "tres_vias":
		return 1.0
	return apertura


func _brida(x: float) -> void:
	var r := Rect2(x - 8.0, Y_TUBO - 46.0, 16.0, 92.0)
	_barra(r, HIERRO, 3.0)
	for dy: float in [-33.0, 33.0]:
		PiezasAri._disco(self, Vector2(x, Y_TUBO + dy), 4.0, Color.WHITE, Color("3b444c"))


func _volante(c: Vector2, r: float) -> void:
	PiezasAri._elipse(self, c + Vector2(0, 4), Vector2(r, r * 0.26), 0.0, Color(0, 0, 0, 0.45))
	PiezasAri._elipse(self, c, Vector2(r, r * 0.26), 0.0, ROJO[3])
	PiezasAri._elipse(self, c - Vector2(0, 2), Vector2(r - 2.0, r * 0.26 - 2.0), 0.0, ROJO[1])
	PiezasAri._elipse(self, c - Vector2(0, 2), Vector2(r * 0.7, r * 0.17), 0.0, ROJO[3])
	PiezasAri._elipse(self, c - Vector2(0, 3), Vector2(r * 0.66, r * 0.14), 0.0, ROJO[1])
	PiezasAri._elipse(self, c + Vector2(-r * 0.3, -r * 0.12), Vector2(r * 0.35, r * 0.05), 0.0, Color(1, 1, 1, 0.35))


## Vástago roscado de «largo» que sale hacia arriba desde «y_base».
func _vastago(x: float, y_base: float, largo: float) -> void:
	var r := Rect2(x - 5.0, y_base - largo, 10.0, largo)
	_barra(r, ACERO, 2.0, false)
	var y := r.position.y + 3.0
	while y < r.end.y - 2.0:
		draw_line(Vector2(x - 5.0, y), Vector2(x + 5.0, y + 2.0), Color("2b3238"), 1.0)
		y += 6.0


## Maneta de cuarto de vuelta: con la apertura en 1 va en línea con el tubo y en 0, cruzada
## (de frente al que mira, se ve como un óvalo).
func _maneta(eje: Vector2, largo: float, colores: Array = ROJO) -> void:
	var a := (1.0 - apertura) * PI / 2.0
	var visible_x := cos(a) * largo
	PiezasAri._disco(self, eje, 9.0, Color.WHITE, Color("3b444c"))
	if visible_x > 14.0:
		var r := Rect2(eje.x - 6.0, eje.y - 8.0, visible_x + 6.0, 16.0)
		_barra(r, colores, 7.0)
		DibujoAri.relleno(self, Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 10.0, 4.0)), 2.0, Color(1, 1, 1, 0.35))
	else:
		var alto := 12.0 + sin(a) * 16.0
		PiezasAri._elipse(self, eje + Vector2(0, 3), Vector2(15.0, alto), 0.0, Color(0, 0, 0, 0.4))
		PiezasAri._elipse(self, eje, Vector2(15.0, alto), 0.0, colores[2])
		PiezasAri._elipse(self, eje - Vector2(1, 2), Vector2(12.0, alto - 3.0), 0.0, colores[1])
		PiezasAri._elipse(self, eje + Vector2(-4, -alto * 0.4), Vector2(5.0, alto * 0.3), 0.0, Color(1, 1, 1, 0.3))
	PiezasAri._disco(self, eje, 6.0, Color.WHITE, Color("3b444c"))


func _cuerpo() -> void:
	var c := Vector2(ANCHO / 2.0, Y_TUBO)
	match tipo:
		"bola", "tres_vias", "actuada":
			_brida(c.x - 66.0)
			_brida(c.x + 66.0)
			if tipo == "tres_vias":
				# Tercera boca hacia abajo, la C.
				_barra(Rect2(c.x - 18.0, c.y + 20.0, 36.0, ALTO - c.y - 20.0), TUBO, 0.0, false)
				_barra(Rect2(c.x - 40.0, c.y + 52.0, 80.0, 14.0), HIERRO, 3.0)
			var cuerpo := Rect2(c.x - 56.0, c.y - 36.0, 112.0, 72.0)
			DibujoAri.sombra(self, cuerpo, 20.0, 0.5, Vector2(0, 4))
			DibujoAri.degradado(self, cuerpo, 20.0, BRONCE)
			DibujoAri.relleno(self, Rect2(cuerpo.position + Vector2(8, 6), Vector2(cuerpo.size.x - 16.0, 14.0)), 7.0, Color(1, 1, 1, 0.25))
			_barra(Rect2(c.x - 12.0, c.y - 62.0, 24.0, 28.0), BRONCE, 4.0)
			if tipo == "actuada":
				_actuador(Vector2(c.x, c.y - 62.0))
			elif tipo == "tres_vias":
				_letras_tres_vias(c)
				_maneta_tres_vias(Vector2(c.x, c.y - 64.0))
			else:
				_maneta(Vector2(c.x, c.y - 64.0), 110.0)
		"mariposa":
			_brida(c.x - 26.0)
			_brida(c.x + 26.0)
			var cuerpo := Rect2(c.x - 18.0, c.y - 54.0, 36.0, 108.0)
			_barra(cuerpo, HIERRO, 8.0, false)
			_barra(Rect2(c.x - 10.0, c.y - 92.0, 20.0, 40.0), HIERRO, 3.0, false)
			# Sector dentado donde se traba la maneta.
			draw_arc(Vector2(c.x, c.y - 92.0), 34.0, -PI, 0.0, 16, Color("8a959e"), 4.0, true)
			for i in 7:
				var ang := -PI + PI * i / 6.0
				var p := Vector2(c.x, c.y - 92.0) + Vector2(cos(ang), sin(ang)) * 34.0
				draw_circle(p, 2.2, Color("3b444c"))
			_maneta(Vector2(c.x, c.y - 94.0), 120.0)
		"macho":
			_brida(c.x - 60.0)
			_brida(c.x + 60.0)
			var cuerpo := PackedVector2Array([c + Vector2(-50, -30), c + Vector2(-30, -48), c + Vector2(30, -48), c + Vector2(50, -30), c + Vector2(50, 30), c + Vector2(-50, 30)])
			draw_colored_polygon(cuerpo, HIERRO[1])
			Relieve.poligono_degradado(self, cuerpo, HIERRO, c + Vector2(0, -48), c + Vector2(0, 30))
			# Cabeza cuadrada con la ranura que marca el paso.
			var cabeza := Rect2(c.x - 18.0, c.y - 78.0, 36.0, 30.0)
			_barra(cabeza, ACERO, 3.0)
			var cen := cabeza.get_center() - Vector2(0, 2)
			var a := (1.0 - apertura) * PI / 2.0
			var d := Vector2(cos(a), sin(a) * 0.45) * 15.0
			draw_line(cen - d, cen + d, Color("1b2228"), 4.0, true)
		"compuerta", "globo":
			_brida(c.x - 62.0)
			_brida(c.x + 62.0)
			if tipo == "compuerta":
				var cuerpo := Rect2(c.x - 52.0, c.y - 40.0, 104.0, 80.0)
				_barra(cuerpo, HIERRO, 10.0)
				_barra(Rect2(c.x - 28.0, c.y - 114.0, 56.0, 78.0), HIERRO, 10.0, false)
			else:
				PiezasAri._elipse(self, c + Vector2(0, 5), Vector2(56, 44), 0.0, Color(0, 0, 0, 0.4))
				PiezasAri._disco(self, c, 50.0, HIERRO[0], HIERRO[3], Vector2(-0.3, -0.4), 10)
				_barra(Rect2(c.x - 22.0, c.y - 110.0, 44.0, 66.0), HIERRO, 8.0, false)
			_barra(Rect2(c.x - 36.0, c.y - 44.0, 72.0, 10.0), HIERRO, 3.0)
			var tope := c.y - (116.0 if tipo == "compuerta" else 112.0)
			var largo := 12.0 + apertura * (52.0 if tipo == "compuerta" else 34.0)
			_vastago(c.x, tope + 4.0, largo)
			_volante(Vector2(c.x, tope + 2.0), 54.0 if tipo == "compuerta" else 42.0)
		"aguja":
			_brida(c.x - 44.0)
			_brida(c.x + 44.0)
			var cuerpo := Rect2(c.x - 34.0, c.y - 30.0, 68.0, 60.0)
			_barra(cuerpo, ACERO, 6.0)
			_barra(Rect2(c.x - 12.0, c.y - 74.0, 24.0, 46.0), ACERO, 4.0, false)
			_vastago(c.x, c.y - 72.0, 10.0 + apertura * 22.0)
			var y_t := c.y - 82.0 - apertura * 22.0
			_barra(Rect2(c.x - 30.0, y_t - 6.0, 60.0, 12.0), [Color("444c55"), Color("1e2328"), Color("0b0e10")], 5.0)
		"retencion":
			_brida(c.x - 62.0)
			_brida(c.x + 62.0)
			var cuerpo := Rect2(c.x - 52.0, c.y - 42.0, 104.0, 84.0)
			_barra(cuerpo, HIERRO, 14.0)
			_barra(Rect2(c.x - 34.0, c.y - 58.0, 68.0, 18.0), HIERRO, 4.0)
			for dx: float in [-26.0, 26.0]:
				PiezasAri._disco(self, Vector2(c.x + dx, c.y - 49.0), 4.0, Color.WHITE, Color("3b444c"))
			# Flecha fundida en el cuerpo: el único sentido en que deja pasar.
			var f0 := Vector2(c.x - 30.0, c.y + 4.0)
			var f1 := Vector2(c.x + 30.0, c.y + 4.0)
			draw_line(f0 + Vector2(0, 1.5), f1 + Vector2(0, 1.5), Color(1, 1, 1, 0.25), 6.0)
			draw_line(f0, f1, Color("142230"), 6.0)
			draw_colored_polygon(PackedVector2Array([f1 + Vector2(10, 0), f1 + Vector2(-6, -10), f1 + Vector2(-6, 10)]), Color("142230"))


func _actuador(base: Vector2) -> void:
	var caja := Rect2(base.x - 52.0, base.y - 62.0, 104.0, 56.0)
	_barra(caja, [Color("5e8fcf"), Color("2c63a8"), Color("1c4a85"), Color("10305a")], 6.0)
	DibujoAri.relleno(self, Rect2(caja.position + Vector2(6, 5), Vector2(caja.size.x - 12.0, 10.0)), 4.0, Color(1, 1, 1, 0.22))
	for dx: float in [-40.0, 40.0]:
		PiezasAri._disco(self, Vector2(base.x + dx, caja.get_center().y), 6.0, Color.WHITE, Color("3b444c"))
	# Indicador de posición: cúpula amarilla con la flecha en el sentido del paso si está abierta.
	var c := Vector2(base.x, caja.position.y - 12.0)
	PiezasAri._elipse(self, c + Vector2(0, 3), Vector2(28, 13), 0.0, Color(0, 0, 0, 0.4))
	PiezasAri._elipse(self, c, Vector2(28, 13), 0.0, AMARILLO[2])
	PiezasAri._elipse(self, c - Vector2(0, 2), Vector2(25, 11), 0.0, AMARILLO[1])
	var a := (1.0 - apertura) * PI / 2.0
	var d := Vector2(cos(a), sin(a) * 0.45) * 20.0
	draw_line(c - d, c + d, Color("1b2228"), 4.0, true)
	draw_colored_polygon(PackedVector2Array([c + d * 1.25, c + d * 0.7 + d.orthogonal().normalized() * 6.0, c + d * 0.7 - d.orthogonal().normalized() * 6.0]), Color("1b2228"))
	PiezasAri.texto(self, "OPEN" if apertura > 0.95 else ("SHUT" if apertura < 0.05 else ""), c.x + 46.0, c.y + 4.0, 11.0, Color("f2cc1a"), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)


func _letras_tres_vias(c: Vector2) -> void:
	for par: Array in [["A", Vector2(c.x - 100.0, c.y - 30.0)], ["B", Vector2(c.x + 100.0, c.y - 30.0)], ["C", Vector2(c.x + 34.0, c.y + 76.0)]]:
		var p: Vector2 = par[1]
		PiezasAri._disco(self, p, 11.0, Color("f4f1e6"), Color("b8b3a0"))
		PiezasAri.texto(self, par[0], p.x, p.y + 4.5, 13.0, Color("20262c"), Tema.PESO_NEGRITA)


## Tres vías con bola en L: la maneta apunta a la boca que se une con la A.
func _maneta_tres_vias(eje: Vector2) -> void:
	PiezasAri._disco(self, eje, 9.0, Color.WHITE, Color("3b444c"))
	if via == "b":
		var r := Rect2(eje.x - 6.0, eje.y - 8.0, 106.0, 16.0)
		_barra(r, ROJO, 7.0)
	else:
		# Hacia la boca C, abajo: se ve de frente, como un óvalo.
		PiezasAri._elipse(self, eje + Vector2(0, 3), Vector2(15.0, 26.0), 0.0, Color(0, 0, 0, 0.4))
		PiezasAri._elipse(self, eje + Vector2(0, 8), Vector2(15.0, 26.0), 0.0, ROJO[2])
		PiezasAri._elipse(self, eje + Vector2(-1, 6), Vector2(12.0, 23.0), 0.0, ROJO[1])
	PiezasAri._disco(self, eje, 6.0, Color.WHITE, Color("3b444c"))


func _seguridad() -> void:
	# Válvula de seguridad de resorte, vertical, con la salida a un lado y la palanca de prueba.
	var x := ANCHO / 2.0
	_barra(Rect2(x - 20.0, 200.0, 40.0, ALTO - 200.0), TUBO, 0.0, false)
	_barra(Rect2(x - 44.0, 192.0, 88.0, 14.0), HIERRO, 3.0)
	var cuerpo := Rect2(x - 40.0, 138.0, 80.0, 58.0)
	_barra(cuerpo, BRONCE, 12.0)
	_barra(Rect2(x + 36.0, 150.0, ANCHO - x - 36.0, 34.0), TUBO, 0.0)
	_barra(Rect2(x - 22.0, 40.0, 44.0, 100.0), BRONCE, 8.0, false)
	# Resorte visto por la ventana del bonete.
	DibujoAri.relleno(self, Rect2(x - 12.0, 52.0, 24.0, 76.0), 4.0, Color("1b2228"))
	var y := 56.0
	while y < 124.0:
		draw_line(Vector2(x - 10.0, y), Vector2(x + 10.0, y + 5.0), Color("c9d1d7"), 2.0, true)
		y += 7.0
	_barra(Rect2(x - 6.0, 24.0, 12.0, 18.0), ACERO, 2.0)
	_barra(Rect2(x - 6.0, 26.0, 70.0, 8.0), ACERO, 4.0)
	PiezasAri.texto(self, "SET 7 bar", x - 30.0, 102.0, 10.0, Color("20262c"), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)


func _reductora() -> void:
	var c := Vector2(ANCHO / 2.0, Y_TUBO)
	_brida(c.x - 62.0)
	_brida(c.x + 62.0)
	var cuerpo := Rect2(c.x - 52.0, c.y - 38.0, 104.0, 76.0)
	_barra(cuerpo, BRONCE, 14.0)
	# Cúpula del resorte y tornillo de ajuste.
	PiezasAri._elipse(self, Vector2(c.x, c.y - 54.0) + Vector2(0, 4), Vector2(46, 22), 0.0, Color(0, 0, 0, 0.4))
	PiezasAri._disco(self, Vector2(c.x, c.y - 70.0), 40.0, BRONCE[0], BRONCE[3], Vector2(-0.3, -0.5), 10)
	_barra(Rect2(c.x - 6.0, c.y - 132.0, 12.0, 26.0), ACERO, 2.0, false)
	_barra(Rect2(c.x - 18.0, c.y - 112.0, 36.0, 8.0), [Color("444c55"), Color("1e2328")], 3.0)
	# Manómetro de aguas abajo.
	var m := Vector2(c.x + 96.0, c.y - 64.0)
	_barra(Rect2(m.x - 4.0, m.y, 8.0, 46.0), ACERO, 2.0, false)
	PiezasAri._disco(self, m, 22.0, Color.WHITE, Color("3b444c"))
	draw_circle(m, 18.0, Color("fbfaf3"))
	draw_line(m, m + Vector2(cos(-0.8), sin(-0.8)) * 14.0, Color("d02a1e"), 2.0, true)
	PiezasAri.texto(self, "bar", m.x, m.y + 12.0, 8.0, Color("20262c"), Tema.PESO_NEGRITA)
