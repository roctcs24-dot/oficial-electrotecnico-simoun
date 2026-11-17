extends Pantalla
## Ficha de un equipo: el dibujo grande en un visor, con marcas numeradas que explican cada
## parte en un bocadillo, y los textos de la ficha repartidos en pestañas con iconos: Partes,
## Funciona, Conexión, Prueba (con el banco de prueba de la simulación) y Fallas.

const PESTANAS := [
	["partes", "Partes", "atlas_que_es"],
	["funciona", "Funciona", "atlas_funciona"],
	["conexion", "Conexión", "atlas_conexion"],
	["prueba", "Prueba", "atlas_medir"],
	["fallas", "Fallas", "atlas_fallas"],
]
const ALTO_VISOR_VERTICAL := 470.0

var pestana := "partes"
## Número de la parte elegida en el dibujo, o 0.
var parte := 0
var partes: Array = []
var color := Tema.ACENTO
var paginas := {}
var filas: Array[FilaParte] = []
var tira: Control
var _ficha := {}
var _vista := "real"
var _visual: Control
var _nota: Label
var _botones_vista := {}
var _sim: SimSimulacion
var _dibujo: VistaEquipo
var _luz: LuzPiloto
var _lectura: Label
var _acumulado := 0.0
var _glosario := {}
var _vistos := {}


func construir() -> void:
	var id: String = args["id"]
	_ficha = raiz.contenido.ficha(id)
	if _ficha.is_empty():
		_cabecera("Ficha no disponible")
		for error in raiz.contenido.errores:
			add_child(_aviso(error))
		return
	raiz.partida.marcar_ficha_vista(id)
	_glosario = raiz.contenido.glosario()
	_vista = str(args.get("vista", "real"))
	partes = raiz.contenido.partes_ficha(id)
	parte = clampi(int(args.get("parte", 1 if not partes.is_empty() else 0)), 0, partes.size())
	pestana = str(args.get("pestana", "partes"))
	if not PESTANAS.any(func(p: Array) -> bool: return p[0] == pestana):
		pestana = "partes"
	var del_area := _area(id)
	color = Tema.color_area(del_area) if not del_area.is_empty() else Tema.ACENTO
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, _ficha["titulo"], _ficha.get("resumen", ""), color, _icono(id, del_area))
	add_child(cabecera)

	var visor := _crear_visor()
	tira = PestanaIcono.tira(PESTANAS, pestana, [], elegir_pestana)
	var hojas := _columna(10)
	for p: Array in PESTANAS:
		var hoja := _columna(10)
		hoja.name = "Hoja_%s" % p[0]
		hojas.add_child(hoja)
		paginas[p[0]] = hoja
	_llenar_hojas()
	var botones := _crear_botones()
	if raiz.vertical:
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(columna)
		visor.custom_minimum_size.y = ALTO_VISOR_VERTICAL
		columna.add_child(visor)
		columna.add_child(tira)
		columna.add_child(hojas)
		if botones != null:
			columna.add_child(botones)
	else:
		# En apaisado el visor ocupa todo el alto de la izquierda y las pestañas van a la derecha.
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 12)
		add_child(fila)
		visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		visor.size_flags_stretch_ratio = 0.92
		fila.add_child(visor)
		var derecha := _columna(8)
		derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_child(derecha)
		derecha.add_child(tira)
		var desplazable := _desplazable()
		derecha.add_child(desplazable)
		desplazable.add_child(hojas)
		if botones != null:
			derecha.add_child(botones)
	elegir_pestana(pestana)
	_mostrar_vista(_vista)


## Sistema del buque o módulo de la Escuela que publica la ficha, para su color y su icono.
func _area(id: String) -> Dictionary:
	for s: Dictionary in raiz.contenido.todos():
		if s.get("modos", {}).get("aprender", {}).get("fichas", []).has(id):
			return s
	var id_atlas := raiz.contenido.atlas_de_ficha(id)
	for s: Dictionary in raiz.contenido.todos():
		if not id_atlas.is_empty() and s.get("modos", {}).get("aprender", {}).get("atlas", []).has(id_atlas):
			return s
	return {}


