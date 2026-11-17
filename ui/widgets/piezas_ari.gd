class_name PiezasAri
extends RefCounted
## Piezas dibujadas de los mímicos del simulador (etapa B del rediseño): chapa azul con bisel y
## tornillos, rótulo grabado, lámparas con halo, amperímetro de cuadro, interruptor de caja
## moldeada, selector rotativo, visor de siete segmentos y botones redondos. Todo en píxeles de
## pantalla, para que el texto y los bordes salgan nítidos a cualquier escala.

const CHAPA := [Color("3f86c2"), Color("2a6aa3"), Color("1e5385")]
const CHAPA_OSCURA := [Color("2d4f6e"), Color("16314b")]
const CHAPA_DISPARO := [Color("4a7fb0"), Color("22507e")]
const BISEL := [Color("bfe0ff"), Color("4b86ba"), Color("0b2742")]
const ROTULO := [Color("1b2633"), Color("0a1018")]
const ROTULO_BORDE := Color("6f8ea9")
const CARA := [Color("fbfaf3"), Color("dcd9cc")]
const MARCO_INSTRUMENTO := [Color("4a525b"), Color("14181c"), Color("050607")]
const CAJA := [Color("3d434a"), Color("2a2f34"), Color("1a1d21")]
const TINTA := Color("222222")
const ROJO_ESCALA := Color("d8261c")
const AGUJA := Color("c4140b")
const TEXTO_CHAPA := Color("d9e8f5")
const TEXTO_SUAVE := Color("b9d3ea")
## Colores de las lámparas: [apagada centro, apagada borde, encendida centro, encendida borde, halo].
const LAMPARAS := {
	"verde": [Color("4f7a5d"), Color("0d1d13"), Color("eafff0"), Color("16d35a"), Color("4dff8c")],
	"rojo": [Color("7a4440"), Color("1e0a09"), Color("fff0ec"), Color("ee2a1d"), Color("ff4a3a")],
	"ambar": [Color("7a5a30"), Color("2a1a08"), Color("fff8e0"), Color("f29a0c"), Color("ffb020")],
	"blanco": [Color("8d8a80"), Color("3a3833"), Color("ffffff"), Color("d9b56a"), Color("ffe9b0")],
	"azul": [Color("44607a"), Color("101c28"), Color("eaf6ff"), Color("2f8fe8"), Color("4ab4ff")],
}
## Franjas de color bajo el rótulo de cada casilla, como las de la leyenda.
const FRANJAS := {
	"verde": Color("3dff74"), "azul": Color("3b8bff"), "cian": Color("38e0e8"), "rojo": Color("ff4d4d"),
	"amarillo": Color("ffd23d"), "gris": Color("c9d3dc"), "lila": Color("d58cff"), "naranja": Color("ff9a3d"),
}


static func fuente(peso := Tema.PESO_NEGRITA) -> Font:
	return Tema.fuente(peso)


## Texto centrado en «centro» (horizontal) con la línea de base en «base».
static func texto(ci: CanvasItem, t: String, centro_x: float, base: float, tam: float, color: Color, peso := Tema.PESO_NEGRITA, alineacion := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var t_px := maxi(roundi(tam), 6)
	var f := fuente(peso)
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, t_px).x
	var x := centro_x - w / 2.0
	if alineacion == HORIZONTAL_ALIGNMENT_LEFT:
		x = centro_x
	elif alineacion == HORIZONTAL_ALIGNMENT_RIGHT:
		x = centro_x - w
	ci.draw_string(f, Vector2(x, base), t, HORIZONTAL_ALIGNMENT_LEFT, -1, t_px, color)


static func ancho_texto(t: String, tam: float, peso := Tema.PESO_NEGRITA) -> float:
	return fuente(peso).get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(roundi(tam), 6)).x


