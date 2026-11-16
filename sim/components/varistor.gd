class_name SimVaristor
extends SimComponente
## Varistor de óxido metálico (MOV) de bornes 1-2, en paralelo con lo que protege. A su tensión de
## servicio casi no deja pasar corriente; ante una sobretensión rápida conduce mucho y la recorta.
## La simulación trabaja con valores eficaces de 50 Hz y no modela los picos de microsegundos:
## aquí el varistor es su fuga y sus averías, y el recorte se ve en el corte animado.
## Averías: degradado (cada golpe lo deja con más fuga: "degradado_kohm"), en corto (funde el
## fusible de delante) y abierto (reventado: ya no protege, pero el equipo sigue funcionando).

const R_CORTO := 2.0


func tipo() -> String:
	return "varistor"


func _params_por_defecto() -> Dictionary:
	return {"v_nominal": 275.0, "v_1ma": 430.0, "v_recorte": 710.0, "r_fuga": 1e9}


func _estado_inicial() -> Dictionary:
	return {"degradado_kohm": 0.0, "corto": false, "abierto": false}


func estampar(e: SimEstampa) -> void:
	if estado["corto"]:
		e.impedancia(n("1"), n("2"), R_CORTO)
	elif not estado["abierto"]:
		var degradado := float(estado["degradado_kohm"])
		e.impedancia(n("1"), n("2"), degradado * 1000.0 if degradado > 0.0 else float(params["r_fuga"]))
