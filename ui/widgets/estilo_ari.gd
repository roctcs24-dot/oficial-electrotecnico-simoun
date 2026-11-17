class_name EstiloAri
extends StyleBox
## Fondo de los botones y paneles del contenido dentro del marco de simulador: degradado con
## brillo, borde oscuro, canto de luz y sombra, dibujado con polígonos para que se vea nítido a
## cualquier escala. Es el mismo relieve que BotonAri y PanelAri, pero como StyleBox, para que los
## botones y tarjetas de las pantallas lo tomen del tema sin tocar su código.

# Exportadas para que duplicate() las copie, como hace _apretar_pestana.
@export var colores: Array = Tema.ARI_BOTON
@export var posiciones: Array = DibujoAri.BRILLO
@export var radio := 6.0
@export var borde := Tema.ARI_BORDE
@export var luz := Color(1, 1, 1, 0.5)
@export var sombra := 0.4
## Distancia entre el borde de la zona táctil y el dibujo, como el hueco de BotonAri.
@export var hueco := Vector2(2.0, 2.0)
## Desplaza el dibujo hacia abajo, para los botones hundidos.
@export var hundido := 0.0


static func crear(p_colores: Array, margen_x := 14.0, margen_y := 13.0, p_radio := 6.0) -> EstiloAri:
	var e := EstiloAri.new()
	e.colores = p_colores
	e.posiciones = DibujoAri.BRILLO if p_colores.size() == 4 else []
	e.radio = p_radio
	e.content_margin_left = margen_x
	e.content_margin_right = margen_x
	e.content_margin_top = margen_y
	e.content_margin_bottom = margen_y
	return e


## Variante del mismo estilo con los colores oscurecidos y el dibujo hundido un punto.
func pulsado() -> EstiloAri:
	var e: EstiloAri = duplicate()
	e.colores = colores.map(func(c: Color) -> Color: return c.darkened(0.18))
	e.hundido = 1.0
	e.sombra = 0.0
	e.luz = Color(1, 1, 1, 0.25)
	return e


func _draw(lienzo: RID, rect: Rect2) -> void:
	var r := Rect2(rect.position + hueco + Vector2(0, hundido), rect.size - hueco * 2.0)
	if r.size.x < 2.0 or r.size.y < 2.0:
		return
	if sombra > 0.0:
		for i in 3:
			_poligono(lienzo, DibujoAri.contorno(Rect2(r.position + Vector2(0, 2), r.size).grow(float(i)), radio + i), Color(0, 0, 0, sombra / 3.0))
	var forma := DibujoAri.contorno(r, radio)
	var n := colores.size()
	if n == 1:
		_poligono(lienzo, forma, colores[0])
	for k in n - 1:
		var p0: float = posiciones[k] if posiciones.size() == n else float(k) / (n - 1)
		var p1: float = posiciones[k + 1] if posiciones.size() == n else float(k + 1) / (n - 1)
		var y0 := r.position.y + r.size.y * p0
		var y1 := r.position.y + r.size.y * p1
		if y1 - y0 < 0.01:
			continue
		var cuadro := PackedVector2Array([Vector2(r.position.x - 1.0, y0), Vector2(r.end.x + 1.0, y0), Vector2(r.end.x + 1.0, y1), Vector2(r.position.x - 1.0, y1)])
		for trozo: PackedVector2Array in Geometry2D.intersect_polygons(forma, cuadro):
			if trozo.size() < 3 or Geometry2D.triangulate_polygon(trozo).is_empty():
				continue
			var cols := PackedColorArray()
			for q in trozo:
				cols.append((colores[k] as Color).lerp(colores[k + 1], clampf((q.y - y0) / (y1 - y0), 0.0, 1.0)))
			RenderingServer.canvas_item_add_polygon(lienzo, trozo, cols)
	if borde.a > 0.0:
		var linea := DibujoAri.contorno(r.grow(-0.5), radio)
		linea.append(linea[0])
		RenderingServer.canvas_item_add_polyline(lienzo, linea, PackedColorArray([borde]), 1.0, true)
	if luz.a > 0.0:
		var y := r.position.y + 1.5
		RenderingServer.canvas_item_add_line(lienzo, Vector2(r.position.x + radio, y), Vector2(r.end.x - radio, y), luz, 1.0)


func _poligono(lienzo: RID, puntos: PackedVector2Array, color: Color) -> void:
	if puntos.size() >= 3 and not Geometry2D.triangulate_polygon(puntos).is_empty():
		RenderingServer.canvas_item_add_polygon(lienzo, puntos, PackedColorArray([color]))
