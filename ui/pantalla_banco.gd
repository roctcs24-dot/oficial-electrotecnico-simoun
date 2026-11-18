class_name PantallaBanco
extends Pantalla
## Base del Taller y de las misiones: la mesa con sus piezas, las pestañas laterales y los
## instrumentos. El estado vive en args para sobrevivir al giro del celular.

const MODOS_MULTIMETRO := [["vac", "V~"], ["vdc", "V="], ["ohm", "Ω"], ["continuidad", "Cont."], ["diodo", "Diodo"], ["a", "A"], ["ma", "mA="]]
const LECTURAS_POR_SEGUNDO := 4.0
## La vista tarda unos cuadros en tomar su tamaño final: mientras tanto se repite el encuadre.
const CUADROS_ENCUADRE := 4
const TAMANO_PESTANA_APRETADA := 14
const MARGEN_PESTANA_APRETADA := 4.0
## Ancho de pantalla desde el que cinco pestañas caben con la letra normal.
const ANCHO_PESTANAS_HOLGADAS := 1200.0

var mesa: MesaTaller
var vista: VistaMesa
var _panel: VBoxContainer
var _desplazable_panel: ScrollContainer
var _estado: Label
var _lectura: Label
var _acumulado := 0.0
var _hasta_lectura := 0.0
var _cuadros_encuadre := 0
var _botones_pestana := {}
## Tablero del buque cuyo frente se muestra, si la pantalla lo tiene: data/tableros/<id>.json.
var tablero := {}
var frente: VistaTablero
var _caja_mesa: Control
var _barra_frente: HBoxContainer
var _boton_puerta: Button
## Mímico del tablero con sus casillas, si el tablero tiene bloque «mimico».
var mimico: VistaMimico
var _botones_vista := {}


## Lista de [id, nombre] de las pestañas.
func _pestanas() -> Array:
	return []


func _mostrar_panel(_id: String) -> void:
	pass


func _opciones_instrumento() -> Array:
	return [["multimetro", "Multímetro"], ["megohmetro", "Megóhmetro"], ["pinza", "Pinza"], ["no", "Cablear"]]


## Una lectura ya tomada. Las misiones la registran como evidencia.
func _tras_medir(_instrumento: String, _modo: String, _a: String, _b: String, _resultado: Dictionary) -> void:
	pass


func _tocar_borne_sin_instrumento(_nodo: String) -> void:
	pass


func _proporcion_vista() -> float:
	return 1.6


func _iniciar_banco(nueva_mesa: MesaTaller, pestana: String, medicion := "") -> void:
	args["mesa"] = nueva_mesa
	args["pestana"] = pestana
	args["multimetro"] = SimMultimetro.new()
	args["megohmetro"] = SimMegohmetro.new()
	args["pinza"] = SimPinza.new()
	args["pinza_cables"] = []
	args["modo"] = "vac"
	args["v_prueba"] = 500
	args["pieza"] = ""
	args["primer_borne"] = ""
	args["roja"] = ""
	args["negra"] = ""
	args["cable"] = -1
	args["medicion"] = medicion
	_cuadros_encuadre = CUADROS_ENCUADRE


func _montar_banco() -> void:
	mesa = args["mesa"]
	_avisos = _capa_avisos()
	add_child(_avisos)
	var cuerpo: BoxContainer = VBoxContainer.new() if raiz.vertical else HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 8)
	add_child(cuerpo)
	cuerpo.add_child(_crear_vista())
	cuerpo.add_child(_crear_lateral())
	_reconstruir_panel()
	_actualizar_marcas()
	tree_exiting.connect(_al_salir)
	if args.has("vista_zoom"):
		vista.zoom = args["vista_zoom"]
		vista.origen = args["vista_origen"]


## Conserva el encuadre al girar el celular.
func _al_salir() -> void:
	args["vista_zoom"] = vista.zoom
	args["vista_origen"] = vista.origen
	if frente != null:
		args["frente_zoom"] = frente.zoom
		args["frente_desplazamiento"] = frente.desplazamiento


func _crear_vista() -> Control:
	return _crear_vista_mesa() if tablero.is_empty() else _crear_vista_tablero()


