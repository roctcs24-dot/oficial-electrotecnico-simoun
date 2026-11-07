class_name SimSeta
extends SimComponente
## Pulsador de parada de emergencia de seta (emergency stop): al pulsarlo queda enclavado y abre
## su contacto 11-12; el 13-14 cierra para dar alarma. Se libera girando la seta.


func tipo() -> String:
	return "seta"


func _estado_inicial() -> Dictionary:
	return {"enclavada": false}


func pulsar() -> void:
	estado["enclavada"] = true


func liberar() -> void:
	estado["enclavada"] = false


func estampar(e: SimEstampa) -> void:
	if estado["enclavada"]:
		e.enlace(n("13"), n("14"))
	else:
		e.enlace(n("11"), n("12"))
