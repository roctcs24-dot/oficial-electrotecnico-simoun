extends Pantalla
## Ficha visual de un componente del atlas de la Escuela, en cinco pestañas: qué es, cómo
## funciona (corte animado), cómo se conecta (esquema con bornes tocables), cómo se mide (con
## valores calculados por la simulación) y fallas con su mantenimiento. Todo sale de
## data/atlas/<id>.json; el dibujo y los símbolos, de la ficha del equipo.

const PESTANAS := [
	["que_es", "Qué es", "atlas_que_es"],
	["funciona", "Funciona", "atlas_funciona"],
	["conexion", "Conexión", "atlas_conexion"],
	["medir", "Medir", "atlas_medir"],
	["fallas", "Fallas", "atlas_fallas"],
]
const SUBTITULOS := {"conexion": "Cómo se conecta: potencia y mando", "medir": "Cómo se mide", "fallas": "Fallas y mantenimiento"}
const COLOR_POR_DEFECTO := Color("f2b705")
const ALTO_DIBUJO := 300.0
const ALTO_ESQUEMA := 290.0
const ALTO_MEDIDA := 250.0
const VERDE := Color("7fd9a4")
const ROJO := Color("f19a8a")
const OSCURO := Color("10161c")

var atlas := {}
var ficha := {}
var color := COLOR_POR_DEFECTO
var pestana := "que_es"
var animacion: Animacion
var esquema: VistaBornes
var dibujo_conexion: VistaBornes
var _glosario := {}
var _vistos := {}
var _pasos: Array[RichTextLabel] = []
var _chips_pasos: Array[PanelContainer] = []
var _lista_pasos := ""
var _titulo_borne: Label
var _texto_borne: RichTextLabel
var _chips := {}


func construir() -> void:
	var id: String = args["id"]
	atlas = raiz.contenido.atlas(id)
	if atlas.is_empty():
		_cabecera("Ficha no disponible")
		add_child(_aviso("Falta data/atlas/%s.json." % id))
		for error in raiz.contenido.errores:
			add_child(_aviso(error))
		return
	ficha = raiz.contenido.ficha(str(atlas.get("ficha", id)))
	color = _color_modulo(id)
	_glosario = raiz.contenido.glosario()
	pestana = str(args.get("pestana", "que_es"))
	raiz.partida.marcar_pestana_atlas(id, pestana)
	_cabecera_atlas()
	add_child(_crear_pestanas())
	match pestana:
		"funciona":
			_construir_funciona()
		"conexion":
			_construir_conexion()
		"medir":
			_construir_medir()
		"fallas":
			_construir_fallas()
		_:
			_construir_que_es()


## Color del módulo o sistema que publica la ficha en su atlas.
func _color_modulo(id: String) -> Color:
	for s: Dictionary in raiz.contenido.todos():
		if s.get("modos", {}).get("aprender", {}).get("atlas", []).has(id):
			return Tema.color_area(s)
	return COLOR_POR_DEFECTO


func _nombre_modulo(id: String) -> String:
	for s: Dictionary in raiz.contenido.todos():
		if s.get("modos", {}).get("aprender", {}).get("atlas", []).has(id):
			return s.get("nombre", "")
	return ""


func elegir_pestana(id: String) -> void:
	args["pestana"] = id
	raiz.reconstruir()


# --- Cabecera y pestañas ---

