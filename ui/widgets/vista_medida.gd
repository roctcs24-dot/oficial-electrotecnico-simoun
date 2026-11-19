class_name VistaMedida
extends Control
## El instrumento virtual sobre el componente: el dibujo del equipo a la izquierda con los bornes
## donde van las puntas resaltados, el multímetro, el megóhmetro o la pinza a la derecha con su
## lectura, y los cables de las puntas de un lado a otro.

const ROJO := Color("c0392b")
const NEGRO := Color("20242a")
const CUERPOS := {
	"multimetro": [Color("e8c43a"), Color("7a6416"), "MULTÍMETRO"],
	"megohmetro": [Color("d9622b"), Color("7a3212"), "MEGÓHMETRO"],
	"pinza": [Color("e8c43a"), Color("7a6416"), "PINZA"],
	"monitor": [Color("e9ebe8"), Color("3b444b"), "MONITOR"],
	"manometro": [Color("4a8ad0"), Color("123766"), "MANÓMETRO"],
	"caudalimetro": [Color("e8a03a"), Color("7a4206"), "CAUDALÍMETRO"],
	"comparador": [Color("d9dde0"), Color("59626a"), "COMPARADOR"],
	"higrometro": [Color("3aa0a0"), Color("14504f"), "HIGRÓMETRO"],
	"cronometro": [Color("e9ebe8"), Color("3b444b"), "CRONÓMETRO"],
}
## Instrumentos de fluidos (y el reloj comparador): se unen a la pieza con un latiguillo de prueba o
## un soporte, no con puntas.
const DE_FLUIDOS := ["manometro", "caudalimetro", "comparador", "higrometro", "cronometro"]
const LATIGUILLO := Color("1d2124")

var dibujo: VistaBornes
var instrumento := "multimetro"
var lectura := ""
var escala := ""
var roja := ""
var negra := ""
var _cables: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	dibujo = VistaBornes.new()
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dibujo)
	_cables = Control.new()
	_cables.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cables.draw.connect(_dibujar_cables)
	add_child(_cables)


func configurar(definicion_dibujo: Dictionary, bornes: Dictionary, p_instrumento: String, p_roja: String, p_negra: String, p_lectura: String, p_escala: String) -> void:
	dibujo.cargar(definicion_dibujo)
	dibujo.poner_bornes(bornes)
	instrumento = p_instrumento
	roja = p_roja
	negra = p_negra
	lectura = p_lectura
	escala = p_escala
	var puntas := {}
	if dibujo.bornes.has(roja):
		puntas[roja] = ROJO
	if dibujo.bornes.has(negra):
		puntas[negra] = Color("3b444b")
	dibujo.resaltados = puntas
	_colocar()
	queue_redraw()
	_cables.queue_redraw()


func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED:
		_colocar()


func _colocar() -> void:
	if dibujo == null:
		return
	dibujo.position = Vector2(4.0, 4.0)
	# El monitor es el propio instrumento: su dibujo ocupa todo y solo se añade la lectura.
	var ancho := size.x - 170.0 if instrumento == "monitor" else size.x * 0.5
	dibujo.size = Vector2(ancho, size.y - 8.0)
	_cables.size = size


func _rect_instrumento() -> Rect2:
	# Conserva las proporciones del cuerpo aunque el hueco sea bajo y ancho.
	var ancho := minf(size.x * 0.36, 170.0)
	var alto := minf(size.y * 0.86, ancho * 1.55)
	ancho = minf(ancho, alto / 1.35)
	return Rect2(Vector2(size.x - ancho - 10.0, (size.y - alto) / 2.0), Vector2(ancho, alto))


