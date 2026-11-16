class_name SimMosfet
extends SimComponente
## MOSFET de canal N (N-channel MOSFET) de bornes G, D y S, como interruptor. La puerta casi no
## consume: manda la tensión G-S. Por debajo del umbral no conduce; con la tensión plena, D-S es
## una resistencia de miliohmios; en medio conduce a medias, con varios ohmios, y se calienta.
## Lleva un diodo interno de S a D que el óhmetro ve. Averías: D-S en corto (quemado) y puerta
## perforada (G-S en corto).

const R_OFF := 1e8
const R_CORTO := 0.05
const R_PUERTA_PERFORADA := 10.0


func tipo() -> String:
	return "mosfet"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {"vth": 3.0, "v_plena": 8.0, "r_on": 0.03, "r_media": 5.0, "i_max": 40.0, "p_max": 3.0, "vf_diodo": 0.5}


func _estado_inicial() -> Dictionary:
	return {"nivel": 0, "diodo_prueba": false, "quemado": false, "puerta_perforada": false}


func r_ds() -> float:
	if estado["quemado"]:
		return R_CORTO
	match int(estado["nivel"]):
		2:
			return float(params["r_on"])
		1:
			return float(params["r_media"])
	return R_OFF


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("G"), n("S"), R_PUERTA_PERFORADA if estado["puerta_perforada"] else 1e9)
	if e.dc and not e.continua:
		# Óhmetro: el canal está apagado y aparece el diodo interno de S a D.
		e.impedancia(n("D"), n("S"), R_CORTO if estado["quemado"] else R_OFF)
		if estado["diodo_prueba"]:
			e.caida(n("S"), n("D"), params["vf_diodo"], 0.05)
		return
	e.impedancia(n("D"), n("S"), r_ds())


## 0 apagado, 1 a medias, 2 conduciendo pleno.
func _nivel(vgs: float) -> int:
	if vgs >= float(params["v_plena"]):
		return 2
	return 1 if vgs >= float(params["vth"]) else 0


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var nivel := _nivel(tension_dc(sol, "G", "S"))
	if nivel == int(estado["nivel"]):
		return false
	estado["nivel"] = nivel
	return true


func ajustar_prueba(sol: SimSolver.Solucion) -> bool:
	var v: float = sol.entre(n("S"), n("D")).re
	var nuevo: bool = (v - float(params["vf_diodo"])) / 0.05 > -1e-9 if estado["diodo_prueba"] else v > float(params["vf_diodo"])
	if nuevo == estado["diodo_prueba"]:
		return false
	estado["diodo_prueba"] = nuevo
	return true


func terminar_prueba() -> void:
	estado["diodo_prueba"] = false


func corriente(sol: SimSolver.Solucion) -> float:
	return tension_dc(sol, "D", "S") / r_ds() if sol.dc != null else 0.0


func potencia(sol: SimSolver.Solucion) -> float:
	var i := corriente(sol)
	return i * i * r_ds()


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	if estado["quemado"] or sol.dc == null:
		return
	var i := corriente(sol)
	if i > float(params["i_max"]) or potencia(sol) > float(params["p_max"]):
		estado["quemado"] = true
		avisar("mosfet_quemado", {"corriente_a": i, "potencia_w": potencia(sol)})