func _cabecera_atlas() -> void:
	var barra := _tarjeta_base("Cabecera")
	add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	barra.add_child(fila)
	if raiz.nivel() > 1:
		var volver := _boton("‹ Volver", raiz.volver)
		volver.autowrap_mode = TextServer.AUTOWRAP_OFF
		volver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(volver)
	var caja_icono := PanelContainer.new()
	caja_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_icono.add_theme_stylebox_override("panel", Tema.caja(Color(color, 0.2), 12, 9, 9))
	caja_icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icono := TextureRect.new()
	icono.texture = VistaSvg.rasterizar("res://art/iconos/%s.svg" % atlas.get("icono", "ficha"), 0.45)
	icono.custom_minimum_size = Vector2(28, 28)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.modulate = color
	caja_icono.add_child(icono)
	fila.add_child(caja_icono)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	textos.add_child(_etiqueta(atlas.get("titulo", ""), "Titulo"))
	var sub := _texto_rico(_subtitulo())
	sub.add_theme_color_override("default_color", Tema.TEXTO_SUAVE)
	for clave in ["normal_font_size", "italics_font_size"]:
		sub.add_theme_font_size_override(clave, Tema.tam(16))
	textos.add_child(sub)
	if raiz.nivel() >= 3:
		var inicio := _boton("", raiz.ir_a_seccion.bind("inicio"))
		inicio.icon = VistaSvg.rasterizar("res://art/iconos/inicio.svg", 0.75)
		inicio.expand_icon = true
		inicio.tooltip_text = "Inicio"
		inicio.custom_minimum_size = Vector2(48, 48)
		inicio.add_theme_constant_override("icon_max_width", 24)
		inicio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(inicio)


func _subtitulo() -> String:
	var propio: String = atlas.get(pestana, {}).get("subtitulo", "") if atlas.get(pestana) is Dictionary else ""
	if not propio.is_empty():
		return propio
	if SUBTITULOS.has(pestana):
		return SUBTITULOS[pestana]
	var termino: Dictionary = _glosario.get(str(atlas.get("termino", "")), {})
	var modulo := _nombre_modulo(str(args["id"]))
	if termino.is_empty():
		return modulo
	return "[i]%s[/i] · %s" % [termino.get("en", ""), modulo]


