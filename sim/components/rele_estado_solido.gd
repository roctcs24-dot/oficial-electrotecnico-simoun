class_name SimReleEstadoSolido
extends SimComponente
## Relé de estado sólido: control en continua por 3 (+) y 4 (−), y carga de alterna entre 1 y 2.
## Conduce con 3 a 32 V de control y la polaridad correcta. Abierto deja pasar unos miliamperios
## de fuga: con el multímetro de alta impedancia se mide tensión en la carga aunque esté
## «apagado». Una sobrecorriente lo daña en corto: la carga queda siempre conectada.

const R_AVERIA := 0.05


func tipo() -> String:
	return "rele_estado_solido"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"v_min_control": 3.0, "v_max_control": 32.0, "r_control": 2000.0, "r_on": 0.05, "r_off": 40000.0, "i_max": 25.0}


func _estado_inicial() -> Dictionary:
	return {"conduce": false, "quemado": false}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("3"), n("4"), params["r_control"])
	var r: float = R_AVERIA if estado["quemado"] else (params["r_on"] if estado["conduce"] else params["r_off"])
	e.impedancia(n("1"), n("2"), r)


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var v := tension_dc(sol, "3", "4")
	var conduce: bool = v >= float(params["v_min_control"]) and v <= float(params["v_max_control"])
	if conduce == estado["conduce"]:
		return false
	estado["conduce"] = conduce
	return true


func corriente_carga(sol: SimSolver.Solucion) -> float:
	var r: float = R_AVERIA if estado["quemado"] else (params["r_on"] if estado["conduce"] else params["r_off"])
	return tension(sol, "1", "2") / r


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"]:
		return
	var i := corriente_carga(sol)
	if i > float(params["i_max"]):
		estado["quemado"] = true
		avisar("ssr_quemado", {"corriente_a": i})
