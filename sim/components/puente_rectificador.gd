class_name SimPuenteRectificador
extends SimComponente
## Puente rectificador de cuatro diodos: alterna en ~1 y ~2, continua en + y −. El simulador
## resuelve la alterna y la continua por separado, así que el puente se modela por su efecto:
## en la continua es una fuente con la tensión media rectificada (o la de pico, con el
## condensador de filtro), y en la alterna una carga con la potencia que entrega.
## Averías: un diodo abierto deja media onda (la mitad de la media sin filtro); un diodo en corto
## cortocircuita la alterna en un semiciclo y funde el fusible de la entrada. Las dos averías son
## del diodo D1, de ~1 a +.
## Sin tensión, el óhmetro y la prueba de diodos ven los cuatro diodos por separado: D1 de ~1 a
## +, D2 de ~2 a +, D3 de − a ~1 y D4 de − a ~2.

const R_INTERNA := 0.5
const MEDIA_SIN_FILTRO := 0.9
const PICO := 1.414
const MEDIA_ONDA := 0.45
## Con filtro y media onda, el condensador se descarga el doble de tiempo: la media baja algo.
const PICO_MEDIA_ONDA := 1.30
const R_DIODO_CORTO := 0.05
const DIODOS := [["~1", "+"], ["~2", "+"], ["-", "~1"], ["-", "~2"]]
const R_ON := 0.05
const R_OFF := 1e8


func tipo() -> String:
	return "puente_rectificador"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vf": 0.7, "i_max": 10.0, "filtro": false}


func _estado_inicial() -> Dictionary:
	return {"v_ac": 0.0, "p_w": 0.0, "quemado": false, "diodo_abierto": false, "diodo_corto": false, "prueba": [false, false, false, false]}


func v_continua() -> float:
	if estado["quemado"]:
		return 0.0
	if estado["diodo_abierto"]:
		var factor_media := PICO_MEDIA_ONDA if params["filtro"] else MEDIA_ONDA
		return maxf(float(estado["v_ac"]) * factor_media - float(params["vf"]), 0.0)
	var factor := PICO if params["filtro"] else MEDIA_SIN_FILTRO
	return maxf(float(estado["v_ac"]) * factor - 2.0 * float(params["vf"]), 0.0)


func estampar(e: SimEstampa) -> void:
	if estado["quemado"]:
		return
	if e.dc and not e.continua:
		_estampar_diodos(e)
		return
	if estado["diodo_corto"]:
		e.impedancia(n("~1"), n("~2"), R_DIODO_CORTO)
	e.fuente_continua(n("+"), n("-"), v_continua(), R_INTERNA)
	var v_ac: float = estado["v_ac"]
	if v_ac > 1.0 and estado["p_w"] > 0.01:
		e.impedancia(n("~1"), n("~2"), v_ac * v_ac / float(estado["p_w"]))
	else:
		e.impedancia(n("~1"), n("~2"), 1e7)


## Lo que ve el óhmetro: cuatro diodos, cada uno en el tramo que le da la corriente de prueba.
func _estampar_diodos(e: SimEstampa) -> void:
	for i in DIODOS.size():
		var d: Array = DIODOS[i]
		if i == 0 and estado["diodo_corto"]:
			e.impedancia(n(d[0]), n(d[1]), R_DIODO_CORTO)
		elif i == 0 and estado["diodo_abierto"]:
			continue
		elif estado["prueba"][i]:
			e.caida(n(d[0]), n(d[1]), params["vf"], R_ON)
		else:
			e.impedancia(n(d[0]), n(d[1]), R_OFF)


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	if estado["quemado"]:
		return false
	var cambio := false
	for i in DIODOS.size():
		if i == 0 and (estado["diodo_corto"] or estado["diodo_abierto"]):
			continue
		var v: float = sol.entre(n(DIODOS[i][0]), n(DIODOS[i][1])).re
		var conduce: bool = estado["prueba"][i]
		var nuevo: bool = (v - float(params["vf"])) / R_ON > -1e-9 if conduce else v > float(params["vf"])
		if nuevo != conduce:
			estado["prueba"][i] = nuevo
			cambio = true
	return cambio


func terminar_prueba() -> void:
	estado["prueba"] = [false, false, false, false]


## La tensión de alterna de la entrada fija la continua: si cambia, hay que volver a resolver.
func asentar(sol: SimSolver.Solucion) -> bool:
	var v := tension(sol, "~1", "~2")
	if absf(v - float(estado["v_ac"])) <= maxf(0.01 * v, 0.05):
		return false
	estado["v_ac"] = v
	return true


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"]:
		return
	var v := tension_dc(sol, "+", "-")
	var i := (v_continua() - v) / R_INTERNA
	estado["p_w"] = maxf(v * i, 0.0)
	if i > float(params["i_max"]):
		estado["quemado"] = true
		avisar("puente_quemado", {"corriente_a": i})
