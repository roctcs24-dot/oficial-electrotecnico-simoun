extends Animacion
## Luz piloto en corte: lente de color, LED con su resistencia y su puente rectificador, y los
## bornes X1-X2. Se elige el color, que dice qué indica según IEC 60204-1 e IEC 60073, y se da
## tensión; con el LED fundido no se enciende aunque tenga tensión.

const ANCHO := 408.0
const ALTO := 280.0
const COLORES := [
	["rojo", Color("e0302a"), "Emergencia o peligro: pare y actúe."],
	["amarillo", Color("f2c400"), "Condición anormal: vigile o intervenga."],
	["verde", Color("2fb35a"), "Condición normal: en marcha o listo."],
	["azul", Color("2f7fd0"), "Acción obligatoria del operador."],
	["blanco", Color("f4f4f0"), "Información general, sin un significado concreto."],
]

var indice := 2
var tension := true
var fundida := false
var _interruptor: Interruptor
var _botones: Array[Button] = []
var _fundir: Button
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.button_pressed = tension
	_interruptor.toggled.connect(poner_tension)
	tarjeta_control("Tensión en X1-X2 (110 V)", "Toque para quitarla o darla", _interruptor)
	var c := tarjeta_mandos()
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	c.add_child(rejilla)
	for i in COLORES.size():
		var b := boton_mando(rejilla, elegir.bind(i))
		b.text = str(COLORES[i][0]).capitalize()
		_botones.append(b)
	_fundir = boton_mando(rejilla, func() -> void: fundir(not fundida))
	_nota = nota_mandos(c)
	_actualizar()


func elegir(i: int) -> void:
	indice = i
	_actualizar()


func poner_tension(con: bool) -> void:
	tension = con
	_interruptor.set_pressed_no_signal(con)
	_interruptor.queue_redraw()
	_actualizar()


func fundir(si: bool) -> void:
	fundida = si
	_actualizar()


func encendida() -> bool:
	return tension and not fundida


## 1 apagada sin tensión, 2 con tensión pero fundida, 3 encendida.
func fase() -> int:
	if encendida():
		return 3
	return 2 if tension else 1


func _actualizar() -> void:
	if _nota == null:
		return
	for i in _botones.size():
		_botones[i].modulate = Color(1, 1, 1, 1.0 if i == indice else 0.6)
	_fundir.text = "Cambiar el LED" if fundida else "Fundir el LED"
	var texto_color: String = COLORES[indice][2]
	if fundida and tension:
		_nota.text = "Tiene tensión y no enciende: el LED está fundido. Entre X1 y X2 se miden los 110 V."
	else:
		_nota.text = "%s: %s" % [str(COLORES[indice][0]).capitalize(), texto_color]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 12), "CORTE DE UNA LUZ PILOTO DE LED", 12, Color("5b6267"))
	var color: Color = COLORES[indice][1]
	# Frente: aro, lente y halo si está encendida.
	var c := Vector2(110, 120)
	if encendida():
		for k in 6:
			l.draw_circle(c, 70.0 - k * 6.0, Color(color, 0.06 + k * 0.03))
	l.draw_circle(c, 52.0, Color("b8bec2"))
	l.draw_circle(c, 44.0, color if encendida() else color.darkened(0.6))
	l.draw_circle(c + Vector2(-14, -14), 10.0, Color(1, 1, 1, 0.35))
	texto(Vector2(110, 196), "Lente de color", 11, Tema.TINTA)
	# Interior: puente, resistencia y LED.
	l.draw_style_box(Tema.caja(Color("f2f3f1"), 8, 0, 0, Color("5b6267")), Rect2(222, 40, 176, 150))
	var cable := Color("c0392b") if tension else Color("8a949b")
	texto(Vector2(234, 60), "X1", 11, Tema.TINTA, false)
	texto(Vector2(234, 172), "X2", 11, Tema.TINTA, false)
	l.draw_line(Vector2(256, 60), Vector2(280, 60), cable, 2.5)
	l.draw_line(Vector2(256, 172), Vector2(280, 172), cable, 2.5)
	l.draw_rect(Rect2(280, 50, 40, 132), Color("dfe3e4"))
	l.draw_rect(Rect2(280, 50, 40, 132), Tema.TINTA, false, 2.0)
	texto(Vector2(300, 116), "~", 18, Tema.TINTA)
	texto(Vector2(300, 196), "puente", 10, Tema.TINTA)
	l.draw_line(Vector2(320, 80), Vector2(340, 80), cable, 2.5)
	l.draw_rect(Rect2(340, 72, 30, 16), Color("d9b380"))
	texto(Vector2(355, 100), "R", 10, Tema.TINTA)
	l.draw_line(Vector2(370, 80), Vector2(384, 80), cable, 2.5)
	l.draw_line(Vector2(384, 80), Vector2(384, 116), cable, 2.5)
	var led := PackedVector2Array([Vector2(374, 116), Vector2(394, 116), Vector2(384, 134)])
	l.draw_colored_polygon(led, color if encendida() else Color("8a949b"))
	l.draw_line(Vector2(374, 136), Vector2(394, 136), Tema.TINTA, 2.5)
	if fundida:
		l.draw_line(Vector2(372, 112), Vector2(396, 140), Tema.FALLO, 3.0)
	l.draw_line(Vector2(384, 136), Vector2(384, 150), cable, 2.5)
	l.draw_line(Vector2(384, 150), Vector2(320, 150), cable, 2.5)
	texto(Vector2(356, 164), "LED", 10, Tema.TINTA)
	var rotulo := "ENCENDIDA" if encendida() else ("FUNDIDA: NO ENCIENDE" if tension else "SIN TENSIÓN")
	rotulo_estado(Vector2(300, 240), rotulo, Tema.ACIERTO if encendida() else (Color("c0392b") if tension else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
