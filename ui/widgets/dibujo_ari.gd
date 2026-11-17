class_name DibujoAri
extends RefCounted
## Dibujo del marco de simulador: rectángulos redondeados con degradado de varias paradas,
## relieve, sombras y dígitos de siete segmentos. Todo con polígonos, sin imágenes.

## Paradas de los botones con brillo: la mitad de arriba más clara, con un corte en el medio.
const BRILLO := [0.0, 0.48, 0.52, 1.0]
const SEGMENTOS := {
	"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc",
	"7": "abc", "8": "abcdefg", "9": "abcdfg", "-": "g", " ": "", "E": "afged", "r": "eg", "o": "cdeg",
}
## Ancho de una cifra respecto a su alto, grosor de un segmento e inclinación.
const PROPORCION_CIFRA := 0.56
const GROSOR := 0.13
const INCLINACION := 0.08
const SEGMENTO_APAGADO := Color(1, 1, 1, 0.06)


## Contorno de un rectángulo con las esquinas redondeadas, en el sentido de las agujas.
static func contorno(r: Rect2, radio: float, segmentos := 5) -> PackedVector2Array:
	radio = minf(radio, minf(r.size.x, r.size.y) / 2.0)
	if radio < 0.5:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var centros := [
		Vector2(r.end.x - radio, r.position.y + radio), r.end - Vector2(radio, radio),
		Vector2(r.position.x + radio, r.end.y - radio), r.position + Vector2(radio, radio),
	]
	var p := PackedVector2Array()
	for k in 4:
		var c: Vector2 = centros[k]
		var a0 := -PI / 2.0 + k * PI / 2.0
		for i in segmentos + 1:
			p.append(c + Vector2.from_angle(a0 + PI / 2.0 * i / segmentos) * radio)
	return p


## Relleno con degradado vertical. «posiciones» reparte las paradas de 0 a 1 (por igual si
## falta). Con «recorte», solo se pinta lo que cae dentro, como la cabecera de un panel.
static func degradado(ci: CanvasItem, r: Rect2, radio: float, colores: Array, posiciones: Array = [], recorte := Rect2()) -> void:
	if r.size.x < 1.0 or r.size.y < 1.0 or colores.is_empty():
		return
	var forma := contorno(r, radio)
	var n := colores.size()
	if n == 1:
		_poligono(ci, forma, colores[0])
		return
	for k in n - 1:
		var p0: float = posiciones[k] if posiciones.size() == n else float(k) / (n - 1)
		var p1: float = posiciones[k + 1] if posiciones.size() == n else float(k + 1) / (n - 1)
		var y0 := r.position.y + r.size.y * p0
		var y1 := r.position.y + r.size.y * p1
		if y1 - y0 < 0.01:
			continue
		var banda := Rect2(r.position.x - 1.0, y0, r.size.x + 2.0, y1 - y0)
		if recorte.has_area():
			banda = banda.intersection(recorte)
			if not banda.has_area():
				continue
		var cuadro := PackedVector2Array([banda.position, Vector2(banda.end.x, banda.position.y), banda.end, Vector2(banda.position.x, banda.end.y)])
		for trozo: PackedVector2Array in Geometry2D.intersect_polygons(forma, cuadro):
			if trozo.size() < 3 or Geometry2D.triangulate_polygon(trozo).is_empty():
				continue
			var cols := PackedColorArray()
			for q in trozo:
				var t := clampf((q.y - y0) / (y1 - y0), 0.0, 1.0)
				cols.append((colores[k] as Color).lerp(colores[k + 1], t))
			ci.draw_polygon(trozo, cols)


static func _poligono(ci: CanvasItem, puntos: PackedVector2Array, color: Color) -> void:
	if puntos.size() >= 3 and not Geometry2D.triangulate_polygon(puntos).is_empty():
		ci.draw_colored_polygon(puntos, color)


