class_name SimCondensadorElectrico
extends SimComponente
## Condensador (capacitor) de bornes + y −. En alterna es una reactancia Xc = 1 / (2π·f·C); en
## continua, una vez cargado, solo deja pasar su fuga. "polarizado" es un electrolítico: con la
## tensión al revés, o con alterna, se calienta, se hincha y queda en corto.
## Averías: "perdida" (fracción de capacidad perdida, como un condensador seco), en corto y
## abierto (terminal suelto por dentro).

const R_CORTO := 0.5
const V_INVERSA_MAX := 1.5


func tipo() -> String:
	return "condensador_electrico"


func _params_por_defecto() -> Dictionary:
	return {"uf": 20.0, "v_nominal": 450.0, "polarizado": false, "r_fuga_mohm": 1000.0}


func _estado_inicial() -> Dictionary:
	return {"perdida": 0.0, "corto": false, "abierto": false}


func usa_continua() -> bool:
	return bool(params["polarizado"])


func capacidad_uf() -> float:
	if estado["abierto"]:
		return 0.0
	return float(params["uf"]) * (1.0 - clampf(float(estado["perdida"]), 0.0, 1.0))


## Reactancia a la frecuencia de la red, o INF si no queda capacidad.
func reactancia() -> float:
	var c := capacidad_uf() * 1e-6
	return INF if c <= 0.0 else 1.0 / (TAU * SimRed.F_HZ * c)


func estampar(e: SimEstampa) -> void:
	if estado["corto"]:
		e.impedancia(n("+"), n("-"), R_CORTO)
		return
	if estado["abierto"]:
		return
	e.impedancia(n("+"), n("-"), float(params["r_fuga_mohm"]) * 1e6)
	var xc := reactancia()
	if not e.dc and xc < INF:
		e.impedancia(n("+"), n("-"), 0.0, -xc)


## Corriente eficaz de alterna que pasa por el condensador.
func corriente(sol: SimSolver.Solucion) -> float:
	if estado["corto"]:
		return tension(sol, "+", "-") / R_CORTO
	var xc := reactancia()
	return 0.0 if xc == INF else tension(sol, "+", "-") / xc


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["corto"]:
		return
	var v_ac := tension(sol, "+", "-")
	var v_dc := tension_dc(sol, "+", "-") if sol.dc != null else 0.0
	var al_reves := bool(params["polarizado"]) and (v_dc < -V_INVERSA_MAX or v_ac > V_INVERSA_MAX)
	var sobretension := maxf(v_ac, absf(v_dc)) > float(params["v_nominal"]) * 1.15
	if al_reves or sobretension:
		estado["corto"] = true
		avisar("condensador_quemado", {"tension_v": v_dc if absf(v_dc) > v_ac else v_ac})
