class_name SimConsumidor
extends SimComponente
## Consumidor monofásico resistivo entre A y B, como un circuito de alumbrado, de tomas o de
## una cocina, con su borne de protección PE unido a la carcasa. Averías: "fuga_ohm", la
## resistencia de una fuga del conductor A a la carcasa (humedad, aislamiento dañado), y
## "corto": un cortocircuito entre A y B, como un portalámparas quemado.

const R_CORTO := 0.02


func tipo() -> String:
	return "consumidor"


func _params_por_defecto() -> Dictionary:
	return {"ohm": 20.0, "fuga_ohm": 1e12, "corto": false, "v_nominal": 110.0, "pieza": "consumidor_alumbrado"}


func _estado_inicial() -> Dictionary:
	return {"alimentado": false}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("A"), n("B"), R_CORTO if params["corto"] else float(params["ohm"]))
	if float(params["fuga_ohm"]) < 1e11:
		e.impedancia(n("A"), n("PE"), float(params["fuga_ohm"]))


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	estado["alimentado"] = tension(sol, "A", "B") >= 0.8 * float(params["v_nominal"])


## Potencia que consume con la tensión de ahora, en vatios.
func potencia(sol: SimSolver.Solucion) -> float:
	var v := tension(sol, "A", "B")
	return v * v / float(params["ohm"])
