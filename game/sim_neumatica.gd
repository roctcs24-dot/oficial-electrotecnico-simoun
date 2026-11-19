class_name SimNeumatica
extends RefCounted
## Modelo de enseñanza de un circuito neumático en régimen estable: red de aire de control, secador
## frigorífico, unidad de filtro y regulador, válvula 5/2 monoestable o 5/3 de centro cerrado con
## bobinas de 24 V DC, reguladores de caudal en los escapes (meter-out), cilindro de doble efecto
## con detectores magnéticos B1 (atrás) y B2 (delante), fugas, y un posicionador electroneumático
## sobre un actuador de cuarto de vuelta de simple efecto (falla cerrada). Las lecturas del
## manómetro, el caudalímetro, el multímetro y el termómetro del atlas salen de aquí. Los valores
## por defecto son típicos del aire de control de un buque — verificar a bordo.
##
## Parámetros (todos opcionales), por componente:
##   red:           {presion (bar), temperatura (°C del ambiente)}
##   secador:       {presente, averiado}
##   fr:            {regulado (bar), filtro_sucio (0 a 1), purga_atascada, lubricador}
##   valvula:       {tipo: "52" o "53", y1, y2, bobina_quemada, corredera_pegada, fuga_corredera}
##   reguladores:   {avance, retroceso: apertura 0 a 1 del regulador del escape que frena ese movimiento}
##   cilindro:      {diametro, vastago, carrera (mm), carga (N), fuga_juntas, sin_iman}
##   fuga:          {diametro (mm de orificio equivalente)}
##   posicionador:  {senal (mA), alimentacion (bar), sin_aire, membrana_fuga, invertido}

const ATM := 1.013                 # bar absolutos de la atmósfera
const RENDIMIENTO := 0.9           # fuerza real / fuerza teórica del cilindro (rozamiento de juntas)
const V_MAX := 615.0               # mm/s del cilindro con el regulador abierto y sin carga
const FRICCION := 0.3              # bar que se gastan en mover el pistón en vacío
const DP_FILTRO := 0.15            # bar que pierde el filtro limpio con el cilindro moviéndose
const DP_FILTRO_SUCIO := 1.6       # bar más con el cartucho colmatado
const FUGA_CORREDERA := 30.0       # NL/min que escapan por una corredera con juntas gastadas
const FUGA_JUNTAS := 40.0          # NL/min que pasan de una cámara a otra con la junta del pistón gastada
const Q_ORIFICIO := 65.0           # NL/min por un orificio de 1 mm a 6 bar (crece con d² y p absoluta)
const KW_POR_NL := 0.006           # kW de compresor por cada NL/min de aire (7 bar)
const ROCIO_SECADOR := 3.0         # °C de punto de rocío a presión con el secador sano
const RESORTE := Vector2(1.0, 4.0) # bar del muelle del actuador: empieza a abrir y abre del todo
const MEMBRANA_MAX := 60.0         # % que alcanza un actuador con la membrana o la junta con fuga
const MA_MINIMO := 3.6             # mA por debajo de los cuales el posicionador se queda sin energía

const POR_DEFECTO := {
	"red": {"presion": 7.0, "temperatura": 30.0},
	"secador": {"presente": true, "averiado": false},
	"fr": {"regulado": 6.0, "filtro_sucio": 0.0, "purga_atascada": false, "lubricador": false},
	"valvula": {"tipo": "52", "y1": true, "y2": false, "bobina_quemada": false, "corredera_pegada": false, "fuga_corredera": false},
	"reguladores": {"avance": 0.3, "retroceso": 0.3},
	"cilindro": {"diametro": 63.0, "vastago": 20.0, "carrera": 200.0, "carga": 0.0, "fuga_juntas": false, "sin_iman": false},
	"fuga": {"diametro": 0.0},
	"posicionador": {"senal": 12.0, "alimentacion": 6.0, "sin_aire": false, "membrana_fuga": false, "invertido": false},
}

