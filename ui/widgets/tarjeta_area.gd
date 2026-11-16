class_name TarjetaArea
extends FilaMenu
## Tarjeta grande del inicio, del color de su área: icono blanco, nombre, detalle y barra de
## avance. Hereda de FilaMenu cómo distingue un toque de un arrastre.

const ALTO := 132.0
const LADO_ICONO_GRANDE := 32.0


func iniciar_area(titulo: String, detalle: String, icono: String, color_area: Color, avance := -1.0) -> void:
	activa = true
	color = color_area
	custom_minimum_size.y = ALTO
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(columna)
	if not icono.is_empty():
		var dibujo := VistaSvg.new()
		dibujo.cargar({"svg": "res://art/iconos/%s.svg" % icono, "tamano": [64, 64]})
		dibujo.custom_minimum_size = Vector2(LADO_ICONO_GRANDE, LADO_ICONO_GRANDE)
		dibujo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna.add_child(dibujo)
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(hueco)
	var nombre := _texto(titulo, "Fuerte", Color.WHITE)
	nombre.add_theme_font_size_override("font_size", 17)
	columna.add_child(nombre)
	if not detalle.is_empty():
		var d := _texto(detalle, "Nota", Color(1, 1, 1, 0.88))
		d.add_theme_font_size_override("font_size", 14)
		columna.add_child(d)
	if avance >= 0.0:
		var b := ProgressBar.new()
		b.min_value = 0.0
		b.max_value = 1.0
		b.value = clampf(avance, 0.0, 1.0)
		b.show_percentage = false
		b.custom_minimum_size.y = 6.0
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_theme_stylebox_override("background", Tema.caja(Color(1, 1, 1, 0.28), 3, 0, 0))
		b.add_theme_stylebox_override("fill", Tema.caja(Color.WHITE, 3, 0, 0))
		columna.add_child(b)
	_actualizar_estilo()


func _actualizar_estilo() -> void:
	var fondo := color.darkened(0.08)
	if _presionada:
		fondo = color.darkened(0.25)
	elif _encima and not OS.has_feature("mobile"):
		fondo = color.lightened(0.06)
	add_theme_stylebox_override("panel", Tema.caja(fondo, 18, 14, 14))
