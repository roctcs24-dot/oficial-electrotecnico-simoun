class_name Animacion
extends VBoxContainer
## Base de las animaciones de las lecciones: un lienzo que se redibuja y controles debajo.
## Cada animación es ui/animaciones/<id>.gd y recibe sus parámetros desde el JSON.

const ALTO_LIENZO := 230.0
const CARPETA := "res://ui/animaciones/%s.gd"

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
	lienzo.draw_style_box(Tema.caja(Tema.PAPEL, Tema.RADIO, 0, 0), Rect2(Vector2.ZERO, lienzo.size))


func texto(posicion: Vector2, cadena: String, tam := 16, color := Tema.TINTA, centrado := true) -> void:
	var fuente := get_theme_default_font()
	var x := posicion.x
	if centrado:
		x -= fuente.get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x / 2.0
	lienzo.draw_string(fuente, Vector2(x, posicion.y + tam * 0.35), cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


## Dibuja en un espacio de diseño fijo, escalado y centrado en el lienzo. Devuelve la escala.
func diseno(ancho: float, alto: float) -> float:
	var escala := minf(lienzo.size.x / ancho, lienzo.size.y / alto)
	var sobra := lienzo.size - Vector2(ancho, alto) * escala
	lienzo.draw_set_transform(sobra / 2.0, 0.0, Vector2(escala, escala))
	return escala


## Tarjeta con un título, una nota y un control a la derecha, como el interruptor de tensión.
func tarjeta_control(titulo: String, nota: String, control: Control) -> Label:
	var tarjeta := PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tarjeta)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	tarjeta.add_child(fila)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	var t := Label.new()
	t.text = titulo
	t.theme_type_variation = "Fuerte"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(t)
	var n := Label.new()
	n.text = nota
	n.theme_type_variation = "Nota"
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(n)
	fila.add_child(control)
	return n


## Tarjeta para los mandos de un corte: devuelve su columna.
func tarjeta_mandos() -> VBoxContainer:
	var tarjeta := PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tarjeta)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	tarjeta.add_child(columna)
	return columna


## Fila con un título y su valor a la derecha, en el color del acento. Devuelve el valor.
func fila_valor(columna: VBoxContainer, titulo: String) -> Label:
	var fila := HBoxContainer.new()
	columna.add_child(fila)
	var t := Label.new()
	t.text = titulo
	t.theme_type_variation = "Fuerte"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(t)
	var v := Label.new()
	v.add_theme_color_override("font_color", Tema.ACENTO)
	fila.add_child(v)
	return v


func barra(columna: VBoxContainer, minimo: float, maximo: float, paso: float, valor: float, al_cambiar: Callable) -> HSlider:
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = paso
	control.value = valor
	control.custom_minimum_size.y = 48.0
	control.value_changed.connect(al_cambiar)
	columna.add_child(control)
	return control


func nota_mandos(columna: VBoxContainer) -> Label:
	var n := Label.new()
	n.theme_type_variation = "Nota"
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(n)
	return n


func boton_mando(contenedor: Container, al_pulsar: Callable) -> Button:
	var b := Button.new()
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size.y = 48.0
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(al_pulsar)
	contenedor.add_child(b)
	return b


## Texto con el ancho medido, alineado a la derecha de x.
func texto_derecha(posicion: Vector2, cadena: String, tam := 12, color := Color("3b444b")) -> void:
	var ancho := get_theme_default_font().get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	texto(Vector2(posicion.x - ancho, posicion.y), cadena, tam, color, false)


## Rótulo de estado: una píldora de color con texto blanco, centrada en x.
func rotulo_estado(centro: Vector2, cadena: String, color: Color) -> void:
	var ancho := get_theme_default_font().get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20.0
	lienzo.draw_style_box(Tema.caja(color, 5, 0, 0), Rect2(centro.x - ancho / 2.0, centro.y - 12.0, ancho, 24.0))
	texto(centro, cadena, 12, Color.WHITE)


## Número con coma decimal y sin ceros sobrantes.
static func coma(v: float, decimales := 1) -> String:
	var s := ("%." + str(decimales) + "f") % v
	if s.contains("."):
		s = s.rstrip("0").trim_suffix(".")
	return s.replace(".", ",")


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
