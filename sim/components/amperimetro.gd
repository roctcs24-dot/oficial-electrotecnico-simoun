class_name SimAmperimetro
extends SimComponente
## Amperímetro de cuadro (ammeter) de 5 A, conectado al secundario S1-S2 de un transformador de
## intensidad. Su escala está graduada en amperios del primario: con un TI de 100/5 A, 5 A en la
## bobina marcan 100 A. Bornes 1-2. Con la bobina cortada, el secundario del TI queda abierto.


func tipo() -> String:
	return "amperimetro"


func _params_por_defecto() -> Dictionary:
	return {"escala_a": 100.0, "entrada_a": 5.0, "r": 0.1}


func _estado_inicial() -> Dictionary:
	return {"bobina_cortada": false, "aguja_pegada": false}


func estampar(e: SimEstampa) -> void:
	if not estado["bobina_cortada"]:
		e.impedancia(n("1"), n("2"), params["r"])


func corriente_bobina(sol: SimSolver.Solucion) -> float:
	if estado["bobina_cortada"]:
		return 0.0
	return tension(sol, "1", "2") / float(params["r"])


## Lectura de la aguja, en amperios del primario.
func leer(sol: SimSolver.Solucion, _magnitud := "") -> Dictionary:
	if estado["aguja_pegada"]:
		return {"valor": 0.0, "unidad": "A", "fuera_de_rango": false, "averia": ""}
	var escala := float(params["escala_a"])
	var a := corriente_bobina(sol) * escala / float(params["entrada_a"])
	return {"valor": minf(a, 1.2 * escala), "unidad": "A", "fuera_de_rango": a > 1.2 * escala, "averia": ""}
