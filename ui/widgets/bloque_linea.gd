class_name BloqueLinea
extends BoxContainer
## Un ejercicio de líneas: el esquema en un visor y, al lado (o debajo), la tarea.
## - «seguir»: los pasos de la ruta con su lámpara; se recorren con el dedo, en orden.
## - «aislar»: se tocan las válvulas y se pulsa COMPROBAR.
## - «servicio»: el tramo marcado late y se contesta con teclas de letra.
## Al terminar emite «respondido(acierto)». «estado» es un diccionario del que lo usa (args), para
## que lo hecho sobreviva al giro del celular.

signal respondido(acierto: bool)

var esquema := {}
var ejercicio := {}
var estado := {}
var resuelto := false
var acierto := true
var vista: VistaLineas
var _panel: VBoxContainer
var _pasos: Array[Control] = []
var _comprobar: BotonAri
var _quiz: BloqueQuiz


func _init() -> void:
	add_theme_constant_override("separation", 12)
	mouse_filter = Control.MOUSE_FILTER_PASS


## «previa» es la respuesta ya dada ({"acierto": …}) o vacía.
func iniciar(p_esquema: Dictionary, colores: Dictionary, p_ejercicio: Dictionary, p_estado: Dictionary, previa: Dictionary, vertical: bool, alto := 260.0) -> void:
	esquema = p_esquema
	ejercicio = p_ejercicio
	estado = p_estado
	resuelto = not previa.is_empty()
	acierto = previa.get("acierto", true)
	self.vertical = vertical
	if not estado.has("hechos"):
		estado["hechos"] = []
		estado["elegidas"] = []
		estado["errores"] = 0
	var visor := VisorFicha.new(10.0)
	visor.name = "VisorLinea"
	visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visor.size_flags_stretch_ratio = 1.6
	# En horizontal el esquema no se estira con la tarea: queda arriba, siempre a la vista.
	if not vertical:
		visor.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(visor)
	var dentro := VBoxContainer.new()
	dentro.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(dentro)
	var guia := {"seguir": "Arrastre el dedo por la línea", "aislar": "Toque las válvulas que cierra", "servicio": "Mire el tramo marcado"}
	dentro.add_child(PiezasLeccion.rotulo(str(guia.get(ejercicio["tipo"], ""))))
	vista = VistaLineas.new()
	vista.name = "Esquema"
	vista.esquema = esquema
	vista.colores = colores
	vista.custom_minimum_size.y = alto
	vista.tramo_tocado.connect(_al_tramo)
	vista.valvula_tocada.connect(_al_valvula)
	dentro.add_child(vista)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 8)
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var placa := PiezasLeccion.placa(14.0, 10.0)
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placa.add_child(_panel)
	add_child(placa)
	_panel.add_child(PiezasLeccion.rotulo(str(esquema.get("titulo", "Línea"))))
	match str(ejercicio["tipo"]):
		"seguir":
			_panel.add_child(PiezasLeccion.etiqueta(str(ejercicio["pregunta"]), 15, Tema.TEXTO, Tema.PESO_NEGRITA))
			for id: String in ejercicio["ruta"]:
				var fila := PiezasLeccion.fila_lampara("verde", str(JuegoLineas.tramo(esquema, id).get("nombre", id)), 13)
				fila.name = "Paso_%s" % id
				_pasos.append(fila)
				_panel.add_child(fila)
		"aislar":
			_panel.add_child(PiezasLeccion.etiqueta(str(ejercicio["pregunta"]), 15, Tema.TEXTO, Tema.PESO_NEGRITA))
			var lista := VBoxContainer.new()
			lista.name = "Elegidas"
			_panel.add_child(lista)
			_comprobar = BotonAri.new("COMPROBAR", comprobar, "ambar")
			_comprobar.name = "Comprobar"
			_comprobar.custom_minimum_size.y = 46.0
			_panel.add_child(_comprobar)
		"servicio":
			vista.marcado = str(ejercicio["tramo"])
			_quiz = BloqueQuiz.new()
			_quiz.rotulo = "Servicio"
			_quiz.iniciar(ejercicio, int(previa.get("elegida", -1)))
			if not resuelto:
				_quiz.respondido.connect(_al_quiz)
			_panel.add_child(_quiz)
	_refrescar()


