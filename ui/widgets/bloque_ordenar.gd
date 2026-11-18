class_name BloqueOrdenar
extends PanelContainer
## Ordenar pasos tocándolos, en una placa con relieve. Los pasos puestos quedan arriba como filas
## numeradas; los que faltan son teclas. Un toque equivocado no avanza y se cuenta como error.

signal respondido(errores: int)

var _datos := {}
var _hechos: VBoxContainer
var _pendientes: VBoxContainer
var _aviso: Label
var _explicacion: Label
var _siguiente := 0
var _errores := 0
var _columna: VBoxContainer
## Sin placa propia, para ponerla dentro de otra.
var sin_placa := false


## ya_resuelto muestra el resultado si se vuelve a una página ya completada.
## «acierto» dice, al volver, si se ordenó sin errores.
func iniciar(datos: Dictionary, ya_resuelto := false, acierto := true) -> void:
	_datos = datos
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new() if sin_placa else Relieve.estilo_placa(14.0, 12.0))
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 7)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(columna)
	_columna = columna
	columna.add_child(PiezasLeccion.rotulo("Ordene los pasos"))
	var pregunta := PiezasLeccion.etiqueta(TextoTecnico.unir_unidades(datos["pregunta"]), 17, Color.WHITE, Tema.PESO_NEGRITA)
	columna.add_child(pregunta)
	_hechos = VBoxContainer.new()
	_hechos.add_theme_constant_override("separation", 2)
	_hechos.mouse_filter = Control.MOUSE_FILTER_PASS
	columna.add_child(_hechos)
	_aviso = PiezasLeccion.etiqueta("", 14, PiezasLeccion.ROJO, Tema.PESO_FUERTE)
	_aviso.visible = false
	columna.add_child(_aviso)
	_pendientes = VBoxContainer.new()
	_pendientes.add_theme_constant_override("separation", 7)
	_pendientes.mouse_filter = Control.MOUSE_FILTER_PASS
	columna.add_child(_pendientes)
	if ya_resuelto:
		for paso: String in datos["pasos"]:
			_agregar_hecho(TextoTecnico.unir_unidades(paso))
		_siguiente = datos["pasos"].size()
		_errores = 0 if acierto else 1
		_mostrar_explicacion()
	else:
		_crear_pendientes()


func _crear_pendientes() -> void:
	var indices := range(_datos["pasos"].size())
	# Mezcla fija, para que al girar el celular no se reordene.
	var azar := RandomNumberGenerator.new()
	azar.seed = hash(_datos["tema"])
	for i in range(indices.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var temporal: int = indices[i]
		indices[i] = indices[j]
		indices[j] = temporal
	for i: int in indices:
		var b := TeclaOpcion.new(TextoTecnico.unir_unidades(_datos["pasos"][i]))
		b.pressed.connect(_tocar.bind(i, b))
		_pendientes.add_child(b)


func _tocar(indice: int, boton: Button) -> void:
	if indice != _siguiente:
		_errores += 1
		_aviso.text = "Paso fuera de secuencia. Revise qué debe ejecutarse antes."
		_aviso.visible = true
		return
	_aviso.text = ""
	_aviso.visible = false
	_agregar_hecho(boton.text)
	_pendientes.remove_child(boton)
	boton.queue_free()
	_siguiente += 1
	if _siguiente == _datos["pasos"].size():
		_mostrar_explicacion()
		respondido.emit(_errores)


func _agregar_hecho(paso: String) -> void:
	var f := FilaParte.new(_hechos.get_child_count() + 1, paso, 15)
	f.mouse_filter = Control.MOUSE_FILTER_PASS
	f.custom_minimum_size.y = 40.0
	_hechos.add_child(f)


func _mostrar_explicacion() -> void:
	var caja := PiezasLeccion.explicacion(_errores == 0, TextoTecnico.unir_unidades(_datos["explicacion"]))
	_columna.add_child(caja)
	_explicacion = caja.find_child("Texto", true, false) as Label
