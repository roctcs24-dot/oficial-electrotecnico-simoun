class_name SimMaquinaPrincipal
extends SimComponente
## Máquina principal diésel vista desde su panel de mando: lo que el oficial electrotécnico
## mide y cablea. Todo a 24 V DC. Bornes de la caja de conexiones del motor:
##   ARR1-ARR2  solenoide de la válvula de aire de los motores de arranque (unos 22 Ω).
##   PAR1-PAR2  solenoide de parada: con tensión corta el combustible (unos 22 Ω).
##   PRE1-PRE2  orden de prelubricación hacia el tablero de bombas (relé de interfaz).
##   PL1-PL2    presostato de aceite: cierra con 0,6 bar o más.
##   VG1-VG2    final de carrera del virador: cierra con el virador desacoplado. En el panel va
##              en serie con la solenoide de aire: con el virador acoplado no llega el aire.
##   PA1-PA2    presostato de aire de arranque: cierra con 6 bar o más en la línea.
##   SV1-SV2    relé de velocidad: cierra por encima de 200 rpm, motor encendido.
##   SB1-SB2    disparo de sobrevelocidad (NC): abre si se superan 1150 rpm.
##   CP1-CP2    presostato de sobrepresión del cárter, COP (NC): abre en disparo.
##   NA1-NA2    detector de niebla de aceite CMR del cárter (NC): abre en alarma.
##   TA1-TA2    termostato de alta temperatura del agua (NC): abre a 95 °C.
##   LL1-LL2    limitación de carga del controlador: cierra con el motor frío en marcha.
##
## Valores vistos en el buque (pantalla del MEC2+ y monitor de la sala de control, 2026-11-12):
## ralentí 440 rpm con la escala del tacómetro hasta 1200 y la nominal en 1050; aceite a la
## entrada del motor 2,8 bar; agua de salida 59 °C; cárter −0,51 mbar; aire de arranque 123 psi,
## unos 8,5 bar. El resto (umbrales, retardos, botellas de 30 bar con reductora) son valores
## típicos: verificar con el manual del Wabtec (GE) 16V250 y su controlador MEC2+. Modelo
## concentrado para enseñar el arranque, los permisivos y las paradas; los tiempos van acelerados.

const V_BOBINA := 24.0
const CIERRA := 0.7
const R_SOLENOIDE := 22.0
const R_INTERFAZ := 640.0
const RPM_GIRO_AIRE := 120.0
const RPM_ENCIENDE := 100.0
const RPM_VELOCIDAD := 200.0
const RPM_RALENTI := 440.0
const RPM_NOMINAL := 1050.0
const RPM_SOBREVELOCIDAD := 1150.0
const RPM_POR_S := 60.0
const P_BOTELLAS_MAX := 30.0
const P_REDUCTORA := 8.5
const P_AIRE_GIRA := 4.0
const P_AIRE_PRESOSTATO := 6.0
const P_ACEITE_PRESOSTATO := 0.6
const P_ACEITE_PRELUB := 1.0
const P_ACEITE_RALENTI := 2.8
const T_PRECALENTADO := 45.0
const T_RALENTI := 60.0
const T_PLENA_CARGA := 75.0
const T_ALTA := 95.0
const T_LIMITA_CARGA := 50.0
const CARTER_MBAR := -0.51
const FALLA_S := 20.0
const CONTACTOS := ["PL", "VG", "PA", "SV", "SB", "CP", "NA", "TA", "LL"]
const AVERIAS := ["", "presostato_aire", "no_enciende", "niebla", "cop", "baja_presion_aceite", "agua_ht", "sobrevelocidad", "termostato_ht_abierto", "prelub_sin_bomba"]


var _avisados := {}


func tipo() -> String:
	return "maquina_principal"


func usa_continua() -> bool:
	return true


func paso_maximo() -> float:
	return 0.25


func _params_por_defecto() -> Dictionary:
	return {
		"virador": "", "selector_velocidad": "", "selector_modo": "", "averia": "",
		"p_aire_inicial": P_BOTELLAS_MAX, "carga_aire_bar_s": 0.08, "aire_cerrado": false,
	}


func _estado_inicial() -> Dictionary:
	return {
		"rpm": 0.0, "consigna": RPM_RALENTI, "encendida": false, "p_aceite": 0.0, "p_aire": -1.0,
		"t_ht": T_PRECALENTADO, "sobrevelocidad": false, "niebla": false, "cop": false,
		"marcha_s": 0.0, "arranques": 0, "arr": false, "par": false, "pre": false,
	}


