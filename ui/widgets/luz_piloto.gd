class_name LuzPiloto
extends Control
## Luz piloto con su aro metálico.

const VERDE_APAGADO := Color("1d3a28")
const VERDE_ENCENDIDO := Color("5dff8f")
const ROJO_APAGADO := Color("3a1d1d")
const ROJO_ENCENDIDO := Color("ff5a4a")
const AMBAR_APAGADO := Color("3a301a")
const AMBAR_ENCENDIDO := Color("ffc24a")

var color_apagado := VERDE_APAGADO
var color_encendido := VERDE_ENCENDIDO
var encendida := false:
	set(valor):
		if valor != encendida:
			encendida = valor
			queue_redraw()
## Para lámparas que alumbran según la tensión, como las de tierra: de 0 a 1.
var brillo := 1.0:
	set(valor):
		valor = clampf(valor, 0.0, 1.0)
		if not is_equal_approx(valor, brillo):
			brillo = valor
			queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(48.0, 48.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centro := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_circle(centro, r, Color("8e9496"))
	draw_circle(centro, r * 0.82, Color("2a2d30"))
	var luz := brillo if encendida else 0.0
	draw_circle(centro, r * 0.7, color_apagado.lerp(color_encendido, luz))
	draw_circle(centro - Vector2(r, r) * 0.22, r * 0.18, Color(1.0, 1.0, 1.0, 0.2 + 0.4 * luz))
