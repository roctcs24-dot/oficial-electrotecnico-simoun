class_name SimGenerador
extends SimComponente
## Diésel-generador: alternador síncrono como fuerza electromotriz detrás de una reactancia,
## con gobernador de velocidad y regulador de tensión (AVR). Bornes L1, L2, L3 y N.
##
## La frecuencia sale del balance entre la potencia del motor diésel y la eléctrica, y el
## ángulo de la fuerza electromotriz avanza con la diferencia respecto de la frecuencia nominal. Así el reparto
## de carga en paralelo, la potencia inversa y la sincronización salen de la propia red.
## La reactancia es un valor intermedio entre la transitoria y la síncrona, elegido para que el
## paralelo sea estable con el paso de la simulación. Modelo simplificado para enseñar.

const ANGULOS := {"L1": 0.0, "L2": -120.0, "L3": 120.0}
const F_NOMINAL := SimRed.F_HZ
const PASO_MAXIMO_S := 0.05
## El AVR excita solo por encima de esta fracción de la velocidad nominal.
const F_EXCITACION := 0.9
const GANANCIA_AVR := 3.0
const E_MAXIMA_PU := 2.5
const TAU_ISOCRONO_S := 2.0
## Con el diésel al límite y la frecuencia por debajo de este valor, el motor se cala.
const F_CALADO := 0.85
const CALADO_S := 2.0
const VIGILANCIA_S := 3.0
const SALTO_MAXIMO_HZ := 2.0
## El diésel admite un 10 % de sobrecarga sobre su potencia nominal. Valor típico: verificar.
const SOBRECARGA_DIESEL := 1.1
const TAU_DESEXCITACION_S := 0.5
## Sin combustible, la compresión y el rozamiento del diésel lo frenan en unos segundos.
## Valor del simulador: verificar con el tiempo de parada del grupo.
const ARRASTRE_PARADO_PU := 0.3

var _ang_terminal := 0.0
var _hay_ang_terminal := false


func tipo() -> String:
	return "generador"


func _params_por_defecto() -> Dictionary:
	return {
		"s_kva": 565.0,
		"p_kw": 452.0,
		"v_linea": SimRed.V_LINEA,
		"r_pu": 0.01,
		"x_pu": 0.5,
		"h_s": 2.0,
		"estatismo": 0.04,
		"estatismo_q": 0.04,
		"tau_gobernador_s": 0.3,
		"amortiguamiento_pu": 2.0,
		"friccion_pu": 0.02,
		"neutro_mohm": 1000.0,
		"modo_gobernador": "estatismo",
		"arranque_automatico": false,
		"vigilar": [],
		# Avería del mando de velocidad: la consigna se mueve sola, en Hz por segundo.
		"deriva_hz_s": 0.0,
	}


## bloqueado: arranque bloqueado con candado y tarjeta. parada: alarma que paró el diésel.
func _estado_inicial() -> Dictionary:
	return {
		"en_marcha": false, "f": 0.0, "delta": 0.0, "e_pu": 1.0, "f_ref": F_NOMINAL, "pm_pu": 0.0,
		"danado": false, "f_red": 0.0, "p_kw": 0.0, "q_kvar": 0.0, "v": 0.0, "i": 0.0,
		"calado_s": 0.0, "vigilancia_s": 0.0, "acelerado": false, "bloqueado": false, "parada": "",
	}


func paso_maximo() -> float:
	return PASO_MAXIMO_S


func frecuencia() -> float:
	return estado["f"]


func en_marcha() -> bool:
	return estado["en_marcha"]


## Devuelve "" o el motivo por el que no arranca.
func arrancar() -> String:
	if estado["danado"]:
		return "El grupo está dañado: cambie el repuesto antes de arrancar."
	if estado["bloqueado"]:
		return "El arranque está bloqueado con candado y tarjeta."
	if not estado["parada"].is_empty():
		return "Parada por alarma: %s. Resuelva la causa antes de arrancar." % estado["parada"]
	if not estado["en_marcha"]:
		estado["en_marcha"] = true
		estado["e_pu"] = maxf(estado["e_pu"], 1.0)
		avisar("arranque_generador")
	return ""


