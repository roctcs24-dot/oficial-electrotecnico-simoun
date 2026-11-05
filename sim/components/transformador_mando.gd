class_name SimTransformadorMando
extends SimComponente
## Transformador de mando. El secundario sigue al primario de la resolución
## anterior; la carga del secundario no se refleja en el primario.

var _v_sec := Cx.new()


func tipo() -> String:
	return "transformador_mando"


func _params_por_defecto() -> Dictionary:
	return {
		"v_primario": 440.0,
		"v_secundario": 110.0,
		"r_primario": 40.0,
		"x_primario": 2000.0,
		"r_secundario": 0.5,
		"x_secundario": 0.5,
	}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("H1"), n("H2"), params["r_primario"], params["x_primario"])
	e.fuente(n("X1"), n("X2"), _v_sec, params["r_secundario"], params["x_secundario"])


func asentar(sol: SimSolver.Solucion) -> bool:
	var nuevo := sol.entre(n("H1"), n("H2")).escala(params["v_secundario"] / params["v_primario"])
	var cambio := nuevo.menos(_v_sec).modulo() > 0.2
	_v_sec = nuevo
	return cambio
