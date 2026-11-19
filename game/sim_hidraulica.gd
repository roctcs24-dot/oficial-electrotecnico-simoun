class_name SimHidraulica
extends RefCounted
## Modelo de enseñanza de un circuito hidráulico en régimen estable: motor eléctrico, bomba de
## cilindrada fija, válvula de alivio, direccional 4/3 de centro cerrado, cilindro de doble
## efecto o motor hidráulico, estranguladora con antirretorno a la salida (meter-out),
## antirretorno pilotada y acumulador de vejiga. Las lecturas del manómetro y del caudalímetro
## del atlas, las animaciones y las fallas salen de aquí. Los valores por defecto son típicos de
## una central pequeña de cubierta — verificar a bordo.
##
## Parámetros (todos opcionales), por componente:
##   motor:          {rpm}
##   bomba:          {cilindrada (cm³/rev), desgaste (0 a 1), aspiracion_obstruida}
##   alivio:         {tarado (bar), pegada (abierta), fuga (asiento dañado)}
##   direccional:    {posicion: 1 avanza (P→A), -1 retrocede (P→B), 0 centro cerrado}
##   actuador:       {tipo: "cilindro" o "motor", diametro y vastago (mm), carga (kN), a_tope,
##                    fuga_juntas; o cilindrada (cm³/rev), par (N·m) y desgaste del motor}
##   estrangulador:  {presente, apertura (0 a 1)}
##   pilotada:       {presente, asiento_danado}
##   acumulador:     {volumen (L), precarga (bar), perdida_gas (0 a 1), p_min, p_max (bar)}

const RETORNO := 2.0             # bar en la línea de tanque, con el filtro limpio
const ASPIRACION := -0.1         # bar en la aspiración de la bomba, sana
const ASPIRACION_OBSTRUIDA := -0.6
const ALIVIO_PEGADO := 15.0      # bar a los que pasa todo con la válvula pegada abierta
const C_ESTRANGULADOR := 0.0125  # Δp = C·(Q/apertura)²: 5 bar con 20 L/min y todo abierto
const K_JUNTAS := 0.05           # L/min por bar entre cámaras con la junta del pistón gastada
const FRICCION_RETROCESO := 10.0 # bar para mover el cilindro en vacío
const DERIVA_CORREDERA := 4.0    # mm/min que baja una carga sostenida solo por la corredera
const DERIVA_PILOTADA_DANADA := 12.0

const POR_DEFECTO := {
	"motor": {"rpm": 1450.0},
	"bomba": {"cilindrada": 20.0, "desgaste": 0.0, "aspiracion_obstruida": false},
	"alivio": {"tarado": 160.0, "pegada": false, "fuga": false},
	"direccional": {"posicion": 1},
	"actuador": {"tipo": "cilindro", "diametro": 63.0, "vastago": 36.0, "carga": 20.0, "a_tope": false, "fuga_juntas": false,
		"cilindrada": 100.0, "par": 150.0, "desgaste": 0.0},
	"estrangulador": {"presente": false, "apertura": 1.0},
	"pilotada": {"presente": false, "asiento_danado": false},
	"acumulador": {"volumen": 10.0, "precarga": 90.0, "perdida_gas": 0.0, "p_min": 100.0, "p_max": 160.0},
}

## Unidad de cada punto de medida.
const UNIDADES := {
	"P": "bar", "A": "bar", "B": "bar", "T": "bar", "S": "bar", "gas": "bar",
	"Q": "L/min", "Q_bomba": "L/min", "Q_alivio": "L/min", "Q_teorico": "L/min", "drenaje": "L/min", "fuga_B": "L/min",
	"velocidad": "mm/s", "deriva": "mm/min", "rpm": "rpm", "par": "N·m", "volumen_util": "L", "calor": "kW",
}


## Los parámetros completos: los por defecto con los dados encima, componente a componente.
static func completar(params: Dictionary) -> Dictionary:
	var r := POR_DEFECTO.duplicate(true)
	for id: String in params:
		if r.has(id) and params[id] is Dictionary:
			r[id].merge(params[id], true)
	return r


## Caudal teórico de la bomba en L/min: cilindrada por revoluciones.
static func caudal_teorico(p: Dictionary) -> float:
	var q := float(p["bomba"]["cilindrada"]) * float(p["motor"]["rpm"]) / 1000.0
	if p["bomba"]["aspiracion_obstruida"]:
		q *= 0.8
	return q