func _refrescar() -> void:
	var tipo := str(ejercicio["tipo"])
	vista.activo = not resuelto
	if tipo == "seguir":
		var hechos: Array = estado["hechos"] if not resuelto else ejercicio["ruta"]
		vista.iluminados = hechos.duplicate()
		for i in _pasos.size():
			var luz: Control = _pasos[i].get_child(0)
			var hecho: bool = hechos.has(ejercicio["ruta"][i])
			luz.set("encendida", hecho)
			luz.set("color", "verde" if hecho else ("ambar" if i == hechos.size() else "apagada"))
			luz.queue_redraw()
	elif tipo == "aislar":
		var elegidas: Array = estado["elegidas"]
		var estados := {}
		for v in elegidas:
			estados[v] = "elegida"
		if resuelto:
			estados.clear()
			for v in ejercicio["valvulas"]:
				estados[v] = "cerrada" if elegidas.has(v) or elegidas.is_empty() else "falta"
			for v in elegidas:
				if not ejercicio["valvulas"].has(v):
					estados[v] = "sobra"
		vista.estados = estados
		var lista: VBoxContainer = _panel.get_node("Elegidas")
		for h in lista.get_children():
			h.queue_free()
		if elegidas.is_empty() and not resuelto:
			lista.add_child(PiezasLeccion.etiqueta("Ninguna válvula elegida todavía.", 13, Tema.TEXTO_SUAVE))
		for v: Dictionary in esquema.get("valvulas", []):
			if elegidas.has(v["id"]):
				lista.add_child(PiezasLeccion.fila_lampara("rojo", str(v["nombre"]), 13))
		_comprobar.visible = not resuelto
		_comprobar.disabled = elegidas.is_empty()
	if resuelto and tipo != "servicio" and _panel.get_node_or_null("Explicacion") == null:
		_panel.add_child(PiezasLeccion.explicacion(acierto, str(ejercicio.get("explicacion", ""))))


func _al_tramo(id: String) -> void:
	if resuelto or ejercicio["tipo"] != "seguir":
		return
	var r := JuegoLineas.paso_seguir(ejercicio["ruta"], estado["hechos"], id)
	if r == "error":
		estado["errores"] = int(estado["errores"]) + 1
		vista.marcar_mal(id)
	elif r == "avanza" and estado["hechos"].size() == ejercicio["ruta"].size():
		_terminar(int(estado["errores"]) == 0)
		return
	_refrescar()


func _al_valvula(id: String) -> void:
	if resuelto or ejercicio["tipo"] != "aislar":
		return
	var elegidas: Array = estado["elegidas"]
	if elegidas.has(id):
		elegidas.erase(id)
	else:
		elegidas.append(id)
	_refrescar()


func comprobar() -> void:
	if resuelto:
		return
	_terminar(JuegoLineas.aislar_correcto(estado["elegidas"], ejercicio["valvulas"]))


func _al_quiz(ok: bool, _indice: int) -> void:
	if resuelto:
		return
	resuelto = true
	acierto = ok
	vista.activo = false
	respondido.emit(ok)


func _terminar(ok: bool) -> void:
	resuelto = true
	acierto = ok
	_refrescar()
	respondido.emit(ok)


## Hace el ejercicio bien, para las pruebas: recorre la ruta, elige las válvulas o contesta.
func resolver_bien() -> void:
	if resuelto:
		return
	match str(ejercicio["tipo"]):
		"seguir":
			for id: String in ejercicio["ruta"]:
				vista.pulsar(vista.a_control(JuegoLineas.centro_tramo(JuegoLineas.tramo(esquema, id))))
				vista._ultimo = ""
		"aislar":
			for v: Dictionary in esquema.get("valvulas", []):
				if ejercicio["valvulas"].has(v["id"]):
					vista.pulsar(vista.a_control(Vector2(float(v["x"]), float(v["y"]))))
			comprobar()
		"servicio":
			_quiz.elegir(int(ejercicio["correcta"]))
