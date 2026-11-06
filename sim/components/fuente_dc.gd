class_name SimFuenteDC
extends SimComponente
## Fuente de alimentación conmutada de 24 V DC: entrada de alterna L-N y salida + y −.
## Con "entrada": "ninguna" funciona sin alterna, como una batería. Ante una sobrecarga o un
## corto limita la corriente y corta la salida un momento, y vuelve a probar: así un corto no la
## destruye, pero todo lo que alimenta se apaga. "tension_pu" por debajo de 1 simula una
## fuente degradada.

const ENTRADA_MINIMA := 0.8
const SOBRECARGA_S := 0.1
const CORTE_S := 2.0
const RENDIMIENTO := 0.88
const P_VACIO_W := 3.0


func tipo() -> String:
	return "fuente_dc"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"v_salida": 24.0, "i_max": 5.0, "r_interna": 0.02, "v_entrada": 230.0, "entrada": "ac", "tension_pu": 1.0}


func _estado_inicial() -> Dictionary:
	return {"alimentada": false, "protegida": false, "corte_s": 0.0, "sobrecarga_s": 0.0, "i_salida": 0.0, "p_salida_w": 0.0, "averiada": false}


func _preparar() -> void:
	if params["entrada"] == "ninguna":
		estado["alimentada"] = true


## La salida da tensión: con alimentación, sin corte por sobrecarga y sin avería.
func activa() -> bool:
	return estado["alimentada"] and not estado["protegida"] and not estado["averiada"]


func v_salida() -> float:
	return float(params["v_salida"]) * float(params["tension_pu"]) if activa() else 0.0


func estampar(e: SimEstampa) -> void:
	e.fuente_continua(n("+"), n("-"), v_salida(), params["r_interna"])
	if params["entrada"] == "ac":
		e.impedancia(n("L"), n("N"), _r_entrada())


## La entrada consume lo que da la salida más sus pérdidas, como una resistencia equivalente.
func _r_entrada() -> float:
	var p: float = (estado["p_salida_w"] / RENDIMIENTO + P_VACIO_W) if estado["alimentada"] else P_VACIO_W
	return pow(float(params["v_entrada"]), 2.0) / p


func asentar(sol: SimSolver.Solucion) -> bool:
	if params["entrada"] != "ac":
		return false
	var alimentada: bool = tension(sol, "L", "N") >= float(params["v_entrada"]) * ENTRADA_MINIMA
	if alimentada == estado["alimentada"]:
		return false
	estado["alimentada"] = alimentada
	return true


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if estado["protegida"]:
		estado["corte_s"] += dt
		if estado["corte_s"] >= CORTE_S:
			estado["protegida"] = false
			estado["corte_s"] = 0.0
		return
	var v_bornes := tension_dc(sol, "+", "-")
	var i: float = (v_salida() - v_bornes) / float(params["r_interna"]) if activa() else 0.0
	estado["i_salida"] = maxf(i, 0.0)
	estado["p_salida_w"] = maxf(v_bornes * i, 0.0)
	if i > float(params["i_max"]) * 1.1:
		estado["sobrecarga_s"] += dt
		if estado["sobrecarga_s"] >= SOBRECARGA_S:
			estado["protegida"] = true
			estado["sobrecarga_s"] = 0.0
			estado["i_salida"] = 0.0
			avisar("fuente_sobrecarga", {"corriente_a": i})
	else:
		estado["sobrecarga_s"] = 0.0
