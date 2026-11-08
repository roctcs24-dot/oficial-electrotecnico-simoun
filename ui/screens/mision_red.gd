extends "res://ui/screens/red_alarmas.gd"
## Una misión de Guardia en la red del puesto de alarmas: los paneles del puesto, de la red y de
## la pantalla local, con una pestaña Misión con el reporte, el procedimiento, el diagnóstico,
## el trabajo, la prueba en servicio y el libro. Cada acción en los paneles se comunica a la
## misión, que vigila el procedimiento. El estado vive en args para sobrevivir al giro.

const LIMITE_OBSERVACION_MS := 6

var mision: MisionRed
var _panel: PanelMision


func construir() -> void:
	_preparar()
	if mision.fin == "accidente":
		_construir_informe_mision(mision, _repetir)
		return
	if mision.fin == "completada":
		_construir_resultado_mision(mision, _repetir)
		return
	super()


func _preparar() -> void:
	if not args.has("mision"):
		var nueva := MisionRed.new(raiz.contenido, args["id"])
		args["mision"] = nueva
		args["red"] = nueva.red
		args["puesto"] = nueva.puesto
		args["hmi"] = nueva.hmi
		args["pestana"] = args.get("pestana_inicial", "mision")
		args["seleccion"] = "PA"
		args["pagina_hmi"] = "principal"
		args["medida"] = ""
		args["prueba_hasta"] = -1.0
		args["oculta"] = ""
	mision = args["mision"]
	_panel = PanelMision.new(self, mision)
	super()


func _titulo() -> String:
	return mision.datos["titulo"]


func _cabecera(titulo: String, _nota := "") -> void:
	super(titulo, mision.datos["equipo"])


func _pestanas() -> Array:
	var lista: Array = [["mision", "Misión"]]
	for p: Array in PESTANAS:
		if p[0] != "averias":
			lista.append(p)
	return lista


func _panel_extra(columna: VBoxContainer, pestana: String) -> void:
	if pestana == "mision":
		_panel.construir(columna, _repetir)


func _al_actuar(accion: String, detalle := {}) -> void:
	mision.registrar(accion, detalle)


func _nombre_equipo(id: String) -> String:
	return id


func _repetir() -> void:
	for clave in ["mision", "red", "puesto", "hmi", "pestana", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()


## Muestra el aviso de una orden de la misión; un final rehace la pantalla entera.
func _atender(aviso: Dictionary) -> void:
	if not mision.fin.is_empty():
		_registrar_final_mision(mision)
		raiz.reconstruir.call_deferred()
		return
	if not aviso.is_empty():
		_mostrar_aviso(aviso["titulo"], aviso["texto"])
	_comprobar_firma()


func _calcular_firma() -> String:
	var base := super()
	if args["pestana"] == "mision":
		base += "|%s|%d|%d" % [_panel.firma(), mision.mediciones.size(), mision.faltas.size()]
	return base


func _avanzar(delta: float) -> void:
	if not mision.fin.is_empty():
		return
	var aviso := _panel.avanzar(LIMITE_OBSERVACION_MS, delta, delta)
	if not aviso.is_empty() or not mision.fin.is_empty():
		_atender(aviso)


func _actualizar() -> void:
	super()
	if args["pestana"] == "mision":
		_panel.actualizar()
