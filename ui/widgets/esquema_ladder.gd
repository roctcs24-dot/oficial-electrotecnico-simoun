class_name EsquemaLadder
extends Control
## Programa ladder dibujado como en el equipo de programación: barra izquierda, contactos en
## serie y en paralelo, y bobinas a la derecha. Con la memoria del PLC, los tramos por los que
## pasa la señal se pintan en verde. Tocar un elemento lo selecciona para editarlo.
## Ruta de un elemento: [peldaño, "logica", i, (rama, j, ...)] o [peldaño, "salidas", i].

signal elemento_tocado(ruta: Array)

const CELDA := Vector2(92.0, 64.0)
const ANCHO_SALIDA := 108.0
const ALTO_COMENTARIO := 22.0
const SEPARACION_PELDANOS := 14.0
const MARGEN := 10.0
const ESCALA_MINIMA := 0.55
const ACTIVO := Color("2e9e5b")
const SELECCION := Color("c2a25a")

var programa: Array = []
## Memoria del PLC (su estado) para pintar la señal; vacía, todo se dibuja sin señal.
var memoria: Dictionary = {}
var etiquetas: Dictionary = {}
var seleccion: Array = []
## Rectángulos tocables de cada elemento, en coordenadas del dibujo sin escalar.
var _zonas: Array = []
var _escala := 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func actualizar(nuevo_programa: Array, nueva_memoria: Dictionary) -> void:
	programa = nuevo_programa
	memoria = nueva_memoria
	_ajustar_tamano()
	queue_redraw()


# --- Medidas ---

## Tamaño de una serie: los elementos uno detrás de otro; un paralelo, sus ramas apiladas.
func _tamano_serie(elementos: Array) -> Vector2:
	var t := Vector2(0.0, CELDA.y)
	for e: Dictionary in elementos:
		var te := _tamano_elemento(e)
		t.x += te.x
		t.y = maxf(t.y, te.y)
	t.x = maxf(t.x, CELDA.x * 0.5)
	return t


func _tamano_elemento(e: Dictionary) -> Vector2:
	if not e.has("paralelo"):
		return CELDA
	var t := Vector2.ZERO
	for rama: Array in e["paralelo"]:
		var tr := _tamano_serie(rama)
		t.x = maxf(t.x, tr.x)
		t.y += tr.y
	return t


func _tamano_peldano(p: Dictionary) -> Vector2:
	var logica := _tamano_serie(p.get("logica", []))
	var salidas := maxf(1.0, p.get("salidas", []).size()) * CELDA.y
	return Vector2(logica.x + ANCHO_SALIDA + CELDA.x * 0.5, maxf(logica.y, salidas) + ALTO_COMENTARIO)


func _tamano_natural() -> Vector2:
	var t := Vector2(MARGEN * 2.0, MARGEN * 2.0)
	for p: Dictionary in programa:
		var tp := _tamano_peldano(p)
		t.x = maxf(t.x, tp.x + MARGEN * 2.0)
		t.y += tp.y + SEPARACION_PELDANOS
	return t


## Si el programa es más ancho que la pantalla, se dibuja más pequeño, hasta un mínimo.
func _ajustar_tamano() -> void:
	var natural := _tamano_natural()
	_escala = clampf(size.x / natural.x, ESCALA_MINIMA, 1.0) if size.x > 0.0 else 1.0
	custom_minimum_size = Vector2(natural.x * ESCALA_MINIMA, natural.y * _escala)


func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED:
		_ajustar_tamano()


# --- Dibujo ---

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tema.PAPEL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_escala, _escala))
	_zonas = []
	var y := MARGEN
	var ancho := size.x / _escala - MARGEN * 2.0
	for i in programa.size():
		var p: Dictionary = programa[i]
		var tp := _tamano_peldano(p)
		var comentario: String = p.get("comentario", "")
		_texto(Vector2(MARGEN + 4.0, y + 14.0), "%d. %s" % [i + 1, comentario], 12, Tema.TINTA, HORIZONTAL_ALIGNMENT_LEFT, ancho)
		var y_linea := y + ALTO_COMENTARIO + CELDA.y * 0.5
		var x0 := MARGEN
		var x1 := MARGEN + ancho
		draw_line(Vector2(x0, y + ALTO_COMENTARIO), Vector2(x0, y + tp.y), _color(true), 3.0)
		draw_line(Vector2(x1, y + ALTO_COMENTARIO), Vector2(x1, y + tp.y), Tema.TINTA, 3.0)
		var flujo := _dibujar_serie(p.get("logica", []), Vector2(x0, y_linea), true, [i, "logica"])
		var x_salidas := x1 - ANCHO_SALIDA
		var x_fin := x0 + _tamano_serie(p.get("logica", [])).x
		draw_line(Vector2(x_fin, y_linea), Vector2(x_salidas, y_linea), _color(flujo), 2.0)
		var salidas: Array = p.get("salidas", [])
		for j in salidas.size():
			var ys := y_linea + j * CELDA.y
			if j > 0:
				draw_line(Vector2(x_salidas, ys - CELDA.y), Vector2(x_salidas, ys), _color(flujo), 2.0)
			_dibujar_salida(salidas[j], Vector2(x_salidas, ys), x1, flujo, [i, "salidas", j])
		y += tp.y + SEPARACION_PELDANOS


