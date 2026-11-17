extends Pantalla
## Escuela técnica: la ruta desde cero, por módulos. Primero los fundamentos del sistema 0;
## después, electricidad industrial, electrónica, hidráulica y neumática, válvulas y líneas, y
## herramientas y racores. Cada módulo es una medalla; el elegido muestra su camino de lecciones
## (con el examen al final, si tiene) y el cajón de piezas con las fichas de su atlas. Un módulo
## sin contenido todavía sale con candado, como «En preparación».

const ANCHO_COLUMNA := 252.0
const PASO_PIEZA := 96.0
const LADO_MEDALLA_PLACA := 52.0

## Para las pruebas: lo que se construyó.
var modulo_elegido := -1
var medallas: Array[MedallaModulo] = []
var camino: CaminoLecciones
var piezas: Array[PiezaAtlas] = []


func construir() -> void:
	var modulos := _modulos()
	modulo_elegido = int(args.get("modulo", _recomendado(modulos)))
	var m := raiz.contenido.sistema(modulo_elegido)
	if m.is_empty():
		modulo_elegido = int(modulos[0]["id"])
		m = modulos[0]
	if raiz.vertical:
		add_child(_crear_cabecera())
		var tira := HBoxContainer.new()
		tira.name = "Modulos"
		tira.add_theme_constant_override("separation", 0)
		add_child(tira)
		var ancho := minf(raiz.ancho_contenido() / modulos.size(), MedallaModulo.LADO_TIRA.x)
		for mod: Dictionary in modulos:
			var medalla := _medalla(mod, "tira")
			medalla.custom_minimum_size.x = ancho
			medalla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tira.add_child(medalla)
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(_ancho_lectura(columna))
		_contenido_modulo(m, columna, raiz.ancho_contenido())
	else:
		var cuerpo := HBoxContainer.new()
		cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cuerpo.add_theme_constant_override("separation", 12)
		add_child(cuerpo)
		var lado := PanelContainer.new()
		lado.name = "Modulos"
		lado.mouse_filter = Control.MOUSE_FILTER_PASS
		lado.custom_minimum_size.x = ANCHO_COLUMNA
		lado.add_theme_stylebox_override("panel", Relieve.estilo_placa(8.0, 8.0))
		cuerpo.add_child(lado)
		var columna_lado := _columna(4)
		lado.add_child(columna_lado)
		columna_lado.add_child(_titulo_con_anillo(true))
		var lista_desplazable := _desplazable()
		columna_lado.add_child(lista_desplazable)
		var lista := _columna(2)
		lista_desplazable.add_child(lista)
		for mod: Dictionary in modulos:
			lista.add_child(_medalla(mod, "fila"))
		var desplazable := _desplazable()
		cuerpo.add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(columna)
		_contenido_modulo(m, columna, raiz.ancho_contenido() - ANCHO_COLUMNA - 24.0)


## El sistema 0 y los módulos de la Escuela, en orden.
func _modulos() -> Array:
	return [raiz.contenido.sistema(0)] + raiz.contenido.modulos_escuela()


## El primer módulo con algo por hacer; si todo está hecho, el primero.
func _recomendado(modulos: Array) -> int:
	for mod: Dictionary in modulos:
		if mod.get("estado", "") != "activo":
			continue
		var parte := Avance.sistema(mod, raiz.partida)
		if parte[1] > 0 and parte[0] < parte[1]:
			return int(mod["id"])
	return int(modulos[0]["id"])


func elegir_modulo(id: int) -> void:
	args["modulo"] = id
	raiz.reconstruir()


func _avance_total() -> float:
	var hechos := 0
	var total := 0
	for mod: Dictionary in _modulos():
		var parte := Avance.sistema(mod, raiz.partida)
		hechos += parte[0]
		total += parte[1]
	return float(hechos) / total if total > 0 else 0.0


func _crear_cabecera() -> Control:
	var placa := PanelContainer.new()
	placa.name = "Cabecera"
	placa.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_theme_stylebox_override("panel", Relieve.estilo_placa(14.0, 8.0))
	placa.add_child(_titulo_con_anillo(false))
	return placa


func _titulo_con_anillo(corto: bool) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	textos.add_child(_etiqueta("Escuela técnica", "Titulo"))
	textos.add_child(_etiqueta("Desde cero, en orden" if corto else "Desde cero, en orden: aprenda, practique y compruébelo", "Nota"))
	var anillo := AnilloAvance.new(_avance_total(), 42.0 if corto else 46.0)
	anillo.name = "Avance"
	fila.add_child(anillo)
	return fila


