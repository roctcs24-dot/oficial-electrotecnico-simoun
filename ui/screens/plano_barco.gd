extends Pantalla
## Pantalla «Buque»: el buque visto desde arriba (PlantaBuque) con dos capas. En «Tableros» cada
## lugar con paneles lleva su marca; al tocarla, sus paneles salen al lado con el código en un
## visor ámbar y una lámpara roja si tienen una avería pendiente. En «Sistemas», las zonas abren
## su sistema, como en el inicio, y al lado va la lista de sistemas con su avance.
## La capa y el lugar elegidos viven en args para sobrevivir al giro del celular.

const ANCHO_LADO_MIN := 280.0
const ANCHO_LADO_MAX := 380.0
const ALTO_BUQUE_VERTICAL := 0.56
const RESERVA_SELECTOR := 50.0

var planta: PlantaBuque
var lugares: Array = []
var filas: Array[FilaPlaca] = []
var selector: Array[BotonAri] = []
## Código del panel -> título de la misión con avería pendiente en él.
var _averias := {}


func construir() -> void:
	var c := raiz.contenido
	if not raiz.partida.aviso.is_empty():
		add_child(_aviso(raiz.partida.aviso))
	for error in c.errores:
		add_child(_aviso(error))
	_averias = averias_por_panel()
	lugares = raiz.paneles.por_lugar(c.planta().get("lugares", []))
	for l: Dictionary in lugares:
		l["nombre"] = l["lugar"]
		l["alarma"] = l["paneles"].any(func(cod: String) -> bool: return _averias.has(cod))
	if not args.has("capa"):
		args["capa"] = "tableros"
	if not args.has("lugar"):
		args["lugar"] = _lugar_inicial()
	planta = _crear_planta()
	var lado := _crear_lado()
	if raiz.vertical:
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(_ancho_lectura(columna))
		planta.custom_minimum_size.y = clampf((raiz.size.y - BarraNavegacion.ALTO) * ALTO_BUQUE_VERTICAL, 300.0, 640.0)
		columna.add_child(planta)
		columna.add_child(lado)
	else:
		var cuerpo := HBoxContainer.new()
		cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_theme_constant_override("separation", 12)
		add_child(cuerpo)
		planta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		planta.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_child(planta)
		var desplazable := _desplazable()
		desplazable.custom_minimum_size.x = clampf(raiz.ancho_contenido() * 0.36, ANCHO_LADO_MIN, ANCHO_LADO_MAX)
		cuerpo.add_child(desplazable)
		desplazable.add_child(lado)


## Misiones con un equipo dañado sin reparar, por el código del panel donde ocurren.
func averias_por_panel() -> Dictionary:
	var r := {}
	for s: Dictionary in raiz.contenido.sistemas():
		for id: String in Avance.misiones_danadas(s, raiz.partida):
			var m := raiz.contenido.mision(id)
			var codigo := raiz.paneles.codigo_mision(m)
			if not codigo.is_empty():
				r[codigo] = str(m.get("titulo", m.get("equipo", "")))
	return r


## Primero el lugar con una avería pendiente; si no hay, la sala de máquinas o el primero.
func _lugar_inicial() -> int:
	for i in lugares.size():
		if lugares[i]["alarma"]:
			return i
	for i in lugares.size():
		if lugares[i]["lugar"] == "Sala de máquinas":
			return i
	return 0 if not lugares.is_empty() else -1


func _crear_planta() -> PlantaBuque:
	var c := raiz.contenido
	var p := PlantaBuque.new()
	p.name = "Planta"
	p.cargar(c.planta(), c.sistemas())
	for s: Dictionary in c.sistemas():
		var id := int(s["id"])
		p.estados[id] = Avance.estado(s, raiz.partida) if s.get("estado", "") == "activo" else "sin_empezar"
		p.avances[id] = Avance.fraccion(Avance.sistema(s, raiz.partida))
	var marcas := []
	for l: Dictionary in lugares:
		marcas.append({"lugar": l["lugar"], "nombre": l["nombre"], "u": l["u"], "v": l["v"], "paneles": l["paneles"].size(), "alarma": l["alarma"]})
	p.lugares = marcas
	p.capa = args["capa"]
	p.lugar_elegido = args["lugar"]
	p.reserva_arriba = RESERVA_SELECTOR
	var barco := c.barco()
	p.rotulo_buque = str(barco.get("nombre", ""))
	p.detalle_buque = _resumen_barco(barco)
	p.sistema_tocado.connect(_abrir_sistema)
	p.lugar_tocado.connect(elegir_lugar)
	# Selector de capas sobre el agua, arriba a la izquierda.
	var fila := HBoxContainer.new()
	fila.name = "Capas"
	fila.position = Vector2(10, 8)
	fila.add_theme_constant_override("separation", 4)
	p.add_child(fila)
	selector.clear()
	for par: Array in [["sistemas", "SISTEMAS", "buque"], ["tableros", "TABLEROS", "electricidad"]]:
		var b := BotonAri.new(par[1], elegir_capa.bind(par[0]), "ambar" if args["capa"] == par[0] else "oscuro", par[2])
		b.name = "Capa_%s" % par[0]
		b.custom_minimum_size.y = 44.0
		b.ajustar_ancho()
		fila.add_child(b)
		selector.append(b)
	return p


