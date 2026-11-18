class_name JuegoValvulas
extends RefCounted
## Minijuego «¿Abierta o cerrada?»: rondas con una válvula del catálogo en un estado al azar, su
## pregunta y sus opciones (data/catalogos/valvulas.json, campo «minijuego»). Hasta FOTOS_RONDAS
## rondas usan una foto tomada a bordo (data/fotos_piezas.json) en lugar del dibujo.

const REGISTRO := "abierta_cerrada"
const FOTOS_RONDAS := 4


## Válvulas del catálogo que tienen minijuego.
static func jugables(catalogo: Dictionary) -> Array:
	return catalogo.get("valvulas", []).filter(func(v: Dictionary) -> bool: return v.has("minijuego"))


## «n» rondas sin repetir la misma válvula y estado seguidos; reparte los tipos.
static func crear_rondas(catalogo: Dictionary, n: int, azar: RandomNumberGenerator, fotos: Array = []) -> Array:
	var lista := jugables(catalogo)
	var servicios: Array = catalogo.get("servicios", [])
	var rondas := []
	if lista.is_empty():
		return rondas
	var orden := range(lista.size())
	for i in range(orden.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var t: int = orden[i]
		orden[i] = orden[j]
		orden[j] = t
	var anterior := ""
	for k in n:
		var v: Dictionary = lista[orden[k % orden.size()]]
		var juego: Dictionary = v["minijuego"]
		var estados: Array = juego["estados"]
		var e: Dictionary = estados[azar.randi_range(0, estados.size() - 1)]
		var clave := "%s_%s" % [v["id"], JSON.stringify(e)]
		if clave == anterior and estados.size() > 1:
			e = estados[(estados.find(e) + 1) % estados.size()]
			clave = "%s_%s" % [v["id"], JSON.stringify(e)]
		anterior = clave
		rondas.append({
			"tipo": "valvula",
			"id": v["id"],
			"dibujo": v["dibujo"],
			"apertura": float(e.get("apertura", 1.0)),
			"via": str(e.get("via", "b")),
			"pregunta": juego["pregunta"],
			"opciones": juego["opciones"],
			"correcta": int(e["correcta"]),
			"explicacion": v["como_saber"],
			"tema": "valvula_%s" % v["id"],
			"servicio": servicios[azar.randi_range(0, servicios.size() - 1)] if not servicios.is_empty() else "",
		})
	_poner_fotos(rondas, lista, fotos, azar)
	return rondas


## Cambia algunas rondas por fotos a bordo: cada foto una vez, en posiciones al azar.
static func _poner_fotos(rondas: Array, lista: Array, fotos: Array, azar: RandomNumberGenerator) -> void:
	var usables := fotos.filter(func(f: Dictionary) -> bool:
		return str(f.get("estado", "")) in ["abierta", "cerrada"] and lista.any(func(v: Dictionary) -> bool: return v["id"] == f.get("pieza", "")))
	var cuantas := mini(mini(FOTOS_RONDAS, usables.size()), rondas.size())
	var posiciones := range(rondas.size())
	for k in cuantas:
		var f: Dictionary = usables.pop_at(azar.randi_range(0, usables.size() - 1))
		var i: int = posiciones.pop_at(azar.randi_range(0, posiciones.size() - 1))
		rondas[i] = ronda_foto(f, lista)


## Ronda con una foto a bordo: la pregunta dice hacia dónde va el tubo, porque en una foto
## de cerca no siempre se ve.
static func ronda_foto(foto: Dictionary, lista: Array) -> Dictionary:
	var v: Dictionary = {}
	for e: Dictionary in lista:
		if e["id"] == foto["pieza"]:
			v = e
	var juego: Dictionary = v["minijuego"]
	var tubo := str(foto.get("tubo", ""))
	return {
		"tipo": "valvula",
		"id": v["id"],
		"foto": foto["id"],
		"dibujo": v["dibujo"],
		"apertura": 1.0 if foto["estado"] == "abierta" else 0.0,
		"via": "b",
		"pregunta": ("El tubo es %s. ¿Cómo está esta válvula?" % tubo) if not tubo.is_empty() else str(juego["pregunta"]),
		"opciones": juego["opciones"],
		"correcta": 0 if foto["estado"] == "abierta" else 1,
		"explicacion": str(foto.get("texto", v["como_saber"])),
		"tema": "valvula_%s" % v["id"],
		"servicio": str(foto.get("lugar", "")),
	}


static func estrellas(aciertos: int, total: int) -> int:
	return JuegoSimbolos.estrellas(aciertos, total)
