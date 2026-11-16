class_name SimPotenciometro
extends SimComponente
## Potenciómetro (potentiometer): pista resistiva entre los extremos 1 y 3 y cursor 2 que se
## mueve sobre ella. "posicion" va de 0 (cursor en 1) a 1 (cursor en 3): R 1-2 = R · posicion y
## R 2-3 = R · (1 − posicion). Con 1 a 0 V y 3 a la referencia, el cursor da una fracción de la
## tensión, como la consigna de velocidad de un variador.
## Averías: el cursor gastado que no toca la pista (2 queda al aire) y la pista cortada entre el
## cursor y el extremo 3.

const R_MINIMA := 0.5


func tipo() -> String:
	return "potenciometro"


func _params_por_defecto() -> Dictionary:
	return {"ohm": 10000.0}


func _estado_inicial() -> Dictionary:
	return {"posicion": 0.5, "cursor_sin_contacto": false, "pista_cortada": false}


func r_1_2() -> float:
	return maxf(float(params["ohm"]) * clampf(float(estado["posicion"]), 0.0, 1.0), R_MINIMA)


func r_2_3() -> float:
	return maxf(float(params["ohm"]) * (1.0 - clampf(float(estado["posicion"]), 0.0, 1.0)), R_MINIMA)


func estampar(e: SimEstampa) -> void:
	if estado["cursor_sin_contacto"]:
		# La pista sigue entera entre 1 y 3, pero el cursor no la toca.
		if not estado["pista_cortada"]:
			e.impedancia(n("1"), n("3"), float(params["ohm"]))
		return
	e.impedancia(n("1"), n("2"), r_1_2())
	if not estado["pista_cortada"]:
		e.impedancia(n("2"), n("3"), r_2_3())
