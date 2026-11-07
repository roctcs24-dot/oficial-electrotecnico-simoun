class_name DibujoEquipos
extends RefCounted
## Dibujo semirrealista de máquinas para los esquemas que se pintan por código: recipientes con
## cabezas abombadas, motores con aletas y ventilador, bombas centrífugas, compresores y bancadas.
## Cada pieza se sombrea como un cilindro iluminado desde arriba a la izquierda, para que tenga
## volumen sin salir del estilo sobrio del resto del juego.

const FRANJAS := 14
const BORDE := Color("101315")
const ACERO := Color("9aa3a6")
const PINTURA_MOTOR := Color("3f5f79")
const PINTURA_COMPRESOR := Color("3e6b4f")
const AMARILLO_PROTECCION := Color("c9a227")


## Color de la superficie de un cilindro a la fracción t de su ancho (0 un borde, 1 el otro).
static func tono(color: Color, t: float) -> Color:
	if t < 0.3:
		return color.darkened(0.35).lerp(color.lightened(0.35), t / 0.3)
	if t < 0.55:
		return color.lightened(0.35).lerp(color, (t - 0.3) / 0.25)
	return color.lerp(color.darkened(0.55), (t - 0.55) / 0.45)


## Rectángulo sombreado como un cilindro. Con eje horizontal la luz varía de arriba abajo.
static func cilindro(ci: CanvasItem, r: Rect2, color: Color, eje_horizontal := true) -> void:
	for i in FRANJAS:
		var t0 := float(i) / FRANJAS
		var t1 := float(i + 1) / FRANJAS
		var p: PackedVector2Array
		if eje_horizontal:
			p = PackedVector2Array([Vector2(r.position.x, r.position.y + r.size.y * t0), Vector2(r.end.x, r.position.y + r.size.y * t0), Vector2(r.end.x, r.position.y + r.size.y * t1), Vector2(r.position.x, r.position.y + r.size.y * t1)])
			ci.draw_polygon(p, PackedColorArray([tono(color, t0), tono(color, t0), tono(color, t1), tono(color, t1)]))
		else:
			p = PackedVector2Array([Vector2(r.position.x + r.size.x * t0, r.position.y), Vector2(r.position.x + r.size.x * t1, r.position.y), Vector2(r.position.x + r.size.x * t1, r.end.y), Vector2(r.position.x + r.size.x * t0, r.end.y)])
			ci.draw_polygon(p, PackedColorArray([tono(color, t0), tono(color, t1), tono(color, t1), tono(color, t0)]))
	ci.draw_rect(r, BORDE, false, 1.0)


## Recipiente a presión con cabezas abombadas (separador, recibidor, botella, condensador).
## Con eje horizontal las cabezas quedan a izquierda y derecha.
static func recipiente(ci: CanvasItem, r: Rect2, color: Color, eje_horizontal := true) -> void:
	var radio := (r.size.y if eje_horizontal else r.size.x) / 2.0
	var hondo := minf(radio * 0.55, (r.size.x if eje_horizontal else r.size.y) * 0.3)
	var contorno := PackedVector2Array()
	for i in FRANJAS:
		var t0 := float(i) / FRANJAS
		var t1 := float(i + 1) / FRANJAS
		var a0 := _media_cabeza(t0, hondo)
		var a1 := _media_cabeza(t1, hondo)
		var p: PackedVector2Array
		if eje_horizontal:
			var y0 := r.position.y + r.size.y * t0
			var y1 := r.position.y + r.size.y * t1
			p = PackedVector2Array([Vector2(r.position.x + hondo - a0, y0), Vector2(r.end.x - hondo + a0, y0), Vector2(r.end.x - hondo + a1, y1), Vector2(r.position.x + hondo - a1, y1)])
			ci.draw_polygon(p, PackedColorArray([tono(color, t0), tono(color, t0), tono(color, t1), tono(color, t1)]))
		else:
			var x0 := r.position.x + r.size.x * t0
			var x1 := r.position.x + r.size.x * t1
			p = PackedVector2Array([Vector2(x0, r.position.y + hondo - a0), Vector2(x1, r.position.y + hondo - a1), Vector2(x1, r.end.y - hondo + a1), Vector2(x0, r.end.y - hondo + a0)])
			ci.draw_polygon(p, PackedColorArray([tono(color, t0), tono(color, t1), tono(color, t1), tono(color, t0)]))
	# Contorno y costuras de soldadura donde empiezan las cabezas.
	for i in FRANJAS + 1:
		var t := float(i) / FRANJAS
		var a := _media_cabeza(t, hondo)
		if eje_horizontal:
			contorno.append(Vector2(r.end.x - hondo + a, r.position.y + r.size.y * t))
		else:
			contorno.append(Vector2(r.position.x + r.size.x * t, r.end.y - hondo + a))
	for i in range(FRANJAS, -1, -1):
		var t := float(i) / FRANJAS
		var a := _media_cabeza(t, hondo)
		if eje_horizontal:
			contorno.append(Vector2(r.position.x + hondo - a, r.position.y + r.size.y * t))
		else:
			contorno.append(Vector2(r.position.x + r.size.x * t, r.position.y + hondo - a))
	contorno.append(contorno[0])
	ci.draw_polyline(contorno, BORDE, 1.2, true)
	var costura := color.darkened(0.45)
	if eje_horizontal:
		ci.draw_line(Vector2(r.position.x + hondo, r.position.y + 1.0), Vector2(r.position.x + hondo, r.end.y - 1.0), costura, 1.0, true)
		ci.draw_line(Vector2(r.end.x - hondo, r.position.y + 1.0), Vector2(r.end.x - hondo, r.end.y - 1.0), costura, 1.0, true)
	else:
		ci.draw_line(Vector2(r.position.x + 1.0, r.position.y + hondo), Vector2(r.end.x - 1.0, r.position.y + hondo), costura, 1.0, true)
		ci.draw_line(Vector2(r.position.x + 1.0, r.end.y - hondo), Vector2(r.end.x - 1.0, r.end.y - hondo), costura, 1.0, true)


