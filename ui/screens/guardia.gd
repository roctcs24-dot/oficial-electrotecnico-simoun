extends Pantalla
## Misiones de avería de un sistema, como la lista de alarmas de un puesto de guardia: cada
## avería reportada es una fila con su panel y su estado. Las pendientes salen también en la
## lista de alarmas del marco; tocar cualquiera de las dos abre la misión.

## Pantalla de cada tipo de misión; las de motores, sin tipo, usan la mesa de trabajo.
const PANTALLAS := {"cuadro": "mision_cuadro", "planta": "mision_planta", "red": "mision_red"}


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera("Guardia", s.get("nombre", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(6)
	desplazable.add_child(_ancho_lectura(lista))
	var ids := _misiones()
	var pendientes := ids.filter(func(id: String) -> bool: return not _completada(id))
	lista.add_child(_resumen(pendientes.size(), ids.size()))
	var tabla := PanelContainer.new()
	tabla.name = "TablaAverias"
	tabla.mouse_filter = Control.MOUSE_FILTER_PASS
	var negro := StyleBoxFlat.new()
	negro.bg_color = Tema.ARI_LISTA
	negro.set_corner_radius_all(6)
	negro.border_color = Tema.ARI_BORDE
	negro.set_border_width_all(1)
	negro.content_margin_bottom = 4
	tabla.add_theme_stylebox_override("panel", negro)
	lista.add_child(tabla)
	var filas := _columna(1)
	tabla.add_child(filas)
	filas.add_child(_cabecera_tabla())
	# Primero las pendientes, como en un puesto de alarmas; dentro de cada grupo, en el orden del
	# sistema.
	for id: String in pendientes + ids.filter(_completada):
		var m := raiz.contenido.mision(id)
		var fila := FilaAveria.new()
		fila.preparar(m, _codigo_mision(m), _estado_mision(id), raiz.vertical)
		fila.pulsada.connect(abrir_mision.bind(id))
		filas.add_child(fila)
	lista.add_child(_etiqueta("Cada misión empieza con un reporte de avería. Aplique el procedimiento real: bloqueo y etiquetado, medición, diagnóstico, reparación, prueba y libro de registro.", "Nota"))


func _misiones() -> Array:
	return raiz.contenido.sistema(args["id"])["modos"]["guardia"].get("misiones", [])


func _completada(id: String) -> bool:
	return raiz.partida.datos["misiones"].get(id, {}).get("completada", false)


func abrir_mision(id: String) -> void:
	var m := raiz.contenido.mision(id)
	raiz.ir_a(PANTALLAS.get(m.get("tipo", ""), "mision"), {"id": id})


## Panel del buque donde ocurre la avería, como P-31 o C-21; vacío si no tiene.
func _codigo_mision(m: Dictionary) -> String:
	return raiz.paneles.codigo_mision(m)


## «sin_atender», «en_curso» o el número de estrellas de una misión hecha.
func _estado_mision(id: String) -> String:
	var r: Dictionary = raiz.partida.datos["misiones"].get(id, {})
	if r.is_empty():
		return "sin_atender"
	if r.get("completada", false):
		return "hecha_%d" % int(r["estrellas"])
	return "en_curso"


func _resumen(pendientes: int, total: int) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var luz := LuzPiloto.new()
	luz.custom_minimum_size = Vector2(18, 18)
	luz.color_apagado = LuzPiloto.ROJO_APAGADO if pendientes > 0 else LuzPiloto.VERDE_APAGADO
	luz.color_encendido = LuzPiloto.ROJO_ENCENDIDO if pendientes > 0 else LuzPiloto.VERDE_ENCENDIDO
	luz.encendida = true
	luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(luz)
	var texto := "%d AVERÍAS SIN TERMINAR DE %d" % [pendientes, total] if pendientes > 0 else "TODAS LAS AVERÍAS ATENDIDAS"
	if pendientes == 1:
		texto = "1 AVERÍA SIN TERMINAR DE %d" % total
	var t := PanelAri.texto(texto, 13, Tema.ARI_EVENTO if pendientes > 0 else Tema.ARI_NORMAL, Tema.PESO_NEGRITA)
	t.add_theme_font_override("font", PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 1))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(t)
	var nota := PanelAri.texto("Toque una avería para atenderla", 12, Tema.ARI_TEXTO_SUAVE)
	nota.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nota.visible = not raiz.vertical
	fila.add_child(nota)
	return fila


func _cabecera_tabla() -> Control:
	var cab := PanelAri.Cabecera.new(Tema.ARI_CABECERA)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cab.add_child(fila)
	for d: Array in [["PANEL", 56.0], ["AVERÍA REPORTADA", 0.0], ["ESTADO", 0.0]]:
		var t := PanelAri.texto(d[0], 10.5, Tema.ARI_TEXTO, Tema.PESO_NEGRITA)
		t.add_theme_font_override("font", PanelAri.fuente_rotulo(Tema.PESO_NEGRITA, 2))
		t.custom_minimum_size.x = d[1]
		if d[0] == "AVERÍA REPORTADA":
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(t)
	return cab


## Las averías sin terminar, en la lista de alarmas del marco: tocarlas abre la misión.
func alarmas_marco_detalle() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for id: String in _misiones():
		if _completada(id):
			continue
		var m := raiz.contenido.mision(id)
		var codigo := _codigo_mision(m)
		var texto: String = m.get("titulo", id)
		if not codigo.is_empty():
			texto = "%s · %s" % [codigo, texto]
		r.append({"hora": "", "texto": texto, "tipo": "alarma", "abrir": abrir_mision.bind(id)})
	return r


func alarmas_marco() -> Array[String]:
	var r: Array[String] = []
	for a in alarmas_marco_detalle():
		r.append(str(a["texto"]))
	return r


## Fila de la tabla de averías: luz de estado, código del panel, título y estado, y una placa
## de acción (ATENDER, SEGUIR o REPETIR). Es una FilaMenu: se toca igual y deja arrastrar la lista.
class FilaAveria:
	extends FilaMenu
	var estado := ""
	var _luz: LuzPiloto

	func preparar(m: Dictionary, codigo: String, p_estado: String, en_columna: bool) -> void:
		estado = p_estado
		var tinta := Tema.ARI_ALARMA
		if estado == "en_curso":
			tinta = Tema.ARI_LCD_AMBAR
		elif estado.begins_with("hecha"):
			tinta = Tema.ARI_NORMAL
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fila)
		_luz = LuzPiloto.new()
		_luz.custom_minimum_size = Vector2(14, 14)
		_luz.color_apagado = Color(tinta, 0.25)
		_luz.color_encendido = tinta
		_luz.encendida = true
		_luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(_luz)
		# Sin tablero del buque, la avería se busca en la mesa del Taller.
		var chip := Placa.new(codigo if not codigo.is_empty() else "MESA")
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(chip)
		var textos := VBoxContainer.new()
		textos.add_theme_constant_override("separation", 1)
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(textos)
		var titulo := PanelAri.texto(str(m.get("equipo", "")).to_upper() + " · " + str(m.get("titulo", "")).to_upper(), 12.5 if not en_columna else 12.0, tinta, Tema.PESO_NEGRITA)
		titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textos.add_child(titulo)
		var detalle := PanelAri.texto(_texto_estado(), 11, Color("8aa0b2"), Tema.PESO_MEDIO)
		textos.add_child(detalle)
		var accion := Placa.new(_texto_accion(), _colores_accion(), Color.WHITE if not estado == "en_curso" else Tema.ARI_TEXTO_OSCURO, 12)
		accion.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(accion)
		_actualizar_estilo()

	func _texto_estado() -> String:
		if estado == "sin_atender":
			return "SIN ATENDER"
		if estado == "en_curso":
			return "EN CURSO: SIN TERMINAR"
		var n := int(estado.trim_prefix("hecha_"))
		return "HECHA · %d DE 3 ESTRELLAS" % n

	func _texto_accion() -> String:
		return {"sin_atender": "ATENDER ›", "en_curso": "SEGUIR ›"}.get(estado, "REPETIR ›")

	func _colores_accion() -> Array:
		if estado == "sin_atender":
			return Tema.ARI_ROJO
		if estado == "en_curso":
			return Tema.ARI_AMBAR
		return Tema.ARI_BOTON

	func _actualizar_estilo() -> void:
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(1, 1, 1, 0.07) if _presionada else Color(0, 0, 0, 0)
		if estado == "sin_atender":
			caja.bg_color = Color(Tema.ARI_ROJO[1], 0.30 if _presionada else 0.16)
		caja.border_color = Color("1d2a35")
		caja.border_width_bottom = 1
		caja.content_margin_left = 10
		caja.content_margin_right = 8
		caja.content_margin_top = 6
		caja.content_margin_bottom = 6
		add_theme_stylebox_override("panel", caja)
		custom_minimum_size.y = 52.0


## Placa pequeña con degradado: el código del panel en amarillo o la acción de una fila.
class Placa:
	extends Control
	var texto := ""
	var colores: Array
	var tinta: Color
	var puntos := 11.0

	func _init(t: String, c: Array = [Color("ffdf7a"), Color("f0a91c")], p_tinta := Tema.ARI_TEXTO_OSCURO, p_puntos := 11.0) -> void:
		texto = t
		colores = c
		tinta = p_tinta
		puntos = p_puntos
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var f := Tema.fuente(Tema.PESO_NEGRITA)
		var ancho := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.tam(puntos)).x
		custom_minimum_size = Vector2(maxf(ancho + 16.0, 46.0), Tema.tam(puntos) + 14.0)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DibujoAri.pieza(self, r, 4.0, colores, DibujoAri.BRILLO if colores.size() == 4 else [], Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.35), 0.35)
		var f := Tema.fuente(Tema.PESO_NEGRITA)
		var tam := Tema.tam(puntos)
		var w := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(f, Vector2((size.x - w) / 2.0, size.y / 2.0 + f.get_ascent(tam) * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, tinta)