## Chapa de una casilla: sombra, bisel claro arriba a la izquierda, degradado y tornillos.
static func chapa(ci: CanvasItem, r: Rect2, s: float, colores: Array = CHAPA, disparo := false) -> void:
	if disparo:
		for i in 4:
			DibujoAri.relleno(ci, r.grow((4.0 - i) * s), (8.0 + 4.0 - i) * s, Color(1.0, 0.23, 0.18, 0.12 + i * 0.05))
	DibujoAri.sombra(ci, r, 6.0 * s, 0.55, Vector2(0, 2.5 * s), 3)
	DibujoAri.degradado(ci, r, 6.0 * s, BISEL)
	var dentro := r.grow(-1.5 * s)
	DibujoAri.degradado(ci, dentro, 5.0 * s, colores)
	# Grano de la pintura: líneas finas casi transparentes.
	var y := dentro.position.y + 3.0 * s
	var k := 0
	while y < dentro.end.y - 3.0 * s:
		ci.draw_line(Vector2(dentro.position.x + 3.0 * s, y), Vector2(dentro.end.x - 3.0 * s, y), Color(1, 1, 1, 0.025 if k % 2 == 0 else 0.012), 1.0)
		y += 2.0 * s
		k += 1
	if disparo:
		DibujoAri.borde(ci, r, 6.0 * s, Color("ff5247"), maxf(2.0 * s, 1.5))
	for p: Vector2 in [Vector2(7, 7), Vector2(r.size.x / s - 7, 7), Vector2(7, r.size.y / s - 7), Vector2(r.size.x / s - 7, r.size.y / s - 7)]:
		tornillo(ci, r.position + p * s, 2.6 * s)


static func tornillo(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.25), r + r * 0.2, Color(0.04, 0.12, 0.2, 0.55))
	_disco(ci, c, r, Color("f4f6f8"), Color("4b545c"), Vector2(-0.35, -0.4))
	var d := Vector2.from_angle(0.6) * r * 0.75
	ci.draw_line(c - d, c + d, Color("3a4148"), maxf(r * 0.38, 1.0))


## Disco con degradado radial aproximado por anillos, con el punto de luz desplazado.
static func _disco(ci: CanvasItem, c: Vector2, r: float, claro: Color, oscuro: Color, luz := Vector2(-0.3, -0.35), pasos := 8) -> void:
	for i in pasos:
		var f := float(i) / pasos
		var radio := r * (1.0 - f * 0.85)
		var centro := c + luz * r * f * 0.6
		ci.draw_circle(centro, radio, oscuro.lerp(claro, f))


## Rótulo grabado: placa negra con borde claro, texto blanco y la franja de color debajo.
static func rotulo(ci: CanvasItem, r: Rect2, t: String, s: float, franja := Color.TRANSPARENT, tam := 9.5) -> void:
	DibujoAri.degradado(ci, r, 1.5 * s, ROTULO)
	DibujoAri.borde(ci, r, 1.5 * s, ROTULO_BORDE, maxf(0.6 * s, 1.0))
	var t_px := tam * s
	while t_px > 6.0 and ancho_texto(t, t_px) > r.size.x - 6.0 * s:
		t_px -= 0.5
	texto(ci, t, r.get_center().x, r.get_center().y + t_px * 0.36, t_px, Color.WHITE)
	if franja.a > 0.0:
		var f := Rect2(r.position.x, r.end.y + 1.0 * s, r.size.x, 2.4 * s)
		DibujoAri.relleno(ci, f, 1.0 * s, franja)


## Placa pequeña de texto, como STOP o START bajo los botones.
static func placa(ci: CanvasItem, r: Rect2, t: String, s: float, tam := 5.2) -> void:
	DibujoAri.degradado(ci, r, 1.2 * s, ROTULO)
	DibujoAri.borde(ci, r, 1.2 * s, Color("5d7891"), 1.0)
	var t_px := tam * s
	while t_px > 5.0 and ancho_texto(t, t_px) > r.size.x - 2.0 * s:
		t_px -= 0.5
	texto(ci, t, r.get_center().x, r.get_center().y + t_px * 0.37, t_px, Color("e8eef3"))


