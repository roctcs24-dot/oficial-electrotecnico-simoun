class_name DibujoMarcas
extends VistaBornes
## Dibujo grande de una ficha con sus marcas numeradas y un bocadillo que explica la parte
## elegida, unido a su marca con una línea guía. Si el visor es apaisado, el bocadillo va a la
## derecha del dibujo; si no, debajo. Su sitio se reserva siempre, para que el dibujo no salte
## al cambiar de parte.
## Cada parte es {nombre, texto, x, y}: el texto puede llevar {{términos}} del glosario.

const MARGEN := 12.0
const SEPARACION := 14.0
const ANCHO_LADO := 0.4
const RELLENO := Vector2(12, 9)

var partes: Array = []
var glosario := {}
## Texto del bocadillo cuando no hay ninguna parte elegida.
var ayuda := "Toque un número para ver qué es cada parte."
## «derecha» o «abajo»; vacío, según la forma del control.
var lado_bocadillo := ""


func _init() -> void:
	super()
	dibujar_elegida = false
	sombra_dibujo = true


func poner_partes(lista: Array, p_glosario: Dictionary, elegida := 0) -> void:
	partes = lista
	glosario = p_glosario
	marcas = []
	for i in partes.size():
		marcas.append([i + 1, float(partes[i]["x"]), float(partes[i]["y"])])
	marca_elegida = clampi(elegida, 0, partes.size())
	queue_redraw()


func elegir(numero: int) -> void:
	marca_elegida = clampi(numero, 0, partes.size())
	queue_redraw()


func al_lado() -> bool:
	if not lado_bocadillo.is_empty():
		return lado_bocadillo == "derecha"
	return size.x > size.y * 1.15


## Zona del dibujo: todo el control, menos el sitio del bocadillo.
func area_dibujo() -> Rect2:
	var r := Rect2(Vector2(MARGEN, MARGEN), size - Vector2(MARGEN, MARGEN) * 2.0)
	if partes.is_empty():
		return r
	if al_lado():
		r.size.x = maxf(r.size.x * (1.0 - ANCHO_LADO) - SEPARACION, 10.0)
	else:
		r.size.y = maxf(r.size.y - _alto_reservado(r.size.x) - SEPARACION, 10.0)
	return r


func rect_imagen() -> Rect2:
	var zona := area_dibujo()
	var escala := minf(zona.size.x / tamano_svg.x, zona.size.y / tamano_svg.y)
	var tam := tamano_svg * escala
	return Rect2(zona.position + (zona.size - tam) / 2.0, tam)


## Rectángulo del bocadillo de la parte elegida, en coordenadas del control.
func rect_bocadillo() -> Rect2:
	var zona := Rect2(Vector2(MARGEN, MARGEN), size - Vector2(MARGEN, MARGEN) * 2.0)
	if al_lado():
		var ancho := zona.size.x * ANCHO_LADO
		var alto := _alto_bocadillo(marca_elegida, ancho)
		var y := zona.get_center().y - alto / 2.0
		if marca_elegida > 0:
			y = a_local(float(marcas[marca_elegida - 1][1]), float(marcas[marca_elegida - 1][2])).y - alto / 2.0
		y = clampf(y, zona.position.y, zona.end.y - alto)
		return Rect2(Vector2(zona.end.x - ancho, y), Vector2(ancho, alto))
	var alto_reservado := _alto_reservado(zona.size.x)
	return Rect2(Vector2(zona.position.x, zona.end.y - alto_reservado), Vector2(zona.size.x, alto_reservado))


func _alto_reservado(ancho: float) -> float:
	var alto := _alto_bocadillo(0, ancho)
	for i in partes.size():
		alto = maxf(alto, _alto_bocadillo(i + 1, ancho))
	return alto


func _textos(numero: int) -> Array[String]:
	if numero <= 0 or numero > partes.size():
		return ["TOQUE UN NÚMERO", "", ayuda]
	var p: Dictionary = partes[numero - 1]
	var nombre := TextoTecnico.plano(str(p.get("nombre", "")), glosario)
	var texto := TextoTecnico.plano(str(p.get("texto", "")), glosario)
	var partes_texto := separar_nombre(nombre, texto)
	return ["PARTE %d" % numero, partes_texto[0], partes_texto[1]]