func _crear_vista_mesa() -> Control:
	var contenedor := VBoxContainer.new()
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_stretch_ratio = _proporcion_vista()
	contenedor.add_theme_constant_override("separation", 6)
	vista = VistaMesa.new()
	vista.mesa = mesa
	vista.custom_minimum_size.y = 220.0
	vista.borne_tocado.connect(_al_tocar_borne)
	vista.pieza_tocada.connect(_al_tocar_pieza)
	vista.cable_tocado.connect(_al_tocar_cable)
	vista.fondo_tocado.connect(_al_tocar_fondo)
	contenedor.add_child(vista)
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 6)
	contenedor.add_child(barra)
	for d: Array in [["−", 1.0 / 1.25], ["+", 1.25]]:
		var b := _boton(d[0], _zoom.bind(d[1]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.custom_minimum_size.x = 56.0
		barra.add_child(b)
	var ver := _boton("Ver todo", func() -> void: vista.encuadrar())
	ver.autowrap_mode = TextServer.AUTOWRAP_OFF
	barra.add_child(ver)
	var ordenar := _boton("Ordenar cables", ordenar_cables)
	ordenar.autowrap_mode = TextServer.AUTOWRAP_OFF
	barra.add_child(ordenar)
	# En su propia línea y sin ajuste: en vertical no queda ancho junto a los botones.
	_estado = _etiqueta("", "Nota")
	_estado.autowrap_mode = TextServer.AUTOWRAP_OFF
	_estado.clip_text = true
	contenedor.add_child(_estado)
	return contenedor


## Con un tablero, la vista es su mímico (casillas de simulador), su frente dibujado como en el
## buque o, con la puerta abierta, la mesa con su interior. Se elige con la barra de arriba.
func _crear_vista_tablero() -> Control:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = _proporcion_vista()
	caja.add_theme_constant_override("separation", 6)
	var barra := HBoxContainer.new()
	barra.name = "BarraVistas"
	barra.add_theme_constant_override("separation", 4)
	caja.add_child(barra)
	var vistas: Array = [["frente", "Frente"], ["interior", "Interior"]]
	if tablero.has("mimico"):
		vistas.push_front(["mimico", "Mímico"])
	var grupo := ButtonGroup.new()
	for v: Array in vistas:
		var b := _boton(v[1], elegir_vista.bind(v[0]))
		b.name = "Vista_" + v[0]
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.toggle_mode = true
		b.button_group = grupo
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.add_child(b)
		_botones_vista[v[0]] = b
	# El botón de la puerta es ahora el de la vista Interior.
	_boton_puerta = _botones_vista["interior"]
	if tablero.has("mimico"):
		mimico = VistaMimico.new()
		mimico.name = "Mimico"
		mimico.custom_minimum_size.y = 200.0
		mimico.preparar(tablero["mimico"], mesa.sim)
		mimico.accion.connect(_al_accionar_casilla)
		caja.add_child(mimico)
	frente = VistaTablero.new()
	frente.datos = tablero["frente"]
	frente.id_tablero = str(tablero.get("id", ""))
	frente.sim = mesa.sim
	frente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frente.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frente.custom_minimum_size.y = 280.0
	frente.elemento_tocado.connect(_al_tocar_elemento)
	frente.elemento_soltado.connect(_al_soltar_elemento)
	caja.add_child(frente)
	_barra_frente = HBoxContainer.new()
	_barra_frente.add_theme_constant_override("separation", 6)
	caja.add_child(_barra_frente)
	for d: Array in [["−", 1.0 / 1.25], ["+", 1.25]]:
		var b := _boton(d[0], func() -> void: frente.cambiar_zoom(d[1], frente.size / 2.0))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.custom_minimum_size.x = 56.0
		_barra_frente.add_child(b)
	var todo := _boton("Ver todo", func() -> void: frente.encuadrar())
	todo.autowrap_mode = TextServer.AUTOWRAP_OFF
	_barra_frente.add_child(todo)
	if args.has("frente_zoom"):
		frente.zoom = args["frente_zoom"]
		frente.desplazamiento = args["frente_desplazamiento"]
	_caja_mesa = _crear_vista_mesa()
	caja.add_child(_caja_mesa)
	_aplicar_puerta()
	_actualizar_megger()
	return caja


## Vista del tablero: «mimico», «frente» o «interior» (la puerta abierta).
func vista_tablero() -> String:
	if args.get("puerta", false):
		return "interior"
	var v: String = args.get("vista", "")
	if v == "mimico" and mimico == null:
		v = "frente"
	if v.is_empty() or v == "interior":
		v = "mimico" if mimico != null else "frente"
	return v


func elegir_vista(id: String) -> void:
	args["puerta"] = id == "interior"
	if id != "interior":
		args["vista"] = id
	_aplicar_puerta()
	_reconstruir_panel()


func _alternar_puerta() -> void:
	args["puerta"] = not args.get("puerta", false)
	_aplicar_puerta()
	_reconstruir_panel()


func _aplicar_puerta() -> void:
	var v := vista_tablero()
	var abierta := v == "interior"
	for clave: String in _botones_vista:
		_botones_vista[clave].set_pressed_no_signal(clave == v)
	if mimico != null:
		mimico.visible = v == "mimico"
	frente.visible = v == "frente"
	_barra_frente.visible = v == "frente"
	_caja_mesa.visible = abierta
	if abierta:
		_cuadros_encuadre = CUADROS_ENCUADRE


# --- Mímico: casillas de arrancador ---

## Componente que maneja una zona de una casilla.
func _componente_zona(casilla: CasillaAri, zona: String) -> String:
	if zona.begins_with("mando_"):
		var elementos: Array = casilla.datos.get("elementos", [])
		return str(elementos[int(zona.trim_prefix("mando_"))].get("componente", ""))
	return str(casilla.datos.get(zona, ""))


func _al_accionar_casilla(casilla: CasillaAri, que: String, valor: Variant) -> void:
	match que:
		"pulsar", "soltar":
			var id := _componente_zona(casilla, str(valor[0]))
			if not mesa.sim.componentes.has(id):
				return
			var c := mesa.sim.componente(id)
			if c is SimSelector:
				if que == "pulsar":
					(c as SimSelector).girar(int(valor[1]))
				else:
					(c as SimSelector).soltar()
			else:
				c.estado["presionado"] = que == "pulsar"
			_tras_accionar_frente()
		"proteccion":
			_maniobrar_proteccion(casilla)
		"seccionador":
			var q := mesa.sim.componente(str(casilla.datos["componente"])) as SimSeccionador
			if not q.accionar(not q.cerrado()):
				_mostrar_aviso("Interruptor bloqueado", "Tiene puesto el candado de bloqueo y su tarjeta. Solo lo retira quien lo puso, cuando termina el trabajo.")
			_tras_accionar_frente()
		"candado":
			var q := mesa.sim.componente(str(casilla.datos["componente"])) as SimSeccionador
			if q.cerrado():
				_mostrar_aviso("Primero abra el interruptor", "El candado y la tarjeta se ponen con el interruptor abierto, en la posición 0.")
			else:
				q.poner_candado(not q.estado["candado"])
			_tras_accionar_frente()
		"elegir":
			if casilla.datos.has("motor"):
				args["meg_casilla"] = casilla.indice
				args.erase("meg_resultado")
				_actualizar_megger()
		"anterior", "siguiente":
			_cambiar_motor_megger(-1 if que == "anterior" else 1)
		"tension":
			var tensiones: Array = SimMegohmetro.TENSIONES
			args["v_prueba"] = tensiones[(tensiones.find(int(args["v_prueba"])) + 1) % tensiones.size()]
			args.erase("meg_resultado")
			_actualizar_megger()
		"test":
			medir_con_megger()
		_:
			if que.begins_with("fase_"):
				args["meg_fase"] = que.trim_prefix("fase_")
				args.erase("meg_resultado")
				_actualizar_megger()
			elif que.begins_with("mando_"):
				var c := mesa.sim.componente(_componente_zona(casilla, que))
				if c is SimSeta:
					if c.estado["enclavada"]:
						(c as SimSeta).liberar()
					else:
						(c as SimSeta).pulsar()
				_tras_accionar_frente()


## ON/TRIP de una casilla: tras un disparo, rearma (el relé térmico, el arrancador suave o el
## guardamotor); si no, abre o cierra la protección.
func _maniobrar_proteccion(casilla: CasillaAri) -> void:
	var d := casilla.datos
	var t: SimComponente = mesa.sim.componente(str(d["termico"])) if d.has("termico") else null
	var a: SimComponente = mesa.sim.componente(str(d["arrancador"])) if d.has("arrancador") else null
	var q := mesa.sim.componente(str(d["proteccion"])) as SimGuardamotor
	if t != null and t.estado.get("disparado", false):
		_rearmar_rele(t.id)
	elif a != null and a.estado.get("fase", "") == "fallo":
		_rearmar_arrancador(a.id)
	elif q.estado["disparado"]:
		q.accionar(false)
		q.accionar(true)
	else:
		q.accionar(not q.estado["encendido"])
	_tras_accionar_frente()
	_reconstruir_panel()


func _casillas_motor() -> Array[CasillaAri]:
	var r: Array[CasillaAri] = []
	if mimico != null:
		for c in mimico.casillas:
			if c.datos.has("motor"):
				r.append(c)
	return r


func _casilla_megger() -> CasillaAri:
	var motores := _casillas_motor()
	if motores.is_empty():
		return null
	var i: int = args.get("meg_casilla", motores[0].indice)
	for c in motores:
		if c.indice == i:
			return c
	return motores[0]


func _cambiar_motor_megger(paso: int) -> void:
	var motores := _casillas_motor()
	if motores.is_empty():
		return
	var actual := motores.find(_casilla_megger())
	args["meg_casilla"] = motores[posmod(actual + paso, motores.size())].indice
	args.erase("meg_resultado")
	_actualizar_megger()


## Prueba de aislamiento desde el mímico: la punta roja al borne de la fase elegida del motor y
## la negra a masa, como al medir en la bornera. Las misiones la registran igual.
func medir_con_megger() -> Dictionary:
	var c := _casilla_megger()
	if c == null or mimico == null:
		return {}
	if args["megohmetro"].destruido:
		_megohmetro_nuevo()
		args["meg_resultado"] = {"lectura": "----", "veredicto": "INSTRUMENTO NUEVO", "color": Tema.ARI_LCD_AMBAR}
		_actualizar_megger()
		return {}
	var masa: String = tablero["mimico"].get("megohmetro", {}).get("masa", "PE.PE")
	args["roja"] = "%s.%s" % [c.datos["motor"], args.get("meg_fase", "U1")]
	args["negra"] = masa
	_actualizar_marcas()
	var r := medir_aislamiento()
	if r.is_empty():
		return r
	var resultado := {}
	if not str(r["averia"]).is_empty():
		resultado = {"lectura": "Err", "veredicto": "AVERIADO: HABÍA TENSIÓN", "color": Tema.ARI_ALARMA}
	elif r["fuera_de_rango"]:
		resultado = {"lectura": "999", "veredicto": "> 999 MΩ · AISLAM. BUENO", "color": Tema.ARI_LCD_VERDE}
	else:
		var mohm: float = r["mohm"]
		var texto := LecturaLcd.numero(mohm, 2 if mohm < 10.0 else (1 if mohm < 100.0 else 0))
		resultado = {"lectura": texto, "veredicto": "AISLAM. BUENO" if r["aceptable"] else "AISLAM. BAJO", "color": Tema.ARI_LCD_VERDE if r["aceptable"] else Tema.ARI_ALARMA}
	args["meg_resultado"] = resultado
	_actualizar_megger()
	return r


func _actualizar_megger() -> void:
	if mimico == null:
		return
	var m := mimico.casilla_megohmetro()
	var elegida := _casilla_megger()
	for c in mimico.casillas:
		c.marcada = m != null and c == elegida
	if m == null:
		return
	var estado := {"motor": str(elegida.datos.get("titulo", "")) if elegida != null else "", "fase": args.get("meg_fase", "U1"), "tension": args.get("v_prueba", 500)}
	estado.merge(args.get("meg_resultado", {"lectura": "----", "veredicto": "PULSE TEST", "color": Tema.ARI_LCD_AMBAR}))
	m.megger = estado
	m.queue_redraw()


# --- Mandos del frente ---

func _elemento(indice: int) -> Dictionary:
	return tablero["frente"]["elementos"][indice]


func _al_tocar_elemento(indice: int, lado: int) -> void:
	accionar(indice, lado)


func _al_soltar_elemento(indice: int) -> void:
	soltar(indice)


## Acción sobre un elemento del frente: pulsar, girar un selector, enclavar o liberar la seta, o
## maniobrar el interruptor general. Devuelve false si el candado lo impide.
func accionar(indice: int, lado := 1) -> bool:
	var e := _elemento(indice)
	var c := mesa.sim.componente(e["componente"])
	var hecho := true
	match e["tipo"]:
		"pulsador":
			c.estado["presionado"] = true
		"selector":
			(c as SimSelector).girar(lado)
		"seta":
			var seta := c as SimSeta
			if seta.estado["enclavada"]:
				seta.liberar()
			else:
				seta.pulsar()
		"seccionador":
			var q := c as SimSeccionador
			hecho = q.accionar(not q.cerrado())
			if not hecho:
				_mostrar_aviso("Interruptor bloqueado", "Tiene puesto el candado de bloqueo y su tarjeta. Solo lo retira quien lo puso, cuando termina el trabajo.")
	_tras_accionar_frente()
	return hecho


## Para que cada pantalla refresque su panel tras tocar un mando del frente.
func _tras_accionar_frente() -> void:
	pass


func soltar(indice: int) -> void:
	var e := _elemento(indice)
	var c := mesa.sim.componente(e["componente"])
	match e["tipo"]:
		"pulsador":
			c.estado["presionado"] = false
		"selector":
			(c as SimSelector).soltar()


func ordenar_cables() -> void:
	mesa.ordenar_cables()
	vista.queue_redraw()
	if args["cable"] >= 0:
		_reconstruir_panel()


func _zoom(factor: float) -> void:
	vista.cambiar_zoom(factor, vista.size / 2.0)


func _crear_lateral() -> Control:
	var lateral := _columna(6)
	lateral.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grupo := ButtonGroup.new()
	var pestanas := HBoxContainer.new()
	pestanas.add_theme_constant_override("separation", 4)
	lateral.add_child(pestanas)
	var muchas := _pestanas().size() > 4
	for p: Array in _pestanas():
		var b := _boton(p[1], _elegir_pestana.bind(p[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		if muchas:
			_apretar_pestana(b)
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["pestana"] == p[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pestanas.add_child(b)
		_botones_pestana[p[0]] = b
	_desplazable_panel = _desplazable()
	lateral.add_child(_chapa_zona(_desplazable_panel))
	_panel = _columna(8)
	_desplazable_panel.add_child(_panel)
	return lateral


## Sin esto, cinco pestañas ensancharían la pantalla más allá del celular.
func _apretar_pestana(b: Button) -> void:
	b.clip_text = true
	b.custom_minimum_size.y = 48.0
	# Dentro del marco, el estilo es el de los botones del simulador.
	var tema: Theme = Tema.crear_ari() if en_marco() else raiz.theme
	for estado: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		if tema.has_stylebox(estado, "Button"):
			var caja: StyleBox = tema.get_stylebox(estado, "Button").duplicate()
			caja.content_margin_left = MARGEN_PESTANA_APRETADA
			caja.content_margin_right = MARGEN_PESTANA_APRETADA
			b.add_theme_stylebox_override(estado, caja)
	# En horizontal, el panel lateral de un celular también es estrecho para cinco pestañas.
	if en_marco():
		b.add_theme_font_size_override("font_size", Tema.tam(13))
	elif raiz.vertical or get_viewport_rect().size.x < ANCHO_PESTANAS_HOLGADAS:
		b.add_theme_font_size_override("font_size", TAMANO_PESTANA_APRETADA)


func _elegir_pestana(id: String) -> void:
	args["pestana"] = id
	for clave: String in _botones_pestana:
		_botones_pestana[clave].set_pressed_no_signal(clave == id)
	_desplazable_panel.scroll_vertical = 0
	_reconstruir_panel()


func _reconstruir_panel() -> void:
	# La lista se rehace entera: sin esto, cada acción devolvería el desplazamiento al inicio.
	var desplazado := _desplazable_panel.scroll_vertical
	for hijo in _panel.get_children():
		_panel.remove_child(hijo)
		hijo.queue_free()
	_lectura = null
	_mostrar_panel(args["pestana"])
	_restaurar_desplazamiento.call_deferred(desplazado)


func _restaurar_desplazamiento(desplazado: int) -> void:
	if is_instance_valid(_desplazable_panel):
		_desplazable_panel.scroll_vertical = desplazado


func _agregar_ajuste(c: SimComponente, titulo: String, minimo: float, maximo: float) -> void:
	var etiqueta := _etiqueta("%s: %s A" % [titulo, TextoTecnico.numero(c.params["ajuste_a"], 1)])
	_panel.add_child(etiqueta)
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = 0.5
	control.value = c.params["ajuste_a"]
	control.custom_minimum_size.y = 48.0
	control.value_changed.connect(func(v: float) -> void:
		c.params["ajuste_a"] = v
		etiqueta.text = "%s: %s A" % [titulo, TextoTecnico.numero(v, 1)])
	_panel.add_child(control)


func _agregar_pulsador(id: String, texto := "Mantener pulsado") -> void:
	var pulsar := Button.new()
	pulsar.text = texto
	pulsar.set_meta("se_mantiene", true)
	pulsar.button_down.connect(_pulsar.bind(id, true))
	pulsar.button_up.connect(_pulsar.bind(id, false))
	_panel.add_child(pulsar)


func _pulsar(id: String, presionado: bool) -> void:
	if mesa.piezas.has(id):
		mesa.sim.componente(id).estado["presionado"] = presionado


func _rearmar_rele(id: String) -> void:
	if not mesa.sim.componente(id).rearmar():
		_mostrar_aviso("Todavía caliente", "El relé no rearma hasta enfriarse. Aproveche para buscar la causa del disparo.")
	_reconstruir_panel()


## El arrancador suave en fallo se rearma desde su teclado; la marcha necesita una orden nueva.
func _rearmar_arrancador(id: String) -> void:
	(mesa.sim.componente(id) as SimArrancadorSuave).rearmar()
	_reconstruir_panel()


## LEDs de las entradas y salidas con nombre de un autómata, como en su frente.
func _agregar_io_plc(c: SimComponente) -> void:
	var plc := c as SimPLC
	var etiquetas: Dictionary = plc.params["etiquetas"]
	_panel.add_child(_etiqueta("%s · %s" % ["Alimentado" if plc.estado["alimentado"] else "Sin alimentación", plc.estado["modo"]], "Nota"))
	for i in SimPLC.ENTRADAS:
		var d := "%" + SimPLC.entrada(i)
		if etiquetas.has(d):
			_panel.add_child(_etiqueta("%s  %s · LED %s" % [d, etiquetas[d], "encendido" if plc.entrada_activa(i) else "apagado"]))
	for i in SimPLC.SALIDAS:
		var d := "%" + SimPLC.salida(i)
		if etiquetas.has(d):
			_panel.add_child(_etiqueta("%s  %s · LED %s" % [d, etiquetas[d], "encendido" if plc.salida_activa(i) else "apagado"]))
	_panel.add_child(_etiqueta("Una entrada apagada con su contacto cerrado indica un cable o un borne; una encendida con el contacto abierto, un corto.", "Nota"))


## Lecturas y contactos de la máquina principal, y el rearme de sus disparos retenidos.
func _agregar_maquina(c: SimComponente, con_rearme := true) -> void:
	var mp := c as SimMaquinaPrincipal
	_panel.add_child(_etiqueta("%s rpm · aceite %s bar · aire %s bar · agua HT %s °C" % [
		TextoTecnico.numero(mp.rpm(), 0), TextoTecnico.numero(mp.presion("aceite"), 1),
		TextoTecnico.numero(mp.presion("aire"), 1), TextoTecnico.numero(mp.temperatura("ht"), 0)], "Nota"))
	for linea: String in mp.pantalla():
		_panel.add_child(_etiqueta(linea, "Nota"))
	var nombres := {"PL": "presostato de aceite", "VG": "virador desacoplado", "PA": "presostato de aire", "SV": "relé de velocidad", "SB": "sobrevelocidad (NC)", "CP": "sobrepresión del cárter, COP (NC)", "NA": "niebla de aceite CMR (NC)", "TA": "alta temperatura del agua (NC)", "LL": "limitación de carga"}
	for par: String in nombres:
		_panel.add_child(_etiqueta("%s1-%s2, %s: %s" % [par, par, nombres[par], "cerrado" if mp.contacto_cerrado(par) else "abierto"]))
	if con_rearme and mp.disparo_retenido():
		_panel.add_child(_boton("Rearmar en el motor el disparo retenido", _rearmar_maquina.bind(c.id)))


func _rearmar_maquina(id: String) -> void:
	if not (mesa.sim.componente(id) as SimMaquinaPrincipal).rearmar():
		_mostrar_aviso("Motor en movimiento", "Los disparos de sobrevelocidad, de sobrepresión del cárter y de niebla de aceite se rearman con el motor parado, después de buscar la causa.")
	_reconstruir_panel()


## Acercar o retirar la pieza metálica delante de un sensor de proximidad.
func _agregar_objeto_sensor(c: SimComponente) -> void:
	var delante: bool = c.estado["objeto"]
	_panel.add_child(_boton("Retirar la pieza metálica" if delante else "Acercar una pieza metálica", _alternar_objeto.bind(c.id)))


func _alternar_objeto(id: String) -> void:
	var c := mesa.sim.componente(id)
	c.estado["objeto"] = not c.estado["objeto"]
	_reconstruir_panel()


## RUN/STOP y tipo de entradas del PLC. El tipo debe coincidir con los sensores y con el común 1M.
func _agregar_mandos_plc(c: SimComponente) -> void:
	var plc := c as SimPLC
	_panel.add_child(_boton("Pasar a STOP" if plc.estado["modo"] == "RUN" else "Pasar a RUN", _alternar_modo_plc.bind(c.id)))
	var tipo: String = plc.params["entradas"]
	_panel.add_child(_etiqueta("Entradas para sensores %s: el común 1M va al %s." % [tipo.to_upper(), "−" if tipo == "pnp" else "+"], "Nota"))
	_panel.add_child(_boton("Configurar entradas %s" % ("NPN" if tipo == "pnp" else "PNP"), _alternar_entradas_plc.bind(c.id)))


func _alternar_modo_plc(id: String) -> void:
	var plc := mesa.sim.componente(id) as SimPLC
	plc.cambiar_modo("STOP" if plc.estado["modo"] == "RUN" else "RUN")
	_reconstruir_panel()


func _alternar_entradas_plc(id: String) -> void:
	var plc := mesa.sim.componente(id) as SimPLC
	plc.params["entradas"] = "npn" if plc.params["entradas"] == "pnp" else "pnp"
	_reconstruir_panel()


## Botón de rearme del arrancador suave, solo si está en fallo.
func _agregar_rearme_arrancador(c: SimComponente) -> void:
	if c.estado.get("fase", "") == "fallo":
		_panel.add_child(_boton("Rearmar el arrancador (tecla Reset)", _rearmar_arrancador.bind(c.id)))


func _panel_medir() -> void:
	var grupo := ButtonGroup.new()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_panel.add_child(fila)
	var opciones := _opciones_instrumento()
	for i: Array in opciones:
		var b := _boton(i[1], _elegir_instrumento.bind(i[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		if opciones.size() > 3:
			_apretar_pestana(b)
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["medicion"] == i[0] or (args["medicion"] == "" and i[0] == "no"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	if args["medicion"] == "multimetro":
		_panel_multimetro()
	elif args["medicion"] == "megohmetro":
		_panel_megohmetro()
	elif args["medicion"] == "pinza":
		_panel_pinza()
	else:
		_panel.add_child(_etiqueta("Elija un instrumento. Después, toque dos bornes para colocar las puntas.", "Nota"))


func _elegir_instrumento(id: String) -> void:
	args["medicion"] = "" if id == "no" else id
	args["primer_borne"] = ""
	args["roja"] = ""
	args["negra"] = ""
	args["pinza_cables"] = []
	_actualizar_marcas()
	_reconstruir_panel()


func _pantalla_instrumento() -> Label:
	var tarjeta := _tarjeta_base("Papel")
	_panel.add_child(tarjeta)
	_lectura = _etiqueta("---", "Titulo")
	# Dentro del marco, la pantalla del instrumento es un visor negro con lectura verde.
	_lectura.add_theme_color_override("font_color", Tema.ARI_LCD_VERDE if en_marco() else Tema.TINTA)
	_lectura.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tarjeta.add_child(_lectura)
	return _lectura


func _panel_multimetro() -> void:
	_pantalla_instrumento()
	var grupo := ButtonGroup.new()
	# Siete modos no caben en una línea de un celular vertical: pasan a la siguiente.
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 4)
	fila.add_theme_constant_override("v_separation", 4)
	_panel.add_child(fila)
	for m: Array in MODOS_MULTIMETRO:
		var b := _boton(m[1], _elegir_modo.bind(m[0]))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		_apretar_pestana(b)
		# Sin recortar: cada modo ocupa su ancho y los que no caben bajan de línea.
		b.clip_text = false
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["modo"] == m[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	_panel.add_child(_etiqueta("Antes de pasar a Ω o A, compruebe que el modo sea adecuado: un error daña el instrumento.", "Nota"))
	var m: SimMultimetro = args["multimetro"]
	if not m.fusible_ok and not m.destruido:
		_panel.add_child(_boton("Cambiar el fusible del multímetro", _cambiar_fusible))
	if m.destruido:
		_panel.add_child(_boton("Usar un multímetro nuevo", _multimetro_nuevo))


func _elegir_modo(id: String) -> void:
	args["modo"] = id
	_hasta_lectura = 0.0


func _cambiar_fusible() -> void:
	args["multimetro"].cambiar_fusible()
	_reconstruir_panel()


func _multimetro_nuevo() -> void:
	args["multimetro"] = SimMultimetro.new()
	_reconstruir_panel()


func _panel_megohmetro() -> void:
	_pantalla_instrumento()
	var grupo := ButtonGroup.new()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_panel.add_child(fila)
	for v: int in SimMegohmetro.TENSIONES:
		var b := _boton("%d V" % v, _elegir_v_prueba.bind(v))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.toggle_mode = true
		b.button_group = grupo
		b.set_pressed_no_signal(args["v_prueba"] == v)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	_panel.add_child(_boton("Realizar la prueba", medir_aislamiento))
	if args["megohmetro"].destruido:
		_panel.add_child(_boton("Usar un megóhmetro nuevo", _megohmetro_nuevo))
	_panel.add_child(_etiqueta("Devanados de menos de 1 kV: mínimo 5 MΩ según IEEE 43. Verificar el criterio del buque.", "Nota"))


func _panel_pinza() -> void:
	_pantalla_instrumento()
	var abrazados: Array = args["pinza_cables"]
	if abrazados.is_empty():
		_panel.add_child(_etiqueta("Toque un cable de la mesa para abrazarlo con la pinza.", "Nota"))
	else:
		var nombres := PackedStringArray()
		for i: int in abrazados:
			nombres.append("%s — %s" % mesa.sim.cables[i])
		_panel.add_child(_etiqueta("Abraza: %s" % ", ".join(nombres)))
		_panel.add_child(_boton("Soltar la pinza", _soltar_pinza))
	_panel.add_child(_etiqueta("Abrace un solo conductor. Con las tres fases de un mismo circuito, las corrientes se anulan y la pinza marca casi cero. Rango de 400 A y resolución de 0,1 A: valores típicos, verificar con la pinza del buque.", "Nota"))


## Tocar un cable lo añade a la pinza; tocarlo de nuevo lo saca.
func _abrazar_cable(indice: int) -> void:
	var abrazados: Array = args["pinza_cables"]
	if abrazados.has(indice):
		abrazados.erase(indice)
	else:
		abrazados.append(indice)
	_hasta_lectura = 0.0
	if args["pestana"] != "medir":
		_elegir_pestana("medir")
	else:
		_reconstruir_panel()
	_actualizar_marcas()


func _soltar_pinza() -> void:
	args["pinza_cables"] = []
	_reconstruir_panel()
	_actualizar_marcas()


func _elegir_v_prueba(v: int) -> void:
	args["v_prueba"] = v


func _megohmetro_nuevo() -> void:
	args["megohmetro"] = SimMegohmetro.new()
	_reconstruir_panel()


## El megóhmetro solo mide a petición: aplica tensión y no debe hacerlo continuamente.
func medir_aislamiento() -> Dictionary:
	if args["roja"].is_empty() or args["negra"].is_empty():
		_mostrar_aviso("Faltan las puntas", "Toque dos bornes o puntos de la mesa para colocar las puntas.")
		return {}
	var r: Dictionary = args["megohmetro"].medir(mesa.sim, args["roja"], args["negra"], args["v_prueba"])
	_tras_medir("megohmetro", str(args["v_prueba"]), args["roja"], args["negra"], r)
	_revisar_eventos()
	if _lectura == null or args["medicion"] != "megohmetro":
		return r
	if not r["averia"].is_empty():
		_lectura.text = "AVERIADO"
	else:
		var valor := "> 999" if r["fuera_de_rango"] else TextoTecnico.numero(r["mohm"], 2)
		_lectura.text = "%s MΩ  %s" % [valor, "aceptable" if r["aceptable"] else "bajo"]
	if args["megohmetro"].destruido:
		_reconstruir_panel()
	return r


func _actualizar_lectura() -> void:
	if args["medicion"] == "pinza" and _lectura != null:
		_actualizar_lectura_pinza()
		return
	if args["medicion"] != "multimetro" or _lectura == null:
		return
	if args["roja"].is_empty() or args["negra"].is_empty():
		_lectura.text = "Coloque las puntas"
		return
	var m: SimMultimetro = args["multimetro"]
	var estaba_bien := m.fusible_ok and not m.destruido
	var r: Dictionary = m.medir(mesa.sim, args["modo"], args["roja"], args["negra"])
	_tras_medir("multimetro", args["modo"], args["roja"], args["negra"], r)
	if not r["averia"].is_empty():
		_lectura.text = "AVERIADO" if m.destruido else "Fusible fundido"
	elif r["fuera_de_rango"]:
		_lectura.text = "OL"
	else:
		var decimales := 3 if absf(float(r["valor"])) < 10.0 else 1
		var pita := "  · continuidad" if r.get("pita", false) else ""
		_lectura.text = "%s %s%s" % [TextoTecnico.numero(r["valor"], decimales), r["unidad"], pita]
	if estaba_bien and not (m.fusible_ok and not m.destruido):
		_reconstruir_panel()


func _actualizar_lectura_pinza() -> void:
	var abrazados: Array = args["pinza_cables"]
	if abrazados.is_empty():
		_lectura.text = "Abrace un cable"
		return
	var r: Dictionary = args["pinza"].medir(mesa.sim, abrazados)
	var primero: Array = mesa.sim.cables[abrazados[0]]
	_tras_medir("pinza", "a" if abrazados.size() == 1 else "a_varios", primero[0], primero[1], r)
	if r["fuera_de_rango"]:
		_lectura.text = "OL"
	else:
		_lectura.text = "%s A" % TextoTecnico.numero(r["valor"], 1)


func _al_tocar_borne(nodo: String) -> void:
	if args["medicion"] == "pinza":
		_estado.text = "La pinza no tiene puntas: se coloca abrazando un cable."
		return
	if args["medicion"] != "":
		_colocar_punta(nodo)
	else:
		_tocar_borne_sin_instrumento(nodo)


func _colocar_punta(nodo: String) -> void:
	if args["roja"].is_empty() or not args["negra"].is_empty():
		args["roja"] = nodo
		args["negra"] = ""
	else:
		args["negra"] = nodo
	_hasta_lectura = 0.0
	_actualizar_marcas()


func _al_tocar_pieza(id: String) -> void:
	args["pieza"] = id
	args["cable"] = -1
	args["primer_borne"] = ""
	_elegir_pestana("pieza")
	_actualizar_marcas()


func _al_tocar_cable(indice: int) -> void:
	if args["medicion"] == "pinza":
		_abrazar_cable(indice)
		return
	args["cable"] = indice
	args["pieza"] = ""
	_elegir_pestana("pieza")
	_actualizar_marcas()


func _al_tocar_fondo() -> void:
	args["primer_borne"] = ""
	args["pieza"] = ""
	args["cable"] = -1
	_estado.text = ""
	_actualizar_marcas()


func _actualizar_marcas() -> void:
	vista.borne_marcado = args["primer_borne"]
	vista.punta_roja = args["roja"]
	vista.punta_negra = args["negra"]
	vista.pieza_marcada = args["pieza"]
	vista.cable_marcado = args["cable"]
	vista.cables_pinza = args.get("pinza_cables", [])
	vista.queue_redraw()


func _process(delta: float) -> void:
	if mesa == null or vista == null:
		return
	if _cuadros_encuadre > 0:
		_cuadros_encuadre -= 1
		vista.encuadrar()
	_avanzar_simulacion(delta)
	if frente != null and frente.visible:
		frente.queue_redraw()
	_hasta_lectura -= delta
	if _hasta_lectura <= 0.0:
		_hasta_lectura = 1.0 / LECTURAS_POR_SEGUNDO
		_actualizar_lectura()


func _avanzar_simulacion(delta: float) -> void:
	_acumulado += delta
	var pasos := mini(int(_acumulado / SimSimulacion.PASO_S), 3)
	if pasos > 0:
		_acumulado = 0.0
		mesa.avanzar(pasos)
		_revisar_eventos()
		vista.queue_redraw()


func _revisar_eventos() -> void:
	var textos: Dictionary = raiz.contenido.leer("taller.json").get("consecuencias", {})
	for e: Dictionary in mesa.eventos_nuevos():
		vista.mostrar_evento(e["tipo"], e["componente"])
		var c: Dictionary = textos.get(e["tipo"], {})
		if not c.is_empty():
			var quien: String = e["componente"]
			_mostrar_aviso("%s (%s)" % [c["titulo"], quien] if mesa.piezas.has(quien) else c["titulo"], c["texto"], "alarma")


