class_name SimTimon
extends SimComponente
## Servomotor del timón visto desde lo eléctrico: dos válvulas de solenoide de 230 V (verificar), a babor (BR, X1-X2) y
## a estribor (ER, X3-X4), mueven la pala mientras la bomba hidráulica gira. SOLAS pide llevarla
## de 35° a una banda a 30° a la otra en 28 s como máximo.
## Velocidad y topes del simulador: verificar con el manual del servomotor.


func tipo() -> String:
	return "timon"


func _params_por_defecto() -> Dictionary:
	return {"bombas": ["M1"], "grados_s": 2.6, "tope": 35.0, "v_solenoide": 230.0, "r_solenoide": 4000.0}


## angulo: positivo a estribor, negativo a babor.
func _estado_inicial() -> Dictionary:
	return {"angulo": 0.0, "babor": false, "estribor": false}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("X1"), n("X2"), params["r_solenoide"])
	e.impedancia(n("X3"), n("X4"), params["r_solenoide"])


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var umbral := 0.7 * float(params["v_solenoide"])
	estado["babor"] = maxf(tension(sol, "X1", "X2"), absf(tension_dc(sol, "X1", "X2"))) >= umbral
	estado["estribor"] = maxf(tension(sol, "X3", "X4"), absf(tension_dc(sol, "X3", "X4"))) >= umbral
	var giro := 0.0
	for id: String in params["bombas"]:
		if not sim().componentes.has(id):
			continue
		var m: SimMotorTrifasico = sim().componente(id)
		giro = maxf(giro, clampf(absf(m.rpm()) / float(m.params["rpm"]), 0.0, 1.0))
	var sentido := (1.0 if estado["estribor"] else 0.0) - (1.0 if estado["babor"] else 0.0)
	var tope: float = params["tope"]
	estado["angulo"] = clampf(estado["angulo"] + sentido * giro * float(params["grados_s"]) * dt, -tope, tope)
