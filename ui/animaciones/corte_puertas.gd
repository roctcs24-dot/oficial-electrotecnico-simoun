extends Animacion
## Puertas lógicas con la lógica de SimPuertaLogica: dos entradas que se tocan para ponerlas a 0
## o a 1, el tipo de puerta, su símbolo IEC y ANSI y la tabla de verdad con la fila actual. Una
## entrada A al aire queda indefinida y la salida a media tensión.

const ANCHO := 400.0
const ALTO := 260.0
const TIPOS := [["and", "AND", "&"], ["or", "OR", "≥1"], ["nand", "NAND", "&"], ["nor", "NOR", "≥1"], ["xor", "XOR", "=1"], ["not", "NOT", "1"]]

var a := 0
var b := 0
var indice := 0
var aire := false
var _modelo: SimPuertaLogica
var _boton_a: Button
var _boton_b: Button
var _aire: Button
var _tipos: Array[Button] = []
var _nota: Label


func preparar() -> void:
	_modelo = SimPuertaLogica.new("U1")
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_boton_a = boton_mando(fila, func() -> void: poner(1 - a, b))
	_boton_b = boton_mando(fila, func() -> void: poner(a, 1 - b))
	_aire = boton_mando(fila, func() -> void: al_aire(not aire))
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 6)
	c.add_child(rejilla)
	for i in TIPOS.size():
		var t_b := boton_mando(rejilla, elegir_tipo.bind(TIPOS[i][0]))
		t_b.text = TIPOS[i][1]
		_tipos.append(t_b)
	_nota = nota_mandos(c)
	_actualizar()


func poner(nuevo_a: int, nuevo_b: int) -> void:
	a = clampi(nuevo_a, 0, 1)
	b = clampi(nuevo_b, 0, 1)
	_actualizar()


func elegir_tipo(tipo_puerta: String) -> void:
	for i in TIPOS.size():
		if TIPOS[i][0] == tipo_puerta:
			indice = i
	_modelo.params["tipo"] = tipo_puerta
	_actualizar()


func al_aire(si: bool) -> void:
	aire = si
	_actualizar()


func tipo_actual() -> String:
	return TIPOS[indice][0]


## 1, 0 o −1 si está indefinida.
func salida() -> int:
	return _modelo.logica(-1 if aire else a, b)


## 1 salida a 0; 2 salida a 1; 3 indefinida.
func fase() -> int:
	match salida():
		1:
			return 2
		-1:
			return 3
	return 1