## Caudal real a la presión dada: la fuga interna crece con la presión y con el desgaste.
static func caudal_bomba(p: Dictionary, presion: float) -> float:
	var fuga := (0.05 + 0.35 * clampf(float(p["bomba"]["desgaste"]), 0.0, 1.0)) * maxf(presion, 0.0) / 160.0
	return maxf(caudal_teorico(p) * (1.0 - fuga), 0.0)


## Presión máxima que deja la válvula de alivio.
static func presion_maxima(p: Dictionary) -> float:
	var a: Dictionary = p["alivio"]
	if a["pegada"]:
		return ALIVIO_PEGADO
	if a["fuga"]:
		return float(a["tarado"]) * 0.75
	return float(a["tarado"])


static func areas(p: Dictionary) -> Vector2:
	var d := float(p["actuador"]["diametro"]) / 10.0
	var v := float(p["actuador"]["vastago"]) / 10.0
	var a1 := PI * d * d / 4.0
	return Vector2(a1, a1 - PI * v * v / 4.0)


## Resuelve el circuito: presiones (bar), caudales (L/min) y movimiento del actuador.
static func resolver(params: Dictionary) -> Dictionary:
	var p := completar(params)
	var pmax := presion_maxima(p)
	var act: Dictionary = p["actuador"]
	var posicion := int(p["direccional"]["posicion"])
	var r := {"P": pmax, "A": 0.0, "B": 0.0, "T": RETORNO, "S": ASPIRACION_OBSTRUIDA if p["bomba"]["aspiracion_obstruida"] else ASPIRACION,
		"Q": 0.0, "Q_alivio": 0.0, "velocidad": 0.0, "deriva": 0.0, "rpm": 0.0, "par": 0.0, "drenaje": 0.0, "fuga_B": 0.0,
		"Q_teorico": caudal_teorico(p), "estado": "", "pmax": pmax}
	var motor := str(act["tipo"]) == "motor"
	var ar := areas(p)
	var carga_a := float(act["carga"]) * 100.0 / ar.x   # bar que pide la carga en la cámara A
	if posicion == 0 or act["a_tope"]:
		# Centro cerrado o actuador a tope: la presión sube hasta el alivio y todo el caudal vuelve por él.
		r["Q_alivio"] = caudal_bomba(p, pmax)
		if posicion == 0:
			r["P"] = pmax
			r["estado"] = "centro"
			if not motor:
				r["A"] = carga_a
				r["B"] = 0.0
				if p["pilotada"]["presente"]:
					r["deriva"] = DERIVA_PILOTADA_DANADA if p["pilotada"]["asiento_danado"] else 0.0
				else:
					r["deriva"] = DERIVA_CORREDERA
		else:
			r["estado"] = "tope"
			r["A"] = pmax if posicion > 0 else 0.0
			r["B"] = pmax if posicion < 0 else 0.0
			if not motor and act["fuga_juntas"] and posicion > 0:
				# Con la boca B suelta, lo que sale por ella es la fuga de la junta del pistón.
				r["fuga_B"] = K_JUNTAS * pmax
		r["calor"] = r["P"] * r["Q_alivio"] / 600.0
		return r
	if motor:
		return _resolver_motor(p, r, pmax)
	# Cilindro en movimiento.
	var avance := posicion > 0
	var a_entra := ar.x if avance else ar.y
	var a_sale := ar.y if avance else ar.x
	var apertura := maxf(float(p["estrangulador"]["apertura"]), 0.02) if p["estrangulador"]["presente"] and avance else 1.0
	var resistencia := carga_a if avance else FRICCION_RETROCESO
	var fuga := K_JUNTAS if act["fuga_juntas"] else 0.0
	# Presión de entrada para mover el cilindro con un caudal q hacia él (meter-out en el avance).
	var presion_para := func(q: float) -> float:
		var q_sale := q * a_sale / a_entra
		var contra := RETORNO + (C_ESTRANGULADOR * pow(q_sale / apertura, 2.0) if p["estrangulador"]["presente"] and avance else 0.0)
		return resistencia + contra * a_sale / a_entra
	var p0: float = presion_para.call(0.0)
	if p0 >= pmax:
		r["estado"] = "atascado"
		r["Q_alivio"] = caudal_bomba(p, pmax)
		r["A"] = pmax if avance else 0.0
		r["B"] = 0.0 if avance else pmax
		r["calor"] = pmax * r["Q_alivio"] / 600.0
		return r
	# Busca el caudal al actuador: el de la bomba a esa presión, o menos si el alivio abre.
	var bajo := 0.0
	var alto := caudal_teorico(p)
	for i in 40:
		var q := (bajo + alto) / 2.0
		var pr: float = presion_para.call(q)
		var disponible := caudal_bomba(p, pr) - fuga * pr
		if pr > pmax or q > disponible:
			alto = q
		else:
			bajo = q
	var q_act := bajo
	var pres: float = presion_para.call(q_act)
	var q_bomba := caudal_bomba(p, minf(pres, pmax))
	r["Q"] = q_act
	r["P"] = pres
	r["Q_alivio"] = maxf(q_bomba - q_act - fuga * pres, 0.0)
	if r["Q_alivio"] > 0.05:
		r["P"] = pmax
	r["A"] = r["P"] if avance else RETORNO
	r["B"] = (pres - resistencia) * a_entra / a_sale if avance else r["P"]
	r["velocidad"] = q_act * 1000.0 / 60.0 / a_entra * 10.0   # (L/min → cm³/s) / cm² = cm/s → mm/s
	r["estado"] = "avanza" if avance else "retrocede"
	r["calor"] = r["P"] * r["Q_alivio"] / 600.0
	return r