## Lo de al lado del buque: los paneles del lugar elegido o la lista de sistemas, y el índice.
func _crear_lado() -> Control:
	var columna := _columna(10)
	columna.name = "Lado"
	filas.clear()
	if args["capa"] == "tableros":
		columna.add_child(_tarjeta_lugar())
	else:
		columna.add_child(_tarjeta_sistemas())
	var indice := BotonAri.new("Índice de paneles", raiz.ir_a.bind("indice_paneles"), "oscuro", "monitor")
	indice.name = "IndicePaneles"
	indice.custom_minimum_size.y = 52.0
	indice.alignment = HORIZONTAL_ALIGNMENT_LEFT
	indice.tooltip_text = "Cuadros, tableros y plantas por su código, como en el simulador"
	columna.add_child(indice)
	return columna


func _tarjeta_lugar() -> Control:
	var placa := PiezasLeccion.placa(10.0, 10.0, Color("7a5a12"))
	placa.name = "TarjetaLugar"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	var i: int = args["lugar"]
	if i < 0 or i >= lugares.size():
		columna.add_child(PiezasLeccion.etiqueta("Toque una marca del buque para ver sus tableros.", 14, Tema.TEXTO_SUAVE))
		return placa
	var l: Dictionary = lugares[i]
	var codigos: Array = l["paneles"]
	var con_averia := codigos.filter(func(cod: String) -> bool: return _averias.has(cod)).size()
	var cabecera := VBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 0)
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(cabecera)
	cabecera.add_child(PiezasLeccion.rotulo(str(l["lugar"])))
	var nota := "%d %s" % [codigos.size(), "panel" if codigos.size() == 1 else "paneles"]
	if con_averia > 0:
		nota += " · %d con avería" % con_averia
	cabecera.add_child(PiezasLeccion.etiqueta(nota, 13, Tema.TEXTO_SUAVE))
	for cod: String in codigos:
		var p := raiz.paneles.panel(cod)
		var disponible := Paneles.disponible(p)
		var detalle := "Avería pendiente: %s" % _averias[cod] if _averias.has(cod) else ("Sin alarmas" if disponible else "Próximamente")
		var f := FilaPlaca.new(str(p.get("titulo", cod)), detalle)
		f.name = "Panel_%s" % cod
		f.tipo = "codigo"
		f.codigo = cod
		f.activa = disponible
		f.lampara = "rojo" if _averias.has(cod) else ("verde" if disponible else "apagada")
		f.elegida = _averias.has(cod)
		f.tocada.connect(raiz.ir_a_panel.bind(cod))
		columna.add_child(f)
		filas.append(f)
	return placa


func _tarjeta_sistemas() -> Control:
	var placa := PiezasLeccion.placa(10.0, 10.0)
	placa.name = "TarjetaSistemas"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Sistemas del buque"))
	for s: Dictionary in raiz.contenido.sistemas():
		var id := int(s["id"])
		var activo: bool = s.get("estado", "") == "activo"
		var f := FilaPlaca.new("%d · %s" % [id, s["nombre"]], _avance_sistema(s) if activo else "Próximamente")
		f.name = "Sistema_%d" % id
		f.tipo = "medalla"
		f.color = Tema.color_area(s)
		f.icono = str(s.get("icono", "sistema_%d" % id))
		f.avance = Avance.fraccion(Avance.sistema(s, raiz.partida))
		f.activa = activo
		var estado := Avance.estado(s, raiz.partida) if activo else "sin_empezar"
		f.lampara = Relieve.LAMPARA_ESTADO.get(estado, "apagada")
		f.tocada.connect(_abrir_sistema.bind(id))
		columna.add_child(f)
		filas.append(f)
	return placa


func _avance_sistema(s: Dictionary) -> String:
	var lecciones := Avance.lecciones(s, raiz.partida)
	if lecciones[1] == 0:
		return str(s.get("resumen", ""))
	var texto := "%d de %d lecciones" % lecciones
	var misiones := Avance.misiones(s, raiz.partida)
	if misiones[1] > 0:
		texto += " · %d de %d misiones" % misiones
	return texto


func _resumen_barco(barco: Dictionary) -> String:
	if not barco.has("red_principal"):
		return ""
	var red: Dictionary = barco["red_principal"]
	return "%d V · %d Hz · trifásica · %d generadores" % [
		red["tension_v"]["valor"],
		red["frecuencia_hz"]["valor"],
		barco["generacion"]["cantidad"]["valor"],
	]


func elegir_capa(capa: String) -> void:
	args["capa"] = capa
	raiz.reconstruir()


func elegir_lugar(i: int) -> void:
	args["lugar"] = i
	raiz.reconstruir()


func _abrir_sistema(id: int) -> void:
	if raiz.contenido.sistema(id).get("estado", "") == "activo":
		raiz.ir_a("sistema", {"id": id})
