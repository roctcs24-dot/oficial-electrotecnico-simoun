class_name BotonPlay
extends Button
## Botón redondo de «Continuar»: moneda ámbar con aro cromado, el triángulo de empezar y un
## halo de luz. Es un Button, así cuenta como botón para el tamaño táctil y el teclado.

const LADO := 64.0


func _init(al_pulsar := Callable(), descripcion := "Continuar") -> void:
	custom_minimum_size = Vector2(LADO, LADO)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	tooltip_text = descripcion
	var vacia := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estado, vacia)
	for s in [button_down, button_up]:
		s.connect(queue_redraw)
	if al_pulsar.is_valid():
		pressed.connect(al_pulsar)


func _draw() -> void:
	var hundido := get_draw_mode() in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
	var r := minf(size.x, size.y) / 2.0 / 1.25
	Relieve.moneda(self, size / 2.0 + Vector2(0, 1.0 if hundido else 0.0), r, "actual", 0, Relieve.AMBAR)
