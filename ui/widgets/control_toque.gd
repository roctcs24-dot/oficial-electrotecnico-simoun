class_name ControlToque
extends Control
## Dibujo que se toca, como el buque del inicio o el camino de la Escuela. Distingue un toque de
## un arrastre igual que FilaMenu, así la lista se desplaza aunque el gesto empiece encima.
## Las clases hijas dibujan en _draw() y reciben el toque en _al_tocar().

const ZONA_MUERTA := 14.0

var _presionado := false
var _inicio := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		var boton := evento as InputEventMouseButton
		if boton.pressed:
			_presionado = true
			_inicio = boton.position
			_al_presionar(boton.position)
		elif _presionado:
			_presionado = false
			_al_soltar()
			if Rect2(Vector2.ZERO, size).has_point(boton.position):
				_al_tocar(boton.position)
	elif evento is InputEventMouseMotion and _presionado:
		if (evento as InputEventMouseMotion).position.distance_to(_inicio) > ZONA_MUERTA:
			cancelar_toque()


## Toque completo en «punto», en coordenadas del control.
func _al_tocar(_punto: Vector2) -> void:
	pass


## Para resaltar lo que hay bajo el dedo mientras se mantiene.
func _al_presionar(_punto: Vector2) -> void:
	queue_redraw()


func _al_soltar() -> void:
	queue_redraw()


## La lista la llama al empezar a desplazarse (Pantalla.cancelar_pulsaciones).
func cancelar_toque() -> void:
	if _presionado:
		_presionado = false
		_al_soltar()


## Simula un toque, para las pruebas.
func tocar(punto: Vector2) -> void:
	_al_tocar(punto)
