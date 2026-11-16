class_name SimTermostato
extends SimComponente
## Termostato de bulbo y capilar, como los de las cámaras y la salmuera: contacto conmutado con
## común 1. Al subir la temperatura hasta la consigna, 1-4 cierra (pide frío) y 1-2 abre; al bajar
## la consigna menos el diferencial, vuelve. La temperatura del bulbo es el parámetro
## temperatura_c. Avería: "capilar_roto", el bulbo pierde la carga y el termostato se queda como
## frío: no vuelve a pedir. Ajustes típicos: verificar a bordo.


func tipo() -> String:
	return "termostato"


func _params_por_defecto() -> Dictionary:
	return {"consigna_c": -18.0, "diferencial_c": 2.0, "temperatura_c": -20.0, "capilar_roto": false}


func _estado_inicial() -> Dictionary:
	return {"pide": false}


func estampar(e: SimEstampa) -> void:
	if estado["pide"]:
		e.enlace(n("1"), n("4"))
	else:
		e.enlace(n("1"), n("2"))


func avanzar(_dt: float, _sol: SimSolver.Solucion) -> void:
	var t := float(params["temperatura_c"])
	if params["capilar_roto"]:
		estado["pide"] = false
	elif t >= float(params["consigna_c"]):
		estado["pide"] = true
	elif t <= float(params["consigna_c"]) - float(params["diferencial_c"]):
		estado["pide"] = false
