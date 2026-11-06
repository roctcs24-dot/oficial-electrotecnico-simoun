extends Animacion
## Práctica de las lecciones de refrigeración con la simulación de la planta de frío.
## Escenario "ciclo": la planta parada; se arranca y se para el compresor y se ve en el esquema
## cómo cambian las presiones y las temperaturas.
## Escenario "presostatos": el compresor en marcha; se paran las bombas y se ve qué presostato
## dispara, y cuál se rearma solo y cuál a mano.
## El tiempo va cinco veces más deprisa que en la realidad para que se vea en la lección.

const ACELERACION := 5.0
const PREPARACION_S := 90

var sim: SimSimulacion
var _escenario := "ciclo"
var _esquema: EsquemaFrio
var _mandos: GridContainer
var _mensaje: Label
var _consecuencias := {}
var _eventos := 0
var _acumulado := 0.0


func preparar() -> void:
	_escenario = params.get("escenario", "ciclo")
	var datos := contenido.leer("planta.json")
	_consecuencias = datos.get("consecuencias", {})
	lienzo.custom_minimum_size.y = 150.0
	if _escenario == "ciclo":
		_esquema = EsquemaFrio.new()
		_esquema.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(_esquema)
		move_child(_esquema, 0)
	_mandos = GridContainer.new()
	_mandos.columns = 2
	_mandos.add_theme_constant_override("h_separation", 8)
	_mandos.add_theme_constant_override("v_separation", 8)
	add_child(_mandos)
	_mensaje = Label.new()
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.theme_type_variation = "Nota"
	add_child(_mensaje)
	reiniciar()