## Lámpara piloto con aro cromado, lente con su brillo y, encendida, un halo de luz.
static func lampara(ci: CanvasItem, c: Vector2, r: float, color: String, brillo: float) -> void:
	var p: Array = LAMPARAS.get(color, LAMPARAS["verde"])
	var on := brillo > 0.05
	if on:
		for i in 6:
			var f := float(i) / 6.0
			ci.draw_circle(c, r * (2.3 - f * 1.1), Color(p[4], (0.05 + f * 0.09) * brillo))
	ci.draw_circle(c + Vector2(0, r * 0.15), r + r * 0.45, Color(0, 0, 0, 0.4))
	_disco(ci, c, r + r * 0.37, Color("ffffff"), Color("2b3238"))
	if on:
		_disco(ci, c, r, (p[2] as Color).lerp(p[3], 1.0 - brillo), (p[3] as Color).darkened(0.4), Vector2(-0.2, -0.3), 10)
	else:
		_disco(ci, c, r, p[0], p[1], Vector2(-0.2, -0.3), 8)
	ci.draw_arc(c, r * 0.62, 0, TAU, 24, Color(1, 1, 1, 0.25 if on else 0.08), maxf(r * 0.1, 0.8), true)
	_elipse(ci, c + Vector2(-r * 0.3, -r * 0.42), Vector2(r * 0.42, r * 0.22), -0.44, Color(1, 1, 1, 0.85 if on else 0.3))