func parar() -> void:
	estado["en_marcha"] = false


## Parada de seguridad del diésel, como la de baja presión de combustible o de aceite.
func parar_por_alarma(alarma: String) -> void:
	estado["en_marcha"] = false
	estado["parada"] = alarma
	avisar("parada_por_alarma", {"alarma": alarma})


## Si puede arrancar: ni dañado, ni bloqueado, ni parado por una alarma.
func disponible() -> bool:
	return not estado["danado"] and not estado["bloqueado"] and estado["parada"].is_empty()


## Subir o bajar la velocidad con el mando del gobernador.
func ajustar_velocidad(hz: float) -> void:
	estado["f_ref"] = clampf(estado["f_ref"] + hz, F_NOMINAL * 0.9, F_NOMINAL * 1.1)


## Subir o bajar la consigna del AVR, en voltios.
func ajustar_tension(voltios: float) -> void:
	var nominal: float = params["v_linea"]
	estado["v_ref"] = clampf(estado.get("v_ref", nominal) + voltios, nominal * 0.9, nominal * 1.1)


func _z() -> Cx:
	var z_base: float = params["v_linea"] * params["v_linea"] / (params["s_kva"] * 1000.0)
	return Cx.new(params["r_pu"] * z_base, params["x_pu"] * z_base)


## Fuerza electromotriz de una fase: proporcional a la velocidad mientras arranca.
func _fem(fase: String) -> Cx:
	var v_fase: float = params["v_linea"] / sqrt(3.0)
	var flujo := clampf(estado["f"] / F_NOMINAL, 0.0, 1.0)
	return Cx.polar(v_fase * estado["e_pu"] * flujo, estado["delta"] + ANGULOS[fase])


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("N"), SimSolver.TIERRA, params["neutro_mohm"] * 1e6)
	var z := _z()
	for fase: String in ANGULOS:
		e.fuente(n(fase), n("N"), _fem(fase), z.re, z.im)


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var s_base: float = params["s_kva"] * 1000.0
	var z := _z()
	var p := 0.0
	var q := 0.0
	var i_max := 0.0
	for fase: String in ANGULOS:
		var v := sol.entre(n(fase), n("N"))
		var i := _fem(fase).menos(v).entre(z)
		p += _fem(fase).por(i.conjugado()).re
		q += v.por(i.conjugado()).im
		i_max = maxf(i_max, i.modulo())
	var v12 := sol.entre(n("L1"), n("L2"))
	estado["p_kw"] = p / 1000.0
	estado["q_kvar"] = q / 1000.0
	estado["v"] = v12.modulo()
	estado["i"] = i_max
	_medir_frecuencia_red(v12, dt)
	_vigilar(dt, sol)
	_gobernar(dt)
	var pe := p / s_base
	var amortiguamiento: float = params["amortiguamiento_pu"] * (estado["f"] - estado["f_red"])
	var friccion: float = 0.0
	if estado["f"] > 0.0:
		friccion = params["friccion_pu"] if estado["en_marcha"] else ARRASTRE_PARADO_PU
	var aceleracion: float = (estado["pm_pu"] - pe - amortiguamiento - friccion) * F_NOMINAL / (2.0 * params["h_s"])
	estado["f"] = maxf(estado["f"] + aceleracion * dt, 0.0)
	var avance: float = 360.0 * (estado["f"] - F_NOMINAL) * dt
	estado["delta"] = fposmod(estado["delta"] + avance + 180.0, 360.0) - 180.0
	_regular_tension(dt, q / s_base)
	_comprobar_calado(dt)


