extends PantallaPreguntas
## Minijuego «Símbolos ISO 1219»: diez rondas. En unas se ve la pieza dibujada (la del atlas) y se
## toca su símbolo entre cuatro hojas de papel; en otras se ve el símbolo y se elige su nombre.
## Registro «simbolos_iso1219». Lo elegido vive en args para sobrevivir al giro.

const RONDAS := 10
const COLOR := Color("1f7fd1")
const Examen := preload("res://ui/screens/prueba_examen.gd")

var opciones: Array[OpcionSimbolo] = []


func _simbolos() -> Array:
	return JuegoIso1219.leer(raiz.contenido, str(args.get("familia", "")))


func _crear_items() -> Array:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	return JuegoIso1219.crear_rondas(_simbolos(), RONDAS, azar)


func _titulo() -> String:
	return "ISO 1219"


func _subtitulo() -> String:
	return "Símbolos de hidráulica · %d rondas" % args.get("items", []).size()


func _color() -> Color:
	return COLOR


func _icono() -> String:
	return "hidraulica"


func _crear_pregunta(columna: VBoxContainer, item: Dictionary, indice: int) -> void:
	var respuesta: Dictionary = args["respuestas"].get(indice, {})
	var lista := _simbolos()
	var s := JuegoIso1219.simbolo(lista, item["id"])
	var disposicion: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	disposicion.add_theme_constant_override("separation", 12)
	disposicion.mouse_filter = Control.MOUSE_FILTER_PASS
	columna.add_child(disposicion)
	var visor := VisorFicha.new(12.0)
	visor.name = "Visor"
	visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disposicion.add_child(visor)
	var dentro := VBoxContainer.new()
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(dentro)
	var lado := _columna()
	lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disposicion.add_child(lado)
	if item["tipo"] == "pieza":
		dentro.add_child(PiezasLeccion.rotulo("¿Qué pieza es? Toque su símbolo"))
		var ficha := raiz.contenido.ficha(str(item["pieza"]))
		var dibujo := VistaSvg.new()
		dibujo.name = "Pieza"
		var def: Dictionary = ficha.get("dibujo", {}).duplicate()
		def.erase("etiquetas")
		dibujo.cargar(def)
		dibujo.custom_minimum_size.y = 210.0 if raiz.vertical else 230.0
		dentro.add_child(dibujo)
		dentro.add_child(PiezasLeccion.etiqueta("Dibujo de enseñanza: marca y datos, verificar a bordo.", 11, Tema.TEXTO_SUAVE))
		var rejilla := GridContainer.new()
		rejilla.name = "Opciones"
		rejilla.columns = 2
		rejilla.add_theme_constant_override("h_separation", 10)
		rejilla.add_theme_constant_override("v_separation", 10)
		lado.add_child(rejilla)
		opciones.clear()
		var elegida := int(respuesta.get("elegida", -1))
		for i in item["opciones"].size():
			var o := OpcionSimbolo.new()
			o.name = "Opcion_%d" % i
			o.letra = "ABCD"[i]
			o.cargar(JuegoIso1219.simbolo(lista, item["opciones"][i]))
			o.custom_minimum_size = Vector2(120, 130 if raiz.vertical else 112)
			o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if not respuesta.is_empty():
				o.disabled = true
				o.estado = "ok" if i == int(item["correcta"]) else ("mal" if i == elegida else "")
				o.nombre = str(JuegoIso1219.simbolo(lista, item["opciones"][i])["nombre"]) if o.estado != "" else ""
			else:
				o.pressed.connect(elegir.bind(i))
			rejilla.add_child(o)
			opciones.append(o)
		if not respuesta.is_empty():
			var ok: bool = respuesta.get("acierto", false)
			lado.add_child(PiezasLeccion.explicacion(ok, "%s (%s). %s" % [s.get("nombre", ""), s.get("en", ""), s.get("explicacion", "")]))
		return
	dentro.add_child(PiezasLeccion.rotulo("Identifique el símbolo"))
	var hoja := PiezasLeccion.papel(8.0)
	dentro.add_child(hoja)
	var simbolo := VistaSvg.new()
	simbolo.name = "Simbolo"
	simbolo.color_etiquetas = Tema.TINTA
	simbolo.cargar(s)
	simbolo.custom_minimum_size.y = ALTO_SIMBOLO if raiz.vertical else ALTO_SIMBOLO * 0.85
	hoja.add_child(simbolo)
	_agregar_quiz(lado, item, respuesta, indice, "Símbolo ISO 1219")


