class_name Relieve
extends RefCounted
## Piezas con relieve para el inicio y la Escuela, que siguen con el tema oscuro y el color por
## área: placas con bisel, medallas con anillo de avance, monedas del camino de lecciones y
## lámparas de estado con halo. Comparten el dibujo de DibujoAri y PiezasAri con el marco.

const PLACA := [Color("25303b"), Color("1c252e"), Color("171f27")]
const PLACA_BORDE := Color("33414e")
const HUECO := [Color("0b1015"), Color("161e26"), Color("1f2933")]
const HUECO_BORDE := Color("2b3642")
const GRIS_OFF := [Color("3a4550"), Color("232c35"), Color("141a20")]
const AMBAR := Color("ffc23a")
const AMBAR_HALO := Color("ffb020")
const VERDE_MARCA := Color("22c55e")
## Lámpara de estado de cada sistema en el buque del inicio.
const LAMPARA_ESTADO := {"completo": "verde", "en_curso": "ambar", "averia": "rojo"}
const LEYENDA := [["completo", "completo"], ["en_curso", "en curso"], ["averia", "avería"], ["sin_empezar", "sin empezar"]]

static var _iconos := {}


## Icono blanco de art/iconos rasterizado con margen para pantallas densas; queda en caché.
static func icono(nombre: String, lado: float) -> Texture2D:
	var px := maxi(ceili(lado * 3.0), 16)
	var clave := "%s@%d" % [nombre, px]
	if not _iconos.has(clave):
		var ruta := "res://art/iconos/%s.svg" % nombre
		_iconos[clave] = VistaSvg.rasterizar(ruta, px / 64.0) if FileAccess.file_exists(ruta) else null
	return _iconos[clave]


static func dibujar_icono(ci: CanvasItem, nombre: String, centro: Vector2, lado: float, tinte := Color.WHITE) -> void:
	var t := icono(nombre, lado)
	if t != null:
		ci.draw_texture_rect(t, Rect2(centro - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), false, tinte)


## Placa oscura con bisel para las tarjetas: degradado, borde, canto de luz y sombra.
static func estilo_placa(margen_x := 12.0, margen_y := 10.0, radio := 12.0, borde := PLACA_BORDE) -> EstiloAri:
	var e := EstiloAri.crear(PLACA, margen_x, margen_y, radio)
	e.borde = borde
	e.luz = Color(1, 1, 1, 0.12)
	e.sombra = 0.55
	e.hueco = Vector2(1, 1)
	return e


## Hueco oscuro, como el fondo de un cajón: sin sombra fuera y con el canto de luz apagado.
static func estilo_hueco(margen := 8.0, radio := 12.0) -> EstiloAri:
	var e := EstiloAri.crear(HUECO, margen, margen, radio)
	e.borde = HUECO_BORDE
	e.luz = Color(0, 0, 0, 0.6)
	e.sombra = 0.0
	e.hueco = Vector2.ZERO
	return e


## Halo de luz: discos concéntricos cada vez más tenues.
static func halo(ci: CanvasItem, c: Vector2, r: float, color: Color, intensidad := 1.0) -> void:
	for i in 7:
		var f := float(i) / 7.0
		ci.draw_circle(c, r * (1.0 - f * 0.55), Color(color, (0.035 + f * 0.05) * intensidad))


## Anillo de avance que empieza arriba y gira en el sentido de las agujas.
static func anillo(ci: CanvasItem, c: Vector2, r: float, ancho: float, fraccion: float, color := AMBAR, fondo := Color("2a343e")) -> void:
	if fondo.a > 0.0:
		ci.draw_arc(c, r, 0.0, TAU, 48, fondo, ancho, true)
	if fraccion > 0.0:
		ci.draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * clampf(fraccion, 0.0, 1.0), 48, color, ancho, true)