func _actualizar() -> void:
	if _nota == null:
		return
	_boton_a.text = "A = %s" % ("?" if aire else str(a))
	_boton_b.text = "B = %d" % b
	_boton_b.disabled = tipo_actual() == "not"
	_aire.text = "A con su resistencia" if aire else "A al aire"
	for k in _tipos.size():
		_tipos[k].modulate = Color(1, 1, 1, 1.0 if k == indice else 0.6)
	if salida() < 0:
		_nota.text = "La entrada A está al aire: la puerta no sabe si es 0 o 1 y la salida queda a media tensión, o parpadea. Toda entrada necesita su resistencia."
	else:
		var textos := {"and": "AND da 1 solo si A y B son 1, como dos contactos en serie.", "or": "OR da 1 si A o B son 1, como dos contactos en paralelo.",
			"nand": "NAND es una AND invertida: da 0 solo si A y B son 1.", "nor": "NOR es una OR invertida: da 1 solo si A y B son 0.",
			"xor": "XOR da 1 si A y B son distintas.", "not": "NOT invierte la entrada A, como un contacto NC."}
		_nota.text = textos[tipo_actual()]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "PUERTA %s" % TIPOS[indice][1], 12, Color("5b6267"))
	var tinta := Tema.TINTA
	var y_out := salida()
	var color_y := Tema.ACENTO_FUERTE if y_out == 1 else (Color("e8a33a") if y_out < 0 else Color("8a949b"))
	var es_not := tipo_actual() == "not"
	# Símbolo IEC.
	texto(Vector2(80, 34), "IEC 60617", 10, Color("5b6267"))
	l.draw_rect(Rect2(50, 46, 60, 70), Color.WHITE)
	l.draw_rect(Rect2(50, 46, 60, 70), tinta, false, 2.5)
	texto(Vector2(80, 80), TIPOS[indice][2], 18, tinta)
	var invertida := tipo_actual() in ["nand", "nor", "not"]
	# Símbolo ANSI.
	texto(Vector2(230, 34), "ANSI/IEEE 315", 10, Color("5b6267"))
	var o := Vector2(200, 46)
	match tipo_actual():
		"and", "nand":
			l.draw_polyline(PackedVector2Array([o + Vector2(30, 0), o, o + Vector2(0, 70), o + Vector2(30, 70)]), tinta, 2.5)
			l.draw_arc(o + Vector2(30, 35), 35.0, -PI / 2.0, PI / 2.0, 20, tinta, 2.5)
		"or", "nor", "xor":
			var arriba := PackedVector2Array()
			for k in 13:
				var f := k / 12.0
				arriba.append(o + Vector2(f * 65.0, 35.0 - 35.0 * cos(f * PI / 2.0)))
			for k in 13:
				var f := 1.0 - k / 12.0
				arriba.append(o + Vector2(f * 65.0, 35.0 + 35.0 * cos(f * PI / 2.0)))
			l.draw_polyline(arriba, tinta, 2.5)
			l.draw_arc(o + Vector2(-30, 35), 40.0, -0.9, 0.9, 12, tinta, 2.5)
			if tipo_actual() == "xor":
				l.draw_arc(o + Vector2(-40, 35), 40.0, -0.9, 0.9, 12, tinta, 2.5)
		"not":
			l.draw_polyline(PackedVector2Array([o, o + Vector2(0, 70), o + Vector2(55, 35), o]), tinta, 2.5)
	var x_salida := 265.0 if not es_not else 255.0
	if invertida:
		l.draw_arc(Vector2(x_salida + 6, 81), 6.0, 0, TAU, 12, tinta, 2.5)
		l.draw_arc(Vector2(116, 81), 6.0, 0, TAU, 12, tinta, 2.5)
	# Entradas y salida con su nivel.
	var color_a := Color("e8a33a") if aire else (Tema.ACENTO_FUERTE if a == 1 else Color("8a949b"))
	var color_b := Tema.ACENTO_FUERTE if b == 1 else Color("8a949b")
	for par: Array in [[50.0, 200.0]]:
		l.draw_line(Vector2(par[0] - 30, 60 if not es_not else 81), Vector2(par[0], 60 if not es_not else 81), color_a, 3.0)
		l.draw_line(Vector2(par[1] - 30, 60 if not es_not else 81), Vector2(par[1], 60 if not es_not else 81), color_a, 3.0)
		if not es_not:
			l.draw_line(Vector2(par[0] - 30, 102), Vector2(par[0], 102), color_b, 3.0)
			l.draw_line(Vector2(par[1] - 30, 102), Vector2(par[1], 102), color_b, 3.0)
	l.draw_line(Vector2(122, 81), Vector2(150, 81), color_y, 3.0)
	l.draw_line(Vector2(x_salida + 12, 81), Vector2(300, 81), color_y, 3.0)
	l.draw_circle(Vector2(320, 81), 12.0, Color("ff5a45") if y_out == 1 else (Color("f2b56a") if y_out < 0 else Color("8e1c15")))
	texto(Vector2(320, 104), "Y = %s" % ("?" if y_out < 0 else str(y_out)), 11, tinta)
	# Tabla de verdad.
	var filas := [[0, 0], [1, 0]] if es_not else [[0, 0], [0, 1], [1, 0], [1, 1]]
	var x0 := 120.0
	texto(Vector2(x0, 140), "A", 11, tinta)
	if not es_not:
		texto(Vector2(x0 + 50, 140), "B", 11, tinta)
	texto(Vector2(x0 + 100, 140), "Y", 11, tinta)
	for k in filas.size():
		var y := 160.0 + k * 20.0
		var actual: bool = not aire and filas[k][0] == a and (es_not or filas[k][1] == b)
		if actual:
			l.draw_rect(Rect2(x0 - 20, y - 10, 140, 20), Color(Tema.ACENTO, 0.6))
		texto(Vector2(x0, y), str(filas[k][0]), 11, tinta)
		if not es_not:
			texto(Vector2(x0 + 50, y), str(filas[k][1]), 11, tinta)
		texto(Vector2(x0 + 100, y), str(_modelo.logica(filas[k][0], filas[k][1])), 11, tinta)
	var rotulo := "INDEFINIDA" if y_out < 0 else ("SALIDA 1" if y_out == 1 else "SALIDA 0")
	rotulo_estado(Vector2(320, 236), rotulo, Tema.FALLO if y_out < 0 else (Tema.ACIERTO if y_out == 1 else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
