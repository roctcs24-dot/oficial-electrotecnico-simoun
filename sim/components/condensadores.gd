class_name SimCondensadores
extends SimComponente
## Batería de condensadores de compensación (power factor correction capacitors) en delta, entre
## L1-L2, L2-L3 y L3-L1, con su resistencia de descarga en paralelo con cada rama. Da la
## potencia reactiva q_kvar a la tensión nominal. En continua, como la ve el óhmetro o el
## megóhmetro, solo quedan las resistencias de descarga.
## perdida: fracción de capacidad perdida, como la de un condensador seco o hinchado.

const RAMAS := [["L1", "L2"], ["L2", "L3"], ["L3", "L1"]]


func tipo() -> String:
	return "condensadores"


func _params_por_defecto() -> Dictionary:
	return {"q_kvar": 25.0, "v_linea": SimRed.V_LINEA, "r_descarga_kohm": 220.0, "aislamiento_mohm": 0.0}


func _estado_inicial() -> Dictionary:
	return {"perdida": 0.0, "rama_abierta": "", "descarga_cortada": false}


## Reactancia de cada rama en delta a la frecuencia de la red.
func reactancia_rama() -> float:
	var q_rama: float = float(params["q_kvar"]) * 1000.0 / 3.0 * (1.0 - float(estado["perdida"]))
	return INF if q_rama <= 0.0 else pow(float(params["v_linea"]), 2.0) / q_rama


func estampar(e: SimEstampa) -> void:
	if float(params["aislamiento_mohm"]) > 0.0:
		e.impedancia(n("L1"), SimSolver.TIERRA, float(params["aislamiento_mohm"]) * 1e6)
	var xc := reactancia_rama()
	for rama in RAMAS:
		if not estado["descarga_cortada"]:
			e.impedancia(n(rama[0]), n(rama[1]), float(params["r_descarga_kohm"]) * 1000.0)
		var nombre := "%s-%s" % [rama[0], rama[1]]
		if not e.dc and nombre != str(estado["rama_abierta"]) and xc < INF:
			e.impedancia(n(rama[0]), n(rama[1]), 0.0, -xc)