func _icono(id: String, del_area: Dictionary) -> String:
	var id_atlas := raiz.contenido.atlas_de_ficha(id)
	if not id_atlas.is_empty():
		return str(raiz.contenido.atlas(id_atlas).get("icono", "ficha"))
	if del_area.has("id"):
		return str(del_area.get("icono", "sistema_%d" % int(del_area["id"])))
	return "ficha"


# --- Visor ---

func _crear_visor() -> VisorFicha:
	var visor := VisorFicha.new(10.0)
	visor.name = "Visor"
	var columna := _columna(6)
	visor.add_child(columna)
	var selector := HBoxContainer.new()
	selector.add_theme_constant_override("separation", 4)
	columna.add_child(selector)
	_agregar_vista(selector, "Equipo", "real", "ficha")
	_agregar_vista(selector, "Símbolos", "simbolos", "simbolos")
	var extras: Array = _ficha.get("dibujos_extra", [])
	for i in extras.size():
		_agregar_vista(selector, extras[i]["titulo"], "extra_%d" % i, "ficha")
	_visual = Control.new()
	_visual.name = "Dibujo"
	_visual.mouse_filter = Control.MOUSE_FILTER_PASS
	_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual.custom_minimum_size.y = 200.0
	columna.add_child(_visual)
	# La nota del dibujo va en la hoja Partes (_llenar_hojas): en el visor, el dibujo manda.
	_nota = _etiqueta("", "Nota")
	_nota.name = "NotaDibujo"
	_nota.add_theme_font_size_override("font_size", Tema.tam(13))
	return visor


func _agregar_vista(selector: HBoxContainer, titulo: String, vista: String, icono: String) -> void:
	var b := BotonAri.new(titulo, _mostrar_vista.bind(vista), "oscuro", icono)
	b.add_theme_font_size_override("font_size", Tema.tam(12))
	b.ajustar_ancho()
	selector.add_child(b)
	_botones_vista[vista] = b


func _mostrar_vista(vista: String) -> void:
	if vista != "real" and vista != "simbolos" and not vista.begins_with("extra_"):
		vista = "real"
	_vista = vista
	args["vista"] = vista
	for clave: String in _botones_vista:
		(_botones_vista[clave] as BotonAri).estilo = "ambar" if clave == vista else "oscuro"
	for hijo in _visual.get_children():
		_visual.remove_child(hijo)
		hijo.queue_free()
	_dibujo = null
	if vista == "real":
		_mostrar_dibujo(_ficha["dibujo"], true)
	elif vista == "simbolos":
		_mostrar_simbolos()
	else:
		_mostrar_dibujo(_ficha["dibujos_extra"][vista.trim_prefix("extra_").to_int()], false)


func _mostrar_dibujo(definicion: Dictionary, con_marcas: bool) -> void:
	if con_marcas and not partes.is_empty():
		var d := DibujoMarcas.new()
		d.cargar(definicion)
		d.poner_partes(partes, _glosario, parte)
		d.lado_bocadillo = "abajo" if raiz.vertical else "derecha"
		d.marca_tocada.connect(elegir_parte)
		_dibujo = d
	else:
		_dibujo = VistaEquipo.new()
		_dibujo.sombra_dibujo = true
		_dibujo.cargar(definicion)
	_dibujo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visual.add_child(_dibujo)
	_nota.text = definicion.get("nota", "")
	_nota.visible = not _nota.text.is_empty()
	_actualizar_banco()


