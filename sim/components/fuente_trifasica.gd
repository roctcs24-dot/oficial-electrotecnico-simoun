class_name SimFuenteTrifasica
extends SimComponente
## Barras trifásicas en estrella interna. El neutro va a tierra por una resistencia
## alta porque la red del barco es aislada: la primera falla a tierra no dispara.


func tipo() -> String:
	return "fuente_trifasica"


func _params_por_defecto() -> Dictionary:
	return {"v_linea": 440.0, "f_hz": 60.0, "r": 0.005, "x": 0.02, "neutro_mohm": 1.0}


func _estado_inicial() -> Dictionary:
	return {"activa": true}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("N"), SimSolver.TIERRA, params["neutro_mohm"] * 1e6)
	var v_fase: float = params["v_linea"] / sqrt(3.0) if estado["activa"] else 0.0
	e.fuente(n("L1"), n("N"), Cx.polar(v_fase, 0.0), params["r"], params["x"])
	e.fuente(n("L2"), n("N"), Cx.polar(v_fase, -120.0), params["r"], params["x"])
	e.fuente(n("L3"), n("N"), Cx.polar(v_fase, 120.0), params["r"], params["x"])
