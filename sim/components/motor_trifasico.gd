class_name SimMotorTrifasico
extends SimComponente
## Motor de inducción con tres devanados U1-U2, V1-V2, W1-W2.
## Los parámetros del circuito equivalente se deducen de la placa de datos.
## La secuencia positiva y negativa de las tensiones decide par y sentido de giro,
## así funcionan la inversión de fases, la falta de fase y los devanados invertidos.
## Modelo simplificado para enseñar, no para dimensionar.

const DEVANADOS := [["U1", "U2"], ["V1", "V2"], ["W1", "W2"]]
const T_AMBIENTE := 40.0
const T_ALARMA := 155.0
const T_QUEMADO := 180.0
const TAU_TERMICA_S := 600.0
const SUBPASOS := 5
const A_RE := -0.5
const A_IM := 0.8660254037844386

var _rs: float
var _rr: float
var _x1: float
var _x2: float
var _xm: float
var _v_dev: float
var _i_dev: float
var _ns: float
var _w_sinc: float
var _par_nominal: float
var _inercia: float
var _peso_pos := 1.0
var _peso_neg := 0.0
var _saturacion := 1.0
var _corrientes := [0.0, 0.0, 0.0]


func tipo() -> String:
	return "motor_trifasico"


func _params_por_defecto() -> Dictionary:
	return {
		"p_kw": 15.0,
		"v_delta": 440.0,
		"v_estrella": 760.0,
		"i_delta": 25.0,
		"i_estrella": 14.5,
		"fp": 0.86,
		"rpm": 1760.0,
		"polos": 4,
		"f_hz": 60.0,
		"arranque_veces": 6.5,
		"arranque_s": 1.5,
		"carga": 0.8,
		"bloqueado": false,
		"aislamiento_mohm": [300.0, 300.0, 300.0],
		"entre_devanados_mohm": 300.0,
	}


func _estado_inicial() -> Dictionary:
	return {"rpm": 0.0, "temperatura": T_AMBIENTE, "quemado": false}


func _preparar() -> void:
	_v_dev = params["v_delta"]
	_i_dev = params["i_delta"] / sqrt(3.0)
	_ns = 120.0 * params["f_hz"] / params["polos"]
	_w_sinc = _ns * TAU / 60.0
	var w_nominal: float = params["rpm"] * TAU / 60.0
	_par_nominal = params["p_kw"] * 1000.0 / w_nominal
	var deslizamiento: float = 1.0 - params["rpm"] / _ns
	_rr = deslizamiento * 3.0 * _v_dev * _v_dev / (_par_nominal * _w_sinc)
	_rs = _rr
	var z_arranque: float = _v_dev / (_i_dev * params["arranque_veces"])
	var x_total := sqrt(maxf(z_arranque * z_arranque - pow(_rs + _rr, 2.0), 0.01))
	_x1 = x_total / 2.0
	_x2 = x_total / 2.0
	_xm = _v_dev / (_i_dev * 0.4)
	_inercia = params["arranque_s"] * _par_nominal / _w_sinc


func rpm() -> float:
	return estado["rpm"]


func temperatura() -> float:
	return estado["temperatura"]


func quemado() -> bool:
	return estado["quemado"]


func resistencia_devanado() -> float:
	return _rs


func par_nominal() -> float:
	return _par_nominal


func sentido() -> String:
	if estado["rpm"] > 5.0:
		return "horario"
	if estado["rpm"] < -5.0:
		return "antihorario"
	return "parado"


## Corriente de un devanado (no de línea, si está en delta) en la última resolución.
func corriente_devanado(i: int) -> float:
	return _corrientes[i]


func estampar(e: SimEstampa) -> void:
	var aislamiento: Array = params["aislamiento_mohm"]
	var entre: float = params["entre_devanados_mohm"] * 1e6
	for i in 3:
		var a: String = n(DEVANADOS[i][0])
		var b: String = n(DEVANADOS[i][1])
		var r_tierra: float = 1000.0 if estado["quemado"] else float(aislamiento[i]) * 1e6
		e.impedancia(a, SimSolver.TIERRA, r_tierra)
		var z := _z_devanado()
		if e.dc:
			e.impedancia(a, b, _rs)
		else:
			e.impedancia(a, b, z.re, z.im)
	if not estado["quemado"]:
		e.impedancia(n("U1"), n("V1"), entre)
		e.impedancia(n("V1"), n("W1"), entre)
		e.impedancia(n("W1"), n("U1"), entre)


func _z_devanado() -> Cx:
	if estado["quemado"]:
		return Cx.new(_rs * 0.3, _x1 * 0.3)
	var s_pos: float = 1.0 - estado["rpm"] / _ns
	var s_neg: float = 1.0 + estado["rpm"] / _ns
	var z := _z_secuencia(s_pos).escala(_peso_pos).mas(_z_secuencia(s_neg).escala(_peso_neg))
	return z


