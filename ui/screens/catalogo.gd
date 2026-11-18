extends Pantalla
## Catálogo del Pañol (data/catalogos/<catalogo>.json): la lista en una placa, el elegido dibujado
## en un visor y sus datos al lado. En las válvulas, el visor deja elegir el estado (abierta o
## cerrada). En vertical, el visor y los datos arriba y la lista debajo. El elegido y su estado
## viven en args. Cada catálogo tiene su configuración en CATALOGOS. Si la pieza tiene fotos
## tomadas a bordo (data/fotos_piezas.json), el visor las enseña primero (args «foto»: su número,
## o -1 para el dibujo).

const CATALOGOS := {
	"valvulas": {
		"titulo": "Catálogo de válvulas", "sub": "Pañol · cómo se reconocen y cómo saber si están abiertas", "rotulo": "Tipos",
		"color": "2e9e6a", "icono": "valvulas",
		"campos": [["Cómo saber si está abierta", "como_saber"], ["Cómo funciona", "funciona"], ["A bordo", "a_bordo"], ["No se usa para", "no_usar"], ["Mantenimiento", "mantenimiento"]],
	},
	"herramientas": {
		"titulo": "Herramientas del pañol", "sub": "Pañol · cómo se llaman, para qué sirven y cómo se usan bien", "rotulo": "Herramientas",
		"color": "d9534f", "icono": "herramientas",
		"campos": [["Para qué sirve", "para_que"], ["Cómo se usa", "como_usar"], ["No haga esto", "no_hacer"], ["Cuidado y revisión", "cuidado"]],
	},
}

var datos := {}
var config := {}
var elementos: Array = []
var filas: Array[FilaPlaca] = []
var dibujo: Control
var botones_estado: Array[BotonAri] = []
var fotos: Array = []


func construir() -> void:
	var nombre := str(args.get("catalogo", "valvulas"))
	config = CATALOGOS.get(nombre, CATALOGOS["valvulas"])
	datos = raiz.contenido.leer("catalogos/%s.json" % nombre)
	elementos = datos.get(nombre, [])
	if elementos.is_empty():
		_cabecera("Catálogo no disponible")
		return
	if not args.has("elegido"):
		args["elegido"] = str(elementos[0]["id"])
	if not args.has("abierta"):
		args["abierta"] = true
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, config["titulo"], config["sub"] if not raiz.vertical else "Pañol · %d %s" % [elementos.size(), str(config["rotulo"]).to_lower()], color(), config["icono"])
	add_child(cabecera)
	var lista := _lista()
	var visor := _visor()
	var ficha := _ficha()
	if raiz.vertical:
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(_ancho_lectura(columna))
		visor.custom_minimum_size.y = 300.0
		columna.add_child(visor)
		columna.add_child(ficha)
		columna.add_child(lista)
	else:
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 12)
		add_child(fila)
		for par: Array in [[lista, 0.7], [visor, 1.1], [ficha, 0.8]]:
			var zona: Control = _desplazable() if par[0] != visor else par[0]
			if zona != par[0]:
				zona.add_child(par[0])
			zona.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			zona.size_flags_stretch_ratio = par[1]
			fila.add_child(zona)


func color() -> Color:
	return Color(str(config["color"]))


func es_valvula() -> bool:
	return config == CATALOGOS["valvulas"]


func elegido() -> Dictionary:
	for e: Dictionary in elementos:
		if e["id"] == args["elegido"]:
			return e
	return elementos[0]


func _lista() -> Control:
	var placa := PiezasLeccion.placa(8.0, 10.0)
	placa.name = "Lista"
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 2)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("%s · %d" % [config["rotulo"], elementos.size()]))
	filas.clear()
	for e: Dictionary in elementos:
		var f := FilaPlaca.new(_corto(str(e["nombre"])), str(e.get("familia", "")))
		f.name = "Tipo_%s" % e["id"]
		f.tipo = "medalla"
		f.icono = config["icono"]
		f.color = color()
		f.avance = 1.0 if e["id"] == args["elegido"] else 0.0
		f.elegida = e["id"] == args["elegido"]
		f.tocada.connect(elegir.bind(str(e["id"])))
		columna.add_child(f)
		filas.append(f)
	return placa


## «Válvula de bola» → «Bola»; los nombres sin «de» quedan enteros.
static func _corto(nombre: String) -> String:
	for prefijo in ["Válvula de ", "Válvula "]:
		if nombre.begins_with(prefijo):
			var resto := nombre.substr(prefijo.length())
			return resto.left(1).to_upper() + resto.substr(1)
	return nombre


