class_name SimLadder
extends RefCounted
## Intérprete de lenguaje de contactos (ladder) con direcciones IEC 61131-3: %I entradas,
## %Q salidas, %M marcas, %T temporizadores, %C contadores, %IW palabras de entrada
## analógica (en unidades de ingeniería) y %AE bit de error de una entrada analógica.
##
## Un programa es una lista de peldaños {logica, salidas}. logica es una serie de elementos:
##   {"na": "%I0.0"}  contacto normalmente abierto: pasa si el bit vale 1
##   {"nc": "%I0.1"}  contacto normalmente cerrado: pasa si el bit vale 0
##   {"flanco": "%I0.2"}  pasa solo en el scan en que el bit pasa de 0 a 1
##   {"cmp": ">=", "a": "%IW0", "b": 12.5}  comparación de una palabra con un número o palabra
##   {"paralelo": [serie, serie, ...]}  ramas en paralelo, cada una una serie
## salidas son las bobinas que reciben el resultado:
##   {"bobina": "%Q0.0"}, {"set": "%M0.0"}, {"reset": "%M0.0"},
##   {"ton": "%T0", "ms": 3000}, {"tof": "%T1", "ms": 2000},
##   {"ctu": "%C0", "pv": 5}, {"rst": "%C0"}
## Una serie vacía siempre pasa.

const COMPARADORES := [">", ">=", "<", "<=", "==", "!="]


## Memoria vacía del autómata.
static func memoria() -> Dictionary:
	return {"bits": {}, "palabras": {}, "temporizadores": {}, "contadores": {}, "previos": {}}


## Un scan del programa: los peldaños de arriba abajo, cada uno de izquierda a derecha.
static func ejecutar(programa: Array, mem: Dictionary, dt: float) -> void:
	var flancos := {}
	for peldano: Dictionary in programa:
		var flujo := serie(peldano.get("logica", []), mem, flancos)
		for s: Dictionary in peldano.get("salidas", []):
			_salida(s, flujo, mem, dt)
	# Un flanco vale solo el scan en que cambia: se guarda el valor para el siguiente.
	for direccion: String in flancos:
		mem["previos"][direccion] = bit(mem, direccion)


## Evalúa todos los elementos de la serie, sin cortar en el primero que no pasa.
static func serie(elementos: Array, mem: Dictionary, flancos := {}) -> bool:
	var pasa := true
	for e: Dictionary in elementos:
		if not elemento(e, mem, flancos):
			pasa = false
	return pasa


static func elemento(e: Dictionary, mem: Dictionary, flancos := {}) -> bool:
	if e.has("na"):
		return bit(mem, e["na"])
	if e.has("nc"):
		return not bit(mem, e["nc"])
	if e.has("flanco"):
		flancos[e["flanco"]] = true
		return bit(mem, e["flanco"]) and not mem["previos"].get(e["flanco"], false)
	if e.has("cmp"):
		return _comparar(e["cmp"], _numero(mem, e["a"]), _numero(mem, e["b"]))
	if e.has("paralelo"):
		var alguna := false
		for rama: Array in e["paralelo"]:
			if serie(rama, mem, flancos):
				alguna = true
		return alguna
	push_error("Elemento de ladder desconocido: %s" % str(e))
	return false


## Valor de un bit. %T y %C dan su salida Q; los bits que nunca se escribieron valen 0.
static func bit(mem: Dictionary, direccion: String) -> bool:
	if direccion.begins_with("%T"):
		return mem["temporizadores"].get(direccion, {}).get("q", false)
	if direccion.begins_with("%C"):
		return mem["contadores"].get(direccion, {}).get("q", false)
	return mem["bits"].get(direccion, false)


static func _numero(mem: Dictionary, valor: Variant) -> float:
	if valor is String:
		return float(mem["palabras"].get(valor, 0.0))
	return float(valor)


static func _comparar(operador: String, a: float, b: float) -> bool:
	match operador:
		">":
			return a > b
		">=":
			return a >= b
		"<":
			return a < b
		"<=":
			return a <= b
		"==":
			return is_equal_approx(a, b)
		"!=":
			return not is_equal_approx(a, b)
	push_error("Comparador desconocido: %s" % operador)
	return false


static func _salida(s: Dictionary, flujo: bool, mem: Dictionary, dt: float) -> void:
	if s.has("bobina"):
		mem["bits"][s["bobina"]] = flujo
	elif s.has("set"):
		if flujo:
			mem["bits"][s["set"]] = true
	elif s.has("reset"):
		if flujo:
			mem["bits"][s["reset"]] = false
	elif s.has("ton"):
		var t := _temporizador(mem, s["ton"], s["ms"])
		if flujo:
			t["acc_ms"] = minf(t["acc_ms"] + dt * 1000.0, t["pt_ms"])
		else:
			t["acc_ms"] = 0.0
		t["q"] = flujo and t["acc_ms"] >= t["pt_ms"]
	elif s.has("tof"):
		var t := _temporizador(mem, s["tof"], s["ms"])
		if flujo:
			t["acc_ms"] = 0.0
			t["q"] = true
		elif t["q"]:
			t["acc_ms"] = minf(t["acc_ms"] + dt * 1000.0, t["pt_ms"])
			if t["acc_ms"] >= t["pt_ms"]:
				t["q"] = false
	elif s.has("ctu"):
		var c := _contador(mem, s["ctu"], s["pv"])
		if flujo and not c["entrada"]:
			c["cv"] += 1
		c["entrada"] = flujo
		c["q"] = c["cv"] >= c["pv"]
	elif s.has("rst"):
		if flujo:
			var c: Dictionary = mem["contadores"].get(s["rst"], {})
			if not c.is_empty():
				c["cv"] = 0
				c["q"] = false
	else:
		push_error("Salida de ladder desconocida: %s" % str(s))


static func _temporizador(mem: Dictionary, direccion: String, ms: float) -> Dictionary:
	if not mem["temporizadores"].has(direccion):
		mem["temporizadores"][direccion] = {"acc_ms": 0.0, "q": false, "pt_ms": float(ms)}
	var t: Dictionary = mem["temporizadores"][direccion]
	t["pt_ms"] = float(ms)
	return t


static func _contador(mem: Dictionary, direccion: String, pv: int) -> Dictionary:
	if not mem["contadores"].has(direccion):
		mem["contadores"][direccion] = {"cv": 0, "q": false, "pv": int(pv), "entrada": false}
	var c: Dictionary = mem["contadores"][direccion]
	c["pv"] = int(pv)
	return c


## Direcciones que usa un programa, en orden de aparición, para listar sus etiquetas.
static func direcciones(programa: Array) -> Array[String]:
	var lista: Array[String] = []
	for peldano: Dictionary in programa:
		_direcciones_serie(peldano.get("logica", []), lista)
		for s: Dictionary in peldano.get("salidas", []):
			for clave in ["bobina", "set", "reset", "ton", "tof", "ctu", "rst"]:
				if s.has(clave) and not lista.has(s[clave]):
					lista.append(s[clave])
	return lista


static func _direcciones_serie(elementos: Array, lista: Array[String]) -> void:
	for e: Dictionary in elementos:
		for clave in ["na", "nc", "flanco", "a", "b"]:
			if e.get(clave) is String and not lista.has(e[clave]):
				lista.append(e[clave])
		for rama: Array in e.get("paralelo", []):
			_direcciones_serie(rama, lista)
