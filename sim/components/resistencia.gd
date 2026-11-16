class_name SimResistencia
extends SimComponente
## Resistencia de dos bornes A-B, para practicar la ley de Ohm y como componente de una placa.
## Con "w" (potencia nominal) se calienta si disipa más de la cuenta y acaba cortada, como una
## resistencia quemada; sin "w" aguanta cualquier potencia. "factor" en el estado simula una
## resistencia que ha cambiado de valor con el calor o los años.

## Veces la potencia nominal que aguanta sin calentarse de más.
const MARGEN := 1.5
## Calor acumulado, en (P/Pn)² · s, con el que se corta.
const ENERGIA_CORTE := 20.0


func tipo() -> String:
	return "resistencia"


func _params_por_defecto() -> Dictionary:
	return {"ohm": 100.0, "w": 0.0}


func _estado_inicial() -> Dictionary:
	return {"cortada": false, "factor": 1.0, "calor": 0.0}


func ohmios() -> float:
	return float(params["ohm"]) * float(estado["factor"])


func estampar(e: SimEstampa) -> void:
	if not estado["cortada"]:
		e.impedancia(n("A"), n("B"), ohmios())


## Potencia que disipa: la de la alterna más la de la continua.
func potencia(sol: SimSolver.Solucion) -> float:
	if estado["cortada"]:
		return 0.0
	var v_ac := tension(sol, "A", "B")
	var v_dc := tension_dc(sol, "A", "B") if sol.dc != null else 0.0
	return (v_ac * v_ac + v_dc * v_dc) / ohmios()


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var w := float(params["w"])
	if w <= 0.0 or estado["cortada"]:
		return
	var veces := potencia(sol) / w
	if veces > MARGEN:
		estado["calor"] += veces * veces * dt
	else:
		estado["calor"] = maxf(0.0, float(estado["calor"]) - dt)
	if estado["calor"] >= ENERGIA_CORTE:
		estado["cortada"] = true
		avisar("resistencia_quemada", {"potencia_w": veces * w})
