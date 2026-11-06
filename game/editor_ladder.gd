class_name EditorLadder
extends RefCounted
## Cambios sobre un programa ladder (ver SimLadder), sin interfaz. Un elemento se señala por su
## ruta: [peldaño, "logica", i] para un contacto de la serie principal, y dentro de un paralelo
## se añaden la rama y la posición: [peldaño, "logica", i, rama, j]. Las salidas son
## [peldaño, "salidas", i]. Los cambios modifican el programa recibido.

const CONTACTOS := ["na", "nc", "flanco"]
const SALIDAS := ["bobina", "set", "reset", "ton", "tof", "ctu", "rst"]
const DIRECCIONES_CONTACTO := [
	"%I0.0", "%I0.1", "%I0.2", "%I0.3", "%I0.4", "%I0.5", "%I0.6", "%I0.7",
	"%Q0.0", "%Q0.1", "%Q0.2", "%Q0.3", "%Q0.4", "%Q0.5",
	"%M0.0", "%M0.1", "%M0.2", "%M0.3", "%M0.4", "%M0.5", "%M0.6", "%M0.7",
	"%T0", "%T1", "%T2", "%T3", "%C0", "%C1", "%AE0",
]
const DIRECCIONES_BOBINA := [
	"%Q0.0", "%Q0.1", "%Q0.2", "%Q0.3", "%Q0.4", "%Q0.5",
	"%M0.0", "%M0.1", "%M0.2", "%M0.3", "%M0.4", "%M0.5", "%M0.6", "%M0.7",
]
const DIRECCIONES_TEMPORIZADOR := ["%T0", "%T1", "%T2", "%T3"]
const DIRECCIONES_CONTADOR := ["%C0", "%C1"]
const PASO_MS := 500.0


## La lista que contiene el elemento de la ruta, y su posición en ella.
static func _lista(programa: Array, ruta: Array) -> Array:
	var lista: Array = programa[ruta[0]][ruta[1]]
	var i := 2
	while i + 2 < ruta.size():
		lista = lista[ruta[i]]["paralelo"][ruta[i + 1]]
		i += 2
	return [lista, ruta[i]]


static func obtener(programa: Array, ruta: Array) -> Dictionary:
	if ruta.size() < 3 or ruta[0] >= programa.size():
		return {}
	var l := _lista(programa, ruta)
	var lista: Array = l[0]
	return lista[l[1]] if l[1] < lista.size() else {}


static func es_salida(ruta: Array) -> bool:
	return ruta.size() == 3 and ruta[1] == "salidas"


## Tipo del elemento: na, nc, flanco, cmp, paralelo, o el de la salida.
static func tipo(e: Dictionary) -> String:
	for clave in CONTACTOS + SALIDAS + ["cmp", "paralelo"]:
		if e.has(clave):
			return clave
	return ""


static func direccion(e: Dictionary) -> String:
	var t := tipo(e)
	if t == "cmp":
		return e["a"]
	return e.get(t, "") if t != "paralelo" else ""


## Cambia un contacto entre NA, NC y flanco, o una salida entre sus tipos, conservando la
## dirección cuando sirve para el nuevo tipo.
static func cambiar_tipo(programa: Array, ruta: Array, nuevo: String) -> void:
	var e := obtener(programa, ruta)
	var d := direccion(e)
	e.clear()
	match nuevo:
		"ton", "tof":
			e[nuevo] = d if d in DIRECCIONES_TEMPORIZADOR else DIRECCIONES_TEMPORIZADOR[0]
			e["ms"] = 3000.0
		"ctu", "rst":
			e[nuevo] = d if d in DIRECCIONES_CONTADOR else DIRECCIONES_CONTADOR[0]
			if nuevo == "ctu":
				e["pv"] = 5
		"bobina", "set", "reset":
			e[nuevo] = d if d in DIRECCIONES_BOBINA else DIRECCIONES_BOBINA[0]
		_:
			e[nuevo] = d if d in DIRECCIONES_CONTACTO else DIRECCIONES_CONTACTO[0]


## Direcciones válidas para el elemento.
static func direcciones_para(e: Dictionary) -> Array:
	match tipo(e):
		"ton", "tof":
			return DIRECCIONES_TEMPORIZADOR
		"ctu", "rst":
			return DIRECCIONES_CONTADOR
		"bobina", "set", "reset":
			return DIRECCIONES_BOBINA
		"cmp":
			return ["%IW0"]
	return DIRECCIONES_CONTACTO


## Pasa a la dirección siguiente (paso 1) o anterior (−1) de la lista válida.
static func mover_direccion(programa: Array, ruta: Array, paso: int) -> void:
	var e := obtener(programa, ruta)
	var lista := direcciones_para(e)
	var t := tipo(e)
	if t == "cmp" or t == "paralelo":
		return
	var i := lista.find(e[t])
	e[t] = lista[posmod(i + paso, lista.size())]


## Ajusta el tiempo de un temporizador, el preajuste de un contador o el valor de una comparación.
static func ajustar_valor(programa: Array, ruta: Array, paso: int) -> void:
	var e := obtener(programa, ruta)
	if e.has("ms"):
		e["ms"] = maxf(PASO_MS, float(e["ms"]) + paso * PASO_MS)
	elif e.has("pv"):
		e["pv"] = maxi(1, int(e["pv"]) + paso)
	elif e.has("cmp"):
		e["b"] = float(e["b"]) + paso * 0.5


static func agregar_en_serie(programa: Array, ruta: Array) -> void:
	var l := _lista(programa, ruta)
	(l[0] as Array).insert(int(l[1]) + 1, {"na": "%I0.0"})


## Pone el elemento en paralelo con un contacto nuevo.
static func agregar_paralelo(programa: Array, ruta: Array) -> void:
	var l := _lista(programa, ruta)
	var lista: Array = l[0]
	var e: Dictionary = lista[l[1]]
	lista[l[1]] = {"paralelo": [[e], [{"na": "%M0.0"}]]}


## Borra el elemento. Un paralelo que se queda con una rama se deshace en serie.
static func borrar(programa: Array, ruta: Array) -> void:
	var l := _lista(programa, ruta)
	var lista: Array = l[0]
	lista.remove_at(l[1])
	if ruta.size() >= 5:
		var padre := ruta.slice(0, ruta.size() - 2)
		var p := obtener(programa, padre)
		var ramas: Array = p["paralelo"]
		if lista.is_empty():
			ramas.erase(lista)
		if ramas.size() == 1:
			var pl := _lista(programa, padre)
			var contenedor: Array = pl[0]
			var resto: Array = ramas[0]
			contenedor.remove_at(pl[1])
			for k in resto.size():
				contenedor.insert(int(pl[1]) + k, resto[k])


static func agregar_salida(programa: Array, peldano: int) -> void:
	programa[peldano]["salidas"].append({"bobina": "%M0.1"})


static func agregar_peldano(programa: Array) -> void:
	programa.append({"comentario": "Peldaño nuevo", "logica": [{"na": "%I0.0"}], "salidas": [{"bobina": "%M0.0"}]})


static func borrar_peldano(programa: Array, peldano: int) -> void:
	programa.remove_at(peldano)