## Medalla de un módulo o del rango: aro oscuro con el anillo de avance, disco del color del
## área con su brillo y el icono (o una letra). Una medalla elegida brilla en ámbar.
static func medalla(ci: CanvasItem, c: Vector2, r: float, color: Color, nombre_icono: String, avance: float, elegida := false, cerrada := false, letra := "") -> void:
	if elegida:
		halo(ci, c, r * 2.0, AMBAR_HALO, 1.3)
	ci.draw_circle(c + Vector2(0, r * 0.14), r * 1.24, Color(0, 0, 0, 0.5))
	ci.draw_circle(c, r * 1.22, Color("0c1116"))
	ci.draw_arc(c, r * 1.22, 0, TAU, 48, Color("3b4855"), 1.0, true)
	anillo(ci, c, r * 1.11, maxf(r * 0.16, 2.0), avance, AMBAR, Color.TRANSPARENT)
	var base := color if not cerrada else Color("3a4550")
	PiezasAri._disco(ci, c, r, base.lightened(0.28), base.darkened(0.3), Vector2(-0.25, -0.35), 10)
	ci.draw_arc(c, r - 0.5, 0, TAU, 48, Color(1, 1, 1, 0.22), 1.0, true)
	PiezasAri._elipse(ci, c + Vector2(-r * 0.2, -r * 0.52), Vector2(r * 0.6, r * 0.24), 0.0, Color(1, 1, 1, 0.22))
	if not letra.is_empty():
		PiezasAri.texto(ci, letra, c.x, c.y + r * 0.36, r, Tema.ARI_TEXTO_OSCURO, Tema.PESO_NEGRITA)
	elif not nombre_icono.is_empty():
		dibujar_icono(ci, nombre_icono, c, r * 1.1, Color(1, 1, 1, 0.45 if cerrada else 1.0))
	if cerrada:
		candado(ci, c + Vector2(r * 0.72, r * 0.72), maxf(r / 22.0, 0.6))


## Candado gris de los módulos que todavía no tienen contenido.
static func candado(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, -2) * s, 3.6 * s, PI, TAU, 12, Color("9aa6b1"), maxf(2.0 * s, 1.2), true)
	ci.draw_line(c + Vector2(-3.6, -2) * s, c + Vector2(-3.6, 0) * s, Color("9aa6b1"), maxf(2.0 * s, 1.2))
	ci.draw_line(c + Vector2(3.6, -2) * s, c + Vector2(3.6, 0) * s, Color("9aa6b1"), maxf(2.0 * s, 1.2))
	var cuerpo := Rect2(c + Vector2(-6, -2) * s, Vector2(12, 10) * s)
	DibujoAri.degradado(ci, cuerpo, 2.0 * s, [Color("c3ccd4"), Color("7d8892")])
	DibujoAri.borde(ci, cuerpo, 2.0 * s, Color("1b2228"), 1.0)
	ci.draw_circle(cuerpo.get_center(), 1.4 * s, Color("1b2228"))


