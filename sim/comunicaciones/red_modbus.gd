class_name SimRedModbus
extends RefCounted
## Red Modbus RTU sobre un bus RS-485 de dos hilos, A y B, con su pantalla.
##
## El maestro está en un extremo del bus y los esclavos siguen en el orden del archivo; el
## último esclavo es el otro extremo. Cada equipo tiene dirección, velocidad, formato del
## carácter (8N1, 8E1...), resistencia de terminación, polaridad de A y B y alimentación.
##
## El maestro recorre su tabla de sondeo: a cada dirección le pide sus registros con la
## función 03 (leer registros de retención) y espera la respuesta hasta su tiempo de espera.
## Resultado de cada petición:
##   ok         la respuesta llega bien y los valores se guardan.
##   sin_respuesta  nadie contesta: equipo apagado, cable cortado antes de él, A y B
##              invertidos, velocidad o formato distintos, o dirección que nadie tiene.
##   crc        llega una trama con el CRC mal: dos equipos con la misma dirección, o la
##              señal deformada por reflexiones (falta un terminador) o por ruido.
##   excepcion  contesta un equipo que no tiene esos registros (excepción 02).
## Tras FALLOS_PARA_FALLA peticiones seguidas sin una respuesta correcta, el maestro da
## falla de comunicación con ese esclavo, hasta que vuelva a contestar bien.
##
## Valores típicos — verificar a bordo: la red real del buque, sus equipos y sus ajustes.

const FALLOS_PARA_FALLA := 3
const HISTORIA := 20
const BITS_POR_CARACTER := 11
const R_TERMINADOR := 120.0
## Carga unitaria de un transceptor RS-485 (TIA-485): unos 12 kΩ entre A y B.
const R_TRANSCEPTOR := 12000.0
const VELOCIDADES := [4800, 9600, 19200, 38400]
const FORMATOS := ["8N1", "8E1", "8O1", "8N2"]
const DIRECCION_MAX := 247

var datos: Dictionary
var maestro: Dictionary
## Esclavos en el orden del bus, desde el maestro.
var esclavos: Array[Dictionary] = []
## Estado del sondeo por dirección de la tabla del maestro.
var sondeo: Array[Dictionary] = []
## Segundos de simulación desde el principio.
var reloj := 0.0
## Índice del equipo del bus antes del que está cortado el cable, o -1. 0 es entre el
## maestro y el primer esclavo.
var corte := -1
var ruido := 0.0
## El cable entre la pantalla local (HMI) y su controlador está suelto.
var hmi_sin_comunicacion := false
var _rng := RandomNumberGenerator.new()
var _indice := 0
var _acumulado := 0.0
var _ciclo_inicio := 0.0
var ciclo_s := 0.0


static func desde_dict(d: Dictionary) -> SimRedModbus:
	var r := SimRedModbus.new()
	r.datos = d.duplicate(true)
	r.maestro = r.datos["maestro"]
	for clave: String in ["baudios", "formato", "timeout_ms", "terminacion"]:
		if not r.maestro.has(clave):
			r.maestro[clave] = {"baudios": 19200, "formato": "8E1", "timeout_ms": 200, "terminacion": true}[clave]
	for e: Dictionary in r.datos.get("esclavos", []):
		var base := {"baudios": 19200, "formato": "8E1", "terminacion": false, "invertido": false, "alimentado": true, "registros": []}
		base.merge(e, true)
		for reg: Dictionary in base["registros"]:
			reg["inicial"] = reg["valor"]
		r.esclavos.append(base)
	for entrada: Dictionary in r.maestro.get("sondeo", []):
		r.sondeo.append({
			"datos": entrada, "estado": "ok", "fallos": 0, "historia": [], "ultimo": "",
			"valores": [], "peticiones": 0, "correctas": 0, "sin_respuesta": 0, "crc": 0, "excepciones": 0,
		})
	# El JSON da los números como decimales: los ajustes de comunicación son enteros.
	for e: Dictionary in [r.maestro] + r.esclavos:
		for clave in ["baudios", "direccion", "timeout_ms"]:
			if e.has(clave):
				e[clave] = int(e[clave])
	r._rng.seed = int(d.get("semilla", 1))
	return r


func longitud_m() -> float:
	return float(datos.get("longitud_m", 150.0))


func esclavo(id: String) -> Dictionary:
	for e in esclavos:
		if e["id"] == id:
			return e
	return {}


func indice_esclavo(id: String) -> int:
	for i in esclavos.size():
		if esclavos[i]["id"] == id:
			return i
	return -1


func entrada_sondeo(direccion: int) -> Dictionary:
	for s in sondeo:
		if int(s["datos"]["direccion"]) == direccion:
			return s
	return {}


## Estado de comunicación de la entrada de la tabla que corresponde a un esclavo esperado.
func estado_de(id_esperado: String) -> Dictionary:
	for s in sondeo:
		if s["datos"].get("esperado", "") == id_esperado:
			return s
	return {}


