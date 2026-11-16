class_name SimZener
extends SimDiodo
## Diodo Zener (Zener diode) de ánodo A a cátodo K. En directa conduce como un diodo; en inversa
## no conduce hasta su tensión Zener vz y, a partir de ahí, la mantiene casi fija: con una
## resistencia en serie, regula. Tres tramos: corte, directa y ruptura. Se daña si disipa más
## de su potencia, y queda en corto.


func tipo() -> String:
	return "zener"


func _params_por_defecto() -> Dictionary:
	return {"vf": 0.7, "r_on": 0.05, "r_off": 1e8, "vz": 12.0, "r_z": 5.0, "p_max": 1.3, "i_max": 1.0, "v_inversa": 1e6, "falla": "corto"}


func _estado_inicial() -> Dictionary:
	return {"conduce": false, "conduce_prueba": false, "ruptura": false, "ruptura_prueba": false, "quemado": false}


func estampar(e: SimEstampa) -> void:
	if estado["quemado"]:
		super.estampar(e)
		return
	var prueba: bool = e.dc and not e.continua
	var directa: bool = estado["conduce_prueba"] if prueba else estado["conduce"]
	var ruptura: bool = estado["ruptura_prueba"] if prueba else estado["ruptura"]
	if directa:
		e.caida(n("A"), n("K"), params["vf"], params["r_on"])
	elif ruptura:
		e.caida(n("K"), n("A"), params["vz"], params["r_z"])
	else:
		e.impedancia(n("A"), n("K"), params["r_off"])


## Corriente de ánodo a cátodo: negativa en ruptura.
func _corriente_zener(v: float, tramo: int) -> float:
	match tramo:
		1:
			return (v - float(params["vf"])) / float(params["r_on"])
		2:
			return -(-v - float(params["vz"])) / float(params["r_z"])
	return v / float(params["r_off"])


func _tramo_actual(prueba: bool) -> int:
	if estado["conduce_prueba" if prueba else "conduce"]:
		return 1
	if estado["ruptura_prueba" if prueba else "ruptura"]:
		return 2
	return 0


func _nuevo_tramo(v: float, tramo: int) -> int:
	if tramo == 1:
		return 1 if _corriente_zener(v, 1) > -I_ACTIVA else 0
	if tramo == 2:
		return 2 if -_corriente_zener(v, 2) > -I_ACTIVA else 0
	if v > float(params["vf"]):
		return 1
	if -v > float(params["vz"]):
		return 2
	return 0


func _poner_tramo(tramo: int, prueba: bool) -> void:
	estado["conduce_prueba" if prueba else "conduce"] = tramo == 1
	estado["ruptura_prueba" if prueba else "ruptura"] = tramo == 2


func corriente(sol: SimSolver.Solucion) -> float:
	if estado["quemado"]:
		return super.corriente(sol)
	return _corriente_zener(tension_dc(sol, "A", "K"), _tramo_actual(false))


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null or estado["quemado"]:
		return false
	var antes := _tramo_actual(false)
	var nuevo := _nuevo_tramo(tension_dc(sol, "A", "K"), antes)
	if nuevo == antes:
		return false
	_poner_tramo(nuevo, false)
	return true


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	if estado["quemado"]:
		return false
	var antes := _tramo_actual(true)
	var nuevo := _nuevo_tramo(sol.entre(n("A"), n("K")).re, antes)
	if nuevo == antes:
		return false
	_poner_tramo(nuevo, true)
	return true


func terminar_prueba() -> void:
	estado["conduce_prueba"] = false
	estado["ruptura_prueba"] = false


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"] or sol.dc == null:
		return
	var v := tension_dc(sol, "A", "K")
	var i := corriente(sol)
	if absf(v * i) > float(params["p_max"]) or i > float(params["i_max"]):
		estado["quemado"] = true
		estado["conduce"] = false
		estado["ruptura"] = false
		avisar("zener_quemado", {"corriente_a": i, "tension_v": v})
