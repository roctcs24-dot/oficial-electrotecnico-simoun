extends Animacion
## Transformador monofásico de 380/220 V o 380/110 V con su carga: la tensión baja en la
## relación de espiras y la corriente sube en la misma relación; la potencia es casi la misma
## a un lado y al otro. Un deslizador cambia la carga del secundario.

const COBRE := Color("b8692e")
const NUCLEO := Color("6c7276")
const RENDIMIENTO := 0.97

var secundario := 220.0
var carga_w := 1500.0
var _boton_tension: Button
var _texto_carga: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = 250.0
	_boton_tension = Button.new()
	_boton_tension.mouse_filter = Control.MOUSE_FILTER_PASS
	_boton_tension.custom_minimum_size.y = 48.0
	_boton_tension.pressed.connect(alternar_secundario)
	add_child(_boton_tension)
	_texto_carga = deslizador(0.0, 5000.0, 100.0, carga_w, cambiar_carga)
	_actualizar()


func alternar_secundario() -> void:
	secundario = 110.0 if secundario == 220.0 else 220.0
	_actualizar()


func cambiar_carga(valor: float) -> void:
	carga_w = valor
	_actualizar()


func _actualizar() -> void:
	_boton_tension.text = "Cambiar a 380/%d V" % (110 if secundario == 220.0 else 220)
	_texto_carga.text = "Carga %s W" % TextoTecnico.numero(carga_w, 0)


func corriente_secundario() -> float:
	return carga_w / secundario


## El primario entrega algo más de lo que recibe la carga: las pérdidas del transformador.
func corriente_primario() -> float:
	return carga_w / RENDIMIENTO / 380.0


func dibujar() -> void:
	fondo()
	var w := lienzo.size.x
	var c := Vector2(w * 0.5, 112.0)
	var ancho := minf(w * 0.42, 200.0)
	# Núcleo de chapa y los dos devanados.
	lienzo.draw_rect(Rect2(c.x - ancho / 2.0, c.y - 70.0, ancho, 140.0), NUCLEO)
	lienzo.draw_rect(Rect2(c.x - ancho / 2.0 + 26.0, c.y - 44.0, ancho - 52.0, 88.0), Tema.PAPEL)
	for k in 12:
		var y := c.y - 50.0 + k * 9.0
		lienzo.draw_line(Vector2(c.x - ancho / 2.0 - 6.0, y), Vector2(c.x - ancho / 2.0 + 32.0, y), COBRE, 5.0)
	var espiras_sec := 7 if secundario == 220.0 else 4
	for k in espiras_sec:
		var y := c.y - 50.0 + k * (100.0 / espiras_sec)
		lienzo.draw_line(Vector2(c.x + ancho / 2.0 - 32.0, y), Vector2(c.x + ancho / 2.0 + 6.0, y), COBRE, 7.0)
	texto(Vector2(c.x - ancho / 2.0 + 12.0, c.y + 84.0), "primario", 12)
	texto(Vector2(c.x + ancho / 2.0 - 12.0, c.y + 84.0), "secundario", 12)
	# El flujo recorre el núcleo.
	var fase := fmod(t * 0.8, 1.0)
	for k in 4:
		lienzo.draw_circle(_punto_nucleo(c, ancho, fmod(fase + k * 0.25, 1.0)), 3.0, Color("ffd36b"))
	var xi := 12.0
	var xd := c.x + ancho / 2.0 + 18.0
	texto(Vector2(xi, 40.0), "380 V", 16, Tema.TINTA, false)
	texto(Vector2(xi, 64.0), "%s A" % TextoTecnico.numero(corriente_primario(), 1), 16, Color("2a5fb0"), false)
	texto(Vector2(xi, 88.0), "%s W" % TextoTecnico.numero(carga_w / RENDIMIENTO, 0), 13, Color("4c555b"), false)
	texto(Vector2(xd, 40.0), "%d V" % int(secundario), 16, Tema.TINTA, false)
	texto(Vector2(xd, 64.0), "%s A" % TextoTecnico.numero(corriente_secundario(), 1), 16, Color("2a5fb0"), false)
	texto(Vector2(xd, 88.0), "%s W" % TextoTecnico.numero(carga_w, 0), 13, Color("4c555b"), false)
	texto(Vector2(w * 0.5, 222.0), "Relación %s : 1 · la corriente sube en la misma relación" % TextoTecnico.numero(380.0 / secundario, 2), 12)


func _punto_nucleo(c: Vector2, ancho: float, u: float) -> Vector2:
	var r := Rect2(c.x - ancho / 2.0 + 13.0, c.y - 57.0, ancho - 26.0, 114.0)
	var d := u * 2.0 * (r.size.x + r.size.y)
	if d < r.size.x:
		return r.position + Vector2(d, 0)
	d -= r.size.x
	if d < r.size.y:
		return Vector2(r.end.x, r.position.y + d)
	d -= r.size.y
	if d < r.size.x:
		return Vector2(r.end.x - d, r.end.y)
	d -= r.size.x
	return Vector2(r.position.x, r.end.y - d)