static func relleno(ci: CanvasItem, r: Rect2, radio: float, color: Color) -> void:
	if r.size.x >= 1.0 and r.size.y >= 1.0:
		_poligono(ci, contorno(r, radio), color)


static func borde(ci: CanvasItem, r: Rect2, radio: float, color: Color, ancho := 1.0) -> void:
	if r.size.x < 2.0 or r.size.y < 2.0:
		return
	var p := contorno(r.grow(-ancho / 2.0), radio)
	p.append(p[0])
	ci.draw_polyline(p, color, ancho, true)


## Sombra difusa bajo una pieza: capas cada vez más anchas y más tenues.
static func sombra(ci: CanvasItem, r: Rect2, radio: float, opacidad := 0.45, desplazamiento := Vector2(0, 2), capas := 3) -> void:
	for i in capas:
		relleno(ci, Rect2(r.position + desplazamiento, r.size).grow(float(i)), radio + i, Color(0, 0, 0, opacidad / capas))


## Línea de luz en el borde de arriba, como el canto de una chapa iluminada desde el techo.
static func brillo_superior(ci: CanvasItem, r: Rect2, radio: float, color: Color) -> void:
	var y := r.position.y + 1.0
	ci.draw_line(Vector2(r.position.x + radio, y), Vector2(r.end.x - radio, y), color, 1.0)


## Pieza con relieve: sombra, degradado, borde oscuro y canto de luz.
static func pieza(ci: CanvasItem, r: Rect2, radio: float, colores: Array, posiciones: Array = [], borde_color := Tema.ARI_BORDE, luz := Color(1, 1, 1, 0.45), sombra_opacidad := 0.4) -> void:
	if sombra_opacidad > 0.0:
		sombra(ci, r, radio, sombra_opacidad)
	degradado(ci, r, radio, colores, posiciones)
	borde(ci, r, radio, borde_color)
	if luz.a > 0.0:
		brillo_superior(ci, r.grow(-1.0), radio, luz)


# --- Siete segmentos ---

static func ancho_cifra(alto: float) -> float:
	return alto * PROPORCION_CIFRA


## Ancho de un texto en siete segmentos: las comas, los puntos y los dos puntos ocupan poco.
static func ancho_seg7(texto: String, alto: float) -> float:
	var w := ancho_cifra(alto)
	var t := alto * GROSOR
	var x := 0.0
	for ch in texto:
		if ch == "," or ch == ".":
			continue
		if ch == ":":
			x += w * 0.45
			continue
		x += w + t * 1.3
	return maxf(x - t * 1.3, 0.0)


## Dibuja el texto con la esquina de arriba a la izquierda en «origen». Los segmentos apagados
## se ven tenues, como en un visor real; los encendidos llevan un halo suave.
static func seg7(ci: CanvasItem, texto: String, origen: Vector2, alto: float, color: Color, apagado := SEGMENTO_APAGADO, halo := true) -> void:
	var w := ancho_cifra(alto)
	var t := alto * GROSOR
	var x := origen.x
	var y := origen.y
	var encendidos: Array[PackedVector2Array] = []
	for ch in texto:
		if ch == "," or ch == ".":
			var punto := Rect2(x - t * 1.2, y + alto - t, t * 1.05, t * 1.05)
			encendidos.append(PackedVector2Array([punto.position, Vector2(punto.end.x, punto.position.y), punto.end, Vector2(punto.position.x, punto.end.y)]))
			continue
		if ch == ":":
			for fy in [0.28, 0.64]:
				var p := Rect2(x + w * 0.1, y + alto * fy, t, t)
				encendidos.append(PackedVector2Array([p.position, Vector2(p.end.x, p.position.y), p.end, Vector2(p.position.x, p.end.y)]))
			x += w * 0.45
			continue
		var activos: String = SEGMENTOS.get(ch, "")
		for s in "abcdefg":
			var poli := _segmento(s, x, y, w, alto, t)
			if s in activos:
				encendidos.append(poli)
			else:
				_poligono(ci, poli, apagado)
		x += w + t * 1.3
	if halo:
		var tenue := Color(color, 0.16)
		for poli in encendidos:
			for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				var corrido := PackedVector2Array()
				for q in poli:
					corrido.append(q + d)
				_poligono(ci, corrido, tenue)
	for poli in encendidos:
		_poligono(ci, poli, color)