func _draw() -> void:
	if instrumento == "monitor":
		_dibujar_lectura()
		return
	var r := _rect_instrumento()
	var cuerpo: Array = CUERPOS.get(instrumento, CUERPOS["multimetro"])
	var fuente := get_theme_default_font()
	var caja := Tema.caja(cuerpo[0], 14, 0, 0, cuerpo[1])
	caja.set_border_width_all(2)
	draw_style_box(caja, r)
	# Pantalla con la lectura.
	var pantalla := Rect2(r.position + Vector2(r.size.x * 0.1, r.size.y * 0.08), Vector2(r.size.x * 0.8, r.size.y * 0.27))
	draw_style_box(Tema.caja(Color("1c2a22"), 4, 0, 0), pantalla)
	var tam := int(pantalla.size.y * 0.42)
	var ancho_texto := fuente.get_string_size(lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	while ancho_texto > pantalla.size.x * 0.92 and tam > 10:
		tam -= 1
		ancho_texto = fuente.get_string_size(lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(fuente, pantalla.get_center() + Vector2(-ancho_texto / 2.0, tam * 0.36), lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color("9df0b8"))
	var nombre: String = cuerpo[2]
	var tam_nombre := int(clampf(r.size.x * 0.085, 9.0, 14.0))
	var ancho_nombre := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_nombre).x
	draw_string(fuente, Vector2(r.get_center().x - ancho_nombre / 2.0, pantalla.end.y + tam_nombre * 1.5), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_nombre, Tema.TINTA)
	if instrumento in DE_FLUIDOS:
		# Sin selector: la escala va escrita bajo el nombre y la conexión, abajo.
		var tam_escala := int(clampf(r.size.x * 0.075, 9.0, 13.0))
		var ancho_escala := fuente.get_string_size(escala, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_escala).x
		draw_string(fuente, Vector2(r.get_center().x - ancho_escala / 2.0, pantalla.end.y + tam_nombre * 1.5 + tam_escala * 1.4), escala, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_escala, Tema.TINTA)
	elif instrumento == "pinza":
		# Mordaza abierta arriba del cuerpo.
		var c := Vector2(r.get_center().x, r.position.y - 2.0)
		draw_arc(c, r.size.x * 0.28, PI, TAU, 24, Color("2b2f32"), 8.0, true)
	else:
		# Selector con la escala elegida.
		var centro := Vector2(r.get_center().x + r.size.x * 0.08, r.position.y + r.size.y * 0.68)
		var radio := r.size.x * 0.24
		draw_circle(centro, radio, Color("2b2f32"))
		draw_line(centro, centro + Vector2(-0.7, -0.7) * radio * 0.8, cuerpo[0], 4.0, true)
		# La escala elegida, junto a la punta del selector.
		var tam_escala := int(clampf(radio * 0.42, 9.0, 13.0))
		var ancho_escala := fuente.get_string_size(escala, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_escala).x
		var x_escala := maxf(centro.x - radio * 0.8 - ancho_escala, r.position.x + 4.0)
		draw_string(fuente, Vector2(x_escala, centro.y - radio * 0.75), escala, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_escala, Tema.TINTA)
	for i in 2:
		var hembra := _hembra(i)
		if instrumento in DE_FLUIDOS:
			if (i == 0 and not roja.is_empty()) or (i == 1 and not negra.is_empty()):
				draw_circle(hembra, 7.0, Color("b9c3cb"))
				draw_circle(hembra, 4.0, LATIGUILLO)
			continue
		draw_circle(hembra, 6.0, ROJO if i == 0 else NEGRO)


## Lectura del monitor en una pantalla pequeña, abajo a la derecha.
func _dibujar_lectura() -> void:
	var fuente := get_theme_default_font()
	var caja := Rect2(Vector2(size.x - 152.0, size.y / 2.0 - 26.0), Vector2(140.0, 52.0))
	draw_style_box(Tema.caja(Color("1c2a22"), 6, 0, 0, Color("3b444b")), caja)
	var tam := 22
	var ancho := fuente.get_string_size(lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(fuente, caja.get_center() + Vector2(-ancho / 2.0, tam * 0.36), lectura, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color("9df0b8"))


## Bornes del instrumento: 0 la roja, 1 la negra (la común).
func _hembra(i: int) -> Vector2:
	var r := _rect_instrumento()
	return Vector2(r.position.x + r.size.x * (0.7 if i == 0 else 0.3), r.end.y - 14.0)


## Dónde llega cada punta en el dibujo; sin el borne dibujado, al borde del equipo.
func _punto(borne: String, i: int) -> Vector2:
	if dibujo.bornes.has(borne):
		var p: Vector2 = dibujo.bornes[borne]
		return dibujo.position + dibujo.a_local(p.x, p.y)
	var marco := dibujo.rect_imagen()
	return dibujo.position + Vector2(marco.end.x, marco.position.y + marco.size.y * (0.4 + 0.2 * i))


func _dibujar_cables() -> void:
	if instrumento == "monitor":
		return
	if instrumento == "pinza":
		if roja.is_empty():
			return
		var p := _punto(roja, 0)
		var r := _rect_instrumento()
		var c := Vector2(r.get_center().x, r.position.y - 2.0)
		_cables.draw_arc(p, 16.0, 0.0, TAU, 24, Color("2b2f32"), 4.0, true)
		_curva(p + Vector2(16.0, 0.0), c - Vector2(r.size.x * 0.28, 0.0), Color("2b2f32"))
		return
	for i in 2:
		var borne := roja if i == 0 else negra
		if borne.is_empty():
			continue
		if instrumento in DE_FLUIDOS:
			_curva(_punto(borne, i), _hembra(i), LATIGUILLO, 6.0)
			continue
		_curva(_punto(borne, i), _hembra(i), ROJO if i == 0 else NEGRO)


func _curva(desde: Vector2, hasta: Vector2, color: Color, grosor := 4.0) -> void:
	var puntos := PackedVector2Array()
	var control := Vector2((desde.x + hasta.x) / 2.0, maxf(desde.y, hasta.y) + 40.0)
	for k in 21:
		var t := k / 20.0
		puntos.append(desde.lerp(control, t).lerp(control.lerp(hasta, t), t))
	_cables.draw_polyline(puntos, color, grosor, true)
	_cables.draw_circle(desde, 5.0, color)
