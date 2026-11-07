extends Animacion
## Práctica de estrella o delta con la simulación real: se elige la placa y la conexión,
## se energiza y se observa el resultado. Los textos vienen del JSON.

const PASOS_POR_FOTOGRAMA := 8
const DURACION_MAXIMA_S := 900.0
const COLORES := {"correcto": Color("23804a"), "exceso": Color("a8352a"), "defecto": Color("a56a12")}

var _placa := "220_380"
var _conexion := "estrella"
var _ensayo: EnsayoConexion
var _resultado: Label
var _energizar: Button
var _terminado := false


func preparar() -> void:
	lienzo.custom_minimum_size.y = 150.0
	var grupo_placa := ButtonGroup.new()
	var grupo_conexion := ButtonGroup.new()
	add_child(_fila_opciones(grupo_placa, [["220Δ / 380Y", "220_380"], ["380Δ / 660Y", "380_660"]], _elegir_placa, _placa))
	add_child(_fila_opciones(grupo_conexion, [["Estrella (Y)", "estrella"], ["Delta (Δ)", "delta"]], _elegir_conexion, _conexion))
	_energizar = Button.new()
	_energizar.text = "Energizar"
	_energizar.mouse_filter = Control.MOUSE_FILTER_PASS
	_energizar.pressed.connect(_alternar)
	add_child(_energizar)
	_resultado = Label.new()
	_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_resultado)


func _fila_opciones(grupo: ButtonGroup, opciones: Array, al_elegir: Callable, activa: String) -> Control:
	var fila := HBoxContainer.new()
	for o: Array in opciones:
		var b := Button.new()
		b.text = o[0]
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = o[1] == activa
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(al_elegir.bind(o[1]))
		fila.add_child(b)
	return fila


func _elegir_placa(id: String) -> void:
	_placa = id
	_reiniciar()


func _elegir_conexion(id: String) -> void:
	_conexion = id
	_reiniciar()


func _reiniciar() -> void:
	_ensayo = null
	_terminado = false
	_energizar.text = "Energizar"
	_resultado.text = ""


func _alternar() -> void:
	if _ensayo != null:
		_reiniciar()
		return
	_ensayo = EnsayoConexion.new(_placa, _conexion)
	_energizar.text = "Desconectar y reiniciar"


func _process(delta: float) -> void:
	super(delta)
	if _ensayo == null or _terminado:
		return
	_ensayo.avanzar(PASOS_POR_FOTOGRAMA)
	# Una conexión incorrecta con sobrecarga moderada tarda minutos en disparar: no debe
	# darse por buena antes de tiempo.
	var correcta := EnsayoConexion.diagnostico(_placa, _conexion) == "correcto"
	var limite: float = params["duracion_s"] if correcta else DURACION_MAXIMA_S
	if _ensayo.disparo() or _ensayo.sim.tiempo >= limite:
		_terminado = true
		_mostrar_resultado()


func _mostrar_resultado() -> void:
	var clave := EnsayoConexion.diagnostico(_placa, _conexion)
	_resultado.text = params["mensajes"][clave]


func dibujar() -> void:
	fondo()
	var tam := lienzo.size
	var clave := EnsayoConexion.diagnostico(_placa, _conexion)
	if _ensayo == null:
		texto(tam / 2.0, "Elija la placa y la conexión, y energice", 16)
		return
	var m := _ensayo.motor()
	var filas := [
		"Tensión por devanado: %s V" % TextoTecnico.numero(_ensayo.v_devanado, 0),
		"Corriente de línea: %s A" % TextoTecnico.numero(_ensayo.corriente, 1),
		"Velocidad: %s rpm" % TextoTecnico.numero(absf(m.rpm()), 0),
		"Temperatura: %s °C" % TextoTecnico.numero(m.temperatura(), 0),
	]
	for i in filas.size():
		texto(Vector2(16.0, 22.0 + i * 25.0), filas[i], 16, Tema.TINTA, false)
	var estado := "En ensayo"
	var color: Color = Tema.TINTA
	if _ensayo.quemado():
		estado = "Motor quemado"
		color = COLORES["exceso"]
	elif _ensayo.disparo():
		estado = "Relé térmico disparado"
		color = COLORES["exceso"]
	elif _terminado:
		estado = "Funcionamiento normal"
		color = COLORES[clave]
	texto(Vector2(16.0, tam.y - 16.0), estado, 16, color, false)
