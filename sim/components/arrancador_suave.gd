class_name SimArrancadorSuave
extends SimComponente
## Arrancador suave (soft starter) con bypass interno, como los Siemens SIRIUS 3RW de los
## compresores nº 3 y nº 4. Potencia 1/L1, 3/L2 y 5/L3 hacia 2/T1, 4/T2 y 6/T3; orden de marcha
## en A1-A2 (a la tensión de mando); salidas 13-14 «en marcha», 23-24 «bypass» y el contacto de
## fallo 95-96 (NC) / 95-98 (NA).
##
## Los tiristores se representan como una resistencia por fase que se recalcula en cada
## resolución: la tensión del motor sube en rampa desde la tensión inicial hasta la plena en el
## tiempo de rampa, sin dejar pasar más corriente que el límite. Cuando la rampa termina y la
## corriente baja cerca de la nominal, cierra el bypass. Modelo simplificado para enseñar: no
## hay recorte de la onda ni armónicos.
##
## Los SIRIUS 3RW40 del tablero de bombas de la máquina principal llevan además protección de
## sobrecarga del motor: con clase_sobrecarga 10, 15 o 20 se calientan con la corriente frente
## a Ie como un relé térmico y, al disparar, cambian el contacto 95-96/98 y encienden OVERLOAD.
## Con clase 0 (OFF) no protegen, como el modelo de los compresores.

const POLOS := [["1", "2"], ["3", "4"], ["5", "6"]]
const R_BLOQUEO := 1.0e5
const CIERRA := 0.85
const ABRE := 0.45
## La corriente a la que cierra el bypass, en veces la ajustada.
const BYPASS_VECES := 1.3
## Se recalcula la resistencia si cambia más que esta fracción.
const TOLERANCIA := 0.03

var _r := R_BLOQUEO


func tipo() -> String:
	return "arrancador_suave"


func _params_por_defecto() -> Dictionary:
	return {
		"modelo": "SIRIUS 3RW55",
		"v_mando": 110.0,
		"r_mando": 2200.0,
		"ie_a": 173.0,
		"u_inicial": 0.4,
		"rampa_s": 10.0,
		"limite_corriente": 3.5,
		"t_max_arranque_s": 30.0,
		"clase_sobrecarga": 0,
	}


func _estado_inicial() -> Dictionary:
	return {"fase": "listo", "t": 0.0, "u": 0.0, "i": 0.0, "fallo": "", "memoria": 0.0, "sobrecarga": false}


func _preparar() -> void:
	_r = R_CONTACTO if estado.get("fase", "") == "bypass" else R_BLOQUEO


## listo, arranque, bypass o fallo.
func fase() -> String:
	return estado["fase"]


func en_marcha() -> bool:
	return estado["fase"] in ["arranque", "bypass"]


func corriente() -> float:
	return estado["i"]


## Texto de la pantalla del arrancador, en el estilo de su indicador. El 3RW40 no tiene
## pantalla: se describen sus LED.
func pantalla() -> Array[String]:
	var amperios := "%d A" % roundi(estado["i"])
	if str(params["modelo"]).contains("3RW40"):
		match estado["fase"]:
			"arranque":
				return ["STATE/BYPASSED verde intermitente", amperios]
			"bypass":
				return ["STATE/BYPASSED verde fijo", amperios]
			"fallo":
				return ["OVERLOAD rojo" if estado["sobrecarga"] else "FAILURE rojo", str(estado["fallo"])]
		return ["DEVICE verde", "Ie %d A · clase %d" % [roundi(params["ie_a"]), int(params["clase_sobrecarga"])]]
	match estado["fase"]:
		"arranque":
			return ["ARRANQUE", "U %d %%   %s" % [roundi(estado["u"] * 100.0), amperios]]
		"bypass":
			return ["BYPASS", "En marcha   %s" % amperios]
		"fallo":
			return ["FALLO", str(estado["fallo"])]
	return ["LISTO", "Ie %d A · rampa %d s" % [roundi(params["ie_a"]), roundi(params["rampa_s"])]]


