extends Pantalla
## Un sistema del barco con sus modos. Solo se muestran los que tienen contenido, cada uno con
## su avance y el color del sistema.

const MODOS := [
	["aprender", "Aprender", "Lecciones cortas y fichas de equipos"],
	["taller", "Taller", "Banco de pruebas libre"],
	["guardia", "Guardia", "Misiones de avería a bordo"],
	["examen", "Examen", "Preguntas y casos prácticos"],
]


func construir() -> void:
	var s := raiz.contenido.sistema(args["id"])
	_cabecera(s.get("nombre", "Sistema"), s.get("resumen", ""))
	var desplazable := _desplazable()
	add_child(desplazable)
	var rejilla := GridContainer.new()
	rejilla.columns = 1 if raiz.vertical else 2
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", 10)
	rejilla.add_theme_constant_override("v_separation", 10)
	desplazable.add_child(rejilla)
	var modos: Dictionary = s.get("modos", {})
	var color := Tema.color_area(s)
	for m: Array in MODOS:
		if not modos.has(m[0]):
			continue
		var detalle: String = modos[m[0]].get("detalle", m[2])
		var opciones := {"color": color}
		var estado := ""
		var parte := _avance_modo(s, m[0])
		if parte[1] > 0:
			opciones["avance"] = Avance.fraccion(parte)
			opciones["hecho"] = parte[0] == parte[1]
			estado = "%d de %d" % parte
		var f := _fila(m[1], detalle, _abrir_modo.bind(m[0]), m[0], estado, true, opciones)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(f)


## [hechos, total] de un modo; [0, 0] si no se cuenta, como el Taller.
func _avance_modo(s: Dictionary, modo: String) -> Array[int]:
	match modo:
		"aprender":
			return Avance.aprender(s, raiz.partida)
		"guardia":
			return Avance.misiones(s, raiz.partida)
		"examen":
			return Avance.examenes(s, raiz.partida)
	return [0, 0]


## Un modo puede abrir otra pantalla, como el Taller del cuadro principal.
func _abrir_modo(modo: String) -> void:
	var s := raiz.contenido.sistema(args["id"])
	raiz.ir_a(s["modos"][modo].get("pantalla", modo), {"id": args["id"]})
