class_name SimPT100
extends SimComponente
## Sonda de resistencia PT100 entre 1 y 2: 100 Ω a 0 °C y unos 0,385 Ω más por grado
## (IEC 60751). La temperatura sale de params "temperatura" o, con "origen", de un proceso.
## "averia": "abierto" (cable o sonda cortados) o "corto".

const ALFA := 0.00385
const R_CORTO := 0.1


func tipo() -> String:
	return "pt100"


func _params_por_defecto() -> Dictionary:
	return {"r0": 100.0, "temperatura": 20.0, "origen": {}, "averia": ""}


func temperatura() -> float:
	var origen: Dictionary = params["origen"]
	return lectura_proceso(origen) if not origen.is_empty() else float(params["temperatura"])


func resistencia() -> float:
	return float(params["r0"]) * (1.0 + ALFA * temperatura())


func estampar(e: SimEstampa) -> void:
	match params["averia"]:
		"abierto":
			return
		"corto":
			e.impedancia(n("1"), n("2"), R_CORTO)
		_:
			e.impedancia(n("1"), n("2"), resistencia())