# --- Capa física ---

## Equipos (maestro y esclavos) con la resistencia de terminación puesta.
func terminadores() -> int:
	var n := 1 if maestro["terminacion"] else 0
	for e in esclavos:
		if e["terminacion"]:
			n += 1
	return n


## Los dos extremos del bus, el maestro y el último esclavo, tienen su terminador.
func extremos_terminados() -> bool:
	return maestro["terminacion"] and (esclavos.is_empty() or esclavos[-1]["terminacion"])


## Esclavos que el maestro alcanza por el cable, sin pasar por un corte.
func alcanzable(i: int) -> bool:
	return corte < 0 or i < corte


## Resistencia entre A y B medida en el conector del maestro, con la red sin alimentación:
## los terminadores y los transceptores en paralelo, hasta el corte si lo hay.
func resistencia_a_b() -> float:
	var g := (1.0 / R_TERMINADOR if maestro["terminacion"] else 0.0) + 1.0 / R_TRANSCEPTOR
	for i in esclavos.size():
		if not alcanzable(i):
			break
		g += (1.0 / R_TERMINADOR if esclavos[i]["terminacion"] else 0.0) + 1.0 / R_TRANSCEPTOR
	return 1.0 / g


## Probabilidad de que una trama llegue deformada, por reflexiones o por ruido.
func probabilidad_error() -> float:
	var p := ruido
	var factor := longitud_m() * float(maestro["baudios"]) / 9600.0
	if not maestro["terminacion"]:
		p += factor / 1200.0
	var ultimo := _ultimo_alcanzable()
	if ultimo >= 0 and not esclavos[ultimo]["terminacion"]:
		p += factor / 1200.0
	# Terminadores de más en el medio del bus: la señal llega con poca amplitud.
	for i in esclavos.size():
		if i != esclavos.size() - 1 and esclavos[i]["terminacion"]:
			p += 0.08
	return clampf(p, 0.0, 0.9)


func _ultimo_alcanzable() -> int:
	var ultimo := -1
	for i in esclavos.size():
		if alcanzable(i):
			ultimo = i
	return ultimo


## El esclavo entiende las tramas del maestro: mismos ajustes, cable y alimentación bien.
func entiende(i: int) -> bool:
	var e := esclavos[i]
	return alcanzable(i) and e["alimentado"] and not e["invertido"] \
		and int(e["baudios"]) == int(maestro["baudios"]) and e["formato"] == maestro["formato"]


# --- Sondeo ---

## Duración de una petición y su respuesta, en segundos.
func duracion_transaccion(entrada: Dictionary, resultado: String) -> float:
	var baudios := float(maestro["baudios"])
	var silencio := 3.5 * BITS_POR_CARACTER / baudios
	var peticion := 8.0 * BITS_POR_CARACTER / baudios
	if resultado == "sin_respuesta":
		return peticion + silencio + float(maestro["timeout_ms"]) / 1000.0
	var n := int(entrada["datos"].get("cantidad", 1))
	return peticion + silencio * 2.0 + (5.0 + 2.0 * n) * BITS_POR_CARACTER / baudios


func avanzar(dt: float) -> void:
	if sondeo.is_empty():
		reloj += dt
		return
	_acumulado += dt
	while true:
		var s := sondeo[_indice]
		var resultado := _responder(s)
		var d := duracion_transaccion(s, resultado["tipo"])
		if _acumulado < d:
			break
		_acumulado -= d
		reloj += d
		_registrar(s, resultado)
		_indice += 1
		if _indice >= sondeo.size():
			_indice = 0
			ciclo_s = reloj - _ciclo_inicio
			_ciclo_inicio = reloj
	_avanzar_procesos(dt)


## Simula hasta completar n vueltas a la tabla de sondeo.
func ciclos(n: int) -> void:
	for _i in n * sondeo.size():
		var s := sondeo[_indice]
		var resultado := _responder(s)
		var d := duracion_transaccion(s, resultado["tipo"])
		reloj += d
		_registrar(s, resultado)
		_avanzar_procesos(d)
		_indice = (_indice + 1) % sondeo.size()
		if _indice == 0:
			ciclo_s = reloj - _ciclo_inicio
			_ciclo_inicio = reloj


## Quién contesta a una petición y cómo llega la respuesta.
func _responder(s: Dictionary) -> Dictionary:
	var direccion := int(s["datos"]["direccion"])
	var cantidad := int(s["datos"].get("cantidad", 1))
	var responden: Array[int] = []
	for i in esclavos.size():
		if int(esclavos[i]["direccion"]) == direccion and entiende(i):
			responden.append(i)
	if responden.is_empty():
		return {"tipo": "sin_respuesta"}
	if responden.size() > 1:
		return {"tipo": "crc", "motivo": "colision"}
	var e := esclavos[responden[0]]
	if (e["registros"] as Array).size() < cantidad:
		return {"tipo": "excepcion", "esclavo": e["id"]}
	# La respuesta se deforma con la misma probabilidad que la trama de la petición.
	if _rng.randf() < probabilidad_error():
		return {"tipo": "crc", "motivo": "senal"}
	var valores: Array[float] = []
	for k in cantidad:
		valores.append(_leer_registro(e["registros"][k]))
	return {"tipo": "ok", "esclavo": e["id"], "valores": valores}


