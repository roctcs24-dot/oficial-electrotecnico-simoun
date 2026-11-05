class_name SimTemporizador
extends SimComponente
## Temporizador con bobina A1-A2 y conmutado 15: NC 15-16, NA 15-18.
## on_delay conmuta al pasar el retardo con bobina activa;
## off_delay conmuta al activar y vuelve al pasar el retardo sin bobina.

const CIERRA := 0.85
const ABRE := 0.45


func tipo() -> String:
	return "temporizador"


func _params_por_defecto() -> Dictionary:
	return {"modo": "on_delay", "retardo_s": 5.0, "v_bobina": 110.0, "r_bobina": 3000.0, "x_bobina": 6000.0}


func _estado_inicial() -> Dictionary:
	return {"bobina": false, "conmutado": false, "cuenta_s": 0.0}


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("A1"), n("A2"), params["r_bobina"], params["x_bobina"])
	if estado["conmutado"]:
		e.enlace(n("15"), n("18"))
	else:
		e.enlace(n("15"), n("16"))


func asentar(sol: SimSolver.Solucion) -> bool:
	var relacion: float = tension(sol, "A1", "A2") / params["v_bobina"]
	var antes: bool = estado["bobina"]
	var conmutado_antes: bool = estado["conmutado"]
	if relacion >= CIERRA:
		estado["bobina"] = true
	elif relacion <= ABRE:
		estado["bobina"] = false
	if antes != estado["bobina"]:
		estado["cuenta_s"] = 0.0
	if params["modo"] == "on_delay":
		if not estado["bobina"]:
			estado["conmutado"] = false
	elif estado["bobina"]:
		estado["conmutado"] = true
	return antes != estado["bobina"] or conmutado_antes != estado["conmutado"]


func avanzar(dt: float, _sol: SimSolver.Solucion) -> void:
	var cuenta_activa: bool = estado["bobina"] if params["modo"] == "on_delay" else not estado["bobina"]
	if not cuenta_activa:
		return
	estado["cuenta_s"] += dt
	if estado["cuenta_s"] >= params["retardo_s"]:
		estado["conmutado"] = params["modo"] == "on_delay"