## Cuánto sobresale la cabeza abombada a la fracción t de la altura del recipiente.
static func _media_cabeza(t: float, hondo: float) -> float:
	var d := absf(t - 0.5) * 2.0
	return hondo * sqrt(maxf(1.0 - d * d, 0.0))


## Silleta o pata de apoyo bajo un recipiente.
static func silleta(ci: CanvasItem, centro_arriba: Vector2, ancho: float, alto: float) -> void:
	var p := PackedVector2Array([centro_arriba + Vector2(-ancho * 0.35, 0.0), centro_arriba + Vector2(ancho * 0.35, 0.0), centro_arriba + Vector2(ancho * 0.5, alto), centro_arriba + Vector2(-ancho * 0.5, alto)])
	ci.draw_colored_polygon(p, Color("3a3f43"))
	ci.draw_line(p[3], p[2], Color("1c1f21"), 2.0)


## Mirilla de nivel: tubo de vidrio con el líquido hasta la fracción indicada.
static func mirilla(ci: CanvasItem, r: Rect2, nivel: float, liquido: Color) -> void:
	ci.draw_rect(r.grow(1.5), Color("2b2f32"))
	ci.draw_rect(r, Color("c9d3d6").darkened(0.55))
	var alto := r.size.y * clampf(nivel, 0.0, 1.0)
	ci.draw_rect(Rect2(Vector2(r.position.x, r.end.y - alto), Vector2(r.size.x, alto)), liquido)
	ci.draw_line(r.position + Vector2(r.size.x * 0.3, 1.0), Vector2(r.position.x + r.size.x * 0.3, r.end.y - 1.0), Color(1, 1, 1, 0.35), 1.0)


## Bancada de perfil de acero bajo un grupo motor-máquina.
static func bancada(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color("2c3134"))
	ci.draw_line(r.position, Vector2(r.end.x, r.position.y), Color("6b7276"), 1.5)
	ci.draw_line(Vector2(r.position.x, r.end.y), r.end, Color("111315"), 1.5)


## Motor eléctrico horizontal: carcasa con aletas, tapa del ventilador a un lado, caja de bornes
## arriba y patas. «ventilador_izquierda» decide hacia dónde queda el ventilador; el eje sale al lado
## contrario.
static func motor(ci: CanvasItem, r: Rect2, color := PINTURA_MOTOR, ventilador_izquierda := true) -> void:
	var tapa := r.size.x * 0.2
	var cuerpo := Rect2(r.position + Vector2(tapa if ventilador_izquierda else 0.0, r.size.y * 0.12), Vector2(r.size.x - tapa, r.size.y * 0.76))
	var pata := r.size.x * 0.16
	for x: float in [cuerpo.position.x + cuerpo.size.x * 0.12, cuerpo.end.x - cuerpo.size.x * 0.12 - pata]:
		ci.draw_rect(Rect2(Vector2(x, cuerpo.end.y - 2.0), Vector2(pata, r.end.y - cuerpo.end.y + 2.0)), color.darkened(0.5))
	cilindro(ci, cuerpo, color)
	var aletas := maxi(int(cuerpo.size.y / 4.0), 3)
	for i in range(1, aletas):
		var y := cuerpo.position.y + cuerpo.size.y * i / aletas
		ci.draw_line(Vector2(cuerpo.position.x + 2.0, y), Vector2(cuerpo.end.x - 2.0, y), Color(0, 0, 0, 0.35), 1.0)
	var caja := Rect2(Vector2(cuerpo.get_center().x - cuerpo.size.x * 0.16, r.position.y), Vector2(cuerpo.size.x * 0.32, r.size.y * 0.14))
	cilindro(ci, caja, color)
	var tx := r.position.x if ventilador_izquierda else cuerpo.end.x
	var ventilador := Rect2(Vector2(tx, cuerpo.position.y + cuerpo.size.y * 0.06), Vector2(tapa, cuerpo.size.y * 0.88))
	cilindro(ci, ventilador, color.darkened(0.15))
	for i in range(1, 5):
		var x := ventilador.position.x + ventilador.size.x * i / 5.0
		ci.draw_line(Vector2(x, ventilador.position.y + 2.0), Vector2(x, ventilador.end.y - 2.0), Color(0, 0, 0, 0.45), 1.0)


