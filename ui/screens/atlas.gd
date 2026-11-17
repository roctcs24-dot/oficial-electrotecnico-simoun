extends Pantalla
## Ficha visual de un componente del atlas de la Escuela, en cinco pestañas con iconos: qué es
## (el dibujo grande con marcas numeradas), cómo funciona (corte animado), cómo se conecta
## (esquema con bornes tocables), cómo se mide (con valores calculados por la simulación) y
## fallas con su mantenimiento. Lo visual va en un visor hundido con luz de foco. Todo sale de
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
## Parte elegida en el dibujo de «Qué es», o 0.
var parte := 0
var dibujo_partes: DibujoMarcas
var filas: Array[FilaParte] = []
var tira: Control
var _fase_pasos := -1
var animacion: Animacion
var esquema: VistaBornes
var dibujo_conexion: VistaBornes
var _glosario := {}
var _vistos := {}
var _pasos: Array[RichTextLabel] = []
var _chips_pasos: Array[FilaParte] = []
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
	tira = _crear_pestanas()
	add_child(tira)
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
	var id: String = args["id"]
	var vistas := raiz.partida.pestanas_atlas_vistas(id).size()
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, atlas.get("titulo", ""), _subtitulo(), color, str(atlas.get("icono", "ficha")),
		float(vistas) / PESTANAS.size(), CabeceraFicha.LamparasVistas.new(vistas, PESTANAS.size()))
	add_child(cabecera)


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
	return PestanaIcono.tira(PESTANAS, pestana, raiz.partida.pestanas_atlas_vistas(str(args["id"])), elegir_pestana)


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


## Hoja de papel dentro del visor, para los esquemas, los cortes y las medidas en tinta.
func _papel() -> PanelContainer:
	var p := _tarjeta_base()
	p.add_theme_stylebox_override("panel", Relieve.estilo_papel(8.0))
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return p


## Visor hundido con luz de foco; con «contenido», ya puesto dentro.
func _visor(contenido: Control = null) -> VisorFicha:
	var v := VisorFicha.new(12.0)
	v.name = "Visor"
	if contenido != null:
		v.add_child(contenido)
	return v


func _placa() -> PanelContainer:
	var p := _tarjeta_base()
	p.add_theme_stylebox_override("panel", Relieve.estilo_placa(12.0, 10.0))
	return p


func _tarjeta(titulo := "") -> VBoxContainer:
	var t := _placa()
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


func _boton_primario(texto: String, al_pulsar: Callable, icono := "taller") -> Button:
	var b := BotonAri.new(texto, al_pulsar, "ambar", icono)
	b.custom_minimum_size.y = 52.0
	b.add_theme_font_size_override("font_size", Tema.tam(15))
	return b


## Tecla para elegir un grupo: gris oscura con relieve, o ámbar encendida si está elegida.
func _chip(texto: String, elegido: bool, al_pulsar: Callable) -> Button:
	var b := BotonAri.new(texto, al_pulsar, "ambar" if elegido else "oscuro")
	b.toggle_mode = true
	b.set_pressed_no_signal(elegido)
	b.custom_minimum_size.y = 48.0
	b.add_theme_font_size_override("font_size", Tema.tam(14))
	b.ajustar_ancho()
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
	var partes := Contenido.partes_atlas(atlas)
	parte = clampi(int(args.get("parte", 1 if not partes.is_empty() else 0)), 0, partes.size())
	dibujo_partes = DibujoMarcas.new()
	dibujo_partes.cargar(ficha.get("dibujo", {"svg": "", "tamano": [100, 100]}))
	dibujo_partes.poner_bornes(atlas.get("bornes_dibujo", {}))
	dibujo_partes.poner_partes(partes, _glosario, parte)
	dibujo_partes.lado_bocadillo = "abajo" if raiz.vertical else "derecha"
	dibujo_partes.custom_minimum_size = Vector2(170, _alto(ALTO_DIBUJO + 60.0))
	dibujo_partes.marca_tocada.connect(elegir_parte)
	var visor := _visor(dibujo_partes)
	var resto: Array[Control] = []
	var lista: Array = datos.get("partes", [])
	if not lista.is_empty():
		var tarjeta := _tarjeta("Partes")
		tarjeta.add_theme_constant_override("separation", 2)
		# Los números siguen a las marcas: una parte sin marca no lleva número en el dibujo.
		var numero := 0
		for p: Dictionary in lista:
			if not p.has("marca"):
				tarjeta.add_child(_rico("• " + str(p["texto"]), 15))
				continue
			numero += 1
			var f := FilaParte.new(numero, TextoTecnico.expandir(p["texto"], _glosario, _vistos), 15)
			f.poner(numero == parte)
			f.tocada.connect(elegir_parte)
			tarjeta.add_child(f)
			filas.append(f)
		resto.append(tarjeta.get_parent())
	resto.append(_tarjeta_simbolos())
	var placa := _tarjeta("Placa y dónde está")
	placa.add_child(_placa_datos(str(datos.get("placa", ""))))
	placa.add_child(_etiqueta("A bordo: %s" % datos.get("a_bordo", ""), "Nota"))
	resto.append(placa.get_parent())
	if datos.has("texto"):
		var para := _tarjeta("Para qué sirve")
		para.add_child(_rico(datos["texto"]))
		resto.append(para.get_parent())
	var leer := BotonAri.new("Leer la ficha completa", raiz.ir_a.bind("ficha", {"id": str(atlas.get("ficha", ""))}), "oscuro", "ficha")
	leer.custom_minimum_size.y = 50.0
	resto.append(leer)
	_disponer(visor, resto)


