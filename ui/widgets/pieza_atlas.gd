class_name PiezaAtlas
extends ControlToque
## Pieza del cajón de la Escuela: una ficha del atlas en su hueco, con el icono, el nombre y una
## marca verde si se vieron sus cinco vistas, o una barra con lo visto hasta ahora.

signal pulsada

const LADO := Vector2(88, 102)

var nombre := ""
var icono := "ficha"
## Fracción de las vistas recorridas (de 0 a 1).
var avance := 0.0


func iniciar(p_nombre: String, p_icono: String, p_avance: float) -> void:
	nombre = p_nombre
	icono = p_icono if FileAccess.file_exists("res://art/iconos/%s.svg" % p_icono) else "ficha"
	avance = clampf(p_avance, 0.0, 1.0)
	custom_minimum_size = LADO
	tooltip_text = nombre
	queue_redraw()


## El nombre en una línea si cabe; si no, en dos, cortando por el espacio más cercano al medio.
static func partir(texto: String, tam: float, ancho: float) -> Array[String]:
	if PiezasAri.ancho_texto(texto, tam) <= ancho or not " " in texto:
		return [texto]
	var palabras := texto.split(" ")
	var mejor := 1
	var diferencia := INF
	for i in range(1, palabras.size()):
		var a := " ".join(palabras.slice(0, i))
		var b := " ".join(palabras.slice(i))
		var d := absf(PiezasAri.ancho_texto(a, tam) - PiezasAri.ancho_texto(b, tam))
		if d < diferencia:
			diferencia = d
			mejor = i
	return [" ".join(palabras.slice(0, mejor)), " ".join(palabras.slice(mejor))]


func _al_tocar(_punto: Vector2) -> void:
	pulsada.emit()


func _draw() -> void:
	var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var placa: Array = Relieve.PLACA
	if _presionado:
		placa = placa.map(func(c: Color) -> Color: return c.lightened(0.08))
	DibujoAri.pieza(self, r, 10.0, [Color("2a3540"), placa[1], placa[2]], [], Color("0b1015"), Color(1, 1, 1, 0.12), 0.5)
	var tam := float(Tema.tam(10.5))
	var lineas := partir(nombre, tam, r.size.x - 6.0)
	var alto_texto := tam * 1.15 * 2.0
	var hueco := Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10.0, r.size.y - alto_texto - 14.0))
	DibujoAri.degradado(self, hueco, 7.0, Relieve.HUECO)
	# Sombra interior del hueco y canto de luz abajo.
	draw_line(hueco.position + Vector2(5, 1.5), Vector2(hueco.end.x - 5.0, hueco.position.y + 1.5), Color(0, 0, 0, 0.8), 3.0)
	draw_line(Vector2(hueco.position.x + 5.0, hueco.end.y - 0.5), hueco.end - Vector2(5, 0.5), Color(1, 1, 1, 0.08), 1.0)
	var lado := minf(hueco.size.y * 0.6, 30.0)
	Relieve.dibujar_icono(self, icono, hueco.get_center() + Vector2(0, 2), lado, Color(0, 0, 0, 0.6))
	Relieve.dibujar_icono(self, icono, hueco.get_center(), lado, Color(1, 1, 1, 1.0 if avance > 0.0 else 0.55))
	var tinta := Color.WHITE if avance > 0.0 else Color("a9b6c1")
	var base := hueco.end.y + 4.0 + tam if lineas.size() > 1 else hueco.end.y + 4.0 + tam * 1.6
	for linea: String in lineas:
		var t := tam
		while t > 7.0 and PiezasAri.ancho_texto(linea, t) > r.size.x - 6.0:
			t -= 0.5
		PiezasAri.texto(self, linea, r.get_center().x, base, t, tinta)
		base += tam * 1.15
	if avance >= 1.0:
		var c := Vector2(r.end.x - 4.0, r.position.y + 4.0)
		Relieve.halo(self, c, 13.0, Relieve.VERDE_MARCA, 1.4)
		draw_circle(c, 10.0, Color("0b1015"))
		PiezasAri._disco(self, c, 8.5, Color("b6ffd0"), Color("0d6b30"), Vector2(-0.2, -0.3), 8)
		draw_polyline(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(-1, 3), c + Vector2(4.5, -3.5)]), Color.WHITE, 2.2, true)
	elif avance > 0.0:
		var barra := Rect2(Vector2(hueco.position.x + 5.0, hueco.end.y - 8.0), Vector2(hueco.size.x - 10.0, 4.0))
		DibujoAri.relleno(self, barra, 2.0, Color("0b1015"))
		DibujoAri.relleno(self, Rect2(barra.position, Vector2(barra.size.x * avance, barra.size.y)), 2.0, Relieve.AMBAR)
