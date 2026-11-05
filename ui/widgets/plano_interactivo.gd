class_name PlanoInteractivo
extends VistaSvg
## Plano del barco con una zona tocable por sistema.

signal sistema_tocado(id: int)

const RADIO_MIN := 10.0
const RADIO_MAX := 16.0

var sistemas: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
		var id := zona_en(evento.position)
		if id >= 0:
			sistema_tocado.emit(id)
			accept_event()


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
	var radio := clampf(rect_imagen().size.x * 0.03, RADIO_MIN, RADIO_MAX)
	var tam_numero := int(radio * 1.2)
	for s: Dictionary in sistemas:
		var activo: bool = s["estado"] == "activo"
		var r := _rect_zona(s)
		var color: Color = Tema.ACENTO if activo else Tema.APAGADO
		draw_rect(r, Color(color, 0.22 if activo else 0.12))
		draw_rect(r, color, false, 2.0 if activo else 1.0)
		var centro := r.get_center()
		draw_circle(centro, radio, color if activo else Tema.PANEL)
		var numero := str(int(s["id"]))
		var ancho := fuente.get_string_size(numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_numero).x
		draw_string(fuente, centro + Vector2(-ancho / 2.0, tam_numero * 0.35), numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_numero, Tema.FONDO if activo else Tema.TEXTO_SUAVE)