func _z_secuencia(s: float) -> Cx:
	var s_seguro := s
	if absf(s_seguro) < 1e-4:
		s_seguro = 1e-4
	var rotor := Cx.new(_rr / s_seguro, _x2)
	var m := Cx.new(0.0, _xm / _saturacion)
	return Cx.new(_rs, _x1).mas(m.por(rotor).entre(m.mas(rotor)))


func _par_secuencia(v2: float, s: float) -> float:
	var s_seguro := s
	if absf(s_seguro) < 1e-4:
		s_seguro = 1e-4
	var reparto := _xm / (_xm + _x1)
	var rs_e := _rr / s_seguro
	var d := pow(_rs + rs_e, 2.0) + pow(_x1 + _x2, 2.0)
	return 3.0 * v2 * reparto * reparto * rs_e / (d * _w_sinc)


## Las reactancias dependen del deslizamiento y de las secuencias, que vienen de las
## tensiones: se actualizan aquí y el resultado vale para la siguiente resolución.
func asentar(sol: SimSolver.Solucion) -> bool:
	var secuencias := _secuencias(sol)
	var total: float = secuencias[0] + secuencias[1]
	var peso_nuevo: float = 1.0 if total < 1.0 else secuencias[0] / total
	var max_v := 0.0
	for par in DEVANADOS:
		max_v = maxf(max_v, tension(sol, par[0], par[1]))
	var exceso := maxf(max_v / _v_dev - 1.05, 0.0)
	var saturacion_nueva := 1.0 + 12.0 * exceso * exceso
	var cambio := absf(peso_nuevo - _peso_pos) > 0.02 or absf(saturacion_nueva - _saturacion) > 0.1
	_peso_pos = peso_nuevo
	_peso_neg = 1.0 - peso_nuevo
	_saturacion = saturacion_nueva
	return cambio


func _secuencias(sol: SimSolver.Solucion) -> Array:
	var va := sol.entre(n("U1"), n("U2"))
	var vb := sol.entre(n("V1"), n("V2"))
	var vc := sol.entre(n("W1"), n("W2"))
	var a := Cx.new(A_RE, A_IM)
	var a2 := Cx.new(A_RE, -A_IM)
	var pos := va.mas(a.por(vb)).mas(a2.por(vc)).escala(1.0 / 3.0)
	var neg := va.mas(a2.por(vb)).mas(a.por(vc)).escala(1.0 / 3.0)
	return [pos.modulo(), neg.modulo()]


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	var z := _z_devanado()
	var calor := 0.0
	for i in 3:
		var par: Array = DEVANADOS[i]
		_corrientes[i] = sol.entre(n(par[0]), n(par[1])).entre(z).modulo()
		calor = maxf(calor, pow(_corrientes[i] / _i_dev, 2.0))
	var t_objetivo := T_AMBIENTE + 80.0 * calor
	estado["temperatura"] += (t_objetivo - estado["temperatura"]) * (1.0 - exp(-dt / TAU_TERMICA_S))
	if not estado["quemado"] and estado["temperatura"] >= T_QUEMADO:
		estado["quemado"] = true
		avisar("motor_quemado", {"temperatura": estado["temperatura"]})
	_avanzar_giro(dt, _secuencias(sol))


func _avanzar_giro(dt: float, secuencias: Array) -> void:
	if params["bloqueado"]:
		estado["rpm"] = 0.0
		return
	var v2_pos: float = 0.0 if estado["quemado"] else pow(secuencias[0], 2.0)
	var v2_neg: float = 0.0 if estado["quemado"] else pow(secuencias[1], 2.0)
	var w_a_rpm := 60.0 / TAU
	var paso := dt / SUBPASOS
	for _i in SUBPASOS:
		var giro: float = estado["rpm"]
		var par_e := _par_secuencia(v2_pos, 1.0 - giro / _ns) - _par_secuencia(v2_neg, 1.0 + giro / _ns)
		var friccion := 0.03 * _par_nominal
		if absf(giro) < 1.0 and absf(par_e) <= friccion:
			estado["rpm"] = 0.0
			continue
		var relativa: float = giro / params["rpm"]
		var par_carga: float = params["carga"] * _par_nominal * relativa * absf(relativa)
		var signo := signf(giro) if absf(giro) >= 1.0 else signf(par_e)
		var neto := par_e - par_carga - friccion * signo
		var nuevo := giro + neto / _inercia * paso * w_a_rpm
		if giro != 0.0 and signf(nuevo) != signf(giro) and absf(par_e) <= friccion:
			nuevo = 0.0
		estado["rpm"] = nuevo
