extends PantallaPreguntas
## Repasar mis errores: repetición espaciada de lo que más se falla.

const POR_SESION := 10
const COLOR := Color("ffc23a")


func construir() -> void:
	if not args.has("items") and _temas_disponibles().is_empty():
		_construir_vacio()
		return
	super()


func _banco() -> BancoRepaso:
	return BancoRepaso.new(raiz.contenido)


## Los temas cuya pregunta ya no existe se omiten: nunca podrían resolverse.
func _temas_disponibles() -> Array[String]:
	var banco := _banco()
	var lista: Array[String] = []
	for tema in raiz.partida.temas_pendientes():
		if banco.tiene(tema):
			lista.append(tema)
	return lista


func _crear_items() -> Array:
	var banco := _banco()
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var items := []
	for tema in _temas_disponibles().slice(0, POR_SESION):
		items.append(banco.pregunta(tema, azar))
	return items


func _titulo() -> String:
	return "Repasar mis errores"


func _color() -> Color:
	return COLOR


func _icono() -> String:
	return "repaso"


func _subtitulo() -> String:
	var n: int = args.get("items", []).size()
	return "%d %s para hoy" % [n, "tema" if n == 1 else "temas"]


## En el repaso, la marcha son las cajas de la repetición espaciada del tema de la pregunta.
func _indicador(items: Array, indice: int) -> Control:
	var tema := str(items[indice].get("tema", ""))
	var entrada: Dictionary = raiz.partida.datos["errores"].get(tema, {})
	var caja := int(entrada.get("caja", 0))
	# Ya contestada, la caja se movió: se muestra la que tenía al preguntar.
	var r: Dictionary = args["respuestas"].get(indice, {})
	if not r.is_empty():
		caja = maxi(caja - 1, 0) if r["acierto"] else 0
	return PiezasLeccion.CajasRepaso.new(caja)


func _al_contestar(item: Dictionary, acierto: bool) -> void:
	raiz.partida.registrar_repaso(item["tema"], acierto)


func _construir_vacio() -> void:
	_poner_cabecera("Sin temas pendientes")
	var placa: Array = _placa_con("", "SinTemas")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa[1].add_child(fila)
	var medalla := MedallaModulo.new()
	medalla.custom_minimum_size = Vector2(70, 70)
	medalla.iniciar("sola", "Repaso", "repaso", COLOR, 1.0)
	medalla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(medalla)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	textos.add_child(PiezasLeccion.etiqueta("No hay temas pendientes", 18, Color.WHITE, Tema.PESO_NEGRITA))
	var texto := "Cuando falle una pregunta o cometa una falta en una misión, el tema aparecerá aquí."
	if not raiz.partida.datos["errores"].is_empty():
		texto = "Cada tema vuelve a aparecer después de un tiempo: 1, 3, 7, 14 y 30 días con cada acierto."
	textos.add_child(PiezasLeccion.etiqueta(texto, 14, Tema.TEXTO_SUAVE))
	var arriba: Array[Control] = [placa[0]]
	_disponer(arriba, [] as Array[Control])
	_botones_pie([["VOLVER", raiz.volver, "Volver"]])


func _construir_final() -> void:
	var total: int = args["items"].size()
	_poner_cabecera("Sesión terminada")
	var placa: Array = _placa_con("Resultado", "Resultado")
	var cal := Resumen.new()
	cal.correctas = aciertos()
	cal.total = total
	placa[1].add_child(cal)
	placa[1].add_child(PiezasLeccion.etiqueta("Los temas acertados volverán más adelante. Los fallados, mañana.", 14, Tema.TEXTO_SUAVE))
	var pendientes := _temas_disponibles().size()
	if pendientes > 0:
		placa[1].add_child(PiezasLeccion.fila_lampara("ambar", "Quedan %d temas pendientes para hoy." % pendientes, 14))
	var arriba: Array[Control] = [placa[0]]
	_disponer(arriba, [] as Array[Control])
	var botones: Array = []
	if pendientes > 0:
		botones.append(["CONTINUAR EL REPASO", _continuar, "Continuar", str(pendientes)])
	botones.append(["VOLVER", raiz.volver, "Volver"])
	_botones_pie(botones)


func _continuar() -> void:
	for clave in ["items", "indice", "respuestas"]:
		args.erase(clave)
	raiz.reconstruir()


## Visor de aciertos de la sesión de repaso y una lámpara por pregunta.
class Resumen:
	extends Control

	var correctas := 0
	var total := 0

	func _init() -> void:
		name = "ResumenRepaso"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(260, 64)

	func _draw() -> void:
		var caja := Rect2(0, 0, minf(size.x, 220.0), 62.0)
		DibujoAri.sombra(self, caja, 8.0, 0.5, Vector2(0, 2))
		DibujoAri.degradado(self, caja, 8.0, [Color("05080a"), Color("2a3b48")])
		PiezasAri.visor(self, Rect2(caja.position + Vector2(6, 6), Vector2(caja.size.x - 12.0, 34.0)), 1.0, str(correctas), "DE %d" % total, Tema.ARI_LCD_VERDE, 22.0)
		PiezasAri.texto(self, "ACIERTOS", caja.get_center().x, caja.end.y - 8.0, float(Tema.tam(10)), Color("a9b6c1"), Tema.PESO_NEGRITA)