func _color(activo: bool) -> Color:
	return ACTIVO if activo and not memoria.is_empty() else Tema.TINTA


## Dibuja la serie desde el punto de entrada; devuelve si la señal llega al final.
func _dibujar_serie(elementos: Array, origen: Vector2, flujo: bool, ruta: Array) -> bool:
	var x := origen.x
	if elementos.is_empty():
		draw_line(origen, origen + Vector2(CELDA.x * 0.5, 0.0), _color(flujo), 2.0)
		return flujo
	for k in elementos.size():
		var e: Dictionary = elementos[k]
		var te := _tamano_elemento(e)
		var r := ruta + [k]
		if e.has("paralelo"):
			flujo = _dibujar_paralelo(e, Vector2(x, origen.y), te, flujo, r)
		else:
			flujo = _dibujar_contacto(e, Vector2(x, origen.y), flujo, r)
		x += te.x
	return flujo


func _dibujar_paralelo(e: Dictionary, origen: Vector2, t: Vector2, flujo: bool, ruta: Array) -> bool:
	var sale := false
	var y := origen.y
	var x_fin := origen.x + t.x
	var ramas: Array = e["paralelo"]
	for k in ramas.size():
		var rama: Array = ramas[k]
		var tr := _tamano_serie(rama)
		var paso := _dibujar_serie(rama, Vector2(origen.x, y), flujo, ruta + [k])
		draw_line(Vector2(origen.x + tr.x, y), Vector2(x_fin, y), _color(paso), 2.0)
		if k > 0:
			draw_line(Vector2(origen.x, y - _tamano_serie(ramas[k - 1]).y), Vector2(origen.x, y), _color(flujo), 2.0)
			draw_line(Vector2(x_fin, y - _tamano_serie(ramas[k - 1]).y), Vector2(x_fin, y), _color(paso or sale), 2.0)
		sale = sale or paso
		y += tr.y
	return sale


func _dibujar_contacto(e: Dictionary, o: Vector2, flujo: bool, ruta: Array) -> bool:
	var pasa := SimLadder.elemento(e, memoria, {}) if not memoria.is_empty() else false
	var sale := flujo and pasa
	var c := o + Vector2(CELDA.x * 0.5, 0.0)
	var trazo := _color(pasa)
	var direccion := ""
	if e.has("cmp"):
		draw_rect(Rect2(c - Vector2(30.0, 14.0), Vector2(60.0, 28.0)), trazo, false, 2.0)
		_texto(c + Vector2(0.0, 5.0), "%s %s" % [e["cmp"], _numero(e["b"])], 12, trazo)
		direccion = str(e["a"])
		draw_line(o, c - Vector2(30.0, 0.0), _color(flujo), 2.0)
		draw_line(c + Vector2(30.0, 0.0), o + Vector2(CELDA.x, 0.0), _color(sale), 2.0)
	else:
		draw_line(o, c - Vector2(8.0, 0.0), _color(flujo), 2.0)
		draw_line(c + Vector2(8.0, 0.0), o + Vector2(CELDA.x, 0.0), _color(sale), 2.0)
		draw_line(c + Vector2(-8.0, -14.0), c + Vector2(-8.0, 14.0), trazo, 2.5)
		draw_line(c + Vector2(8.0, -14.0), c + Vector2(8.0, 14.0), trazo, 2.5)
		if e.has("nc"):
			draw_line(c + Vector2(-12.0, 14.0), c + Vector2(12.0, -14.0), trazo, 2.0)
		if e.has("flanco"):
			_texto(c + Vector2(0.0, 5.0), "P", 12, trazo)
		direccion = str(e.get("na", e.get("nc", e.get("flanco", ""))))
	_rotulos(c, direccion)
	_zona(Rect2(o + Vector2(0.0, -CELDA.y * 0.5), CELDA), ruta)
	return sale