func _mostrar_simbolos() -> void:
	var simbolos: Dictionary = _ficha["simbolos"]
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 8)
	rejilla.add_theme_constant_override("v_separation", 8)
	rejilla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visual.add_child(rejilla)
	if simbolos.has("lista"):
		for id: String in simbolos["lista"]:
			var datos := raiz.contenido.simbolo(id)
			rejilla.add_child(_tarjeta_simbolo(datos["iec"], "IEC 60617"))
			rejilla.add_child(_tarjeta_simbolo(datos["ansi"], "ANSI/IEEE 315 (NEMA)"))
	else:
		rejilla.add_child(_tarjeta_simbolo(simbolos["iec"], simbolos["iec"].get("titulo", "IEC 60617")))
		rejilla.add_child(_tarjeta_simbolo(simbolos["ansi"], simbolos["ansi"].get("titulo", "ANSI/IEEE 315")))
	_nota.text = simbolos.get("nota", "")
	_nota.visible = not _nota.text.is_empty()


func _tarjeta_simbolo(definicion: Dictionary, titulo: String) -> Control:
	var tarjeta := PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_PASS
	tarjeta.add_theme_stylebox_override("panel", Relieve.estilo_papel(6.0))
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var columna := _columna(2)
	tarjeta.add_child(columna)
	var dibujo := VistaSvg.new()
	dibujo.color_etiquetas = Tema.TINTA
	dibujo.cargar(definicion)
	dibujo.custom_minimum_size.y = 90.0
	dibujo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(dibujo)
	var nombre := _etiqueta(titulo, "Fuerte")
	nombre.add_theme_color_override("font_color", Tema.TINTA)
	nombre.add_theme_font_size_override("font_size", Tema.tam(13))
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(nombre)
	return tarjeta


# --- Partes y pestañas ---

func elegir_parte(numero: int) -> void:
	parte = clampi(numero, 0, partes.size())
	args["parte"] = parte
	if _vista != "real":
		_mostrar_vista("real")
	elif _dibujo is DibujoMarcas:
		(_dibujo as DibujoMarcas).elegir(parte)
	for f in filas:
		f.poner(f.numero == parte)


func elegir_pestana(clave: String) -> void:
	pestana = clave
	args["pestana"] = clave
	for p in PestanaIcono.de_tira(tira):
		p.poner(p.clave == clave)
	for k: String in paginas:
		paginas[k].visible = k == clave


## Pestaña de cada sección de la ficha según su título.
static func pestana_de_seccion(titulo: String) -> String:
	var t := titulo.to_lower()
	if t.contains("para qué"):
		return "partes"
	if t.contains("funciona"):
		return "funciona"
	if t.contains("prueba"):
		return "prueba"
	if t.contains("falla") or t.contains("manten"):
		return "fallas"
	return "conexion"


func _llenar_hojas() -> void:
	if not partes.is_empty():
		var placa := _placa()
		var columna := _columna(2)
		placa.add_child(columna)
		columna.add_child(_rotulo("Partes · %d marcas en el dibujo" % partes.size()))
		for i in partes.size():
			var p: Dictionary = partes[i]
			var texto := TextoTecnico.expandir(str(p.get("texto", "")), _glosario, _vistos)
			if not str(p.get("nombre", "")).is_empty():
				texto = "[b]%s[/b]: %s" % [p["nombre"], texto]
			var f := FilaParte.new(i + 1, texto)
			f.poner(i + 1 == parte)
			f.tocada.connect(elegir_parte)
			columna.add_child(f)
			filas.append(f)
		paginas["partes"].add_child(placa)
	for seccion: Dictionary in _ficha.get("secciones", []):
		var clave := pestana_de_seccion(str(seccion["titulo"]))
		paginas[clave].add_child(_seccion(seccion["titulo"], TextoTecnico.expandir(seccion["texto"], _glosario, _vistos)))
		if clave == "prueba" and _ficha.has("banco") and _sim == null:
			paginas["prueba"].add_child(_crear_banco())
	paginas["partes"].add_child(_nota)
	var referencias: Array = _ficha.get("para_saber_mas", [])
	if not referencias.is_empty():
		var lineas := PackedStringArray()
		for r: String in referencias:
			lineas.append("• %s" % r)
		paginas["fallas"].add_child(_seccion("Para saber más", "\n".join(lineas)))


func _placa() -> PanelContainer:
	var placa := PanelContainer.new()
	placa.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_theme_stylebox_override("panel", Relieve.estilo_placa(12.0, 10.0))
	return placa


