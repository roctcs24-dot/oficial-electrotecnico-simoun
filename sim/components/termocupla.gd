class_name SimTermocupla
extends SimComponente
## Termocupla tipo K, + y −: da unos 41 µV por grado de diferencia entre la unión caliente y
## la fría, la de los bornes del instrumento. Es una tensión de milivoltios con polaridad:
## conectada al revés, el instrumento lee la temperatura bajando. "averia": "abierto".

const UV_POR_GRADO := 41.0
const R_HILOS := 10.0


func tipo() -> String:
	return "termocupla"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"temperatura": 20.0, "origen": {}, "t_union_fria": 25.0, "averia": ""}


func temperatura() -> float:
	var origen: Dictionary = params["origen"]
	return lectura_proceso(origen) if not origen.is_empty() else float(params["temperatura"])


func fem_v() -> float:
	return UV_POR_GRADO * 1e-6 * (temperatura() - float(params["t_union_fria"]))


func estampar(e: SimEstampa) -> void:
	if params["averia"] != "abierto":
		e.fuente_continua(n("+"), n("-"), fem_v(), R_HILOS)
