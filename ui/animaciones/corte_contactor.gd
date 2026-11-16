extends Animacion
## Corte de un contactor de doble ruptura: la bobina de mando (110 V, como la de la simulación)
## magnetiza el núcleo en E, que atrae la armadura y vence el muelle; la armadura arrastra el
## portacontactos y los puentes móviles cierran 1-2, 3-4 y 5-6. A la vez cierra el auxiliar
## 13-14 (NA) y abre el 21-22 (NC). Sin tensión, el muelle devuelve todo a reposo.
## Parámetros: v_bobina (V). fase() dice qué paso de la explicación se está viendo.

const ANCHO := 408.0
const ALTO := 392.0
const COBRE := Color("b26a1e")
const PLATA := Color("d8a24a")
const GRIS := Color("6e7a83")
const HIERRO := Color("596570")
const BORDE := Color("3b444b")
const CORRIENTE := Color("e8462e")
const CAMPO := Color("2f6b8f")
const POLOS := [95.0, 158.0, 221.0]
const CARRERA := 16.0
## Segundos que tarda el campo en crecer o caer y la armadura en recorrer su carrera. Más
## lentos que en la realidad (unas decenas de milisegundos) para poder verlo.
const T_CAMPO := 0.45
const T_CARRERA := 0.55

var tension := true
## 0 sin campo, 1 con todo el campo.
var campo := 1.0
## 0 abierto (armadura arriba), 1 cerrado.
var posicion := 1.0
var _interruptor: Interruptor
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_interruptor = Interruptor.new()
	_interruptor.button_pressed = tension
	_interruptor.toggled.connect(poner_tension)
	_nota = tarjeta_control("Tensión en A1-A2", "", _interruptor)
	_actualizar_nota()


func poner_tension(con: bool) -> void:
	tension = con
	_interruptor.set_pressed_no_signal(con)
	_interruptor.queue_redraw()
	_actualizar_nota()


func _actualizar_nota() -> void:
	_nota.text = "Toque para quitarla y ver cómo abre" if tension else "Toque para dar %d V y ver cómo cierra" % _v_bobina()


func _v_bobina() -> int:
	return int(params.get("v_bobina", 110))


func cerrado() -> bool:
	return posicion > 0.99


## Paso de la explicación que se está viendo: 1 el campo, 2 la armadura en marcha, 3 los
## contactos ya cambiados.
func fase() -> int:
	if tension:
		if posicion > 0.99:
			return 3
		return 2 if campo > 0.99 else 1
	if posicion < 0.01:
		return 3
	return 2 if campo < 0.01 else 1


