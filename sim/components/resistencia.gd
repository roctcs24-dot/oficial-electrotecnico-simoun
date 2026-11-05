class_name SimResistencia
extends SimComponente
## Resistencia de dos bornes A-B, para practicar la ley de Ohm.


func tipo() -> String:
	return "resistencia"


func _params_por_defecto() -> Dictionary:
	return {"ohm": 100.0}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("A"), n("B"), params["ohm"])
