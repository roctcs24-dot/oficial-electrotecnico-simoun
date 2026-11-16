class_name SimVariador
extends SimComponente
## Variador de frecuencia (variable frequency drive, VFD). Rectifica la red L1-L2-L3 a un bus de
## continua (DC+ / DC-, unos 1,35 × la tensión de línea) y lo vuelve a ondular con los IGBT hacia
## U-V-W, con la frecuencia y la tensión de la consigna en proporción constante (V/f): a 25 Hz,
## 190 V. El motor que alimenta («motor») recibe esa frecuencia y gira en proporción.
##
## Modelo simplificado para enseñar: la salida es una fuente trifásica senoidal de la frecuencia
## fundamental (sin modulación PWM ni armónicos) y la entrada consume la potencia de la salida
## dividida por el rendimiento, como una carga resistiva. Las órdenes de marcha y la consigna se
## dan desde el teclado (estado marcha y consigna_hz); por bornes, la orden llega a DI1 desde +24 V.

const ANGULOS := {"U": 0.0, "V": -120.0, "W": 120.0}
const R_SALIDA := 0.05
const R_BUS := 1000.0
## Dispara por sobrecorriente por encima de estas veces la nominal.
const SOBRECORRIENTE := 2.0
const TOLERANCIA := 0.05
const T_VENTILADOR_S := 20.0

var _p_entrada_w := 0.0


func tipo() -> String:
	return "variador"


func _params_por_defecto() -> Dictionary:
	return {
		"modelo": "Variador 15 kW",
		"v_nominal": SimRed.V_LINEA,
		"f_nominal": SimRed.F_HZ,
		"i_nominal": 32.0,
		"aceleracion_s": 5.0,
		"deceleracion_s": 5.0,
		"consigna_hz": 50.0,
		"sentido": "directo",
		"rendimiento": 0.97,
		"p_reposo_w": 40.0,
		"motor": "",
	}


func _estado_inicial() -> Dictionary:
	return {"marcha": false, "f": 0.0, "fallo": "", "i": 0.0, "bus_v": 0.0, "memoria": 0.0, "corto_salida": false,
		"ventilador_parado": false, "t_caliente": 0.0}


func usa_continua() -> bool:
	return true


func marchar() -> void:
	if estado["fallo"] == "":
		estado["marcha"] = true


func parar() -> void:
	estado["marcha"] = false


func rearmar() -> bool:
	if estado["fallo"] == "":
		return false
	estado["fallo"] = ""
	estado["memoria"] = 0.0
	estado["t_caliente"] = 0.0
	return true


func en_fallo() -> bool:
	return estado["fallo"] != ""


func _salida_activa() -> bool:
	return not en_fallo() and float(estado["f"]) > 0.05


## Tensión de línea de la salida: V/f constante, sin pasar de lo que da el bus.
func tension_salida() -> float:
	if not _salida_activa():
		return 0.0
	var v: float = float(params["v_nominal"]) * minf(float(estado["f"]) / float(params["f_nominal"]), 1.0)
	return minf(v, float(estado["bus_v"]) / 1.35)


func _angulo(fase: String) -> float:
	var a: float = ANGULOS[fase]
	return -a if params["sentido"] == "inverso" else a


func estampar(e: SimEstampa) -> void:
	if _p_entrada_w > 1.0:
		var r: float = pow(float(params["v_nominal"]), 2.0) / _p_entrada_w
		for fase in ["L1", "L2", "L3"]:
			e.impedancia(n(fase), n("NE"), r)
	e.fuente_continua(n("DC+"), n("DC-"), float(estado["bus_v"]), R_BUS)
	if estado["corto_salida"]:
		e.impedancia(n("U"), n("V"), 0.01)
	if not _salida_activa():
		return
	var v_fase := tension_salida() / sqrt(3.0)
	for fase: String in ANGULOS:
		e.fuente(n(fase), n("NS"), Cx.polar(v_fase, _angulo(fase)), R_SALIDA)


## Corrientes de salida U, V y W y potencia activa entregada en la resolución sol.
func _salida(sol: SimSolver.Solucion) -> Array:
	if not _salida_activa():
		return [0.0, 0.0]
	var v_fase := tension_salida() / sqrt(3.0)
	var maxima := 0.0
	var p := 0.0
	for fase: String in ANGULOS:
		var v_t := sol.entre(n(fase), n("NS"))
		var i := Cx.polar(v_fase, _angulo(fase)).menos(v_t).escala(1.0 / R_SALIDA)
		maxima = maxf(maxima, i.modulo())
		p += v_t.por(i.conjugado()).re
	return [maxima, p]