func _process(delta: float) -> void:
	if tension:
		campo = move_toward(campo, 1.0, delta / T_CAMPO)
		# La armadura arranca cuando el campo vence la fuerza del muelle.
		if campo > 0.6:
			posicion = move_toward(posicion, 1.0, delta / T_CARRERA)
	else:
		campo = move_toward(campo, 0.0, delta / T_CAMPO)
		if campo < 0.4:
			posicion = move_toward(posicion, 0.0, delta / T_CARRERA)
	super(delta)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var d := -CARRERA * (1.0 - posicion)
	var l := lienzo
	# Carcasa en corte.
	l.draw_style_box(Tema.caja(Color("cfd4d6"), 10, 0, 0, Color("5b6267")), Rect2(40, 18, 250, 356))
	l.draw_style_box(Tema.caja(Color("f1f2f0"), 6, 0, 0), Rect2(52, 30, 226, 332))
	texto(Vector2(165, 10), "CORTE DEL CONTACTOR", 11, Color("5b6267"))
	# Vástago del portacontactos, detrás de todo.
	l.draw_rect(Rect2(152, 104 + d, 12, 106), Color("7f8a92"))
	# Contactos fijos de cada polo: la línea baja por la izquierda y la carga sale por la
	# derecha; el puente móvil une las dos pastillas al bajar.
	var marcas_arriba := ["1/L1", "3/L2", "5/L3"]
	var marcas_abajo := ["2/T1", "4/T2", "6/T3"]
	for i in 3:
		var x: float = POLOS[i]
		l.draw_polyline(PackedVector2Array([Vector2(x - 18, 58), Vector2(x - 18, 126), Vector2(x - 9, 126)]), COBRE, 5.0)
		l.draw_polyline(PackedVector2Array([Vector2(x + 9, 126), Vector2(x + 18, 126), Vector2(x + 18, 166)]), COBRE, 5.0)
		l.draw_rect(Rect2(x - 13, 118, 8, 6), PLATA)
		l.draw_rect(Rect2(x + 5, 118, 8, 6), PLATA)
		texto(Vector2(x - 18, 48), marcas_arriba[i], 12, Tema.TINTA)
		texto(Vector2(x + 20, 178), marcas_abajo[i], 12, Tema.TINTA)
	# Portacontactos aislante con los tres puentes.
	l.draw_style_box(Tema.caja(GRIS, 4, 0, 0), Rect2(66, 94 + d, 184, 14))
	for x: float in POLOS:
		l.draw_rect(Rect2(x - 14, 108 + d, 28, 6), COBRE)
		l.draw_rect(Rect2(x - 13, 112 + d, 8, 4), PLATA)
		l.draw_rect(Rect2(x + 5, 112 + d, 8, 4), PLATA)
	# La corriente del motor solo circula con los puentes cerrados.
	if cerrado():
		var avance := fmod(t * 30.0, 12.0)
		for x: float in POLOS:
			_trazo_corriente(PackedVector2Array([Vector2(x - 24, 62), Vector2(x - 24, 120), Vector2(x, 112), Vector2(x + 24, 120), Vector2(x + 24, 164)]), avance)
	# Armadura móvil con el brazo que comprime el muelle.
	l.draw_style_box(Tema.caja(HIERRO, 3, 0, 0, BORDE), Rect2(96, 210 + d, 124, 26))
	l.draw_rect(Rect2(220, 216 + d, 20, 8), HIERRO)
	# Muelle de retorno entre el brazo y una repisa fija.
	l.draw_rect(Rect2(220, 260, 30, 5), Color("8a949b"))
	var arriba := 224.0 + d
	var abajo := 260.0
	var muelle := PackedVector2Array()
	for k in 9:
		var y := lerpf(arriba, abajo, k / 8.0)
		muelle.append(Vector2(232.0 + (6.0 if k % 2 == 1 else -2.0), y))
	l.draw_polyline(muelle, BORDE, 2.5, true)
	# Núcleo fijo en E.
	var nucleo := PackedVector2Array([Vector2(96, 238), Vector2(220, 238), Vector2(220, 312), Vector2(196, 312), Vector2(196, 258),
		Vector2(170, 258), Vector2(170, 312), Vector2(146, 312), Vector2(146, 258), Vector2(120, 258), Vector2(120, 312), Vector2(96, 312)])
	l.draw_colored_polygon(nucleo, HIERRO)
	nucleo.append(nucleo[0])
	l.draw_polyline(nucleo, BORDE, 2.0)
	# Bobina: más viva con corriente.
	var color_bobina := Color("b9844f").lerp(Color("e58a2e"), campo)
	for x in [118.0, 172.0]:
		l.draw_style_box(Tema.caja(color_bobina, 3, 0, 0, Color("9a5512")), Rect2(x, 264, 28, 42))
	# Líneas de campo.
	if campo > 0.02:
		var color_campo := Color(CAMPO, 0.85 * campo)
		_curva(Vector2(108, 306), Vector2(102, 250), Vector2(112, 232 + d * 0.3), color_campo)
		_curva(Vector2(208, 306), Vector2(214, 250), Vector2(204, 232 + d * 0.3), color_campo)
		l.draw_line(Vector2(158, 310), Vector2(158, 238), color_campo, 2.0)
	# Bornes de la bobina.
	var color_mando := Color("c0392b") if tension else Color("8a949b")
	l.draw_polyline(PackedVector2Array([Vector2(78, 332), Vector2(118, 332), Vector2(118, 306)]), color_mando, 2.5)
	l.draw_polyline(PackedVector2Array([Vector2(238, 332), Vector2(200, 332), Vector2(200, 306)]), color_mando, 2.5)
	texto(Vector2(66, 332), "A1", 12, Tema.TINTA)
	texto(Vector2(252, 332), "A2", 12, Tema.TINTA)
	# Auxiliares.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 6, 0, 0, Color("5b6267")), Rect2(296, 40, 104, 150))
	texto(Vector2(348, 54), "AUXILIARES", 11, Color("5b6267"))
	texto(Vector2(306, 80), "13-14 NA", 12, Tema.TINTA, false)
	_contacto(Vector2(312, 102), posicion)
	texto(Vector2(306, 120), "cerrado" if cerrado() else "abierto", 11, Tema.ACIERTO if cerrado() else Tema.FALLO, false)
	texto(Vector2(306, 142), "21-22 NC", 12, Tema.TINTA, false)
	_contacto(Vector2(312, 164), 1.0 - posicion)
	var nc_cerrado := posicion < 0.01
	texto(Vector2(306, 182), "cerrado" if nc_cerrado else "abierto", 11, Tema.ACIERTO if nc_cerrado else Tema.FALLO, false)
	# Llamadas.
	var llamadas := [["Puente móvil", 214.0, Vector2(250, 112 + d)], ["Muelle", 238.0, Vector2(240, 242)], ["Armadura", 262.0, Vector2(222, 224 + d)],
		["Núcleo fijo", 286.0, Vector2(222, 276)], ["Bobina", 310.0, Vector2(200, 290)]]
	for c: Array in llamadas:
		l.draw_line(Vector2(298, c[1] - 4.0), c[2], Tema.TINTA, 1.0, true)
		texto(Vector2(300, c[1] - 4.0), c[0], 12, Tema.TINTA, false)
	# Rótulo de estado.
	var rotulo := "%d V en la bobina" % _v_bobina() if tension else "Sin tensión en la bobina"
	var fuente := get_theme_default_font()
	var ancho := fuente.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20.0
	l.draw_style_box(Tema.caja(Tema.ACIERTO if tension else Color("5b6267"), 4, 0, 0), Rect2(62, 342, ancho, 22))
	texto(Vector2(62 + ancho / 2.0, 353), rotulo, 12, Color.WHITE)
	l.draw_set_transform(Vector2.ZERO)


