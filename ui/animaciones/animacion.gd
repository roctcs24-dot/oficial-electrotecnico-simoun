class_name Animacion
extends VBoxContainer
## Base de las animaciones de las lecciones: un lienzo que se redibuja y controles debajo.
## Cada animación es ui/animaciones/<id>.gd y recibe sus parámetros desde el JSON.

const ALTO_LIENZO := 230.0

var lienzo: Control
var params := {}
var contenido: Contenido
## Segundos desde que empezó, para mover lo que se anima.
var t := 0.0


func iniciar(datos: Dictionary, contenido_juego: Contenido) -> void:
	params = datos
	contenido = contenido_juego
	lienzo = Control.new()
	lienzo.custom_minimum_size.y = ALTO_LIENZO
	lienzo.mouse_filter = Control.MOUSE_FILTER_PASS
	lienzo.draw.connect(dibujar)
	add_child(lienzo)
	preparar()


func preparar() -> void:
	pass


func dibujar() -> void:
	pass


func _process(delta: float) -> void:
	t += delta
	if lienzo != null:
		lienzo.queue_redraw()


func fondo() -> void:
	lienzo.draw_style_box(Tema.caja(Tema.PAPEL, 10, 0, 0), Rect2(Vector2.ZERO, lienzo.size))


func texto(posicion: Vector2, cadena: String, tam := 16, color := Tema.TINTA, centrado := true) -> void:
	var fuente := get_theme_default_font()
	var x := posicion.x
	if centrado:
		x -= fuente.get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x / 2.0
	lienzo.draw_string(fuente, Vector2(x, posicion.y + tam * 0.35), cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


func flecha(desde: Vector2, hasta: Vector2, color: Color, grosor := 3.0) -> void:
	lienzo.draw_line(desde, hasta, color, grosor, true)
	var d := hasta - desde
	if d.length() < 8.0:
		return
	var u := d.normalized()
	var punta := PackedVector2Array([hasta, hasta - u * 12.0 + u.orthogonal() * 5.0, hasta - u * 12.0 - u.orthogonal() * 5.0])
	lienzo.draw_colored_polygon(punta, color)


## Fila con nombre y deslizador. El alto de 48 lo hace cómodo de arrastrar con el dedo.
func deslizador(minimo: float, maximo: float, paso: float, valor: float, al_cambiar: Callable) -> Label:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	add_child(fila)
	var etiqueta := Label.new()
	etiqueta.custom_minimum_size.x = 110.0
	fila.add_child(etiqueta)
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = paso
	control.value = valor
	control.custom_minimum_size.y = 48.0
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	control.value_changed.connect(al_cambiar)
	fila.add_child(control)
	return etiqueta