## Moneda del camino de lecciones. «hecha»: del color del módulo con una marca; «actual»: ámbar
## con el triángulo de empezar y un halo; «pendiente»: hundida, con su número o su icono.
static func moneda(ci: CanvasItem, c: Vector2, r: float, tipo: String, numero: int, color: Color, nombre_icono := "") -> void:
	if tipo == "actual":
		halo(ci, c, r * 1.9, AMBAR_HALO, 1.5)
		var pasos := 28
		for i in pasos:
			if i % 2 == 0:
				var a0 := TAU * i / pasos
				ci.draw_arc(c, r + r * 0.36, a0, a0 + TAU / pasos * 0.8, 3, Color(Tema.ACENTO, 0.55), 1.5, true)
	ci.draw_circle(c + Vector2(0, r * 0.17), r * 1.13, Color(0, 0, 0, 0.55))
	if tipo == "pendiente":
		ci.draw_circle(c, r * 1.13, Color("0b1015"))
		ci.draw_arc(c, r * 1.13, 0, TAU, 40, Color("3b4855"), 1.0, true)
		PiezasAri._disco(ci, c, r, GRIS_OFF[0], GRIS_OFF[2], Vector2(-0.2, -0.3), 8)
		# Sombra interior: el hueco recibe la luz desde abajo.
		ci.draw_arc(c, r - 1.5, PI * 1.1, PI * 1.9, 20, Color(0, 0, 0, 0.55), 3.0, true)
		ci.draw_arc(c, r - 1.0, PI * 0.15, PI * 0.85, 20, Color(1, 1, 1, 0.07), 1.5, true)
		if not nombre_icono.is_empty():
			dibujar_icono(ci, nombre_icono, c, r * 0.95, Color(1, 1, 1, 0.45))
		else:
			PiezasAri.texto(ci, str(numero), c.x, c.y + r * 0.36, r * 0.95, Color("7f8c97"), Tema.PESO_NEGRITA)
		return
	PiezasAri._disco(ci, c, r * 1.13, Color("ffffff"), Color("2b3238"))
	if tipo == "actual":
		PiezasAri._disco(ci, c, r, Color("fff4cf"), Color("a86500"), Vector2(-0.24, -0.4), 10)
		var t := PackedVector2Array([c + Vector2(-0.28, -0.44) * r, c + Vector2(0.5, 0) * r, c + Vector2(-0.28, 0.44) * r])
		ci.draw_colored_polygon(t, Color("2a1a00"))
	else:
		PiezasAri._disco(ci, c, r, color.lightened(0.3), color.darkened(0.25), Vector2(-0.24, -0.4), 10)
		var tinta := Color("1d1400") if color.get_luminance() > 0.45 else Color.WHITE
		var marca := PackedVector2Array([c + Vector2(-0.38, 0.02) * r, c + Vector2(-0.1, 0.32) * r, c + Vector2(0.42, -0.3) * r])
		ci.draw_polyline(marca, tinta, maxf(r * 0.2, 2.0), true)
	PiezasAri._elipse(ci, c + Vector2(-r * 0.15, -r * 0.52), Vector2(r * 0.6, r * 0.25), 0.0, Color(1, 1, 1, 0.4))


## Lámpara de estado: verde, ámbar o roja encendidas con su halo; apagada, gris.
static func lampara_estado(ci: CanvasItem, c: Vector2, r: float, estado: String) -> void:
	if LAMPARA_ESTADO.has(estado):
		PiezasAri.lampara(ci, c, r, LAMPARA_ESTADO[estado], 1.0)
		return
	ci.draw_circle(c + Vector2(0, r * 0.15), r * 1.45, Color(0, 0, 0, 0.45))
	PiezasAri._disco(ci, c, r * 1.37, Color("ffffff"), Color("2b3238"))
	PiezasAri._disco(ci, c, r, GRIS_OFF[0], GRIS_OFF[2], Vector2(-0.2, -0.3), 8)
	PiezasAri._elipse(ci, c + Vector2(-r * 0.3, -r * 0.42), Vector2(r * 0.42, r * 0.2), -0.44, Color(1, 1, 1, 0.25))


## Insignia roja con un número, como los temas del repaso.
static func insignia(ci: CanvasItem, c: Vector2, texto: String, tam := 11.0) -> void:
	var w := maxf(PiezasAri.ancho_texto(texto, tam) + tam * 0.9, tam * 1.8)
	var r := Rect2(c - Vector2(w, tam * 1.8) / 2.0, Vector2(w, tam * 1.8))
	halo(ci, c, tam * 1.9, Color("ff3b2f"), 1.2)
	DibujoAri.relleno(ci, r.grow(1.5), r.size.y, Color("10161c"))
	DibujoAri.degradado(ci, r, r.size.y / 2.0, [Color("ff8b80"), Color("d8372c"), Color("9f1e16")])
	PiezasAri.texto(ci, texto, c.x, c.y + tam * 0.36, tam, Color.WHITE)