## Sin nombre, un texto como «Bornes de potencia: entra la línea…» da el nombre en negrita y
## el resto debajo, con mayúscula.
static func separar_nombre(nombre: String, texto: String) -> Array[String]:
	var dos_puntos := texto.find(": ")
	if nombre.is_empty() and dos_puntos > 0 and dos_puntos <= 40 and not texto.substr(0, dos_puntos).contains("("):
		nombre = texto.substr(0, dos_puntos)
		texto = texto.substr(dos_puntos + 2)
		texto = texto.substr(0, 1).to_upper() + texto.substr(1)
	return [nombre, texto]


func _tamanos() -> Array[int]:
	return [Tema.tam(11), Tema.tam(14), Tema.tam(13)]


func _alto_bocadillo(numero: int, ancho: float) -> float:
	var t := _textos(numero)
	var tam := _tamanos()
	var util := maxf(ancho - RELLENO.x * 2.0, 40.0)
	var alto := RELLENO.y * 2.0 + tam[0] * 1.3
	if not t[1].is_empty():
		alto += Tema.fuente(Tema.PESO_NEGRITA).get_multiline_string_size(t[1], HORIZONTAL_ALIGNMENT_LEFT, util, tam[1]).y
	alto += Tema.fuente(Tema.PESO_NORMAL).get_multiline_string_size(t[2], HORIZONTAL_ALIGNMENT_LEFT, util, tam[2]).y
	return ceilf(alto)


func _draw() -> void:
	super()
	if partes.is_empty():
		return
	var caja := rect_bocadillo()
	var elegida := marca_elegida > 0
	if elegida:
		var c := a_local(float(marcas[marca_elegida - 1][1]), float(marcas[marca_elegida - 1][2]))
		var destino: Vector2
		if al_lado():
			destino = Vector2(caja.position.x, clampf(c.y, caja.position.y + 10.0, caja.end.y - 10.0))
		else:
			destino = Vector2(clampf(c.x, caja.position.x + 20.0, caja.end.x - 20.0), caja.position.y)
		var desde := c + (destino - c).normalized() * radio_marca() * 1.3
		draw_line(desde, destino, Color(0, 0, 0, 0.6), 4.0, true)
		draw_dashed_line(desde, destino, Relieve.AMBAR, 1.6, 5.0)
		draw_circle(destino, 3.0, Relieve.AMBAR)
		# La marca va encima de la línea.
		Relieve.marca(self, c, radio_marca() * 1.15, marca_elegida, true)
	_dibujar_bocadillo(caja, elegida)


func _dibujar_bocadillo(caja: Rect2, elegida: bool) -> void:
	var borde := Relieve.AMBAR if elegida else Color("3b4855")
	if elegida:
		for i in 3:
			DibujoAri.borde(self, caja.grow(2.0 + i * 2.0), 10.0 + i * 2.0, Color(Relieve.AMBAR_HALO, 0.16 - i * 0.05), 2.0)
	DibujoAri.sombra(self, caja, 10.0, 0.6, Vector2(0, 4))
	DibujoAri.degradado(self, caja, 10.0, [Color("1f2a34"), Color("121a21")])
	DibujoAri.borde(self, caja, 10.0, borde, 1.2)
	DibujoAri.brillo_superior(self, caja.grow(-1.0), 9.0, Color(1, 1, 1, 0.1))
	var t := _textos(marca_elegida)
	var tam := _tamanos()
	var util := caja.size.x - RELLENO.x * 2.0
	var x := caja.position.x + RELLENO.x
	var y := caja.position.y + RELLENO.y
	var rotulo := Tema.fuente(Tema.PESO_NEGRITA)
	draw_string(rotulo, Vector2(x, y + rotulo.get_ascent(tam[0])), t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, tam[0], Color(Tema.ACENTO, 1.0 if elegida else 0.7))
	y += tam[0] * 1.3
	if not t[1].is_empty():
		var negrita := Tema.fuente(Tema.PESO_NEGRITA)
		draw_multiline_string(negrita, Vector2(x, y + negrita.get_ascent(tam[1])), t[1], HORIZONTAL_ALIGNMENT_LEFT, util, tam[1], -1, Color.WHITE)
		y += negrita.get_multiline_string_size(t[1], HORIZONTAL_ALIGNMENT_LEFT, util, tam[1]).y
	var normal := Tema.fuente(Tema.PESO_NORMAL)
	draw_multiline_string(normal, Vector2(x, y + normal.get_ascent(tam[2])), t[2], HORIZONTAL_ALIGNMENT_LEFT, util, tam[2], -1, Color("cfd8df") if elegida else Tema.TEXTO_SUAVE)