func _crear_pestanas() -> Control:
	var rejilla := GridContainer.new()
	rejilla.columns = PESTANAS.size()
	rejilla.add_theme_constant_override("h_separation", 4)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for p: Array in PESTANAS:
		var b := _boton(p[1], elegir_pestana.bind(p[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.clip_text = true
		b.toggle_mode = true
		b.set_pressed_no_signal(p[0] == pestana)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 54)
		b.icon = VistaSvg.rasterizar("res://art/iconos/%s.svg" % p[2], 0.4)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 20)
		b.add_theme_constant_override("h_separation", 2)
		b.add_theme_font_size_override("font_size", Tema.tam(13))
		b.add_theme_stylebox_override("normal", Tema.caja(Tema.PANEL, Tema.RADIO, 2, 5, Tema.BORDE))
		b.add_theme_stylebox_override("hover", Tema.caja(Tema.PANEL, Tema.RADIO, 2, 5, Tema.BORDE))
		b.add_theme_stylebox_override("pressed", Tema.caja(color, Tema.RADIO, 2, 5))
		b.add_theme_stylebox_override("hover_pressed", Tema.caja(color, Tema.RADIO, 2, 5))
		for clave in ["font_color", "font_hover_color", "font_focus_color"]:
			b.add_theme_color_override(clave, Tema.TEXTO_SUAVE)
		for clave in ["font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(clave, Tema.FONDO)
		for clave in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
			b.add_theme_color_override(clave, Tema.TEXTO_SUAVE)
		for clave in ["icon_pressed_color", "icon_hover_pressed_color"]:
			b.add_theme_color_override(clave, Tema.FONDO)
		rejilla.add_child(b)
	return rejilla


# --- Disposición común ---

## En vertical, todo en una columna que se desplaza. En horizontal, el dibujo ocupa todo el alto
## de la izquierda, entero a la vista, y las tarjetas se desplazan a la derecha.
func _disponer(visual: Control, resto: Array[Control]) -> void:
	if raiz.vertical:
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(columna)
		columna.add_child(visual)
		for c in resto:
			columna.add_child(c)
		return
	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 12)
	add_child(fila)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_child(visual)
	var desplazable := _desplazable()
	fila.add_child(desplazable)
	var columna := _columna(10)
	desplazable.add_child(columna)
	for c in resto:
		columna.add_child(c)


## Alto mínimo del dibujo: en horizontal se ajusta al alto que quede libre.
func _alto(vertical: float) -> float:
	return vertical if raiz.vertical else 120.0


func _papel() -> PanelContainer:
	var p := _tarjeta_base()
	p.add_theme_stylebox_override("panel", Tema.caja(Tema.PAPEL, Tema.RADIO_TARJETA, 10, 10))
	return p


func _tarjeta(titulo := "") -> VBoxContainer:
	var t := _tarjeta_base()
	var columna := _columna(6)
	t.add_child(columna)
	if not titulo.is_empty():
		columna.add_child(_rotulo(titulo))
	return columna


func _rico(texto: String, tam := 17, tinta := false) -> RichTextLabel:
	var r := _texto_rico(TextoTecnico.expandir(texto, _glosario, _vistos))
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		r.add_theme_font_size_override(clave, Tema.tam(tam))
	if tinta:
		r.add_theme_color_override("default_color", Tema.TINTA)
	return r


func _boton_primario(texto: String, al_pulsar: Callable) -> Button:
	var b := _boton(texto, al_pulsar)
	b.custom_minimum_size.y = 52.0
	for estado in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(estado, Tema.caja(Tema.ACENTO_FUERTE.darkened(0.15 if estado.contains("pressed") else 0.0), 12, 14, 13))
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(clave, Tema.FONDO)
	b.add_theme_font_override("font", Tema.fuente(Tema.PESO_FUERTE))
	return b


## Chip para elegir un grupo: píldora gris, o del color del acento si está elegido.
func _chip(texto: String, elegido: bool, al_pulsar: Callable) -> Button:
	var b := _boton(texto, al_pulsar)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.toggle_mode = true
	b.set_pressed_no_signal(elegido)
	b.custom_minimum_size.y = 48.0
	b.add_theme_font_size_override("font_size", Tema.tam(15))
	var normal := Tema.caja(Color(Tema.TEXTO_SUAVE, 0.12), 24, 14, 12)
	var activo := Tema.caja(Color(color, 0.22), 24, 14, 12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", activo)
	b.add_theme_stylebox_override("hover_pressed", activo)
	for clave in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(clave, Tema.TEXTO_SUAVE)
	for clave in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(clave, Tema.ACENTO)
	return b


func _flujo() -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return f


func _vista_dibujo() -> VistaBornes:
	var v := VistaBornes.new()
	v.cargar(ficha.get("dibujo", {"svg": "", "tamano": [100, 100]}))
	v.poner_bornes(atlas.get("bornes_dibujo", {}))
	return v


# --- Qué es ---

func _construir_que_es() -> void:
	var datos: Dictionary = atlas.get("que_es", {})
	var papel := _papel()
	papel.custom_minimum_size.y = _alto(ALTO_DIBUJO + 20.0)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	papel.add_child(fila)
	var dibujo := _vista_dibujo()
	dibujo.custom_minimum_size = Vector2(170, _alto(ALTO_DIBUJO))
	dibujo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var partes: Array = datos.get("partes", [])
	var marcas: Array = []
	var notas := _columna(9)
	notas.alignment = BoxContainer.ALIGNMENT_CENTER
	notas.size_flags_stretch_ratio = 1.1
	for i in partes.size():
		var parte: Dictionary = partes[i]
		if parte.has("marca"):
			marcas.append([i + 1, parte["marca"][0], parte["marca"][1]])
		notas.add_child(_rico("[b]%d[/b] · %s" % [i + 1, parte["texto"]], 14, true))
	dibujo.marcas = marcas
	fila.add_child(dibujo)
	var resto: Array[Control] = []
	# En horizontal las notas no caben junto al dibujo: van en la primera tarjeta.
	if raiz.vertical:
		fila.add_child(notas)
	else:
		var tarjeta_notas := _tarjeta("Partes")
		for nota: RichTextLabel in notas.get_children():
			notas.remove_child(nota)
			nota.add_theme_color_override("default_color", Tema.TEXTO)
			for clave in ["normal_font_size", "bold_font_size", "italics_font_size"]:
				nota.add_theme_font_size_override(clave, Tema.tam(16))
			tarjeta_notas.add_child(nota)
		notas.free()
		resto.append(tarjeta_notas.get_parent())
	resto.append(_tarjeta_simbolos())
	var placa := _tarjeta("Placa y dónde está")
	var linea := _etiqueta(datos.get("placa", ""))
	placa.add_child(linea)
	placa.add_child(_etiqueta("A bordo: %s" % datos.get("a_bordo", ""), "Nota"))
	resto.append(placa.get_parent())
	if datos.has("texto"):
		var para := _tarjeta("Para qué sirve")
		para.add_child(_rico(datos["texto"]))
		resto.append(para.get_parent())
	resto.append(_boton("Leer la ficha completa", raiz.ir_a.bind("ficha", {"id": str(atlas.get("ficha", ""))})))
	_disponer(papel, resto)


func _tarjeta_simbolos() -> Control:
	var columna := _tarjeta("Símbolos")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	columna.add_child(fila)
	var simbolos: Dictionary = ficha.get("simbolos", {})
	var definiciones := {}
	if simbolos.has("lista") and not simbolos["lista"].is_empty():
		var s := raiz.contenido.simbolo(simbolos["lista"][0])
		definiciones = {"iec": s.get("iec", {}), "ansi": s.get("ansi", {})}
	else:
		definiciones = {"iec": simbolos.get("iec", {}), "ansi": simbolos.get("ansi", {})}
	for par: Array in [["iec", "IEC 60617"], ["ansi", "ANSI/IEEE 315"]]:
		var tarjeta := _papel()
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var interior := _columna(2)
		tarjeta.add_child(interior)
		var def: Dictionary = definiciones[par[0]]
		if def.has("svg"):
			var v := VistaSvg.new()
			v.color_etiquetas = Tema.TINTA
			v.cargar(def)
			v.custom_minimum_size.y = 100.0
			interior.add_child(v)
		var titulo := _etiqueta(par[1], "Fuerte")
		titulo.add_theme_color_override("font_color", Tema.TINTA)
		titulo.add_theme_font_size_override("font_size", Tema.tam(14))
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interior.add_child(titulo)
		fila.add_child(tarjeta)
	return columna.get_parent()


# --- Funciona ---

func _construir_funciona() -> void:
	var datos: Dictionary = atlas.get("funciona", {})
	var guion: GDScript = load(Animacion.CARPETA % datos.get("animacion", ""))
	animacion = guion.new()
	animacion.add_theme_constant_override("separation", 10)
	animacion.iniciar(datos.get("params", {}), raiz.contenido)
	var resto: Array[Control] = []
	# En horizontal el corte ocupa la izquierda y sus mandos pasan a la derecha.
	if not raiz.vertical:
		animacion.lienzo.custom_minimum_size.y = _alto(0.0)
		animacion.lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		for control: Control in animacion.get_children():
			if control != animacion.lienzo:
				animacion.remove_child(control)
				resto.append(control)
	var tarjeta := _tarjeta()
	for i in 3:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		tarjeta.add_child(fila)
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.custom_minimum_size = Vector2(30, 30)
		chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var cifra := _etiqueta(str(i + 1))
		cifra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cifra.add_theme_font_size_override("font_size", Tema.tam(15))
		chip.add_child(cifra)
		fila.add_child(chip)
		var texto := _rico("", 17)
		fila.add_child(texto)
		_chips_pasos.append(chip)
		_pasos.append(texto)
	resto.append(tarjeta.get_parent())
	_disponer(animacion, resto)
	_actualizar_pasos()


func _actualizar_pasos() -> void:
	if animacion == null or _pasos.is_empty():
		return
	var datos: Dictionary = atlas.get("funciona", {})
	var lista := "pasos"
	if datos.has("pasos_sin") and "tension" in animacion and not animacion.tension:
		lista = "pasos_sin"
	if lista != _lista_pasos:
		_lista_pasos = lista
		var textos: Array = datos.get(lista, [])
		var vistos := {}
		for i in _pasos.size():
			_pasos[i].text = TextoTecnico.expandir(textos[i], _glosario, vistos) if i < textos.size() else ""
	var fase := int(animacion.fase()) if animacion.has_method("fase") else 3
	for i in _chips_pasos.size():
		var activo := i < fase
		_chips_pasos[i].add_theme_stylebox_override("panel", Tema.caja(Color(color, 0.25) if activo else Color(Tema.TEXTO_SUAVE, 0.1), 15, 0, 2))
		(_chips_pasos[i].get_child(0) as Label).add_theme_color_override("font_color", Tema.ACENTO if activo else Tema.APAGADO)
		_pasos[i].modulate.a = 1.0 if activo else 0.55


func _process(_delta: float) -> void:
	if animacion != null:
		_actualizar_pasos()


# --- Conexión ---

func _construir_conexion() -> void:
	var datos: Dictionary = atlas.get("conexion", {})
	var papel := _papel()
	esquema = VistaBornes.new()
	esquema.color_etiquetas = Tema.TINTA
	esquema.cargar(datos.get("esquema", {"svg": "", "tamano": [400, 290]}))
	esquema.poner_bornes(datos.get("bornes_esquema", {}))
	esquema.custom_minimum_size.y = _alto(ALTO_ESQUEMA)
	esquema.borne_tocado.connect(tocar_borne)
	papel.add_child(esquema)
	var resto: Array[Control] = []
	var tarjeta := _tarjeta_base()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	tarjeta.add_child(fila)
	var marco := _papel()
	marco.add_theme_stylebox_override("panel", Tema.caja(Tema.PAPEL, Tema.RADIO, 4, 4))
	dibujo_conexion = _vista_dibujo()
	dibujo_conexion.custom_minimum_size = Vector2(110, 160)
	dibujo_conexion.borne_tocado.connect(tocar_borne)
	marco.add_child(dibujo_conexion)
	fila.add_child(marco)
	var textos := _columna(4)
	fila.add_child(textos)
	_titulo_borne = _etiqueta("", "Fuerte")
	textos.add_child(_titulo_borne)
	_texto_borne = _rico("", 16)
	textos.add_child(_texto_borne)
	textos.add_child(_etiqueta("Toque un borne en el esquema o en el dibujo: se ilumina en los dos.", "Nota"))
	resto.append(tarjeta)
	var chips := _flujo()
	var grupos: Array = datos.get("grupos", [])
	for i in grupos.size():
		var c := _chip(grupos[i]["nombre"], false, elegir_grupo.bind(i))
		chips.add_child(c)
		_chips[i] = c
	resto.append(chips)
	if datos.has("taller"):
		resto.append(_boton_primario("Montarlo en el Taller", raiz.ir_a.bind("taller", {"plantilla": datos["taller"]})))
	_disponer(papel, resto)
	if args.has("borne"):
		tocar_borne(str(args["borne"]))
	else:
		elegir_grupo(int(args.get("grupo", 0)))


## Ilumina un grupo de bornes en el esquema y en el dibujo, con su explicación.
func elegir_grupo(indice: int) -> void:
	var grupos: Array = atlas.get("conexion", {}).get("grupos", [])
	if indice < 0 or indice >= grupos.size():
		return
	args["grupo"] = indice
	args.erase("borne")
	var g: Dictionary = grupos[indice]
	esquema.resaltar(g["bornes"])
	dibujo_conexion.resaltar(g["bornes"])
	_titulo_borne.text = "Bornes %s" % g["nombre"]
	_texto_borne.text = TextoTecnico.expandir(g.get("texto", ""), _glosario, {})
	_marcar_chip(indice)


## Ilumina un borne en los dos dibujos y dice qué le llega.
func tocar_borne(id: String) -> void:
	var textos: Dictionary = atlas.get("conexion", {}).get("bornes", {})
	args["borne"] = id
	esquema.resaltar([id])
	dibujo_conexion.resaltar([id])
	_titulo_borne.text = "Borne tocado: %s" % id
	_texto_borne.text = TextoTecnico.expandir(textos.get(id, ""), _glosario, {})
	var grupos: Array = atlas.get("conexion", {}).get("grupos", [])
	var del_grupo := -1
	for i in grupos.size():
		if grupos[i]["bornes"].has(id):
			del_grupo = i
			break
	_marcar_chip(del_grupo)


func _marcar_chip(indice: int) -> void:
	for i: int in _chips:
		_chips[i].set_pressed_no_signal(i == indice)


# --- Medir ---

func _construir_medir() -> void:
	var datos: Dictionary = atlas.get("medir", {})
	var grupos: Array = datos.get("grupos", [])
	var indice := clampi(int(args.get("grupo_medir", 0)), 0, maxi(grupos.size() - 1, 0))
	var chips := _flujo()
	for i in grupos.size():
		chips.add_child(_chip(grupos[i]["nombre"], i == indice, elegir_grupo_medir.bind(i)))
	add_child(chips)
	if grupos.is_empty():
		return
	var g: Dictionary = grupos[indice]
	var filas := filas_medir(indice)
	var papel := _papel()
	var columna := _columna(4)
	papel.add_child(columna)
	var vista := VistaMedida.new()
	vista.custom_minimum_size.y = _alto(ALTO_MEDIDA)
	vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(vista)
	vista.configurar(ficha.get("dibujo", {"svg": "", "tamano": [100, 100]}), atlas.get("bornes_dibujo", {}), str(g.get("instrumento", "multimetro")),
		str(g.get("roja", "")), str(g.get("negra", "")), filas[0]["lectura"] if not filas.is_empty() else "", str(g.get("escala", "")))
	var como := _etiqueta(g.get("como", ""), "Fuerte")
	como.add_theme_color_override("font_color", Tema.TINTA)
	como.add_theme_font_size_override("font_size", Tema.tam(15))
	columna.add_child(como)
	var nota := _etiqueta(g.get("nota", ""))
	nota.add_theme_color_override("font_color", Color("3b444b"))
	nota.add_theme_font_size_override("font_size", Tema.tam(14))
	columna.add_child(nota)
	var tabla := _tarjeta(g.get("titulo_tabla", "Qué debe marcar"))
	tabla.add_child(_fila_tabla(["Estado", g.get("columna", "Lectura"), "Qué hacer"], true, true))
	for f: Dictionary in filas:
		tabla.add_child(_separador())
		tabla.add_child(_fila_tabla([f["estado"], f["lectura"], f["hacer"]], false, f["bien"]))
	tabla.add_child(_etiqueta(datos.get("nota", ""), "Nota"))
	var resto: Array[Control] = [tabla.get_parent()]
	if datos.has("taller"):
		resto.append(_boton_primario("Medirlo yo en el Taller", raiz.ir_a.bind("taller", {"plantilla": datos["taller"], "pestana_inicial": "medir"})))
	_disponer(papel, resto)


func elegir_grupo_medir(indice: int) -> void:
	args["grupo_medir"] = indice
	raiz.reconstruir()


## Filas de la tabla de un grupo con la lectura calculada por la simulación:
## [{estado, lectura, hacer, bien}].
func filas_medir(indice: int) -> Array[Dictionary]:
	var g: Dictionary = atlas.get("medir", {}).get("grupos", [])[indice]
	var lista: Array[Dictionary] = []
	for f: Dictionary in g.get("filas", []):
		var medida := AtlasMedidas.combinar(g.get("medida", {}), f.get("cambios", {}))
		var r := AtlasMedidas.medir(raiz.contenido, medida)
		lista.append({"estado": f.get("estado", ""), "lectura": r["texto"], "hacer": f.get("hacer", ""), "bien": f.get("bien", true)})
	return lista


func _fila_tabla(celdas: Array, cabecera: bool, bien: bool) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var proporciones := [1.25, 0.8, 1.25]
	for i in 3:
		var e := _etiqueta(str(celdas[i]), "Rotulo" if cabecera else "")
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.size_flags_stretch_ratio = proporciones[i]
		if not cabecera:
			e.add_theme_font_size_override("font_size", Tema.tam(15))
			if i == 1:
				e.add_theme_color_override("font_color", VERDE if bien else ROJO)
				e.add_theme_font_override("font", Tema.fuente(Tema.PESO_FUERTE))
		fila.add_child(e)
	return fila


func _separador() -> Control:
	var linea := ColorRect.new()
	linea.color = Tema.BORDE
	linea.custom_minimum_size.y = 1.0
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return linea


# --- Fallas ---

func _construir_fallas() -> void:
	var datos: Dictionary = atlas.get("fallas", {})
	var lista: Array = datos.get("lista", [])
	var indice := clampi(int(args.get("falla", 0)), 0, maxi(lista.size() - 1, 0))
	var rejilla := GridContainer.new()
	rejilla.columns = 2 if raiz.vertical else 4
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in lista.size():
		var b := _boton(lista[i]["nombre"], elegir_falla.bind(i))
		b.toggle_mode = true
		b.set_pressed_no_signal(i == indice)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", Tema.tam(15))
		b.add_theme_stylebox_override("pressed", Tema.caja(color, 12, 10, 13))
		b.add_theme_stylebox_override("hover_pressed", Tema.caja(color, 12, 10, 13))
		b.add_theme_stylebox_override("normal", Tema.caja(Tema.BOTON, 12, 10, 13, Tema.BORDE))
		b.add_theme_stylebox_override("hover", Tema.caja(Tema.BOTON, 12, 10, 13, Tema.BORDE))
		for clave in ["font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(clave, Tema.FONDO)
		rejilla.add_child(b)
	add_child(rejilla)
	var desplazable := _desplazable()
	add_child(desplazable)
	var contenedor: BoxContainer = _columna(10) if raiz.vertical else HBoxContainer.new()
	contenedor.add_theme_constant_override("separation", 10)
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazable.add_child(contenedor)
	if not lista.is_empty():
		var falla := _tarjeta_falla(lista[indice])
		falla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		falla.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		contenedor.add_child(falla)
	var derecha := _columna(10)
	derecha.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	contenedor.add_child(derecha)
	derecha.add_child(_tarjeta_mantenimiento(datos))
	var referencias: Array = atlas.get("para_saber_mas", [])
	if not referencias.is_empty():
		var saber := _tarjeta("Para saber más")
		for r: String in referencias:
			saber.add_child(_etiqueta("• %s" % r, "Nota"))
		derecha.add_child(saber.get_parent())


func elegir_falla(indice: int) -> void:
	args["falla"] = indice
	raiz.reconstruir()


func _tarjeta_falla(f: Dictionary) -> Control:
	var columna := _tarjeta()
	columna.add_theme_constant_override("separation", 4)
	columna.add_child(_rotulo("Síntoma"))
	columna.add_child(_rico(f.get("sintoma", "")))
	columna.add_child(_rotulo("Se mide"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	columna.add_child(fila)
	for lectura: Dictionary in lecturas_falla(f):
		var caja := PanelContainer.new()
		caja.mouse_filter = Control.MOUSE_FILTER_PASS
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.add_theme_stylebox_override("panel", Tema.caja(OSCURO, Tema.RADIO, 8, 8))
		var interior := _columna(0)
		caja.add_child(interior)
		var valor := _etiqueta(lectura["texto"])
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		valor.add_theme_font_size_override("font_size", Tema.tam(21))
		valor.add_theme_font_override("font", Tema.fuente(Tema.PESO_NEGRITA))
		valor.add_theme_color_override("font_color", VERDE if lectura["bien"] else ROJO)
		interior.add_child(valor)
		var donde := _etiqueta(lectura["donde"], "Nota")
		donde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		donde.add_theme_font_size_override("font_size", Tema.tam(13))
		interior.add_child(donde)
		fila.add_child(caja)
	columna.add_child(_rotulo("Causa"))
	columna.add_child(_rico(f.get("causa", "")))
	columna.add_child(_rotulo("Reparación"))
	columna.add_child(_rico(f.get("reparacion", "")))
	return columna.get_parent()


## Lecturas de una falla: {texto, donde, bien}; con la simulación salvo las escritas a mano.
func lecturas_falla(f: Dictionary) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for m: Dictionary in f.get("mide", []):
		var texto := str(m["valor"]) if m.has("valor") else str(AtlasMedidas.medir(raiz.contenido, m.get("medida", {}))["texto"])
		lista.append({"texto": texto, "donde": m.get("donde", ""), "bien": m.get("bien", false)})
	return lista


func _tarjeta_mantenimiento(datos: Dictionary) -> Control:
	var columna := _tarjeta("Mantenimiento preventivo")
	var tareas: Array = datos.get("mantenimiento", [])
	var id: String = args["id"]
	for i in tareas.size():
		var t: Dictionary = tareas[i]
		var casilla := Casilla.new()
		casilla.text = "%s: %s" % [t.get("periodo", ""), t.get("tarea", "")]
		casilla.set_pressed_no_signal(raiz.partida.tarea_atlas_hecha(id, i))
		casilla.toggled.connect(func(hecha: bool) -> void: raiz.partida.marcar_tarea_atlas(id, i, hecha))
		columna.add_child(casilla)
	columna.add_child(_etiqueta(datos.get("nota_mantenimiento", ""), "Nota"))
	return columna.get_parent()


## Tarea de mantenimiento para marcar: casilla dibujada a la izquierda, verde si está hecha.
class Casilla extends Button:
	const LADO := 24.0

	func _init() -> void:
		toggle_mode = true
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mouse_filter = Control.MOUSE_FILTER_PASS
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size.y = 48.0
		for estilo in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			var caja := StyleBoxEmpty.new()
			caja.content_margin_left = LADO + 14.0
			caja.content_margin_top = 8.0
			caja.content_margin_bottom = 8.0
			add_theme_stylebox_override(estilo, caja)
		for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			add_theme_color_override(clave, Tema.TEXTO)
		add_theme_font_size_override("font_size", Tema.tam(16))
		toggled.connect(func(_hecha: bool) -> void: queue_redraw())

	func _draw() -> void:
		var r := Rect2(Vector2(2.0, (size.y - LADO) / 2.0), Vector2(LADO, LADO))
		if button_pressed:
			draw_style_box(Tema.caja(Tema.HECHO, 5, 0, 0), r)
			var c := r.get_center()
			var p := PackedVector2Array([c + Vector2(-6, 0), c + Vector2(-2, 5), c + Vector2(7, -6)])
			draw_polyline(p, Tema.FONDO, 3.0, true)
		else:
			var borde := Tema.caja(Color.TRANSPARENT, 5, 0, 0, Tema.APAGADO)
			borde.set_border_width_all(2)
			draw_style_box(borde, r)