## El registro guarda un entero: el valor en unidades de ingeniería dividido por la escala.
func _leer_registro(reg: Dictionary) -> float:
	var escala := float(reg.get("escala", 1.0))
	var v := float(reg["valor"]) + _rng.randfn(0.0, float(reg.get("ruido", 0.0)))
	return roundf(v / escala) * escala


func _registrar(s: Dictionary, r: Dictionary) -> void:
	s["peticiones"] += 1
	s["ultimo"] = r["tipo"]
	var historia: Array = s["historia"]
	historia.append(r["tipo"])
	if historia.size() > HISTORIA:
		historia.pop_front()
	match r["tipo"]:
		"ok":
			s["correctas"] += 1
			s["fallos"] = 0
			s["valores"] = r["valores"]
			s["contesta"] = r["esclavo"]
		"sin_respuesta":
			s["sin_respuesta"] += 1
			s["fallos"] += 1
		"crc":
			s["crc"] += 1
			s["fallos"] += 1
		"excepcion":
			s["excepciones"] += 1
			s["fallos"] += 1
			s["contesta"] = r["esclavo"]
	s["estado"] = _estado(s)


func _estado(s: Dictionary) -> String:
	if int(s["fallos"]) >= FALLOS_PARA_FALLA:
		return "falla"
	var malas := 0
	for r: String in s["historia"]:
		if r != "ok":
			malas += 1
	return "intermitente" if malas * 10 > (s["historia"] as Array).size() else "ok"


## Las rampas de las averías mueven los valores del proceso, como una temperatura que sube.
func _avanzar_procesos(dt: float) -> void:
	for e in esclavos:
		for reg: Dictionary in e["registros"]:
			if reg.has("rampa"):
				var hasta := float(reg.get("hasta", 1e9))
				var v := float(reg["valor"]) + float(reg["rampa"]) * dt
				reg["valor"] = minf(v, hasta) if float(reg["rampa"]) > 0.0 else maxf(v, hasta)


## Valor de un registro de la tabla del maestro, o NAN si no hay un dato válido.
func valor(direccion: int, k: int) -> float:
	var s := entrada_sondeo(direccion)
	if s.is_empty() or s["estado"] == "falla" or k >= (s["valores"] as Array).size():
		return NAN
	return s["valores"][k]


## Valor real de un registro de un esclavo, como lo ve su pantalla local.
func valor_local(id: String, k: int) -> float:
	var e := esclavo(id)
	if e.is_empty() or not e["alimentado"]:
		return NAN
	return float(e["registros"][k]["valor"])


# --- Ajustes y averías ---

func ajustar(id: String, clave: String, v: Variant) -> void:
	var destino := maestro if id == maestro["id"] else esclavo(id)
	if destino.is_empty():
		push_error("Equipo %s no está en la red" % id)
		return
	destino[clave] = v


## Aplica una avería o una reparación: {op: "ajuste"|"corte"|"ruido"|"valor"|"rampa", ...}.
func aplicar(a: Dictionary) -> void:
	match a["op"]:
		"ajuste":
			ajustar(a["equipo"], a["clave"], a["valor"])
		"corte":
			corte = indice_esclavo(a["antes_de"]) if a.get("antes_de", "") != "" else -1
		"ruido":
			ruido = float(a["valor"])
		"hmi":
			hmi_sin_comunicacion = bool(a["valor"])
		"valor", "rampa":
			var reg: Dictionary = esclavo(a["equipo"])["registros"][int(a["registro"])]
			if a["op"] == "valor":
				reg.erase("rampa")
				reg["valor"] = float(a["valor"])
			else:
				reg["rampa"] = float(a["valor"])
				reg["hasta"] = float(a["hasta"])
		_:
			push_error("Operación de red desconocida: %s" % a["op"])


## Reponer el proceso a sus valores normales, sin tocar los ajustes de la red.
func normalizar_proceso() -> void:
	for e in esclavos:
		for reg: Dictionary in e["registros"]:
			reg.erase("rampa")
			reg["valor"] = reg["inicial"]


## Contadores a cero, como el botón de reponer diagnóstico de un maestro.
func reponer_contadores() -> void:
	for s in sondeo:
		for clave in ["peticiones", "correctas", "sin_respuesta", "crc", "excepciones"]:
			s[clave] = 0
		s["historia"] = []


static func siguiente(lista: Array, actual: Variant, paso := 1) -> Variant:
	var i := lista.find(actual)
	return lista[posmod(i + paso, lista.size())]
