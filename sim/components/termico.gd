class_name SimTermico
extends RefCounted
## Memoria térmica por fase, compartida por el relé térmico y el guardamotor.
## Se ajusta a clase 10: unos 6 s a 7,2 × Ir, no dispara a 1,05 × Ir y unos
## 10 min a 1,2 × Ir. Valores simplificados para enseñar: verificar con el catálogo.

const TAU_S := 240.0
const UMBRAL := 1.3225


## Devuelve la memoria actualizada de una fase.
static func actualizar(memoria: float, corriente: float, ajuste: float, dt: float) -> float:
	var objetivo := pow(corriente / ajuste, 2.0)
	return memoria + (objetivo - memoria) * (1.0 - exp(-dt / TAU_S))