func asentar(sol: SimSolver.Solucion) -> bool:
	var con_red := tension(sol, "L1", "L2") > 50.0
	var p_nueva := 0.0
	if con_red:
		p_nueva = maxf(float(_salida(sol)[1]), 0.0) / float(params["rendimiento"]) + float(params["p_reposo_w"])
	if absf(p_nueva - _p_entrada_w) <= maxf(TOLERANCIA * _p_entrada_w, 20.0):
		return false
	_p_entrada_w = p_nueva
	return true


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var objetivo_bus := 1.35 * tension(sol, "L1", "L2")
	if objetivo_bus >= float(estado["bus_v"]):
		estado["bus_v"] = objetivo_bus
	else:
		estado["bus_v"] += (objetivo_bus - float(estado["bus_v"])) * (1.0 - exp(-dt / 2.0))
	var salida := _salida(sol)
	estado["i"] = salida[0]
	if not en_fallo():
		_proteger(dt)
	var objetivo := float(params["consigna_hz"]) if estado["marcha"] and not en_fallo() else 0.0
	var f := float(estado["f"])
	if en_fallo():
		f = 0.0
	elif f < objetivo:
		f = minf(f + float(params["f_nominal"]) / maxf(float(params["aceleracion_s"]), 0.1) * dt, objetivo)
	else:
		f = maxf(f - float(params["f_nominal"]) / maxf(float(params["deceleracion_s"]), 0.1) * dt, objetivo)
	estado["f"] = f
	_mandar_motor()


func _proteger(dt: float) -> void:
	var i_n := float(params["i_nominal"])
	if float(estado["i"]) > SOBRECORRIENTE * i_n:
		_fallar("F001 Sobrecorriente en la salida")
		return
	if estado["marcha"] and float(estado["bus_v"]) < 0.65 * 1.35 * float(params["v_nominal"]):
		_fallar("F003 Subtensión del bus de continua")
		return
	estado["memoria"] = SimTermico.actualizar(estado["memoria"], estado["i"], i_n, dt)
	if estado["memoria"] >= SimTermico.UMBRAL:
		_fallar("F004 Sobrecarga del motor (I²t)")
		return
	if estado["ventilador_parado"] and _salida_activa():
		estado["t_caliente"] += dt
		if estado["t_caliente"] >= T_VENTILADOR_S:
			_fallar("F005 Sobretemperatura del radiador")


func _fallar(texto: String) -> void:
	estado["fallo"] = texto
	estado["marcha"] = false
	estado["f"] = 0.0
	avisar("variador_fallo", {"fallo": texto})


func _mandar_motor() -> void:
	if str(params["motor"]).is_empty() or sim() == null:
		return
	var m := sim().componente(str(params["motor"]))
	if m != null:
		m.estado["f_alim"] = maxf(float(estado["f"]), 0.5)


## Pantalla del teclado del variador.
func pantalla() -> Array[String]:
	var bus := "bus %d V" % roundi(estado["bus_v"])
	if en_fallo():
		return ["FALLO", str(estado["fallo"])]
	if float(estado["bus_v"]) < 100.0:
		return ["SIN RED", "bus %d V" % roundi(estado["bus_v"])]
	if _salida_activa():
		return ["RUN %s Hz" % ("%.1f" % estado["f"]).replace(".", ","), "%d A · %d V · %s" % [roundi(estado["i"]), roundi(tension_salida()), bus]]
	return ["STOP · LISTO", "Consigna %d Hz · %s" % [roundi(params["consigna_hz"]), bus]]


## Magnitudes de la pantalla: f, i, bus, u (tensión de salida) y pantalla.
func leer(_sol: SimSolver.Solucion, magnitud := "f") -> Dictionary:
	match magnitud if not magnitud.is_empty() else "f":
		"f":
			return {"valor": estado["f"], "unidad": "Hz", "fuera_de_rango": false, "averia": ""}
		"i":
			return {"valor": estado["i"], "unidad": "A", "fuera_de_rango": false, "averia": ""}
		"bus":
			return {"valor": estado["bus_v"], "unidad": "V", "fuera_de_rango": false, "averia": ""}
		"u":
			return {"valor": tension_salida(), "unidad": "V", "fuera_de_rango": false, "averia": ""}
		"pantalla":
			var texto: String = str(estado["fallo"]).get_slice(" ", 0) if en_fallo() else pantalla()[0]
			return {"valor": 0.0, "unidad": "", "fuera_de_rango": false, "averia": "", "texto": texto}
	return {"valor": 0.0, "unidad": "", "fuera_de_rango": false, "averia": "magnitud_desconocida"}
