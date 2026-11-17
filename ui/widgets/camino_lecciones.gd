class_name CaminoLecciones
extends ControlToque
## Camino de lecciones de un módulo de la Escuela: una moneda por lección (y por examen) unidas
## por un surco que se rellena con el color del módulo a medida que se avanza. Va en serpentina:
## de izquierda a derecha y, en la fila siguiente, de vuelta. Ninguna lección queda cerrada; la
## siguiente recomendada brilla en ámbar.

signal paso_tocado(indice: int)

const PASO_MIN := 76.0
## Si todas las monedas caben en una fila con este paso, el camino va en una sola fila.
const PASO_UNA_FILA := 62.0
const ALTO_FILA := 100.0
const RADIO := 21.0
const RADIO_ACTUAL := 25.0
const ONDA := 7.0
const ARRIBA := 38.0

## [{tipo: «leccion» o «examen», titulo, hecho}].
var pasos: Array = []
var color := Tema.ACENTO
var _tocado := -1


func _init() -> void:
	super()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(func() -> void:
		update_minimum_size()
		queue_redraw())


func iniciar(p_pasos: Array, p_color: Color) -> void:
	pasos = p_pasos
	color = p_color
	update_minimum_size()
	queue_redraw()


## Primer paso sin hacer, o -1 si están todos hechos.
func actual() -> int:
	for i in pasos.size():
		if not pasos[i].get("hecho", false):
			return i
	return -1


func columnas() -> int:
	var ancho := size.x if size.x > 0.0 else 400.0
	if pasos.size() > 0 and pasos.size() <= int((ancho - 16.0) / PASO_UNA_FILA):
		return pasos.size()
	return clampi(int((ancho - 16.0) / PASO_MIN), 3, 9)


func filas() -> int:
	return ceili(float(pasos.size()) / columnas()) if not pasos.is_empty() else 0


func _get_minimum_size() -> Vector2:
	return Vector2(240, filas() * ALTO_FILA + 6.0)


## Centro de cada moneda.
func centros() -> Array[Vector2]:
	var r: Array[Vector2] = []
	var cols := columnas()
	var ancho := size.x if size.x > 0.0 else 400.0
	var esp := (ancho - 16.0) / cols
	for i in pasos.size():
		var fila := i / cols
		var col := i % cols
		var pos := col if fila % 2 == 0 else cols - 1 - col
		r.append(Vector2(8.0 + esp * (pos + 0.5), ARRIBA + fila * ALTO_FILA + (ONDA if i % 2 == 1 else -ONDA * 0.5)))
	return r


func paso_en(punto: Vector2) -> int:
	var mejor := RADIO + 16.0
	var r := -1
	var lista := centros()
	for i in lista.size():
		var d := lista[i].distance_to(punto)
		if d < mejor:
			mejor = d
			r = i
	return r


func _al_presionar(punto: Vector2) -> void:
	_tocado = paso_en(punto)
	queue_redraw()


func _al_soltar() -> void:
	_tocado = -1
	queue_redraw()


func _al_tocar(punto: Vector2) -> void:
	var i := paso_en(punto)
	if i >= 0:
		paso_tocado.emit(i)


## Puntos del surco entre las monedas; al cambiar de fila, una curva por fuera.
func _trazado(hasta: int) -> PackedVector2Array:
	var lista := centros()
	var p := PackedVector2Array()
	if lista.is_empty():
		return p
	var esp := (size.x - 16.0) / columnas()
	p.append(lista[0])
	for i in range(1, mini(hasta + 1, lista.size())):
		var a := lista[i - 1]
		var b := lista[i]
		if absf(b.y - a.y) < ALTO_FILA * 0.5:
			p.append(b)
			continue
		var bulto := minf(46.0, esp * 0.55) * (1.0 if a.x > size.x / 2.0 else -1.0)
		for k in range(1, 17):
			var t := k / 16.0
			var q := a.bezier_interpolate(a + Vector2(bulto, 0), b + Vector2(bulto, 0), b, t)
			p.append(q)
	return p


func _draw() -> void:
	if pasos.is_empty():
		return
	var lista := centros()
	var todo := _trazado(pasos.size() - 1)
	if todo.size() >= 2:
		draw_polyline(todo, Color("05080b"), 17.0, true)
		draw_polyline(todo, Color("202a33"), 12.0, true)
		var luz := PackedVector2Array()
		for q in todo:
			luz.append(q + Vector2(0, -3.5))
		draw_polyline(luz, Color(1, 1, 1, 0.06), 2.0, true)
	var siguiente := actual()
	var hechos := siguiente if siguiente >= 0 else pasos.size() - 1
	if hechos > 0:
		var tramo := _trazado(hechos)
		draw_polyline(tramo, color.darkened(0.2), 7.0, true)
		var brillo := PackedVector2Array()
		for q in tramo:
			brillo.append(q + Vector2(0, -1.5))
		draw_polyline(brillo, Color(1, 1, 1, 0.35), 2.0, true)
	for i in lista.size():
		var paso: Dictionary = pasos[i]
		var tipo := "hecha" if paso.get("hecho", false) else ("actual" if i == siguiente else "pendiente")
		var r := RADIO_ACTUAL if tipo == "actual" else RADIO
		if i == _tocado:
			r += 2.0
		var icono := "examen" if paso.get("tipo", "") == "examen" else ""
		Relieve.moneda(self, lista[i], r, tipo, i + 1, color, icono)
		if paso.get("tipo", "") == "examen" and tipo != "actual":
			var tam := float(Tema.tam(9.5))
			PiezasAri.texto(self, "EXAMEN", lista[i].x, lista[i].y + r * 1.13 + tam + 4.0, tam, Relieve.AMBAR)
	if siguiente >= 0:
		_rotulo_actual(lista[siguiente], str(pasos[siguiente].get("titulo", "")))


## Nombre de la siguiente lección en una pastilla bajo su moneda.
func _rotulo_actual(c: Vector2, titulo: String) -> void:
	var tam := float(Tema.tam(10.5))
	var maximo := minf((size.x - 16.0) / columnas() * 2.2, size.x - 8.0)
	var texto := titulo
	while texto.length() > 4 and PiezasAri.ancho_texto(texto, tam) + 18.0 > maximo:
		texto = texto.substr(0, texto.length() - 2) + "…"
		texto = texto.replace("……", "…")
	var ancho := PiezasAri.ancho_texto(texto, tam) + 18.0
	var x := clampf(c.x - ancho / 2.0, 4.0, size.x - ancho - 4.0)
	var p := Rect2(Vector2(x, c.y + RADIO_ACTUAL * 1.13 + 8.0), Vector2(ancho, tam + 9.0))
	DibujoAri.relleno(self, p, p.size.y / 2.0, Color("0d1318"))
	DibujoAri.borde(self, p, p.size.y / 2.0, Color(Relieve.AMBAR, 0.75), 1.0)
	PiezasAri.texto(self, texto, p.get_center().x, p.get_center().y + tam * 0.36, tam, Tema.ACENTO)