## Un segmento hexagonal, inclinado como en los visores de verdad.
static func _segmento(s: String, x: float, y: float, w: float, h: float, t: float) -> PackedVector2Array:
	var pts: Array[Vector2] = []
	match s:
		"a", "g", "d":
			var yy := y if s == "a" else (y + h / 2.0 - t / 2.0 if s == "g" else y + h - t)
			var x1 := x + t
			var x2 := x + w - t
			pts = [Vector2(x1, yy + t / 2.0), Vector2(x1 + t / 2.0, yy), Vector2(x2 - t / 2.0, yy), Vector2(x2, yy + t / 2.0), Vector2(x2 - t / 2.0, yy + t), Vector2(x1 + t / 2.0, yy + t)]
		_:
			var xx := x if s in "fe" else x + w - t
			var arriba := s in "fb"
			var y1 := y + t * 0.6 if arriba else y + h / 2.0 + t * 0.4
			var y2 := y + h / 2.0 - t * 0.4 if arriba else y + h - t * 0.6
			pts = [Vector2(xx + t / 2.0, y1), Vector2(xx + t, y1 + t / 2.0), Vector2(xx + t, y2 - t / 2.0), Vector2(xx + t / 2.0, y2), Vector2(xx, y2 - t / 2.0), Vector2(xx, y1 + t / 2.0)]
	var inclinacion := INCLINACION * h
	var r := PackedVector2Array()
	for q in pts:
		r.append(Vector2(q.x + inclinacion * (1.0 - (q.y - y) / h), q.y))
	return r


# --- Signos de los botones ---

## Galón ‹ o ›: «sentido» -1 apunta a la izquierda y 1 a la derecha.
static func galon(ci: CanvasItem, centro: Vector2, tam: float, sentido: int, color: Color, ancho := 3.0) -> void:
	var dx := tam * 0.28 * sentido
	ci.draw_polyline(PackedVector2Array([centro + Vector2(-dx, -tam * 0.45), centro + Vector2(dx, 0), centro + Vector2(-dx, tam * 0.45)]), color, ancho, true)


## Flecha de volver: un gancho que regresa hacia la izquierda.
static func flecha_volver(ci: CanvasItem, centro: Vector2, tam: float, color: Color, ancho := 2.6) -> void:
	var r := tam * 0.32
	var c := centro + Vector2(tam * 0.08, tam * 0.02)
	var arco := PackedVector2Array()
	for i in 13:
		arco.append(c + Vector2.from_angle(-PI / 2.0 + PI * i / 12.0) * r)
	arco.append(c + Vector2(-tam * 0.12, r))
	ci.draw_polyline(arco, color, ancho, true)
	var punta := c + Vector2(-tam * 0.02, -r)
	ci.draw_polyline(PackedVector2Array([punta + Vector2(tam * 0.17, -tam * 0.15), punta + Vector2(-tam * 0.08, 0), punta + Vector2(tam * 0.17, tam * 0.15)]), color, ancho, true)


## Triángulo ámbar de aviso con su signo de admiración.
static func triangulo_aviso(ci: CanvasItem, r: Rect2, color := Tema.ARI_LCD_AMBAR) -> void:
	var p := PackedVector2Array([Vector2(r.get_center().x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	_poligono(ci, p, color)
	var c := r.get_center()
	var h := r.size.y
	ci.draw_line(c + Vector2(0, -h * 0.12), c + Vector2(0, h * 0.2), Tema.ARI_TEXTO_OSCURO, maxf(h * 0.12, 1.5))
	ci.draw_circle(c + Vector2(0, h * 0.36), maxf(h * 0.07, 1.0), Tema.ARI_TEXTO_OSCURO)