## Unidad de cada punto de medida.
const UNIDADES := {
	"P_red": "bar", "P_reg": "bar", "dP_filtro": "bar", "P_A": "bar", "P_B": "bar", "P_salida": "bar", "P_alim": "bar",
	"velocidad": "mm/s", "tiempo": "s", "fuerza": "N", "fuerza_retroceso": "N",
	"consumo": "NL", "fuga_Q": "NL/min", "fuga_kW": "kW", "fuga_escape": "NL/min",
	"B1": "V", "B2": "V", "Y1": "V", "senal": "mA", "posicion": "%", "rocio": "°C",
}


## Los parámetros completos: los por defecto con los dados encima, componente a componente.
static func completar(params: Dictionary) -> Dictionary:
	var r := POR_DEFECTO.duplicate(true)
	for id: String in params:
		if r.has(id) and params[id] is Dictionary:
			r[id].merge(params[id], true)
	return r


## Áreas del pistón (x) y anular (y) en mm².
static func areas(p: Dictionary) -> Vector2:
	var d := float(p["cilindro"]["diametro"])
	var v := float(p["cilindro"]["vastago"])
	var a1 := PI * d * d / 4.0
	return Vector2(a1, a1 - PI * v * v / 4.0)


## Presión a la salida del regulador (bar) con el cilindro moviéndose o en reposo.
static func presion_regulada(p: Dictionary, moviendo := true) -> float:
	var caida := (DP_FILTRO + DP_FILTRO_SUCIO * clampf(float(p["fr"]["filtro_sucio"]), 0.0, 1.0)) if moviendo else 0.0
	return maxf(minf(float(p["fr"]["regulado"]), float(p["red"]["presion"]) - caida), 0.0)


## Fuerza teórica por rendimiento (N) que da una presión en bar sobre un área en mm².
static func fuerza(presion: float, area_mm2: float) -> float:
	return presion * 0.1 * area_mm2 * RENDIMIENTO


## Aire libre (NL) que gasta un ciclo completo (avance y retroceso) a la presión dada.
static func consumo_ciclo(p: Dictionary, presion: float) -> float:
	var a := areas(p)
	var volumen_l := (a.x + a.y) * float(p["cilindro"]["carrera"]) / 1.0e6
	return volumen_l * (presion + ATM) / ATM


## Caudal (NL/min) que se escapa por un orificio de «d» mm a la presión dada.
static func fuga_orificio(d: float, presion: float) -> float:
	return Q_ORIFICIO * d * d * (presion + ATM) / (6.0 + ATM)


## Hacia dónde manda la válvula: 1 avance (1→4), -1 retroceso (1→2), 0 centro cerrado.
static func mando(p: Dictionary) -> int:
	var v: Dictionary = p["valvula"]
	var y1: bool = v["y1"] and not v["bobina_quemada"] and not v["corredera_pegada"]
	var y2: bool = v["y2"] and not v["corredera_pegada"]
	if str(v["tipo"]) == "53":
		if y1 and not y2:
			return 1
		if y2 and not y1:
			return -1
		return 0
	return 1 if y1 else -1