## Rellena un polígono con un degradado lineal entre «desde» y «hasta», con varias paradas.
static func poligono_degradado(ci: CanvasItem, puntos: PackedVector2Array, colores: Array, desde: Vector2, hasta: Vector2) -> void:
	var eje := hasta - desde
	var largo := eje.length()
	if largo < 0.01 or puntos.size() < 3:
		return
	var d := eje / largo
	var n := Vector2(-d.y, d.x) * 10000.0
	var tramos := colores.size() - 1
	for k in tramos:
		var t0 := float(k) / tramos if k > 0 else -20.0
		var t1 := float(k + 1) / tramos if k < tramos - 1 else 20.0
		var a := desde + eje * t0
		var b := desde + eje * t1
		var banda := PackedVector2Array([a - n, b - n, b + n, a + n])
		var c0: Color = colores[k]
		var c1: Color = colores[k + 1]
		var p0 := float(k) / tramos
		var p1 := float(k + 1) / tramos
		for trozo: PackedVector2Array in Geometry2D.intersect_polygons(puntos, banda):
			if trozo.size() < 3 or Geometry2D.triangulate_polygon(trozo).is_empty():
				continue
			var cols := PackedColorArray()
			for q in trozo:
				var t := (q - desde).dot(d) / largo
				cols.append(c0.lerp(c1, clampf((t - p0) / (p1 - p0), 0.0, 1.0)))
			ci.draw_polygon(trozo, cols)


## Marca numerada sobre un dibujo: moneda ámbar con aro cromado, brillo y la cifra oscura.
## «elegida» la agranda con un halo y una corona de trazos; «apagada» la deja gris y hundida,
## como un paso que todavía no ha llegado.
static func marca(ci: CanvasItem, c: Vector2, r: float, numero: int, elegida := false, apagada := false, con_halo := true) -> void:
	if elegida:
		halo(ci, c, r * 2.4, AMBAR_HALO, 1.6)
		var pasos := 24
		for i in pasos:
			if i % 2 == 0:
				var a0 := TAU * i / pasos
				ci.draw_arc(c, r * 1.55, a0, a0 + TAU / pasos * 0.75, 3, Color(Tema.ACENTO, 0.85), maxf(r * 0.12, 1.2), true)
	elif con_halo and not apagada:
		halo(ci, c, r * 1.6, AMBAR_HALO, 0.8)
	ci.draw_circle(c + Vector2(0, r * 0.18), r * 1.2, Color(0, 0, 0, 0.55))
	PiezasAri._disco(ci, c, r * 1.16, Color("ffffff"), Color("2b3238"))
	if apagada:
		PiezasAri._disco(ci, c, r, GRIS_OFF[0], GRIS_OFF[2], Vector2(-0.2, -0.3), 8)
		ci.draw_arc(c, r - 1.0, PI * 1.1, PI * 1.9, 16, Color(0, 0, 0, 0.5), 2.0, true)
		PiezasAri.texto(ci, str(numero), c.x, c.y + r * 0.38, r * 1.05, Color("8a97a2"), Tema.PESO_NEGRITA)
		return
	PiezasAri._disco(ci, c, r, Color("fff4cf"), Color("a86500"), Vector2(-0.24, -0.4), 10)
	PiezasAri._elipse(ci, c + Vector2(-r * 0.15, -r * 0.5), Vector2(r * 0.6, r * 0.26), 0.0, Color(1, 1, 1, 0.45))
	PiezasAri.texto(ci, str(numero), c.x, c.y + r * 0.38, r * 1.08, Color("2a1a00"), Tema.PESO_NEGRITA)


## Hoja de papel sobre el visor, para los esquemas y los cortes, que se dibujan en tinta.
static func estilo_papel(margen := 8.0, radio := 9.0) -> EstiloAri:
	var e := EstiloAri.crear([Color("f4f1e6"), Color("e9e6da"), Color("dedac9")], margen, margen, radio)
	e.borde = Color("6f6a58")
	e.luz = Color(1, 1, 1, 0.9)
	e.sombra = 0.55
	e.hueco = Vector2(1, 1)
	return e


static var _foco: GradientTexture2D

## Luz de foco del visor: un degradado radial que aclara el centro del hueco.
static func foco() -> Texture2D:
	if _foco == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 0.8, 1.0])
		g.colors = PackedColorArray([Color("3b4855"), Color("26313c"), Color("141b22"), Color("0d1318")])
		_foco = GradientTexture2D.new()
		_foco.gradient = g
		_foco.fill = GradientTexture2D.FILL_RADIAL
		_foco.fill_from = Vector2(0.5, 0.42)
		_foco.fill_to = Vector2(1.08, 0.95)
		_foco.width = 256
		_foco.height = 256
	return _foco
