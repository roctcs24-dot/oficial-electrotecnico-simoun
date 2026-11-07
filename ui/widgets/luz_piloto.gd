class_name LuzPiloto
extends Control
## Luz piloto de 22 mm con su aro cromado moleteado y lente de Fresnel.

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
	var r := minf(size.x, size.y) / 2.0 - 2.0
	var luz := brillo if encendida else 0.0
	DibujoInstrumentos.lampara(self, size / 2.0, r, color_apagado, color_encendido, luz)