## Eje y acoplamiento entre el motor y la máquina, con marcas que avanzan si gira.
static func acople(ci: CanvasItem, r: Rect2, giro: float, girando: bool) -> void:
	cilindro(ci, r, AMARILLO_PROTECCION)
	if not girando:
		return
	var paso := r.size.x / 3.0
	var d := fmod(giro * r.size.y * 6.0, paso)
	var x := r.position.x + d
	while x < r.end.x:
		ci.draw_line(Vector2(x, r.position.y + 1.0), Vector2(x - r.size.y * 0.3, r.end.y - 1.0), Color(0, 0, 0, 0.5), 1.5)
		x += paso


## Bomba centrífuga vista de frente: voluta, brida de descarga arriba y rodete que gira.
static func bomba(ci: CanvasItem, centro: Vector2, radio: float, color: Color, giro: float, girando: bool, aro: Color) -> void:
	ci.draw_rect(Rect2(centro + Vector2(-radio * 0.32, -radio * 1.35), Vector2(radio * 0.64, radio * 0.6)), color.darkened(0.3))
	ci.draw_rect(Rect2(centro + Vector2(-radio * 0.5, -radio * 1.45), Vector2(radio, radio * 0.18)), color.darkened(0.45))
	for i in 6:
		var f := 1.0 - i / 6.0
		var c := tono(color, 0.55 - 0.45 * (1.0 - f))
		ci.draw_circle(centro + Vector2(-radio, -radio) * 0.12 * (1.0 - f), radio * f, c)
	ci.draw_arc(centro, radio, 0.0, TAU, 28, aro, 2.0, true)
	var ojo := radio * 0.38
	ci.draw_circle(centro, ojo, color.darkened(0.55))
	var angulo := giro * 40.0 if girando else 0.0
	for i in 5:
		var a := angulo + TAU * i / 5.0
		ci.draw_line(centro, centro + Vector2(cos(a), sin(a)) * ojo * 0.9, color.lightened(0.25), 1.5, true)
	ci.draw_circle(centro, ojo * 0.25, color.lightened(0.4))


## Compresor de pistón con su motor: bancada, motor, acoplamiento y bloque con cilindros y culatas.
## Devuelve el rectángulo del bloque, por donde entran la succión y sale la descarga.
static func compresor_piston(ci: CanvasItem, r: Rect2, giro: float, en_marcha: bool, cilindros := 3) -> Rect2:
	var alto_bancada := r.size.y * 0.08
	var b := Rect2(Vector2(r.position.x, r.end.y - alto_bancada), Vector2(r.size.x * 0.58, alto_bancada))
	bancada(ci, b)
	var m := Rect2(Vector2(r.position.x, r.position.y + r.size.y * 0.3), Vector2(r.size.x * 0.42, r.size.y * 0.62))
	motor(ci, m, PINTURA_MOTOR, true)
	var eje_y := m.position.y + m.size.y * 0.5
	acople(ci, Rect2(Vector2(m.end.x, eje_y - m.size.y * 0.17), Vector2(r.size.x * 0.12, m.size.y * 0.34)), giro, en_marcha)
	var bloque := Rect2(Vector2(r.position.x + r.size.x * 0.54, r.position.y), Vector2(r.size.x * 0.46, r.size.y))
	var carter := Rect2(Vector2(bloque.position.x, bloque.position.y + bloque.size.y * 0.45), Vector2(bloque.size.x, bloque.size.y * 0.55))
	cilindro(ci, carter, PINTURA_COMPRESOR, false)
	ci.draw_line(Vector2(carter.position.x + 2.0, carter.position.y + carter.size.y * 0.55), Vector2(carter.end.x - 2.0, carter.position.y + carter.size.y * 0.55), Color(0, 0, 0, 0.4), 1.0)
	# Mirilla de aceite del cárter.
	var mir := carter.position + Vector2(carter.size.x * 0.24, carter.size.y * 0.75)
	ci.draw_circle(mir, carter.size.y * 0.1, Color("1c1f21"))
	ci.draw_circle(mir, carter.size.y * 0.08, Color("d7b24a"))
	var ancho_cil := bloque.size.x / cilindros
	for i in cilindros:
		var cil := Rect2(Vector2(bloque.position.x + ancho_cil * i + ancho_cil * 0.1, bloque.position.y + bloque.size.y * 0.16), Vector2(ancho_cil * 0.8, bloque.size.y * 0.32))
		cilindro(ci, cil, PINTURA_COMPRESOR.lightened(0.08), false)
		var culata := Rect2(Vector2(cil.position.x - ancho_cil * 0.06, bloque.position.y), Vector2(cil.size.x + ancho_cil * 0.12, bloque.size.y * 0.18))
		cilindro(ci, culata, ACERO.darkened(0.15), false)
		for k in 3:
			var y := culata.position.y + culata.size.y * (k + 1) / 4.0
			ci.draw_line(Vector2(culata.position.x + 1.0, y), Vector2(culata.end.x - 1.0, y), Color(0, 0, 0, 0.35), 1.0)
	return bloque
