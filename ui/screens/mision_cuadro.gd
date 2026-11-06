extends "res://ui/screens/cuadro.gd"
## Una misión de Guardia en el cuadro principal: los paneles del cuadro y una pestaña Misión con
## el reporte, el procedimiento, el diagnóstico, el trabajo, la prueba en servicio y el libro.
## Los mandos pasan por la misión, que vigila el procedimiento. El estado vive en args para
## sobrevivir al giro del celular.

const LIMITE_OBSERVACION_MS := 6

var mision: MisionCuadro
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
		var nueva := MisionCuadro.new(raiz.contenido, args["id"])
		args["mision"] = nueva
		args["pestana"] = args.get("pestana_inicial", "mision")
		args["sincronizar"] = "G2"
		args["eventos"] = nueva.sim.eventos.size()
	mision = args["mision"]
	_panel = PanelMision.new(self, mision)
	datos = mision.panel
	sim = mision.sim
	operador = mision


func _poner_cabecera() -> void:
	_cabecera(mision.datos["titulo"], mision.datos["equipo"])


func _pestanas_extra() -> Array:
	return [["mision", "Misión"]]


func _llenar_zona(columna: VBoxContainer, id: String) -> void:
	if id == "mision":
		_panel.construir(columna, _repetir)
	else:
		super(columna, id)


## En una misión no se reinicia la práctica: se repite la misión desde su pestaña.
func _pie_barras(_columna: VBoxContainer) -> void:
	pass


func _permite_reparar() -> bool:
	return false


## Lo que se bloquea: el arranque de un grupo, o el interruptor de una salida.
func _nombre_equipo(id: String) -> String:
	for c: Dictionary in datos["cargas"]:
		if c["id"] == id:
			var nombre: String = c["nombre"]
			return "%s (%s)" % [id, nombre.substr(0, 1).to_lower() + nombre.substr(1)]
	return "el arranque de %s" % id


func _repetir() -> void:
	for clave in ["mision", "pestana", "sincronizar", "eventos", "ganados", "respuestas"]:
		args.erase(clave)
	raiz.reconstruir()


# --- Resultados y tiempo ---

## Un final de misión rehace la pantalla entera para mostrar el informe o el resultado.
func _atender(aviso: Dictionary) -> void:
	if not mision.fin.is_empty():
		_registrar_final_mision(mision)
		raiz.reconstruir.call_deferred()
		return
	super(aviso)


func _calcular_firma() -> String:
	return "%s|%s" % [super(), _panel.firma()]


func _avanzar(pasos: int) -> void:
	if not mision.fin.is_empty():
		return
	var aviso := _panel.avanzar(LIMITE_OBSERVACION_MS, pasos * SimSimulacion.PASO_S, SimSimulacion.PASO_S)
	if not aviso.is_empty() or not mision.fin.is_empty():
		_atender(aviso)


func _actualizar() -> void:
	super()
	_panel.actualizar()
