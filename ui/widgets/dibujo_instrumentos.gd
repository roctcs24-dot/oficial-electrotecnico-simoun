class_name DibujoInstrumentos
extends RefCounted
## Dibujo semirrealista de los instrumentos de cuadro y de planta: marcos DIN de baquelita con
## sus tornillos, aros de acero de los manómetros, esferas con escala graduada, agujas con
## contrapeso, reflejo del vidrio y lámparas piloto con su aro cromado. La luz viene de arriba a
## la izquierda, igual que en DibujoEquipos.

const LUZ := -2.356 # Dirección de la luz: arriba a la izquierda (−135°).
const SEGMENTOS := 48
const BAQUELITA := Color("1d2023")
const ACERO_CLARO := Color("e3e7e8")
const ACERO_OSCURO := Color("5c6366")
const CARA := Color("f1f1ec")
const TINTA := Color("1b1e22")
const ROJO := Color("b3261e")


## Iluminación de una superficie curva según hacia dónde mira: 1 de cara a la luz, 0 de espaldas.
static func _luz(angulo: float) -> float:
	return (cos(angulo - LUZ) + 1.0) / 2.0


## Aro entre dos radios con la luz repartida por ángulo. Con invertido el aro se ve hundido.
static func aro(ci: CanvasItem, c: Vector2, r_ext: float, r_int: float, claro: Color, oscuro: Color, invertido := false) -> void:
	for i in SEGMENTOS:
		var a0 := TAU * i / SEGMENTOS
		var a1 := TAU * (i + 1) / SEGMENTOS
		var l0 := _luz(a0)
		var l1 := _luz(a1)
		if invertido:
			l0 = 1.0 - l0
			l1 = 1.0 - l1
		var c0 := oscuro.lerp(claro, l0)
		var c1 := oscuro.lerp(claro, l1)
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		ci.draw_polygon(PackedVector2Array([c + d0 * r_ext, c + d1 * r_ext, c + d1 * r_int, c + d0 * r_int]),
			PackedColorArray([c0, c1, c1, c0]))


## Disco con degradado radial aproximado por círculos concéntricos, más claro hacia la luz.
static func disco(ci: CanvasItem, c: Vector2, r: float, centro: Color, borde: Color, pasos := 10) -> void:
	for i in pasos:
		var t := float(i) / pasos
		var radio := r * (1.0 - t)
		var desvio := Vector2.from_angle(LUZ) * r * 0.25 * t
		ci.draw_circle(c + desvio, radio, borde.lerp(centro, t))


## Tornillo de cabeza ranurada.
static func tornillo(ci: CanvasItem, c: Vector2, r: float, angulo := 0.6) -> void:
	ci.draw_circle(c + Vector2(0.6, 0.8) * r * 0.3, r, Color(0, 0, 0, 0.35))
	disco(ci, c, r, ACERO_CLARO, ACERO_OSCURO, 5)
	var d := Vector2.from_angle(angulo) * r * 0.75
	ci.draw_line(c - d, c + d, Color("2b2f32"), maxf(1.0, r * 0.28))


## Marco cuadrado de instrumento de cuadro (formato DIN 96 o 72), con bisel y cuatro tornillos.
static func marco_cuadrado(ci: CanvasItem, r: Rect2) -> Rect2:
	var borde := r.size.x * 0.075
	ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r, BAQUELITA)
	# Bisel: el canto superior e izquierdo reciben luz, el inferior y el derecho quedan en sombra.
	var claro := BAQUELITA.lightened(0.14)
	var oscuro := BAQUELITA.darkened(0.6)
	var a := r.position
	var b := r.end
	var ai := a + Vector2(borde, borde)
	var bi := b - Vector2(borde, borde)
	ci.draw_colored_polygon(PackedVector2Array([a, Vector2(b.x, a.y), Vector2(bi.x, ai.y), ai, Vector2(ai.x, bi.y), Vector2(a.x, b.y)]), claro)
	ci.draw_colored_polygon(PackedVector2Array([b, Vector2(a.x, b.y), Vector2(ai.x, bi.y), bi, Vector2(bi.x, ai.y), Vector2(b.x, a.y)]), oscuro)
	var cara := Rect2(ai, bi - ai)
	ci.draw_rect(cara.grow(1.0), Color("0b0c0d"))
	ci.draw_rect(cara, CARA)
	var rt := borde * 0.32
	for p: Vector2 in [a + Vector2(borde, borde) * 0.5, Vector2(b.x, a.y) + Vector2(-borde, borde) * 0.5,
			Vector2(a.x, b.y) + Vector2(borde, -borde) * 0.5, b - Vector2(borde, borde) * 0.5]:
		tornillo(ci, p, rt)
	return cara


