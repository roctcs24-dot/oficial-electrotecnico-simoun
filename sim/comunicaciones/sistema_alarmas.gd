class_name SimSistemaAlarmas
extends RefCounted
## Sistema de alarmas y monitoreo: vigila valores y estados y gestiona cada alarma como un
## puesto de alarmas de sala de máquinas (estados según ISA-18.2 / IEC 62682):
##   normal       sin alarma.
##   activa       la condición está presente y nadie la ha reconocido: parpadea y suena.
##   reconocida   la condición sigue presente, pero ya se reconoció: luz fija.
##   retorno      la condición desapareció antes de reconocerla: parpadea lento hasta que
##                se reconozca.
## Silenciar apaga la bocina; no reconoce nada. Reconocer pasa las activas a reconocidas y
## borra las que ya volvieron a la normalidad.
## Si una alarma sigue sin reconocer más de tiempo_extension_s, se extiende a los camarotes
## de los oficiales (llamada al oficial de guardia, buques con cámara de máquinas sin
## dotación permanente: valor típico — verificar a bordo).
##
## Cada punto es {id, texto, tipo: alta|baja|digital|comunicacion, limite, histeresis,
## retardo_s} y el lector devuelve su valor (NAN si no hay dato válido: el punto se queda
## como está, salvo los de comunicación).

const TIEMPO_EXTENSION_S := 180.0
const MAX_HISTORIAL := 200

var puntos: Array[Dictionary] = []
var lector: Callable
var reloj := 0.0
var hora_inicio := 2 * 3600 + 14 * 60
var bocina := false
var extension := false
var prueba_lamparas := false
var historial: Array[Dictionary] = []
var tiempo_extension_s := TIEMPO_EXTENSION_S


func _init(lista: Array, lector_valores: Callable) -> void:
	lector = lector_valores
	for p: Dictionary in lista:
		var punto := {"tipo": "alta", "limite": 0.0, "histeresis": -1.0, "retardo_s": 0.0}
		punto.merge(p, true)
		if float(punto["histeresis"]) < 0.0:
			punto["histeresis"] = maxf(absf(float(punto["limite"])) * 0.02, 0.05)
		punto.merge({"estado": "normal", "pendiente": 0.0, "desde": 0.0, "inhibida": false}, true)
		puntos.append(punto)


## Puntos del puesto de alarmas a partir de la tabla de sondeo de una red Modbus: cada canal
## con sus límites y una alarma de falla de comunicación por cada equipo.
static func desde_red(red: SimRedModbus) -> SimSistemaAlarmas:
	var lista: Array = []
	for s: Dictionary in red.sondeo:
		var d: Dictionary = s["datos"]
		lista.append({"id": "%s-COM" % d["esperado"], "texto": "Falla de comunicación: %s" % d["nombre"], "tipo": "comunicacion", "direccion": int(d["direccion"])})
		for c: Dictionary in d.get("canales", []):
			for tipo: String in ["alta", "baja", "digital"]:
				if c.has(tipo):
					var texto: String = c.get("texto_" + tipo, "%s %s" % [c["nombre"], {"alta": "alta", "baja": "baja", "digital": ""}[tipo]]).strip_edges()
					var limite: float = 0.5 if tipo == "digital" else float(c[tipo])
					lista.append({
						"id": "%s-%s" % [c["tag"], tipo], "texto": texto, "tipo": tipo, "limite": limite,
						"retardo_s": float(c.get("retardo_s", 0.0)), "direccion": int(d["direccion"]), "registro": int(c["reg"]),
						"histeresis": float(c.get("histeresis", -1.0)),
					})
	var lectura := func(p: Dictionary) -> float:
		if p["tipo"] == "comunicacion":
			return 1.0 if red.entrada_sondeo(p["direccion"])["estado"] == "falla" else 0.0
		return red.valor(p["direccion"], p["registro"])
	return SimSistemaAlarmas.new(lista, lectura)


func punto(id: String) -> Dictionary:
	for p in puntos:
		if p["id"] == id:
			return p
	return {}


func estado(id: String) -> String:
	return punto(id).get("estado", "")


## Hora del barco en el reloj del puesto, hh:mm:ss.
func hora(segundos := -1.0) -> String:
	var s := int(hora_inicio + (reloj if segundos < 0.0 else segundos)) % 86400
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func _condicion(p: Dictionary, v: float, presente: bool) -> bool:
	var h := float(p["histeresis"])
	var limite := float(p["limite"])
	match p["tipo"]:
		"alta":
			return v > limite or (presente and v > limite - h)
		"baja":
			return v < limite or (presente and v < limite + h)
		_:
			return v > 0.5


func actualizar(dt: float) -> void:
	reloj += dt
	for p in puntos:
		if p["inhibida"]:
			continue
		var v: float = lector.call(p)
		if is_nan(v):
			continue
		var presente: bool = p["estado"] in ["activa", "reconocida"]
		var hay := _condicion(p, v, presente)
		if hay and not presente:
			p["pendiente"] += dt
			if p["pendiente"] >= float(p["retardo_s"]):
				p["estado"] = "activa"
				p["desde"] = reloj
				p["valor_alarma"] = v
				bocina = true
				_anotar(p, "ALARMA")
		elif not hay:
			p["pendiente"] = 0.0
			if p["estado"] == "activa":
				p["estado"] = "retorno"
				_anotar(p, "NORMAL")
			elif p["estado"] == "reconocida":
				p["estado"] = "normal"
				_anotar(p, "NORMAL")
	extension = false
	for p in puntos:
		if p["estado"] == "activa" and reloj - float(p["desde"]) >= tiempo_extension_s:
			extension = true


func _anotar(p: Dictionary, evento: String) -> void:
	historial.push_front({"hora": hora(), "id": p["id"], "texto": p["texto"], "evento": evento})
	if historial.size() > MAX_HISTORIAL:
		historial.pop_back()


func silenciar() -> void:
	bocina = false


func reconocer() -> void:
	bocina = false
	for p in puntos:
		if p["estado"] == "activa":
			p["estado"] = "reconocida"
			_anotar(p, "RECONOCIDA")
		elif p["estado"] == "retorno":
			p["estado"] = "normal"
			_anotar(p, "RECONOCIDA")
	extension = false


## Las alarmas que se muestran: primero las que no se han reconocido, después las demás.
func visibles() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for orden in ["activa", "retorno", "reconocida"]:
		for p in puntos:
			if p["estado"] == orden:
				lista.append(p)
	return lista


func sin_reconocer() -> int:
	var n := 0
	for p in puntos:
		if p["estado"] in ["activa", "retorno"]:
			n += 1
	return n


func activas() -> int:
	var n := 0
	for p in puntos:
		if p["estado"] in ["activa", "reconocida"]:
			n += 1
	return n