static func _resolver_motor(p: Dictionary, r: Dictionary, pmax: float) -> Dictionary:
	var act: Dictionary = p["actuador"]
	var vm := float(act["cilindrada"])
	var desgaste := clampf(float(act["desgaste"]), 0.0, 1.0)
	var dp := 20.0 * PI * float(act["par"]) / vm       # bar que pide el par
	var pres := dp + RETORNO
	var q_bomba := caudal_bomba(p, minf(pres, pmax))
	if pres >= pmax:
		r["estado"] = "atascado"
		r["Q_alivio"] = caudal_bomba(p, pmax)
		r["P"] = pmax
		r["calor"] = pmax * r["Q_alivio"] / 600.0
		return r
	var drenaje := q_bomba * (0.02 + 0.3 * desgaste) * pres / 160.0
	r["P"] = pres
	r["A"] = pres if int(p["direccional"]["posicion"]) > 0 else RETORNO
	r["B"] = RETORNO if int(p["direccional"]["posicion"]) > 0 else pres
	r["Q"] = q_bomba
	r["drenaje"] = drenaje
	r["rpm"] = (q_bomba - drenaje) * 1000.0 / vm
	r["par"] = float(act["par"])
	r["estado"] = "gira"
	return r


## Acumulador de vejiga: precarga real y volumen de aceite útil entre p_min y p_max, con la ley
## de Boyle a temperatura constante y presiones absolutas.
static func acumulador(params: Dictionary) -> Dictionary:
	var a: Dictionary = completar(params)["acumulador"]
	var p0 := float(a["precarga"]) * (1.0 - clampf(float(a["perdida_gas"]), 0.0, 1.0))
	var v0 := float(a["volumen"])
	var p1 := float(a["p_min"])
	var p2 := float(a["p_max"])
	var util := 0.0
	if p0 < p2:
		var desde := maxf(p0, p1)
		util = v0 * (p0 + 1.0) * (1.0 / (desde + 1.0) - 1.0 / (p2 + 1.0))
	return {"gas": p0, "volumen_util": util}


## Lectura de un punto: {valor, unidad, fuera_de_rango, averia}.
static func medir(medida: Dictionary) -> Dictionary:
	var params: Dictionary = medida.get("params", {})
	var punto := str(medida.get("punto", "P"))
	var valor := 0.0
	match punto:
		"gas", "volumen_util":
			valor = float(acumulador(params)[punto])
		"Q_bomba":
			# Caudalímetro con válvula de carga a la salida de la bomba: el caudal a esa presión.
			var p := completar(params)
			valor = caudal_bomba(p, minf(float(medida.get("presion_prueba", 0.0)), presion_maxima(p)))
		_:
			var r := resolver(params)
			if not r.has(punto):
				return {"valor": 0.0, "unidad": "", "fuera_de_rango": false, "averia": "punto_desconocido"}
			valor = float(r[punto])
	return {"valor": valor, "unidad": UNIDADES.get(punto, ""), "fuera_de_rango": false, "averia": ""}