func _visor() -> Control:
	var e := elegido()
	var visor := VisorFicha.new(12.0)
	visor.name = "Visor"
	visor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(columna)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	columna.add_child(fila)
	botones_estado.clear()
	fotos = FotosPiezas.de_pieza(raiz.contenido.leer(FotosPiezas.ARCHIVO), str(e["id"])) if es_valvula() else []
	var foto := int(args.get("foto", 0 if not fotos.is_empty() else -1))
	if foto >= fotos.size():
		foto = -1
	if not fotos.is_empty():
		var vistas := HBoxContainer.new()
		vistas.add_theme_constant_override("separation", 6)
		columna.add_child(vistas)
		var rotulo := PiezasLeccion.rotulo("Foto a bordo")
		rotulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rotulo.autowrap_mode = TextServer.AUTOWRAP_OFF
		vistas.add_child(rotulo)
		for i in fotos.size() + 1:
			var vista := i if i < fotos.size() else -1
			var b := BotonAri.new(str(i + 1) if vista >= 0 else "DIBUJO", ver_foto.bind(vista), "ambar" if vista == foto else "oscuro")
			b.name = "Vista_%d" % i
			b.custom_minimum_size = Vector2(44.0 if vista >= 0 else 0.0, 44.0)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if vista < 0:
				b.ajustar_ancho()
			vistas.add_child(b)
	if foto >= 0:
		var f := FotoPieza.desde(fotos[foto], str(raiz.contenido.leer(FotosPiezas.ARCHIVO).get("credito", "")), true)
		f.size_flags_vertical = Control.SIZE_EXPAND_FILL
		f.custom_minimum_size.y = 220.0
		dibujo = f
		columna.add_child(f)
		var nota := PiezasLeccion.etiqueta(str(fotos[foto].get("texto", "")), 12, Tema.TEXTO_SUAVE)
		nota.name = "TextoFoto"
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nota.custom_minimum_size.x = 120.0
		columna.add_child(nota)
		return visor
	var con_estado: bool = es_valvula() and not str(e["dibujo"]) in ["retencion", "seguridad", "reductora"]
	if con_estado:
		var nombres := ["DE A A B", "DE A A C"] if e["dibujo"] == "tres_vias" else ["ABIERTA", "CERRADA"]
		for i in 2:
			var b := BotonAri.new(nombres[i], poner_estado.bind(i == 0), "ambar" if (i == 0) == bool(args["abierta"]) else "oscuro", "valvulas")
			b.name = "Estado_%d" % i
			b.custom_minimum_size.y = 44.0
			b.ajustar_ancho()
			fila.add_child(b)
			botones_estado.append(b)
	if es_valvula():
		var v := DibujoValvula.new()
		v.tipo = str(e["dibujo"])
		v.flujo = true
		v.apertura = 1.0 if bool(args["abierta"]) else 0.0
		v.via = "b" if bool(args["abierta"]) or v.tipo == "retencion" else "c"
		dibujo = v
	else:
		var h := DibujoHerramienta.new()
		h.tipo = str(e["dibujo"])
		h.medida = str(e.get("medida", ""))
		dibujo = h
	dibujo.name = "Dibujo"
	dibujo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dibujo.custom_minimum_size.y = 220.0
	columna.add_child(dibujo)
	var pie := PiezasLeccion.rotulo(str(e.get("como_saber", e.get("para_que", ""))).get_slice(".", 0))
	pie.add_theme_font_size_override("font_size", Tema.tam(10.5))
	columna.add_child(pie)
	return visor


func _ficha() -> Control:
	var e := elegido()
	var placa := PiezasLeccion.placa(14.0, 12.0)
	placa.name = "Datos"
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo(str(e["nombre"])))
	columna.add_child(PiezasLeccion.texto_rico("[i]%s[/i] · %s" % [e.get("en", ""), str(e.get("familia", "")).to_lower()], 13, Tema.TEXTO_SUAVE))
	for par: Array in config["campos"]:
		if e.has(par[1]):
			columna.add_child(PiezasLeccion.rotulo(par[0]))
			columna.add_child(PiezasLeccion.texto_rico(str(e[par[1]]), 14))
	if e.has("fallas"):
		columna.add_child(PiezasLeccion.rotulo("Fallas"))
		for f: String in e["fallas"]:
			columna.add_child(PiezasLeccion.fila_lampara("rojo", f, 13))
	columna.add_child(PiezasLeccion.etiqueta(str(datos.get("nota", "")), 12, Tema.TEXTO_SUAVE))
	return placa


func elegir(id: String) -> void:
	args["elegido"] = id
	args["abierta"] = true
	args.erase("foto")
	raiz.reconstruir()


## Cambia la vista del visor: una foto a bordo (su número) o el dibujo (-1).
func ver_foto(i: int) -> void:
	args["foto"] = i
	raiz.reconstruir()


func poner_estado(abierta: bool) -> void:
	args["abierta"] = abierta
	var v := dibujo as DibujoValvula
	if v == null:
		return
	v.apertura = 1.0 if abierta else 0.0
	if v.tipo == "tres_vias":
		v.via = "b" if abierta else "c"
	for i in botones_estado.size():
		botones_estado[i].estilo = "ambar" if (i == 0) == abierta else "oscuro"
