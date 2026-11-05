class_name SimPulsador
extends SimComponente
## Pulsador con retorno. Bornes 13-14 si es NA, 21-22 si es NC.


func tipo() -> String:
	return "pulsador"


func _params_por_defecto() -> Dictionary:
	return {"contacto": "NA"}


func _estado_inicial() -> Dictionary:
	return {"presionado": false}


func estampar(e: SimEstampa) -> void:
	if params["contacto"] == "NA":
		if estado["presionado"]:
			e.enlace(n("13"), n("14"))
	elif not estado["presionado"]:
		e.enlace(n("21"), n("22"))
