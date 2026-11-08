class_name SimContactor
extends SimComponente
## Contactor: bobina A1-A2, polos 1-2, 3-4, 5-6, auxiliares NA 13-14 y 43-44, NC 21-22 y 31-32.
## Una corriente muy alta suelda los polos: el contactor queda cerrado hasta cambiarlo.
## Cierra en cuanto la bobina tiene tensión, pero la armadura tarda en soltar: así un hueco
## de tensión durante un corto no lo abre antes de que el arco actúe.
## Avería espiras_en_corto: la bobina mide unos pocos ohmios, no cierra y funde el fusible de mando.

const POLOS := [["1", "2"], ["3", "4"], ["5", "6"]]
const AUX_NA := [["13", "14"], ["43", "44"]]
const AUX_NC := [["21", "22"], ["31", "32"]]
const CIERRA := 0.85
const ABRE := 0.45
const QUEMA := 1.3
const QUEMA_S := 2.0
const SUELTA_S := 0.02
const VIBRA_CIERRES := 3
const VIBRA_VENTANA_S := 0.5

var _sobretension_s := 0.0
var _sin_tension_s := 0.0
var _desde_cierre_s := VIBRA_VENTANA_S
var _cierres_seguidos := 0


func tipo() -> String:
	return "contactor"


func _params_por_defecto() -> Dictionary:
	return {
		"v_bobina": 110.0,
		"r_bobina": 360.0,
		"x_bobina": 1150.0,
		"i_soldadura_a": 700.0,
		"r_contacto": [0.0, 0.0, 0.0],
		"espiras_en_corto": false,
	}


func _estado_inicial() -> Dictionary:
	return {"energizada": false, "soldado": false, "bobina_quemada": false}


func cerrado() -> bool:
	return estado["energizada"] or estado["soldado"]


func estampar(e: SimEstampa) -> void:
	if params.get("espiras_en_corto", false):
		e.impedancia(n("A1"), n("A2"), 3.0, 1.0)
	elif not estado["bobina_quemada"]:
		e.impedancia(n("A1"), n("A2"), params["r_bobina"], params["x_bobina"])
	var pares := AUX_NA if cerrado() else AUX_NC
	for par in pares:
		e.enlace(n(par[0]), n(par[1]))
	if cerrado():
		for i in 3:
			e.impedancia(n(POLOS[i][0]), n(POLOS[i][1]), R_CONTACTO + float(params["r_contacto"][i]))


func corriente(sol: SimSolver.Solucion, polo: int) -> float:
	if not cerrado():
		return 0.0
	var r: float = R_CONTACTO + float(params["r_contacto"][polo])
	return sol.entre(n(POLOS[polo][0]), n(POLOS[polo][1])).modulo() / r


func asentar(sol: SimSolver.Solucion) -> bool:
	if estado["bobina_quemada"]:
		if estado["energizada"]:
			estado["energizada"] = false
			return true
		return false
	if estado["energizada"] or params.get("espiras_en_corto", false) or tension(sol, "A1", "A2") / params["v_bobina"] < CIERRA:
		return false
	estado["energizada"] = true
	_contar_cierre()
	return true


## Una bobina que se alimenta por su propio NC cierra y suelta sin parar.
func _contar_cierre() -> void:
	_cierres_seguidos = _cierres_seguidos + 1 if _desde_cierre_s < VIBRA_VENTANA_S else 0
	_desde_cierre_s = 0.0
	if _cierres_seguidos == VIBRA_CIERRES:
		avisar("vibracion_mando")


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	_desde_cierre_s += dt
	if not estado["bobina_quemada"]:
		if tension(sol, "A1", "A2") > params["v_bobina"] * QUEMA:
			_sobretension_s += dt
			if _sobretension_s >= QUEMA_S:
				estado["bobina_quemada"] = true
				avisar("bobina_quemada")
		else:
			_sobretension_s = 0.0
	if not estado["soldado"]:
		for i in 3:
			var corr := corriente(sol, i)
			if corr > params["i_soldadura_a"]:
				estado["soldado"] = true
				avisar("arco_contactos_soldados", {"corriente_a": corr})
				break
	if estado["energizada"] and tension(sol, "A1", "A2") / params["v_bobina"] <= ABRE:
		_sin_tension_s += dt
		if _sin_tension_s >= SUELTA_S:
			estado["energizada"] = false
	else:
		_sin_tension_s = 0.0