static func _elipse(ci: CanvasItem, c: Vector2, radios: Vector2, angulo: float, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		p.append(c + Vector2(cos(a) * radios.x, sin(a) * radios.y).rotated(angulo))
	ci.draw_colored_polygon(p, color)


## Amperímetro de cuadro de 72 mm: marco negro, esfera crema, zona roja desde la nominal y
## aguja con sombra. «unidad» se rotula abajo, como «A», «kW», «V» o «Hz».
static func amperimetro(ci: CanvasItem, r: Rect2, s: float, valor: float, minimo: float, fondo: float, nominal: float, unidad := "A") -> void:
	DibujoAri.relleno(ci, Rect2(r.position + Vector2(-1, 1.5) * s, r.size + Vector2(2, 2) * s), 3.0 * s, Color(0, 0, 0, 0.45))
	DibujoAri.degradado(ci, r, 3.0 * s, MARCO_INSTRUMENTO)
	var m := 4.5 * s
	var cara := r.grow(-m)
	DibujoAri.degradado(ci, cara, 1.5 * s, CARA)
	var centro := Vector2(r.get_center().x, r.end.y + 4.0 * s)
	var radio := r.size.y - 8.5 * s
	var a0 := deg_to_rad(132.0)
	var a1 := deg_to_rad(48.0)
	var punto := func(fr: float, rr: float) -> Vector2:
		var a := a0 - (a0 - a1) * fr
		return centro + Vector2(cos(a), -sin(a)) * rr
	var rango := maxf(fondo - minimo, 0.001)
	# Zona roja desde la nominal hasta el fondo de escala.
	if nominal < fondo:
		var fr_n := clampf((nominal - minimo) / rango, 0.0, 1.0)
		var zona := PackedVector2Array()
		for i in 13:
			zona.append(punto.call(lerpf(fr_n, 1.0, i / 12.0), radio - 2.5 * s))
		ci.draw_polyline(zona, ROJO_ESCALA, maxf(3.0 * s, 1.5), true)
	var arco := PackedVector2Array()
	for i in 25:
		arco.append(punto.call(i / 24.0, radio))
	ci.draw_polyline(arco, TINTA, maxf(0.7 * s, 1.0), true)
	var tam := 6.2 * s
	for k in 13:
		var fr := k / 12.0
		var larga := k % 6 == 0
		var media := k % 3 == 0
		var largo := 6.5 if larga else (4.5 if media else 3.0)
		ci.draw_line(punto.call(fr, radio), punto.call(fr, radio - largo * s), Color("1d1d1d"), maxf((1.1 if larga else 0.6) * s, 1.0), true)
		if larga:
			var q: Vector2 = punto.call(fr, radio - 11.5 * s)
			texto(ci, _numero_escala(minimo + rango * fr), q.x, q.y + tam * 0.36, tam, TINTA)
	var fr_v := clampf((valor - minimo) / rango, -0.03, 1.05)
	var punta: Vector2 = punto.call(fr_v, radio + 1.0 * s)
	ci.draw_line(centro + Vector2(1, 1.5) * s, punta + Vector2(1, 1.5) * s, Color(0, 0, 0, 0.35), maxf(1.4 * s, 1.0), true)
	ci.draw_line(centro, punta, AGUJA, maxf(1.4 * s, 1.0), true)
	var banda := Rect2(cara.position.x, cara.end.y - 9.0 * s, cara.size.x, 9.0 * s)
	ci.draw_rect(banda, Color("1b1f23"))
	texto(ci, unidad, banda.get_center().x, banda.end.y - 2.3 * s, 6.4 * s, Color("e9eef2"))
	texto(ci, "CL 1.5", banda.end.x - 2.0 * s, banda.end.y - 2.6 * s, 3.6 * s, Color("8b949c"), Tema.PESO_MEDIO, HORIZONTAL_ALIGNMENT_RIGHT)
	# Reflejo del cristal.
	ci.draw_colored_polygon(PackedVector2Array([cara.position, Vector2(cara.end.x, cara.position.y), cara.position + Vector2(10.0 * s, cara.size.y * 0.5)]), Color(1, 1, 1, 0.13))


static func _numero_escala(v: float) -> String:
	if absf(v - roundf(v)) < 0.01:
		return str(int(roundf(v)))
	return LecturaLcd.numero(v, 1)


## Visor negro con dígitos de siete segmentos alineados a la derecha y la unidad.
static func visor(ci: CanvasItem, r: Rect2, s: float, t: String, unidad := "", color := Tema.ARI_LCD_VERDE, alto_cifra := 0.0) -> void:
	DibujoAri.degradado(ci, r, 2.5 * s, [Color("05080a"), Color("3b5466")])
	var dentro := r.grow(-1.5 * s)
	DibujoAri.degradado(ci, dentro, 1.5 * s, [Tema.ARI_LCD_FONDO, Color("0b1510")])
	var h := alto_cifra if alto_cifra > 0.0 else r.size.y * 0.62
	var tam_u := h * 0.62
	var ancho_u := (ancho_texto(unidad, tam_u) + 3.0 * s) if not unidad.is_empty() else 0.0
	var ancho_t := DibujoAri.ancho_seg7(t, h)
	# Si no cabe, se achica la cifra.
	var disponible := r.size.x - 6.0 * s - ancho_u
	if ancho_t > disponible and ancho_t > 0.0:
		h *= disponible / ancho_t
		ancho_t = DibujoAri.ancho_seg7(t, h)
	var x := r.end.x - 3.0 * s - ancho_u - ancho_t
	DibujoAri.seg7(ci, t, Vector2(x, r.get_center().y - h / 2.0), h, color)
	if not unidad.is_empty():
		texto(ci, unidad, r.end.x - 3.0 * s, r.get_center().y + tam_u * 0.36, tam_u, Color(color, 0.85), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_RIGHT)
	DibujoAri.degradado(ci, Rect2(dentro.position, Vector2(dentro.size.x, dentro.size.y * 0.42)), 1.0, [Color(1, 1, 1, 0.13), Color(1, 1, 1, 0.0)])


## Interruptor de caja moldeada: «estado» es «on», «off» o «trip». ON con la palanca arriba,
## OFF abajo y TRIP en medio con la ventana ámbar.
static func interruptor(ci: CanvasItem, r: Rect2, s: float, estado: String, rotulo_caja := "") -> void:
	DibujoAri.relleno(ci, Rect2(r.position + Vector2(-1, 2) * s, r.size + Vector2(2, 0)), 3.0 * s, Color(0, 0, 0, 0.45))
	DibujoAri.degradado(ci, r, 3.0 * s, CAJA)
	DibujoAri.borde(ci, r, 3.0 * s, Color("0c0e10"), 1.0)
	var cabeza := Rect2(r.position + Vector2(3, 3) * s, Vector2(r.size.x - 6.0 * s, 5.0 * s))
	DibujoAri.relleno(ci, cabeza, 1.0 * s, Color("15181b"))
	if not rotulo_caja.is_empty():
		texto(ci, rotulo_caja, cabeza.get_center().x, cabeza.end.y - 1.2 * s, 3.8 * s, Color("9aa3ab"))
	var ranura := Rect2(r.get_center().x - 6.0 * s, r.position.y + 12.0 * s, 12.0 * s, r.size.y - 30.0 * s)
	DibujoAri.relleno(ci, ranura, 2.0 * s, Color("0a0c0e"))
	var alto_palanca := 13.0 * s
	var y := ranura.position.y + 1.0 * s
	if estado == "trip":
		y = ranura.get_center().y - alto_palanca / 2.0
	elif estado == "off":
		y = ranura.end.y - alto_palanca - 1.0 * s
	var palanca := Rect2(ranura.position.x + 1.0 * s, y, ranura.size.x - 2.0 * s, alto_palanca)
	DibujoAri.degradado(ci, palanca, 1.5 * s, [Color("5a6067"), Color("15181b")])
	DibujoAri.borde(ci, palanca, 1.5 * s, Color(0, 0, 0, 0.8), 1.0)
	ci.draw_line(palanca.position + Vector2(2, 2) * s, Vector2(palanca.end.x - 2.0 * s, palanca.position.y + 2.0 * s), Color(1, 1, 1, 0.3), 1.0)
	var ventana := Rect2(r.position.x + 3.0 * s, r.end.y - 15.0 * s, r.size.x - 6.0 * s, 11.0 * s)
	var fondo := Color("c81b12")
	var tinta := Color.WHITE
	var t := "ON  I"
	if estado == "trip":
		fondo = Color("ffb020")
		tinta = Color("1b1200")
		t = "TRIP"
	elif estado == "off":
		fondo = Color("2fbf4f")
		tinta = Color("06210e")
		t = "OFF  O"
	DibujoAri.relleno(ci, ventana, 1.5 * s, fondo)
	texto(ci, t, ventana.get_center().x, ventana.end.y - 3.3 * s, 6.4 * s, tinta)


## Selector rotativo con sus posiciones rotuladas. «posicion» es el índice de la elegida y
## «nombres» los rótulos cortos, de izquierda a derecha.
static func selector(ci: CanvasItem, c: Vector2, s: float, nombres: Array, posicion: int) -> void:
	var n := maxi(nombres.size(), 1)
	var angulos: Array[float] = []
	for i in n:
		angulos.append(135.0 - 90.0 * i / maxf(n - 1, 1) if n > 1 else 90.0)
	for i in n:
		var a := deg_to_rad(angulos[i])
		var dir := Vector2(cos(a), -sin(a))
		ci.draw_line(c + dir * 13.0 * s, c + dir * 16.0 * s, Color("e8f1f8"), maxf(1.4 * s, 1.0))
		var q := c + dir * 22.0 * s
		texto(ci, str(nombres[i]), q.x, q.y + 2.0 * s, 5.2 * s, TEXTO_CHAPA if i != posicion else Color("ffd23d"))
	ci.draw_circle(c + Vector2(0, 1.5 * s), 12.5 * s, Color(0, 0, 0, 0.45))
	_disco(ci, c, 12.0 * s, Color("ffffff"), Color("2b3238"))
	_disco(ci, c, 10.0 * s, Color("5b6168"), Color("050607"), Vector2(-0.24, -0.4))
	var a := deg_to_rad(angulos[clampi(posicion, 0, n - 1)])
	var giro := PI / 2.0 - a
	var mango := PackedVector2Array()
	for p: Vector2 in [Vector2(-3.4, -10.5), Vector2(3.4, -10.5), Vector2(3.4, 10.5), Vector2(-3.4, 10.5)]:
		mango.append(c + (p * s).rotated(giro))
	ci.draw_colored_polygon(mango, Color("2a2e33"))
	ci.draw_polyline(mango + PackedVector2Array([mango[0]]), Color(0, 0, 0, 0.9), 1.0, true)
	var brillo := PackedVector2Array()
	for p: Vector2 in [Vector2(-1.2, -10.0), Vector2(1.2, -10.0), Vector2(1.2, 10.0), Vector2(-1.2, 10.0)]:
		brillo.append(c + (p * s).rotated(giro))
	ci.draw_colored_polygon(brillo, Color(1, 1, 1, 0.16))
	ci.draw_line(c + (Vector2(0, -9.5) * s).rotated(giro), c + (Vector2(0, -5.0) * s).rotated(giro), Color.WHITE, maxf(1.4 * s, 1.0), true)


## Botón redondo con aro, como TEST o los pulsadores de un panel de mando.
static func boton(ci: CanvasItem, c: Vector2, r: float, s: float, color: Color, t := "", pulsado := false) -> void:
	ci.draw_circle(c + Vector2(0, 1.6 * s), r + 2.8 * s, Color(0, 0, 0, 0.45))
	_disco(ci, c, r + 2.4 * s, Color("ffffff"), Color("2b3238"))
	var centro := c + (Vector2(0, 0.8 * s) if pulsado else Vector2.ZERO)
	_disco(ci, centro, r, color.lightened(0.45 if not pulsado else 0.2), color.darkened(0.45), Vector2(-0.2, -0.3), 10)
	_elipse(ci, centro + Vector2(-r * 0.25, -r * 0.45), Vector2(r * 0.5, r * 0.22), 0.0, Color(1, 1, 1, 0.45 if not pulsado else 0.2))
	if not t.is_empty():
		var tam := minf(r * 0.62, 7.0 * s)
		texto(ci, t, centro.x + 0.6, centro.y + tam * 0.36 + 0.8, tam, Color(0, 0, 0, 0.6))
		texto(ci, t, centro.x, centro.y + tam * 0.36, tam, Color.WHITE)


## Candado amarillo con su tarjeta roja de «NO OPERAR», del bloqueo y etiquetado.
static func candado(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, -2) * s, 5.0 * s, PI, TAU, 12, Color("c9d0d6"), maxf(2.4 * s, 1.5), true)
	ci.draw_line(c + Vector2(-5, -2) * s, c + Vector2(-5, 0) * s, Color("c9d0d6"), maxf(2.4 * s, 1.5))
	ci.draw_line(c + Vector2(5, -2) * s, c + Vector2(5, 0) * s, Color("c9d0d6"), maxf(2.4 * s, 1.5))
	var cuerpo := Rect2(c + Vector2(-7.5, -1) * s, Vector2(15, 12) * s)
	DibujoAri.degradado(ci, cuerpo, 2.0 * s, [Color("ffd23d"), Color("c89400")])
	DibujoAri.borde(ci, cuerpo, 2.0 * s, Color("7a5000"), 1.0)
	ci.draw_circle(cuerpo.get_center(), 1.6 * s, Color("3a2a00"))
	var tarjeta := PackedVector2Array()
	for p: Vector2 in [Vector2(6, 3), Vector2(22, 7), Vector2(20, 17), Vector2(4, 13)]:
		tarjeta.append(c + p * s)
	ci.draw_colored_polygon(tarjeta, Color("e2392d"))
	texto(ci, "NO", c.x + 13.0 * s, c.y + 12.5 * s, 4.6 * s, Color.WHITE)


## Escala redonda para un amperímetro: el primer fondo de escala de la serie que deje la nominal
## hacia los dos tercios, como en los cuadros reales.
static func fondo_escala(nominal: float) -> float:
	for f: float in [1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0, 60.0, 80.0, 100.0, 150.0, 200.0, 250.0, 300.0, 400.0, 500.0, 600.0, 800.0, 1000.0, 1500.0]:
		if f >= nominal * 1.4:
			return f
	return ceilf(nominal * 1.5)