func _boton(titulo: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = titulo
	b.custom_minimum_size.y = 48.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(accion)
	return b


func reiniciar() -> void:
	sim = contenido.circuito("planta_frio")
	(sim.componente("Q1") as SimGuardamotor).accionar(true)
	sim.avanzar_tiempo(0.1)
	if _escenario == "presostatos":
		_pulsar_marcha()
		for _i in PREPARACION_S:
			sim.paso(1.0)
	_eventos = sim.eventos.size()
	_mensaje.text = _instruccion()
	_rehacer_mandos()
	_actualizar_esquema()


func _instruccion() -> String:
	if _escenario == "ciclo":
		return "Arranque el compresor y mire el esquema: la succión baja, la descarga sube y la salmuera se enfría. Después párelo: las presiones se igualan con la salmuera y con el agua de mar."
	return "El compresor enfría la salmuera. Pare una bomba y mire qué presostato dispara. Después arránquela de nuevo y compruebe cuál se rearma solo."


func _pulsar_marcha() -> void:
	sim.componente("S1").estado["presionado"] = true
	sim.avanzar_tiempo(0.3)
	sim.componente("S1").estado["presionado"] = false
	sim.avanzar_tiempo(3.0)


func en_marcha() -> bool:
	return (sim.componente("K1") as SimContactor).cerrado()


func alternar_compresor() -> void:
	if en_marcha():
		sim.componente("S0").estado["presionado"] = true
		sim.avanzar_tiempo(0.3)
		sim.componente("S0").estado["presionado"] = false
	else:
		_pulsar_marcha()
	_revisar_eventos()
	_rehacer_mandos()


func alternar_bomba(nombre: String) -> void:
	var planta: SimPlantaFrio = sim.componente("PLANTA")
	planta.estado[nombre] = not planta.estado[nombre]
	_rehacer_mandos()


func rearmar_alta() -> void:
	if not (sim.componente("PA") as SimPresostato).rearmar():
		_mensaje.text = "El presostato de alta no rearma todavía: la presión de descarga sigue alta."
	_rehacer_mandos()


func _rehacer_mandos() -> void:
	for hijo in _mandos.get_children():
		_mandos.remove_child(hijo)
		hijo.queue_free()
	var planta: SimPlantaFrio = sim.componente("PLANTA")
	_mandos.add_child(_boton("Parar el compresor" if en_marcha() else "Arrancar el compresor", alternar_compresor))
	if _escenario == "presostatos":
		_mandos.add_child(_boton("Parar el agua de mar" if planta.estado["bomba_agua_mar"] else "Arrancar el agua de mar", alternar_bomba.bind("bomba_agua_mar")))
		_mandos.add_child(_boton("Parar la salmuera" if planta.estado["bomba_salmuera"] else "Arrancar la salmuera", alternar_bomba.bind("bomba_salmuera")))
		if (sim.componente("PA") as SimPresostato).estado["disparado"]:
			_mandos.add_child(_boton("Rearmar el presostato de alta", rearmar_alta))
	_mandos.add_child(_boton("Reiniciar", reiniciar))


## Avanza la simulación con el tiempo acelerado de la práctica.
func avanzar_segundos(segundos: float) -> void:
	var resto := segundos
	while resto > 0.0:
		var dt := minf(resto, 0.25)
		sim.paso(dt)
		resto -= dt
	_revisar_eventos()


## El último evento con explicación sustituye a la instrucción.
func _revisar_eventos() -> void:
	var cambio := false
	for i in range(_eventos, sim.eventos.size()):
		var e: Dictionary = sim.eventos[i]
		var tipo: String = e["tipo"]
		if tipo == "disparo_presostato":
			tipo += "_" + str(e["detalle"].get("punto", ""))
			cambio = true
		var c: Dictionary = _consecuencias.get(tipo, {})
		if not c.is_empty():
			_mensaje.text = "%s. %s" % [c["titulo"], c["texto"]]
	_eventos = sim.eventos.size()
	if cambio:
		_rehacer_mandos()


func _process(delta: float) -> void:
	super(delta)
	if sim == null:
		return
	_acumulado += delta
	if _acumulado >= SimSimulacion.PASO_S:
		avanzar_segundos(_acumulado * ACELERACION)
		_acumulado = 0.0
	_actualizar_esquema()


func _actualizar_esquema() -> void:
	if _esquema == null:
		return
	var planta: SimPlantaFrio = sim.componente("PLANTA")
	_esquema.en_marcha = planta.compresor_en_marcha()
	_esquema.presion_succion = planta.presion("succion")
	_esquema.presion_descarga = planta.presion("descarga")


func dibujar() -> void:
	fondo()
	if sim == null:
		return
	var planta: SimPlantaFrio = sim.componente("PLANTA")
	var x := 16.0
	texto(Vector2(x, 18.0), "Succión %s bar · evapora a %s °C" % [TextoTecnico.numero(planta.presion("succion"), 2), TextoTecnico.numero(planta.temperatura("evaporacion"), 0)], 14, Tema.TINTA, false)
	texto(Vector2(x, 42.0), "Descarga %s bar · condensa a %s °C" % [TextoTecnico.numero(planta.presion("descarga"), 1), TextoTecnico.numero(planta.temperatura("condensacion"), 0)], 14, Tema.TINTA, false)
	texto(Vector2(x, 66.0), "Salmuera %s °C · aceite %s bar" % [TextoTecnico.numero(planta.temperatura("salmuera"), 1), TextoTecnico.numero(planta.presion("aceite"), 1)], 14, Tema.TINTA, false)
	var estados := PackedStringArray()
	for par in [["PA", "Alta"], ["PB", "Baja"], ["PO", "Aceite"]]:
		var p: SimPresostato = sim.componente(par[0])
		estados.append("%s %s" % [par[1], "abierto" if not p.cerrado() else "cerrado"])
	texto(Vector2(x, 90.0), "Compresor %s · tiempo ×%d" % ["en marcha" if en_marcha() else "parado", int(ACELERACION)], 14, Tema.TINTA, false)
	texto(Vector2(x, 114.0), " · ".join(estados), 14, Tema.TINTA, false)
