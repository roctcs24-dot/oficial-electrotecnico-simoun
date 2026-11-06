class_name SimPLC
extends SimComponente
## Autómata programable compacto, genérico. Bornes:
##   L+ y M: alimentación de 24 V DC. Con menos de 19 V se para y apaga las salidas.
##   I0.0 a I0.7 con su común 1M: entradas digitales de 24 V. Con "entradas": "pnp" la entrada
##     se activa cuando recibe el + respecto a 1M (1M al −, para sensores PNP); con "npn",
##     cuando recibe el − (1M al +, para sensores NPN).
##   Q0.0 a Q0.5: salidas. A relé ("salidas": "rele"), un contacto entre el común 1L y cada Q,
##     que sirve para alterna o continua. A transistor, cada Q da el + de L+ a su carga.
##   AI0+ y AI0−: entrada analógica de 4–20 mA, con 250 Ω, escalada a %IW0 con "analogica".
## En cada paso de la simulación hace un scan: lee las entradas, ejecuta el programa ladder
## (SimLadder) y escribe las salidas. En STOP, o sin alimentación, las salidas se abren.

const ENTRADAS := 8
const SALIDAS := 6
const V_MIN_ALIMENTACION := 19.0
const R_ALIMENTACION := 160.0
const R_ANALOGICA := 250.0
const R_SALIDA_TRANSISTOR := 0.2
const R_ABIERTA := 1e7
## Por debajo de 3,6 mA o por encima de 21 mA, la entrada analógica marca error (NAMUR NE 43).
const MA_ERROR_BAJO := 3.6
const MA_ERROR_ALTO := 21.0


func tipo() -> String:
	return "plc"


func usa_continua() -> bool:
	return true


func _params_por_defecto() -> Dictionary:
	return {
		"entradas": "pnp", "salidas": "rele", "programa": [], "etiquetas": {},
		"analogica": {"min": 0.0, "max": 10.0, "unidad": "bar"},
		"r_entrada": 3300.0, "v_activa": 15.0, "v_inactiva": 5.0,
	}


func _estado_inicial() -> Dictionary:
	var mem := SimLadder.memoria()
	mem.merge({"modo": "RUN", "alimentado": false}, true)
	return mem


## El programa es del PLC: no debe compartirse con el contenido del que se cargó.
func _preparar() -> void:
	params["programa"] = params["programa"].duplicate(true)


static func entrada(i: int) -> String:
	return "I0.%d" % i


static func salida(i: int) -> String:
	return "Q0.%d" % i


func en_marcha() -> bool:
	return estado["alimentado"] and estado["modo"] == "RUN"


func bit(direccion: String) -> bool:
	return SimLadder.bit(estado, direccion)


func salida_activa(i: int) -> bool:
	return en_marcha() and bit("%" + salida(i))


func entrada_activa(i: int) -> bool:
	return estado["alimentado"] and bit("%" + entrada(i))


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("L+"), n("M"), R_ALIMENTACION)
	for i in ENTRADAS:
		e.impedancia(n(entrada(i)), n("1M"), params["r_entrada"])
	e.impedancia(n("AI0+"), n("AI0-"), R_ANALOGICA)
	for i in SALIDAS:
		var activa := salida_activa(i)
		if params["salidas"] == "rele":
			if activa:
				e.enlace(n("1L"), n(salida(i)))
		else:
			e.impedancia(n("L+"), n(salida(i)), R_SALIDA_TRANSISTOR if activa else R_ABIERTA)


func asentar(sol: SimSolver.Solucion) -> bool:
	if sol.dc == null:
		return false
	var alimentado := tension_dc(sol, "L+", "M") >= V_MIN_ALIMENTACION
	if alimentado == estado["alimentado"]:
		return false
	estado["alimentado"] = alimentado
	return true


## Corriente de la entrada analógica, en miliamperios.
func miliamperios(sol: SimSolver.Solucion) -> float:
	return tension_dc(sol, "AI0+", "AI0-") / R_ANALOGICA * 1000.0


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if sol.dc == null or not estado["alimentado"]:
		return
	_leer_entradas(sol)
	if estado["modo"] == "RUN":
		SimLadder.ejecutar(params["programa"], estado, dt)


func _leer_entradas(sol: SimSolver.Solucion) -> void:
	var signo := 1.0 if params["entradas"] == "pnp" else -1.0
	for i in ENTRADAS:
		var v := tension_dc(sol, entrada(i), "1M") * signo
		var direccion := "%" + entrada(i)
		var antes: bool = estado["bits"].get(direccion, false)
		# Entre los dos umbrales la entrada conserva su estado.
		if v >= float(params["v_activa"]):
			estado["bits"][direccion] = true
		elif v <= float(params["v_inactiva"]):
			estado["bits"][direccion] = false
		else:
			estado["bits"][direccion] = antes
	var ma := miliamperios(sol)
	var a: Dictionary = params["analogica"]
	estado["palabras"]["%IW0"] = float(a["min"]) + (ma - 4.0) / 16.0 * (float(a["max"]) - float(a["min"]))
	estado["bits"]["%AE0"] = ma < MA_ERROR_BAJO or ma > MA_ERROR_ALTO


func cambiar_modo(modo: String) -> void:
	estado["modo"] = modo


## Cargar un programa nuevo: se guarda en el PLC y la memoria vuelve a cero, como al
## transferir un programa desde el equipo de programación.
func cargar_programa(programa: Array) -> void:
	params["programa"] = programa.duplicate(true)
	var alimentado: bool = estado["alimentado"]
	var modo: String = estado["modo"]
	estado = _estado_inicial()
	estado["alimentado"] = alimentado
	estado["modo"] = modo
