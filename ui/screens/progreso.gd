extends Pantalla
## Rango, estadísticas y traspaso de la partida entre dispositivos.

const TEMAS_EN_ESTADISTICAS := 5
const NOMBRE_ARCHIVO := "partida_via_simoun.json"


func construir() -> void:
	_cabecera("Mi progreso")
	# Arriba y fuera de la lista: al pegar o elegir un archivo, debe verse sin desplazarse.
	if args.has("texto_importado") or args.has("mensaje"):
		var avisos := _columna(8)
		add_child(_ancho_lectura(avisos))
		if args.has("texto_importado"):
			_agregar_confirmacion(avisos)
		if args.has("mensaje"):
			avisos.add_child(_aviso(args["mensaje"]))
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(10)
	desplazable.add_child(_ancho_lectura(columna))
	_seccion_rango(columna)
	_seccion_avance(columna)
	_seccion_errores(columna)
	_seccion_ajustes(columna)
	_seccion_partida(columna)


## Tamaño del texto y la bienvenida de la primera vez.
func _seccion_ajustes(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Tamaño del texto"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	columna.add_child(fila)
	var grupo := ButtonGroup.new()
	for t: Array in Tema.TAMANOS_TEXTO:
		var b := _boton(t[0], raiz.aplicar_tamano_texto.bind(t[1]))
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(is_equal_approx(Tema.escala_texto, t[1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	columna.add_child(_boton("Ver la bienvenida otra vez", raiz.ir_a.bind("bienvenida")))


func _seccion_rango(columna: VBoxContainer) -> void:
	var p := raiz.partida
	var rangos := raiz.contenido.rangos()
	var actual := p.rango(rangos)
	columna.add_child(_rotulo("Rango"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	columna.add_child(fila)
	var pala := PalaRango.new(_galones(rangos, actual), true)
	pala.name = "PalaActual"
	pala.custom_minimum_size = Vector2(96, 48)
	pala.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(pala)
	var textos := _columna(2)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(textos)
	textos.add_child(_etiqueta(actual, "Subtitulo"))
	var siguiente := p.siguiente_rango(rangos)
	if siguiente.is_empty():
		textos.add_child(_etiqueta("%d puntos. Es el rango más alto." % p.datos["puntos"], "Nota"))
	else:
		textos.add_child(_etiqueta("%d puntos. Faltan %d para %s." % [p.datos["puntos"], siguiente["faltan"], siguiente["nombre"]], "Nota"))
	columna.add_child(_barra_avance(p.progreso_rango(rangos)))
	_escalera(columna, rangos, actual)
	_puntos_del_juego(columna)


func _galones(rangos: Array, nombre: String) -> int:
	for r: Dictionary in rangos:
		if r["nombre"] == nombre:
			return int(r.get("galones", 0))
	return 0


## Los rangos de arriba abajo, del más alto al primero: alcanzados en verde, el actual en ámbar.
func _escalera(columna: VBoxContainer, rangos: Array, actual: String) -> void:
	columna.add_child(_rotulo("Escalera de rangos"))
	var puntos := int(raiz.partida.datos["puntos"])
	for i in range(rangos.size() - 1, -1, -1):
		var r: Dictionary = rangos[i]
		var es_actual: bool = r["nombre"] == actual
		var alcanzado := puntos >= int(r["puntos"])
		var fila := HBoxContainer.new()
		fila.name = "Rango_%d" % i
		fila.add_theme_constant_override("separation", 10)
		fila.custom_minimum_size.y = 40.0
		columna.add_child(fila)
		var luz := PiezasLeccion.Lampara.new("ambar" if es_actual else "verde", alcanzado, 6.0)
		luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(luz)
		var pala := PalaRango.new(int(r.get("galones", 0)), es_actual, not alcanzado)
		pala.custom_minimum_size = Vector2(58, 29)
		pala.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(pala)
		var color := Color("ffd166") if es_actual else (Color.WHITE if alcanzado else Tema.TEXTO_SUAVE)
		var nombre := PiezasLeccion.etiqueta(str(r["nombre"]), 14, color, Tema.PESO_FUERTE)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nombre)
		var pts := PiezasLeccion.etiqueta("%d pts" % int(r["puntos"]), 13, color, Tema.PESO_FUERTE)
		pts.autowrap_mode = TextServer.AUTOWRAP_OFF
		pts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(pts)


## Cuántos puntos da cada parte del juego: así se ve qué falta para el rango más alto.
func _puntos_del_juego(columna: VBoxContainer) -> void:
	var m := PuntosJuego.maximos(raiz.contenido)
	columna.add_child(_rotulo("Puntos que da el juego"))
	for par: Array in [["Lecciones", m["lecciones"]], ["Misiones de Guardia", m["misiones"]], ["Exámenes y minijuegos", m["evaluaciones"]], ["Todo el juego", m["total"]]]:
		var fila := HBoxContainer.new()
		fila.name = "Puntos_%s" % str(par[0]).replace(" ", "_")
		columna.add_child(fila)
		var total: bool = par[0] == "Todo el juego"
		var color := Color("ffd166") if total else Tema.TEXTO
		var e := PiezasLeccion.etiqueta(str(par[0]), 14, color, Tema.PESO_FUERTE if total else Tema.PESO_MEDIO)
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(e)
		var valor := PiezasLeccion.etiqueta(str(par[1]), 14, color, Tema.PESO_FUERTE)
		valor.autowrap_mode = TextServer.AUTOWRAP_OFF
		fila.add_child(valor)


func _seccion_avance(columna: VBoxContainer) -> void:
	var c := raiz.contenido
	var p := raiz.partida
	var lecciones := 0
	var hechas := 0
	var misiones := 0
	var completadas := 0
	var estrellas := 0
	for s: Dictionary in c.todos():
		var modos: Dictionary = s.get("modos", {})
		for id: String in modos.get("aprender", {}).get("lecciones", []):
			lecciones += 1
			if p.leccion_completada(id):
				hechas += 1
		for id: String in modos.get("guardia", {}).get("misiones", []):
			misiones += 1
			var r: Dictionary = p.datos["misiones"].get(id, {})
			if r.get("completada", false):
				completadas += 1
				estrellas += int(r["estrellas"])
	columna.add_child(_rotulo("Avance"))
	columna.add_child(_etiqueta("Lecciones: %d de %d" % [hechas, lecciones]))
	columna.add_child(_etiqueta("Misiones de Guardia: %d de %d, con %d de %d estrellas" % [completadas, misiones, estrellas, misiones * 3]))
	for id: String in raiz.contenido.examenes():
		var titulo: String = raiz.contenido.examen(id).get("titulo", id)
		var e: Dictionary = p.datos["examenes"].get(id, {})
		if e.is_empty():
			columna.add_child(_etiqueta("%s: sin presentar" % titulo))
		else:
			columna.add_child(_etiqueta("%s: %s, mejor nota %d %%" % [titulo, "aprobado" if e["aprobado"] else "no aprobado", roundi(e["mejor"])]))
	var accidentes := 0
	for r: Dictionary in p.datos["misiones"].values():
		accidentes += int(r.get("accidentes", 0))
	if accidentes > 0:
		columna.add_child(_etiqueta("Informes de accidente: %d" % accidentes))


func _seccion_errores(columna: VBoxContainer) -> void:
	var p := raiz.partida
	columna.add_child(_rotulo("Errores"))
	columna.add_child(_etiqueta("Fallos registrados: %d" % p.total_fallos()))
	var banco := BancoRepaso.new(raiz.contenido)
	for tema in p.temas_mas_fallados(TEMAS_EN_ESTADISTICAS):
		columna.add_child(_etiqueta("%d × %s" % [int(p.datos["errores"][tema]["fallos"]), banco.titulo(tema)], "Nota"))
	columna.add_child(_boton("Repasar mis errores", raiz.ir_a.bind("repaso")))


func _seccion_partida(columna: VBoxContainer) -> void:
	columna.add_child(_rotulo("Pasar la partida a otro dispositivo"))
	columna.add_child(_etiqueta("Cada dispositivo guarda su propio progreso. Exporte aquí y, en el otro, importe el archivo o pegue el texto. Importar reemplaza el progreso de ese dispositivo.", "Nota"))
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		columna.add_child(_boton("Exportar a un archivo", _elegir_destino))
		columna.add_child(_boton("Importar desde un archivo", _elegir_origen))
	columna.add_child(_boton("Copiar la partida como texto", copiar))
	columna.add_child(_boton("Pegar una partida copiada", pegar))


func _agregar_confirmacion(columna: VBoxContainer) -> void:
	var r := Partida.examinar(args["texto_importado"])
	columna.add_child(_aviso("La partida recibida tiene %d puntos, y la de este dispositivo, %d. Si continúa, se reemplazará el progreso de este dispositivo." % [r["puntos"], raiz.partida.datos["puntos"]]))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	columna.add_child(fila)
	for b: Button in [_boton("Reemplazar mi progreso", confirmar_importacion), _boton("Cancelar", _cancelar_importacion)]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)


func _elegir_destino() -> void:
	DisplayServer.file_dialog_show("Exportar la partida", "", NOMBRE_ARCHIVO, false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(), _al_elegir_destino)


func _elegir_origen() -> void:
	# Sin filtro: un archivo recibido por mensajería puede traer un tipo o un nombre distinto.
	DisplayServer.file_dialog_show("Importar una partida", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(), _al_elegir_origen)


func _al_elegir_destino(aceptado: bool, rutas: PackedStringArray, _filtro: int) -> void:
	if aceptado and not rutas.is_empty():
		exportar_a(rutas[0])


func _al_elegir_origen(aceptado: bool, rutas: PackedStringArray, _filtro: int) -> void:
	if aceptado and not rutas.is_empty():
		importar_de(rutas[0])


func exportar_a(ruta: String) -> void:
	_mostrar("Partida exportada." if raiz.partida.exportar(ruta) else "No se pudo escribir el archivo. Pruebe a copiar la partida como texto.")


func importar_de(ruta: String) -> void:
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		_mostrar("No se pudo leer el archivo. Pruebe a pegar la partida como texto.")
		return
	recibir_texto(archivo.get_as_text())


func copiar() -> void:
	DisplayServer.clipboard_set(raiz.partida.a_texto())
	_mostrar("Partida copiada. Péguela en una nota o un mensaje para llevarla al otro dispositivo.")


func pegar() -> void:
	recibir_texto(DisplayServer.clipboard_get())


## Se revisa sin tocar nada, y se pide confirmación antes de reemplazar el progreso.
func recibir_texto(texto: String) -> void:
	var r := Partida.examinar(texto)
	if not r["motivo"].is_empty():
		args.erase("texto_importado")
		_mostrar("No se importó: %s." % r["motivo"])
		return
	args["texto_importado"] = texto
	args.erase("mensaje")
	raiz.reconstruir.call_deferred()


func confirmar_importacion() -> void:
	var motivo := raiz.partida.importar_texto(args["texto_importado"])
	args.erase("texto_importado")
	_mostrar("Partida importada." if motivo.is_empty() else "No se importó: %s." % motivo)


func _cancelar_importacion() -> void:
	args.erase("texto_importado")
	raiz.reconstruir.call_deferred()


func _mostrar(mensaje: String) -> void:
	args["mensaje"] = mensaje
	raiz.reconstruir.call_deferred()
