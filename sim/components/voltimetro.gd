class_name SimVoltimetro
extends SimComponente
## Voltímetro de cuadro (voltmeter) de hierro móvil, de 0 a 500 V, entre dos fases. Bornes 1-2.
## Va protegido por sus fusibles: por debajo de 1000 V no necesita transformador de tensión.


func tipo() -> String:
	return "voltimetro"


func _params_por_defecto() -> Dictionary:
	return {"escala_v": 500.0, "r": 200000.0}


func _estado_inicial() -> Dictionary:
	return {"bobina_cortada": false}


func estampar(e: SimEstampa) -> void:
	if not estado["bobina_cortada"]:
		e.impedancia(n("1"), n("2"), params["r"])


func leer(sol: SimSolver.Solucion, _magnitud := "") -> Dictionary:
	var escala := float(params["escala_v"])
	var v := 0.0 if estado["bobina_cortada"] else tension(sol, "1", "2")
	return {"valor": minf(v, 1.2 * escala), "unidad": "V", "fuera_de_rango": v > 1.2 * escala, "averia": ""}
