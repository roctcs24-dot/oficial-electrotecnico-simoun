class_name VistaEquipo
extends VistaSvg
## Dibujo de un equipo con su indicador mecánico: verde con O en reposo, rojo con I si cierra.

const VERDE := Color("2f9e57")
const ROJO := Color("c9352b")

var indicador := {}
var _avance := 0.0
var _tween: Tween


func cargar(definicion: Dictionary) -> void:
	super(definicion)
	indicador = definicion.get("indicador", {})


func poner_cerrado(cerrado: bool) -> void:
	var objetivo := 1.0 if cerrado else 0.0
	if is_equal_approx(objetivo, _avance):
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_fijar_avance, _avance, objetivo, 0.08)


func _fijar_avance(valor: float) -> void:
	_avance = valor
	queue_redraw()


func _draw() -> void:
	super()
	if indicador.is_empty():
		return
	var origen := a_local(indicador["x"], indicador["y"])
	var fin := a_local(indicador["x"] + indicador["ancho"], indicador["y"] + indicador["alto"])
	var tam := fin - origen
	var alto_rojo := tam.y * _avance
	draw_rect(Rect2(origen, Vector2(tam.x, tam.y - alto_rojo)), VERDE)
	draw_rect(Rect2(origen + Vector2(0.0, tam.y - alto_rojo), Vector2(tam.x, alto_rojo)), ROJO)
	var fuente := get_theme_default_font()
	var letra := "I" if _avance > 0.5 else "O"
	var tam_letra := maxi(int(tam.y * 0.7), 8)
	var ancho := fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_letra).x
	draw_string(fuente, origen + Vector2((tam.x - ancho) / 2.0, tam.y * 0.5 + tam_letra * 0.35), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_letra, Color.WHITE)