## El rearme borra el fallo; el arranque necesita después una orden nueva.
func rearmar() -> bool:
	if estado["fase"] != "fallo":
		return false
	estado["fase"] = "listo"
	estado["fallo"] = ""
	estado["sobrecarga"] = false
	estado["t"] = 0.0
	_r = R_BLOQUEO
	return true


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("A1"), n("A2"), params["r_mando"])
	for par in POLOS:
		e.impedancia(n(par[0]), n(par[1]), _r)
	if en_marcha():
		e.enlace(n("13"), n("14"))
	if estado["fase"] == "bypass":
		e.enlace(n("23"), n("24"))
	if estado["fase"] == "fallo":
		e.enlace(n("95"), n("98"))
	else:
		e.enlace(n("95"), n("96"))


func _orden(sol: SimSolver.Solucion) -> float:
	return tension(sol, "A1", "A2") / float(params["v_mando"])


func asentar(sol: SimSolver.Solucion) -> bool:
	var orden := _orden(sol)
	match estado["fase"]:
		"listo":
			if orden >= CIERRA:
				estado["fase"] = "arranque"
				estado["t"] = 0.0
				estado["u"] = params["u_inicial"]
				_r = 50.0
				return true
		"arranque", "bypass":
			if orden <= ABRE:
				estado["fase"] = "listo"
				_r = R_BLOQUEO
				return true
			if estado["fase"] == "arranque":
				return _ajustar(sol)
	return false


## Resistencia por fase para que el motor reciba la fracción u de la tensión de línea sin pasar
## del límite de corriente. Con la red equilibrada, la tensión de fase del motor sale de las de
## línea en su lado y la corriente, de la caída en la resistencia actual.
func _ajustar(sol: SimSolver.Solucion) -> bool:
	var i1 := sol.entre(n("1"), n("2")).escala(1.0 / _r)
	if i1.modulo() < 1e-3:
		return false
	var va := sol.entre(n("2"), n("4")).menos(sol.entre(n("6"), n("2"))).escala(1.0 / 3.0)
	var zm := va.entre(i1)
	var v_fase := tension(sol, "1", "3") / sqrt(3.0)
	var u: float = maxf(estado["u"], 0.05)
	var modulo := zm.modulo() / u
	var limite: float = float(params["limite_corriente"]) * float(params["ie_a"])
	if limite > 0.0:
		modulo = maxf(modulo, v_fase / limite)
	var r_nueva := sqrt(maxf(modulo * modulo - zm.im * zm.im, 0.0)) - zm.re
	r_nueva = clampf(r_nueva, R_CONTACTO, R_BLOQUEO)
	if absf(r_nueva - _r) <= TOLERANCIA * maxf(_r, 0.01):
		return false
	_r = r_nueva
	return true


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	estado["i"] = sol.entre(n("1"), n("2")).modulo() / _r
	_proteger(dt)
	if not en_marcha():
		return
	var lineas := [tension(sol, "1", "3"), tension(sol, "3", "5"), tension(sol, "5", "1")]
	var maxima: float = lineas.max()
	if maxima >= 200.0 and lineas.min() < 0.6 * maxima:
		_fallar("Falta de fase en la entrada")
		return
	if estado["fase"] != "arranque":
		return
	estado["t"] += dt
	var rampa: float = maxf(float(params["rampa_s"]), 0.1)
	var u0: float = params["u_inicial"]
	estado["u"] = minf(u0 + (1.0 - u0) * estado["t"] / rampa, 1.0)
	if estado["t"] >= rampa and estado["i"] <= BYPASS_VECES * float(params["ie_a"]):
		estado["fase"] = "bypass"
		estado["u"] = 1.0
		_r = R_CONTACTO
		avisar("arrancador_bypass")
	elif estado["t"] >= float(params["t_max_arranque_s"]):
		_fallar("Tiempo de arranque excedido")


## Memoria térmica del motor: la clase 10 dispara como un relé térmico; las clases 15 y 20
## tardan 1,5 y 2 veces más.
func _proteger(dt: float) -> void:
	var clase := int(params["clase_sobrecarga"])
	if clase <= 0:
		return
	var paso := dt * 10.0 / float(clase)
	estado["memoria"] = SimTermico.actualizar(estado["memoria"], estado["i"], float(params["ie_a"]), paso)
	if en_marcha() and estado["memoria"] >= SimTermico.UMBRAL:
		estado["sobrecarga"] = true
		_fallar("Sobrecarga del motor", "arrancador_sobrecarga")


func _fallar(texto: String, evento := "arrancador_fallo") -> void:
	estado["fase"] = "fallo"
	estado["fallo"] = texto
	_r = R_BLOQUEO
	avisar(evento, {"fallo": texto})
