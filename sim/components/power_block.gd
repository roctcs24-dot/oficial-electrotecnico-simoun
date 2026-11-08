class_name SimPowerBlock
extends SimComponente
## Power block de la red de cerco, movido por un motor hidráulico, con su válvula direccional
## de mando eléctrico: la bobina Y1 (bornes Y1A-Y1B) hace virar, la recogida de la red, y la Y2
## (Y2A-Y2B) arriar. Bobinas de 24 V DC.
## Sin presión de la central hidráulica no gira; con las dos bobinas a la vez, la corredera
## queda centrada y no gira. Averías de cada bobina: "abierta" (hilo cortado) o "corto"
## (espiras en cortocircuito, que pide mucha corriente a la fuente).
## Valores típicos — verificar a bordo: el buque tiene una central hidráulica de cubierta con
## motor diésel propio y once circuitos de 65 a 160 bar.

const RPM_MAX := 20.0
const CONSTANTE_TIEMPO_S := 1.5
const R_ABIERTA := 1e7
const R_CORTO := 0.6


func tipo() -> String:
	return "power_block"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"r_bobina": 22.0, "v_bobina": 24.0, "averia_y1": "", "averia_y2": "", "presion": true}


func _estado_inicial() -> Dictionary:
	return {"rpm": 0.0, "y1": false, "y2": false}


func _r(bobina: String) -> float:
	match params["averia_" + bobina]:
		"abierta":
			return R_ABIERTA
		"corto":
			return R_CORTO
	return float(params["r_bobina"])


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("Y1A"), n("Y1B"), _r("y1"))
	e.impedancia(n("Y2A"), n("Y2B"), _r("y2"))


## Una bobina mueve la corredera con al menos el 70 % de su tensión, si no está cortada.
func _excitada(sol: SimSolver.Solucion, bobina: String) -> bool:
	if params["averia_" + bobina] != "":
		return false
	var a := "Y1A" if bobina == "y1" else "Y2A"
	var b := "Y1B" if bobina == "y1" else "Y2B"
	return absf(tension_dc(sol, a, b)) >= 0.7 * float(params["v_bobina"])


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if sol.dc == null:
		return
	estado["y1"] = _excitada(sol, "y1")
	estado["y2"] = _excitada(sol, "y2")
	var objetivo := 0.0
	if params["presion"] and estado["y1"] != estado["y2"]:
		objetivo = RPM_MAX if estado["y1"] else -RPM_MAX
	var rpm: float = estado["rpm"]
	estado["rpm"] = rpm + (objetivo - rpm) * minf(dt / CONSTANTE_TIEMPO_S, 1.0)


func sentido() -> String:
	var rpm: float = estado["rpm"]
	if rpm > 2.0:
		return "virando"
	if rpm < -2.0:
		return "arriando"
	return "parado"