## Toca la opción «i» de una ronda de pieza.
func elegir(i: int) -> void:
	var indice: int = args["indice"]
	var item: Dictionary = args["items"][indice]
	if args["respuestas"].has(indice):
		return
	_resolver(indice, i == int(item["correcta"]), i)
	raiz.reconstruir()


## Responde bien la ronda actual (para las pruebas).
func resolver_bien() -> void:
	var indice: int = args["indice"]
	var item: Dictionary = args["items"][indice]
	if item["tipo"] == "pieza":
		elegir(int(item["correcta"]))
	else:
		_resolver(indice, true, int(item["correcta"]))


func _construir_final() -> void:
	var total: int = args["items"].size()
	var correctas := aciertos()
	var estrellas := JuegoSimbolos.estrellas(correctas, total)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_minijuego(JuegoIso1219.REGISTRO, estrellas)
	_poner_cabecera("Resultado")
	var calif: Array = _placa_con("Calificación", "PlacaCalificacion")
	var cal = Examen.Calificacion.new()
	cal.porcentaje = 100.0 * correctas / maxf(total, 1)
	cal.minimo = 50.0
	cal.estrellas = estrellas
	cal.aprobado = estrellas > 0
	cal.correctas = correctas
	cal.total = total
	cal.puntos = int(args["ganados"])
	calif[1].add_child(cal)
	var izquierda: Array[Control] = [calif[0]]
	var derecha: Array[Control] = []
	var falladas: Array[String] = []
	var lista := _simbolos()
	for i in total:
		if not args["respuestas"].get(i, {}).get("acierto", false):
			var t := str(JuegoIso1219.simbolo(lista, args["items"][i]["id"]).get("nombre", ""))
			if not falladas.has(t):
				falladas.append(t)
	if not falladas.is_empty():
		var temas: Array = _placa_con("A repasar", "ARepasar")
		for t in falladas:
			temas[1].add_child(PiezasLeccion.fila_lampara("rojo", t, 14))
		derecha.append(temas[0])
	var nota: Array = _placa_con("La norma", "NotaNorma")
	nota[1].add_child(PiezasLeccion.etiqueta(str(raiz.contenido.leer(JuegoIso1219.ARCHIVO).get("nota", "")), 13, Tema.TEXTO_SUAVE))
	derecha.append(nota[0])
	_disponer(izquierda, derecha)
	_botones_pie([["JUGAR OTRA VEZ", _repetir, "Repetir"], ["VOLVER", raiz.volver, "Volver"]])


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()


## Hoja de papel con un símbolo y su letra; verde si es la correcta, roja si es la elegida mal.
class OpcionSimbolo:
	extends Button

	var letra := "A"
	var estado := ""
	var nombre := ""
	var _dibujo: VistaSvg

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		focus_mode = Control.FOCUS_NONE
		var papel := Relieve.estilo_papel(8.0)
		for clave in ["normal", "hover", "pressed", "disabled", "focus"]:
			add_theme_stylebox_override(clave, papel)
		_dibujo = VistaSvg.new()
		_dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dibujo.color_etiquetas = Tema.TINTA
		_dibujo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_dibujo.offset_left = 18.0
		_dibujo.offset_right = -6.0
		_dibujo.offset_top = 6.0
		_dibujo.offset_bottom = -6.0
		add_child(_dibujo)

	func cargar(definicion: Dictionary) -> void:
		_dibujo.cargar(definicion)

	func _draw() -> void:
		var color := Color("22c55e") if estado == "ok" else (Color("ff4a3a") if estado == "mal" else Color(0, 0, 0, 0))
		if color.a > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size).grow(-1.5), color, false, 3.0)
		var c := Vector2(18, 18)
		draw_circle(c + Vector2(0, 1.5), 13.0, Color(0, 0, 0, 0.4))
		draw_circle(c, 12.0, Color("22c55e") if estado == "ok" else (Color("e2392d") if estado == "mal" else Color("3a4652")))
		var fuente := get_theme_default_font()
		var w := fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(fuente, c + Vector2(-w / 2.0, 5.0), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if not nombre.is_empty():
			var tam := 11
			var wn := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
			draw_string(fuente, Vector2(maxf((size.x - wn) / 2.0, 4.0), size.y - 6.0), nombre, HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, tam, Color("0f5c2a") if estado == "ok" else Color("8a1c14"))
