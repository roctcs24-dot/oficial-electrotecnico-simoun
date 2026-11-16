class_name SimPuertaLogica
extends SimComponente
## Puerta lógica CMOS (logic gate) de entradas A y B, salida Y y alimentación VCC-GND. "tipo":
## and, or, nand, nor, xor o not (solo A). Una entrada es 1 por encima del 70 % de VCC y 0 por
## debajo del 30 %; en medio, o al aire, el nivel es indefinido y la salida queda a media
## tensión, como en la realidad una entrada CMOS sin conectar. Avería: salida quemada, pegada a 0.

const R_ENTRADA := 1e9
const ALTO := 0.7
const BAJO := 0.3
const TIPOS := ["and", "or", "nand", "nor", "xor", "not"]


func tipo() -> String:
	return "puerta_logica"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"tipo": "and", "r_out": 50.0, "r_alimentacion": 5000.0}


func _estado_inicial() -> Dictionary:
	return {"vcc": 0.0, "salida": 0, "salida_quemada": false}


## 1, 0 o −1 (indefinido) de una entrada.
func nivel(v: float, vcc: float) -> int:
	if vcc < 1.0:
		return 0
	if v >= ALTO * vcc:
		return 1
	return 0 if v <= BAJO * vcc else -1


## Salida lógica para unas entradas: 1, 0 o −1 si alguna está indefinida.
func logica(a: int, b: int) -> int:
	var t := str(params["tipo"])
	if a < 0 or (t != "not" and b < 0):
		return -1
	match t:
		"and":
			return a & b
		"or":
			return a | b
		"nand":
			return 1 - (a & b)
		"nor":
			return 1 - (a | b)
		"xor":
			return a ^ b
		"not":
			return 1 - a
	return 0


func v_salida() -> float:
	var vcc := float(estado["vcc"])
	if estado["salida_quemada"] or vcc < 1.0:
		return 0.0
	match int(estado["salida"]):
		1:
			return vcc
		-1:
			return vcc / 2.0
	return 0.0


func estampar(e: SimEstampa) -> void:
	for entrada in ["A", "B"]:
		e.impedancia(n(entrada), n("VCC"), R_ENTRADA)
		e.impedancia(n(entrada), n("GND"), R_ENTRADA)
	e.impedancia(n("VCC"), n("GND"), params["r_alimentacion"])
	e.fuente_continua(n("Y"), n("GND"), v_salida(), params["r_out"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var vcc := tension_dc(sol, "VCC", "GND")
	var salida := logica(nivel(tension_dc(sol, "A", "GND"), vcc), nivel(tension_dc(sol, "B", "GND"), vcc))
	var cambio: bool = salida != int(estado["salida"]) or absf(vcc - float(estado["vcc"])) > 0.01
	estado["vcc"] = vcc
	estado["salida"] = salida
	return cambio
