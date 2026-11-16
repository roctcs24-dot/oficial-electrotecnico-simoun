class_name SimFinalCarrera
extends SimComponente
## Final de carrera (limit switch) de palanca con rodillo: un contacto NA 13-14 y uno NC 21-22 de
## apertura positiva. Al empujar la leva el rodillo, el NA cierra y el NC abre; al soltarlo, un
## resorte los devuelve. Avería: "atascado", la palanca no vuelve y queda accionado.


func tipo() -> String:
	return "final_carrera"


func _params_por_defecto() -> Dictionary:
	return {"atascado": false}


func _estado_inicial() -> Dictionary:
	return {"accionado": false}


func accionado() -> bool:
	return estado["accionado"] or params["atascado"]


func estampar(e: SimEstampa) -> void:
	if accionado():
		e.enlace(n("13"), n("14"))
	else:
		e.enlace(n("21"), n("22"))