## Caja redonda de manómetro o termómetro: aro de acero inoxidable, junta y esfera blanca.
## Devuelve el radio útil de la esfera.
static func caja_redonda(ci: CanvasItem, c: Vector2, r: float) -> float:
	ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))
	aro(ci, c, r, r * 0.86, ACERO_CLARO, ACERO_OSCURO)
	aro(ci, c, r * 0.86, r * 0.82, ACERO_CLARO.darkened(0.1), ACERO_OSCURO.darkened(0.3), true)
	ci.draw_circle(c, r * 0.82, Color("2a2d30"))
	var esfera := r * 0.8
	disco(ci, c, esfera, CARA, CARA.darkened(0.12), 8)
	return esfera


## Toma de presión con hexágono para la llave, debajo de la caja del manómetro.
static func toma_inferior(ci: CanvasItem, c: Vector2, r: float) -> void:
	var ancho := r * 0.32
	var alto := r * 0.22
	var arriba := c.y + r * 0.96
	var cuello := Rect2(Vector2(c.x - ancho * 0.3, arriba - 2.0), Vector2(ancho * 0.6, alto * 0.6))
	DibujoEquipos.cilindro(ci, cuello, Color("b08d3c"), false)
	var hexagono := Rect2(Vector2(c.x - ancho / 2.0, cuello.end.y - 1.0), Vector2(ancho, alto))
	DibujoEquipos.cilindro(ci, hexagono, Color("c39a42"), false)