func _seccion(titulo: String, texto: String) -> Control:
	var placa := _placa()
	var interior := _columna(6)
	placa.add_child(interior)
	interior.add_child(_rotulo(titulo))
	interior.add_child(_texto_rico(texto))
	return placa


func _crear_botones() -> Control:
	var hay_atlas := not raiz.contenido.atlas_de_ficha(str(args["id"])).is_empty()
	if not _ficha.has("banco") and not hay_atlas:
		return null
	var fila := HBoxContainer.new()
	fila.name = "Botones"
	fila.add_theme_constant_override("separation", 10)
	if _ficha.has("banco"):
		var banco := BotonAri.new("Banco de prueba", elegir_pestana.bind("prueba"), "oscuro", "atlas_medir")
		banco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banco.custom_minimum_size.y = 50.0
		fila.add_child(banco)
	if hay_atlas:
		# El acceso a la ficha visual del atlas de la Escuela, con sus cinco vistas.
		var atlas := BotonAri.new("Ver en el atlas", raiz.ir_a.bind("atlas", {"id": raiz.contenido.atlas_de_ficha(str(args["id"]))}), "ambar", "escuela")
		atlas.name = "VerAtlas"
		atlas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		atlas.size_flags_stretch_ratio = 1.2
		atlas.custom_minimum_size.y = 50.0
		fila.add_child(atlas)
	return fila


# --- Banco de prueba ---

func _crear_banco() -> Control:
	var banco: Dictionary = _ficha["banco"]
	_sim = raiz.contenido.circuito(banco["circuito"])
	var placa := _placa()
	var columna := _columna(8)
	placa.add_child(columna)
	columna.add_child(_rotulo("Banco de prueba"))
	columna.add_child(_etiqueta(banco.get("explicacion", ""), "Nota"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	columna.add_child(fila)
	var pulsador := BotonAri.new("Mantener pulsado %s" % banco["pulsador"], Callable(), "azul")
	pulsador.name = "Pulsador"
	pulsador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pulsador.custom_minimum_size.y = 52.0
	# Se mantiene pulsado: el filtro por defecto evita que un movimiento del dedo arrastre la lista.
	pulsador.mouse_filter = Control.MOUSE_FILTER_STOP
	pulsador.set_meta("se_mantiene", true)
	pulsador.button_down.connect(pulsar_banco.bind(true))
	pulsador.button_up.connect(pulsar_banco.bind(false))
	fila.add_child(pulsador)
	_luz = LuzPiloto.new()
	fila.add_child(_luz)
	_lectura = _etiqueta("")
	columna.add_child(_lectura)
	if _sim != null:
		_sim.paso()
		_actualizar_banco()
	return placa


func pulsar_banco(presionado: bool) -> void:
	if _sim == null:
		return
	_sim.componente(_ficha["banco"]["pulsador"]).estado["presionado"] = presionado
	_sim.paso()
	_actualizar_banco()


func _process(delta: float) -> void:
	if _sim == null:
		return
	_acumulado += delta
	if _acumulado >= SimSimulacion.PASO_S:
		_acumulado = 0.0
		_sim.paso()
		_actualizar_banco()


func _actualizar_banco() -> void:
	if _sim == null or _lectura == null:
		return
	var banco: Dictionary = _ficha["banco"]
	var k: SimContactor = _sim.componente(banco["contactor"])
	var cerrado := k.cerrado()
	_luz.encendida = _sim.componente(banco["lampara"]).estado["encendida"]
	if _dibujo != null and is_instance_valid(_dibujo):
		_dibujo.poner_cerrado(cerrado)
	_lectura.text = "Bobina A1-A2: %d V\nPolos 1-2, 3-4, 5-6 y auxiliar 13-14: %s\nAuxiliar 21-22: %s" % [
		roundi(k.tension(_sim.solucion, "A1", "A2")),
		"cerrados" if cerrado else "abiertos",
		"abierto" if cerrado else "cerrado",
	]