func _preparar() -> void:
	if float(estado["p_aire"]) < 0.0:
		estado["p_aire"] = float(params["p_aire_inicial"])


func encendida() -> bool:
	return estado["encendida"]


func rpm() -> float:
	return estado["rpm"]


func _selector(clave: String) -> SimSelector:
	var id: String = params[clave]
	if id.is_empty() or sim() == null or not sim().componentes.has(id):
		return null
	return sim().componente(id) as SimSelector


func virador_acoplado() -> bool:
	var s := _selector("virador")
	return s != null and s.nombre_posicion() == "ACOPLADO"


## Presión en la línea de los motores de arranque, después de la reductora: cero con la válvula
## de la botella cerrada y la línea purgada para trabajar en ella.
func p_linea_aire() -> float:
	return 0.0 if params["aire_cerrado"] else minf(float(estado["p_aire"]), P_REDUCTORA)


## Para los transmisores, los indicadores y la pantalla.
func presion(punto: String) -> float:
	match punto:
		"aire":
			return p_linea_aire()
		"botellas":
			return estado["p_aire"]
		"carter":
			return CARTER_MBAR if estado["encendida"] else 0.0
	return estado["p_aceite"]


func temperatura(_punto: String) -> float:
	return estado["t_ht"]


func lectura(clave: String) -> float:
	match clave:
		"rpm":
			return estado["rpm"]
		"aceite":
			return estado["p_aceite"]
		"aire":
			return p_linea_aire()
		"ht":
			return estado["t_ht"]
	return 0.0


func disparo_retenido() -> bool:
	return estado["sobrevelocidad"] or estado["niebla"] or estado["cop"]


func contacto_cerrado(par: String) -> bool:
	match par:
		"PL":
			return estado["p_aceite"] >= P_ACEITE_PRESOSTATO
		"VG":
			return not virador_acoplado()
		"PA":
			return p_linea_aire() >= P_AIRE_PRESOSTATO and params["averia"] != "presostato_aire"
		"SV":
			return estado["rpm"] >= RPM_VELOCIDAD
		"SB":
			return not estado["sobrevelocidad"]
		"CP":
			return not estado["cop"]
		"NA":
			return not estado["niebla"]
		"TA":
			return estado["t_ht"] < T_ALTA and params["averia"] != "termostato_ht_abierto"
		"LL":
			return estado["encendida"] and estado["t_ht"] < T_LIMITA_CARGA
	return false


## Los disparos de sobrevelocidad, de sobrepresión del cárter y de niebla de aceite se rearman
## en el motor, con el motor parado y la causa revisada.
func rearmar() -> bool:
	if estado["rpm"] > 1.0 or not disparo_retenido():
		return false
	estado["sobrevelocidad"] = false
	estado["niebla"] = false
	estado["cop"] = false
	return true


## Lo que muestra la pantalla del MEC2+, con sus nombres en inglés como a bordo.
func pantalla() -> Array[String]:
	var situacion := "Stopped"
	if estado["encendida"]:
		situacion = "Running"
	elif estado["rpm"] > 1.0:
		situacion = "Cranking" if estado["arr"] else "Stopping"
	if disparo_retenido():
		situacion = "Shutdown"
	var modo := _selector("selector_modo")
	return [
		"Engine Status: %s" % situacion,
		"Actual Speed %d RPM · Ref Speed %d RPM" % [roundi(estado["rpm"]), roundi(estado["consigna"]) if estado["encendida"] else 0],
		"Engine Control Mode: %s" % ("Local" if modo != null and modo.nombre_posicion() == "LOCAL" else "Remote"),
		"Lube Oil (Inlet) %s bar · Water (Outlet) %d °C" % [TextoTecnico.numero(estado["p_aceite"], 1), roundi(estado["t_ht"])],
		"Starting Air %s bar · Crankcase %s mbar" % [TextoTecnico.numero(p_linea_aire(), 1), TextoTecnico.numero(presion("carter"), 2)],
	]


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("ARR1"), n("ARR2"), R_SOLENOIDE)
	e.impedancia(n("PAR1"), n("PAR2"), R_SOLENOIDE)
	e.impedancia(n("PRE1"), n("PRE2"), R_INTERFAZ)
	for par: String in CONTACTOS:
		if contacto_cerrado(par):
			e.enlace(n(par + "1"), n(par + "2"))


func _bobina(sol: SimSolver.Solucion, nombre: String) -> bool:
	if sol.dc == null:
		return false
	return absf(tension_dc(sol, nombre + "1", nombre + "2")) >= CIERRA * V_BOBINA