## Elige una parte: se enciende su marca en el dibujo y su fila en la lista.
func elegir_parte(numero: int) -> void:
	parte = numero
	args["parte"] = numero
	if dibujo_partes != null:
		dibujo_partes.elegir(numero)
	for f in filas:
		f.poner(f.numero == numero)


## Placa de datos como una chapa de aluminio remachada, con el texto grabado.
func _placa_datos(texto: String) -> Control:
	var chapa := PanelContainer.new()
	chapa.name = "PlacaDatos"
	chapa.mouse_filter = Control.MOUSE_FILTER_PASS
	var e := EstiloAri.crear([Color("e8ecef"), Color("c9d0d6"), Color("dfe4e8"), Color("aab3bb")], 18.0, 8.0, 6.0)
	e.borde = Color("4b545c")
	e.luz = Color(1, 1, 1, 0.85)
	e.sombra = 0.55
	e.hueco = Vector2(1, 1)
	chapa.add_theme_stylebox_override("panel", e)
	chapa.draw.connect(func() -> void:
		for p: Vector2 in [Vector2(9, 9), Vector2(chapa.size.x - 9.0, 9), Vector2(9, chapa.size.y - 9.0), chapa.size - Vector2(9, 9)]:
			chapa.draw_circle(p + Vector2(0, 0.8), 3.2, Color(0, 0, 0, 0.45))
			PiezasAri._disco(chapa, p, 2.8, Color("ffffff"), Color("6d7780")))
	var columna := _columna(0)
	chapa.add_child(columna)
	var rotulo := _etiqueta("PLACA DE DATOS")
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", Tema.tam(10))
	rotulo.add_theme_color_override("font_color", Color("4b545c"))
	rotulo.add_theme_font_override("font", Tema.fuente(Tema.PESO_NEGRITA))
	columna.add_child(rotulo)
	var linea := _etiqueta(texto)
	linea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linea.add_theme_font_size_override("font_size", Tema.tam(16))
	linea.add_theme_color_override("font_color", Color("20262c"))
	linea.add_theme_font_override("font", Tema.fuente(Tema.PESO_NEGRITA))
	columna.add_child(linea)
	return chapa


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
		tarjeta.size_flags_vertical = Control.SIZE_FILL
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
	var tarjeta := _tarjeta("Paso a paso")
	tarjeta.add_theme_constant_override("separation", 2)
	for i in 3:
		var fila := FilaParte.new(i + 1, "", 16)
		tarjeta.add_child(fila)
		_chips_pasos.append(fila)
		_pasos.append(fila.texto)
	resto.append(tarjeta.get_parent())
	animacion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_disponer(_visor(animacion), resto)
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
		_fase_pasos = -1
		var textos: Array = datos.get(lista, [])
		var vistos := {}
		for i in _pasos.size():
			_pasos[i].text = TextoTecnico.expandir(textos[i], _glosario, vistos) if i < textos.size() else ""
	var fase := int(animacion.fase()) if animacion.has_method("fase") else 3
	if fase == _fase_pasos:
		return
	_fase_pasos = fase
	# Los pasos ya dados se encienden; el último, resaltado; los que faltan, apagados.
	for i in _chips_pasos.size():
		_chips_pasos[i].poner(i == fase - 1, i >= fase)


func _process(_delta: float) -> void:
	if animacion != null:
		_actualizar_pasos()


# --- Conexión ---