func _activo(mod: Dictionary) -> bool:
	return mod.get("estado", "") == "activo"


func _icono(mod: Dictionary) -> String:
	return str(mod.get("icono", "sistema_%d" % int(mod["id"])))


func _medalla(mod: Dictionary, forma: String) -> MedallaModulo:
	var id := int(mod["id"])
	var activo := _activo(mod)
	var parte := Avance.sistema(mod, raiz.partida)
	var nombre: String = mod.get("nombre", "")
	if forma == "tira":
		nombre = nombre.get_slice(" ", 0)
	var detalle := "%d de %d" % parte if activo else "En preparación"
	var medalla := MedallaModulo.new()
	medalla.name = "Modulo%d" % id
	medalla.iniciar(forma, nombre, _icono(mod), Tema.color_area(mod), Avance.fraccion(parte) if activo else 0.0,
		{"detalle": detalle, "elegida": id == modulo_elegido, "cerrada": not activo})
	medalla.tooltip_text = mod.get("nombre", "")
	medalla.pulsada.connect(elegir_modulo.bind(id))
	medallas.append(medalla)
	return medalla


func _contenido_modulo(m: Dictionary, columna: VBoxContainer, ancho: float) -> void:
	columna.add_child(_placa_modulo(m))
	if not _activo(m):
		columna.add_child(_etiqueta("Este módulo está en preparación. Mientras tanto, siga con los módulos que ya tienen contenido.", "Nota"))
		return
	var pasos := _pasos(m)
	if not pasos.is_empty():
		var hechos := pasos.filter(func(p: Dictionary) -> bool: return p["hecho"]).size()
		columna.add_child(_rotulo("Camino de lecciones · %d de %d" % [hechos, pasos.size()]))
		camino = CaminoLecciones.new()
		camino.name = "Camino"
		camino.iniciar(pasos, Tema.color_area(m))
		camino.paso_tocado.connect(_abrir_paso.bind(pasos, int(m["id"])))
		columna.add_child(camino)
	var atlas: Array = m.get("modos", {}).get("aprender", {}).get("atlas", [])
	if not atlas.is_empty():
		var parte := Avance.atlas(m, raiz.partida)
		columna.add_child(_rotulo("Cajón de piezas · atlas %d / %d" % parte))
		var cajon := PanelContainer.new()
		cajon.name = "Cajon"
		cajon.mouse_filter = Control.MOUSE_FILTER_PASS
		cajon.add_theme_stylebox_override("panel", Relieve.estilo_hueco(9.0))
		columna.add_child(cajon)
		var rejilla := GridContainer.new()
		rejilla.columns = maxi(int((ancho - 20.0) / PASO_PIEZA), 2)
		rejilla.add_theme_constant_override("h_separation", 8)
		rejilla.add_theme_constant_override("v_separation", 8)
		cajon.add_child(rejilla)
		for id: String in atlas:
			var a := raiz.contenido.atlas(id)
			var pieza := PiezaAtlas.new()
			pieza.name = "Pieza_%s" % id
			pieza.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var vistas := raiz.partida.pestanas_atlas(id)
			pieza.iniciar(str(a.get("titulo", id)), str(a.get("icono", "ficha")), 1.0 if raiz.partida.atlas_completo(id) else minf(vistas / 5.0, 0.99))
			pieza.pulsada.connect(raiz.ir_a.bind("atlas", {"id": id}))
			piezas.append(pieza)
			rejilla.add_child(pieza)


## Lecciones del módulo y, al final, sus exámenes: [{tipo, id, titulo, hecho}].
func _pasos(m: Dictionary) -> Array:
	var r := []
	var modos: Dictionary = m.get("modos", {})
	for id: String in modos.get("aprender", {}).get("lecciones", []):
		var l := raiz.contenido.leccion(id)
		r.append({"tipo": "leccion", "id": id, "titulo": l.get("titulo", id), "minutos": int(l.get("minutos", 0)), "hecho": raiz.partida.leccion_completada(id)})
	for id: String in modos.get("examen", {}).get("examenes", []):
		var e := raiz.contenido.examen(id)
		r.append({"tipo": "examen", "id": id, "titulo": e.get("titulo", "Examen"), "minutos": 0, "hecho": raiz.partida.examen_aprobado(id)})
	return r


