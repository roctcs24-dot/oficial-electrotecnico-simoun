class_name SimSincronoscopio
extends SimComponente
## Sincronoscopio: compara la tensión del generador entrante (G1-G2) con la de las barras
## (B1-B2). La aguja indica el ángulo, y su giro, la diferencia de frecuencia: en sentido
## rápido (positivo), el entrante va más rápido que las barras.

const TENSION_MINIMA := 0.1

var _anterior := 0.0
var _hay_anterior := false


func tipo() -> String:
	return "sincronoscopio"


func _params_por_defecto() -> Dictionary:
	return {"v_linea": SimRed.V_LINEA}


func _estado_inicial() -> Dictionary:
	return {"angulo": 0.0, "deslizamiento_hz": 0.0, "dv_pct": 0.0, "valido": false}


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var g := sol.entre(n("G1"), n("G2"))
	var b := sol.entre(n("B1"), n("B2"))
	var minima: float = params["v_linea"] * TENSION_MINIMA
	if g.modulo() < minima or b.modulo() < minima:
		estado["valido"] = false
		_hay_anterior = false
		return
	var angulo := Cx.diferencia_angulo(g.angulo(), b.angulo())
	if _hay_anterior:
		estado["deslizamiento_hz"] = Cx.diferencia_angulo(angulo, _anterior) / 360.0 / dt
	_anterior = angulo
	_hay_anterior = true
	estado["angulo"] = angulo
	estado["dv_pct"] = (g.modulo() - b.modulo()) / params["v_linea"] * 100.0
	estado["valido"] = true
