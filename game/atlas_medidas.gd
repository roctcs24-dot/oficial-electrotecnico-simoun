class_name AtlasMedidas
extends RefCounted
## Las lecturas de las tablas «Medir» y de las fallas del atlas se calculan con la simulación,
## no se escriben a mano. Cada medida del JSON dice qué circuito montar, qué cambiar en él y
## con qué instrumento medir:
##   {"circuito": "medir_contactor", "estado": {"K1": {"bobina_quemada": true}},
##    "params": {"B": {"v_linea": 300}}, "segundos": 2, "instrumento": "multimetro",
##    "modo": "ohm", "a": "K1.A1", "b": "K1.A2"}
## Con la pinza, "cable": ["F2.2", "M1.U1"] dice qué conductor abraza, o "cables" varios a la
## vez; la pinza de fugas mide en mA lo que no vuelve por los conductores que abraza. Con el
## megóhmetro, "v_prueba" elige 250, 500 o 1000 V. "monitor" lee el monitor de aislamiento
## "id" de la propia red. "aparato" lee la pantalla o la aguja del componente "id" (un
## amperímetro, un analizador de red o un variador), con su "magnitud". Una medida puede llevar "valor" escrito en su lugar:
## solo se admite en las fallas, para lo que la simulación no modela.


## Las lecturas ya calculadas: el contenido no cambia mientras el juego está abierto.
static var _cache := {}


## La medida de una fila: la del grupo con los cambios de la fila. "estado" y "params" se
## mezclan componente a componente; el resto de claves se sustituye.
static func combinar(base: Dictionary, cambios: Dictionary) -> Dictionary:
	var r := base.duplicate(true)
	for clave: String in cambios:
		if clave in ["estado", "params"]:
			var mezcla: Dictionary = r.get(clave, {})
			for id: String in cambios[clave]:
				var previo: Dictionary = mezcla.get(id, {})
				previo.merge(cambios[clave][id], true)
				mezcla[id] = previo
			r[clave] = mezcla
		else:
			r[clave] = cambios[clave]
	return r


## Devuelve {valor, unidad, fuera_de_rango, averia, texto}, o {texto, averia} con el motivo
## si la medida no se puede hacer.
static func medir(contenido: Contenido, medida: Dictionary) -> Dictionary:
	if medida.has("valor"):
		return {"texto": str(medida["valor"]), "averia": ""}
	var clave := JSON.stringify(medida, "", true)
	if not _cache.has(clave):
		_cache[clave] = _medir(contenido, medida)
	return _cache[clave].duplicate()


static func _medir(contenido: Contenido, medida: Dictionary) -> Dictionary:
	var datos := contenido.circuito_datos(str(medida.get("circuito", "")))
	if datos.is_empty():
		return {"texto": "?", "averia": "sin_circuito"}
	for c: Dictionary in datos.get("componentes", []):
		var id: String = c["id"]
		if medida.get("params", {}).has(id):
			var p: Dictionary = c.get("params", {})
			p.merge(medida["params"][id], true)
			c["params"] = p
		if medida.get("estado", {}).has(id):
			var e: Dictionary = c.get("estado", {})
			e.merge(medida["estado"][id], true)
			c["estado"] = e
	var sim := SimSimulacion.desde_dict(datos)
	var segundos := float(medida.get("segundos", 0.0))
	if segundos > 0.0:
		sim.avanzar_tiempo(segundos)
	var r := {}
	match str(medida.get("instrumento", "multimetro")):
		"multimetro":
			var m := SimMultimetro.new()
			m.ruido = 0.0
			r = m.medir(sim, str(medida.get("modo", "ohm")), medida["a"], medida["b"])
		"megohmetro":
			var mg := SimMegohmetro.new()
			mg.ruido = 0.0
			var lectura := mg.medir(sim, medida["a"], medida["b"], int(medida.get("v_prueba", 500)))
			r = {"valor": lectura["mohm"], "unidad": "MΩ", "fuera_de_rango": lectura["fuera_de_rango"], "averia": lectura["averia"]}
		"pinza":
			var pz := SimPinza.new()
			pz.ruido = 0.0
			r = pz.medir(sim, _indices(sim, medida))
		"pinza_fugas":
			r = {"valor": _suma_corrientes(sim, _indices(sim, medida)) * 1000.0, "unidad": "mA", "fuera_de_rango": false, "averia": ""}
		"monitor":
			var mohm: float = (sim.componente(str(medida.get("id", ""))) as SimMonitorAislamiento).medir()
			r = {"valor": mohm, "unidad": "MΩ", "fuera_de_rango": mohm >= SimMonitorAislamiento.MOHM_MAX, "averia": ""}
		"aparato":
			var aparato := sim.componente(str(medida.get("id", "")))
			if aparato == null or not aparato.has_method("leer"):
				return {"texto": "?", "averia": "aparato_desconocido"}
			r = aparato.call("leer", sim.resolver(), str(medida.get("magnitud", "")))
		_:
			return {"texto": "?", "averia": "instrumento_desconocido"}
	if not r.has("texto"):
		r["texto"] = texto(r)
	return r


static func _indices(sim: SimSimulacion, medida: Dictionary) -> Array:
	var lista: Array = []
	var cables: Array = medida.get("cables", [medida.get("cable", [])])
	for c: Array in cables:
		var i := _indice_cable(sim, c)
		if i >= 0:
			lista.append(i)
	return lista


## Suma de las corrientes de los cables abrazados, como la pinza pero sin su resolución de 0,1 A.
static func _suma_corrientes(sim: SimSimulacion, cables: Array) -> float:
	if cables.is_empty():
		return 0.0
	var sol := sim.resolver(false, func(e: SimEstampa) -> void:
		for i: int in cables:
			e.impedancia(sim.cables[i][0], sim.cables[i][1], SimPinza.R_SONDA), cables)
	var suma := Cx.new(0.0, 0.0)
	for i: int in cables:
		suma = suma.mas(sol.entre(sim.cables[i][0], sim.cables[i][1]).escala(1.0 / SimPinza.R_SONDA))
	return suma.modulo()


static func _indice_cable(sim: SimSimulacion, cable: Array) -> int:
	if cable.size() != 2:
		return -1
	for i in sim.cables.size():
		var c: Array = sim.cables[i]
		if (c[0] == cable[0] and c[1] == cable[1]) or (c[0] == cable[1] and c[1] == cable[0]):
			return i
	return -1


## Lectura como la mostraría la pantalla del instrumento, con coma decimal.
static func texto(r: Dictionary) -> String:
	if not str(r.get("averia", "")).is_empty():
		return "—"
	var unidad: String = r.get("unidad", "")
	var v := float(r.get("valor", 0.0))
	if r.get("fuera_de_rango", false):
		return "> 999 MΩ" if unidad == "MΩ" else "OL"
	match unidad:
		"Ω":
			if v < 1.0:
				return "%s Ω" % _numero(v, 1)
			if v >= 1000.0:
				return "%s kΩ" % _numero(v / 1000.0, 1)
			return "%d Ω" % roundi(v)
		"V", "A", "mA", "Hz":
			return "%s %s" % [_numero(v, 0 if v >= 20.0 else 1), unidad]
		"MΩ":
			return "%s MΩ" % _numero(v, 0 if v >= 20.0 else 1)
	return "%s %s" % [_numero(v, 1), unidad]


static func _numero(v: float, decimales: int) -> String:
	if decimales == 0:
		return str(roundi(v))
	return (("%." + str(decimales) + "f") % v).replace(".", ",")