func _dibujar_salida(s: Dictionary, o: Vector2, x_fin: float, flujo: bool, ruta: Array) -> void:
	var c := o + Vector2(ANCHO_SALIDA * 0.5, 0.0)
	var activo := _salida_activa(s)
	var trazo := _color(activo)
	var direccion := ""
	var tipo := ""
	for clave in ["bobina", "set", "reset", "ton", "tof", "ctu", "rst"]:
		if s.has(clave):
			tipo = clave
			direccion = s[clave]
	if tipo in ["ton", "tof", "ctu"]:
		draw_line(o, c - Vector2(30.0, 0.0), _color(flujo), 2.0)
		draw_rect(Rect2(c - Vector2(30.0, 16.0), Vector2(60.0, 32.0)), trazo, false, 2.0)
		_texto(c + Vector2(0.0, -2.0), tipo.to_upper(), 11, trazo)
		_texto(c + Vector2(0.0, 12.0), _valor_bloque(s, tipo, direccion), 10, trazo)
		draw_line(c + Vector2(30.0, 0.0), Vector2(x_fin, o.y), Tema.TINTA, 2.0)
	else:
		draw_line(o, c - Vector2(14.0, 0.0), _color(flujo), 2.0)
		draw_arc(c, 14.0, PI * 0.65, PI * 1.35, 12, trazo, 2.5)
		draw_arc(c, 14.0, -PI * 0.35, PI * 0.35, 12, trazo, 2.5)
		var letra: String = {"set": "S", "reset": "R", "rst": "R"}.get(tipo, "")
		if not letra.is_empty():
			_texto(c + Vector2(0.0, 5.0), letra, 12, trazo)
		draw_line(c + Vector2(14.0, 0.0), Vector2(x_fin, o.y), Tema.TINTA, 2.0)
	_rotulos(c, direccion)
	_zona(Rect2(o + Vector2(0.0, -CELDA.y * 0.5), Vector2(ANCHO_SALIDA, CELDA.y)), ruta)


func _salida_activa(s: Dictionary) -> bool:
	if memoria.is_empty():
		return false
	for clave in ["bobina", "set", "reset", "ton", "tof", "ctu"]:
		if s.has(clave):
			return SimLadder.bit(memoria, s[clave])
	return false


func _valor_bloque(s: Dictionary, tipo: String, direccion: String) -> String:
	if tipo == "ctu":
		var c: Dictionary = memoria.get("contadores", {}).get(direccion, {})
		return "%d / %d" % [int(c.get("cv", 0)), int(s["pv"])]
	var t: Dictionary = memoria.get("temporizadores", {}).get(direccion, {})
	return "%s / %s s" % [TextoTecnico.numero(float(t.get("acc_ms", 0.0)) / 1000.0, 1), TextoTecnico.numero(float(s["ms"]) / 1000.0, 1)]


## Dirección encima del elemento y su etiqueta corta debajo: el nombre del dispositivo, como
## «S1», o el principio del texto si no lo tiene, recortado al ancho de la celda.
func _rotulos(c: Vector2, direccion: String) -> void:
	_texto(c + Vector2(0.0, -20.0), direccion, 12, Tema.TINTA)
	var etiqueta: String = etiquetas.get(direccion, "")
	if etiqueta.is_empty():
		return
	var corta := etiqueta.get_slice(" · ", 0)
	var fuente := get_theme_default_font()
	while corta.length() > 3 and fuente.get_string_size(corta, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > CELDA.x - 6.0:
		corta = corta.substr(0, corta.length() - 2) + "…"
		corta = corta.replace("……", "…")
	_texto(c + Vector2(0.0, 30.0), corta, 10, Color("4b5560"))


func _zona(r: Rect2, ruta: Array) -> void:
	_zonas.append([r, ruta])
	if ruta == seleccion:
		draw_rect(r.grow(-2.0), SELECCION, false, 3.0)


func _numero(v: Variant) -> String:
	return str(v) if v is String else TextoTecnico.numero(float(v), 1)


func _texto(p: Vector2, texto: String, tamano: int, color: Color, alineacion := HORIZONTAL_ALIGNMENT_CENTER, ancho := 0.0) -> void:
	var fuente := get_theme_default_font()
	var medida := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var x := p.x if alineacion == HORIZONTAL_ALIGNMENT_LEFT else p.x - medida / 2.0
	draw_string(fuente, Vector2(x, p.y), texto, HORIZONTAL_ALIGNMENT_LEFT, ancho if ancho > 0.0 else -1.0, tamano, color)


# --- Toques ---

func _gui_input(evento: InputEvent) -> void:
	var toque: bool = (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT) or (evento is InputEventScreenTouch and evento.pressed)
	if not toque:
		return
	var punto: Vector2 = evento.position / _escala
	for z: Array in _zonas:
		if (z[0] as Rect2).has_point(punto):
			elemento_tocado.emit(z[1])
			return