func _construir_conexion() -> void:
	var datos: Dictionary = atlas.get("conexion", {})
	var papel := _papel()
	var visor := _visor(papel)
	esquema = VistaBornes.new()
	esquema.color_etiquetas = Tema.TINTA
	esquema.cargar(datos.get("esquema", {"svg": "", "tamano": [400, 290]}))
	esquema.poner_bornes(datos.get("bornes_esquema", {}))
	esquema.custom_minimum_size.y = _alto(ALTO_ESQUEMA)
	esquema.borne_tocado.connect(tocar_borne)
	papel.add_child(esquema)
	var resto: Array[Control] = []
	var tarjeta := _placa()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	tarjeta.add_child(fila)
	var marco := VisorFicha.new(6.0)
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
	_disponer(visor, resto)
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
		(_chips[i] as BotonAri).estilo = "ambar" if i == indice else "oscuro"


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
	var visor := _visor(papel)
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
	_disponer(visor, resto)


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
		if i == 1 and not cabecera:
			var visor := _visor_lectura(str(celdas[i]), bien, 16)
			visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			visor.size_flags_stretch_ratio = proporciones[i]
			visor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fila.add_child(visor)
			continue
		var e := _etiqueta(str(celdas[i]), "Rotulo" if cabecera else "")
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.size_flags_stretch_ratio = proporciones[i]
		if not cabecera:
			e.add_theme_font_size_override("font_size", Tema.tam(15))
		fila.add_child(e)
	return fila


## Lectura en un visor negro hundido, verde si es normal y roja si indica falla, con brillo.
func _visor_lectura(texto: String, bien: bool, tam := 21, donde := "") -> Control:
	var caja := PanelContainer.new()
	caja.name = "VisorLectura"
	caja.set_meta("visor_lectura", true)
	caja.mouse_filter = Control.MOUSE_FILTER_PASS
	var e := EstiloAri.crear([Color("05080a"), Color("1a2731"), Color("2a3b48")], 6.0, 5.0, 7.0)
	e.borde = Color("0b1015")
	e.luz = Color(1, 1, 1, 0.08)
	e.sombra = 0.5
	caja.add_theme_stylebox_override("panel", e)
	var interior := _columna(2)
	caja.add_child(interior)
	var lcd := PanelContainer.new()
	lcd.mouse_filter = Control.MOUSE_FILTER_PASS
	var fondo := EstiloAri.crear([Tema.ARI_LCD_FONDO, Color("0b1510")], 6.0, 2.0, 4.0)
	fondo.borde = Color("000000")
	fondo.luz = Color(0, 0, 0, 0.0)
	fondo.sombra = 0.0
	fondo.hueco = Vector2.ZERO
	lcd.add_theme_stylebox_override("panel", fondo)
	interior.add_child(lcd)
	var tinta := Tema.ARI_LCD_VERDE if bien else Tema.ARI_ALARMA
	var valor := _etiqueta(texto)
	valor.autowrap_mode = TextServer.AUTOWRAP_OFF
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valor.add_theme_font_size_override("font_size", Tema.tam(tam))
	valor.add_theme_font_override("font", Tema.fuente(Tema.PESO_NEGRITA))
	valor.add_theme_color_override("font_color", tinta)
	valor.add_theme_color_override("font_shadow_color", Color(tinta, 0.45))
	valor.add_theme_constant_override("shadow_offset_x", 0)
	valor.add_theme_constant_override("shadow_offset_y", 0)
	valor.add_theme_constant_override("shadow_outline_size", 6)
	lcd.add_child(valor)
	if not donde.is_empty():
		var nota := _etiqueta(donde, "Nota")
		nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nota.add_theme_font_size_override("font_size", Tema.tam(12))
		interior.add_child(nota)
	return caja


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
		var b := BotonAri.new(lista[i]["nombre"], elegir_falla.bind(i), "ambar" if i == indice else "oscuro")
		b.name = "Falla_%d" % i
		b.toggle_mode = true
		b.set_pressed_no_signal(i == indice)
		b.lampara = "rojo"
		b.lampara_encendida = i == indice
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 50.0
		b.add_theme_font_size_override("font_size", Tema.tam(14))
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
		var caja := _visor_lectura(lectura["texto"], lectura["bien"], 21, lectura["donde"])
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
			# Gema verde encendida, con su halo, y la marca blanca.
			Relieve.halo(self, r.get_center(), LADO * 0.95, Relieve.VERDE_MARCA, 1.0)
			DibujoAri.pieza(self, r, 6.0, [Color("b6ffd0"), Color("22c55e"), Color("0d6b30")], [], Color("0b1015"), Color(1, 1, 1, 0.5), 0.4)
			var c := r.get_center()
			var p := PackedVector2Array([c + Vector2(-6, 0), c + Vector2(-2, 5), c + Vector2(7, -6)])
			draw_polyline(p, Color.WHITE, 3.0, true)
		else:
			# Hueco vacío, hundido en la placa.
			DibujoAri.degradado(self, r, 6.0, [Color("0b1015"), Color("1a222a")])
			DibujoAri.borde(self, r, 6.0, Color("3b4855"), 1.0)
			draw_line(r.position + Vector2(5, 2), Vector2(r.end.x - 5, r.position.y + 2), Color(0, 0, 0, 0.6), 2.0)
