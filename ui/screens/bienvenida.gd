extends Pantalla
## Bienvenida de la primera vez: qué es el juego, por dónde empezar y cómo se maneja. Se puede
## volver a abrir desde Mi progreso.

const PAGINAS := [
	["Bienvenido a bordo",
		"Este juego prepara para el puesto de oficial electrotécnico del atunero B/P Vía Simoun: generadores y cuadro principal, motores, refrigeración por amoníaco, cubierta, distribución, electrónica y alarmas.\n\nEmpieza desde cero. No hace falta saber qué es un voltio.",
		"inicio"],
	["Por dónde empezar",
		"• [b]Inicio:[/b] la tarjeta «Continuar» abre siempre la siguiente lección recomendada.\n• [b]Escuela técnica:[/b] electricidad, electrónica, hidráulica, válvulas y herramientas, desde cero y en orden.\n• [b]Buque:[/b] los sistemas reales del barco. En cada uno: Aprender, Taller para practicar, Guardia con averías y Examen.\n• [b]Pañol:[/b] consulta rápida de fichas de equipos y del glosario.",
		"escuela"],
	["Cómo se maneja",
		"• Toque una tarjeta para abrirla y arrastre para desplazar la lista.\n• En los tableros y en el Taller, pellizque o use la rueda del ratón para ampliar.\n• La tecla atrás del celular vuelve a la pantalla anterior.\n• Si la letra le resulta pequeña, cámbiela en Mi progreso.\n\nLos valores que no salen de las fotos del buque van marcados «verificar a bordo».",
		"progreso"],
]


func construir() -> void:
	var pagina := int(args.get("pagina", 0))
	var datos: Array = PAGINAS[pagina]
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(16)
	desplazable.add_child(_ancho_lectura(columna))
	var icono := VistaSvg.new()
	icono.cargar({"svg": "res://art/iconos/%s.svg" % datos[2], "tamano": [64, 64]})
	icono.custom_minimum_size = Vector2(64, 64)
	icono.modulate = Tema.ACENTO
	icono.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(icono)
	var titulo := _etiqueta(datos[0], "Titulo")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	columna.add_child(_texto_rico(datos[1]))
	var puntos := _etiqueta("Página %d de %d" % [pagina + 1, PAGINAS.size()], "Nota")
	puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(puntos)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	add_child(fila)
	var izquierda := _boton("Saltar" if pagina == 0 else "‹ Anterior", terminar if pagina == 0 else _ir.bind(pagina - 1))
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(izquierda)
	var ultima := pagina == PAGINAS.size() - 1
	var derecha := _boton("Empezar" if ultima else "Siguiente ›", terminar if ultima else _ir.bind(pagina + 1))
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for estado in ["normal", "hover", "pressed", "hover_pressed"]:
		derecha.add_theme_stylebox_override(estado, Tema.caja(Tema.ACENTO_FUERTE, Tema.RADIO, 14, 13))
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		derecha.add_theme_color_override(clave, Tema.FONDO)
	fila.add_child(derecha)


func _ir(pagina: int) -> void:
	args["pagina"] = pagina
	raiz.reconstruir()


func terminar() -> void:
	raiz.partida.datos["ajustes"]["bienvenida_vista"] = true
	raiz.partida.guardar()
	raiz.volver()
