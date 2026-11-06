class_name SimPresostato
extends SimComponente
## Presostato de seguridad (pressure switch): un contacto 1-2 cerrado mientras la presión es
## correcta, que se abre al pasar del corte. Va en serie con la bobina del contactor del
## compresor, así que al abrirse lo para.
## tipo "alta" corta por encima del corte, y "baja" por debajo. Con rearme manual queda abierto
## hasta rearmarlo; con rearme automático cierra solo al recuperarse la presión en el diferencial.
## El de aceite tiene un retardo que le deja arrancar mientras sube la presión, y solo vigila con
## el compresor en marcha. Ajustes típicos: verificar con el manual de la planta.


func tipo() -> String:
	return "presostato"


func _params_por_defecto() -> Dictionary:
	return {
		"planta": "PLANTA",
		"punto": "descarga",
		"tipo": "alta",
		"corte_bar": 16.0,
		"diferencial_bar": 2.0,
		"rearme": "manual",
		"retardo_s": 0.0,
		"solo_en_marcha": false,
	}


func _estado_inicial() -> Dictionary:
	return {"disparado": false, "fuera_s": 0.0, "puenteado": false}


func cerrado() -> bool:
	return not estado["disparado"] or estado["puenteado"]


func estampar(e: SimEstampa) -> void:
	if cerrado():
		e.enlace(n("1"), n("2"))


## Rearme manual: solo si la presión ya volvió a un valor correcto. El que vigila solo en
## marcha, como el de aceite, rearma con el compresor parado: el retardo cuenta al arrancar.
func rearmar() -> bool:
	var vigila: bool = not params["solo_en_marcha"] or _planta().compresor_en_marcha()
	if vigila and (_fuera_de_corte(_presion()) or _en_diferencial(_presion())):
		return false
	estado["disparado"] = false
	estado["fuera_s"] = 0.0
	return true


func _planta() -> SimPlantaFrio:
	return sim().componente(params["planta"])


func _presion() -> float:
	return _planta().presion(params["punto"])


func _fuera_de_corte(p: float) -> bool:
	return p > params["corte_bar"] if params["tipo"] == "alta" else p < params["corte_bar"]


## Entre el corte y el corte más el diferencial todavía no se considera recuperada.
func _en_diferencial(p: float) -> bool:
	var d: float = params["diferencial_bar"]
	if params["tipo"] == "alta":
		return p > float(params["corte_bar"]) - d
	return p < float(params["corte_bar"]) + d


func avanzar(dt: float, _sol: SimSolver.Solucion) -> void:
	if sim() == null:
		return
	var p := _presion()
	var vigila: bool = not params["solo_en_marcha"] or _planta().compresor_en_marcha()
	if estado["disparado"]:
		if params["rearme"] == "automatico" and not _fuera_de_corte(p) and not _en_diferencial(p):
			estado["disparado"] = false
		return
	if vigila and _fuera_de_corte(p):
		estado["fuera_s"] += dt
		if estado["fuera_s"] >= float(params["retardo_s"]):
			estado["disparado"] = true
			estado["fuera_s"] = 0.0
			avisar("disparo_presostato", {"punto": params["punto"], "bar": p})
	else:
		estado["fuera_s"] = 0.0
