extends Animacion
## Válvula 5/2 cortada: cuerpo con las bocas 4 y 2 arriba y 5, 1 y 3 abajo, y la corredera con
## sus juntas. Sin tensión el muelle la deja a la derecha (1→2, 4→5); con la bobina Y1, o con el
## mando manual, el piloto la empuja (1→4, 2→3). Se ve por dónde pasa el aire y por dónde sale.
## Parámetros: "y1" inicial (bool).

const ANCHO := 440.0
const ALTO := 210.0

var y1 := false
var manual := false
var bobina_quemada := false
var _corredera := 0.0
var _flujo := 0.0
var _boton_y1: Button
var _boton_manual: Button
var _boton_quemada: Button
var _vias: Label


func preparar() -> void:
	y1 = bool(params.get("y1", false))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_boton_y1 = boton_mando(fila, func() -> void:
		y1 = not y1
		_actualizar())
	_boton_manual = boton_mando(fila, func() -> void:
		manual = not manual
		_actualizar())
	_boton_quemada = boton_mando(c, func() -> void:
		bobina_quemada = not bobina_quemada
		_actualizar())
	_vias = fila_valor(c, "Pasos abiertos")
	_actualizar()


func pilotada() -> bool:
	return (y1 and not bobina_quemada) or manual


func _actualizar() -> void:
	_boton_y1.text = "Quitar tensión a Y1" if y1 else "Dar tensión a Y1"
	_boton_y1.modulate = Color(1.0, 0.85, 0.4) if y1 else Color.WHITE
	_boton_manual.text = "Soltar el mando manual" if manual else "Mando manual"
	_boton_quemada.text = "Cambiar la bobina" if bobina_quemada else "Quemar la bobina"
	_vias.text = "1 → 4 · 2 → 3" if pilotada() else "1 → 2 · 4 → 5"


func fase() -> int:
	if y1 and bobina_quemada and not manual:
		return 3
	return 2 if pilotada() else 1


func _process(delta: float) -> void:
	_corredera = move_toward(_corredera, 1.0 if pilotada() else 0.0, delta * 4.0)
	_flujo += delta * 30.0
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoNeumatico.FONDO)
	var cuerpo := Rect2(100, 62, 270, 80)
	# Bocas: posición x de cada una.
	var bocas := {"4": 180.0, "2": 270.0, "5": 150.0, "1": 225.0, "3": 300.0}
	var on := pilotada()
	var papeles := {"1": "presion", "4": "presion" if on else "escape", "2": "escape" if on else "presion", "5": "" if on else "escape", "3": "escape" if on else ""}
	for b: String in ["4", "2"]:
		DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(bocas[b], 14), Vector2(bocas[b], cuerpo.position.y)]), papeles[b], _flujo if papeles[b] == "presion" else -_flujo, 10.0)
	for b: String in ["5", "1", "3"]:
		var desde := Vector2(bocas[b], 196) if b == "1" else Vector2(bocas[b], cuerpo.end.y)
		var hasta := Vector2(bocas[b], cuerpo.end.y) if b == "1" else Vector2(bocas[b], 176)
		DibujoNeumatico.tubo(l, PackedVector2Array([desde, hasta]), papeles[b], _flujo if papeles[b] != "" else -1.0, 10.0)
	DibujoHidraulico.pieza(l, cuerpo, 6.0)
	# Taladro de la corredera y la corredera con sus juntas.
	var taladro := Rect2(cuerpo.position.x + 12, cuerpo.get_center().y - 14, cuerpo.size.x - 24, 28)
	DibujoAri.relleno(l, taladro, 4.0, Color("20262c"))
	# El aire que pasa por dentro: entre la boca de entrada y la de salida de cada paso.
	var pasos: Array = [["1", "4"], ["2", "3"]] if on else [["1", "2"], ["4", "5"]]
	for par: Array in pasos:
		var a: float = bocas[par[0]]
		var b: float = bocas[par[1]]
		var col := DibujoNeumatico.PRESION[1] if par[0] == "1" else DibujoNeumatico.ESCAPE[1]
		DibujoAri.relleno(l, Rect2(minf(a, b) - 6, taladro.position.y + 3, absf(b - a) + 12, taladro.size.y - 6), 3.0, Color(col, 0.75))
	var dx := -26.0 * _corredera
	var vastago := Rect2(taladro.position.x + 6 + dx, taladro.get_center().y - 4, taladro.size.x - 12, 8)
	DibujoAri.relleno(l, vastago, 3.0, Color("aab4bb"))
	# Émbolos de la corredera (14 px), colocados para que en cada posición separen los pasos.
	for xa: float in [118.0, 186.0, 278.0, 334.0]:
		if xa + dx < taladro.position.x:
			continue
		var piston := Rect2(xa + dx, taladro.position.y + 2, 14, taladro.size.y - 4)
		DibujoAri.pieza(l, piston, 3.0, [Color("ffffff"), Color("cfd6db"), Color("7d868d")], [], DibujoNeumatico.CONTORNO)
		DibujoAri.relleno(l, Rect2(piston.position.x + 5, piston.position.y, 4, piston.size.y), 1.0, Color("1b1e21"))
	# Bobina con su piloto a la izquierda, muelle a la derecha.
	DibujoNeumatico.bobina(l, fuente, Rect2(34, 78, 62, 48), "Y1", y1 and not bobina_quemada)
	if y1 and bobina_quemada:
		DibujoHidraulico.rotulo(l, fuente, Vector2(65, 160), "BOBINA QUEMADA", 9, Color("ff7a5a"))
	l.draw_circle(Vector2(90, 136), 6.0, Color("f2b81f") if manual else Color("9a6a00"))
	var muelle := PackedVector2Array()
	var largo := 36.0 - 22.0 * _corredera
	for i in 9:
		muelle.append(Vector2(cuerpo.end.x + 4 + i * largo / 8.0, cuerpo.get_center().y + (7.0 if i % 2 else -7.0)))
	DibujoHidraulico.pieza(l, Rect2(cuerpo.end.x, cuerpo.position.y + 18, 44, 44), 6.0)
	l.draw_polyline(muelle, Color("e8c43a"), 2.0, true)
	for b: String in bocas:
		var y := 8.0 if b in ["4", "2"] else 190.0
		DibujoHidraulico.rotulo(l, fuente, Vector2(bocas[b] + 14, y + (0 if b in ["4", "2"] else 0)), b, 10, Color("ffc23a"))
	texto(Vector2(390, 30), "a los cilindros", 9, Color("cfd8df"))
	texto(Vector2(395, 186), "1 entra · 3 y 5 escapan", 9, Color("cfd8df"))
