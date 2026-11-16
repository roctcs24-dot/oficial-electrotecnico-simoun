class_name SimTransformadorMando
extends SimComponente
## Transformador de mando. El secundario sigue al primario de la resolución
## anterior; la carga del secundario no se refleja en el primario.

var _v_sec := Cx.new()


func tipo() -> String:
	return "transformador_mando"


func _params_por_defecto() -> Dictionary:
	return {
		"v_primario": SimRed.V_LINEA,
		"v_secundario": 110.0,
		"r_primario": 40.0,
		"x_primario": 2000.0,
		"r_secundario": 0.5,
		"x_secundario": 0.5,
		"aislamiento_mohm": 0.0,
	}


## Averías: un devanado cortado no conduce; el aislamiento solo se modela si se da en params
## (contra el casco, desde H1 y desde X1), para no cambiar las redes que no lo miden.
func _estado_inicial() -> Dictionary:
	return {"primario_cortado": false, "secundario_cortado": false}


func estampar(e: SimEstampa) -> void:
	var aislamiento := float(params["aislamiento_mohm"])
	if aislamiento > 0.0:
		e.impedancia(n("H1"), SimSolver.TIERRA, aislamiento * 1e6)
		e.impedancia(n("X1"), SimSolver.TIERRA, aislamiento * 1e6)
	if not estado["primario_cortado"]:
		e.impedancia(n("H1"), n("H2"), params["r_primario"], params["x_primario"])
	if estado["primario_cortado"] and not estado["secundario_cortado"]:
		# Sin primario, el secundario solo es su reactancia magnetizante: en un banco en delta,
		# las otras dos columnas siguen dando tensión (triángulo abierto).
		var relacion: float = float(params["v_secundario"]) / float(params["v_primario"])
		e.impedancia(n("X1"), n("X2"), params["r_secundario"], float(params["x_primario"]) * relacion * relacion)
	elif not estado["secundario_cortado"]:
		e.fuente(n("X1"), n("X2"), _v_sec, params["r_secundario"], params["x_secundario"])


func asentar(sol: SimSolver.Solucion) -> bool:
	if estado["primario_cortado"]:
		var cambio_corte := _v_sec.modulo() > 0.0
		_v_sec = Cx.new()
		return cambio_corte
	var nuevo := sol.entre(n("H1"), n("H2")).escala(params["v_secundario"] / params["v_primario"])
	var cambio := nuevo.menos(_v_sec).modulo() > 0.2
	_v_sec = nuevo
	return cambio
