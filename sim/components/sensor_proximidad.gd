class_name SimSensorProximidad
extends SimComponente
## Sensor de proximidad inductivo o capacitivo con salida a transistor. Tres hilos: marrón BN
## (+), azul BU (−) y negro BK (salida). Un PNP conecta la salida al +, y un NPN al −. De dos
## hilos (BN y BU) va en serie con la carga: activo deja pasar la corriente con una caída de
## unos voltios, e inactivo, una fuga de alrededor de 1 mA.
## Necesita al menos v_min entre BN y BU. Con la polaridad invertida no funciona. Un corto en
## la salida lo protege: corta y vuelve a probar.

const R_FUGA_SALIDA := 1e7
const PROTECCION_S := 1.0


func tipo() -> String:
	return "sensor_proximidad"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {
		"deteccion": "inductivo", "salida": "pnp", "contacto": "NA", "v_min": 10.0, "v_max": 30.0,
		"consumo_ma": 10.0, "r_on": 10.0, "i_max": 0.2, "caida_dos_hilos": 5.0, "fuga_ma": 1.0,
	}


func _estado_inicial() -> Dictionary:
	return {"objeto": false, "alimentado": false, "activa": false, "protegido": false, "protegido_s": 0.0, "averiado": false}


func dos_hilos() -> bool:
	return params["salida"] == "dos_hilos"


## La salida conmuta: con objeto delante si es NA, sin él si es NC.
func detecta() -> bool:
	return estado["objeto"] != (params["contacto"] == "NC")


func estampar(e: SimEstampa) -> void:
	if dos_hilos():
		_estampar_dos_hilos(e)
		return
	if not estado["averiado"]:
		e.impedancia(n("BN"), n("BU"), 24.0 / (float(params["consumo_ma"]) / 1000.0))
	var activa: bool = estado["activa"]
	match params["salida"]:
		"pnp":
			e.impedancia(n("BN"), n("BK"), params["r_on"] if activa else R_FUGA_SALIDA)
		"npn":
			e.impedancia(n("BK"), n("BU"), params["r_on"] if activa else R_FUGA_SALIDA)


func _estampar_dos_hilos(e: SimEstampa) -> void:
	if estado["averiado"]:
		e.impedancia(n("BN"), n("BU"), R_FUGA_SALIDA)
	elif estado["activa"]:
		e.caida(n("BN"), n("BU"), params["caida_dos_hilos"], params["r_on"])
	else:
		e.impedancia(n("BN"), n("BU"), 24.0 / (float(params["fuga_ma"]) / 1000.0))


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var v := tension_dc(sol, "BN", "BU")
	var alimentado: bool
	if dos_hilos():
		# Inactivo, le llega casi toda la tensión; activo, se alimenta de su propia caída.
		alimentado = v >= float(params["v_min"]) or (estado["activa"] and v > 0.0)
	else:
		alimentado = v >= float(params["v_min"])
	alimentado = alimentado and not estado["averiado"]
	var activa: bool = alimentado and detecta() and not estado["protegido"]
	if alimentado == estado["alimentado"] and activa == estado["activa"]:
		return false
	estado["alimentado"] = alimentado
	estado["activa"] = activa
	return true


func corriente_salida(sol: SimSolver.Solucion) -> float:
	if not estado["activa"]:
		return 0.0
	match params["salida"]:
		"pnp":
			return tension_dc(sol, "BN", "BK") / float(params["r_on"])
		"npn":
			return tension_dc(sol, "BK", "BU") / float(params["r_on"])
	return (tension_dc(sol, "BN", "BU") - float(params["caida_dos_hilos"])) / float(params["r_on"])


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if estado["averiado"] or sol.dc == null:
		return
	if estado["protegido"]:
		estado["protegido_s"] += dt
		if estado["protegido_s"] >= PROTECCION_S:
			estado["protegido"] = false
			estado["protegido_s"] = 0.0
		return
	if absf(tension_dc(sol, "BN", "BU")) > float(params["v_max"]) * 1.5:
		estado["averiado"] = true
		estado["activa"] = false
		avisar("sensor_averiado", {"tension_v": tension_dc(sol, "BN", "BU")})
		return
	var i := corriente_salida(sol)
	if i > float(params["i_max"]):
		estado["protegido"] = true
		estado["activa"] = false
		avisar("sensor_cortocircuito", {"corriente_a": i})
