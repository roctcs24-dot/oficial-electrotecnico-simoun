class_name PlanoInteractivo
extends VistaSvg
## Plano del barco con una zona tocable por sistema, marcada con su número, y una marca amarilla
## en el lugar de cada tablero del buque que se puede manejar.

signal sistema_tocado(id: int)
signal tablero_tocado(id: String)

const LADO_MIN := 19.0
const LADO_MAX := 27.0

var sistemas: Array = []
## {id, x, y} en coordenadas del dibujo del plano.
var tableros: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
		var tablero := tablero_en(evento.position)
		if not tablero.is_empty():
			tablero_tocado.emit(tablero)
			accept_event()
			return
		var id := zona_en(evento.position)
		if id >= 0:
			sistema_tocado.emit(id)
			accept_event()


func _lado() -> float:
	return clampf(rect_imagen().size.x * 0.045, LADO_MIN, LADO_MAX)


## Tablero cuya marca está bajo el punto, o "". Las marcas tienen prioridad sobre las zonas.
func tablero_en(punto: Vector2) -> String:
	for t: Dictionary in tableros:
		if a_local(t["x"], t["y"]).distance_to(punto) <= _lado() * 0.75:
			return t["id"]
	return ""


## Sistema activo cuya zona contiene el punto, o -1.
func zona_en(punto: Vector2) -> int:
	for s: Dictionary in sistemas:
		if s["estado"] == "activo" and _rect_zona(s).has_point(punto):
			return int(s["id"])
	return -1


func _rect_zona(s: Dictionary) -> Rect2:
	var z: Array = s["zona"]
	var origen := a_local(z[0], z[1])
	return Rect2(origen, a_local(z[0] + z[2], z[1] + z[3]) - origen)


func _draw() -> void:
	super()
	var fuente := get_theme_default_font()
	var lado := clampf(rect_imagen().size.x * 0.045, LADO_MIN, LADO_MAX)
	var tam_numero := int(lado * 0.72)
	for s: Dictionary in sistemas:
		var activo: bool = s["estado"] == "activo"
		var r := _rect_zona(s)
		if activo:
			draw_rect(r, Color(Tema.ACENTO, 0.12))
			draw_rect(r, Tema.ACENTO, false, 1.5)
		else:
			draw_rect(r, Tema.APAGADO, false, 1.0)
		var insignia := Rect2(r.get_center() - Vector2(lado, lado) / 2.0, Vector2(lado, lado))
		draw_rect(insignia, Tema.ACENTO if activo else Tema.PANEL)
		draw_rect(insignia, Tema.ACENTO if activo else Tema.APAGADO, false, 1.0)
		var numero := str(int(s["id"]))
		var ancho := fuente.get_string_size(numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_numero).x
		var base := insignia.get_center() + Vector2(-ancho / 2.0, tam_numero * 0.35)
		draw_string(fuente, base, numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_numero, Tema.FONDO if activo else Tema.TEXTO_SUAVE)
	for t: Dictionary in tableros:
		var c := a_local(t["x"], t["y"])
		var m := lado * 0.42
		draw_rect(Rect2(c - Vector2(m, m), Vector2(m, m) * 2.0), Color("e8bf27"))
		draw_rect(Rect2(c - Vector2(m, m), Vector2(m, m) * 2.0), Tema.FONDO, false, 1.5)
		# Rayo: el símbolo de riesgo eléctrico de los tableros.
		var rayo := PackedVector2Array([c + Vector2(0.15, -0.8) * m, c + Vector2(-0.45, 0.1) * m, c + Vector2(-0.02, 0.1) * m,
			c + Vector2(-0.18, 0.8) * m, c + Vector2(0.45, -0.15) * m, c + Vector2(0.02, -0.15) * m])
		draw_colored_polygon(rayo, Tema.FONDO)