## Resuelve el cilindro: presiones, velocidad, fuerzas, consumo y detectores.
static func resolver(params: Dictionary) -> Dictionary:
	var p := completar(params)
	var a := areas(p)
	var sentido := mando(p)
	var cil: Dictionary = p["cilindro"]
	var reg_mov := presion_regulada(p, sentido != 0)
	var r := {"P_red": float(p["red"]["presion"]), "P_reg": reg_mov, "dP_filtro": 0.0, "P_A": 0.0, "P_B": 0.0, "velocidad": 0.0, "tiempo": 0.0, "fuerza": fuerza(presion_regulada(p, false), a.x),
		"fuerza_retroceso": fuerza(presion_regulada(p, false), a.y), "consumo": consumo_ciclo(p, presion_regulada(p, false)),
		"fuga_escape": 0.0, "B1": 0.0, "B2": 0.0, "Y1": 24.0 if p["valvula"]["y1"] else 0.0, "estado": ""}
	r["dP_filtro"] = DP_FILTRO + DP_FILTRO_SUCIO * clampf(float(p["fr"]["filtro_sucio"]), 0.0, 1.0)
	if p["valvula"]["fuga_corredera"]:
		r["fuga_escape"] = FUGA_CORREDERA
	if cil["fuga_juntas"]:
		r["fuga_escape"] += FUGA_JUNTAS
	if sentido == 0:
		r["estado"] = "parado"
		r["P_A"] = reg_mov
		r["P_B"] = reg_mov * a.x / a.y
		return r
	# Presión que pide la carga en la cámara que empuja.
	var area := a.x if sentido > 0 else a.y
	var carga := float(cil["carga"]) if sentido > 0 else 0.0
	var pide := carga / (0.1 * area * RENDIMIENTO) + FRICCION
	var apertura := clampf(float(p["reguladores"]["avance" if sentido > 0 else "retroceso"]), 0.0, 1.0)
	var velocidad := 0.0
	if pide < reg_mov:
		velocidad = V_MAX * apertura * sqrt(1.0 - pide / reg_mov)
	if cil["fuga_juntas"]:
		velocidad *= 0.6
	r["velocidad"] = velocidad
	r["tiempo"] = float(cil["carrera"]) / velocidad if velocidad > 0.0 else 0.0
	# En el final de carrera, la cámara que empuja llega a la regulada y la otra queda a escape.
	var aguanta := reg_mov if not cil["fuga_juntas"] else reg_mov * 0.6
	r["P_A"] = aguanta if sentido > 0 else 0.0
	r["P_B"] = aguanta if sentido < 0 else 0.0
	if velocidad <= 0.0:
		r["estado"] = "no_mueve"
		r["B1"] = 0.0 if cil["sin_iman"] else 24.0
		return r
	r["estado"] = "avanza" if sentido > 0 else "retrocede"
	if not cil["sin_iman"]:
		r["B2" if sentido > 0 else "B1"] = 24.0
	return r


## Posicionador: señal, presión de salida al actuador y posición de la válvula.
static func posicionador(params: Dictionary) -> Dictionary:
	var p: Dictionary = completar(params)["posicionador"]
	var senal := float(p["senal"])
	var r := {"senal": senal, "P_alim": 0.0 if p["sin_aire"] else float(p["alimentacion"]), "P_salida": 0.0, "posicion": 0.0}
	if p["sin_aire"] or senal < MA_MINIMO:
		return r  # sin aire o sin señal, el muelle cierra: posición de falla
	var objetivo := clampf((senal - 4.0) / 16.0, 0.0, 1.0)
	if p["invertido"]:
		objetivo = 1.0 - objetivo
	var posicion := objetivo * 100.0
	if p["membrana_fuga"]:
		posicion = minf(posicion, MEMBRANA_MAX)
	r["posicion"] = posicion
	r["P_salida"] = minf(RESORTE.x + (RESORTE.y - RESORTE.x) * posicion / 100.0, float(r["P_alim"])) if posicion > 0.0 else 0.0
	return r


## Aire de la red: punto de rocío a presión (°C) y fugas.
static func red(params: Dictionary) -> Dictionary:
	var p := completar(params)
	var rocio := float(p["red"]["temperatura"]) if (not p["secador"]["presente"] or p["secador"]["averiado"]) else ROCIO_SECADOR
	var q := fuga_orificio(float(p["fuga"]["diametro"]), float(p["red"]["presion"]))
	return {"rocio": rocio, "fuga_Q": q, "fuga_kW": q * KW_POR_NL}


## Lectura de un punto: {valor, unidad, fuera_de_rango, averia}.
static func medir(medida: Dictionary) -> Dictionary:
	var params: Dictionary = medida.get("params", {})
	var punto := str(medida.get("punto", "P_reg"))
	var valor := 0.0
	match punto:
		"senal", "P_salida", "P_alim", "posicion":
			valor = float(posicionador(params)[punto])
		"rocio", "fuga_Q", "fuga_kW":
			valor = float(red(params)[punto])
		_:
			var r := resolver(params)
			if not r.has(punto):
				return {"valor": 0.0, "unidad": "", "fuera_de_rango": false, "averia": "punto_desconocido"}
			valor = float(r[punto])
	return {"valor": valor, "unidad": UNIDADES.get(punto, ""), "fuera_de_rango": false, "averia": ""}