func _abrir_paso(indice: int, pasos: Array, sistema: int) -> void:
	var p: Dictionary = pasos[indice]
	if p["tipo"] == "examen":
		raiz.ir_a("prueba_examen", {"id": p["id"]})
	else:
		raiz.ir_a("leccion", {"id": p["id"], "sistema": sistema})


## Placa del módulo elegido: su medalla, el avance y la siguiente lección con «Empezar».
func _placa_modulo(m: Dictionary) -> Control:
	var color := Tema.color_area(m)
	var activo := _activo(m)
	var placa := PanelContainer.new()
	placa.name = "PlacaModulo"
	placa.mouse_filter = Control.MOUSE_FILTER_PASS
	var estilo := Relieve.estilo_placa(14.0, 10.0, 12.0, color.darkened(0.45))
	estilo.colores = [Relieve.PLACA[0].lerp(color, 0.32), Relieve.PLACA[1].lerp(color, 0.12), Relieve.PLACA[2]]
	estilo.posiciones = []
	placa.add_theme_stylebox_override("panel", estilo)
	placa.draw.connect(func() -> void:
		for p: Vector2 in [Vector2(8, 8), Vector2(placa.size.x - 8.0, 8), Vector2(8, placa.size.y - 8.0), placa.size - Vector2(8, 8)]:
			PiezasAri.tornillo(placa, p, 2.6))
	var columna := _columna(8)
	placa.add_child(columna)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	columna.add_child(fila)
	var parte := Avance.sistema(m, raiz.partida)
	var medalla := MedallaModulo.new()
	medalla.custom_minimum_size = Vector2(LADO_MEDALLA_PLACA, LADO_MEDALLA_PLACA)
	medalla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	medalla.iniciar("sola", m.get("nombre", ""), _icono(m), color, Avance.fraccion(parte), {"cerrada": not activo})
	fila.add_child(medalla)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	textos.add_child(_etiqueta(m.get("nombre", ""), "Subtitulo"))
	textos.add_child(_etiqueta(_resumen_avance(m) if activo else m.get("resumen", ""), "Nota"))
	if not activo:
		var chip := _etiqueta("EN PREPARACIÓN", "Rotulo")
		textos.add_child(chip)
		return placa
	var pasos := _pasos(m)
	var siguiente := -1
	for i in pasos.size():
		if not pasos[i]["hecho"]:
			siguiente = i
			break
	if pasos.is_empty():
		return placa
	var abajo := HBoxContainer.new()
	abajo.add_theme_constant_override("separation", 10)
	columna.add_child(abajo)
	var textos_abajo := VBoxContainer.new()
	textos_abajo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos_abajo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos_abajo.add_theme_constant_override("separation", 0)
	abajo.add_child(textos_abajo)
	if siguiente < 0:
		textos_abajo.add_child(_etiqueta("Camino completo: puede repasar cualquier lección tocándola.", "Nota"))
		return placa
	var p: Dictionary = pasos[siguiente]
	var rotulo := _etiqueta("SIGUIENTE", "Rotulo")
	rotulo.add_theme_color_override("font_color", Tema.ACENTO)
	textos_abajo.add_child(rotulo)
	var nombre := "%d · %s" % [siguiente + 1, p["titulo"]]
	if int(p["minutos"]) > 0:
		nombre += " · %d min" % int(p["minutos"])
	textos_abajo.add_child(_etiqueta(nombre, "Fuerte"))
	var empezar := BotonAri.new("Empezar", _abrir_paso.bind(siguiente, pasos, int(m["id"])), "ambar")
	empezar.name = "Empezar"
	empezar.custom_minimum_size = Vector2(120, 48)
	empezar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	empezar.radio = 9.0
	abajo.add_child(empezar)
	return placa


func _resumen_avance(m: Dictionary) -> String:
	var partes: Array[String] = []
	var l := Avance.lecciones(m, raiz.partida)
	if l[1] > 0:
		partes.append("%d de %d lecciones" % l)
	var a := Avance.atlas(m, raiz.partida)
	if a[1] > 0:
		partes.append("%d de %d piezas del atlas" % a)
	var e := Avance.examenes(m, raiz.partida)
	if e[1] > 0:
		partes.append("%d de %d exámenes" % e)
	return " · ".join(partes)