## La frecuencia de la red se deduce de cómo gira la tensión de los bornes respecto del propio
## rotor. Medida respecto de la frecuencia nominal, una frecuencia muy baja avanzaría más de media vuelta por
## paso y no se podría leer. El amortiguamiento actúa sobre la diferencia entre las dos.
func _medir_frecuencia_red(v12: Cx, dt: float) -> void:
	if v12.modulo() < params["v_linea"] * 0.1:
		estado["f_red"] = estado["f"]
		_hay_ang_terminal = false
		return
	var ang := Cx.diferencia_angulo(v12.angulo(), estado["delta"])
	if _hay_ang_terminal:
		# Al cerrar un interruptor la tensión salta de ángulo de golpe: se limita para que ese
		# salto no se lea como una frecuencia absurda.
		var medida: float = estado["f"] + Cx.diferencia_angulo(ang, _ang_terminal) / 360.0 / dt
		estado["f_red"] = clampf(medida, estado["f"] - SALTO_MAXIMO_HZ, estado["f"] + SALTO_MAXIMO_HZ)
	else:
		estado["f_red"] = estado["f"]
	_ang_terminal = ang
	_hay_ang_terminal = true


## Potencia máxima del diésel, en por unidad de los kVA del alternador.
func _pm_maxima() -> float:
	return SOBRECARGA_DIESEL * params["p_kw"] / params["s_kva"]


## El estatismo se refiere a la potencia activa nominal: con 4 %, de vacío a plena carga
## la frecuencia baja 2,4 Hz.
func _gobernar(dt: float) -> void:
	var objetivo := 0.0
	if estado["en_marcha"]:
		if params["deriva_hz_s"] != 0.0:
			ajustar_velocidad(params["deriva_hz_s"] * dt)
		if params["modo_gobernador"] == "isocrono" and estado["f"] > F_NOMINAL * F_EXCITACION:
			estado["f_ref"] += (F_NOMINAL - estado["f"]) * dt / TAU_ISOCRONO_S
		var nominal: float = params["p_kw"] / params["s_kva"]
		objetivo = clampf((estado["f_ref"] - estado["f"]) / (params["estatismo"] * F_NOMINAL) * nominal, -0.1, _pm_maxima())
	estado["pm_pu"] += (objetivo - estado["pm_pu"]) * (1.0 - exp(-dt / params["tau_gobernador_s"]))


## Con estatismo de reactiva, cada AVR baja un poco su consigna al dar kVAr, y los grupos en
## paralelo se reparten la reactiva en vez de pelear por ella.
func _regular_tension(dt: float, q_pu: float) -> void:
	# Al parar se quita la excitación: la tensión cae en segundos, no con la velocidad.
	if not estado["en_marcha"]:
		estado["e_pu"] *= exp(-dt / TAU_DESEXCITACION_S)
		return
	if estado["f"] < F_NOMINAL * F_EXCITACION:
		return
	var consigna: float = estado.get("v_ref", params["v_linea"]) * (1.0 - params["estatismo_q"] * q_pu)
	var error: float = (consigna - estado["v"]) / params["v_linea"]
	estado["e_pu"] = clampf(estado["e_pu"] + GANANCIA_AVR * error * dt, 0.0, E_MAXIMA_PU)


## Solo después de alcanzar la velocidad: al arrancar el diésel también va al máximo con la
## frecuencia baja, y no es un calado.
func _comprobar_calado(dt: float) -> void:
	if not estado["en_marcha"]:
		estado["acelerado"] = false
	elif estado["f"] >= F_NOMINAL * F_EXCITACION:
		estado["acelerado"] = true
	if estado["acelerado"] and estado["f"] < F_NOMINAL * F_CALADO and estado["pm_pu"] > _pm_maxima() * 0.95:
		estado["calado_s"] += dt
		if estado["calado_s"] >= CALADO_S:
			estado["en_marcha"] = false
			avisar("parada_por_sobrecarga")
	else:
		estado["calado_s"] = 0.0


## Arranque automático, como el del generador de emergencia: si la tensión vigilada falta
## durante unos segundos, el grupo arranca solo.
func _vigilar(dt: float, sol: SimSolver.Solucion) -> void:
	var vigilar: Array = params["vigilar"]
	if not params["arranque_automatico"] or vigilar.size() < 2 or estado["en_marcha"] or not disponible():
		estado["vigilancia_s"] = 0.0
		return
	if sol.entre(vigilar[0], vigilar[1]).modulo() < params["v_linea"] * 0.5:
		estado["vigilancia_s"] += dt
		if estado["vigilancia_s"] >= VIGILANCIA_S:
			arrancar()
			avisar("arranque_automatico")
	else:
		estado["vigilancia_s"] = 0.0
