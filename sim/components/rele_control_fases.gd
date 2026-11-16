class_name SimReleControlFases
extends SimComponente
## Relé de control de fases y de tensión (phase monitoring relay): se alimenta y mide por L1,
## L2 y L3. Con la red bien, tras el retardo, su relé se activa: 11-14 cierra y 11-12 abre.
## Suelta si falta una fase, si la secuencia es inversa, si la tensión baja de umin o sube de
## umax (en tanto por uno de la nominal) o si las fases se desequilibran más que asimetria.
## Protege los motores de un arranque al revés o con dos fases. Ajustes típicos: verificar.

## Impedancia de medida entre cada par de fases.
const R_MEDIDA := 200000.0
## Por debajo de esta fracción de la nominal, la fase se da por perdida.
const FALTA := 0.6


func tipo() -> String:
	return "rele_control_fases"


func _params_por_defecto() -> Dictionary:
	return {"v_nominal": 380.0, "umin": 0.85, "umax": 1.1, "asimetria": 0.1, "retardo_s": 0.5}


func _estado_inicial() -> Dictionary:
	return {"rele": false, "falla": "sin_tension", "espera_s": 0.0}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("L1"), n("L2"), R_MEDIDA)
	e.impedancia(n("L2"), n("L3"), R_MEDIDA)
	e.impedancia(n("L3"), n("L1"), R_MEDIDA)
	if estado["rele"]:
		e.enlace(n("11"), n("14"))
	else:
		e.enlace(n("11"), n("12"))


## "" si la red está bien, o el motivo: sin_tension, falta_fase, secuencia, subtension,
## sobretension o asimetria.
func diagnostico(sol: SimSolver.Solucion) -> String:
	var v12 := sol.entre(n("L1"), n("L2"))
	var v23 := sol.entre(n("L2"), n("L3"))
	var v31 := sol.entre(n("L3"), n("L1"))
	var vn := float(params["v_nominal"])
	var modulos: Array[float] = [v12.modulo(), v23.modulo(), v31.modulo()]
	var minimo: float = modulos.min()
	var maximo: float = modulos.max()
	if maximo < 0.2 * vn:
		return "sin_tension"
	if minimo < FALTA * vn:
		return "falta_fase"
	# En secuencia directa, U23 va 120° por detrás de U12.
	if Cx.diferencia_angulo(v23.angulo(), v12.angulo()) > 0.0:
		return "secuencia"
	if minimo < float(params["umin"]) * vn:
		return "subtension"
	if maximo > float(params["umax"]) * vn:
		return "sobretension"
	if (maximo - minimo) / vn > float(params["asimetria"]):
		return "asimetria"
	return ""


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var falla := diagnostico(sol)
	var debe := falla.is_empty()
	if debe == estado["rele"]:
		estado["espera_s"] = 0.0
		estado["falla"] = falla
		return
	estado["espera_s"] += dt
	if estado["espera_s"] >= float(params["retardo_s"]):
		estado["rele"] = debe
		estado["espera_s"] = 0.0
		estado["falla"] = falla
		if not debe:
			avisar("falla_fases", {"falla": falla})