## Las bobinas se leen en cada paso; los contactos cambian con el estado y la simulación los
## vuelve a estampar en la resolución siguiente.
func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var averia: String = params["averia"]
	var arr := _bobina(sol, "ARR")
	var par := _bobina(sol, "PAR")
	var pre := _bobina(sol, "PRE")
	estado["arr"] = arr
	estado["par"] = par
	estado["pre"] = pre
	var combustible: bool = not par and averia != "no_enciende" and not estado["sobrevelocidad"]
	var r: float = estado["rpm"]
	# Aire de arranque: la válvula abierta gasta aire de las botellas; los compresores las cargan.
	if arr and p_linea_aire() > 0.0:
		estado["p_aire"] = maxf(float(estado["p_aire"]) - 1.2 * dt, 0.0)
	else:
		estado["p_aire"] = minf(float(estado["p_aire"]) + float(params["carga_aire_bar_s"]) * dt, P_BOTELLAS_MAX)
	if arr and estado["encendida"] and r > RPM_VELOCIDAD + 50.0:
		_una_vez("mp_arranque_en_marcha")
	if estado["encendida"]:
		_mover_consigna(dt)
		var objetivo: float = 1250.0 if averia == "sobrevelocidad" else float(estado["consigna"])
		r += (objetivo - r) * minf(1.0, dt * 0.6)
		if not combustible:
			estado["encendida"] = false
		elif r >= RPM_SOBREVELOCIDAD:
			estado["sobrevelocidad"] = true
			estado["encendida"] = false
			avisar("mp_sobrevelocidad")
	else:
		if arr and p_linea_aire() >= P_AIRE_GIRA:
			r += (RPM_GIRO_AIRE - r) * minf(1.0, dt * 1.5)
		else:
			r -= r * minf(1.0, dt * 0.8)
			if r < 1.0:
				r = 0.0
		# Solo enciende mientras el aire lo hace girar: un motor que se para por inercia no vuelve
		# a encender solo al quitar la parada.
		if r >= RPM_ENCIENDE and combustible and arr:
			estado["encendida"] = true
			estado["consigna"] = RPM_RALENTI
			estado["arranques"] = int(estado["arranques"]) + 1
			estado["marcha_s"] = 0.0
	estado["rpm"] = r
	var carga := clampf((r - RPM_RALENTI) / (RPM_NOMINAL - RPM_RALENTI), 0.0, 1.0)
	# Aceite: en marcha lo da la bomba del motor y sube con la velocidad; parado, la de
	# prelubricación.
	var p_obj := 0.0
	if r >= RPM_VELOCIDAD:
		p_obj = (0.6 if averia == "baja_presion_aceite" else P_ACEITE_RALENTI) * clampf(r / RPM_RALENTI, 0.0, 1.6)
	elif pre and averia != "prelub_sin_bomba":
		p_obj = P_ACEITE_PRELUB
	estado["p_aceite"] = float(estado["p_aceite"]) + (p_obj - float(estado["p_aceite"])) * minf(1.0, dt / 2.0)
	# Agua de refrigeración: el motor parado se mantiene precalentado.
	var t_obj := T_PRECALENTADO
	var tau := 300.0
	if estado["encendida"]:
		t_obj = 105.0 if averia == "agua_ht" else lerpf(T_RALENTI, T_PLENA_CARGA, carga)
		tau = 40.0
	estado["t_ht"] = float(estado["t_ht"]) + (t_obj - float(estado["t_ht"])) * minf(1.0, dt / tau)
	if estado["encendida"]:
		estado["marcha_s"] = float(estado["marcha_s"]) + dt
		if estado["marcha_s"] >= FALLA_S:
			if averia == "niebla" and not estado["niebla"]:
				estado["niebla"] = true
				avisar("mp_niebla")
			elif averia == "cop" and not estado["cop"]:
				estado["cop"] = true
				avisar("mp_cop")


## SPEED DECR-INCR: mientras se mantiene, la consigna baja o sube entre el ralentí y la nominal.
func _mover_consigna(dt: float) -> void:
	var s := _selector("selector_velocidad")
	if s == null:
		return
	var sentido := 0.0
	match s.nombre_posicion():
		"INCR":
			sentido = 1.0
		"DECR":
			sentido = -1.0
	estado["consigna"] = clampf(float(estado["consigna"]) + sentido * RPM_POR_S * dt, RPM_RALENTI, RPM_NOMINAL)


func _una_vez(evento: String) -> void:
	if not _avisados.has(evento):
		_avisados[evento] = true
		avisar(evento)
