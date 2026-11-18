extends Pantalla
## Catálogo del Pañol (data/catalogos/<catalogo>.json): la lista de tipos en una placa, el elegido
## dibujado en un visor con su estado (abierta o cerrada) y sus datos al lado. En vertical, el
## visor y los datos arriba y la lista debajo. El elegido y su estado viven en args.

const COLOR := Color("2e9e6a")

var datos := {}
var elementos: Array = []
var filas: Array[FilaPlaca] = []
var dibujo: DibujoValvula
var botones_estado: Array[BotonAri] = []


func construir() -> void:
	var nombre := str(args.get("catalogo", "valvulas"))
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
	cabecera.iniciar(raiz, "Catálogo de válvulas", "Pañol · cómo se reconocen y cómo saber si están abiertas" if not raiz.vertical else "Pañol · %d tipos" % elementos.size(), COLOR, "valvulas")
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
	columna.add_child(PiezasLeccion.rotulo("Tipos · %d" % elementos.size()))
	filas.clear()
	for e: Dictionary in elementos:
		var f := FilaPlaca.new(_corto(str(e["nombre"])), str(e.get("familia", "")))
		f.name = "Tipo_%s" % e["id"]
		f.tipo = "medalla"
		f.icono = "valvulas"
		f.color = COLOR
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
	var con_estado: bool = not str(e["dibujo"]) in ["retencion", "seguridad", "reductora"]
	if con_estado:
		var nombres := ["DE A A B", "DE A A C"] if e["dibujo"] == "tres_vias" else ["ABIERTA", "CERRADA"]
		for i in 2:
			var b := BotonAri.new(nombres[i], poner_estado.bind(i == 0), "ambar" if (i == 0) == bool(args["abierta"]) else "oscuro", "valvulas")
			b.name = "Estado_%d" % i
			b.custom_minimum_size.y = 44.0
			b.ajustar_ancho()
			fila.add_child(b)
			botones_estado.append(b)
	dibujo = DibujoValvula.new()
	dibujo.name = "Dibujo"
	dibujo.tipo = str(e["dibujo"])
	dibujo.flujo = true
	dibujo.apertura = 1.0 if bool(args["abierta"]) else 0.0
	dibujo.via = "b" if bool(args["abierta"]) else "c"
	if dibujo.tipo == "retencion":
		dibujo.via = "b"
	dibujo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dibujo.custom_minimum_size.y = 220.0
	columna.add_child(dibujo)
	var pie := PiezasLeccion.rotulo(str(e.get("como_saber", "")).get_slice(".", 0))
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
	for par: Array in [["Cómo saber si está abierta", "como_saber"], ["Cómo funciona", "funciona"], ["A bordo", "a_bordo"], ["No se usa para", "no_usar"], ["Mantenimiento", "mantenimiento"]]:
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
	raiz.reconstruir()


func poner_estado(abierta: bool) -> void:
	args["abierta"] = abierta
	dibujo.apertura = 1.0 if abierta else 0.0
	if dibujo.tipo == "tres_vias":
		dibujo.via = "b" if abierta else "c"
	for i in botones_estado.size():
		botones_estado[i].estilo = "ambar" if (i == 0) == abierta else "oscuro"
