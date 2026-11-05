extends Pantalla
## Un sistema del barco con sus cuatro modos.

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
	rejilla.add_theme_constant_override("h_separation", 8)
	rejilla.add_theme_constant_override("v_separation", 8)
	desplazable.add_child(rejilla)
	var modos: Dictionary = s.get("modos", {})
	for m: Array in MODOS:
		var disponible := modos.has(m[0])
		var f := _fila(m[1], m[2] if disponible else "Próximamente", _abrir_modo.bind(m[0]), m[0], "", disponible)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(f)


func _abrir_modo(modo: String) -> void:
	raiz.ir_a(modo, {"id": args["id"]})
