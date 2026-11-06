extends "res://ui/screens/planta.gd"
## Una misión de Guardia en la planta de frío: los paneles de la planta y una pestaña Misión con
## el reporte, el procedimiento, el diagnóstico, el trabajo, la prueba en servicio y el libro.
## Los mandos pasan por la misión, que vigila el procedimiento. El estado vive en args para
## sobrevivir al giro del celular.

const LIMITE_OBSERVACION_MS := 6
const NOMBRES_EQUIPO := {
	"Q1": "el guardamotor Q1 del compresor",
	"bomba_agua_mar": "el arrancador de la bomba de agua de mar",
	"bomba_salmuera": "el arrancador de la bomba de salmuera",
}

var mision: MisionPlanta
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
		var nueva := MisionPlanta.new(raiz.contenido, args["id"])
		args["mision"] = nueva
		args["pestana"] = args.get("pestana_inicial", "mision")
		args["eventos"] = nueva.sim.eventos.size()
		args["termometro"] = ""
		args["rapido"] = false
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
func _pie_mando(_columna: VBoxContainer) -> void:
	pass


func _nombre_equipo(id: String) -> String:
	return NOMBRES_EQUIPO.get(id, id)


## El termómetro también anota la lectura en el libro de la misión.
func _medir_tuberia(id: String) -> void:
	mision.medir_tuberia(id)
	super(id)
	_comprobar_firma()


func _repetir() -> void:
	for clave in ["mision", "pestana", "eventos", "termometro", "rapido", "ganados", "respuestas"]:
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
	return "%s|%s|%d" % [super(), _panel.firma(), mision.mediciones.size()]


func _avanzar(pasos: int, dt: float) -> void:
	if not mision.fin.is_empty():
		return
	var aviso := _panel.avanzar(LIMITE_OBSERVACION_MS, pasos * dt, dt)
	if not aviso.is_empty() or not mision.fin.is_empty():
		_atender(aviso)


func _actualizar() -> void:
	super()
	_panel.actualizar()