## Contacto auxiliar: dos tramos fijos y una pala que cierra con avance 1.
func _contacto(origen: Vector2, avance: float) -> void:
	var l := lienzo
	l.draw_line(origen, origen + Vector2(24, 0), Tema.TINTA, 3.0)
	l.draw_line(origen + Vector2(48, 0), origen + Vector2(72, 0), Tema.TINTA, 3.0)
	var angulo := lerpf(-0.42, 0.0, clampf(avance, 0.0, 1.0))
	l.draw_line(origen + Vector2(24, 0), origen + Vector2(24, 0) + Vector2(cos(angulo), sin(angulo)) * 25.0, Tema.TINTA, 3.0, true)


func _curva(a: Vector2, control: Vector2, b: Vector2, color: Color) -> void:
	var puntos := PackedVector2Array()
	for k in 13:
		var u := k / 12.0
		puntos.append(a.lerp(control, u).lerp(control.lerp(b, u), u))
	lienzo.draw_polyline(puntos, color, 2.0, true)


## Trazo discontinuo que avanza por el camino de la corriente.
func _trazo_corriente(camino: PackedVector2Array, avance: float) -> void:
	for k in range(camino.size() - 1):
		var a := camino[k]
		var b := camino[k + 1]
		var largo := a.distance_to(b)
		var s := avance - 12.0
		while s < largo:
			var s0 := maxf(s, 0.0)
			var s1 := minf(s + 7.0, largo)
			if s1 > s0:
				lienzo.draw_line(a.lerp(b, s0 / largo), a.lerp(b, s1 / largo), CORRIENTE, 3.0)
			s += 12.0
