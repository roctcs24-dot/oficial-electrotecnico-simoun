class_name SimMasa
extends SimComponente
## Punto de masa del casco. Da un borne donde apoyar la punta al medir contra tierra.


func tipo() -> String:
	return "masa"


func estampar(e: SimEstampa) -> void:
	e.enlace(n("PE"), SimSolver.TIERRA)
