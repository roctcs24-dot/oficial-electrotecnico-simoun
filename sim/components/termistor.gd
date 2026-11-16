class_name SimTermistor
extends SimComponente
## Termistor de bornes 1-2: su resistencia cambia mucho con la temperatura.
## - NTC (negative temperature coefficient): baja al calentarse, R = R25 · e^(B·(1/T − 1/298 K)).
##   Sonda típica de 10 kΩ a 25 °C con B = 3950 K.
## - PTC (positive temperature coefficient): la de un motor, metida en el bobinado. Casi
##   constante en frío y sube de golpe cerca de su temperatura nominal de respuesta (TNF). La
##   curva sigue los límites de DIN 44081 (≤ 250 Ω hasta TNF − 20 °C, ≤ 550 Ω a TNF − 5 °C,
##   ≥ 1330 Ω a TNF + 5 °C y ≥ 4000 Ω a TNF + 15 °C); "sensores" pone varias en serie, como
##   las tres de un motor trifásico.
## Averías: abierto (cable o sonda cortada) y corto.

const T0_K := 273.15
## Curva de una PTC: grados sobre la TNF y ohmios de cada sonda. Entre puntos, logarítmica.
const CURVA_PTC := [[-150.0, 80.0], [-20.0, 150.0], [-5.0, 400.0], [5.0, 1500.0], [15.0, 5000.0], [30.0, 10000.0]]
const R_CORTO := 0.2


func tipo() -> String:
	return "termistor"


func _params_por_defecto() -> Dictionary:
	return {"tipo": "ntc", "r25": 10000.0, "beta": 3950.0, "tnf": 130.0, "sensores": 1, "aislamiento_mohm": 0.0}


func _estado_inicial() -> Dictionary:
	return {"temperatura_c": 25.0, "abierto": false, "corto": false}


## Resistencia a una temperatura, sin averías.
func ohmios_a(temperatura_c: float) -> float:
	if str(params["tipo"]) == "ptc":
		return _ptc(temperatura_c - float(params["tnf"])) * float(params["sensores"])
	var t_k := temperatura_c + T0_K
	return float(params["r25"]) * exp(float(params["beta"]) * (1.0 / t_k - 1.0 / (25.0 + T0_K)))


func ohmios() -> float:
	return ohmios_a(float(estado["temperatura_c"]))


static func _ptc(sobre_tnf: float) -> float:
	if sobre_tnf <= CURVA_PTC[0][0]:
		return CURVA_PTC[0][1]
	for i in range(1, CURVA_PTC.size()):
		var b: Array = CURVA_PTC[i]
		if sobre_tnf <= b[0]:
			var a: Array = CURVA_PTC[i - 1]
			var f: float = (sobre_tnf - a[0]) / (b[0] - a[0])
			return a[1] * pow(b[1] / a[1], f)
	return CURVA_PTC[-1][1]


func estampar(e: SimEstampa) -> void:
	var aislamiento := float(params["aislamiento_mohm"])
	if aislamiento > 0.0:
		e.impedancia(n("1"), SimSolver.TIERRA, aislamiento * 1e6)
	if estado["corto"]:
		e.impedancia(n("1"), n("2"), R_CORTO)
	elif not estado["abierto"]:
		e.impedancia(n("1"), n("2"), ohmios())