## Reflejo del vidrio: una franja curva clara arriba a la izquierda.
static func reflejo(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_arc(c, r * 0.86, PI * 1.05, PI * 1.45, 16, Color(1, 1, 1, 0.22), maxf(2.0, r * 0.1), true)
	ci.draw_arc(c, r * 0.7, PI * 1.12, PI * 1.32, 10, Color(1, 1, 1, 0.12), maxf(1.0, r * 0.05), true)


## Paso entre marcas principales: 1, 2 o 5 por potencia de diez, con no más de 7 divisiones,
## prefiriendo un paso del que el mínimo y el máximo sean múltiplos (45-55 Hz → 45, 50, 55).
static func paso_escala(minimo: float, maximo: float) -> float:
	var rango := maximo - minimo
	if rango <= 0.0:
		return 1.0
	var base := pow(10.0, floor(log(rango) / log(10.0)) - 1.0)
	var primero := 0.0
	for k in 4:
		for f: float in [1.0, 2.0, 5.0]:
			var paso := f * base * pow(10.0, k)
			if rango / paso > 7.0 + 1e-6:
				continue
			if primero == 0.0:
				primero = paso
			if _multiplo(minimo, paso) and _multiplo(maximo, paso):
				return paso
	return primero


static func _multiplo(v: float, paso: float) -> bool:
	var q := v / paso
	return absf(q - roundf(q)) < 1e-4


## Ángulo de pantalla de un valor en una escala de apertura dada, simétrica respecto a la vertical
## y con el hueco abajo.
static func angulo_escala(v: float, minimo: float, maximo: float, apertura_grados: float) -> float:
	var t := clampf((v - minimo) / (maximo - minimo), 0.0, 1.0)
	return deg_to_rad(90.0 + (360.0 - apertura_grados) / 2.0 + t * apertura_grados)


## Escala graduada: marcas menores, principales numeradas y franja roja desde zona_roja.
## Con interior las cifras van por dentro del arco (manómetros) y si no, también.
static func escala(ci: CanvasItem, fuente: Font, c: Vector2, radio: float, minimo: float, maximo: float,
		apertura: float, zona_roja: float, tinta: Color, tam: int, grosor := 1.0) -> void:
	var paso := paso_escala(minimo, maximo)
	var cifra := int(roundf(paso / pow(10.0, floor(log(paso) / log(10.0)))))
	var divisiones := 4 if cifra == 2 else 5
	var menor := paso / divisiones
	if zona_roja < maximo:
		var a0 := angulo_escala(maxf(zona_roja, minimo), minimo, maximo, apertura)
		var a1 := angulo_escala(maximo, minimo, maximo, apertura)
		ci.draw_arc(c, radio * 0.95, a0, a1, 24, ROJO, radio * 0.09, true)
	ci.draw_arc(c, radio, angulo_escala(minimo, minimo, maximo, apertura), angulo_escala(maximo, minimo, maximo, apertura), 48, tinta, grosor, true)
	var decimales := 0 if paso >= 1.0 - 1e-6 else (1 if paso >= 0.1 - 1e-6 else 2)
	# Si las cifras no caben entre dos marcas principales, se numera una sí y otra no.
	var mas_ancha := 0.0
	for v: float in [minimo, maximo]:
		mas_ancha = maxf(mas_ancha, fuente.get_string_size(TextoTecnico.numero(v, decimales), HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	var hueco := radio * 0.72 * deg_to_rad(apertura) * paso / (maximo - minimo)
	var salto := 1 if hueco >= mas_ancha * 1.15 else 2
	var k0 := int(ceil(minimo / menor - 1e-4))
	var k1 := int(floor(maximo / menor + 1e-4))
	for k in range(k0, k1 + 1):
		var v := k * menor
		var a := angulo_escala(v, minimo, maximo, apertura)
		var d := Vector2.from_angle(a)
		var principal := _multiplo(v, paso)
		var color := ROJO if v > zona_roja + 1e-6 else tinta
		var largo := 0.14 if principal else (0.09 if _multiplo(v, paso / 2.0) and divisiones != 4 else 0.06)
		ci.draw_line(c + d * radio, c + d * radio * (1.0 - largo), color, grosor * (1.8 if principal else 1.0), true)
		if principal and posmod(int(roundf(v / paso)), salto) == 0:
			var texto := TextoTecnico.numero(v, decimales)
			var medida := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
			var p := c + d * radio * 0.72
			ci.draw_string(fuente, p - Vector2(medida.x / 2.0, -tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


## Escala secundaria en otra unidad (psi en un manómetro en bar), por dentro y en rojo.
static func escala_secundaria(ci: CanvasItem, fuente: Font, c: Vector2, radio: float, minimo: float, maximo: float,
		factor: float, apertura: float, color: Color, tam: int) -> void:
	var lo := minimo * factor
	var hi := maximo * factor
	var paso := paso_escala(lo, hi)
	var k0 := int(ceil(lo / paso - 1e-4))
	var k1 := int(floor(hi / paso + 1e-4))
	ci.draw_arc(c, radio, angulo_escala(minimo, minimo, maximo, apertura), angulo_escala(maximo, minimo, maximo, apertura), 40, color, 1.0, true)
	for k in range(k0, k1 + 1):
		var v := k * paso
		var a := angulo_escala(v / factor, minimo, maximo, apertura)
		var d := Vector2.from_angle(a)
		ci.draw_line(c + d * radio, c + d * radio * 1.08, color, 1.2, true)
		var texto := TextoTecnico.numero(v, 0)
		var medida := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
		var p := c + d * radio * 0.8
		ci.draw_string(fuente, p - Vector2(medida.x / 2.0, -tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


## Aguja afilada con contrapeso y tapa central.
static func aguja(ci: CanvasItem, c: Vector2, angulo: float, largo: float, color: Color, punta := Color(0, 0, 0, 0)) -> void:
	var d := Vector2.from_angle(angulo)
	var n := Vector2(-d.y, d.x)
	var ancho := maxf(largo * 0.035, 1.5)
	var sombra := Vector2(1.5, 2.0)
	var cuerpo := PackedVector2Array([c + d * largo, c + n * ancho - d * largo * 0.05, c - d * largo * 0.22 + n * ancho * 0.8,
		c - d * largo * 0.22 - n * ancho * 0.8, c - n * ancho - d * largo * 0.05])
	var sombreada := PackedVector2Array()
	for p in cuerpo:
		sombreada.append(p + sombra)
	ci.draw_colored_polygon(sombreada, Color(0, 0, 0, 0.25))
	ci.draw_colored_polygon(cuerpo, color)
	if punta.a > 0.0:
		ci.draw_colored_polygon(PackedVector2Array([c + d * largo, c + d * largo * 0.72 + n * ancho * 0.45, c + d * largo * 0.72 - n * ancho * 0.45]), punta)
	ci.draw_circle(c - d * largo * 0.2, ancho * 2.0, color)
	disco(ci, c, ancho * 2.6, color.lightened(0.45), color, 4)


## Lámpara piloto: aro cromado moleteado, lente con anillos de Fresnel y halo cuando alumbra.
static func lampara(ci: CanvasItem, c: Vector2, r: float, apagado: Color, encendido: Color, luz: float) -> void:
	ci.draw_circle(c + Vector2(1.5, 2.0), r, Color(0, 0, 0, 0.35))
	aro(ci, c, r, r * 0.8, ACERO_CLARO, ACERO_OSCURO)
	for i in 24:
		var d := Vector2.from_angle(TAU * i / 24.0)
		ci.draw_line(c + d * r * 0.98, c + d * r * 0.86, Color(0, 0, 0, 0.18), 1.0)
	aro(ci, c, r * 0.8, r * 0.72, ACERO_CLARO.darkened(0.15), ACERO_OSCURO.darkened(0.4), true)
	var color := apagado.lerp(encendido, luz)
	disco(ci, c, r * 0.72, color.lightened(0.15 + 0.35 * luz), color.darkened(0.45 - 0.2 * luz), 8)
	for k in 3:
		ci.draw_arc(c, r * (0.22 + 0.16 * k), 0.0, TAU, 24, Color(0, 0, 0, 0.1 + 0.05 * (1.0 - luz)), 1.0, true)
	if luz > 0.0:
		ci.draw_circle(c, r * 0.3, Color(1, 1, 1, 0.25 * luz))
	ci.draw_arc(c, r * 0.56, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.3 + 0.3 * luz), maxf(1.5, r * 0.08), true)
